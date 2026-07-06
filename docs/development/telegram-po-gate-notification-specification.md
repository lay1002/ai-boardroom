# Telegram PO Gate Notification Specification

Version: 1.7 (Sprint-014, wording clarified in Sprint-016; notify-gate Execution Policy, Manual/Formal distinction, inline artifact content, Product Owner Summary, Next AI Handoff Package, Telegram Content Mode, and section-aware standalone message split requirements added in Sprint-017)

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

## 18. notify-gate Execution Policy（Sprint-017）

1. **Claude / Codex 不得自動觸發 Telegram**。`scripts/review_bridge.sh` 中沒有任何函式會在完成實作、Review 或產生 Handoff Package 之後，自動呼叫 `cmd_notify_gate`——`notify-gate` 只能透過人在終端機明確輸入指令觸發，不存在任何程式內部呼叫路徑。
2. **Product Owner 決定是否手動執行 `notify-gate`**。是否要讓 Product Owner 收到某個 Gate 的 Telegram 通知，由 Product Owner 自行判斷並執行指令，不是 Claude Code 或 Codex 的決定。
3. **`notify-gate` 屬於外部通知操作，預設需要 Product Owner 明確允許**——即使 Handoff Package 已經包含第 6 節要求的「Telegram Notification」區塊（說明「應不應該通知」與相關欄位），這個區塊本身只是**建議與資訊**，不構成執行授權，也不會自動觸發任何送出動作。
4. 正確 CLI 格式：

   ```bash
   ./scripts/review_bridge.sh notify-gate <gate_id> <sprint_id> <round_id> <artifact_path>
   ```

   **第一個參數是 `gate_id`，不是 `sprint_id`**——這是最容易搞混的地方，必須明確記住順序：`gate_id` → `sprint_id` → `round_id` → `artifact_path`。
5. **Claude Code 不得執行 `notify-gate`**。這包含：不得在完成實作後自行執行、不得在 Handoff Package 中建議「已經執行」、不得假設 Product Owner 一定會執行。

## 19. Manual Handoff vs. Formal Telegram Gate Notification（Sprint-017）

Handoff Package 有兩種截然不同的交付方式，必須明確區分，不得混淆：

### 19.1 聊天中手動交接（Manual Handoff）

Product Owner 直接在 ChatGPT（或 Claude Code / Codex）對話中取得 Handoff Package 內容，並手動複製給下一位執行者（Claude Code 或 Codex）。

**此模式不代表 Telegram 已通知。** 不論這份 Handoff Package 內容多正式、多完整，只要沒有實際執行 `notify-gate`，就不構成「Product Owner 已收到 Telegram 通知」。

### 19.2 正式 Telegram Gate Notification

Product Owner 明確允許並執行 `notify-gate`，使 Telegram 收到正式 Gate Notification（見第 4/6/7 節的訊息格式）。

**只有實際執行 `notify-gate` 且 Telegram 收到通知後，才可記錄為正式 Telegram Gate Notification 完成。** 任何報告、Retrospective、或 Handoff Package 都不得把「聊天中手動交接」誤記為「Telegram 通知已完成」——這兩者是完全獨立的事件，即使內容相同。

## 20. Handoff Package 必須內嵌 Artifact 內容，不得只給路徑（Sprint-017 Must Fix Round 3）

Product Owner 在實際收到 Telegram Gate Notification 後回報：Handoff Package 區塊只寫「請閱讀：- \<path\>」，逼得 Product Owner 必須離開 Telegram、自行到 repository 打開檔案才能看到內容。這不符合「Product Owner 可以直接在 Telegram 上複製使用」的原始目的。

### 20.1 規則

