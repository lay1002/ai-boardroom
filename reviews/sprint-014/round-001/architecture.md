# Sprint-014 Architecture — Telegram PO Gate Notification & Execution Policy V1

## 0. Provenance Note

**此 Architecture 內容來源為 Product Owner 已核准的 Sprint-014 Architecture Artifact**，由 Product Owner 直接於 Claude Code Implementation 指令中提供。

**這不是 Claude Code 自行設計的 Architecture。** Claude Code 只是把 Product Owner 已核准的決策內容，正式轉錄、存檔到本專案的 canonical 路徑（`reviews/sprint-014/round-001/architecture.md`），以符合 `docs/development/consensus-workflow.md` 的 Required Artifact Structure。

**Claude Code 不得修改本文件記錄的 Architecture 決策。** 若實作過程中發現本文件未涵蓋、或需要補充判斷（例如 21 個 Gate 各自的中文名稱、next_actor、風險等級等未逐一列出的細節），Claude Code 只能在授權範圍內做「合理且可追溯」的實作填補，並在 `claude_report.md` 中明確揭露這些屬於「實作填補」而非「Architecture 決策」，供 Product Owner 之後審閱、確認或調整。

**Claude Code 只負責依此 Architecture 進行 Implementation**，不得自行擴大 scope、不得自行新增或移除 Architecture 已定義的範圍。

---

## 1. Sprint Information

Sprint ID: `sprint-014`

Sprint Name: `Telegram PO Gate Notification & Execution Policy V1`

中文定位: `Telegram Product Owner Gate 通知完整接入與 Claude / Codex 執行權限策略`

Sprint Type: Implementation

Architecture Status: APPROVED（Product Owner，直接於 Implementation 指令中提供）

---

## 2. Objective

1. 將 21 個 Product Owner Gate 全部接入 Telegram Notification Runtime。
2. 每個 Gate 都要產生 Product Owner 可直接複製的 Handoff Package。
3. 每個 Gate 都要明確標示 next_actor。
4. 每個 Gate 都要明確標示 Recommended Execution Mode。
5. 建立 Claude / Codex Execution Permission Policy。
6. Telegram 推播內容必須繁體中文化。
7. Telegram 推播內容必須適合手機閱讀與複製操作。
8. Commit / Push 類 Gate 必須維持高風險格式與嚴格 Product Owner 人工核准。

---

## 3. In Scope

1. 建立 21 個 Product Owner Gate whitelist（見第 5 節）。
2. 每個 Gate 具備 metadata：gate_id、gate_name_zh、sprint_id、round_id、notification_recipient、next_actor、recommended_execution_mode、risk_level、current_status_zh、product_owner_next_action_zh、handoff_package、delivery_metadata。
3. `notification_recipient` 固定為 `Product Owner`。
4. `next_actor` 只能是 `Product Owner` / `ChatGPT` / `Claude Code` / `Codex`。
5. `risk_level` 只能是 `low` / `medium` / `high`。
6. 每個 Gate 都能產生 Notification Package。
7. 每個 Gate 都能產生繁體中文 Telegram message。
8. 一般 Gate 使用一般格式；Commit / Push 類 Gate 使用高風險格式。
9. Handoff Package 獨立成可複製區塊；Delivery Metadata 位於訊息最後。
10. 建立 `docs/development/execution-permission-policy.md`、`docs/development/telegram-po-gate-notification-specification.md`。
11. 更新必要測試，且 Sprint-013 既有 `notify` 測試不得 regression。

## 4. Out of Scope

Telegram button 自動執行、n8n Execute Command、自動呼叫 Claude / Codex、自動 commit、自動 push、完全 bypass sandbox、AI Auto Loop、Telegram 按鈕直接觸發本機終端機、自動核准 Product Owner Gate、多使用者權限管理、Web UI、Notification Center。不得擴大 scope、不得修改 unrelated Sprint files、不得處理 unrelated dirty / untracked files。

---

## 5. 21 個 Product Owner Gate Whitelist

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

高風險 Gate（Commit / Push 類，必須使用高風險格式）：`commit_approval`、`codex_commit_approval`、`push_approval`、`codex_push_approval`。

---

## 6. Telegram Message Layout

### 一般 Gate 格式

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
notification_recipient: Product Owner
next_actor: {next_actor}
delivery_channel: telegram
```

### 高風險 Gate 格式

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
notification_recipient: Product Owner
next_actor: {next_actor}
risk_level: high
delivery_channel: telegram
```

實作備註（非 Architecture 決策，屬實作填補）：為滿足第 8 節 Notification Package Contract 要求「至少包含」的完整欄位清單（含 project_id、project_name、created_at、delivery_status、risk_level 等未出現在上述範例本文中的欄位），Claude Code 會把這些欄位補進「🧾 Delivery Metadata」區塊（該區塊本來就定義為「位於訊息最後」），不改變範例的整體版面與可讀性，也不新增其他區塊。

