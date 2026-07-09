# Product Owner Live Push Validation Checklist - Sprint-019

Required Evidence:

- [x] Product Owner received Sprint-019 workflow-generated push.
- [x] Push was not a manual unrelated test.
- [x] notification_history.jsonl contains delivery_status=delivered.
- [x] notification artifact exists.
- [x] artifact path matches notification_history.jsonl.
- [x] Push content includes Sprint ID.
- [x] Push content includes Job ID or Request ID.
- [x] Push content includes Product Owner next step.
- [x] Push does not trigger shell command.
- [x] Push does not auto-approve Gate.
- [x] Push does not auto-run Claude or Codex.
- [x] Push does not auto-commit.
- [x] Push does not auto-push.
- [x] Product Owner manually confirms receipt.

## Product Owner Decision

PASS

Sprint-019 Product Owner Live Push Validation is approved.

## Evidence

- Telegram 3 則訊息均已實際收到。
- 全部為繁體中文。
- 第 2 則訊息只包含 Codex Review Handoff Package。
- 第 2 則訊息可直接整段複製給 Codex Review。
- 第 2 則訊息未混入 Product Owner Summary、Evidence、Notification Metadata 或其他非 Codex 指令內容。
- `record-po-decision` 的 approve / reject 指令清楚可讀。
- `notification_history.jsonl` 有 `delivery_status=delivered`。
- delivered_at: `2026-07-09T14:30:19Z`
- audit trail 有 `live_push_attempted` / `live_push_delivered` 正確配對。
- audit trail 有 `product_owner_live_push_confirmed`。
- confirmed_at: `2026-07-09T15:06:37Z`
- repo 內未發現 token / credential 外洩。
- Must Fix Round 3 已補足 approved manifest / `handoff_package_path` / `consume-approved` dry-run 閉環。
- 46 項測試全數通過。

## Next Step

Codex Review may proceed.

Git Review / Commit / Push / Closure remain BLOCKED until Codex Review PASS.

---
## Round 4 Amendment - Product Owner Validation

PASS

Product Owner has re-validated the Sprint-019 Round 4 live push.

Evidence:

- ref: `sprint-019-implementation-must-fix-4`
- live-push artifact: `reviews/sprint-019/round-001/notifications/sprint-019-implementation-must-fix-4-live-push.md`
- codex-handoff artifact: `reviews/sprint-019/round-001/notifications/sprint-019-implementation-must-fix-4-codex-handoff.md`
- Telegram 3 則訊息均已實際收到。
- Message 1 顯示 `Job/Request ID: sprint-019-implementation-must-fix-4`。
- Message 2 只包含 Codex Review Handoff Package。
- approve 指令包含 `--handoff-package-path`。
- approve 指令引用 `sprint-019-implementation-must-fix-4-codex-handoff.md`。
- `notification_history.jsonl` 最新 Round 4 delivery 為 `delivered`。
- `confirm-live-push` 已由 Product Owner 執行。
- audit trail 已記錄 Round 4 `product_owner_live_push_confirmed`。
- `record-po-decision approve` 已由 Product Owner 執行。
- approved manifest 已產生：`reviews/approved-execution-queue/approved/sprint-019-implementation-must-fix-4.md`
- `consume-approved` 已執行，且僅 dry-run。
- dry-run report 已產生：`reviews/approved-execution-queue/dry-run/sprint-019-implementation-must-fix-4-dry-run-report.md`
- dry-run 未真實呼叫 Claude CLI / Codex CLI。
- dry-run 未 commit。
- dry-run 未 push。
- 未發現 token / credential 外洩。
- 48 項測試全數通過。
- Git Review / Commit / Push / Closure remain BLOCKED until Codex Review PASS.

Decision:

Sprint-019 Round 4 Product Owner Live Push Validation: PASS

Codex Review may proceed.

---

## 操作說明（供 Product Owner 使用）

1. 確認本機環境已設定 `NOTIFICATION_ENABLED=true`、`TELEGRAM_BOT_TOKEN`、`TELEGRAM_CHAT_ID`（只需確認是否存在，不需要把值貼給 Claude Code 或任何人）。
2. 執行（或請 Claude Code 執行）：
   ```bash
   NOTIFICATION_ENABLED=true TELEGRAM_BOT_TOKEN=*** TELEGRAM_CHAT_ID=*** \
   python scripts/approved_execution_queue.py live-push \
     --sprint-id sprint-019 --round round-001 --ref <job_id 或 request_id> \
     --gate-type <gate/action 類型> --target-actor <target actor> \
     --risk-level <risk level> --next-step "<下一步說明>" \
     --artifact-path <artifact 路徑> --audit-reference reviews/approved-execution-queue/audit/audit.jsonl \
     --dry-run-status <would-execute 或 blocked>
   ```
3. 確認終端機輸出 `delivery_status=delivered`，並在 Telegram 實際看到這則推播。
4. 逐項勾選上方 Required Evidence。
5. 親自執行確認指令（不得由 Claude Code 代為執行）：
   ```bash
   python scripts/approved_execution_queue.py confirm-live-push \
     --sprint-id sprint-019 --ref <job_id 或 request_id> \
     <notification artifact 路徑>
   ```
