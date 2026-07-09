# Claude Fix Report — Sprint-019 Must Fix Round 1

## 1. Summary

依 Product Owner 的 Sprint-019 Must Fix 指令（Product Owner Live Push Validation：FAIL），修正 `scripts/approved_execution_queue.py` 的 `cmd_live_push` 推播內容格式：原本的 live push 是純英文、扁平欄位列表，沒有繁體中文化、沒有分段、沒有可複製給 Codex Review 的 Handoff Package。本輪重寫推播內容為繁體中文、12 個必要區塊（標題、Sprint/Round/Gate 資訊、目前狀態、Product Owner 要做什麼、下一個 AI 是誰、給 Codex 的可複製 Handoff Package、Codex Review 必讀檔案、Codex Review 必查項目、Codex Review 禁止事項、Safety Notice、Evidence Reference、Notification/Audit Reference），並在修正過程中額外發現並修正一個既有缺陷（見第 5 節）。

本輪只修改 `scripts/approved_execution_queue.py` 的推播內容產生邏輯與 Telegram 傳送的例外處理，未修改 validator、dry-run worker、schema、audit trail 的行為，未擴大 scope，未修改 `scripts/review_bridge.sh` 或 `configs/n8n/*.json`。

Scope Expansion: No

## 2. Context Completeness Check

- Full required reading list provided: PASS
- Missing context files: 同 `claude_report.md` 第 15.3 節已揭露的兩項（Sprint-019 Architecture Definition 獨立檔案、Sprint-018 Retrospective / Actual Flow Report 獨立檔案，repo 中皆不存在對應獨立檔案）
- Did missing context affect implementation or review: NO
- Notes: 本輪額外閱讀了 Product Owner Must Fix 指令本身提供的 Telegram UX 要求與 Codex Handoff Package 範本，並以此為準重寫推播內容。

## 3. Must Fix Items Addressed

| # | Fail Reason（Product Owner 指出） | 修正方式 |
|---|---|---|
| 1 | 推播內容不是繁體中文 | 重寫 `cmd_live_push` 訊息文字全面改為繁體中文 |
| 2 | 缺少基本中文化排版與可讀性設計 | 改為 12 個明確標題區塊（🔔📌📍✅➡️🤖📖🔍🚫⚠️📎🧾），emoji 標題 + 分段 |
| 3 | 沒有清楚寫出交給下一個 AI 的指令 | 新增「➡️ 下一個 AI 是誰」區塊，明確寫出 `Codex（Codex Review）` |
| 4 | 沒有提供可直接複製給 Codex Review 的 Handoff Package | 新增「🤖 給 Codex 的 Handoff Package」區塊，以 `===== BEGIN COPY TO CODEX REVIEW =====` / `===== END COPY TO CODEX REVIEW =====` 包住完整可複製內容 |
| 5 | 沒有明確列出 Codex Review 要閱讀的檔案 | Handoff Package 內嵌 18 項必讀檔案清單，另於「📖 Codex Review 必讀檔案」區塊重複列出供快速閱讀 |
| 6 | 沒有明確列出 Codex Review 要檢查的項目 | Handoff Package 內嵌 17 項檢查清單，另於「🔍 Codex Review 必查項目」區塊重複列出 |
| 7 | 沒有明確列出 Codex Review 不得執行的事項 | Handoff Package 內嵌 9 項禁止事項，另於「🚫 Codex Review 禁止事項」區塊重複列出 |
| 8 | 沒有達到 Product Owner 對 Telegram Gate Notification UX 的要求 | 整體格式改為比照既有 `docs/development/telegram-po-gate-notification-specification.md` 的 Handoff Package / Evidence Reference / Delivery Metadata 慣例（延伸既有規格的既有模式，非重新發明） |

## 4. Files Modified

- `scripts/approved_execution_queue.py`
  - 重寫 `cmd_live_push` 的訊息組裝邏輯（繁體中文、12 區塊、Codex Handoff Package）。
  - 新增 `_chunk_message()`：依區塊邊界（空行）切分訊息，確保 Codex Handoff Package 的 `BEGIN`/`END COPY` 區塊永遠完整不被截斷，只在單一區塊本身超過安全長度時才退回逐字元切分。
  - 新增 `_build_codex_handoff_block()` 與三個常數（`_CODEX_REVIEW_READING_LIST`、`_CODEX_REVIEW_CHECK_ITEMS`、`_CODEX_REVIEW_FORBIDDEN_ACTIONS`），內容取自 Product Owner Must Fix 指令提供的範本。
  - 修正 `_post_telegram_message()` 的例外處理（見第 5 節）。