1. `cmd_notify_gate`（`scripts/review_bridge.sh`）產生的「📦 Handoff Package」區塊，**必須內嵌來源 artifact 的實際內容**，不得只給檔案路徑。
2. 內嵌內容是**直接讀取同一個 artifact_path 檔案的原文**（`cat` 該檔案），不是重新摘要、改寫或詮釋——這與 Sprint-013 Must Fix 1「Telegram 傳送內容必須是 artifact 原文」的 Artifact First 原則完全一致，只是把「原文」的範圍從「整個 Notification Package」擴大到「Notification Package 裡引用的來源 artifact 也要原文內嵌」。
3. 內嵌內容必須以明確的起訖標記包住（`===== BEGIN ARTIFACT CONTENT (...) =====` / `===== END ARTIFACT CONTENT =====`），確保即使被 Telegram 訊息長度限制切成多則訊息，人類讀者仍能辨識內嵌內容的起訖範圍，不會與其他欄位混淆。
4. 此規則適用於全部 21 個 Gate，不是只適用於曾經被實際執行過的少數 Gate——`scripts/test_review_bridge.sh` Test 28 對全部 21 個 gate_id 分別驗證內嵌內容確實存在。

### 20.2 過長內容的安全切分（Safe Chunking）

Notification Package（包含新內嵌的 artifact 內容）整體仍然透過既有的 `_notify_split_for_telegram`（Sprint-013 Must Fix 1 已驗證）依字元數切分成多則訊息，**依序**送出，不做任何重新排序、摘要或改寫：

1. 切分永遠保持原始文字的先後順序——訊息 1、2、3...的內容串接起來就是完整的原始檔案，沒有亂序風險。
2. 若 artifact 內容非常長，切分點可能落在某一行的中間，這是已知且可接受的限制（Telegram 訊息長度限制本身無法避免這一點）；但因為是連續、依序送出，Product Owner 依訊息接收順序閱讀即可正確重建完整內容。
3. 不會因為內容過長而截斷、省略或只取部分內容——所有內容都會送出，只是可能分成多則訊息。
4. 這個切分機制是既有機制的直接重用，本次 Must Fix 未修改 `_notify_split_for_telegram` 本身的行為。

## 21. Product Owner Summary — 正式 Telegram Gate Notification 必須先給繁體中文摘要（Sprint-017 Must Fix Round 4）

Product Owner 實際收到內嵌 artifact 內容的 Telegram 通知後回報：內嵌內容大多是英文的 Codex report，Product Owner 必須先自行閱讀、理解這些英文內容，才能做出決策，這違背了「Telegram 通知應該讓 Product Owner 直接看懂、直接決策」的目的。

### 21.1 規則

1. `notify-gate` 新增第 5 個**選用**參數 `summary_path`：

   ```bash
   ./scripts/review_bridge.sh notify-gate <gate_id> <sprint_id> <round_id> <artifact_path> [summary_path]
   ```

2. 當 `summary_path`有提供時，`cmd_notify_gate` 會把該檔案的內容**逐字內嵌**在「📦 Handoff Package」區塊中、置於 `===== BEGIN ARTIFACT CONTENT =====` **之前**，標題為「🇹🇼 Product Owner Summary（繁體中文摘要，請先讀這裡）」。
3. 當 `summary_path` **未提供**時，行為與 Sprint-017 Must Fix Round 3 完全相同（不會出現這個區塊）——這是向下相容的選用功能，不影響既有呼叫方式。
4. 若 `summary_path` 有提供但檔案不存在，`notify-gate` 會直接失敗（`Summary artifact not found: <path>`），不會靜默略過。
5. 原始 artifact 內容（第 20 節內嵌規則）仍然保留在 Product Owner Summary **之後**，作為佐證，Product Owner 可以視需要往下捲動查看完整原始資料，但**必須光靠 Product Owner Summary 就能理解這次要做什麼決策**，不需要先讀完原始內容。

### 21.2 Product Owner Summary 必須包含的內容

Product Owner Summary 是**由呼叫 `notify-gate` 的人**（目前是 Claude Code 依 Product Owner 指示準備，未來也可能是 Product Owner 自己撰寫）另外準備的一份繁體中文檔案，內容至少必須包含：