6. 填寫上方 Product Owner Decision：PASS 或 FAIL。

若第 3 步的 `delivery_status` 不是 `delivered`（例如 `disabled` 或 `failed`），本 Checklist 一律判定 FAIL，Sprint-019 remains open，Must Fix required within Sprint-019，不得進入 Git Review / Commit / Push / Closure。

---

## Must Fix Round 1 Evidence（供 Product Owner 核對用，非自動勾選）

Product Owner 於 Must Fix Round 1 判定原始推播 FAIL（英文、無 Handoff Package）。修正內容見 `reviews/sprint-019/round-001/claude_fix_report.md`。本輪重新送出的證據：

- Notification artifact: `reviews/sprint-019/round-001/notifications/sprint-019-implementation-must-fix-1-live-push.md`
- `notification_history.jsonl` 記錄: `created_at: 2026-07-09T13:57:42Z`, `delivery_status: delivered`, `delivered_at: 2026-07-09T13:57:43Z`
- Audit trail: `live_push_attempted`（`cd842b7d-ba1c-4826-9a31-90fe13a3ffdb`）→ `live_push_delivered`（`24dc617d-b077-4cb5-a62f-26816a4ebe6e`）

以上僅為 Claude Code 記錄的客觀事實（檔案是否存在、記錄內容），**不代表**上方 Required Evidence 清單已被勾選——每一項仍須 Product Owner 親自核對後勾選，Product Owner Decision 仍須 Product Owner 本人填寫。

---

## Must Fix Round 2 Evidence（供 Product Owner 核對用，非自動勾選）

Product Owner 於 Must Fix Round 2 判定 FAIL：Codex Handoff Package 未獨立成一則訊息、缺少審核閉環。修正內容見 `reviews/sprint-019/round-001/claude_fix_report_round_2.md`，重點：

- Telegram live push 已改為依序送出 3 則獨立訊息（Summary / **只含** Codex Handoff Package / Evidence & Checklist）。
- **Product Owner 已裁決**：不新增真實 Telegram callback / webhook / polling listener（與已核准 Architecture Section 4.2 衝突），改用 `record-po-decision` CLI 作為安全替代方案，並要求補齊完整閉環：
  - `record-po-decision --decision approve` 寫入通過 validator 的 Approved Job Manifest 到 `approved/`。
  - `record-po-decision --decision reject` 只寫入 audit event，不產生任何檔案。
  - `consume-approved`（人工觸發的一次性批次指令，非排程器/daemon）只消費 `approved/`，僅 dry-run，從不呼叫真實 Claude/Codex CLI。
- 43 項測試（Round 1 的 30 項 + Round 2 累計新增 13 項）全數通過。
- 「Telegram true approve/reject buttons are deferred...」聲明已寫入 `claude_fix_report_round_2.md`、`docs/development/approved-execution-queue.md`、`docs/development/product-owner-live-push-validation.md`。
- 本輪的實際新 live push 送出結果（`delivery_status`、新 artifact path、audit 事件）待 Product Owner 執行 `claude_fix_report_round_2.md` 第 10 節指令後才會產生——Claude Code 未持有 Telegram 憑證，不會代為送出。

**Round 2 已由 Product Owner 確認**：3 則訊息、繁體中文、Codex Handoff Package 獨立可複製、CLI 替代按鍵方案皆已驗收通過（見對話紀錄）。

---

## Must Fix Round 3 Evidence（供 Product Owner 核對用，非自動勾選）

Product Owner 補充要求驗證並補強 approve/reject/consume-approved 完整閉環，並列出 manifest 應包含的具體欄位。修正內容見 `reviews/sprint-019/round-001/claude_fix_report_round_3.md`，重點：

- `live-push` 現在額外寫入獨立 Codex Handoff Package 檔案（`<ref>-codex-handoff.md`），與 Telegram Message 2 逐位元組相同。
- Approved Job Manifest 新增 5 個補充欄位：`next_ai`、`handoff_package_path`、`source_artifact_path`、`audit_reference`、`status`（詳見 `claude_fix_report_round_3.md` 第 3.5 節）。
- 完整閉環（live-push → approve → manifest 引用獨立 handoff 檔案 → consume-approved 只消費 approved 目錄且僅 dry-run）已端對端驗證（自動化測試 Test 46 + 手動 CLI 驗證）。
- 46 項測試全數通過（Round 1 的 30 + Round 2 的 13 + Round 3 新增 3）。


**本輪實際送出證據**（Product Owner 已執行 live-push，見 `claude_fix_report_round_2.md` 第 10a 節）：`delivery_status=delivered`（`created_at: 2026-07-09T14:30:16Z`, `delivered_at: 2026-07-09T14:30:19Z`），artifact 內容確認含 3 則獨立訊息（Summary / Codex Handoff Package / Evidence & Checklist）。Product Owner 已親自確認，audit trail 已記錄 `product_owner_live_push_confirmed`（`created_at: 2026-07-09T15:06:37Z`）。
