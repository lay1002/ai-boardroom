# n8n Workflow 2：Codex Review 完成通知

## 狀態

本文件為設計文件，非實作紀錄。目前 workspace 內尚無任何已部署或已啟用的 n8n workflow。本文件只描述 Workflow 2 的節點設計與設定建議，不代表已經在任何 n8n 實例中建立或部署。

本文件不屬於任何 Sprint，不對應 `reviews/<sprint-id>/` 下的 Review Bridge 流程。

本 Workflow 完全沿用 `docs/development/n8n-claude-done-notification.md`（Workflow 1）已驗證可行的架構與設計原則，不建立新架構、不引入新模式。

---

## 使用目的

當 `scripts/review_bridge.sh check <sprint-id> <round>` 依既有流程確認 `codex_review.md` 或 `codex_final_review.md` 為 **READY**（存在且非 placeholder）之後，透過 Telegram 通知 Product Owner：

> 提醒 Product Owner 回來查看 Codex Review 結果。

這個 workflow 只負責「接收事件 + 通知」，不做任何判斷、審核或後續動作。是否要採納 Codex Review 意見、是否要進入下一步，完全由 Product Owner 自行決定。

---

## 節點設計

```text
Webhook Trigger
  ↓
Telegram：通知 Product Owner
```

與 Workflow 1 完全相同的兩節點結構，不加入其他節點（不做 IF 判斷、不做內容解析、不做決策分支）。

### 1. Webhook Trigger

- Type: `n8n-nodes-base.webhook`
- HTTP Method: `POST`
- Path: `codex-review-done`
- 純粹被動接收 HTTP 請求，不主動存取檔案系統、不執行任何指令、不呼叫任何外部服務。
- 觸發來源：`scripts/review_bridge.sh check` 在確認 `codex_review.md` 或 `codex_final_review.md` 為 READY 後，選擇性自動送出一次 `curl` POST（見下方「Review Bridge 整合」）。這是 Review Bridge 對外送出通知，不是 n8n 主動呼叫或觸發 Claude/Codex，n8n 全程只是被動收件者。

### 2. Telegram：通知 Product Owner

發送訊息給 Product Owner 的 Telegram 帳號/群組。

#### 訊息模板

```text
✅ Codex Review 已完成

Sprint: {{$json.body.sprint_id}}
Round: {{$json.body.round_id}}
Type: {{$json.body.review_type}}

請回到 workspace 查看：
{{$json.body.file_path}}
```

（`{{$json.body.sprint_id}}` 等為 n8n expression 語法，對應 Webhook 節點收到的 JSON body 欄位。）

---

## 環境變數

新增一個 opt-in 環境變數：

```bash
N8N_CODEX_REVIEW_DONE_WEBHOOK_URL
```

```bash
export N8N_CODEX_REVIEW_DONE_WEBHOOK_URL="https://<your-n8n-host>/webhook/codex-review-done"
scripts/review_bridge.sh check <sprint-id> <round>
```

- 未設定時：不送通知、不報錯、`check` 行為與加入本功能之前完全一致。
- 與 Workflow 1 的 `N8N_CLAUDE_DONE_WEBHOOK_URL` 是兩個獨立、互不影響的環境變數，可以只啟用其中一個。
- 建議先用 test Webhook URL 測試，確認無誤後再改用 production URL（需 workflow 已啟用）。

---

## Payload

POST 的 JSON payload 固定為：

```json
{
  "sprint_id": "sprint-xxx",
  "round_id": "round-001",
  "review_type": "codex_review",
  "file_path": "reviews/sprint-xxx/round-001/codex_review.md"
}
```

`review_type` 只會是以下兩者之一：

- `codex_review` — 對應 `codex_review.md` 變為 READY。
- `codex_final_review` — 對應 `codex_final_review.md` 變為 READY。

四個欄位對應 Telegram 訊息模板中的 `{{$json.body.sprint_id}}`、`{{$json.body.round_id}}`、`{{$json.body.review_type}}`、`{{$json.body.file_path}}`。

---

## Review Bridge 整合（可選，非必要）

`scripts/review_bridge.sh check` 沿用既有的 READY 判斷結果（`ready[]` 陣列），**沒有新增第二套 READY 判斷邏輯、沒有再次掃描檔案、沒有再次解析 markdown**。判斷完成後，若 `codex_review.md` 或 `codex_final_review.md` 出現在既有的 `ready[]` 清單中，且對應環境變數已設定，才呼叫 `notify_codex_review_done` 送出通知。

這個函式與 Workflow 1 的 `notify_claude_report_done` 共用同一個底層 POST helper（`_post_n8n_notification`），行為保證完全一致：

### Webhook 行為

- **opt-in**：未設定 `N8N_CODEX_REVIEW_DONE_WEBHOOK_URL` 時完全不觸發。
- **best effort**：`curl -fsS --max-time 5`，逾時 5 秒。
- **webhook 失敗只印 warning**：任何失敗（連不上、逾時、HTTP 錯誤、`curl` 未安裝）只印一行 `WARNING: ...` 到 stderr，不影響 `check` 的 exit code 或 PASS/FAIL 判定。
- **warning 不印出完整 URL**：警告訊息固定為 `WARNING: Failed to POST <review_type> notification to N8N webhook. Continuing without notification.`，不含 `$webhook_url` 的實際內容。
- **`--dry-run` 支援**：設定環境變數並加上 `--dry-run` 時，只印出 `[dry-run] Would POST <review_type> notification to N8N_CODEX_REVIEW_DONE_WEBHOOK_URL`，不會真的呼叫 `curl`。

