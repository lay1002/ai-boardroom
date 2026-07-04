# n8n Workflow 1：Claude 完成通知

## 狀態

本文件為設計文件，非實作紀錄。目前 workspace 內尚無任何已部署或已啟用的 n8n workflow。本文件只描述 Workflow 1 的節點設計與設定建議，不代表已經在任何 n8n 實例中建立或部署。

本文件不屬於任何 Sprint，不對應 `reviews/<sprint-id>/` 下的 Review Bridge 流程。

---

## 版本歷史：為何從 Execute Command 改為 Webhook

初版設計是 `Schedule Trigger → Execute Command → IF → Telegram`，由 Execute Command 節點定時執行 `find` 指令偵測 `claude_report.md`。

實際匯入 n8n 2.25.7 測試後發生：

```text
Unrecognized node type: n8n-nodes-base.executeCommand
```

查證根因：**n8n 從 v2.0 起，基於安全考量（該節點可執行任意 shell 指令），將 Execute Command 節點預設停用**，這是伺服器端的節點白名單/黑名單設定，不是 workflow JSON 內 `type` 欄位寫錯。要重新啟用需要 Product Owner 在 n8n 主機/容器設定環境變數（例如 `N8N_NODES_INCLUDE=n8n-nodes-base.executeCommand`，若無效則需改用 `NODES_EXCLUDE=[]`）並重啟服務，這是伺服器管理動作，不是 workflow 設計問題。

為了避免依賴一個「預設被停用、需要開放任意指令執行權限」的節點，本版改採**更安全的 MVP 設計**：改由外部（Product Owner 手動，或 Claude Code 完成報告後）以 `curl` 呼叫 n8n Webhook 觸發通知，n8n 本身不再主動輪詢、不再存取檔案系統、不再執行任何 shell 指令。

---

## Workflow 目的

當 Claude Code 完成一份 `reviews/<sprint>/round-<round>/claude_report.md` 之後，由外部觸發一個 HTTP 事件，n8n 收到後透過 Telegram 通知 Product Owner：

> Claude Code 已完成 Implementation Report，請手動執行 Codex Review。

這個 workflow 只負責「接收事件 + 通知」，不做任何判斷、審核或後續動作。是否要執行 Codex Review、何時執行，完全由 Product Owner 自行決定。

---

## 節點設計

```text
Webhook Trigger
  ↓
Telegram：通知 Product Owner
```

### 1. Webhook Trigger

- Type: `n8n-nodes-base.webhook`
- HTTP Method: `POST`
- Path: `claude-report-done`
- 純粹被動接收 HTTP 請求，不主動存取檔案系統、不執行任何指令、不呼叫任何外部服務。
- 由誰呼叫、何時呼叫，完全在 n8n 之外決定：
  - Product Owner 手動執行一次 `curl`；或
  - `scripts/review_bridge.sh check` 在確認 `claude_report.md` 為 READY 後，選擇性自動執行一次 `curl`（見下方「Review Bridge 整合」章節）。這是 Review Bridge 對外送出通知，不是 n8n 主動呼叫或觸發 Claude/Codex，n8n 全程只是被動收件者。

#### 觸發範例（Product Owner 或 Claude Code 手動執行）

```bash
curl -X POST "http://<n8n-host>:<port>/webhook/claude-report-done" \
  -H "Content-Type: application/json" \
  -d '{
    "sprint_id": "sprint-008",
    "round_id": "round-001",
    "file_path": "reviews/sprint-008/round-001/claude_report.md"
  }'
```

- `<n8n-host>:<port>` 依實際 n8n 部署位置調整。
- Workflow 未啟用（`active: false`）期間，n8n 只提供 **test 用的 Webhook URL**（通常是 `/webhook-test/claude-report-done`），且必須先在 n8n 編輯畫面按下「Listen for Test Event」或「Execute Workflow」才會接收一次事件；正式的 `/webhook/claude-report-done` production URL 只有在 workflow 被啟用（Active）後才會持續生效。

### 2. Telegram：通知 Product Owner

發送訊息給 Product Owner 的 Telegram 帳號/群組。

#### 訊息模板

```text
Claude Code 已完成 Implementation Report。

Sprint:
{{$json.body.sprint_id}}

Round:
{{$json.body.round_id}}

檔案:
{{$json.body.file_path}}

請 Product Owner 手動執行 Codex Review。

Manual Gate Reminder:
n8n 只通知，不自動執行 Codex。
```

