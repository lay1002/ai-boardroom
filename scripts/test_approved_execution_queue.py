#!/usr/bin/env python3
"""Test suite for scripts/approved_execution_queue.py (Sprint-019).

Run with:
    python3 scripts/test_approved_execution_queue.py

Covers the 30 test cases required by
reviews/sprint-019/round-001/architecture.md Section 17. Each test runs
against a temporary REVIEWS_OVERRIDE directory (monkeypatched onto the
module's path globals) so nothing here ever touches the real
reviews/approved-execution-queue tree or reviews/notification_history.jsonl.
"""

from __future__ import annotations

import contextlib
import hashlib
import io
import json
import re
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import yaml

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
import approved_execution_queue as aeq  # noqa: E402


class AEQTestCase(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp(prefix="aeq_test_"))
        self.reviews_dir = self.tmp / "reviews"
        self.reviews_dir.mkdir()

        # Monkeypatch the module's path globals to point at the temp dir,
        # instead of the real reviews/ tree.
        aeq.REVIEWS_DIR = self.reviews_dir
        aeq.QUEUE_DIR = self.reviews_dir / "approved-execution-queue"
        aeq.REQUESTS_DIR = aeq.QUEUE_DIR / "requests"
        aeq.APPROVED_DIR = aeq.QUEUE_DIR / "approved"
        aeq.DRY_RUN_DIR = aeq.QUEUE_DIR / "dry-run"
        aeq.AUDIT_DIR = aeq.QUEUE_DIR / "audit"
        aeq.AUDIT_LOG = aeq.AUDIT_DIR / "audit.jsonl"
        aeq.NOTIFICATION_HISTORY = self.reviews_dir / "notification_history.jsonl"

        self.fixtures_dir = self.tmp / "fixtures"
        self.fixtures_dir.mkdir()

    def tearDown(self) -> None:
        shutil.rmtree(self.tmp, ignore_errors=True)

    # -- fixture helpers --------------------------------------------------

    def write_md(self, name: str, data: dict, body: str = "# doc\n") -> Path:
        path = self.fixtures_dir / name
        content = "---\n" + yaml.safe_dump(data, allow_unicode=True, sort_keys=False) + "---\n\n" + body
        path.write_text(content, encoding="utf-8")
        return path

    def valid_request(self, **overrides) -> dict:
        data = {
            "project_id": "ai-workspace",
            "sprint_id": "sprint-019",
            "request_id": "req-001",
            "requested_by": "product_owner",
            "requested_action": "Review Sprint-019 implementation and produce codex_review.md",
            "target_actor": "codex",
            "risk_level": "low",
            "allowed_actions": ["review"],
            "forbidden_actions": [
                "shell_command", "auto_approval", "auto_handoff", "commit", "push", "closure",
            ],
            "input_artifact": "reviews/sprint-019/round-001/architecture.md",
            "expected_output_artifact": "reviews/sprint-019/round-001/codex_review.md",
            "evidence_reference": "reviews/sprint-019/round-001/claude_report.md",
            "requires_product_owner_approval": True,
            "created_at": "2026-07-09T00:00:00Z",
        }
        data.update(overrides)
        return data

    def valid_job(self, **overrides) -> dict:
        data = {
            "job_id": "job-001",
            "approval_request_id": "req-001",
            "approved_by": "product_owner",
            "approved_at": "2026-07-09T00:05:00Z",
            "product_owner_decision_reference": "reviews/sprint-019/round-001/architecture.md#section-28",
            "target_actor": "codex",
            "job_type": "review",
            "allowed_action": "Review Sprint-019 implementation",
            "input_artifact": "reviews/sprint-019/round-001/architecture.md",
            "expected_output_artifact": "reviews/sprint-019/round-001/codex_review.md",
            "safety_level": "low",
            "dry_run_required": True,
            "commit_allowed": False,
            "push_allowed": False,
            "closure_allowed": False,
            "auto_handoff_allowed": False,
            "shell_command_allowed": False,
            "created_at": "2026-07-09T00:05:00Z",
        }
        data.update(overrides)
        return data

    def run_cmd(self, argv: list[str]) -> tuple[int, str]:
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
            code = aeq.main(argv)
        return code, buf.getvalue()

    def audit_events(self) -> list[dict]:
        if not aeq.AUDIT_LOG.is_file():
            return []
        return [json.loads(line) for line in aeq.AUDIT_LOG.read_text().splitlines() if line.strip()]

    # -- 1-3: Approval Request ---------------------------------------------

    def test_01_valid_approval_request_passes_validation(self):
        path = self.write_md("req-valid.md", self.valid_request())
        code, out = self.run_cmd(["validate-request", str(path)])
        self.assertEqual(code, 0)
        self.assertIn("VALIDATION: PASS", out)

    def test_02_invalid_approval_request_fails_validation(self):
        data = self.valid_request()
        del data["risk_level"]
        path = self.write_md("req-invalid.md", data)
        code, out = self.run_cmd(["validate-request", str(path)])
        self.assertEqual(code, 1)
        self.assertIn("VALIDATION: FAIL", out)

    def test_03_approval_request_cannot_be_treated_as_approved_job(self):
        path = self.write_md("req-as-job.md", self.valid_request())
        code, out = self.run_cmd(["dry-run", str(path)])
        self.assertEqual(code, 1)
        self.assertIn("BLOCKED", out)
        self.assertIn("Approval Request", out)

    # -- 4-17: Approved Job Manifest ---------------------------------------

    def test_04_approved_job_manifest_with_po_approval_passes(self):
        path = self.write_md("job-valid.md", self.valid_job())
        code, out = self.run_cmd(["validate-approved-job", str(path)])
        self.assertEqual(code, 0)
        self.assertIn("VALIDATION: PASS", out)

    def test_05_manifest_without_po_approval_fails(self):
        data = self.valid_job(approved_by="")
        path = self.write_md("job-no-po.md", data)
        code, out = self.run_cmd(["validate-approved-job", str(path)])
        self.assertEqual(code, 1)
        self.assertIn("approval metadata missing", out)

    def test_06_manifest_shell_command_allowed_true_fails(self):
        path = self.write_md("job-shell.md", self.valid_job(shell_command_allowed=True))
        code, out = self.run_cmd(["validate-approved-job", str(path)])
        self.assertEqual(code, 1)
        self.assertIn("shell_command_allowed", out)

    def test_07_manifest_commit_allowed_true_fails(self):
        path = self.write_md("job-commit.md", self.valid_job(commit_allowed=True))
        code, out = self.run_cmd(["validate-approved-job", str(path)])
        self.assertEqual(code, 1)
        self.assertIn("commit_allowed", out)

    def test_08_manifest_push_allowed_true_fails(self):
        path = self.write_md("job-push.md", self.valid_job(push_allowed=True))
        code, out = self.run_cmd(["validate-approved-job", str(path)])
        self.assertEqual(code, 1)
        self.assertIn("push_allowed", out)

    def test_09_manifest_closure_allowed_true_fails(self):
        path = self.write_md("job-closure.md", self.valid_job(closure_allowed=True))
        code, out = self.run_cmd(["validate-approved-job", str(path)])
        self.assertEqual(code, 1)
        self.assertIn("closure_allowed", out)

    def test_10_manifest_auto_handoff_allowed_true_fails(self):
        path = self.write_md("job-handoff.md", self.valid_job(auto_handoff_allowed=True))
        code, out = self.run_cmd(["validate-approved-job", str(path)])
        self.assertEqual(code, 1)
        self.assertIn("auto_handoff_allowed", out)

    def test_11_manifest_forbidden_field_command_fails(self):
        data = self.valid_job()
        data["command"] = "rm -rf /"
        path = self.write_md("job-field-command.md", data)
        code, out = self.run_cmd(["validate-approved-job", str(path)])
        self.assertEqual(code, 1)
        self.assertIn("Forbidden field(s)", out)
        self.assertIn("command", out)

    def test_12_manifest_forbidden_field_shell_fails(self):
        data = self.valid_job()
        data["shell"] = "/bin/bash"
        path = self.write_md("job-field-shell.md", data)
        code, out = self.run_cmd(["validate-approved-job", str(path)])
        self.assertEqual(code, 1)
        self.assertIn("Forbidden field(s)", out)
        self.assertIn("shell", out)

    def test_13_manifest_forbidden_field_exec_fails(self):
        data = self.valid_job()
        data["exec"] = "true"
        path = self.write_md("job-field-exec.md", data)
        code, out = self.run_cmd(["validate-approved-job", str(path)])
        self.assertEqual(code, 1)
        self.assertIn("Forbidden field(s)", out)
        self.assertIn("exec", out)

    def test_14_manifest_unknown_target_actor_fails(self):
        path = self.write_md("job-bad-actor.md", self.valid_job(target_actor="random_actor"))
        code, out = self.run_cmd(["validate-approved-job", str(path)])
        self.assertEqual(code, 1)
        self.assertIn("target_actor", out)

    def test_15_manifest_unknown_job_type_fails(self):
        path = self.write_md("job-bad-type.md", self.valid_job(job_type="not_a_real_job_type"))
        code, out = self.run_cmd(["validate-approved-job", str(path)])
        self.assertEqual(code, 1)
        self.assertIn("job_type", out)

    def test_16_missing_input_artifact_fails(self):
        path = self.write_md(
            "job-missing-input.md",
            self.valid_job(input_artifact="reviews/does-not-exist/nope.md"),
        )
        code, out = self.run_cmd(["validate-approved-job", str(path)])
        self.assertEqual(code, 1)
        self.assertIn("input_artifact does not exist", out)

    def test_17_output_artifact_outside_allowed_directory_fails(self):
        path = self.write_md(
            "job-bad-output.md",
            self.valid_job(expected_output_artifact="scripts/hacked.py"),
        )
        code, out = self.run_cmd(["validate-approved-job", str(path)])
        self.assertEqual(code, 1)
        self.assertIn("outside allowed directory", out)

    # -- 18-21: Dry-run worker behavior -------------------------------------

    def test_18_dry_run_worker_produces_report(self):
        path = self.write_md("job-for-dryrun.md", self.valid_job())
        code, out = self.run_cmd(["dry-run", str(path)])
        self.assertEqual(code, 0)
        report_path = aeq.DRY_RUN_DIR / "job-001-dry-run-report.md"
        self.assertTrue(report_path.is_file())
        front_matter = aeq.parse_front_matter(report_path)
        for field in (
            "job_id", "validation_result", "would_execute", "target_actor",
            "job_type", "input_artifact", "expected_output_artifact",
            "blocked_reason", "dry_run_status", "created_at",
        ):
            self.assertIn(field, front_matter)
        self.assertTrue(front_matter["would_execute"])

    def test_19_dry_run_worker_does_not_execute_shell_command(self):
        source = (SCRIPT_DIR / "approved_execution_queue.py").read_text()
        for pattern in (r"subprocess\.(run|Popen|call)\(", r"os\.system\(", r"os\.popen\("):
            self.assertIsNone(
                re.search(pattern, source),
                f"Found forbidden shell-execution call matching {pattern!r}",
            )

    def test_20_dry_run_worker_does_not_call_claude_cli(self):
        source = (SCRIPT_DIR / "approved_execution_queue.py").read_text()
        self.assertNotIn("subprocess", source)
        self.assertNotRegex(source, r"claude[_\s]+code\s+cli\s*\(")

    def test_21_dry_run_worker_does_not_call_codex_cli(self):
        source = (SCRIPT_DIR / "approved_execution_queue.py").read_text()
        self.assertNotIn("subprocess", source)
        self.assertNotRegex(source, r"codex\s+cli\s*\(")

    # -- 22-23: Audit Trail ---------------------------------------------------

    def test_22_audit_trail_is_written(self):
        path = self.write_md("job-for-audit.md", self.valid_job())
        self.run_cmd(["validate-approved-job", str(path)])
        events = self.audit_events()
        self.assertTrue(len(events) >= 2)
        event_types = {e["event_type"] for e in events}
        self.assertIn("approved_job_manifest_created", event_types)
        self.assertIn("validator_passed", event_types)

    def test_23_audit_trail_does_not_contain_secrets(self):
        data = self.valid_job()
        data["token"] = "sk-super-secret-value-12345"
        path = self.write_md("job-with-secret.md", data)
        self.run_cmd(["validate-approved-job", str(path)])
        raw = aeq.AUDIT_LOG.read_text()
        self.assertNotIn("sk-super-secret-value-12345", raw)

    # -- 24-26: Notification / Live Push -------------------------------------

    def live_push_argv(self, **overrides) -> list[str]:
        base = {
            "--sprint-id": "sprint-019",
            "--round": "round-001",
            "--ref": "job-001",
            "--gate-type": "notification_validation",
            "--target-actor": "product_owner",
            "--risk-level": "low",
            "--next-step": "請確認收到本次推播",
            "--artifact-path": "reviews/approved-execution-queue/dry-run/job-001-dry-run-report.md",
            "--audit-reference": "reviews/approved-execution-queue/audit/audit.jsonl",
            "--dry-run-status": "would-execute",
        }
        base.update(overrides)
        argv = ["live-push"]
        for key, value in base.items():
            argv.extend([key, value])
        return argv

    def test_24_notification_artifact_is_created(self):
        import os
        os.environ.pop("NOTIFICATION_ENABLED", None)
        os.environ.pop("TELEGRAM_BOT_TOKEN", None)
        os.environ.pop("TELEGRAM_CHAT_ID", None)
        self.run_cmd(self.live_push_argv())
        artifact = self.reviews_dir / "sprint-019" / "round-001" / "notifications" / "job-001-live-push.md"
        self.assertTrue(artifact.is_file())

    def test_25_disabled_delivery_cannot_pass_po_validation(self):
        import os
        os.environ.pop("NOTIFICATION_ENABLED", None)
        os.environ.pop("TELEGRAM_BOT_TOKEN", None)
        os.environ.pop("TELEGRAM_CHAT_ID", None)
        code, out = self.run_cmd(self.live_push_argv())
        self.assertEqual(code, 1)
        self.assertIn("disabled", out)
        self.assertIn("cannot pass until live push delivery is fixed", out)
        history_lines = aeq.NOTIFICATION_HISTORY.read_text().splitlines()
        record = json.loads(history_lines[-1])
        self.assertEqual(record["delivery_status"], "disabled")

    def test_26_delivered_delivery_required_for_po_validation(self):
        import os
        with mock.patch.dict(
            os.environ,
            {"NOTIFICATION_ENABLED": "true", "TELEGRAM_BOT_TOKEN": "tok", "TELEGRAM_CHAT_ID": "1"},
        ):
            with mock.patch.object(aeq, "_post_telegram_message", return_value=(True, "")):
                code, out = self.run_cmd(self.live_push_argv())
        self.assertEqual(code, 0)
        self.assertIn("delivered", out)
        history_lines = aeq.NOTIFICATION_HISTORY.read_text().splitlines()
        record = json.loads(history_lines[-1])
        self.assertEqual(record["delivery_status"], "delivered")
        events = self.audit_events()
        event_types = {e["event_type"] for e in events}
        self.assertIn("live_push_delivered", event_types)

    # -- 27-30: Safety boundaries ---------------------------------------------

    def test_27_configs_n8n_remains_unchanged(self):
        n8n_dir = aeq.REPO_ROOT / "configs" / "n8n"

        def hash_dir(d: Path) -> str:
            digest = hashlib.sha256()
            for f in sorted(d.rglob("*")):
                if f.is_file():
                    digest.update(f.read_bytes())
            return digest.hexdigest()

        before = hash_dir(n8n_dir)

        # Run a representative slice of the CLI surface.
        req_path = self.write_md("req.md", self.valid_request())
        job_path = self.write_md("job.md", self.valid_job())
        self.run_cmd(["validate-request", str(req_path)])
        self.run_cmd(["validate-approved-job", str(job_path)])
        self.run_cmd(["dry-run", str(job_path)])
        import os
        os.environ.pop("NOTIFICATION_ENABLED", None)
        self.run_cmd(self.live_push_argv())

        after = hash_dir(n8n_dir)
        self.assertEqual(before, after, "configs/n8n must remain unchanged")

    def test_28_no_commit_automation_exists(self):
        source = (SCRIPT_DIR / "approved_execution_queue.py").read_text()
        self.assertNotRegex(source, r"git\s+commit")
        self.assertNotRegex(source, r"git\s+add\s")

    def test_29_no_push_automation_exists(self):
        source = (SCRIPT_DIR / "approved_execution_queue.py").read_text()
        self.assertNotRegex(source, r"git\s+push")

    def test_30_no_callback_execution_exists(self):
        source = (SCRIPT_DIR / "approved_execution_queue.py").read_text()
        self.assertNotIn("subprocess", source)
        self.assertNotIn("os.system(", source)
        self.assertNotIn("os.popen(", source)
        self.assertNotIn("eval(", source)
        self.assertNotIn("exec(", source)

    # -- 31-36: Sprint-019 Must Fix Round 2 (section-aware live push split,
    #           CLI-based Product Owner decision recording) ----------------

    def _live_push_messages(self):
        argv = self.live_push_argv()
        parser = aeq.build_parser()
        args = parser.parse_args(argv)
        notif_dir = aeq.REVIEWS_DIR / args.sprint_id / args.round / "notifications"
        artifact_path = notif_dir / "job-001-live-push.md"
        handoff_path = notif_dir / "job-001-codex-handoff.md"
        created_at = aeq.now_iso()
        codex_handoff = aeq._build_codex_handoff_block()
        return aeq._build_live_push_messages(args, artifact_path, handoff_path, created_at, codex_handoff)

    def test_31_codex_handoff_split_into_independent_message(self):
        message1, message2, message3 = self._live_push_messages()
        self.assertNotEqual(message1, message2)
        self.assertNotEqual(message2, message3)
        self.assertTrue(message2.startswith("===== BEGIN COPY TO CODEX REVIEW ====="))
        self.assertTrue(message2.rstrip().endswith("===== END COPY TO CODEX REVIEW ====="))

    def test_32_handoff_message_contains_only_copy_block(self):
        _, message2, _ = self._live_push_messages()
        # Nothing before BEGIN or after END.
        begin = "===== BEGIN COPY TO CODEX REVIEW ====="
        end = "===== END COPY TO CODEX REVIEW ====="
        self.assertEqual(message2.find(begin), 0)
        self.assertEqual(message2.rstrip(), message2.rstrip()[: message2.rstrip().rfind(end) + len(end)])

    def test_33_po_summary_not_mixed_into_handoff_message(self):
        _, message2, _ = self._live_push_messages()
        self.assertNotIn("Product Owner 現在要做什麼", message2)
        self.assertNotIn("🔔", message2)
        self.assertNotIn("🗳️", message2)

    def test_34_evidence_reference_not_mixed_into_handoff_message(self):
        _, message2, _ = self._live_push_messages()
        self.assertNotIn("📎 Evidence Reference", message2)
        self.assertNotIn("Audit Reference:", message2)

    def test_35_notification_metadata_not_mixed_into_handoff_message(self):
        _, message2, _ = self._live_push_messages()
        self.assertNotIn("🧾 Notification / Audit Reference", message2)
        self.assertNotIn("notification_package_path:", message2)
        self.assertNotIn("delivery_status", message2)

    def test_36_record_po_decision_no_callback_transport_exists(self):
        source = (SCRIPT_DIR / "approved_execution_queue.py").read_text()
        # No callback/button transport exists at all (no Flask/webhook/bot
        # polling library, no inline keyboard payload) -- record-po-decision
        # is a Product-Owner-run CLI command only.
        self.assertNotIn("InlineKeyboard", source)
        self.assertNotIn("reply_markup", source)
        self.assertNotIn("callback_query", source)

    def approve_argv(self, **overrides) -> list[str]:
        handoff_fixture = self.fixtures_dir / "codex-handoff.md"
        if not handoff_fixture.exists():
            handoff_fixture.write_text(
                "===== BEGIN COPY TO CODEX REVIEW =====\nfixture\n===== END COPY TO CODEX REVIEW =====\n",
                encoding="utf-8",
            )
        base = {
            "--sprint-id": "sprint-019",
            "--ref": "job-002",
            "--decision": "approve",
            "--target-actor": "codex",
            "--job-type": "review",
            "--allowed-action": "Review Sprint-019 implementation and produce codex_review.md",
            "--input-artifact": "reviews/sprint-019/round-001/architecture.md",
            "--expected-output-artifact": "reviews/sprint-019/round-001/codex_review.md",
            "--safety-level": "low",
            "--handoff-package-path": str(handoff_fixture),
        }
        base.update(overrides)
        argv = ["record-po-decision"]
        for key, value in base.items():
            argv.extend([key, value])
        return argv

    def test_37_approve_writes_valid_approved_job_manifest(self):
        code, out = self.run_cmd(self.approve_argv())
        self.assertEqual(code, 0)
        self.assertIn("product_owner_decision_recorded", out)
        self.assertIn("Approved Job Manifest written", out)

        manifest_path = aeq.APPROVED_DIR / "job-002.md"
        self.assertTrue(manifest_path.is_file())
        data = aeq.parse_front_matter(manifest_path)
        passed, reasons = aeq.validate_approved_job(data)
        self.assertTrue(passed, reasons)
        self.assertEqual(data["approved_by"], "product_owner")
        self.assertFalse(data["commit_allowed"])
        self.assertFalse(data["shell_command_allowed"])

        events = self.audit_events()
        event_types = {e["event_type"] for e in events}
        self.assertIn("product_owner_decision_recorded", event_types)
        self.assertIn("approved_job_manifest_created", event_types)

        # Must Fix Round 3: descriptive fields Product Owner asked to see.
        self.assertEqual(data["next_ai"], "Codex Review")
        self.assertTrue(data["handoff_package_path"])
        self.assertEqual(data["source_artifact_path"], data["input_artifact"])
        self.assertIn("audit.jsonl", data["audit_reference"])
        self.assertEqual(data["status"], "approved")

    def test_38_reject_writes_no_manifest_only_audit_event(self):
        code, out = self.run_cmd(
            ["record-po-decision", "--sprint-id", "sprint-019", "--ref", "job-003", "--decision", "reject"]
        )
        self.assertEqual(code, 0)
        self.assertFalse((aeq.APPROVED_DIR / "job-003.md").exists())

        events = self.audit_events()
        matching = [e for e in events if e["event_type"] == "product_owner_decision_recorded"]
        self.assertEqual(len(matching), 1)
        self.assertEqual(matching[0]["status"], "reject")
        self.assertNotIn("approved_job_manifest_created", {e["event_type"] for e in events})

    def test_39_approve_missing_fields_fails_loudly(self):
        code, out = self.run_cmd(
            ["record-po-decision", "--sprint-id", "sprint-019", "--ref", "job-004", "--decision", "approve"]
        )
        self.assertNotEqual(code, 0)
        self.assertIn("requires:", out)
        self.assertFalse((aeq.APPROVED_DIR / "job-004.md").exists())

    def test_40_invalid_decision_value_rejected(self):
        import os

        code, out = self.run_cmd(
            ["record-po-decision", "--sprint-id", "sprint-019", "--ref", "job-001", "--decision", "maybe"]
        )
        self.assertNotEqual(code, 0)
        raw = aeq.AUDIT_LOG.read_text() if aeq.AUDIT_LOG.is_file() else ""
        self.assertNotIn("TELEGRAM_BOT_TOKEN", raw)
        self.assertNotIn(os.environ.get("TELEGRAM_BOT_TOKEN", "__unset__"), raw)

    def test_41_consume_approved_only_dry_runs_approved_directory(self):
        # Put a request-shaped file directly in approved/ by hand (simulating
        # an operator mistake) -- consume-approved must still only ever
        # dry-run it (which blocks it, since it's not approved-shaped), and
        # must never read requests/ at all.
        self.run_cmd(self.approve_argv())
        aeq.REQUESTS_DIR.mkdir(parents=True, exist_ok=True)
        (aeq.REQUESTS_DIR / "should-be-ignored.md").write_text(
            "---\nrequest_id: r-1\n---\nshould never be touched\n", encoding="utf-8"
        )

        code, out = self.run_cmd(["consume-approved"])
        self.assertEqual(code, 0)
        self.assertIn("job-002.md", out)
        self.assertNotIn("should-be-ignored", out)

        dry_run_reports = list(aeq.DRY_RUN_DIR.glob("*.md"))
        self.assertTrue(any("job-002" in p.name for p in dry_run_reports))

    def test_42_consume_approved_never_calls_real_cli(self):
        source = (SCRIPT_DIR / "approved_execution_queue.py").read_text()
        self.assertNotIn("subprocess", source)
        self.assertNotIn("os.system(", source)
        self.run_cmd(self.approve_argv())
        code, out = self.run_cmd(["consume-approved"])
        self.assertEqual(code, 0)
        self.assertIn("would-execute", out)

    def test_43_no_daemon_or_scheduler_exists(self):
        source = (SCRIPT_DIR / "approved_execution_queue.py").read_text()
        # consume-approved must be a one-shot CLI command, never a
        # scheduled/looping background process.
        self.assertNotIn("while True", source)
        self.assertNotIn("schedule.", source)
        self.assertNotIn("threading.Timer", source)
        self.assertNotIn("apscheduler", source)

    # -- 44-46: Must Fix Round 3 (standalone Codex Handoff file, full loop) --

    def test_44_live_push_writes_standalone_handoff_file(self):
        import os

        os.environ.pop("NOTIFICATION_ENABLED", None)
        self.run_cmd(self.live_push_argv())
        handoff_path = self.reviews_dir / "sprint-019" / "round-001" / "notifications" / "job-001-codex-handoff.md"
        self.assertTrue(handoff_path.is_file())
        content = handoff_path.read_text()
        self.assertTrue(content.startswith("===== BEGIN COPY TO CODEX REVIEW ====="))
        self.assertTrue(content.rstrip().endswith("===== END COPY TO CODEX REVIEW ====="))
        # Byte-identical to Telegram Message 2 -- not a re-summarized copy.
        _, message2, _ = self._live_push_messages()
        self.assertEqual(content, message2)

    def test_45_approve_rejects_nonexistent_handoff_package_path(self):
        code, out = self.run_cmd(
            self.approve_argv(**{"--handoff-package-path": str(self.tmp / "does-not-exist.md")})
        )
        self.assertNotEqual(code, 0)
        self.assertIn("does not exist", out)
        self.assertFalse((aeq.APPROVED_DIR / "job-002.md").exists())

    def test_46_full_loop_live_push_to_consume_approved(self):
        import os

        os.environ.pop("NOTIFICATION_ENABLED", None)
        self.run_cmd(self.live_push_argv(**{"--ref": "job-005"}))
        handoff_path = self.reviews_dir / "sprint-019" / "round-001" / "notifications" / "job-005-codex-handoff.md"
        self.assertTrue(handoff_path.is_file())

        code, out = self.run_cmd(
            self.approve_argv(**{"--ref": "job-005", "--handoff-package-path": str(handoff_path)})
        )
        self.assertEqual(code, 0)

        manifest_path = aeq.APPROVED_DIR / "job-005.md"
        data = aeq.parse_front_matter(manifest_path)
        self.assertEqual(data["handoff_package_path"], str(handoff_path))

        code, out = self.run_cmd(["consume-approved"])
        self.assertEqual(code, 0)
        self.assertIn("job-005.md", out)
        self.assertIn("would-execute", out)

    # -- 47-48: Codex Review Must Fix (live-push artifact must actually
    #           carry the Round 3 --handoff-package-path closed loop,
    #           not just the manifest side) ---------------------------------

    def test_47_live_push_message1_includes_handoff_package_path_flag(self):
        message1, _, _ = self._live_push_messages()
        self.assertIn("--handoff-package-path", message1)

    def test_48_live_push_artifact_front_matter_includes_handoff_package_path(self):
        import os

        os.environ.pop("NOTIFICATION_ENABLED", None)
        self.run_cmd(self.live_push_argv())
        artifact_path = self.reviews_dir / "sprint-019" / "round-001" / "notifications" / "job-001-live-push.md"
        front_matter = aeq.parse_front_matter(artifact_path)
        self.assertIn("handoff_package_path", front_matter)
        handoff_path = Path(front_matter["handoff_package_path"])
        self.assertTrue(handoff_path.is_file())


if __name__ == "__main__":
    unittest.main(verbosity=2)