- 未修改 `scripts/test_approved_execution_queue.py`：既有 30 項測試只驗證行為（artifact 是否建立、delivery_status 是否正確、audit 是否寫入、n8n 是否未變動、無 shell/commit/push/callback 執行能力），不驗證訊息文字內容，因此格式重寫後全部維持 PASS，未需修改測試本身。

## 5. 額外發現並修正的缺陷（非 Product Owner 原始 Must Fix 項目）

第一次依修正後程式碼實際嘗試送出 live push 時，Telegram API 呼叫發生網路逾時（`TimeoutError`）。原本的 `_post_telegram_message()` 只捕捉 `urllib.error.URLError`，但 Python 的 socket read timeout 拋出的是 `TimeoutError`（`OSError` 的子類別，**不是** `URLError` 的子類別），導致例外未被捕捉、直接讓整個指令 crash——程式在寫入 `live_push_attempted` audit 記錄之後、寫入 `live_push_delivered`/`live_push_failed` 與 `notification_history.jsonl` 之前中斷，留下一筆不完整的稽核記錄。

修正：`_post_telegram_message()` 的 `except` 子句擴大為 `(urllib.error.URLError, OSError, ValueError)`，涵蓋逾時等網路層例外與非預期的回應內容，確保任何送出失敗都會正確走到 `delivery_status="failed"` 分支並完整寫入 audit trail 與 notification history，不會再讓未捕捉的例外中斷整個流程。

這筆不完整的舊記錄（`event_id: 7fe9cab6-81d7-444d-a205-801f994fedc9`，`event_type: live_push_attempted`，`created_at: 2026-07-09T13:54:25Z`，無對應 delivered/failed 記錄）**未被刪除或修改**——依 Architecture 第 12 節 audit trail 必須 append-only 的規則，這是一筆誠實保留的問題發生記錄，不得回頭覆蓋。

## 6. Notification / Live Push Validation Result（本輪重新送出）

**Live push attempted**: YES（`scripts/approved_execution_queue.py live-push --ref sprint-019-implementation-must-fix-1 ...`，由 Product Owner 在自己的終端機以自己的 Telegram 憑證執行，Claude Code 未接觸、未讀取、未記錄任何 token 值）

**第一次嘗試**：網路逾時，未產生 delivered/failed 記錄（見第 5 節根因與修正）。

**第二次嘗試（修正後）**：

- Delivery status: **delivered**
- `notification_history.jsonl` 記錄：`created_at: 2026-07-09T13:57:42Z`, `delivered_at: 2026-07-09T13:57:43Z`, `notification_package_path: /home/ivan/AI/reviews/sprint-019/round-001/notifications/sprint-019-implementation-must-fix-1-live-push.md`
- Audit trail：`live_push_attempted`（event_id `cd842b7d-ba1c-4826-9a31-90fe13a3ffdb`）→ `live_push_delivered`（event_id `24dc617d-b077-4cb5-a62f-26816a4ebe6e`）
- 訊息以 2 則 Telegram message 依序送出（`_chunk_message` 切分結果），Codex Handoff Package 完整包含在單一則訊息內，未被截斷或跨訊息分割（已於本機以相同內容驗證切分點，見第 7 節）。

**Notification artifact path**: `reviews/sprint-019/round-001/notifications/sprint-019-implementation-must-fix-1-live-push.md`

**Notification history reference**: `reviews/notification_history.jsonl`（`record_type: "approved_execution_queue_live_push"`, `sprint_id: "sprint-019"`, `ref: "sprint-019-implementation-must-fix-1"`, `delivery_status: "delivered"`）

**Product Owner confirmation required**: YES（`delivery_status=delivered` 只代表 Telegram API 回應成功，Product Owner 仍須親自在 Telegram 用戶端確認實際看到本則訊息、確認內容包含可複製的 Codex Handoff Package，並執行 `confirm-live-push` 指令、完成 `product_owner_live_push_validation_checklist.md`）