---

## 7. Telegram 美編規則

必須使用繁體中文；必須有清楚標題；必須分段；不得整段文字堆在一起；必須清楚標示目前 Gate / 目前狀態 / Product Owner 下一步 / next_actor / Recommended Execution Mode；Handoff Package 必須獨立成區塊；Delivery Metadata 必須放最後；可使用少量 emoji 協助辨識區塊；不得過度花俏；不得破壞 Handoff Package 可複製性；高風險 Gate 必須使用警示格式。

---

## 8. Notification Package Contract

每個 Gate 的 Notification Package 至少必須包含：

```text
project_id, project_name, sprint_id, round_id, gate_id, gate_name_zh, event_type,
notification_recipient, next_actor, recommended_execution_mode, risk_level,
current_status_zh, product_owner_next_action_zh, handoff_package, delivery_channel,
delivery_status, created_at, delivery_metadata
```

Artifact-first 原則：

1. Notification Package 是 Gate notification 的 SSOT。
2. Telegram message 必須由 Notification Package 產生。
3. Delivery Adapter 不得重新組語意。
4. 若有格式化，格式化規則必須可追溯到 Notification Package 內容。
5. Delivery Adapter 只負責 transport，不負責決策。

實作備註（非 Architecture 決策，屬實作填補）：本 Sprint 的 Notification Package **本身就是**渲染好的繁體中文 Telegram 版面（第 6 節模板套入實際值後的結果），而不是另外維護一份「18 欄位資料結構」再由 Delivery Adapter 重新組字串——這樣可以直接沿用 Sprint-013 Must Fix 1 已驗證過的「Telegram 逐位元組傳送 artifact 原文」機制，避免重新引入「另外組訊息」的風險。

---

## 9. Execution Permission Policy（`docs/development/execution-permission-policy.md`）

至少涵蓋 7 個 mode：`Claude Implementation Mode`、`Claude Must Fix Mode`、`Codex Review Mode`、`Codex Final Review Mode`、`Codex Git Review Mode`、`Codex Commit Mode`、`Codex Push Mode`。每個 mode 須定義：適用情境、允許動作、禁止動作、是否可低中斷執行、是否需要 Product Owner 明確核准、風險等級、sandbox / permission 原則。

核心規則：可低中斷不等於完全 bypass sandbox；Review 類任務可低中斷；Claude Implementation / Must Fix 可在核准 scope 內低中斷；Commit / Push 不得低中斷；Commit / Push 必須 Product Owner 明確核准；不得 `git add .`；不得自動 commit；不得自動 push；不得自動呼叫 Claude / Codex；不得自動進入下一個 Gate。

---

## 10. Telegram PO Gate Notification Specification（`docs/development/telegram-po-gate-notification-specification.md`）

至少包含：Sprint-014 目的、21 個 Gate 清單、Gate Metadata Contract、Notification Package Contract、Telegram message layout（一般/高風險格式）、next_actor 規則、recommended_execution_mode 規則、risk_level 規則、Handoff Package 規則、Delivery Metadata 規則、禁止事項、Artifact-first 原則、Product Owner Manual Gate 原則。

---

## 11. 預期可修改檔案

```text
scripts/review_bridge.sh
scripts/test_review_bridge.sh
docs/development/telegram-po-gate-notification-specification.md
docs/development/execution-permission-policy.md
reviews/sprint-014/round-001/architecture.md
```

若因實作需要修改其他檔案，須在 `claude_report.md` 中明確說明原因，不得靜默修改。

---

## 12. 不得混入的 unrelated dirty / untracked files

`AGENTS.md`、`CLAUDE.md`、`CODEX.md`、`GPT.md`、`docs/architecture.md`、`docs/vision.md`、`docs/development/n8n-*.md`、`reviews/sprint-004/`、`docs/principles.md`、`docs/roadmap.md`、`reviews/notification-gap-review.md`、`reviews/notification_history.jsonl`、`reviews/sprint-006/`、`reviews/sprint-007/`、`reviews/sprint-009/`、`reviews/sprint-013/round-001/notifications/`。這些檔案不得被修改、stage、整理、清理或納入本 Sprint。

---

## 13. Definition of Done（Testing Requirements 摘要）

21 個 Gate 皆在 whitelist、皆有完整 metadata、皆能產生 Notification Package 與中文 Telegram message；一般/高風險格式正確套用；Handoff Package 可複製、Delivery Metadata 在最後；Execution Permission Policy 與 Telegram PO Gate Specification 文件存在；不存在 Telegram button 自動執行、n8n Execute Command、自動呼叫 Claude/Codex、自動 commit/push、bypass sandbox 之邏輯；Sprint-013 既有 `notify` 測試零迴歸。

---

## 14. Architecture Review Result

Not yet reviewed by Codex. 本文件為 Claude Code 依 Product Owner 決策轉錄之 Architecture Artifact，尚待 Codex 於 Implementation Review 階段一併確認。
