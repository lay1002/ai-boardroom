# Telegram PO Gate Notification Specification

Version: 1.1 (Sprint-014, wording clarified in Sprint-016)

## 1. Sprint-014 目的

Sprint-013 建立了 8 個「事件」（`*_done`）的 Telegram 通知（`scripts/review_bridge.sh notify`）。Sprint-014 在此基礎上，額外接入 21 個 **Product Owner Gate**（`docs/development/consensus-workflow.md` 中需要 Product Owner 明確核准才能繼續的節點），讓 Product Owner 在每一個需要做決策的節點都能收到繁體中文、適合手機閱讀與複製操作的 Telegram 通知。

Sprint-013 的 `notify` 指令與其 8 個事件、其測試，完全不受影響（見第 15 節）。Sprint-014 新增的是一個獨立、附加（additive）的 `notify-gate` 指令與其自己的 Gate whitelist。

## 2. 21 個 Product Owner Gate 清單

```text
sprint_start_approval
architecture_definition_approval
architecture_artifact_approval
claude_implementation_approval
claude_implementation_report_acceptance
codex_review_approval
codex_review_result_decision
claude_must_fix_approval
claude_must_fix_report_acceptance
codex_final_review_approval
codex_final_review_result_decision
product_owner_validation_approval
codex_git_review_approval
codex_git_review_result_decision
commit_approval
codex_commit_approval
push_approval
codex_push_approval
retrospective_entry_approval
retrospective_content_approval
product_owner_closure_approval
```

高風險 Gate（Commit / Push 類，必須使用高風險格式，見第 6 節）：

```text
commit_approval
codex_commit_approval
push_approval
codex_push_approval
```

## 3. Gate Metadata Contract

每個 Gate 在 runtime（`scripts/review_bridge.sh`）中必須解析出以下 metadata：

| 欄位 | 說明 |
|---|---|
| `gate_id` | whitelist 中的其中一個 ID |
| `gate_name_zh` | Gate 的繁體中文名稱 |
| `sprint_id` / `round_id` | 由 CLI 參數提供 |
| `notification_recipient` | 固定為 `Product Owner` |
| `next_actor` | `Product Owner` / `ChatGPT` / `Claude Code` / `Codex` 其中之一 |
| `recommended_execution_mode` | `docs/development/execution-permission-policy.md` 定義的 7 個 mode 之一，或 `N/A（Product Owner 決策點）` |
| `risk_level` | `low` / `medium` / `high` 其中之一 |
| `current_status_zh` | 目前狀態的繁體中文敘述 |
| `product_owner_next_action_zh` | Product Owner 下一步該做什麼的繁體中文敘述 |
| `handoff_package` | 可複製的交接內容（引用來源 artifact） |
| `delivery_metadata` | 見第 12 節 |

這 21 個 Gate 的實際中文名稱、`next_actor`、`recommended_execution_mode`、`risk_level`、狀態與下一步文字，原為 Sprint-014 Architecture 未逐一列出的實作填補（見 `reviews/sprint-014/round-001/architecture.md` 第 0 節與 `claude_report.md`）。**自 Sprint-016 起，這些值已正式 canonicalize 為 `docs/development/product-owner-gate-metadata.md`**——該文件是 21 個 Gate metadata 的 canonical source of truth，本節第 46–62 行的欄位定義與該文件第 2 節完全對應；`scripts/review_bridge.sh` 的 `_gate_resolve_metadata()` 是這份 canonical metadata 的 runtime 實作，兩者內容逐字一致（見 `product-owner-gate-metadata.md` 第 5 節）。若要查詢或調整任一 Gate 的實際中文名稱、`next_actor`、`recommended_execution_mode`、`risk_level`、狀態與下一步文字，請以 `docs/development/product-owner-gate-metadata.md` 第 4 節為準，而非本文件重複維護一份副本。

## 4. Notification Package Contract

每個 Gate 的 Notification Package 至少必須包含：

```text
project_id, project_name, sprint_id, round_id, gate_id, gate_name_zh, event_type,
notification_recipient, next_actor, recommended_execution_mode, risk_level,
current_status_zh, product_owner_next_action_zh, handoff_package, delivery_channel,
delivery_status, created_at, delivery_metadata
```

`event_type` 的值固定等於 `gate_id`（Gate 本身就是它自己的事件，不另外定義一組事件命名）。

