# Approved Job Manifest Schema（Sprint-019）

## 1. 定位

Approved Job Manifest 是 Product Owner **明確核准後**才可能存在的資料描述。它**不是** shell script，**不是** command wrapper。存放於 `reviews/approved-execution-queue/approved/`，是唯一可以被 dry-run worker 處理的檔案類型。

格式採用 Markdown + YAML Front Matter：

```markdown
---
job_id: job-001
approval_request_id: req-001
approved_by: product_owner
approved_at: "2026-07-09T00:05:00Z"
product_owner_decision_reference: reviews/sprint-019/round-001/architecture.md#section-28
target_actor: codex
job_type: review
allowed_action: "Review Sprint-019 implementation"
input_artifact: reviews/sprint-019/round-001/architecture.md
expected_output_artifact: reviews/sprint-019/round-001/codex_review.md
safety_level: low
dry_run_required: true
commit_allowed: false
push_allowed: false
closure_allowed: false
auto_handoff_allowed: false
shell_command_allowed: false
created_at: "2026-07-09T00:05:00Z"
---

# Approved Job Manifest job-001
```

## 2. 必填欄位

`job_id`、`approval_request_id`、`approved_by`、`approved_at`、`product_owner_decision_reference`、`target_actor`、`job_type`、`allowed_action`、`input_artifact`、`expected_output_artifact`、`safety_level`、`dry_run_required`、`commit_allowed`、`push_allowed`、`closure_allowed`、`auto_handoff_allowed`、`shell_command_allowed`、`created_at`。

`approved_by`、`approved_at`、`product_owner_decision_reference` 三者合稱「Product Owner approval metadata」，任一缺漏，validator 判定失敗。

## 3. 固定限制（不可協商）

以下六個欄位值是**固定的**，Approved Job Manifest 只要偏離就會被拒絕：

| 欄位 | 固定值 |
|---|---|
| `dry_run_required` | `true` |
| `commit_allowed` | `false` |
| `push_allowed` | `false` |
| `closure_allowed` | `false` |
| `auto_handoff_allowed` | `false` |
| `shell_command_allowed` | `false` |

這是 Sprint-019 的核心安全設計：即使 Product Owner 核准了一個 job，這個 job 也永遠只能被 dry-run，永遠不能真的 commit / push / closure / 執行 shell / 自動 handoff。

## 4. 禁止欄位

Manifest 中**任何位置**（遞迴掃描，不只 top-level）只要出現以下鍵名（不分大小寫），validator 一律拒絕：

`command`、`shell`、`exec`、`script`、`args`、`token`、`credential`、`secret`、`password`、`api_key`

## 5. `job_type` 白名單 / 黑名單

**允許**：`review`、`implementation_handoff`、`fix_handoff`、`validation_handoff`、`notification_validation`、`dry_run_only`

**禁止**（即使不在允許清單中也會被 forbidden 清單明確攔截並給出對應訊息）：`shell_execution`、`claude_cli_execution`、`codex_cli_execution`、`commit`、`push`、`closure`、`telegram_callback_execution`、`line_callback_execution`

## 6. `target_actor` 白名單

`chatgpt`、`claude_code`、`codex`、`product_owner`。

## 7. `input_artifact` 與 `expected_output_artifact`

- `input_artifact`：必須是實際存在於 repo 內的檔案路徑（相對於 repo root）。
- `expected_output_artifact`：必須位於 `reviews/` 目錄之下。指向 `scripts/`、`configs/`、repo root 或任何 `reviews/` 以外的路徑一律拒絕——因為所有真實動作（commit/push/closure/shell）都已被第 3 節的固定限制封死，`expected_output_artifact` 只可能是一份審閱/交接文件，沒有理由指向程式碼或設定檔位置。

## 8. Validator 指令

```bash
python scripts/approved_execution_queue.py validate-approved-job reviews/approved-execution-queue/approved/<file>.md
```

## 9. Dry-run 指令

```bash
python scripts/approved_execution_queue.py dry-run reviews/approved-execution-queue/approved/<file>.md
```

validator 通過時輸出 `would-execute` 的模擬報告；未通過時輸出 `blocked` 報告，兩者都寫入 `reviews/approved-execution-queue/dry-run/` 與 audit trail，但都**不會**執行任何真實動作。

## 10. 補充欄位（Sprint-019 Must Fix Round 3，非本文件第 2 節必填欄位）

當 manifest 是由 `record-po-decision --decision approve`（見 [approved-execution-queue.md](approved-execution-queue.md) 第 5a 節）產生時，會額外包含 `next_ai`、`handoff_package_path`、`source_artifact_path`、`audit_reference`、`status` 五個描述性欄位。這些欄位**不是** Architecture Section 9 的必填欄位，也不影響第 2-7 節任何驗證規則——手動撰寫的 manifest 不需要包含它們也能通過 validator。詳細定義見 `approved-execution-queue.md` 第 5a.1 節。
