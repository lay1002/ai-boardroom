# Sprint-019 Architecture Artifact

## 1. Artifact Metadata

Project：

AI Workspace

Sprint：

Sprint-019

Sprint Name：

Product Owner Approved Execution Queue MVP

中文名稱：

Product Owner 核准式執行佇列 MVP

Artifact Type：

Architecture Artifact

Status：

Approved by Product Owner (see Section 28)

Previous Sprint：

Sprint-018 CLOSED

Next Phase After Approval：

Claude Code Implementation

---

## 2. Architecture Intent

Sprint-019 的目標是建立一個安全、
檔案式、可稽核的 Product Owner
Approved Execution Queue MVP。

本 Sprint 要解決的核心問題是：

Product Owner 明確核准後，
才可以產生 approved job manifest。

approved job manifest 必須經 validator 驗證。

dry-run worker 只能產生模擬執行 evidence。

dry-run worker 不得真實執行：

Claude CLI

Codex CLI

shell command

commit

push

closure

Sprint-019 不是完整 automation platform。

Sprint-019 不是完整 workflow engine。

Sprint-019 不是 AI Decision Assistant 主產品功能。

它只是 AI Workspace 在 Sprint-020
收斂為 Workflow v1.0 前的流程安全補強。

---

## 3. Mandatory Live Push Requirement

Sprint-019 有一個硬性驗收條件：

Product Owner 必須在 Sprint-019 workflow 內
實際收到 live push。

而且 notification_history.jsonl 必須記錄：

delivery_status=delivered

如果 Product Owner 沒有收到推播，
或只有 delivery_status=disabled，
Sprint-019 不得驗收。

若 live push 未完成：

Product Owner Validation = FAIL

不得進入 Git Review。

不得 Commit。

不得 Push。

不得 Closure。

必須在 Sprint-019 內修到完成，
才可以結案。

---

## 4. Architecture Scope

### 4.1 In Scope

Sprint-019 必須完成：

1. Approval Request Schema
2. Approved Job Manifest Schema
3. Queue Directory Structure
4. Markdown Front Matter Schema
5. Product Owner Live Push Validation Checklist
6. Validator
7. Dry-run Worker
8. Audit Trail
9. Notification Artifact
10. Mandatory Live Push Validation
11. Safety Rule Documentation
12. Test Cases
13. Sprint-019 review / validation / git gate artifacts

### 4.2 Out of Scope

Sprint-019 不得包含：

