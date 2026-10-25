#!/usr/bin/env python3
"""Record three repeatable ten-second workshop films. Run with --list for the edit."""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

PROJECT = Path(__file__).resolve().parents[1]
ROOT = PROJECT.parents[1]
SHOT_FILE = Path(__file__).with_name("progress_shots.json")


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def json_hash(value) -> str:
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def inputs() -> dict[str, str]:
    paths = [ROOT / "play.command", PROJECT / "project.godot", SHOT_FILE, Path(__file__),
             Path(__file__).with_suffix(".gd")]
    for folder in ("scripts", "assets", "scenes"):
        paths.extend(p for p in (PROJECT / folder).rglob("*")
                     if p.is_file() and p.suffix not in (".uid", ".import"))
    return {str(p.relative_to(ROOT)): digest(p) for p in sorted(paths)}


def validate(document: dict, fps: int) -> dict:
    if document.get("version") != 1:
        raise ValueError("Unsupported shot-list version")
    sequences = document["sequences"]
    for name, sequence in sequences.items():
        frames = 0
        ids = set()
        for shot in sequence["shots"]:
            if shot["id"] in ids:
                raise ValueError(f"{name}: duplicate shot ID")
            ids.add(shot["id"])
            count = shot["seconds"] * fps
            if not 0 < shot["seconds"] <= 4 or not math.isclose(count, round(count)):
                raise ValueError(f"{name}/{shot['id']}: use 0–4 seconds on whole frames")
            if not isinstance(shot["speed"], int) or not 1 <= shot["speed"] <= 8:
                raise ValueError("Shot speed must be an integer from 1 to 8")
            if not 20 <= shot["fov"] <= 90:
                raise ValueError("Camera FOV must be 20–90 degrees")
            for field in ("eye_from", "eye_to", "target"):
                if len(shot[field]) != 3 or not all(math.isfinite(v) for v in shot[field]):
                    raise ValueError(f"Invalid camera {field}")
            if shot["eye_from"] == shot["eye_to"]:
                raise ValueError("Every shot needs a camera move")
            frames += round(count)
        if frames != 10 * fps:
            raise ValueError(f"{name}: the edit must be exactly ten seconds")
    return sequences