1. Sprint ID / Round
2. gate_id
3. 目前 Gate 的中文名稱（對應 `docs/development/product-owner-gate-metadata.md` 的 `gate_name_zh`）
4. 目前狀態的中文敘述（對應 `current_status_zh`）
5. Codex Final Review 結果（PASS / FAIL / 尚未進行）
6. 剩餘 Must Fix（無 / 清單）
7. Should Fix（無 / 清單）
8. 測試結果（例如 `bash scripts/test_review_bridge.sh` 的通過/失敗筆數）
9. 21 Gate contract coverage 結果（例如「PASS，21/21」，不得與 live delivery 混為一談，見第 21.3 節）
10. Live Telegram delivery coverage 狀態（例如「1/21，僅本次 Gate 已實際送達」）
11. Product Owner 下一步決策（對應 `product_owner_next_action_zh`）
12. Telegram 是否已經實際送出或仍為 pending 的說明

**這份摘要不是由 `cmd_notify_gate` 自動產生的**——`cmd_notify_gate` 是通用、跨 Sprint 的基礎設施，不會、也不應該自動知道「Codex Final Review 結果」「剩餘 Must Fix」這類特定 Sprint 當下的事實。`cmd_notify_gate` 只負責把已經準備好的摘要檔案**原文內嵌**進 Notification Package（Artifact First 原則的延伸：摘要本身也是一份 artifact，一樣不得被 Delivery Adapter 重新改寫）。

### 21.3 Contract Coverage 與 Live Delivery 必須清楚分開（呼應 Sprint-017 Must Fix Round 4 Blocker 2）

Product Owner 明確要求：**不得宣稱「21 Gate live delivery: PASS」**，除非 21 個 Gate 都真的被 Product Owner 逐一手動執行過 `notify-gate` 且 Telegram 確認收到。

- **Contract coverage（21/21 PASS 是合理宣稱）**：`scripts/test_review_bridge.sh` Test 28 對全部 21 個 gate_id 做自動化、可重複執行的驗證（正確 gate_id、正確指令、內嵌內容存在），這是程式碼正確性的證明，每次執行測試都會重新驗證一次。
- **Live delivery（只能宣稱實際測試過的那幾個）**：只有 `reviews/notification_history.jsonl` 裡有 `"delivery_status": "delivered"` 紀錄的 gate_id，才可以標記為「live delivery: PASS」；其餘一律標記為「NOT TESTED」，不得因為 contract coverage 是 PASS 就推論 live delivery 也是 PASS。
- 見 `reviews/sprint-017/round-001/gate_notification_coverage_report.md`，這是把上述兩種證據明確分開列出的具體範例。

## 22. Next AI Handoff Package — Product Owner 核准後應可直接複製轉交（Sprint-017 Must Fix Round 5）

Product Owner 收到內嵌繁體中文摘要與原始 artifact 證據的 Telegram 通知後回報：訊息告訴 Product Owner「確認後可進入 Git Review 階段」，卻沒有附上實際可以轉交給 Codex 的 Git Review Handoff Package，逼得 Product Owner 還是得回到 ChatGPT 才能取得下一步要用的內容。這違背「Product Owner 收到 Telegram 通知後應能直接複製轉交，不需要回到 ChatGPT」的可用性目標。

### 22.1 規則

1. `notify-gate` 新增第 6 個**選用**參數 `next_handoff_path`：

   ```bash
   ./scripts/review_bridge.sh notify-gate <gate_id> <sprint_id> <round_id> <artifact_path> [summary_path] [next_handoff_path]
   ```

2. 當 `next_handoff_path` 有提供時，該檔案內容會**逐字內嵌**在「📦 Handoff Package」區塊中，標題為「🤖 Next AI Handoff Package（可直接複製；實際目標 AI 執行者請見下方內容的 Target AI）」。
3. 當 `next_handoff_path` **未提供**時，行為與 Round 4 完全相同（不會出現這個區塊）——向下相容，不影響既有呼叫方式。
4. 若 `next_handoff_path` 有提供但檔案不存在，`notify-gate` 會直接失敗（`Next AI Handoff Package artifact not found: <path>`），不會靜默略過。
5. 標題刻意不寫死「轉交給 `${GATE_NEXT_ACTOR}`」：`GATE_NEXT_ACTOR`（canonical metadata 的 next_actor 欄位）對某些 Gate（例如 `product_owner_validation_approval`）本身就是 `Product Owner`，但這個 Gate 核准後幾步之後的**實際 AI 執行者**（例如 Codex Git Review）可能是不同的人。實際目標 AI 由內嵌內容自己用「Target AI」欄位聲明（沿用 Sprint-010 Handoff Package 的既有慣例），標題不做無法保證正確的假設。

