# Product Owner Live Push Validation（Sprint-019）

## 1. 為什麼這是硬性驗收條件

Sprint-019 Architecture Artifact 第 3、13、22、25 節明訂：Product Owner 必須在 Sprint-019 workflow 內**實際收到** live push，且 `reviews/notification_history.jsonl` 必須記錄 `delivery_status=delivered`。

**`delivery_status=disabled` 不足以通過 Sprint-019 驗收**——它只能作為「本機環境尚未設定 Telegram 憑證」的診斷 evidence，不能作為 Product Owner Validation PASS 的依據。若 live push 未 delivered：

- Product Owner Validation = FAIL
- 不得進入 Git Review
- 不得 Commit
- 不得 Push
- 不得 Closure
- 必須在 Sprint-019 內修到完成才能結案

## 2. 機制：重用既有安全通知機制與環境變數

Architecture 第 27 節要求「live push 必須使用既有安全通知機制與環境變數」。Sprint-019 **沒有**修改 `scripts/review_bridge.sh`（它不在 Sprint-019 Allowed Files 清單內），而是在 `scripts/approved_execution_queue.py` 內部重新實作了完全相同的 opt-in 慣例：

- `NOTIFICATION_ENABLED=true` 才會嘗試送出。
- 需同時設定 `TELEGRAM_BOT_TOKEN` 與 `TELEGRAM_CHAT_ID`。
- 缺一即為 `delivery_status=disabled`（不是 `failed`，與 `review_bridge.sh` 既有慣例一致）。
- 實際送出使用 Telegram Bot API `sendMessage`（Python 標準函式庫 `urllib`，非 shell curl）。
- 送出結果（不論 delivered / failed / disabled）都會 append 一筆記錄到 `reviews/notification_history.jsonl`，欄位與既有 `record_type: "gate"` 記錄相容，`record_type` 為 `approved_execution_queue_live_push` 以便區分。
- Token / Chat ID 只透過環境變數提供，絕不寫入 repo、絕不寫入 audit trail 或 notification artifact。

## 3. CLI

```bash
python scripts/approved_execution_queue.py live-push \
  --sprint-id sprint-019 \
  --round round-001 \
  --ref <job_id 或 request_id> \
  --gate-type <gate/action 類型> \
  --target-actor <target actor> \
  --risk-level <risk level> \
  --next-step "<Product Owner 下一步的中文說明>" \
  --artifact-path <相關 artifact 路徑> \
  --audit-reference <audit.jsonl 路徑> \
  --dry-run-status <would-execute 或 blocked>
```

執行後會：

1. 在 `reviews/sprint-019/round-001/notifications/<ref>-live-push.md` 寫入完整通知內容（見下方 3 則訊息的合併記錄）。
2. 依環境變數決定是否實際透過 Telegram 送出。
3. 寫入 `reviews/notification_history.jsonl` 一筆記錄。
4. 寫入 audit trail 的 `live_push_attempted` 事件，再依結果寫入 `live_push_delivered` 或 `live_push_failed`。
5. 若最終 `delivery_status != delivered`，CLI 回傳 exit code `1`，並在 stdout 明確印出：「Sprint-019 Product Owner Validation cannot pass until live push delivery is fixed.」

### 3.1 三則獨立訊息（Sprint-019 Must Fix Round 2）

Telegram 實際收到的是依序送出的 3 則獨立訊息，彼此內容不混雜：

1. **Message 1（Product Owner Summary）**：Sprint/Round/Gate 資訊、目前狀態、Product Owner 現在要做什麼、下一個 AI 是誰、Product Owner 審核（`record-po-decision` 指令說明）、Safety Notice、Evidence Reference、Notification/Audit Reference。
2. **Message 2（Codex Handoff Package）**：**只**包含 `===== BEGIN COPY TO CODEX REVIEW =====` 到 `===== END COPY TO CODEX REVIEW =====` 之間的內容，可直接整段複製貼給 Codex，不含任何其他文字。若內容超過單則訊息安全長度（3500 字元），`live-push` 會直接失敗（Fail Loudly），不會默默切成兩則。
3. **Message 3（Evidence & Checklist）**：notification_package_path、notification_history.jsonl、audit.jsonl 路徑，以及 `confirm-live-push` 指令、checklist 路徑、PASS/FAIL 填寫提醒。

## 3.2 Product Owner 審核：CLI 替代 Telegram 按鍵（Sprint-019 Must Fix Round 2）

Product Owner 曾要求 Telegram 推播提供「同意/不同意」互動按鍵。真實按鍵需要 Telegram callback 真實串接（webhook 或長輪詢接收 `callback_query`），這與 Sprint-019 Architecture 明確禁止的「不做 Telegram callback 真實串接」「不做長期 worker daemon」直接衝突。

**Sprint-019 本輪不實作真實 Telegram callback 按鍵。PO 同意/不同意改由 `record-po-decision` CLI 記錄。真實 Telegram 按鍵列入後續 Sprint Architecture Amendment。**（Telegram true approve/reject buttons are deferred because they require Architecture Amendment; Sprint-019 uses the `record-po-decision` CLI as the approved safe substitute.）

Message 1 內嵌完整的 `record-po-decision` 指令（同意會額外寫入一份 Approved Job Manifest；不同意只寫入 audit event），完整規則見 [approved-execution-queue.md](approved-execution-queue.md) 第 5a 節。

## 4. Product Owner 親自確認

送達（`delivery_status=delivered`）只代表 Telegram API 回應成功，**不代表** Product Owner 已經親自確認收到。Architecture 要求「Product Owner 親自確認收到推播」，因此本模組另外提供：

```bash
python scripts/approved_execution_queue.py confirm-live-push \
  --sprint-id sprint-019 --ref <job_id 或 request_id> \
  reviews/sprint-019/round-001/notifications/<ref>-live-push.md
```

**這個指令只能由 Product Owner 本人執行**，在 Product Owner 實際打開 Telegram 確認收到訊息之後——Claude Code / Codex 不得代為執行，也不得假設已經確認。執行後會寫入 audit trail 的 `product_owner_live_push_confirmed` 事件，作為 [product_owner_live_push_validation_checklist.md](../../reviews/sprint-019/round-001/product_owner_live_push_validation_checklist.md) 的佐證。

## 5. 安全邊界

- 推播內容本身不觸發 shell command。
- 推播不會自動核准任何 Gate。
- 推播不會自動呼叫 Claude 或 Codex。
- 推播不會自動 commit / push / closure。
- `delivery_status=delivered` 僅代表推播成功送達 Telegram，不代表 approval 或 execution 自動成立。