def frame_plan(sequence: dict, fps: int) -> list[dict]:
    result = []
    cursor = 0
    for shot in sequence["shots"]:
        count = round(shot["seconds"] * fps)
        result.append({"id": shot["id"], "first": cursor, "last": cursor + count - 1,
                       "samples": [cursor, cursor + count // 2, cursor + count - 1]})
        cursor += count
    return result


def run_engine(command: list[str], log: Path, timeout: float = 600) -> list[str]:
    """Fail on script errors even when Godot remains open or exits successfully."""
    with log.open("w") as stream:
        process = subprocess.Popen(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
        started = time.monotonic()
        consumed = 0
        try:
            while True:
                text = log.read_text(errors="replace")
                for line in text[consumed:].splitlines():
                    if line.startswith(("CAPTURE_", "ERROR:", "SCRIPT ERROR:")):
                        print(line, flush=True)
                consumed = len(text)
                if "SCRIPT ERROR:" in text or "PROGRESS_CAPTURE:" in text:
                    raise RuntimeError(f"Capture failed; see {log}")
                if process.poll() is not None:
                    break
                if time.monotonic() - started > timeout:
                    raise RuntimeError(f"Capture timed out; see {log}")
                time.sleep(0.1)
            text = log.read_text(errors="replace")
            errors, teardown_warnings = capture_errors(text)
            if process.returncode or errors or "CAPTURE_OK " not in text:
                raise RuntimeError(f"Capture failed; see {log}")
            if teardown_warnings:
                print(f"Capture complete; {len(teardown_warnings)} Godot renderer teardown warnings retained in {log}", flush=True)
            return teardown_warnings
        finally:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


def capture_errors(log: str) -> tuple[list[str], list[str]]:
    """Keep the known Forward+ teardown bug distinct from capture failures."""
    errors, teardown = [], []
    complete = False
    for line in log.splitlines():
        if line.startswith("CAPTURE_OK "):
            complete = True
        if "ERROR:" not in line or 'Condition "ret != noErr"' in line:
            continue
        if complete and line == "ERROR: BUG, indexing did not unpair geometries from light.":
            teardown.append(line)
        else:
            errors.append(line)
    return errors, teardown


def encode(ffmpeg: str, folder: Path, fps: int, frames: int) -> Path:
    destination = folder / "video.mp4"
    subprocess.run([ffmpeg, "-hide_banner", "-loglevel", "error", "-n", "-framerate", str(fps),
                    "-start_number", "0", "-i", str(folder / "frame-%06d.png"),
                    "-frames:v", str(frames), "-an", "-c:v", "libx264", "-preset", "slow",
                    "-crf", "18", "-threads", "1", "-pix_fmt", "yuv420p", "-map_metadata", "-1",
                    "-movflags", "+faststart", str(destination)], check=True)
    return destination


def contact_sheet(ffmpeg: str, folder: Path, plan: list[dict]) -> None:
    samples = folder / "stills"
    samples.mkdir()
    index = 0
    for shot in plan:
        for frame in shot["samples"]:
            shutil.copyfile(folder / f"frame-{frame:06d}.png", samples / f"{index:02d}.png")
            index += 1
    subprocess.run([ffmpeg, "-hide_banner", "-loglevel", "error", "-n", "-i", str(samples / "%02d.png"),
                    "-vf", f"scale=480:270,tile=3x{len(plan)}", "-frames:v", "1",
                    "-update", "1", str(folder / "storyboard.jpg")], check=True)


def capture(args, name: str, sequence: dict, base: Path, ffmpeg: str | None) -> dict:
    folder = base / name
    folder.mkdir()
    before = inputs()
    job = {"sequence": sequence, "fps": args.fps, "width": 960 if args.draft else 1920,
           "height": 540 if args.draft else 1080, "output": str(folder),
           "check": args.check, "storyboard": args.storyboard}
    job_path = folder / "job.json"
    job_path.write_text(json.dumps(job, indent=2) + "\n")
    command = [str(ROOT / "play.command"), "--fixed-fps", "60", "--disable-render-loop",
               "--log-file", str(folder / "engine.log")]
    command += ["--headless"] if args.check else ["--windowed", "--resolution", "960x540"]
    command += ["--script", "tools/record_progress.gd", "--", f"--capture-job={job_path}"]
    print(f"Recording {name}: {sequence['title']}", flush=True)
    teardown_warnings = run_engine(command, folder / "capture.log")
    report = json.loads((folder / "capture.json").read_text())
    if before != inputs():
        raise RuntimeError("Source changed during capture. Retry from a stable checkout.")
    if report["frames"] != 10 * args.fps or report["save_enabled"]:
        raise RuntimeError("Invalid frame count or save isolation")
    plan = frame_plan(sequence, args.fps)
    wanted = sorted(frame for shot in plan for frame in shot["samples"]) if args.storyboard else list(range(report["frames"]))
    actual = sorted(int(p.stem.split("-")[1]) for p in folder.glob("frame-*.png"))
    if not args.check and actual != wanted:
        raise RuntimeError("Missing or unexpected rendered frames")
    manifest = {"sequence": name, "title": sequence["title"], "seconds": 10, "fps": args.fps,
                "size": report["size"], "mode": "check" if args.check else "storyboard" if args.storyboard else "video",
                "engine": report["engine"], "renderer": report["renderer"], "adapter": report["adapter"],
                "input_hashes": before, "shot_list": sequence, "edit": plan,
                "trace_sha256": json_hash(report["trace"]),
                "final_state_sha256": json_hash([report["final_equipment"], report["final_model"]]),
                "frame_hashes": {p.name: digest(p) for p in sorted(folder.glob("frame-*.png"))},
                "command": command,
                "git_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()}
    if teardown_warnings:
        manifest["teardown_warnings"] = teardown_warnings
    if not args.check:
        contact_sheet(ffmpeg, folder, plan)
        if not args.storyboard:
            video = encode(ffmpeg, folder, args.fps, report["frames"])
            manifest["video_sha256"] = digest(video)
    if args.compare:
        previous = json.loads((args.compare / name / "manifest.json").read_text())
        manifest["comparison"] = {key: manifest[key] == previous[key]
                                  for key in ("input_hashes", "trace_sha256", "final_state_sha256", "frame_hashes")}
        print(f"Comparison {name}: {manifest['comparison']}", flush=True)
    (folder / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    if not args.keep_frames:
        for frame in folder.glob("frame-*.png"):
            frame.unlink()
    print(f"Saved {folder}", flush=True)
    return manifest


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sequences", nargs="*", help="crown, pelvis, leg; default all three")
    parser.add_argument("--list", action="store_true", help="Show the sequences and shot timings")
    parser.add_argument("--draft", action="store_true", help="960×540 instead of 1920×1080")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--storyboard", action="store_true", help="Render first/middle/last frame of each shot")
    mode.add_argument("--check", action="store_true", help="Replay mechanically without rendering or encoding")
    parser.add_argument("--fps", type=int, choices=(30, 60), default=30)
    parser.add_argument("--output", type=Path, help="New output directory (existing paths are refused)")
    parser.add_argument("--compare", type=Path, help="Prior output directory; compare timing/state/pixel hashes")
    parser.add_argument("--keep-frames", action="store_true", help="Keep all lossless PNG frames after encoding")
    args = parser.parse_args(argv)
    try:
        sequences = validate(json.loads(SHOT_FILE.read_text()), args.fps)
        selected = list(dict.fromkeys(args.sequences or sequences))
        if set(selected) - sequences.keys():
            parser.error("Sequences must be " + ", ".join(sequences))
        if args.list:
            for name in selected:
                sequence = sequences[name]
                print(f"{name}: {sequence['title']} (10s)")
                for shot in sequence["shots"]:
                    print(f"  {shot['seconds']:g}s  {shot['id']}  ({shot['speed']}× equipment speed)")
            return 0
        ffmpeg = shutil.which(os.environ.get("FFMPEG_BIN", "ffmpeg"))
        if not args.check and not ffmpeg:
            parser.error("FFmpeg is needed to encode videos. On macOS: brew install ffmpeg; or set FFMPEG_BIN")
        if not (PROJECT / ".godot/imported").is_dir():
            parser.error("Import this worktree first: ./play.command --headless --editor --import --quit")
        stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
        base = (args.output or PROJECT / "verification" / ("progress-" + stamp)).resolve()
        base.mkdir(parents=True, exist_ok=False)
        print(f"PROGRESS_OUTPUT {base}", flush=True)
        results = [capture(args, name, sequences[name], base, ffmpeg) for name in selected]
        (base / "index.json").write_text(json.dumps(results, indent=2) + "\n")
        return 0
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"Recording stopped: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