（`{{$json.body.sprint_id}}` 等為 n8n expression 語法，對應 Webhook 節點收到的 JSON body 欄位，實際欄位名稱需與呼叫端 `curl` 送出的 body 一致。）

---

## Review Bridge 整合（可選，非必要）

`scripts/review_bridge.sh check <sprint-id> <round>` 在判定 `claude_report.md` 為 **READY**（存在且非 placeholder）之後，若設定了環境變數 `N8N_CLAUDE_DONE_WEBHOOK_URL`，會自動對該 URL 送出一次 POST 通知，取代原本「Product Owner 或 Claude Code 手動執行一次 `curl`」的動作。這是選配（opt-in）行為，不是 Review Bridge 的必要流程。

### 如何設定 `N8N_CLAUDE_DONE_WEBHOOK_URL`

```bash
export N8N_CLAUDE_DONE_WEBHOOK_URL="http://<n8n-host>:<port>/webhook/claude-report-done"
scripts/review_bridge.sh check <sprint-id> <round>
```

- 未設定此環境變數時，`review_bridge.sh` 的行為與加入這個功能之前完全一致（見下方「不影響原本流程」）。
- 建議先用 test Webhook URL（`/webhook-test/claude-report-done`）測試，確認無誤後再改用 production URL（`/webhook/claude-report-done`，需 workflow 已啟用）。
- POST 的 JSON payload 固定為：

  ```json
  {"sprint_id": "<sprint-id>", "round_id": "round-<round>", "file_path": "<round_dir>/claude_report.md"}
  ```

  三個欄位對應 Telegram 訊息模板中的 `{{$json.body.sprint_id}}`、`{{$json.body.round_id}}`、`{{$json.body.file_path}}`。

### 為什麼這不違反 Manual Gate

- `review_bridge.sh check` 本身**只是唯讀檢查**，原本就會判斷每個 artifact 是 Missing / Placeholder / Ready，這個功能只是在判斷結果為 Ready 時多發一個 HTTP 通知，並未新增任何判斷邏輯、不影響 check 的判定結果或 exit code。
- 通知內容只包含 `sprint_id`、`round_id`、`file_path` 三個事實性欄位，Review Bridge 不會呼叫 Codex、不會呼叫 Claude、不會修改任何檔案、不會執行 `consensus` 或 `finalize`。
- n8n 收到通知後也只轉發 Telegram 訊息，同樣不做任何決策（見「Manual Gate 限制」章節）。
- 是否要執行 Codex Review、何時執行，決策權完全還在 Product Owner 手上；這個功能只是把「Product Owner 原本要手動執行的那次 `curl`」改成由 `check` 命令代勞，通知的**內容與角色分工完全沒有改變**，只是省去人工手動打一次 `curl` 指令的步驟。
- 沒有任何 Auto Claude Loop / Auto Codex Loop / Auto Commit 產生：這個功能不會觸發任何後續動作，只送出一則單向的通知訊息。

### webhook 失敗不影響 Review Bridge 主流程

- `curl` 呼叫使用 `--max-time 5` 限制逾時時間，且失敗時（DNS 失敗、連線被拒、逾時、HTTP 錯誤狀態碼等）只會印出一行 `WARNING: Failed to POST claude_report.md notification ...` 到 stderr，**不會**讓 `check` 的 exit code 變成非 0，也不會影響 Missing / Placeholder / Ready 的判定結果。
- 若系統上根本沒有安裝 `curl`，同樣只印出 WARNING 並略過通知，不會讓 `check` 失敗。
- 已在 `scripts/test_review_bridge.sh` Test 18 驗證：即使把 `N8N_CLAUDE_DONE_WEBHOOK_URL` 指向一個無法連線的位址，`check` 仍然正常回報 `PASS:` 且 exit code 為 0。

### 不影響原本流程

- 沒有設定 `N8N_CLAUDE_DONE_WEBHOOK_URL` 時，`check` 完全不會嘗試任何網路連線，行為與加入這個功能之前逐位元組一致（已由 Test 18a 驗證：輸出中不會出現任何 `WARNING` 或 `N8N_CLAUDE_DONE_WEBHOOK_URL` 字樣）。
- `--dry-run` 搭配已設定的 `N8N_CLAUDE_DONE_WEBHOOK_URL` 時，只會印出 `[dry-run] Would POST claude_report.md notification ...`，不會真的呼叫 `curl`（已由 Test 18c 驗證）。