Notification Package **本身就是**渲染好的繁體中文 Telegram 版面（第 6 節模板套入實際值後的結果）：Project ID / Project Name / Created Time / Delivery Status / Risk Level 這些沒有直接出現在模板可讀段落中的欄位，統一放進「🧾 Delivery Metadata」區塊（該區塊本來就位於訊息最後），藉此讓 Notification Package 檔案同時滿足「必須包含完整欄位」與「必須是可直接送出的 Telegram 版面」兩項要求，而不需要另外維護一份分離的資料結構。

## 4.1 `notify-gate` CLI Usage

```bash
PROJECT_ID=<project-id> PROJECT_NAME="<Project Name>" \
  scripts/review_bridge.sh notify-gate <gate-id> <sprint-id> <round> <artifact-path> [--dry-run]
```

- `<gate-id>` 必須是第 2 節 21 個 whitelist 之一，其餘值會被拒絕（`Invalid gate_id`）。
- `<sprint-id>` / `<round>` 規則與 `notify`（Sprint-013 事件通知）相同，見 `docs/development/notification-package-specification.md`。
- `<artifact-path>` 是這個 Gate 的 Handoff Package 要引用的來源 artifact，可為相對於 repo root 的相對路徑，或絕對路徑。
- 需要 `PROJECT_ID`、`PROJECT_NAME` 環境變數；若要實際送達 Telegram，另需 `NOTIFICATION_ENABLED=true`、`TELEGRAM_BOT_TOKEN`、`TELEGRAM_CHAT_ID`（與 `notify` 共用同一組環境變數）。
- `--dry-run` 只印出將會寫入的路徑與是否會嘗試送出，不實際寫檔、不呼叫 Telegram API、不寫入 Notification History。
- 範例：`PROJECT_ID=ai-workspace PROJECT_NAME="AI Workspace" scripts/review_bridge.sh notify-gate codex_review_approval sprint-016 001 reviews/sprint-016/round-001/claude_report.md`

## 5. Telegram message layout

Telegram message 內容即 Notification Package 檔案的完整原文（逐位元組），只在超過 Telegram 訊息長度限制時，依字元切分成多則訊息依序送出，不做任何摘要、改寫或重新詮釋（沿用 Sprint-013 Must Fix 1 已驗證的機制，見 `scripts/review_bridge.sh` 的 `_notify_split_for_telegram`）。

## 6. 一般 Gate 格式

```text
🔔 AI Workspace Gate 通知

📌 Sprint
{sprint_id} / {round_id}

🧭 目前 Gate
{gate_name_zh}

📍 目前狀態
{current_status_zh}

👤 通知對象
Product Owner

➡️ 下一位執行者
{next_actor}

⚙️ 建議執行模式
{recommended_execution_mode}
{execution_mode_summary_zh}

✅ Product Owner 下一步
{product_owner_next_action_zh}

📦 Handoff Package
---
{handoff_package}
---

🧾 Delivery Metadata
gate_id: {gate_id}
event_type: {event_type}
project_id: {project_id}
project_name: {project_name}
notification_recipient: Product Owner
next_actor: {next_actor}
risk_level: {risk_level}
delivery_channel: telegram
delivery_status: {delivery_status}
created_at: {created_at}
```

## 7. 高風險 Gate 格式

適用於 `commit_approval`、`codex_commit_approval`、`push_approval`、`codex_push_approval`：

```text
⚠️ 高風險 Gate：{gate_name_zh}

📌 Sprint
{sprint_id} / {round_id}

📍 目前狀態
{current_status_zh}

⚠️ 風險提醒
此步驟可能涉及 Commit / Push，必須確認範圍、commit hash、remote / branch 與排除檔案。

👤 通知對象
Product Owner

➡️ 下一位執行者
{next_actor}

⚙️ 建議執行模式
{recommended_execution_mode}
{execution_mode_summary_zh}

✅ Product Owner 下一步
{product_owner_next_action_zh}

📦 Handoff Package
---
{handoff_package}
---

🧾 Delivery Metadata
gate_id: {gate_id}
event_type: {event_type}
project_id: {project_id}
project_name: {project_name}
notification_recipient: Product Owner
next_actor: {next_actor}
risk_level: high
delivery_channel: telegram
delivery_status: {delivery_status}
created_at: {created_at}
```

**Sprint-016 wording clarification — 高風險格式必須包含的元素**：套用本節格式的 4 個 Gate（`commit_approval`、`codex_commit_approval`、`push_approval`、`codex_push_approval`），其 Notification Package 內容必須同時滿足：

