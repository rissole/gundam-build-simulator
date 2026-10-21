"""Run the headless workshop regressions and retain logs plus input fingerprints.

Run from anywhere; --list shows cases and --only selects named cases. Rendered
inspection remains a separate operation and is never implied by a passing run.
"""
from __future__ import annotations

import argparse
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


def cases() -> dict[str, list[str]]:
    result = {}
    for path in sorted((PROJECT / "tests").glob("*_test.gd")):
        if re.search(r"^extends SceneTree\s*$", path.read_text(), re.MULTILINE):
            result[path.stem] = ["--script", "tests/" + path.name]
    result.update({
        "single_pad_desktop": ["--", "--single-pad", "--demo-test"],
        "multi_build_desktop": ["--", "--multi-test"],
        "pitch_desktop": ["--", "--pitch-test"],
        "pitch_swapped_desktop": ["--", "--pitch-test", "--swap-identical-parts"],
        "pockets_desktop": ["--", "--pockets-test"],
    })
    return result


def fingerprints() -> dict[str, str]:
    paths = [PROJECT / "project.godot", ROOT / "play-heel-pad.command"]
    for folder in [PROJECT / "scripts", PROJECT / "tests", PROJECT / "assets", PROJECT / "tools"]:
        paths.extend(p for p in folder.rglob("*") if p.suffix in {".gd", ".gdshader", ".json", ".glb", ".py", ".png"})
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
        cmd = [str(ROOT / "play-heel-pad.command"), "--headless", "--fixed-fps", "60",
               "--log-file", str(output / (name + ".engine.log")), *available[name]]
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
        passed = code == 0 and not timed_out and not errors and bool(summaries) and not any("FAIL" in s for s in summaries)
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