---

## Manual Gate 限制

依 `docs/development/development-workflow.md` 第 5 節 Manual Gate Policy 與 `docs/development/consensus-workflow.md` 的 Manual Gate Policy，本 workflow 必須遵守：

- 不自動觸發 Codex Review。
- 不自動觸發 Claude Code 的任何後續動作。
- 不自動修改程式碼。
- 不自動 commit。
- 不在 n8n 內做任何「決策」，例如判斷 Review 是否該通過、判斷是否該進入下一輪。
- 所有後續動作（執行 Codex Review、撰寫 `codex_review.md` 等）皆由 Product Owner 或對應 AI 角色手動觸發，n8n 只負責讓 Product Owner「知道」有新的 `claude_report.md` 出現。
- Webhook 只被動接收，不主動輪詢、不主動掃描檔案系統，進一步降低 n8n 端的權限需求（不需要任何 shell 執行權限）。

---

## 不做的事情

- 不新增 AI Runner（n8n 不呼叫任何 LLM API）。
- 不新增 Workflow Engine（這不是 AI Decision Assistant V3 產品內的 `Workflow Engine`，只是外部的通知自動化工具）。
- 不新增 Platform。
- 不自動呼叫 Codex CLI 或 Codex API。
- 不自動呼叫 Claude Code。
- 不自動修改任何程式碼或 review artifact。
- 不自動執行 `scripts/review_bridge.sh` 的任何 command（`init` / `skeleton` / `check` / `consensus` / `finalize` 皆不在本 workflow 範圍）。
- 不處理 Codex Review、Claude Reply、Codex Final Review、Consensus、Final Consensus 任何後續步驟的通知（僅限 Workflow 1：Claude 完成通知）。
- 不建立新的 Sprint。
- 不修改 Review Bridge 或 Consensus Algorithm。
- 不在 n8n 內執行任何 shell 指令或存取檔案系統（本版已移除 Execute Command 節點）。

---

## 可匯入 JSON 草稿

已提供最小可用草稿：

```text
configs/n8n/claude-done-notification.workflow.json
```

內含 2 個節點（Webhook Trigger → Telegram Send Message），節點參數與本文件上方「節點設計」章節一致。此檔案是**匯入草稿**，不是已部署或已啟用的 workflow：

- 檔案內 `active` 欄位為 `false`。
- Telegram 節點的 `credentials` 為空物件，`chatId` 為明顯的佔位字串 `REPLACE_WITH_PRODUCT_OWNER_CHAT_ID`，尚未設定任何真實憑證或收件對象。
- 各節點附有 `notes` 欄位，複述 Manual Gate 限制與根因說明，方便在 n8n 介面內直接看到提醒。

### 如何匯入

1. 開啟 n8n 介面（Product Owner 自行登入，本文件與草稿檔案本身不執行任何登入動作）。
2. 使用 n8n 的「Import from File」（或貼上 JSON 內容的「Import from URL/Clipboard」）功能，選擇 `configs/n8n/claude-done-notification.workflow.json`。
3. 匯入後會產生一個名為「Workflow 1 - Claude 完成通知 (DRAFT - DO NOT ACTIVATE)」的 workflow，狀態為未啟用。

### 匯入後需要手動設定 Telegram credential

- Telegram Send Message 節點目前沒有附帶任何 credential。
- Product Owner 需在 n8n 的 Credentials 介面手動新增 Telegram Bot Token，並在該節點重新指定要使用的 credential。
- 同時需要把 `chatId` 欄位的佔位字串 `REPLACE_WITH_PRODUCT_OWNER_CHAT_ID` 換成實際要接收通知的 chat_id。
- 這兩項憑證/收件人設定完全由 Product Owner 在 n8n 介面內操作，不包含在這份 JSON 草稿或本文件的交付範圍內。

### 匯入後不要立刻啟用

- 匯入完成、設定好 Telegram credential 與 chatId 之後，**先用手動執行（Manual Execute / Listen for Test Event）測試整個流程**，確認：
  - Webhook 能正確收到 `curl` 送出的 test 事件。
  - Telegram 訊息格式、`{{$json.body.sprint_id}}` / `{{$json.body.round_id}}` / `{{$json.body.file_path}}` 內容正確帶入實際傳入值。
