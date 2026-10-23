"""Run the headless workshop regressions and retain logs plus input fingerprints.

Run from anywhere; --list shows cases and --only selects named cases. Rendered
inspection remains a separate operation and is never implied by a passing run.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
import datetime as dt
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import time

PROJECT = Path(__file__).resolve().parents[1]
ROOT = PROJECT.parents[1]


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


def cases() -> dict[str, Case]:
    result = {}
    for path in sorted((PROJECT / "tests").glob("*_test.gd")):
        if is_scene_tree(path):
            result[path.stem] = Case(["--script", "tests/" + path.name])
    aliases = {
        "default_workshop_launch": [],
        "foot_workshop_launch": ["--foot-workshop"],
        "m2_workshop_launch": ["--m2-workshop"],
        "m2_retention_launch": ["--m2-workshop", "--m2-trial=retention"],
        "m2_crane_launch": ["--m2-workshop", "--m2-trial=crane"],
    }
    for name, arguments in aliases.items():
        result[name] = Case(["--quit-after", "5", "--", *arguments], "launch")
    for profile in ("foot", "pads_single", "pads_multi", "leg_bay_retention", "leg_bay_crane"):
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


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--only", nargs="+", help="Case names from --list")
    parser.add_argument("--timeout", type=float, default=180, help="Per-case timeout in seconds")
    args = parser.parse_args()
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
    results = []
    print("REGRESSION_OUTPUT " + str(output), flush=True)
    for name in chosen:
        log = output / (name + ".log")
        case = available[name]
        cmd = ([sys.executable, *case.arguments] if case.kind == "python" else
               [str(ROOT / "play.command"), "--headless", "--fixed-fps", "60",
                "--log-file", str(output / (name + ".engine.log")), *case.arguments])
        started = time.monotonic()
        timed_out = False
        with log.open("w") as stream:
            try:
                completed = subprocess.run(cmd, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT,
                                           timeout=args.timeout, check=False)
                code = completed.returncode
            except subprocess.TimeoutExpired:
                timed_out, code = True, None
        text = log.read_text(errors="replace")
        # macOS's certificate-store diagnostic is unrelated to these offline
        # tests. Every other engine/script error must be investigated.
        errors = [line for line in text.splitlines()
                  if ("SCRIPT ERROR:" in line or "ERROR:" in line)
                  and 'Condition "ret != noErr"' not in line]
        summaries = [line for line in text.splitlines()
                     if re.search(r"\b(?:PASS|FAIL)\s+\d+\s+checks", line)]
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
        result = {"name": name, "passed": passed, "exit_code": code, "timed_out": timed_out,
                  "seconds": round(time.monotonic() - started, 3), "command": cmd,
                  "summaries": summaries, "errors": errors, "log": str(log)}
        results.append(result)
        print(("PASS " if passed else "FAIL ") + name + " " + "; ".join(summaries), flush=True)
        if not passed:
            print("  " + str(log), flush=True)
        (output / "results.json").write_text(json.dumps({"rendered": False, "cases": results}, indent=2) + "\n")
    unchanged = fingerprints() == before
    passed = all(case["passed"] for case in results) and unchanged
    report = {"passed": passed, "rendered": False, "inputs_unchanged": unchanged,
              "input_hashes": before, "cases": results}
    (output / "results.json").write_text(json.dumps(report, indent=2) + "\n")
    print("REGRESSIONS " + ("PASS" if passed else "FAIL") + f" {len(results)} cases; inputs unchanged={unchanged}")
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
