import tempfile
import unittest
from pathlib import Path

from tool.verify_stateful_test_manifest import (
    core_exclusion_files,
    workflow_runner_files,
)


class StatefulTestManifestTest(unittest.TestCase):
    def test_matches_core_exclusions_to_direct_and_python_runners(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            tests = root / "test"
            tools = root / "tool"
            tests.mkdir()
            tools.mkdir()
            for name in ["direct_test.dart", "sync_alpha_test.dart"]:
                (tests / name).write_text("", encoding="utf-8")
            (tools / "isolated.py").write_text(
                "files = tests.glob('*sync*_test.dart')\n", encoding="utf-8"
            )
            workflow = """
              ! -name 'direct_test.dart' \\
              ! -name '*sync*_test.dart' \\
              flutter test test/direct_test.dart
              python3 tool/isolated.py
            """

            excluded, exclusion_errors = core_exclusion_files(workflow, root)
            covered, runner_errors = workflow_runner_files(workflow, root)

            self.assertEqual(exclusion_errors, [])
            self.assertEqual(runner_errors, [])
            self.assertEqual(
                excluded,
                {"test/direct_test.dart", "test/sync_alpha_test.dart"},
            )
            self.assertEqual(excluded - covered, set())

    def test_reports_dead_exclusions_and_runner_entries(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            (root / "test").mkdir()
            (root / "tool").mkdir()
            (root / "tool/isolated.py").write_text(
                "files = tests / 'missing_test.dart'\n", encoding="utf-8"
            )
            workflow = """
              ! -name 'gone_test.dart' \\
              python3 tool/isolated.py
            """

            _, exclusion_errors = core_exclusion_files(workflow, root)
            _, runner_errors = workflow_runner_files(workflow, root)

            self.assertEqual(
                exclusion_errors,
                ["dead Core exclusion: test/gone_test.dart"],
            )
            self.assertEqual(
                runner_errors,
                [
                    "dead isolated runner entry: "
                    "tool/isolated.py: test/missing_test.dart"
                ],
            )


if __name__ == "__main__":
    unittest.main()