1. 標題使用 `⚠️ 高風險 Gate：` 前綴（不得使用第 6 節的一般 `🔔` 標題）。
2. 包含獨立的「⚠️ 風險提醒」區塊，明確指出此步驟涉及 repository state / remote state 變更。
3. Delivery Metadata 的 `risk_level` 固定顯示 `high`（不可省略、不可顯示其他值）。
4. Product Owner 下一步文字必須明確要求 Product Owner 親自確認 scope / commit hash / remote / branch 等細節，不得只寫「請核准」這種空泛文字。

這些元素的具體規則見 `docs/development/execution-permission-policy.md` Safety Level 3（高風險/需 Manual Gate 操作）。

## 8. next_actor 規則

`next_actor` 只能是以下四者之一：`Product Owner`、`ChatGPT`、`Claude Code`、`Codex`。`next_actor` 與 `notification_recipient`（固定 `Product Owner`）是兩個獨立欄位，不得混用（沿用 Sprint-013 Must Fix 2 的原則）。當 Gate 的結果需要 Product Owner 自行判斷是否轉交下一位執行者時，`next_actor` 保守標示為 `Product Owner`。

## 9. recommended_execution_mode 規則

值必須是 `docs/development/execution-permission-policy.md` 定義的 7 個 mode 名稱之一（`Claude Implementation Mode`、`Claude Must Fix Mode`、`Codex Review Mode`、`Codex Final Review Mode`、`Codex Git Review Mode`、`Codex Commit Mode`、`Codex Push Mode`），或是 `N/A（Product Owner 決策點）` / `N/A（Commit 需人工核准，不可低中斷）` / `N/A（Push 需人工核准，不可低中斷）` 這類代表「本 Gate 是純 Product Owner 決策點，沒有對應的 AI 執行 mode」的值。`execution_mode_summary_zh` 是該 mode 的中文摘要，定義於 execution-permission-policy.md 並在 runtime 中集中維護，確保多個 Gate 引用同一個 mode 時文字一致。

## 10. risk_level 規則

值只能是 `low`、`medium`、`high`。`commit_approval`、`codex_commit_approval`、`push_approval`、`codex_push_approval` 固定為 `high`，並套用第 7 節高風險格式；其餘 17 個 Gate 依語意標示 `low` 或 `medium`（例如緊接在 Commit 之前的 `codex_git_review_approval` / `codex_git_review_result_decision` 標示為 `medium`）。

## 11. Handoff Package 規則

`handoff_package` 必須獨立成可複製區塊（`📦 Handoff Package` 與前後 `---` 分隔線之間），內容包含：來源 artifact 路徑、Sprint/Round/Gate 資訊、若 Product Owner 決定轉交時的 next_actor 提示、Product Owner 下一步文字。此區塊不得與 Delivery Metadata 或其他區塊混雜，確保 Product Owner 可以整段複製貼上轉交給下一位執行者。

## 12. Delivery Metadata 規則

`🧾 Delivery Metadata` 區塊必須位於訊息最後，包含 `gate_id`、`event_type`、`project_id`、`project_name`、`notification_recipient`、`next_actor`、`risk_level`、`delivery_channel`、`delivery_status`、`created_at`。高風險 Gate 的 `risk_level` 固定顯示 `high`。

`delivery_status` 在 Notification Package 檔案本身固定顯示 `pending`（產生當下、尚未嘗試送出前的狀態，避免送出內容與檔案內容不一致，原則同 Sprint-013 Must Fix 4）；實際送出結果記錄在 Notification History（見第 14 節）。

**Sprint-016 wording clarification — Notification Package Status 與 Actual Delivery Status 的區別**：本規格明確區分兩個不同的概念，避免 Product Owner 誤解：

- **Notification Package Status**：即 Notification Package 檔案裡 `delivery_status:` 欄位顯示的值，一律是 `pending`。這只代表「Notification Package 產生的當下、尚未嘗試送出前」的狀態，是一個時間點快照，**不代表**訊息是否真的送達 Telegram。
- **Actual Delivery Status**：Telegram 實際送出後的真實結果（`delivered` / `failed` / `disabled`），只記錄在 `reviews/notification_history.jsonl`（見第 14 節），不會回寫進 Notification Package 檔案。

