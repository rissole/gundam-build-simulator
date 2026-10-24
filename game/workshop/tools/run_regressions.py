"""Run the headless workshop regressions and retain logs plus input fingerprints.

Run from anywhere; --list shows cases, --only selects named cases, and --jobs
runs independent cases together. Rendered inspection remains a separate
operation and is never implied by a passing run.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass, field
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import select
import subprocess
import sys
import time

PROJECT = Path(__file__).resolve().parents[1]
ROOT = PROJECT.parents[1]
CHECK_SUMMARY = re.compile(r"\b(?:PASS|FAIL)\s+\d+\s+checks")
PYTHON_SUMMARY = re.compile(r"^Ran \d+ tests? in |^(?:OK|FAILED)\b", re.MULTILINE)
SCRIPT_ERROR = "SCRIPT ERROR:"
JOLT_STALL = "Waiting for jobs to become available"
# A finished suite prints its summary and should exit immediately. Longer than
# this means quit() never ran; the case's time cap covers a suite still working.
SUMMARY_GRACE = 5.0
# The historical walked route and arm section have longer caps. Stage-flag
# coverage prepares only an early and the furthest stage. Fail-fast engine
# checks still apply.
CASE_TIMEOUTS = {"m3_acceptance_test": 900.0, "arm_delivery_test": 600.0}
# Historical single-leg walking/access evidence is retained on disk. M3's
# wider-workshop plan explicitly assigns those acceptance checks to the user.
# Do not silently bring them back through default discovery or --only.
HUMAN_M3_CHECKS = {"m3_acceptance_test", "m3_hip_access_test", "m3_route_clearance_test"}
# M3 saving is deferred until the wider structure exists (design/game/m3-wide-workshop-plan.md, "Saves and checkpoints").
DEFERRED_M3_SAVE_CHECKS = {"m3_save_validation_test"}


def is_scene_tree(path: Path, visited: frozenset[Path] = frozenset()) -> bool:
    """Include runnable suites that inherit another test's SceneTree harness."""
    path = path.resolve()
    if path in visited or not path.is_file():
        return False
    declaration = re.search(r'^extends\s+(SceneTree|"(res://[^"]+)")\s*(?:#.*)?$',
                            path.read_text(), re.MULTILINE)
    if not declaration:
        return False
    if declaration.group(1) == "SceneTree":
        return True
    return is_scene_tree(PROJECT / declaration.group(2).removeprefix("res://"), visited | {path})


@dataclass(frozen=True)
class Case:
    arguments: list[str]
    kind: str = "godot"
    timeout: float = 180.0


def cases() -> dict[str, Case]:
    result = {}
    for path in sorted((PROJECT / "tests").glob("*_test.gd")):
        if path.stem in HUMAN_M3_CHECKS or path.stem in DEFERRED_M3_SAVE_CHECKS:
            continue
        if is_scene_tree(path):
            result[path.stem] = Case(["--script", "tests/" + path.name],
                                     timeout=CASE_TIMEOUTS.get(path.stem, 180.0))
    aliases = {
        "default_workshop_launch": [],
        "foot_workshop_launch": ["--foot-workshop"],
        "m2_workshop_launch": ["--m2-workshop"],
        "m2_retention_launch": ["--m2-workshop", "--m2-trial=retention"],
        "m2_crane_launch": ["--m2-workshop", "--m2-trial=crane"],
        "m3_workshop_launch": ["--m3-workshop"],
    }
    for name, arguments in aliases.items():
        result[name] = Case(["--quit-after", "5", "--", *arguments], "launch")
    for profile in ("foot", "pads_single", "pads_multi", "leg_bay_retention", "leg_bay_crane", "leg_bay_m3"):
        result[profile + "_profile_launch"] = Case(
            ["--quit-after", "5", "--", "--profile=" + profile], "launch")
    result["source_assets"] = Case(
        ["-B", "-m", "unittest", "discover", "-s", str(PROJECT / "tests"),
         "-p", "test_source_assets.py"], "python")
    return result


def fingerprints() -> dict[str, str]:
    paths = [PROJECT / "project.godot", ROOT / "play.command"]
    for folder in [PROJECT / "scripts", PROJECT / "tests", PROJECT / "assets", PROJECT / "tools",
                   ROOT / "models/foot-fa01/src", ROOT / "models/foot-fa01/output"]:
        paths.extend(p for p in folder.rglob("*") if p.suffix in {".gd", ".gdshader", ".json", ".glb", ".py", ".png", ".svg"})
    return {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}


def command_for(case: Case, engine_log: Path) -> list[str]:
    if case.kind == "python":
        return [sys.executable, *case.arguments]
    return [str(ROOT / "play.command"), "--headless", "--fixed-fps", "60",
            "--log-file", str(engine_log), *case.arguments]


def completion_summary(kind: str, text: str) -> bool:
    """True once a case has printed the line that means its work is done."""
    if kind == "launch":
        return False
    if kind == "python":
        return PYTHON_SUMMARY.search(text) is not None
    return CHECK_SUMMARY.search(text) is not None


def assess(case: Case, text: str, code: int | None, timed_out: bool) -> tuple[bool, list[str], list[str]]:
    # macOS's certificate-store diagnostic is unrelated to these offline
    # tests. Every other engine/script error must be investigated.
    errors = [line for line in text.splitlines()
              if ("SCRIPT ERROR:" in line or "ERROR:" in line)
              and 'Condition "ret != noErr"' not in line]
    summaries = [line for line in text.splitlines() if CHECK_SUMMARY.search(line)]
    # Every case shares timeout/log/error/unchanged-input gates. Python's
    # unittest summary is required just as Godot suites require check counts.
    if case.kind == "python":
        summaries = [line for line in text.splitlines()
                     if re.search(r"^Ran \d+ tests? in ", line) or line == "OK"]
        evidence = any(line.startswith("Ran ") for line in summaries) and "OK" in summaries
    else:
        evidence = bool(summaries) or case.kind == "launch"
    passed = (code == 0 and not timed_out and not errors and evidence
              and not any("FAIL" in summary for summary in summaries))
    return passed, summaries, errors


