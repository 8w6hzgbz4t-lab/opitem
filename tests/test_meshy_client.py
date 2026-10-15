"""Offline checks for paid-task safety, resumability, and artifact handling.

All HTTP access is mocked. These tests never need a Meshy key or submit a task.
"""
from __future__ import annotations

import argparse
from contextlib import redirect_stderr, redirect_stdout
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import Mock, call, patch
from urllib.error import URLError


REPO = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("meshygenerator_under_test", REPO / "meshy" / "generate_models.py")
assert SPEC is not None and SPEC.loader is not None
meshy = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(meshy)


def glb_bytes() -> bytes:
    """A complete GLB 2 container with a minimal JSON asset chunk."""
    content = b'{"asset":{"version":"2.0"}}'
    content += b" " * ((-len(content)) % 4)
    chunk = struct.pack("<I4s", len(content), b"JSON") + content
    return struct.pack("<4sII", b"glTF", 2, 12 + len(chunk)) + chunk


def args_for(**changes) -> argparse.Namespace:
    values = dict(resume_preview=None, resume_refine=None, timeout=10, poll=1, formats=["glb"])
    values.update(changes)
    return argparse.Namespace(**values)


class OfflineMeshyChecks(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.folder = Path(self.temporary.name)
        self.assets = meshy.read_assets(REPO / "meshy" / "assets.json")
        self.asset = next(asset for asset in self.assets if not asset.get("needs_reference") and not asset.get("reference_required"))
        # A forgotten mock must fail immediately, not contact the service.
        blocker = patch.object(meshy, "urlopen", side_effect=AssertionError("Unmocked network request"))
        self.blocked_network = blocker.start()
        self.addCleanup(blocker.stop)

    def test_plan_lists_all_briefs_without_credentials_or_http(self):
        output = io.StringIO()
        with patch.dict(meshy.os.environ, {}, clear=True), patch.object(meshy.getpass, "getpass") as prompt, redirect_stdout(output):
            result = meshy.main(["plan", "--output", str(self.folder / "unused")])
        self.assertEqual(result, 0)
        self.assertEqual(len(self.assets), 33)
        self.assertIn("33 briefs; no Meshy task submitted", output.getvalue())
        self.assertIn("REFERENCE NEEDED", output.getvalue())
        self.assertFalse((self.folder / "unused").exists())
        prompt.assert_not_called()
        self.blocked_network.assert_not_called()

    def test_missing_key_fails_before_submitting_or_creating_state(self):
        errors = io.StringIO()
        with patch.dict(meshy.os.environ, {}, clear=True), redirect_stderr(errors):
            result = meshy.main(["generate", "--asset", self.asset["key"], "--output", str(self.folder / "unused")])
        self.assertEqual(result, 1)
        self.assertIn("MESHY_API_KEY", errors.getvalue())
        self.assertFalse((self.folder / "unused").exists())
        self.blocked_network.assert_not_called()

    def test_generate_requires_an_explicit_asset_selection(self):
        with patch.dict(meshy.os.environ, {"MESHY_API_KEY": "fake-only"}, clear=True), redirect_stderr(io.StringIO()):
            result = meshy.main(["generate", "--output", str(self.folder)])
        self.assertEqual(result, 1)
        self.blocked_network.assert_not_called()

    def test_submit_once_persists_task_before_any_poll_and_reuses_it(self):
        path = self.folder / "asset" / "state.json"
        state = {"key": self.asset["key"]}
        client = Mock(spec=meshy.MeshyClient)

        def submit(payload):
            saved = json.loads(path.read_text())
            self.assertEqual(saved["submission_in_flight"], "preview")
            self.assertNotIn("preview_task_id", saved)
            return "preview_task_123"

        client.submit.side_effect = submit
        payload = meshy.preview_payload(self.asset)
        first = meshy.submit_once(client, state, path, "preview", payload)
        reloaded = json.loads(path.read_text())
        second = meshy.submit_once(client, reloaded, path, "preview", payload)
        self.assertEqual(first, second)
        self.assertEqual(reloaded["preview_task_id"], "preview_task_123")
        self.assertNotIn("submission_in_flight", reloaded)
        client.submit.assert_called_once_with(payload)

    def test_ambiguous_post_failure_blocks_a_second_paid_submission(self):
        path = self.folder / "state.json"
        state = {"key": self.asset["key"]}
        client = Mock(spec=meshy.MeshyClient)
        client.submit.side_effect = meshy.MeshyError("Connection lost after POST")
        with self.assertRaisesRegex(meshy.MeshyError, "Connection lost"):
            meshy.submit_once(client, state, path, "preview", meshy.preview_payload(self.asset))
        saved = json.loads(path.read_text())
        self.assertEqual(saved["submission_in_flight"], "preview")
        with self.assertRaisesRegex(meshy.MeshyError, "duplicate submission is blocked"):
            meshy.submit_once(client, saved, path, "preview", meshy.preview_payload(self.asset))
        self.assertEqual(client.submit.call_count, 1)

    def test_reference_required_asset_never_submits_or_creates_state(self):
        asset = next(asset for asset in self.assets if asset.get("needs_reference") or asset.get("reference_required"))
        client = Mock(spec=meshy.MeshyClient)
        with self.assertRaisesRegex(meshy.MeshyError, "reference"):
            meshy.generate(asset, client, self.folder, args_for())
        client.submit.assert_not_called()
        client.wait.assert_not_called()
        self.assertFalse((self.folder / asset["key"]).exists())
        self.blocked_network.assert_not_called()

    def test_resume_refine_downloads_without_creating_or_waiting_for_preview(self):
        client = Mock(spec=meshy.MeshyClient)
        client.wait.return_value = {"status": "SUCCEEDED", "model_urls": {"glb": "https://assets.example/model.glb?signed=1"}}
        body = glb_bytes()
        with patch.object(meshy, "urlopen", return_value=io.BytesIO(body)), redirect_stdout(io.StringIO()):
            meshy.generate(self.asset, client, self.folder, args_for(resume_refine="refine_task_123"))
        client.submit.assert_not_called()
        client.wait.assert_called_once_with("refine_task_123", 10, 1)
        output = self.folder / self.asset["key"]
        self.assertEqual((output / (self.asset["key"] + ".glb")).read_bytes(), body)
        saved = json.loads((output / "state.json").read_text())
        self.assertEqual(saved["status"], "downloaded")
        self.assertEqual(saved["files_sha256"][self.asset["key"] + ".glb"], hashlib.sha256(body).hexdigest())

    def test_saved_refine_id_is_also_resumed_without_paid_preview(self):
        output = self.folder / self.asset["key"]
        meshy.save_state(output / "state.json", {"key": self.asset["key"], "refine_task_id": "refine_task_saved"})
        client = Mock(spec=meshy.MeshyClient)
        client.wait.return_value = {"status": "SUCCEEDED", "model_urls": {"glb": "https://assets.example/model.glb"}}
        with patch.object(meshy, "urlopen", return_value=io.BytesIO(glb_bytes())), redirect_stdout(io.StringIO()):
            meshy.generate(self.asset, client, self.folder, args_for())
        client.submit.assert_not_called()
        client.wait.assert_called_once_with("refine_task_saved", 10, 1)

    def test_full_generation_and_repeat_use_two_total_paid_submissions(self):
        submissions = []
        downloads = []
        gets = []
        secret = "fake-local-test-key"

        def fetch(request, **kwargs):
            if request.full_url.startswith(meshy.API_BASE):
                self.assertEqual(request.get_header("Authorization"), "Bearer " + secret)
                if request.method == "POST":
                    payload = json.loads(request.data)
                    submissions.append(payload)
                    task_id = "preview_task_integration" if payload["mode"] == "preview" else "refine_task_integration"
                    return io.BytesIO(json.dumps({"result": task_id}).encode())
                self.assertEqual(request.method, "GET")
                gets.append(request.full_url)
                result = {"status": "SUCCEEDED", "progress": 100}
                if request.full_url.endswith("refine_task_integration"):
                    result["model_urls"] = {"glb": "https://assets.example/complete.glb"}
                return io.BytesIO(json.dumps(result).encode())
            self.assertEqual(request.full_url, "https://assets.example/complete.glb")
            self.assertFalse(request.has_header("Authorization"))
            downloads.append(request.full_url)
            return io.BytesIO(glb_bytes())

        client = meshy.MeshyClient(secret)
        with patch.object(meshy, "urlopen", side_effect=fetch), redirect_stdout(io.StringIO()):
            meshy.generate(self.asset, client, self.folder, args_for())
            # Running the same command again resumes instead of buying replacements.
            meshy.generate(self.asset, client, self.folder, args_for())
        self.assertEqual([payload["mode"] for payload in submissions], ["preview", "refine"])
        self.assertEqual(submissions[1]["preview_task_id"], "preview_task_integration")
        self.assertEqual(len(downloads), 1)
        self.assertEqual(len(gets), 3)
        state = json.loads((self.folder / self.asset["key"] / "state.json").read_text())
        self.assertEqual(state["preview_task_id"], "preview_task_integration")
        self.assertEqual(state["refine_task_id"], "refine_task_integration")
        self.assertEqual(state["status"], "downloaded")
        self.assertNotIn("submission_in_flight", state)

    def test_changed_brief_cannot_silently_reuse_old_paid_task(self):
        output = self.folder / self.asset["key"]
        meshy.save_state(output / "state.json", {"key": self.asset["key"], "prompt_sha256": "not-the-current-prompt", "preview_task_id": "preview_task_123"})
        client = Mock(spec=meshy.MeshyClient)
        with self.assertRaisesRegex(meshy.MeshyError, "brief changed"):
            meshy.generate(self.asset, client, self.folder, args_for())
        client.submit.assert_not_called()
        client.wait.assert_not_called()

    def test_download_requires_https_without_embedded_credentials(self):
        for address in ("http://assets.example/a.glb", "file:///tmp/a.glb", "https://user:secret@assets.example/a.glb", "https:///a.glb"):
            with self.subTest(address=address), self.assertRaises(meshy.MeshyError):
                meshy.download(address, self.folder / "invalid.glb", "glb")
        self.blocked_network.assert_not_called()

    def test_signed_asset_download_has_no_api_authorization_and_checksums_bytes(self):
        body = glb_bytes()
        requests = []

        def fetch(request, **kwargs):
            requests.append(request)
            self.assertFalse(request.has_header("Authorization"))
            self.assertEqual(request.full_url, "https://assets.example/model.glb?token=signed-value")
            return io.BytesIO(body)

        target = self.folder / "model.glb"
        with patch.object(meshy, "urlopen", side_effect=fetch) as network:
            checksum = meshy.download("https://assets.example/model.glb?token=signed-value", target, "glb")
            # Resuming an already validated artifact must not redownload it.
            second = meshy.download("https://assets.example/model.glb?token=signed-value", target, "glb")
        self.assertEqual(target.read_bytes(), body)
        self.assertEqual(checksum, hashlib.sha256(body).hexdigest())
        self.assertEqual(second, checksum)
        self.assertEqual(network.call_count, 1)
        self.assertFalse(target.with_suffix(".glb.part").exists())

    def test_bad_or_truncated_glb_is_never_promoted_to_final_output(self):
        valid = glb_bytes()
        cases = {
            "html error": b"<html>not a model</html>",
            "truncated header": b"glTF", 
            "truncated body": valid[:-4],
            "wrong version": struct.pack("<4sII", b"glTF", 1, len(valid)) + valid[12:],
            "incorrect declared length": struct.pack("<4sII", b"glTF", 2, len(valid) + 20) + valid[12:],
        }
        for name, body in cases.items():
            target = self.folder / "model.glb"
            with self.subTest(case=name), patch.object(meshy, "urlopen", return_value=io.BytesIO(body)), self.assertRaises(meshy.MeshyError):
                meshy.download("https://assets.example/model.glb", target, "glb")
            self.assertFalse(target.exists())
            self.assertFalse(target.with_suffix(".glb.part").exists())

    def test_failed_download_removes_partial_output_and_can_resume(self):
        target = self.folder / "model.glb"
        response = Mock()
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)
        response.read.side_effect = [b"glTF", URLError("broken stream")]
        with patch.object(meshy, "urlopen", return_value=response), self.assertRaisesRegex(meshy.MeshyError, "run again to resume"):
            meshy.download("https://assets.example/model.glb", target, "glb")
        self.assertFalse(target.exists())
        self.assertFalse(target.with_suffix(".glb.part").exists())
        with patch.object(meshy, "urlopen", return_value=io.BytesIO(glb_bytes())):
            meshy.download("https://assets.example/model.glb", target, "glb")
        self.assertTrue(target.exists())

    def test_wait_polls_existing_task_and_reports_progress_until_success(self):
        client = meshy.MeshyClient("fake-key-for-offline-test")
        succeeded = {"status": "SUCCEEDED", "progress": 100, "model_urls": {"glb": "https://assets.example/model.glb"}}
        states = [{"status": "PENDING", "progress": 0}, {"status": "PENDING", "progress": 0}, {"status": "IN_PROGRESS", "progress": 42}, succeeded]
        output = io.StringIO()
        with patch.object(client, "request", side_effect=states) as request, patch.object(meshy.time, "sleep") as sleep, patch.object(meshy.time, "monotonic", return_value=100), redirect_stdout(output):
            self.assertEqual(client.wait("existing_task_123", 10, 1), succeeded)
        self.assertEqual(request.call_args_list, [call("GET", task_id="existing_task_123")] * 4)
        self.assertEqual(sleep.call_count, 3)
        self.assertEqual(output.getvalue().count("PENDING 0%"), 1)
        self.assertIn("IN_PROGRESS 42%", output.getvalue())
        self.assertIn("SUCCEEDED 100%", output.getvalue())

    def test_terminal_failures_and_unknown_status_never_create_replacement_tasks(self):
        for status in (*sorted(meshy.TERMINAL_FAILURES), "UNEXPECTED"):
            with self.subTest(status=status):
                client = meshy.MeshyClient("fake-key-for-offline-test")
                with patch.object(client, "request", return_value={"status": status, "progress": 50}) as request, redirect_stdout(io.StringIO()), self.assertRaises(meshy.MeshyError):
                    client.wait("existing_task_123", 10, 1)
                request.assert_called_once_with("GET", task_id="existing_task_123")

    def test_timeout_keeps_the_original_task_available_for_resume(self):
        client = meshy.MeshyClient("fake-key-for-offline-test")
        with patch.object(client, "request", return_value={"status": "IN_PROGRESS", "progress": 50}) as request, patch.object(meshy.time, "monotonic", side_effect=[100, 111]), redirect_stdout(io.StringIO()), self.assertRaisesRegex(meshy.MeshyError, "resume task existing_task_123"):
            client.wait("existing_task_123", 10, 1)
        request.assert_called_once_with("GET", task_id="existing_task_123")

    def test_api_request_uses_credentials_but_connection_errors_do_not_expose_them(self):
        client = meshy.MeshyClient("private-test-credential")

        def fail(request, **kwargs):
            self.assertEqual(request.get_header("Authorization"), "Bearer private-test-credential")
            self.assertEqual(request.method, "POST")
            raise URLError("private-test-credential must never appear in the friendly message")

        with patch.object(meshy, "urlopen", side_effect=fail), self.assertRaises(meshy.MeshyError) as error:
            client.submit(meshy.preview_payload(self.asset))
        self.assertNotIn("private-test-credential", str(error.exception))
        self.assertIn("not retried", str(error.exception))


if __name__ == "__main__":
    unittest.main()
