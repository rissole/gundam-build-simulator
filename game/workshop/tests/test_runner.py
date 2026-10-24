"""Runner contracts: tiny Python subprocesses, never recursive game suites."""
import contextlib
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

TOOLS = Path(__file__).resolve().parents[1] / 'tools'
sys.path.insert(0, str(TOOLS))
import regression_support as runner
from test_inventory import ROUTINE, DIAGNOSTIC


class RunnerTests(unittest.TestCase):
    def test_explicit_inventory_and_unclassified_failure(self):
        self.assertFalse(set(ROUTINE) & set(DIAGNOSTIC))
        self.assertEqual(set(runner.cases()), set(ROUTINE))
        self.assertEqual(set(runner.cases(True)), set(DIAGNOSTIC))
        cases = runner.discovered_cases()
        cases['unclassified_test'] = runner.Case([])
        with patch.object(runner, 'discovered_cases', return_value=cases):
            with self.assertRaisesRegex(ValueError, 'unclassified_test'):
                runner.cases()
        with patch.object(runner, 'discovered_cases', return_value={}):
            with self.assertRaisesRegex(ValueError, 'missing='):
                runner.cases()

    def test_diagnostics_require_names_and_cannot_enter_routine(self):
        for script, args in [('run_diagnostics.py', []),
                             ('run_regressions.py', ['--only', DIAGNOSTIC[0]]),
                             ('run_diagnostics.py', ['--all'])]:
            result = subprocess.run([sys.executable, '-B', str(TOOLS / script), *args],
                                    capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
            self.assertNotIn('REGRESSION_OUTPUT', result.stdout)

    def test_warning_is_once_and_does_not_change_success(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            budget = runner.RuntimeBudget(100)
            self.assertFalse(budget.check(160))
            self.assertTrue(budget.check(161))
            self.assertFalse(budget.check(200))
        self.assertEqual(output.getvalue().count('WARNING:'), 1)
        self.assertIn('Improve slow tests', output.getvalue())
        self.assertTrue(runner.assess(runner.Case([]), 'PASS 1 checks', 0, False)[0])

    def test_missing_imports_do_not_trigger_implicit_editor_run(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(runner, 'PROJECT', Path(folder)), \
             patch.object(runner, 'cases', return_value={'scene': runner.Case([])}), \
             patch.object(runner, 'run_pool') as pool, \
             patch.object(sys, 'argv', ['run_regressions.py']), contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as error:
                runner.main()
            self.assertEqual(error.exception.code, 2)
            pool.assert_not_called()

    def test_failure_gates(self):
        case = runner.Case([])
        for output, code, timed_out in [('FAIL 1 checks', 0, False),
                                        ('SCRIPT ERROR: broken\nPASS 1 checks', 0, False),
                                        ('ERROR: broken\nPASS 1 checks', 0, False),
                                        ('PASS 1 checks', 1, False),
                                        ('PASS 1 checks', 0, True), ('', 0, False)]:
            self.assertFalse(runner.assess(case, output, code, timed_out)[0])

    def test_empty_python_discovery_is_not_success(self):
        self.assertFalse(runner.assess(runner.Case([], 'python'), 'Ran 0 tests in 0.001s\nOK', 0, False)[0])

    def test_pool_uses_real_exit_status_and_warns_without_killing(self):
        cases = {'okay': runner.Case(['-c', "print('Ran 1 test in 0.001s'); print('OK')"], 'python'),
                 'bad': runner.Case(['-c', "print('Ran 1 test in 0.001s'); print('OK'); raise SystemExit(1)"], 'python')}
        with tempfile.TemporaryDirectory() as folder, contextlib.redirect_stdout(io.StringIO()):
            budget = runner.RuntimeBudget(time.monotonic() - 61)
            results = runner.run_pool(list(cases), cases, Path(folder), 2, 3, budget)
            self.assertTrue(budget.warned)
            self.assertTrue(results[0]['passed'])
            self.assertFalse(results[1]['passed'])
            self.assertEqual(len(json.loads((Path(folder) / 'results.json').read_text())['cases']), 2)

    def test_stalled_pass_fails(self):
        case = runner.Case(['-c', "import time; print('Ran 1 test in 0.001s', flush=True); print('OK', flush=True); time.sleep(2)"], 'python')
        with tempfile.TemporaryDirectory() as folder, patch.object(runner, 'SUMMARY_GRACE', .05), contextlib.redirect_stdout(io.StringIO()):
            result = runner.run_pool(['stalled'], {'stalled': case}, Path(folder), 1, 3)[0]
        self.assertFalse(result['passed'])
        self.assertNotEqual(result['exit_code'], 0)

    def test_changed_inputs_fail_main(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(runner, 'PROJECT', Path(folder)), \
             patch.object(runner, 'cases', return_value={'fake': runner.Case([], 'python')}), \
             patch.object(runner, 'fingerprints', side_effect=[{'a': 'before'}, {'a': 'after'}]), \
             patch.object(runner, 'run_pool', return_value=[{'name': 'fake', 'seconds': 0, 'passed': True}]), \
             patch.object(sys, 'argv', ['run_regressions.py']), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(runner.main(), 1)
            report = json.loads(next((Path(folder) / 'verification').glob('*/results.json')).read_text())
            self.assertFalse(report['inputs_unchanged'])
            self.assertFalse(report['passed'])


if __name__ == '__main__':
    unittest.main()