### 22.2 Notification 四大區塊，必須清楚分開（呼應 Sprint-017 Must Fix Round 5 需求 4）

`cmd_notify_gate` 產生的「📦 Handoff Package」區塊，固定依以下順序呈現 4 個明確標示的子區塊：

1. **🇹🇼 Product Owner Summary**（第 21 節，選用，`summary_path` 提供時才出現）
2. **✅ Product Owner Decision Options**（固定出現：Sprint/Round/Gate 資訊、`next_actor`、Product Owner 下一步）
3. **🤖 Next AI Handoff Package**（本節，選用，`next_handoff_path` 提供時才出現）
4. **📄 Raw Artifact Evidence**（第 20 節，固定出現：`請閱讀：` 路徑參考 + 內嵌原始 artifact 內容）

這個順序讓 Product Owner 依序讀到：先看摘要理解狀況 → 再看清楚有哪些決策選項 → 若要轉交下一位 AI 有現成可複製的內容 → 最後才是原始佐證資料（可視需要往下捲動查看）。

### 22.3 Next AI Handoff Package 必須包含的內容

`next_handoff_path` 指向的檔案（由呼叫 `notify-gate` 的人另外準備，`cmd_notify_gate` 本身不自動產生，理由同第 21.2 節：跨 Sprint 通用的基礎設施不會自動知道特定任務的 review target、allowed files 等事實）內容至少必須包含：

1. 完整必讀清單（見 `docs/development/consensus-workflow.md` Handoff Package Standard 的 10 項清單）
2. 語言 / 輸出規則：要求次一位 AI 執行者的產出使用繁體中文
3. Context Completeness Check 要求（區塊格式）
4. Task Objective（任務目標）
5. Review Target（審查對象）
6. Allowed Files（允許範圍）
7. Prohibited Files（禁止範圍）
8. Repository Hygiene Checks（依 `docs/development/repository-hygiene-policy.md`）
9. Runtime Evidence Exclusion Checks（依 `docs/development/runtime-evidence-exclusion-policy.md`）
10. 明確的產出報告路徑（Exact Report Path）
11. 明確限制：不得 `git add`、不得 `commit`、不得 `push`、不得執行 `notify-gate`、不得觸發 Telegram、不得修改 n8n JSON

範例見 `reviews/sprint-017/round-001/codex_git_review_handoff_zh.md`（Sprint-017 目前 Gate 對應的真實 Codex Git Review Handoff Package）。

## 23. Telegram Content Mode / Copyability Improvement（Sprint-017 Must Fix Round 6）

Product Owner 實際在手機上使用 Round 5 的通知後回報：內容太長、被 Telegram 切成很多則訊息，導致真正要複製轉交的「🤖 Next AI Handoff Package」變得不好操作——因為 Raw Artifact Evidence（第 20 節）預設一律內嵌完整原文，把 Handoff Package 淹沒在很長的原始證據裡。

### 23.1 三種 Content Mode

`notify-gate` 透過環境變數 `TELEGRAM_CONTENT_MODE` 控制內容策略，共 3 種模式：

| Mode | Product Owner Summary | Product Owner Decision Options | Next AI Handoff Package | Evidence Reference | Full Raw Artifact Evidence |
|---|---|---|---|---|---|
| `summary` | ✅ | ✅ | ❌ | ✅ | ❌ |
| `handoff`（**預設**） | ✅ | ✅ | ✅ | ✅ | ❌ |
| `full` | ✅ | ✅ | ✅ | ✅ | ✅ |

- **`summary`**：只需要讓 Product Owner 理解狀況、看到決策選項的場合使用（例如還沒準備好交接內容時）。
- **`handoff`（預設，不設定 `TELEGRAM_CONTENT_MODE` 時就是這個模式）**：日常使用的預設模式，包含摘要、決策選項與可複製的下一步 Handoff Package，但**不**內嵌完整原始 artifact 內容——這是 Round 6 對 Round 3-5「預設一律內嵌完整原文」設計的修正。
- **`full`**：需要完整原始佐證時才手動指定，內嵌完整 Raw Artifact Evidence（沿用第 20 節既有的 BEGIN/END 標記與切分規則，未改變）。