- 確認測試結果正確後，才由 Product Owner 自行決定是否啟用（打開 workflow 右上角 Active 開關），啟用後 production Webhook URL 才會持續生效。本草稿刻意保持 `active: false`，啟用與否是 Product Owner 的手動決定，不是本文件或 JSON 草稿的一部分。

### 目前版本沒有去重機制，可能重複通知

- 若同一個 `claude_report.md` 被多次呼叫 `curl` 觸發（例如 Product Owner 或 Claude Code 重複執行），Webhook 會每次都觸發一次 Telegram 通知，沒有任何比對「是否已通知過同一個檔案」的邏輯。
- 本次 JSON 草稿**沒有新增任何去重邏輯**（例如記錄已通知過的檔案路徑、比對前次觸發內容），維持最小範圍。若之後需要去重，應視為獨立的後續調整項目，由 Product Owner 決定是否要做，不在本草稿內預先實作。

### 這不是 AI Runner，也不是自動化 Codex 流程

- 本 workflow 全程只有「接收 HTTP 事件 → 發 Telegram 訊息」兩個動作，沒有任何節點呼叫 LLM API、Claude、Codex CLI 或任何 AI 服務。
- Webhook 節點只被動接收外部傳入的 JSON，不讀寫任何檔案，也不觸發 `scripts/review_bridge.sh` 或任何 Review Bridge 指令。
- 沒有任何節點會建立、修改或提交（commit）程式碼、Sprint、review artifact。
- 呼叫 Webhook 的動作（`curl`）發生在 n8n 之外，由 Product Owner 或 Claude Code 手動執行一次性通知，n8n 收到後不會回頭觸發或呼叫任何 Claude/Codex 流程，是否要執行 Codex Review、何時執行，完全交由 Product Owner 收到通知後手動決定與操作。

## Product Owner 後續設定建議

以下是设定建議，非本文件已完成的部署動作：

1. 依上方「如何匯入」章節，將 `configs/n8n/claude-done-notification.workflow.json` 匯入 n8n。
2. Telegram 節點需要 Product Owner 自行在 n8n 設定 Telegram Bot Token 與目標 chat_id（屬於 n8n credential 設定，不在本文件範圍內處理）。
3. 測試時先用 test Webhook URL（需先在編輯畫面按下「Listen for Test Event」）搭配上方 `curl` 範例手動觸發一次，確認 Telegram 訊息內容正確。
4. 確認無誤後再啟用 workflow，並改用 production Webhook URL（`/webhook/claude-report-done`）。
5. 若之後想讓「Claude Code 完成報告時自動呼叫這個 Webhook」成為固定流程的一部分，這是另一個獨立的決定（涉及是否要在 Claude Code 的工作流程中加入一個對外通知步驟），需要 Product Owner 另行明確要求，不在本次任務範圍內實作。
6. 若未來需要新增更多 workflow（例如 Codex Review 完成通知），應比照本文件模式，另外撰寫獨立文件與獨立 JSON 草稿，不要擴大本文件或本草稿範圍。

---

# Validation Result

以下驗證結果由 Product Owner 在實際 n8n / Telegram / Production Webhook 環境中執行並回報確認，非本文件或 Claude Code 自行執行驗證（Claude Code 無法登入 n8n 或存取 Telegram）。第 8 項（既有測試通過數）已由 Claude Code 重新執行 `scripts/test_review_bridge.sh` 獨立覆核。

## Environment

- **Review Bridge**：`scripts/review_bridge.sh check`，本機/CI 執行，已加入可選的 `N8N_CLAUDE_DONE_WEBHOOK_URL` 通知邏輯。
- **n8n**：Workflow 1（Claude 完成通知），已由 Product Owner 匯入 `configs/n8n/claude-done-notification.workflow.json` 並啟用。
- **Telegram**：Telegram Bot credential 已由 Product Owner 在 n8n 完成設定，通知對象為 Product Owner 本人。
- **Production Webhook**：`https://<your-n8n-host>/webhook/claude-report-done`（實際部署時對應 Product Owner 的 n8n 正式主機位址；此處以佔位格式記錄，避免在文件中暴露真實 host）

## Verification

驗證完成：

- [x] review_bridge.sh check 成功送出 Webhook
- [x] n8n 成功接收
- [x] Telegram 成功通知
- [x] 未設定 Webhook 時保持原行為
- [x] Webhook 失敗不影響主流程
- [x] Manual Gate 保留

