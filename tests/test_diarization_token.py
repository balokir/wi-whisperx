"""Windows launcher regression tests; no models, credentials, or extra packages."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
TOKEN = "hf_fake_launcher_test"


@unittest.skipUnless(os.name == "nt", "requires Windows cmd.exe")
class DiarizationTokenTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="wi whisperx test ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for folder in ("scripts", "setup"):
            (self.root / folder).mkdir()
        for name in ("transcribe-common.cmd", "require-hf-token.cmd"):
            shutil.copyfile(REPO / "scripts" / name, self.root / "scripts" / name)
        shutil.copyfile(REPO / "setup/config.cmd", self.root / "setup/config.cmd")
        (self.root / "input.wav").touch()
        (self.root / "hf-token.cmd.example").touch()
        (self.root / "capture.py").write_text(
            "import json, os, pathlib, sys\n"
            "pathlib.Path('capture.json').write_text(json.dumps({"
            "'args': sys.argv[1:], 'token': os.environ.get('HF_TOKEN'), "
            "'implicit': os.environ.get('HF_HUB_DISABLE_IMPLICIT_TOKEN')}))\n"
            "sys.exit(int(os.environ.get('TEST_EXIT_CODE', '0')))\n"
        )
        (self.root / "scripts/whisperx.cmd").write_text(
            '@echo off\n"%TEST_PYTHON%" "%ROOT%\\capture.py" %*\n'
            'exit /b %ERRORLEVEL%\n'
        )

    def run_launcher(self, mode, source="env", count="2", exit_code=0):
        env = os.environ.copy()
        env.pop("HF_TOKEN", None)
        env["TEST_PYTHON"] = sys.executable
        env["TEST_EXIT_CODE"] = str(exit_code)
        env["HF_HUB_DISABLE_IMPLICIT_TOKEN"] = "1"
        if source == "env":
            env["HF_TOKEN"] = TOKEN
            # An environment token must take precedence over the file.
            (self.root / "hf-token.cmd").write_text('@set "HF_TOKEN=hf_wrong"\n')
        elif source == "file":
            (self.root / "hf-token.cmd").write_text(f'@set "HF_TOKEN={TOKEN}"\n')
        result = subprocess.run(
            ["cmd.exe", "/d", "/c", "call", "scripts\\transcribe-common.cmd",
             "input.wav", mode, count], cwd=self.root, env=env,
            capture_output=True, text=True,
        )
        self.assertNotIn(TOKEN, result.stdout + result.stderr)
        return result

    def test_both_modes_and_token_sources(self):
        for mode in ("diarize", "diarize-speakers"):
            for source in ("env", "file"):
                with self.subTest(mode=mode, source=source):
                    result = self.run_launcher(mode, source)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    data = json.loads((self.root / "capture.json").read_text())
                    self.assertEqual(data["token"], TOKEN)
                    self.assertEqual(data["implicit"], "0")
                    self.assertNotIn(TOKEN, " ".join(data["args"]))
                    self.assertNotIn("--hf_token", data["args"])
                    self.assertIn("--diarize", data["args"])
                    for flag in ("--min_speakers", "--max_speakers"):
                        if mode == "diarize-speakers":
                            self.assertEqual(data["args"][data["args"].index(flag) + 1], "2")
                        else:
                            self.assertNotIn(flag, data["args"])

    def test_missing_token_stops_both_modes(self):
        for mode in ("diarize", "diarize-speakers"):
            self.assertNotEqual(self.run_launcher(mode, "missing").returncode, 0)
            self.assertFalse((self.root / "capture.json").exists())

    def test_invalid_speaker_count_stops_before_launch(self):
        self.assertNotEqual(self.run_launcher("diarize-speakers", count="0").returncode, 0)
        self.assertFalse((self.root / "capture.json").exists())

    def test_failure_keeps_exit_code_and_outputs(self):
        transcript = self.root / "transcript"
        transcript.mkdir()
        output = transcript / "input.json"
        output.touch()
        self.assertEqual(self.run_launcher("diarize", exit_code=7).returncode, 7)
        self.assertTrue(output.exists())

    def test_plain_does_not_require_token(self):
        self.assertEqual(self.run_launcher("plain", "missing").returncode, 0)
        data = json.loads((self.root / "capture.json").read_text())
        self.assertNotIn("--diarize", data["args"])
        self.assertEqual(data["implicit"], "1")


if __name__ == "__main__":
    unittest.main()