1. 不做 Telegram callback 真實串接。
2. 不做 LINE callback 真實串接。
3. 不做真實 Claude CLI 自動執行。
4. 不做真實 Codex CLI 自動執行。
5. 不做 Commit automation。
6. 不做 Push automation。
7. 不修改 configs/n8n/*.json。
8. 不讓 AI 自動產生 approved job。
9. 不讓 Telegram / LINE button 直接觸發 shell command。
10. 不做長期 worker daemon。
11. 不做 multi-tenant queue。
12. 不做完整 workflow engine。
13. 不回頭修改 Sprint-018 已 push commit。

---

## 5. Canonical Full Reading List

Claude Code implementation 前必須閱讀以下上下文：

1. AGENTS.md
2. CLAUDE.md
3. CODEX.md
4. GPT.md
5. PROJECT_BOOTSTRAP.md
6. Sprint-019 Architecture Definition
7. 本 Sprint-019 Architecture Artifact
8. Sprint-018 Retrospective / Actual Flow Report
9. Sprint-018 Final Commit：7b803a0 Sprint-018: complete PO gate operation UX
10. reviews/sprint-018/round-001/codex_final_review_round_6.md
11. reviews/sprint-018/round-001/codex_git_review_supplement.md
12. docs/development/telegram-po-gate-notification-specification.md
13. docs/development/consensus-workflow.md
14. docs/development/product-owner-gate-operation-ux.md
15. scripts/review_bridge.sh
16. scripts/test_review_bridge.sh

若任一檔案不存在，Claude Code 必須在 implementation report 中列出。不得自行假設。

Claude Code 必須特別確認：

1. AI Workspace 是開發流程工具，不是 AI Decision Assistant 主產品。
2. Sprint-019 不得擴張成完整 automation platform。
3. Product Owner 保留所有關鍵 Gate 最終決策權。
4. Claude Code 不得自動呼叫 Codex。
5. Codex 不得自動呼叫 Claude。
6. AI 不得自動 commit。
7. AI 不得自動 push。
8. AI 不得自動 Closure。
9. Telegram / LINE 不得直接觸發 shell command。
10. Sprint-020 後 AI Workspace 應收斂為 Workflow v1.0。

---

## 6. Context Completeness Check

Claude Code 開始 implementation 前必須確認：

1. Sprint-018 已 CLOSED。
2. Sprint-019 Architecture Definition 已由 Product Owner 核准。
3. Sprint-019 Architecture Artifact 必須由 Product Owner 核准後，才可 implementation。
4. 本 Sprint 不得修改 Sprint-018 已 push commit。
5. 本 Sprint 不得修改 configs/n8n/*.json。
6. 本 Sprint 必須完成 live push validation。
7. delivery_status=disabled 不能作為 Sprint-019 Product Owner Validation PASS。
8. Product Owner 必須實際收到 workflow-generated live push。
9. 若 live push 未 delivered，Sprint-019 必須留在 Must Fix 狀態。

---

## 7. Queue Directory Contract

Sprint-019 採用 file-based queue。必須建立以下目錄：

- reviews/approved-execution-queue/requests/
- reviews/approved-execution-queue/approved/
- reviews/approved-execution-queue/dry-run/
- reviews/approved-execution-queue/audit/

目錄用途：

- **requests/**：存放 approval request draft。不得被 worker 視為 approved job。
- **approved/**：只存放 Product Owner 明確核准後的 approved job manifest。
- **dry-run/**：只存放 dry-run worker 結果。不得存放真實執行結果。
- **audit/**：存放 append-only audit records。不得覆蓋既有紀錄。

基本規則：

1. requests/ 內檔案不得被執行。
2. approved/ 內 manifest 必須有 Product Owner approval metadata。
3. dry-run/ 只能記錄模擬執行。
4. audit/ 必須 append-only。
5. 任一檔案不得包含 secret、token、credential。

---

## 8. Approval Request Schema

Approval Request 是「請求核准」，不是「已核准」。格式採用 Markdown + YAML Front Matter。

必填欄位：project_id, sprint_id, request_id, requested_by, requested_action, target_actor, risk_level, allowed_actions, forbidden_actions, input_artifact, expected_output_artifact, evidence_reference, requires_product_owner_approval: true, created_at

Validation rules：

1. requires_product_owner_approval 必須為 true。
2. requested_action 不得是 shell command。
3. target_actor 必須在白名單內。
4. forbidden_actions 必須包含：shell_command, auto_approval, auto_handoff, commit, push, closure
5. Approval Request 不得被 dry-run worker 當作 approved job 執行。

Allowed target_actor：chatgpt, claude_code, codex, product_owner

---

## 9. Approved Job Manifest Schema

Approved Job Manifest 是 Product Owner 明確核准後才可產生的資料描述。它不是 shell script，不是 command wrapper。格式採用 Markdown + YAML Front Matter。

必填欄位：job_id, approval_request_id, approved_by, approved_at, product_owner_decision_reference, target_actor, job_type, allowed_action, input_artifact, expected_output_artifact, safety_level, dry_run_required: true, commit_allowed: false, push_allowed: false, closure_allowed: false, auto_handoff_allowed: false, shell_command_allowed: false, created_at

固定限制：dry_run_required=true, commit_allowed=false, push_allowed=false, closure_allowed=false, auto_handoff_allowed=false, shell_command_allowed=false

Approved Job Manifest 不得包含：command, shell, exec, script, args, token, credential, secret, password, api_key。只要出現上述欄位，validator 必須拒絕。

Allowed job_type：review, implementation_handoff, fix_handoff, validation_handoff, notification_validation, dry_run_only

Forbidden job_type：shell_execution, claude_cli_execution, codex_cli_execution, commit, push, closure, telegram_callback_execution, line_callback_execution

---

## 10. Validator Requirements

Validator 是 Sprint-019 的安全核心。實作檔案：scripts/approved_execution_queue.py

CLI：

```
python scripts/approved_execution_queue.py validate-request <path>
python scripts/approved_execution_queue.py validate-approved-job <path>
python scripts/approved_execution_queue.py dry-run <path>
```

Validator 必須檢查（17 項，詳見 docs/development/approved-execution-validator.md）。

Validator 不得：執行 shell command、呼叫 Claude CLI、呼叫 Codex CLI、commit、push、closure、自動建立 approved job、自動呼叫下一個 AI。

---

## 11. Dry-run Worker Requirements

Dry-run Worker 只模擬執行：讀取 approved job manifest → 執行 validator → fail 時輸出 blocked dry-run report，pass 時輸出 would-execute dry-run report → 寫入 dry-run artifact → 寫入 audit record。

Dry-run report 必須包含：job_id, validation_result, would_execute, target_actor, job_type, input_artifact, expected_output_artifact, blocked_reason, dry_run_status, created_at

Dry-run worker 不得：呼叫 Claude CLI、呼叫 Codex CLI、執行 shell command、commit、push、closure、auto handoff、auto approval。

---

## 12. Audit Trail Requirements

Audit Trail 必須 append-only。路徑：reviews/approved-execution-queue/audit/audit.jsonl

每筆記錄至少包含：event_id, event_type, project_id, sprint_id, job_id, request_id, actor, status, artifact_path, created_at

必須記錄事件：approval_request_created, approved_job_manifest_created, validator_executed, validator_passed, validator_failed, dry_run_executed, dry_run_passed, dry_run_blocked, live_push_attempted, live_push_delivered, live_push_failed, product_owner_live_push_confirmed

Audit Trail 不得記錄：secret, token, credential

---

## 13. Telegram Notification Block

Sprint-019 必須完成 workflow-generated live push validation（硬性驗收條件）。

必須產出 notification artifact：reviews/sprint-019/round-001/notifications/

推播內容至少包含：Sprint ID、Job ID 或 Request ID、Gate/Action 類型、Target Actor、Risk Level、Product Owner 下一步、Artifact path、Audit reference、Dry-run status、明確標示不會自動執行 shell command / Claude / Codex / commit / push。

Sprint-019 Product Owner Validation PASS 必須同時滿足第 13 節列出的 9 項條件（Product Owner 實際收到推播、notification_history.jsonl 記錄 delivered、artifact 存在且可對上、PO 親自確認等）。delivery_status=disabled 只能作為診斷 evidence，不能作為 PASS 依據。

---

## 14. Product Owner Live Push Validation Checklist

必須新增：reviews/sprint-019/round-001/product_owner_live_push_validation_checklist.md（內容見該檔案）。

---

## 15. Documentation Update Requirements

Claude Code 應建立或更新：

docs/development/approved-execution-queue.md
docs/development/approval-request-schema.md
docs/development/approved-job-manifest-schema.md
docs/development/approved-execution-validator.md
docs/development/product-owner-live-push-validation.md

文件必須說明：

1. Queue directory structure。
2. Approval Request 與 Approved Job Manifest 差異。
3. Validator 安全規則。
4. Dry-run Worker 行為。
5. Audit Trail 格式。
6. Mandatory Live Push Validation。
7. delivery_status=disabled 不足以通過 Sprint-019 驗收。
8. 禁止 callback shell execution。
9. 禁止 Claude / Codex auto execution。
10. 禁止 commit / push automation。

---

## 16. Review Bridge / Script Requirements

Claude Code 可新增：

scripts/approved_execution_queue.py
scripts/test_approved_execution_queue.py

若需要 shell wrapper，可新增：

scripts/test_approved_execution_queue.sh

Script 限制：

1. 不得自動呼叫 Claude。
2. 不得自動呼叫 Codex。
3. 不得 git add。
4. 不得 commit。
5. 不得 push。
6. 不得 closure。
7. 不得執行任意 shell command manifest。
8. 不得寫入 secret、token、chat id。
9. 不得修改 configs/n8n/*.json。

---

## 17. Test Requirements

必須新增測試，並可由單一指令執行。

建議指令：

python scripts/test_approved_execution_queue.py
或：
bash scripts/test_approved_execution_queue.sh

測試必須覆蓋：

1. valid approval request passes validation。
2. invalid approval request fails validation。
3. approval request cannot be treated as approved job。
4. approved job manifest with PO approval passes。
5. manifest without PO approval fails。
6. manifest with shell_command_allowed=true fails。
7. manifest with commit_allowed=true fails。
8. manifest with push_allowed=true fails。
9. manifest with closure_allowed=true fails。
10. manifest with auto_handoff_allowed=true fails。
11. manifest with forbidden field command fails。
12. manifest with forbidden field shell fails。
13. manifest with forbidden field exec fails。
14. manifest with unknown target_actor fails。
15. manifest with unknown job_type fails。
16. missing input_artifact fails。
17. expected_output_artifact outside allowed directory fails。
18. dry-run worker produces report。
19. dry-run worker does not execute shell command。
20. dry-run worker does not call Claude CLI。
21. dry-run worker does not call Codex CLI。
22. audit trail is written。
23. audit trail does not contain secrets。
24. notification artifact is created。
25. disabled delivery cannot pass PO validation。
26. delivered delivery is required for PO validation。
27. configs/n8n remains unchanged。
28. no commit automation exists。
29. no push automation exists。
30. no callback execution exists。

---

## 18. Allowed Files

Claude Code 可建立或修改：

reviews/sprint-019/round-001/architecture.md
reviews/sprint-019/round-001/claude_report.md
reviews/sprint-019/round-001/notifications/
reviews/sprint-019/round-001/product_owner_live_push_validation_checklist.md
docs/development/approved-execution-queue.md
docs/development/approval-request-schema.md
docs/development/approved-job-manifest-schema.md
docs/development/approved-execution-validator.md
docs/development/product-owner-live-push-validation.md
reviews/approved-execution-queue/requests/
reviews/approved-execution-queue/approved/
reviews/approved-execution-queue/dry-run/
reviews/approved-execution-queue/audit/
scripts/approved_execution_queue.py
scripts/test_approved_execution_queue.py
scripts/test_approved_execution_queue.sh

若需新增其他 Sprint-019 scope 內檔案，必須在 Claude report 中列明原因。

---

## 19. Prohibited Files

Claude Code 不得修改：

configs/n8n/*.json
Sprint-018 已 push commit 內容
.env
*.env
local config
secret files
token files
credential files
runtime sqlite database
cache files
log files
unrelated Sprint artifacts
AI Decision Assistant 主產品文件，除非 Product Owner 明確核准。

---

## 20. Runtime Evidence Exclusion

Commit scope 不得包含：

.env, *.env, secret, token, credential, cache, tmp, log, sqlite runtime DB, local-only config

Live push 相關 token / chat id 必須透過環境變數提供。不得寫入 repo。

---

## 21. Safety Level Interpretation

Sprint-019 safety level 為：Low-risk file-based dry-run infrastructure

但因包含 live push validation，仍必須遵守：

1. 不得觸發 shell command。
2. 不得自動呼叫 AI CLI。
3. 不得自動 commit。
4. 不得自動 push。
5. 不得自動核准 Product Owner Gate。
6. 不得將 Telegram / LINE callback 變成 execution trigger。
7. delivery_status=delivered 僅代表推播成功，不代表 approval 或 execution 自動成立。

---

## 22. Validation Flow

Sprint-019 正式 validation flow：

1. Claude Code implementation。
2. Claude Code 產出 claude_report.md。
3. Claude Code 執行測試。
4. Claude Code 嘗試 Sprint-019 workflow-generated live push。
5. 若 delivery_status != delivered，Sprint-019 不可進 Product Owner Validation PASS。
6. Codex Review。
7. 若 Codex Review 發現 Must Fix，回 Claude Code 修正。
8. Codex Final Review PASS 後，Product Owner 執行 Live Push Validation Checklist。
9. Product Owner Validation PASS 後，才可 Codex Git Review。
10. Product Owner Commit Scope Decision 後，才可 commit。
11. Product Owner Push Approval 後，才可 push。
12. Push 後產出 Retrospective / Actual Flow Report。
13. Product Owner Closure Decision 後才可 Closure。

---

## 23. Expected Claude Implementation Report Requirements

Claude Code 完成後必須產出：reviews/sprint-019/round-001/claude_report.md

報告至少包含：Implementation Summary、Files Created、Files Modified、Queue Directory Created、Schema Implemented、Validator Behavior、Dry-run Worker Behavior、Audit Trail Behavior、Notification / Live Push Validation Result、Test Commands Executed、Test Results、Safety Boundary Confirmation、configs/n8n unchanged confirmation、Git status summary、Known Limitations、Product Owner Validation Notes

Live Push Result 必須明確寫：Live push attempted: YES/NO、Delivery status: delivered/failed/disabled、Notification artifact path、Notification history reference、Product Owner confirmation required: YES

若 delivery_status 不是 delivered，Claude report 必須明確寫：Sprint-019 Product Owner Validation cannot pass until live push delivery is fixed。

---

## 24. Expected Codex Review Report Requirements

Codex Review 必須檢查是否符合 Architecture Artifact、是否未擴張成 automation platform、Schema 完整性、Validator 是否拒絕 unsafe manifest、Dry-run Worker 是否無 real execution、Audit Trail 是否 append-only、Live Push Validation 是否達成 delivered、PO 推播驗收表是否存在、configs/n8n 是否未修改、是否無 Claude/Codex CLI auto execution、是否無 commit/push automation、是否無 callback shell execution、tests 是否通過、是否有 secret/token/credential 混入。

若 live push 未 delivered，Codex 必須判定 Must Fix。Codex Final Review 不得取代 Product Owner Validation。

---

## 25. Product Owner Scenario Validation Checklist

Product Owner Validation 只能在 18 項條件全部達成後 PASS（Claude implementation complete、Codex Review PASS、所有 Must Fix 完成、Schema 可查核、Validator 可查核、Dry-run Worker 可查核、Audit Trail 可查核、Tests passed、configs/n8n 未修改、無 real auto execution、無 callback shell execution、無 commit/push automation、PO 實際收到 live push、notification_history.jsonl 有 delivered、notification artifact 存在且 path 可對上、PO 親自確認收到推播、Checklist 已完成）。

若第 14–18 項任一項未達成：Product Owner Validation = FAIL，Sprint-019 remains open，Must Fix required within Sprint-019，No Git Review，No Commit，No Push，No Closure。

---

## 26. Definition of Done

1. File-based approved execution queue exists。
2. Approval request schema exists。
3. Approved job manifest schema exists。
4. Validator rejects unsafe jobs。
5. Dry-run worker creates evidence without real execution。
6. Audit trail records events。
7. Product Owner live push delivered。
8. Product Owner confirms receipt。
9. Product Owner Live Push Validation Checklist completed。
10. Tests pass。
11. Safety boundaries preserved。
12. No n8n workflow JSON modified。
13. No automatic Claude / Codex execution。
14. No callback shell execution。
15. No commit / push automation。
16. Product Owner Validation PASS。
17. Commit and push complete through Product Owner gates。
18. Retrospective completed before Closure。
19. Product Owner Closure Decision approved。

---

## 27. Implementation Gate

Product Owner 尚未核准前，不得交給 Claude Code implementation。一旦 Product Owner 核准本 Architecture Artifact，Claude Code 才可進入 Sprint-019 Implementation。

Claude Code implementation 限制：

1. 只能依本 Architecture Artifact 實作。
2. 不得修改 configs/n8n/*.json。
3. 不得修改 Sprint-018 已 push commit。
4. 不得自動呼叫 Codex。
5. 不得 git add。
6. 不得 commit。
7. 不得 push。
8. 不得 closure。
9. 不得建立真實 Claude / Codex CLI execution path。
10. 不得建立 Telegram / LINE callback shell execution path。
11. 不得硬編 secret、token、chat id。
12. live push 必須使用既有安全通知機制與環境變數。

---

## 28. Product Owner Approval Request — Decision

Product Owner Decision：

我核准 Sprint-019 Architecture Artifact。Sprint-019「Product Owner Approved Execution Queue MVP」可以進入 Claude Code Implementation。

Claude Code 必須依本 Architecture Artifact 實作：Approval Request Schema、Approved Job Manifest Schema、Queue Directory Structure、Markdown Front Matter Schema、Product Owner Live Push Validation Checklist、Validator、Dry-run Worker、Audit Trail、Notification Artifact、Mandatory Live Push Validation、Safety Rule Documentation、Test Cases。

硬性驗收要求：Product Owner 必須在 Sprint-019 workflow 內實際收到 live push，且 notification_history.jsonl 必須記錄 delivery_status=delivered，Sprint-019 才可通過 Product Owner Validation。若 Product Owner 沒有實際收到推播，或只有 delivery_status=disabled，Sprint-019 必須判定 Product Owner Validation FAIL，並且必須在 Sprint-019 內修到完成 live push validation 才能結案。

限制：不得修改 Sprint-018 已 push commit；不得修改 configs/n8n/*.json；不得做 Telegram / LINE callback 真實串接；不得讓 Telegram / LINE button 直接觸發 shell command；不得真實自動呼叫 Claude CLI；不得真實自動呼叫 Codex CLI；不得做 commit automation；不得做 push automation；不得讓 AI 自動核准 approved job；不得自動進入 Codex Review；不得自動 commit；不得自動 push；不得自動 Closure。

下一步：交給 Claude Code 進行 Sprint-019 Implementation。