### Failure Handling

| 情境 | 行為 |
|---|---|
| 環境變數未設定 | 直接返回，不嘗試任何網路操作，`check` 行為不變 |
| 系統沒有 `curl` | 印出 WARNING，略過通知，`check` 正常繼續 |
| Webhook 連線失敗 / 逾時 / HTTP 錯誤 | 印出 WARNING（不含真實 URL），`check` 正常繼續，exit code 不受影響 |
| `--dry-run` | 印出 would-POST 訊息，不觸發任何真實網路請求 |

---

## Manual Gate 邊界

依 `docs/development/development-workflow.md` 第 5 節與 `docs/development/consensus-workflow.md` 的 Manual Gate Policy，本 workflow 必須遵守：

- **不自動呼叫 Claude**：通知內容只有事實性欄位（`sprint_id`/`round_id`/`review_type`/`file_path`），不會觸發任何 Claude Code 動作。
- **不自動修正程式**：Review Bridge 與 n8n 皆不修改任何原始碼或 review artifact。
- **不自動產生 Consensus**：通知與 `scripts/review_bridge.sh consensus` / `finalize` 完全無關，不會代為執行或觸發這些指令。
- **不自動 Commit**：全流程沒有任何一步會執行 git 操作。
- **不自動開始下一輪 Review**：是否要根據 Codex Review 結果修正、是否要開始下一輪，完全由 Product Owner 收到通知後手動決定。
- **不在 n8n 內做任何決策**：Webhook → Telegram 只是單向轉發，沒有 IF 判斷、沒有內容解析、沒有分支邏輯。

---

## 不做的事情

- 不新增 AI Runner（n8n 不呼叫任何 LLM API）。
- 不新增 Workflow Engine。
- 不新增 Platform。
- 不自動呼叫 Codex CLI 或 Codex API 重跑 Review。
- 不自動呼叫 Claude Code。
- 不自動修改任何程式碼或 review artifact。
- 不自動執行 `scripts/review_bridge.sh` 的 `consensus` / `finalize` 等其他 command。
- 不建立新的 Sprint。
- 不修改 Review Bridge 既有 READY 判斷邏輯或 Consensus Algorithm。
- 不在 n8n 內執行任何 shell 指令或存取檔案系統。
- 不在文件或設定檔中記錄真實 Production n8n host（見下方）。

---

## 可匯入 JSON 草稿

已提供最小可用草稿：

```text
configs/n8n/codex-review-done-notification.workflow.json
```

內含 2 個節點（Webhook Trigger → Telegram Send Message），與 Workflow 1 結構完全相同，不加入其他節點。此檔案是**匯入草稿**，不是已部署或已啟用的 workflow：

- 檔案內 `active` 欄位為 `false`。
- Telegram 節點的 `credentials` 為空物件，`chatId` 為明顯的佔位字串 `REPLACE_WITH_PRODUCT_OWNER_CHAT_ID`，尚未設定任何真實憑證或收件對象。

### 如何匯入

1. 開啟 n8n 介面（Product Owner 自行登入）。
2. 使用「Import from File」功能，選擇 `configs/n8n/codex-review-done-notification.workflow.json`。
3. 匯入後會產生一個名為「Workflow 2 - Codex Review 完成通知 (DRAFT - DO NOT ACTIVATE)」的 workflow，狀態為未啟用。
4. 手動設定 Telegram credential 與真實 chatId（同 Workflow 1 做法）。
5. 先用 test Webhook URL 測試，確認訊息格式正確後才啟用 workflow，並改用 production Webhook URL。

### Production Webhook URL 佔位範例

```text
https://<your-n8n-host>/webhook/codex-review-done
```

**不得在本文件或任何設定檔中放入真實 Production Host**，理由與 Workflow 1 相同：避免 repo 被分享或公開時，任何人取得該 URL 就能對 n8n 送出任意 POST 造成誤觸發或濫用。

### 目前版本沒有去重機制，可能重複通知

- 若同一份 `codex_review.md` 或 `codex_final_review.md` 被多次執行 `check` 且環境變數已設定，會每次都觸發一次通知，沒有比對「是否已通知過」的邏輯。
- 這與 Workflow 1 的已知限制一致，維持最小範圍，不在本次一併實作去重。

---

## Product Owner 後續設定建議

以下是設定建議，非本文件已完成的部署動作：

1. 依上方「如何匯入」章節，將 `configs/n8n/codex-review-done-notification.workflow.json` 匯入 n8n。
2. 自行在 n8n 設定 Telegram Bot Token 與目標 chat_id（可與 Workflow 1 共用同一個 Telegram credential，也可另外設定）。
3. 測試時先用 test Webhook URL 手動觸發一次，確認 Telegram 訊息內容正確。
4. 確認無誤後再啟用 workflow，並在需要時設定 `N8N_CODEX_REVIEW_DONE_WEBHOOK_URL` 指向 production Webhook URL。
5. 若未來需要新增更多通知 workflow（例如 Consensus 完成通知），應比照本文件與 Workflow 1 的模式，另外撰寫獨立文件與獨立 JSON 草稿，不要擴大本文件或本草稿範圍。
