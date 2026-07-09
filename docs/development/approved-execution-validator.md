# Approved Execution Validator（Sprint-019）

實作於 `scripts/approved_execution_queue.py`（函式 `validate_request` / `validate_approved_job`）。

## 1. 17 項檢查對照表

| # | 檢查項目 | 適用對象 | 實作位置 |
|---|---|---|---|
| 1 | Markdown Front Matter 是否存在 | 兩者 | `parse_front_matter` |
| 2 | 必填欄位是否完整 | 兩者 | `_missing_fields` |
| 3 | `target_actor` 是否在白名單 | 兩者 | `ALLOWED_TARGET_ACTORS` |
| 4 | `job_type` 是否在白名單 | Approved Job Manifest | `ALLOWED_JOB_TYPES` / `FORBIDDEN_JOB_TYPES` |
| 5 | Product Owner approval metadata 是否存在 | Approved Job Manifest | `approved_by` / `approved_at` / `product_owner_decision_reference` |
| 6 | shell command 是否被禁止 | 兩者 | Request: `is_shell_like(requested_action)`；Job: `shell_command_allowed` 必須為 `false` |
| 7 | commit 是否被禁止 | 兩者 | Request: `forbidden_actions` 含 `commit`；Job: `commit_allowed` 必須為 `false` |
| 8 | push 是否被禁止 | 兩者 | 同上，`push` / `push_allowed` |
| 9 | closure 是否被禁止 | 兩者 | 同上，`closure` / `closure_allowed` |
| 10 | auto handoff 是否被禁止 | 兩者 | 同上，`auto_handoff` / `auto_handoff_allowed` |
| 11 | auto approval 是否被禁止 | Approval Request | `forbidden_actions` 含 `auto_approval`；Approved Job 則以 `approved_by` 存在證明已核准 |
| 12 | forbidden field 是否出現 | 兩者 | `collect_forbidden_fields`（遞迴掃描） |
| 13 | `input_artifact` 是否存在 | 兩者 | 檔案系統存在性檢查（相對 repo root） |
| 14 | `expected_output_artifact` 是否位於允許目錄 | 兩者 | 必須以 `reviews/` 開頭 |
| 15 | 是否沒有 secret / token / credential | 兩者 | 與 #12 共用同一個遞迴掃描 |
| 16 | 是否沒有任意 command 欄位 | 兩者 | 與 #12 共用同一個遞迴掃描 |
| 17 | validation fail 時是否有明確 blocked reason | 兩者 | 每個失敗檢查都會附加一則人類可讀的原因字串，CLI 以 `Blocked reasons:` 條列輸出 |

## 2. Validator 絕不會做的事

- 不執行 shell command（模組完全不 import `subprocess`，也沒有 `os.system` / `os.popen` 呼叫）。
- 不呼叫 Claude CLI 或 Codex CLI。
- 不 commit、不 push、不 closure。
- 不自動建立 approved job（validator 只讀取既有檔案，從不寫入 `approved/`）。
- 不自動呼叫下一個 AI。

這些保證由 `scripts/test_approved_execution_queue.py` 的第 19-21、28-30 項測試直接對原始碼掃描驗證，而非僅靠文件宣稱。

## 3. CLI

```bash
python scripts/approved_execution_queue.py validate-request <path>
python scripts/approved_execution_queue.py validate-approved-job <path>
python scripts/approved_execution_queue.py dry-run <path>
```

Exit code：`0` = PASS，`1` = FAIL / BLOCKED。所有失敗都會在 stdout 印出明確原因，並寫入 audit trail（`validator_executed` → `validator_passed` 或 `validator_failed`）。

## 4. 已知限制

- `requested_action` 的 shell-like 偵測是模式比對黑名單，不是完整的 shell 語法解析器（見 [approval-request-schema.md](approval-request-schema.md) 第 4 節）。
- `risk_level` / `safety_level` 目前只檢查「是否存在」，不限制具體取值——Architecture 並未要求這兩個欄位有固定白名單，Validator 因此沒有額外發明限制範圍之外的規則。