## 7. Test Commands Executed

```bash
python3 scripts/test_approved_execution_queue.py
bash scripts/test_approved_execution_queue.sh
```

## 8. Test Results

全部 30 項測試通過（`Ran 30 tests ... OK`），與修正前相同——本輪只改變訊息內容與例外處理範圍，未改變任何驗證行為，因此測試案例無需修改即可涵蓋。另外以本機（`REVIEWS_OVERRIDE` 暫存目錄，`NOTIFICATION_ENABLED` 未設定）人工預覽新訊息格式與 `_chunk_message` 切分結果，確認 12 區塊皆存在、Codex Handoff Package 未被切分點截斷。

## 9. Safety Boundary Confirmation

與 `claude_report.md` 第 12 節完全一致，本輪修正未新增任何執行能力：

- 不執行 shell command：`scripts/approved_execution_queue.py` 仍不 import `subprocess`，無 `os.system`/`os.popen`/`eval`/`exec`（測試 28-30 靜態掃描）。
- 不呼叫 Claude CLI / Codex CLI：Handoff Package 只是**文字內容**，Product Owner 仍須親自決定是否複製貼給 Codex，程式本身不呼叫任何外部 AI CLI。
- 不自動核准 Gate、不自動 commit/push/closure：訊息內容本身即明確聲明「不構成 Gate 核准」（Safety Notice 區塊），且程式邏輯未變。
- Telegram token / chat id 只透過環境變數提供，Claude Code 全程未讀取、未印出、未記錄、未寫入任何檔案（已以 `grep` 對新 artifact / history / audit 掃描確認不含 token-like 字串）。

## 10. configs/n8n Unchanged Confirmation

`git status --short configs/n8n/` 於本輪修正前後皆無輸出。本輪僅修改 `scripts/approved_execution_queue.py`，未觸碰 `scripts/review_bridge.sh` 或 `configs/n8n/*.json`。

## 11. Git Status Summary

本輪修改／新增為 untracked 或 modified，未執行 `git add`：

```
 M scripts/approved_execution_queue.py
?? reviews/sprint-019/round-001/claude_fix_report.md
?? reviews/sprint-019/round-001/notifications/sprint-019-implementation-must-fix-1-live-push.md
 M reviews/notification_history.jsonl
 M reviews/approved-execution-queue/audit/audit.jsonl
```

## 12. Known Limitations

1. 第一次 live push 嘗試因網路逾時留下一筆不完整的 audit 記錄（`live_push_attempted` 無對應結果），已依 append-only 規則保留、未刪除，詳見第 5 節。
2. `_chunk_message()` 的切分邏輯以「空行分隔的區塊」為單位，若未來訊息內容中 Codex Handoff Package 本身單一區塊長度超過 3500 字元安全上限，會退回逐字元硬切（可能切斷 Handoff Package 本身）——目前實際內容（約 1500-2000 字元）遠低於此上限，屬於已知但目前不影響本輪驗收的邊界情況。
3. Product Owner 仍需完成：親自在 Telegram 確認收到、執行 `confirm-live-push`、填寫 `product_owner_live_push_validation_checklist.md` 的 Product Owner Decision，這些是 Claude Code 不得代為執行的步驟。

## 13. Product Owner Validation Notes

在 Product Owner 完成以下事項之前，Product Owner Validation 不得判定 PASS：

1. ~~重新執行 `live-push` 指令~~ — 已完成，`delivery_status=delivered`（`created_at: 2026-07-09T13:57:42Z`）。
2. ~~確認 `reviews/notification_history.jsonl` 記錄新的 `delivery_status=delivered`~~ — 已確認。
3. 確認實際在 Telegram 收到本則推播，且內容為繁體中文、包含可複製的 Codex Handoff Package。
4. 執行 `confirm-live-push` 指令。
5. 完成 `reviews/sprint-019/round-001/product_owner_live_push_validation_checklist.md` 並填寫 PASS/FAIL。

在此之前，本 Sprint 不得進入 Codex Git Review、不得 Commit、不得 Push、不得 Closure。