@dataclass
class Job:
    name: str
    case: Case
    command: list[str]
    log_path: Path
    log_file: object
    process: subprocess.Popen
    started: float
    output: bytearray = field(default_factory=bytearray)
    summary_at: float | None = None

    def drain(self) -> None:
        stream = self.process.stdout
        if stream is None or stream.closed:
            return
        while True:
            try:
                chunk = os.read(stream.fileno(), 1 << 16)
            except BlockingIOError:
                break
            if not chunk:
                break
            self.output.extend(chunk)
            self.log_file.write(chunk)
        self.log_file.flush()

    def text(self) -> str:
        return self.output.decode("utf-8", "replace")

    def stop_reason(self, now: float, timeout: float) -> str | None:
        """Why a still-running process should be killed, if it should."""
        text = self.text()
        if SCRIPT_ERROR in text:
            return "script_error"
        if JOLT_STALL in text:
            return "jolt_stall"
        if completion_summary(self.case.kind, text):
            if self.summary_at is None:
                self.summary_at = now
            elif now - self.summary_at >= SUMMARY_GRACE:
                return "summary_stall"
        if now - self.started >= timeout:
            return "timeout"
        return None

    def result(self, code: int | None, timed_out: bool) -> dict:
        if self.process.stdout is not None and not self.process.stdout.closed:
            self.process.stdout.close()
        self.log_file.close()
        passed, summaries, errors = assess(self.case, self.text(), code, timed_out)
        return {"name": self.name, "passed": passed, "exit_code": code, "timed_out": timed_out,
                "seconds": round(time.monotonic() - self.started, 3), "command": self.command,
                "summaries": summaries, "errors": errors, "log": str(self.log_path)}


def start_job(name: str, case: Case, output: Path) -> Job:
    log_path = output / (name + ".log")
    log_file = log_path.open("wb")
    command = command_for(case, output / (name + ".engine.log"))
    process = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    assert process.stdout is not None
    os.set_blocking(process.stdout.fileno(), False)
    return Job(name, case, command, log_path, log_file, process, time.monotonic())


def settle_job(job: Job, now: float, timeout: float) -> dict | None:
    """Return a result when the process has exited or must be killed."""
    if job.process.poll() is not None:
        job.drain()
        return job.result(job.process.returncode, False)
    reason = job.stop_reason(now, timeout)
    if reason is None:
        return None
    if job.process.poll() is None:
        job.process.kill()
        job.process.wait(timeout=10)
    job.drain()
    timed_out = reason == "timeout"
    # A timeout used to report no exit code. Fail-fast kills keep the signal
    # status so a stalled PASS is still a failed process.
    code = None if timed_out else job.process.returncode
    return job.result(code, timed_out)


def run_pool(chosen: list[str], available: dict[str, Case], output: Path, jobs: int, timeout: float | None) -> list[dict]:
    queue = list(chosen)
    active: list[Job] = []
    finished: dict[str, dict] = {}

    def publish() -> None:
        ordered = [finished[name] for name in chosen if name in finished]
        (output / "results.json").write_text(json.dumps({"rendered": False, "cases": ordered}, indent=2) + "\n")

    while queue or active:
        while queue and len(active) < jobs:
            name = queue.pop(0)
            active.append(start_job(name, available[name], output))
        streams = [job.process.stdout for job in active if job.process.stdout is not None]
        ready, _, _ = select.select(streams, [], [], 0.05)
        ready_ids = {id(stream) for stream in ready}
        now = time.monotonic()
        still: list[Job] = []
        for job in active:
            if job.process.stdout is not None and id(job.process.stdout) in ready_ids:
                job.drain()
            result = settle_job(job, now, job.case.timeout if timeout is None else timeout)
            if result is None:
                still.append(job)
                continue
            finished[job.name] = result
            print(("PASS " if result["passed"] else "FAIL ") + job.name + " " + "; ".join(result["summaries"]), flush=True)
            if not result["passed"]:
                print("  " + result["log"], flush=True)
            publish()
        active = still
    return [finished[name] for name in chosen]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--only", nargs="+", help="Case names from --list")
    parser.add_argument("--jobs", type=int, default=3, help="Independent cases to run at once")
    parser.add_argument("--timeout", type=float,
                        help="Override every case's timeout in seconds (default 180; full M3 journey 900)")
    args = parser.parse_args()
    if args.jobs < 1:
        parser.error("--jobs must be at least 1")
    available = cases()
    if args.list:
        print("\n".join(available))
        return 0
    chosen = args.only or list(available)
    unknown = set(chosen) - available.keys()
    if unknown:
        parser.error("Unknown cases: " + ", ".join(sorted(unknown)))
    stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    output = PROJECT / "verification" / ("regressions-" + stamp)
    output.mkdir(parents=True)
    before = fingerprints()
    print("REGRESSION_OUTPUT " + str(output), flush=True)
    results = run_pool(chosen, available, output, args.jobs, args.timeout)
    unchanged = fingerprints() == before
    passed = all(case["passed"] for case in results) and unchanged
    report = {"passed": passed, "rendered": False, "inputs_unchanged": unchanged,
              "input_hashes": before, "cases": results}
    (output / "results.json").write_text(json.dumps(report, indent=2) + "\n")
    print("REGRESSIONS " + ("PASS" if passed else "FAIL") + f" {len(results)} cases; inputs unchanged={unchanged}")
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