補充：

- 「未設定 Webhook 時保持原行為」與「Webhook 失敗不影響主流程」兩項，除 Product Owner 的實機驗證外，亦已由 `scripts/test_review_bridge.sh` Test 18（18a / 18b / 18c）以自動化測試覆蓋，本次覆核重新執行仍為 **64 passed, 0 failed**。

## Architecture Confirmation

再次確認：

```text
Notification 可以自動。
Decision 不可以自動。
```

目前流程：

```text
Claude Code
  ↓
Review Bridge
  ↓
n8n Webhook
  ↓
Telegram
  ↓
Product Owner
  ↓
Codex Review（手動）
```

說明：

- 從 `Claude Code` 到 `Product Owner` 收到 Telegram 通知為止，全部是**單向、事實性的通知傳遞**，沒有任何一個節點做出「是否該進入下一步」的判斷。
- 從 `Product Owner` 到 `Codex Review` 這一步，是流程圖中唯一標示「（手動）」的環節，也是唯一涉及「決策」的環節：是否執行 Codex Review、何時執行，由 Product Owner 決定並手動觸發，不由 Review Bridge 或 n8n 代為決定。
- 這與 Sprint-002 補件過程中反覆確認的原則一致：Claude Code 不得扮演 Reviewer AI、Review Bridge 不得自動判斷 Gate 是否該通過並觸發下一步、n8n 只通知不決策。本次驗證的 Production Webhook 打通，改變的是「通知這件事本身有沒有自動化」，沒有改變「決策仍然 100% 由人工執行」這個事實。

## Lessons Learned

1. **為什麼 Execute Command 被放棄**：n8n 從 v2.0 起基於安全考量，將 Execute Command 節點（可執行任意 shell 指令）預設停用，這是伺服器端的節點白名單設定，不是 workflow JSON 的 `type` 欄位寫錯；换成任何其他 type 字串都無法讓已停用的節點重新被識別。
2. **為什麼改用 Webhook**：Webhook Trigger 只被動接收外部傳入的 HTTP 請求，不需要在 n8n 端開放任何 shell 執行權限，也不需要 Product Owner 為了重新啟用 Execute Command 而修改 n8n 伺服器層級設定、承擔開放任意指令執行的安全風險。
3. **Webhook 比 Execute Command 更符合安全性**：Execute Command 節點的攻擊面是「任意 shell 指令執行」，一旦被停用又被強制重新啟用，等於對整個 n8n 實例開放高風險能力；Webhook 節點的攻擊面僅限於「接收哪些 HTTP request 觸發哪個既定流程」，且本設計中 payload 內容只有三個事實性欄位（`sprint_id`/`round_id`/`file_path`），沒有任何指令注入或檔案系統存取的路徑。
4. **本方案符合 MVP First**：從最初 4 節點（Schedule Trigger → Execute Command → IF → Telegram）到最終 2 節點（Webhook Trigger → Telegram），節點數量與複雜度不增反減；`review_bridge.sh` 的整合也只新增一個 best-effort、預設關閉（未設定環境變數即不啟用）的通知函式，沒有引入任何新的常駐服務或背景輪詢機制。
5. **沒有新增任何 AI Runner**：全流程（Review Bridge → n8n Webhook → Telegram）沒有一個環節呼叫任何 LLM API、Claude Code 或 Codex CLI；`review_bridge.sh` 新增的程式碼只有一次 `curl POST`，內容是三個事實欄位的 JSON，不含任何 AI 推論或生成內容。
6. **沒有新增任何 Workflow Engine**：n8n workflow 本身、以及 `review_bridge.sh` 的通知函式，都不是 AI Decision Assistant V3 產品定義的 `Workflow Engine`（AGENTS.md 第 0.4、7.5 節），純粹是外部的、與產品 Runtime 無關的通知自動化工具。
7. **沒有違反 Manual Gate Policy**：`docs/development/development-workflow.md` 第 5 節與 `docs/development/consensus-workflow.md` 的 Manual Gate Policy 禁止 Auto Claude Loop、Auto Codex Loop、Auto Commit、以及未經 Product Owner 可見即自動進入下一輪；本方案全程只送出通知，不觸發任何後續動作，Codex Review 是否執行、何時執行，仍 100% 由 Product Owner 手動決定，與 Manual Gate Policy 完全一致。
