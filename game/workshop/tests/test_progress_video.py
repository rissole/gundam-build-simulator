"""Cheap edit/export contracts; actual rendered captures remain an opt-in tool."""
import copy
from contextlib import redirect_stdout
import io
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

TOOL = Path(__file__).resolve().parents[1] / "tools" / "record_progress.py"
spec = importlib.util.spec_from_file_location("record_progress", TOOL)
video = importlib.util.module_from_spec(spec)
spec.loader.exec_module(video)


class ProgressVideoTests(unittest.TestCase):
    def setUp(self):
        self.document = json.loads(video.SHOT_FILE.read_text())

    def test_replacement_finishes_the_robot_and_removes_rejected_preset(self):
        self.assertEqual(set(self.document["sequences"]), {"crown", "pelvis", "leg"})
        crown = self.document["sequences"]["crown"]
        self.assertEqual(crown["final_stage"], "complete")
        self.assertEqual(crown["expect"]["service_crane"]["station"], "park")
        self.assertEqual(crown["parents"]["head_crown"], "chest")

    def test_edits_cover_exactly_ten_seconds_at_both_rates(self):
        for fps in (30, 60):
            for sequence in video.validate(self.document, fps).values():
                plan = video.frame_plan(sequence, fps)
                frames = [frame for shot in plan for frame in range(shot["first"], shot["last"] + 1)]
                self.assertEqual(frames, list(range(10 * fps)))
                for shot in plan:
                    self.assertEqual(shot["samples"][0], shot["first"])
                    self.assertEqual(shot["samples"][-1], shot["last"])

    def test_rejects_edit_drift_and_static_shots(self):
        for field, value in (("seconds", 2.51), ("speed", 1.5), ("target", [float("nan"), 0, 0])):
            bad = copy.deepcopy(self.document)
            bad["sequences"]["crown"]["shots"][0][field] = value
            with self.assertRaises(ValueError):
                video.validate(bad, 30)
        shot = self.document["sequences"]["crown"]["shots"][0]
        shot["eye_to"] = shot["eye_from"]
        with self.assertRaises(ValueError):
            video.validate(self.document, 30)

    def test_capture_requires_success_marker_and_clean_exit(self):
        with tempfile.TemporaryDirectory() as folder, redirect_stdout(io.StringIO()):
            for program in ("print('nothing captured')", "print('CAPTURE_OK 300 frames'); raise SystemExit(1)",
                            "print('CAPTURE_OK 300 frames'); print('SCRIPT ERROR: broken')"):
                with self.assertRaises(RuntimeError):
                    video.run_engine([sys.executable, "-c", program], Path(folder) / "log")
            video.run_engine([sys.executable, "-c", "print('CAPTURE_OK 300 frames')"], Path(folder) / "log")

    def test_trace_hash_ignores_object_key_order_but_tracks_camera_motion(self):
        self.assertEqual(video.json_hash({"eye": [1, 2, 3], "frame": 4}),
                         video.json_hash({"frame": 4, "eye": [1, 2, 3]}))
        self.assertNotEqual(video.json_hash({"eye": [1, 2, 3]}), video.json_hash({"eye": [2, 2, 3]}))


if __name__ == "__main__":
    unittest.main()
