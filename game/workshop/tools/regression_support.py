"""Workshop verification infrastructure. Routine tests warn above 60 seconds;
expensive diagnostics require explicit case names through run_diagnostics.py.
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
# The arm section, the foot-build desktop journeys in the full hangar and the
# suites that script the whole build have longer caps.
# Fail-fast engine checks still apply.
CASE_TIMEOUTS = {"arm_delivery_test": 600.0, "pitch_desktop_test": 600.0, "pitch_swapped_desktop_test": 600.0,
                 **{name: 360.0 for name in ("stage_sequence_test", "head_closure_test", "head_crane_test",
                                             "head_preflight_test", "pauldron_delivery_test", "pauldron_preflight_test")}}


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


def discovered_cases() -> dict[str, Case]:
    result = {}
    for path in sorted((PROJECT / "tests").glob("*_test.gd")):
        if is_scene_tree(path):
            result[path.stem] = Case(["--script", "tests/" + path.name],
                                     timeout=CASE_TIMEOUTS.get(path.stem, 180.0))
    launches = {
        "stage_launch": ["--stage=pelvis"],
    }
    for name, arguments in launches.items():
        result[name] = Case(["--quit-after", "5", "--", *arguments], "launch")
    python_names = {"test_source_assets": "source_assets", "test_runner": "runner_contracts"}
    for path in sorted((PROJECT / "tests").glob("test_*.py")):
        name = python_names.get(path.stem, path.stem)
        result[name] = Case(
            ["-B", "-m", "unittest", "discover", "-s", str(PROJECT / "tests"),
             "-p", path.name], "python")
    return result


def cases(diagnostic: bool = False) -> dict[str, Case]:
    from test_inventory import ROUTINE, DIAGNOSTIC
    available = discovered_cases()
    overlap = set(ROUTINE) & set(DIAGNOSTIC)
    unknown = available.keys() - set(ROUTINE) - set(DIAGNOSTIC)
    missing = (set(ROUTINE) | set(DIAGNOSTIC)) - available.keys()
    if overlap or unknown or missing:
        raise ValueError(f"Test inventory mismatch: overlap={sorted(overlap)}, unclassified={sorted(unknown)}, missing={sorted(missing)}")
    return {name: available[name] for name in (DIAGNOSTIC if diagnostic else ROUTINE)}


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
        evidence = any(re.match(r"^Ran [1-9]\d* tests? in ", line) for line in summaries) and "OK" in summaries
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


def run_pool(chosen: list[str], available: dict[str, Case], output: Path, jobs: int, timeout: float | None, budget=None) -> list[dict]:
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
        if budget is not None:budget.check(now)
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


class RuntimeBudget:
    """A performance warning, never a timeout or correctness failure."""
    def __init__(self, started: float, seconds: float = 60.0):
        self.started, self.seconds, self.warned = started, seconds, False

    def check(self, now: float) -> bool:
        if not self.warned and now - self.started > self.seconds:
            self.warned = True
            print(f"WARNING: routine verification exceeded {self.seconds:g} seconds. Improve slow tests; do not raise the performance budget. Checks will finish normally.", flush=True)
            return True
        return False


def main(diagnostic: bool = False) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--only", nargs="+", help="Case names from --list")
    parser.add_argument("--jobs", type=int, default=1 if diagnostic else 4, help="Independent cases to run at once")
    parser.add_argument("--timeout", type=float,
                        help="Override every case's timeout in seconds (default 180)")
    args = parser.parse_args()
    if args.timeout is not None and args.timeout <= 0:
        parser.error("--timeout must be positive")
    if args.jobs < 1:
        parser.error("--jobs must be at least 1")
    try:
        available = cases(diagnostic)
    except ValueError as error:
        parser.error(str(error))
    if args.list:
        print("\n".join(available))
        return 0
    if diagnostic and not args.only:
        parser.error("Diagnostics require --only NAME ...; there is no run-all mode. Use --list.")
    chosen = list(dict.fromkeys(args.only or list(available)))
    unknown = set(chosen) - available.keys()
    if unknown:
        parser.error("Unknown cases: " + ", ".join(sorted(unknown)))
    if any(available[name].kind != "python" for name in chosen) and not (PROJECT / ".godot/imported").is_dir():
        parser.error("Assets need importing before verification. Run ./play.command --headless --editor --import --quit separately; import time is not test time.")
    started = time.monotonic()
    budget = None if diagnostic else RuntimeBudget(started)
    stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    output = PROJECT / "verification" / (("diagnostics-" if diagnostic else "regressions-") + stamp)
    output.mkdir(parents=True)
    before = fingerprints()
    print("REGRESSION_OUTPUT " + str(output), flush=True)
    results = run_pool(chosen, available, output, args.jobs, args.timeout, budget)
    unchanged = fingerprints() == before
    passed = all(case["passed"] for case in results) and unchanged
    elapsed = time.monotonic() - started
    if budget is not None:budget.check(time.monotonic())
    report = {"seconds": round(elapsed, 3), "performance_warning": bool(budget and budget.warned), "diagnostic": diagnostic, "asset_import": "not run; existing imports used", "passed": passed, "rendered": False, "inputs_unchanged": unchanged,
              "input_hashes": before, "cases": results}
    (output / "results.json").write_text(json.dumps(report, indent=2) + "\n")
    print("SLOWEST " + "; ".join(f"{case['name']} {case['seconds']:.3f}s" for case in sorted(results, key=lambda case: case["seconds"], reverse=True)[:5]))
    print(f"TOTAL {elapsed:.3f}s (includes fingerprinting and process startup; asset import is separate setup)")
    print(("DIAGNOSTICS " if diagnostic else "REGRESSIONS ") + ("PASS" if passed else "FAIL") + f" {len(results)} cases; inputs unchanged={unchanged}")
    return 0 if passed else 1