因此，Product Owner 若在 Telegram 收到的訊息裡看到 `delivery_status: pending`，這只是「這份 Package 產生時的狀態標記」，**不是** Telegram 尚未送達的意思（因為 Product Owner 能收到這則訊息，本身就代表送達已經成功）。若要查詢某次通知實際是否送達，必須查 `reviews/notification_history.jsonl` 對應紀錄的 `delivery_status` 欄位（該檔案裡的同名欄位才是 Actual Delivery Status），不得以 Notification Package 檔案內的 `delivery_status: pending` 做為送達與否的依據。

## 13. 禁止事項

Sprint-014 不得實作：Telegram button 自動執行、n8n Execute Command、自動呼叫 Claude / Codex、自動 commit、自動 push、完全 bypass sandbox、AI Auto Loop、Telegram 按鈕直接觸發本機終端機、自動核准 Product Owner Gate、多使用者權限管理、Web UI、Notification Center。

## 14. Notification History

Gate 通知的送出結果記錄於既有的 `reviews/notification_history.jsonl`（與 Sprint-013 事件通知共用同一個 append-only 檔案），每筆紀錄額外包含 `"record_type": "gate"` 與 `gate_id`、`risk_level` 欄位以與 Sprint-013 的事件紀錄區分。

Gate 通知**不做去重（deduplication）**：每次 Gate 被觸發都代表一個新的、需要 Product Owner 決策的時間點，即使 gate_id 與 artifact 相同也應該重新通知（例如同一個 Gate 因故被重新觸發），因此不套用 Sprint-013 事件通知的 artifact-hash 去重機制。這是 Sprint-014 的實作填補判斷，記錄於 `claude_report.md`，若 Product Owner 認為需要去重，可在未來 Sprint 明確要求。

## 15. Artifact-first 原則

1. Notification Package 是 Gate notification 的 SSOT。
2. Telegram message 必須由 Notification Package 產生（逐位元組，見第 5 節）。
3. Delivery Adapter（Telegram 送出邏輯）不得重新組語意，只負責 transport。
4. 若有格式化（第 6/7 節模板），格式化規則可完全追溯到 Notification Package 內容本身——因為 Notification Package 檔案的內容就是套用模板後的結果，不是另外維護的資料結構。

## 16. Product Owner Manual Gate 原則

本規格不改變、不繞過 `docs/development/consensus-workflow.md` 定義的 Manual Gate。Telegram 通知是「讓 Product Owner 更方便知道現在該做決策」的輔助管道，不會自動核准任何 Gate、不會自動呼叫 Claude Code 或 Codex、不會自動進入下一個 Gate。送出失敗（`disabled` / `failed`）不會阻擋既有 Review Bridge 流程，通知永遠是 best-effort。

**Sprint-016 wording clarification — Commit / Push Gate 必須 Product Owner Manual Gate**：`commit_approval`、`codex_commit_approval`、`push_approval`、`codex_push_approval` 這 4 個 Gate，對應 `docs/development/execution-permission-policy.md` 的 Safety Level 3（`git add`、`git commit`、`git push` 皆屬 Level 3）。這代表：

1. 不論 Telegram 通知是否送達、Product Owner 是否已讀，這 4 個 Gate 的核准**只能**由 Product Owner 本人在 Telegram 或其他管道外，用明確的、獨立的核准動作完成，Notification Package 或 Telegram message 本身**不構成**核准，也不會觸發任何自動核准。
2. Codex 在 Codex Commit Mode / Codex Push Mode 下只能準備草案與檢查清單，不得自行執行 `git add` / `git commit` / `git push`（見 `execution-permission-policy.md` 2.6/2.7）。
3. 這 4 個 Gate 不適用本規格第 3 節「是否允許 sandboxed read-only auto-approval」欄位以外的任何自動化——即使是 Level 0 唯讀指令，也只能用於「準備」核准所需的資訊（例如 `git status --short`、`git log -1 --oneline`），不得被誤用為「已經檢查過所以可以自動核准」的依據。

## 17. 與 Sprint-013 的關係

本規格與 `docs/development/notification-package-specification.md`（Sprint-013 事件通知規格）並存，互不修改對方定義的事件白名單或欄位契約。`scripts/review_bridge.sh` 以獨立的 `notify-gate` 指令、獨立的 21-Gate whitelist、獨立的 metadata 解析函式提供本規格的功能，`notify` 指令與其 8 個事件行為完全不變。
