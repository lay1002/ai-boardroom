# Approval Request Schema（Sprint-019）

## 1. 定位

Approval Request 是「請求核准」，**不是**「已核准」。它存放在 `reviews/approved-execution-queue/requests/`，且**不得**被 dry-run worker 當作 Approved Job Manifest 執行——`scripts/approved_execution_queue.py dry-run` 會偵測並直接拒絕。

格式採用 Markdown + YAML Front Matter：

```markdown
---
project_id: ai-workspace
sprint_id: sprint-019
request_id: req-001
requested_by: product_owner
requested_action: "Review Sprint-019 implementation and produce codex_review.md"
target_actor: codex
risk_level: low
allowed_actions:
  - review
forbidden_actions:
  - shell_command
  - auto_approval
  - auto_handoff
  - commit
  - push
  - closure
input_artifact: reviews/sprint-019/round-001/architecture.md
expected_output_artifact: reviews/sprint-019/round-001/codex_review.md
evidence_reference: reviews/sprint-019/round-001/claude_report.md
requires_product_owner_approval: true
created_at: "2026-07-09T00:00:00Z"
---

# Approval Request req-001

（此處為人類可讀說明，非驗證依據）
```

## 2. 必填欄位

| 欄位 | 說明 |
|---|---|
| `project_id` | 專案識別碼 |
| `sprint_id` | Sprint 識別碼 |
| `request_id` | 本請求的唯一識別碼 |
| `requested_by` | 提出請求的角色 |
| `requested_action` | 請求的動作描述（不得是 shell command，見第 4 節） |
| `target_actor` | 見第 3 節白名單 |
| `risk_level` | 風險等級（自由文字，建議 low/medium/high） |
| `allowed_actions` | 允許的動作清單 |
| `forbidden_actions` | 必須包含第 5 節六個固定值 |
| `input_artifact` | 輸入 artifact 的 repo 相對路徑，必須實際存在 |
| `expected_output_artifact` | 預期輸出路徑，必須位於 `reviews/` 之下 |
| `evidence_reference` | 佐證資料路徑 |
| `requires_product_owner_approval` | 必須為 `true` |
| `created_at` | 建立時間 |

## 3. `target_actor` 白名單

`chatgpt`、`claude_code`、`codex`、`product_owner`。其他值一律驗證失敗。

## 4. `requested_action` 不得是 shell command

Validator 使用一個**啟發式、模式比對（pattern-based）的黑名單**，偵測 shell 運算子（`&&`、`||`、`;`、`|`、`` ` ``、`$()`）與常見可執行指令前綴（`sudo`、`rm`、`chmod`、`curl`、`wget`、`python`、`bash`、`sh`、`./`、`git`、`npm`、`pip`）。

**已知限制**：這不是完整的 shell 語法解析器，只能攔截明顯像 shell 呼叫的字串；`requested_action` 應該用一句自然語言描述「要做什麼」，而不是任何形式的指令列。

## 5. `forbidden_actions` 固定要求

必須包含：`shell_command`、`auto_approval`、`auto_handoff`、`commit`、`push`、`closure`。缺少任何一項，validator 判定失敗。

## 6. 禁止欄位

與 Approved Job Manifest 相同（見 [approved-job-manifest-schema.md](approved-job-manifest-schema.md) 第 4 節），Validator 對 Approval Request 也會遞迴掃描是否出現 `command / shell / exec / script / args / token / credential / secret / password / api_key`，作為縱深防禦。

## 7. Validator 指令

```bash
python scripts/approved_execution_queue.py validate-request reviews/approved-execution-queue/requests/<file>.md
```

Exit code `0` 表示 `VALIDATION: PASS`；`1` 表示 `VALIDATION: FAIL`，並在 stdout 列出明確的 blocked reasons。