不合法的 `TELEGRAM_CONTENT_MODE` 值會直接讓 `notify-gate` 失敗（`Invalid TELEGRAM_CONTENT_MODE`），不會靜默 fallback 成任何模式。

### 23.2 啟用 full mode 的方式

```bash
TELEGRAM_CONTENT_MODE=full PROJECT_ID="ai-workspace" PROJECT_NAME="AI Workspace" \
  ./scripts/review_bridge.sh notify-gate <gate_id> <sprint_id> <round_id> <artifact_path> [summary_path] [next_handoff_path]
```

若 Product Owner 需要完整 evidence（例如要仔細檢查 Codex 的完整原文），可以自行加上 `TELEGRAM_CONTENT_MODE=full` 手動啟用，這是 opt-in，不是預設行為。

### 23.3 Evidence Reference（第 4 個必要區塊，任何 mode 都會出現）

即使不內嵌完整原文，Telegram 內容仍必須清楚列出 evidence 的實際路徑：

```text
📎 Evidence Reference
- Source Artifact: <artifact_path>
- Product Owner Summary: <summary_path>（若有提供）
- Next AI Handoff Package: <next_handoff_path>（若有提供）
- Notification History: reviews/notification_history.jsonl
```

這些路徑只涵蓋 `notify-gate` 本身已知的通用參數，不會臆測特定 Sprint 才有的額外檔案（例如某個 Sprint 自己準備的 coverage report）——如果呼叫方想讓 Product Owner 看到更多 evidence 路徑，應該把它們寫進 `summary_path` 或 `next_handoff_path` 指向的檔案內容裡，而不是期待 `cmd_notify_gate` 自動生出來。

### 23.4 Notification 區塊固定順序（Copyability Priority）

不論哪個 mode，出現的區塊一律遵循固定順序：

```text
1. Header / Gate metadata（🔔/⚠️ 標題、📌 Sprint、🧭 目前 Gate、📍 目前狀態、👤 通知對象、➡️ 下一位執行者、⚙️ 建議執行模式）
2. 🇹🇼 Product Owner Summary
3. ✅ Product Owner Decision Options
4. 🤖 Next AI Handoff Package（handoff / full mode 才出現）
5. 📎 Evidence Reference
6. 📄 Raw Artifact Evidence（只有 full mode 才出現，且明確標示「完整原文，內容可能很長」）
7. 🧾 Delivery Metadata
```

**Next AI Handoff Package 永遠保持完整、連續**：Raw Artifact Evidence 只會出現在它之後（Evidence Reference 之後），不會插在 Next AI Handoff Package 的中間或前面，確保 Product Owner 要複製 Handoff Package 時，往下捲動不會先卡到一大段原始證據。

### 23.5 Contract Coverage 仍不等於 Live Delivery（沿用第 21.3 節原則，未改變）

Content Mode 的改動不影響第 21.3 節已經確立的原則：**contract validation PASS（例如 21 個 Gate 都能正確產生 handoff/summary/full 三種模式的內容）不等於 21 個 Gate 都已經 live delivery PASS**。只有 `reviews/notification_history.jsonl` 裡有 `"delivery_status": "delivered"` 紀錄的 gate_id 才算 live delivery PASS，其餘一律 NOT TESTED，Content Mode 的選擇不會改變這個判斷標準。

## 24. AI Handoff Standalone Message / Copy Boundary UX Improvement（Sprint-017 Must Fix Round 7）

Round 6 改成預設不內嵌完整原文後，Product Owner 實際在手機上使用時仍回報：Telegram 推播若整份內容一起用字元數切分送出，「🤖 Next AI Handoff Package」後面仍可能接著出現「📎 Evidence Reference」或其他非 AI 指令內容，逼得 Product Owner 得自己判斷哪一段才是要複製給下一個 AI 的指令。

### 24.1 Section-aware Message Split

`notify-gate` 送到 Telegram 的內容，不再是把整份 Notification Package 用字元數切分成連續訊息，而是依「邏輯區塊」拆成獨立訊息，依序送出：

```text
Message 1：Header / Gate metadata + 🇹🇼 Product Owner Summary + ✅ Product Owner Decision Options
Message 2（handoff / full mode，且有提供 next_handoff_path 才出現）：只有 🤖 Next AI Handoff Package 的 copy block
Message 3：📎 Evidence Reference + 🧾 Delivery Metadata
Message 4+（只有 full mode 才出現）：📄 Raw Artifact Evidence（若很長，才依既有字元數切分機制繼續切成多則）
```

每一則訊息的內容仍然是同一份 Notification Package 資料裡的原文片段（Artifact First 原則不變：沒有重新組字、沒有摘要），只是改成依邏輯區塊分組傳送，而不是按字元數盲切。寫入 `reviews/<sprint>/round-<round>/notifications/gate-<gate_id>.md` 的完整檔案內容不受影響，仍是 Round 6 的完整單一檔案格式；改變的只是「送到 Telegram 的方式」。

### 24.2 Next AI Handoff Message 不得含雜訊

**Evidence Reference 不屬於 AI 指令。Delivery Metadata 不屬於 AI 指令。Raw Artifact Evidence 不屬於 AI 指令。Product Owner Summary 不屬於 AI 指令。** 這些內容一律不會出現在 Message 2（Next AI Handoff message）裡，Message 2 只包含：

1. Copy boundary marker（見 24.3 節）
2. `next_handoff_path` 檔案的原文內容

### 24.3 Copy Boundary Marker 格式

```text
===== BEGIN COPY TO <TARGET_AI> =====
<next_handoff_path 原文內容>
===== END COPY TO <TARGET_AI> =====
```

`<TARGET_AI>`（例如 `CODEX`）取自 `next_handoff_path` 檔案自己宣告的「Target AI」（Sprint-010 既有慣例，例如 `## 1. Target AI\n\nCodex`），全部轉大寫。若 `next_handoff_path` 沒有可解析出的 Target AI 宣告，`notify-gate` 會直接失敗（`does not declare a 'Target AI'`），不會用 `GATE_NEXT_ACTOR` 或任何猜測值頂替——原因與 Round 5 一致：Gate 的 canonical `next_actor` 有時就是 `Product Owner` 自己，跟這份 Handoff Package 實際要轉交的 AI 執行者不必然相同。

### 24.4 若 Handoff Package 太長：Fail Loudly，不默默切成兩則

Product Owner 明確要求「完整的一條」。因此若 `next_handoff_path` 內容加上 copy boundary marker 後，超過安全的單則訊息字元數上限（3500 字元，與既有 `_notify_split_for_telegram` 的切分粒度一致，安全低於 Telegram 實際約 4096 字元的訊息長度限制），`notify-gate` 會直接失敗：

```text
ERROR: Next AI Handoff Package '<path>' is too long to send as a single, uninterrupted Telegram message (... chars ...). Shorten the handoff content ...
```

不會默默把它切成 PART 1 / PART 2 兩則訊息後還宣稱「可整則複製」。因此撰寫 `next_handoff_path` 內容時，應該保持精簡、可在單一訊息內完整呈現（範例見 `reviews/sprint-017/round-001/codex_git_review_handoff_zh.md`，已刻意精簡到安全長度內）。

### 24.5 與既有原則的關係

- 與第 20 節「Full Raw Artifact Evidence 內嵌」原則不衝突：Raw Artifact Evidence 只在 full mode 才出現，且固定排在 Next AI Handoff message（Message 2）之後，絕不會插入其中。
- 與第 21/22/23 節原則不衝突：Product Owner Summary、Next AI Handoff Package、Content Mode 的內容規則本身未變，Round 7 只改變「這些內容如何被分組送到 Telegram」。
- 與第 21.3/23.5 節「Contract Coverage 不等於 Live Delivery」原則不衝突：Section-aware split 是否正確運作，屬於 contract validation 的一部分（`scripts/test_review_bridge.sh` Test 32），不代表 21 個 Gate 都已經完成 live delivery。
