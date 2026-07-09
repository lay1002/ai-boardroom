# Sprint-018 Gate Notification Matrix

Version: 1.2 (Sprint-018; Must Fix Round 1 補齊 14 欄位完整性；Must Fix Round 2 新增第 14 個 Gate 與 Claude Report Push to PO 欄位)

## 0. Round 2 變更說明

Sprint-018 Round 1 原本挑選 13 個操作性 Gate（見 `reviews/sprint-018/round-001/architecture.md` 第 3 節），並將 `claude_must_fix_report_acceptance` 列入排除清單。Must Fix Round 2 依 Product Owner 明確指示，把 `claude_must_fix_report_acceptance` 加回矩陣，作為第 14 個 Gate——理由：`claude_must_fix_approval`（原矩陣第 6 個 Gate）語意是「Must Fix **開始前**的執行授權」，不適合承接「Claude Fix Report **完成後**、等待 Product Owner 審核並決定是否送 Codex Final Review」這個語意；真正對應的 canonical Gate 是 `claude_must_fix_report_acceptance`，跟 Gate 4 `claude_implementation_report_acceptance`（Implementation Report 完成後的驗收 Gate）是同一種角色的對稱 Gate。這不是任意擴大 scope，是 Product Owner 對 Sprint-018 流程語意的直接修正指示，完整理由記錄於 `reviews/sprint-018/round-001/claude_fix_report_round_2.md`。`architecture.md` 本身（Round 1 的核准決策紀錄）不因此修改，保留原始決策軌跡；本文件是目前生效的最新版本。

## 1. Purpose

本文件把 Sprint-013–017 已完成的 Telegram / Handoff 能力，套用到 14 個經挑選的操作性 Product Owner Gate 上（Round 1 選出 13 個，Round 2 新增 1 個，見上方第 0 節），讓每個 Gate 都能定義出「Product Owner 收到通知後具體該怎麼操作」的完整契約。其餘 7 個 canonical Gate 仍存在於 `docs/development/product-owner-gate-metadata.md`，只是未列入本矩陣。

`notify-gate` 本身是通用、跨 Sprint 的基礎設施（不因本矩陣而修改），本文件記錄的是「呼叫 `notify-gate` 時，這 14 個 Gate 各自應該怎麼組出 `summary_path` / `next_handoff_path` / `TELEGRAM_CONTENT_MODE`」的操作準則。

## 2. 欄位定義

每個 Gate 記錄 14 個欄位，**全部 14 個欄位在每個 Gate 都必須明確填寫，不得省略、留白或以「同上」代替**：Gate ID、Gate name（繁體中文）、Notification purpose（這則通知存在的目的）、Product Owner action required（PO 必須做什麼）、Decision options（PO 可選擇的具體選項）、Recommended next step（做出決策後接下來會發生什麼）、Required Reading（PO 決策前應參考的文件，非給下一位 AI 的閱讀清單）、Evidence reference（佐證此決策的 artifact 路徑）、是否需要 Next AI Handoff Package、Target AI、copy boundary、notify-gate command requirement（呼叫慣例）、stop condition（不應繼續派送/執行的情況）、Telegram content mode（建議預設模式）。

**Target AI 與 copy boundary 的填寫規則（Sprint-018 Must Fix Round 1 新增）**：若「是否需要 Next AI Handoff Package」為「否」，`Target AI` 與 `copy boundary` 兩欄仍必須明確填寫為 `N/A（不適用）`，不得直接省略該欄位或留白——這是 Round 1 Must Fix 修正的重點，確保矩陣的欄位完整性可以被逐一驗證，而不是靠「沒寫就代表不需要」這種隱含推論。

**Claude Report Push to PO 欄位（Sprint-018 Must Fix Round 2 新增，僅適用於「Claude Completion Gate」）**：`claude_implementation_report_acceptance`（Gate 4）與 `claude_must_fix_report_acceptance`（Gate 14，新增）這類「Claude 剛完成一份報告、等待 Product Owner 審核」的 Gate，除了上述 14 個通用欄位外，另外必須明確填寫以下 6 個欄位：

```text
Claude report push to PO
Report artifact
PO review required
PO manually sends to Codex
Auto send to Codex
Codex review checklist authority
```

這 6 個欄位的目的是明確區分「Claude Report Push to PO」（純通知）與「Formal Codex Review Approval」「Auto Handoff to Codex」「Auto Gate Approval」（皆不等於前者）——完整規則見 `docs/development/product-owner-gate-operation-ux.md` 第 6 節與 `docs/development/telegram-po-gate-notification-specification.md` 的「Claude Report Push to Product Owner」一節。若未來新增更多 Claude Completion Gate（例如 Codex Final Review 之後又產生新一輪 Claude 報告的情境），也應套用同一規則，補上這 6 個欄位。

## 3. Gate Notification Matrix

### 3.1 `sprint_start_approval`

- **Gate ID**：`sprint_start_approval`

- **Gate name**：Sprint 啟動核准
- **Notification purpose**：讓 Product Owner 知道有新的 Sprint 需求待啟動決策。
- **Product Owner action required**：審閱需求脈絡，決定是否啟動本 Sprint。
- **Decision options**：核准啟動 / 退回補充資訊 / 暫緩。
- **Recommended next step**：核准後由 ChatGPT 開始 Architecture 設計。
- **Required Reading**：`PROJECT_BOOTSTRAP.md`、`docs/development/consensus-workflow.md`。
- **Evidence reference**：本次 Sprint 需求描述（通常在對話中，尚無正式 artifact）。
- **是否需要 Next AI Handoff Package**：是。
- **Target AI**：ChatGPT。
- **copy boundary**：`===== BEGIN COPY TO CHATGPT =====` / `===== END COPY TO CHATGPT =====`。
- **notify-gate command requirement**：`artifact_path` 指向需求描述檔案（若有）；建議附上 `summary_path` 與 `next_handoff_path`（給 ChatGPT 的 Architecture 設計指示）。
- **stop condition**：需求描述不完整、Product Owner 尚未確認範圍。
- **Telegram content mode**：`handoff`（預設）。

### 3.2 `architecture_definition_approval`

- **Gate ID**：`architecture_definition_approval`

- **Gate name**：Architecture 定義核准
- **Notification purpose**：讓 Product Owner 審閱 ChatGPT 提出的 Architecture 定義。
- **Product Owner action required**：審閱 Architecture 定義是否符合預期。
- **Decision options**：核准 / 要求修改 / 退回重新設計。
- **Recommended next step**：核准後交給 Claude Code 開始實作。
- **Required Reading**：`docs/development/consensus-workflow.md`、本次 Architecture 定義內容。
- **Evidence reference**：ChatGPT 提供的 Architecture 定義（對話或文件）。
- **是否需要 Next AI Handoff Package**：是。
- **Target AI**：Claude Code。
- **copy boundary**：`===== BEGIN COPY TO CLAUDE =====` / `===== END COPY TO CLAUDE =====`。
- **notify-gate command requirement**：`next_handoff_path` 應為 Claude Code Implementation Handoff Package。
- **stop condition**：Architecture 定義尚未完整、與既有 Development Principles 衝突未解決。
- **Telegram content mode**：`handoff`（預設）。

### 3.3 `claude_implementation_approval`

- **Gate ID**：`claude_implementation_approval`

- **Gate name**：Claude Implementation 執行核准
- **Notification purpose**：讓 Product Owner 授權 Claude Code 依已核准 Architecture 開始實作。
- **Product Owner action required**：確認 Architecture 已核准，授權開始實作。
- **Decision options**：授權開始 / 暫緩 / 要求先釐清範圍。
- **Recommended next step**：授權後 Claude Code 進入 Claude Implementation Mode。
- **Required Reading**：`reviews/<sprint>/round-<round>/architecture.md`。
- **Evidence reference**：`reviews/<sprint>/round-<round>/architecture.md`。
- **是否需要 Next AI Handoff Package**：是（即本次執行的 Handoff Package 本身）。
- **Target AI**：Claude Code。
- **copy boundary**：`===== BEGIN COPY TO CLAUDE =====` / `===== END COPY TO CLAUDE =====`。
- **notify-gate command requirement**：`artifact_path` 指向 `architecture.md`；`next_handoff_path` 為完整 Implementation Handoff Package。
- **stop condition**：Architecture 尚未核准、範圍不明確。
- **Telegram content mode**：`handoff`（預設）。

### 3.4 `claude_implementation_report_acceptance`（Claude Completion Gate）

- **Gate ID**：`claude_implementation_report_acceptance`

- **Gate name**：Claude Implementation Report 驗收
- **Notification purpose**：讓 Product Owner 驗收 Claude Code 的實作報告。
- **Product Owner action required**：審閱 `claude_report.md`，確認實作內容與範圍相符。
- **Decision options**：驗收通過 / 要求補充說明 / 退回重做。
- **Recommended next step**：驗收後交給 Codex 進行 Review。
- **Required Reading**：`reviews/<sprint>/round-<round>/claude_report.md`。
- **Evidence reference**：`reviews/<sprint>/round-<round>/claude_report.md`。
- **是否需要 Next AI Handoff Package**：是。
- **Target AI**：Codex。
- **copy boundary**：`===== BEGIN COPY TO CODEX =====` / `===== END COPY TO CODEX =====`。
- **notify-gate command requirement**：`artifact_path` 為 `claude_report.md`；`next_handoff_path` 為 Codex Review Handoff（須符合 `codex_review_handoff_policy.md`）。
- **stop condition**：`claude_report.md` 尚未產出或仍是 placeholder。
- **Telegram content mode**：`handoff`（預設）。
- **Claude report push to PO**：YES。
- **Report artifact**：`reviews/<sprint>/round-<round>/claude_report.md`（本 Sprint 對應 `reviews/sprint-018/round-001/claude_report.md`）。
- **PO review required**：YES。
- **PO manually sends to Codex**：YES。
- **Auto send to Codex**：NO。
- **Codex review checklist authority**：canonical template / `codex_review_handoff_policy.md`（不得由 Claude Report 自行定義）。

### 3.5 `codex_review_result_decision`

- **Gate ID**：`codex_review_result_decision`

- **Gate name**：Codex Review 結果決策
- **Notification purpose**：讓 Product Owner 依 Codex Review 結論決定下一步。
- **Product Owner action required**：審閱 `codex_review.md` 結論。
- **Decision options**：無 Must Fix，進入下一階段 / 有 Must Fix，授權 Claude Code 修正 / 要求 Codex 補充說明。
- **Recommended next step**：視決策結果，交給 Claude Code（Must Fix）或直接進入 Final Review 前置階段。
- **Required Reading**：`reviews/<sprint>/round-<round>/codex_review.md`。
- **Evidence reference**：`reviews/<sprint>/round-<round>/codex_review.md`。
- **是否需要 Next AI Handoff Package**：視 Codex Review 結果而定——有 Must Fix 才需要（Target AI=Claude Code）；無 Must Fix 則不需要。
- **Target AI**：Claude Code（僅 Must Fix 情境）。
- **copy boundary**：`===== BEGIN COPY TO CLAUDE =====` / `===== END COPY TO CLAUDE =====`（僅 Must Fix 情境）。
- **notify-gate command requirement**：`artifact_path` 為 `codex_review.md`；只有判定需要 Must Fix 時才附上 `next_handoff_path`。
- **stop condition**：`codex_review.md` 尚未產出或 Final Recommendation 欄位空白。
- **Telegram content mode**：`handoff`（有 Must Fix 時）／`summary`（無 Must Fix 時，PO 自行決定是否繼續）。

### 3.6 `claude_must_fix_approval`

- **Gate ID**：`claude_must_fix_approval`

- **Gate name**：Claude Must Fix 執行核准
- **Notification purpose**：讓 Product Owner 授權 Claude Code 依 Must Fix 清單修正。
- **Product Owner action required**：確認 Must Fix 範圍，授權修正。
- **Decision options**：授權修正 / 要求先釐清 Must Fix 範圍 / 退回 Codex 重新 Review。
- **Recommended next step**：授權後 Claude Code 進入 Claude Must Fix Mode。
- **Required Reading**：`reviews/<sprint>/round-<round>/codex_review.md`。
- **Evidence reference**：`reviews/<sprint>/round-<round>/codex_review.md`。
- **是否需要 Next AI Handoff Package**：是。
- **Target AI**：Claude Code。
- **copy boundary**：`===== BEGIN COPY TO CLAUDE =====` / `===== END COPY TO CLAUDE =====`。
- **notify-gate command requirement**：`next_handoff_path` 為 Must Fix Handoff Package，僅涵蓋 Codex 指出的項目。
- **stop condition**：Must Fix 清單不明確。
- **Telegram content mode**：`handoff`（預設）。

### 3.7 `claude_must_fix_report_acceptance`（Claude Completion Gate，Sprint-018 Must Fix Round 2 新增）

- **Gate ID**：`claude_must_fix_report_acceptance`

- **Gate name**：Claude Fix Report 驗收
- **Notification purpose**：讓 Product Owner 知道 Claude Fix Report 已完成，並驗收其內容。
- **Product Owner action required**：審閱 `claude_fix_report.md`（或對應輪次的 fix report，例如 `claude_fix_report_round_2.md`），確認修正內容與 Must Fix 範圍相符。
- **Decision options**：驗收通過，送交 Codex Final Review / 要求補充說明 / 退回重做。
- **Recommended next step**：驗收後由 Product Owner 手動把報告內容與 Codex Review 要求貼給 Codex 進行 Final Review。
- **Required Reading**：`reviews/<sprint>/round-<round>/claude_fix_report*.md`、對應的 `codex_review.md`（列出本輪要修正的 Must Fix 項目）。
- **Evidence reference**：`reviews/<sprint>/round-<round>/claude_fix_report*.md`。
- **是否需要 Next AI Handoff Package**：是。
- **Target AI**：Codex。
- **copy boundary**：`===== BEGIN COPY TO CODEX =====` / `===== END COPY TO CODEX =====`。
- **notify-gate command requirement**：`artifact_path` 為對應的 fix report；`next_handoff_path` 為 Codex Final Review Handoff（須符合 `codex_review_handoff_policy.md`）。
- **stop condition**：fix report 尚未產出或仍是 placeholder；Must Fix 項目未逐一對應說明處理結果。
- **Telegram content mode**：`handoff`（預設）。
- **Claude report push to PO**：YES。
- **Report artifact**：`reviews/<sprint>/round-<round>/claude_fix_report.md`（或 round-specific fix report，本 Sprint 對應 `reviews/sprint-018/round-001/claude_fix_report.md` / `claude_fix_report_round_2.md`）。
- **PO review required**：YES。
- **PO manually sends to Codex**：YES。
- **Auto send to Codex**：NO。
- **Codex review checklist authority**：canonical template / `codex_review_handoff_policy.md`（不得由 Claude Report 自行定義）。

### 3.8 `codex_final_review_result_decision`

- **Gate ID**：`codex_final_review_result_decision`

- **Gate name**：Codex Final Review 結果決策
- **Notification purpose**：讓 Product Owner 依 Final Review 結論決定是否進入 Validation。
- **Product Owner action required**：審閱 `codex_final_review.md` 結論。
- **Decision options**：PASS，進入 Product Owner Validation / 仍有問題，回到 Must Fix / 要求 Codex 補充說明。
- **Recommended next step**：PASS 則 Product Owner 自行進行 Validation（無需 AI Handoff）；未 PASS 則回到 `claude_must_fix_approval`。
- **Required Reading**：`reviews/<sprint>/round-<round>/codex_final_review.md`。
- **Evidence reference**：`reviews/<sprint>/round-<round>/codex_final_review.md`。
- **是否需要 Next AI Handoff Package**：預設否（PASS 時 PO 自行驗證）；若判定需要再一輪 Must Fix，則視同 `claude_must_fix_approval` 附上 Handoff。
- **Target AI**：（視情況）Claude Code。
- **copy boundary**：`===== BEGIN COPY TO CLAUDE =====` / `===== END COPY TO CLAUDE =====`（僅需要再修正時）。
- **notify-gate command requirement**：`artifact_path` 為 `codex_final_review.md`；預設不附 `next_handoff_path`。
- **stop condition**：`codex_final_review.md` 尚未產出。
- **Telegram content mode**：`summary`（預設）；需要再修正時手動改用 `handoff`。

### 3.9 `product_owner_validation_approval`

- **Gate ID**：`product_owner_validation_approval`

- **Gate name**：Product Owner Validation 核准
- **Notification purpose**：讓 Product Owner 實際驗證本輪成果。
- **Product Owner action required**：實際操作/驗證功能是否運作。
- **Decision options**：驗證通過，進入 Git Review / 驗證失敗，回報問題。
- **Recommended next step**：通過後交給 Codex 進行 Git Review（本 Sprint-017 已示範，見 `reviews/sprint-017/round-001/codex_git_review_handoff_zh.md`）。
- **Required Reading**：`reviews/<sprint>/round-<round>/codex_final_review.md`。
- **Evidence reference**：`reviews/<sprint>/round-<round>/codex_final_review.md`。
- **是否需要 Next AI Handoff Package**：是。
- **Target AI**：Codex。
- **copy boundary**：`===== BEGIN COPY TO CODEX =====` / `===== END COPY TO CODEX =====`。
- **notify-gate command requirement**：`next_handoff_path` 為 Codex Git Review Handoff（須符合 `codex_review_handoff_policy.md`）。
- **stop condition**：Final Review 尚未 PASS。
- **Telegram content mode**：`handoff`（預設）。

### 3.10 `codex_git_review_result_decision`

- **Gate ID**：`codex_git_review_result_decision`

- **Gate name**：Codex Git Review 結果決策
- **Notification purpose**：讓 Product Owner 依 Git Review 結果決定是否進入 Commit。
- **Product Owner action required**：審閱 Git Review 結果，確認 commit scope 乾淨。
- **Decision options**：核准進入 Commit / 要求調整 scope / 退回修正。
- **Recommended next step**：核准後進入 `commit_approval`。
- **Required Reading**：`reviews/<sprint>/round-<round>/codex_git_review.md`。
- **Evidence reference**：`reviews/<sprint>/round-<round>/codex_git_review.md`。
- **是否需要 Next AI Handoff Package**：預設否（Commit 由 Product Owner 親自核准/執行，見 `commit_approval`）；若 Product Owner 選擇透過 Codex Commit Mode 準備 commit 內容，才需要。
- **Target AI**：N/A（不適用）；若 Product Owner 選擇透過 Codex Commit Mode 準備 commit 內容，則為 `Codex`。
- **copy boundary**：N/A（不適用）；若上述情況成立，則為 `===== BEGIN COPY TO CODEX =====` / `===== END COPY TO CODEX =====`。
- **notify-gate command requirement**：`artifact_path` 為 `codex_git_review.md`；預設不附 `next_handoff_path`。
- **stop condition**：Git Review 尚未產出或發現 scope 汙染。
- **Telegram content mode**：`summary`（預設）。

### 3.11 `commit_approval`（高風險）

- **Gate ID**：`commit_approval`

- **Gate name**：Commit 核准
- **Notification purpose**：讓 Product Owner 明確核准是否執行 Commit。
- **Product Owner action required**：確認 commit scope、排除檔案、commit message。
- **Decision options**：核准 Commit / 要求調整範圍或訊息 / 拒絕。
- **Recommended next step**：核准後由 Product Owner 親自執行 `git add`/`git commit`（或明確授權 Codex Commit Mode 準備草案）。
- **Required Reading**：`docs/development/git-review-checklist.md`、`docs/development/execution-permission-policy.md` 2.6。
- **Evidence reference**：`reviews/<sprint>/round-<round>/codex_git_review.md`。
- **是否需要 Next AI Handoff Package**：否（Commit 屬於 Product Owner 親自執行/核准範疇，不透過 AI Handoff 自動化）。
- **Target AI**：N/A（不適用）。
- **copy boundary**：N/A（不適用）。
- **notify-gate command requirement**：不附 `next_handoff_path`；使用 `TELEGRAM_CONTENT_MODE=summary`。
- **stop condition**：Git Review 未通過、commit scope 含 Prohibited Files。
- **Telegram content mode**：`summary`（固定，不使用 handoff）。

### 3.12 `push_approval`（高風險）

- **Gate ID**：`push_approval`

- **Gate name**：Push 核准
- **Notification purpose**：讓 Product Owner 明確核准是否執行 Push。
- **Product Owner action required**：確認 commit hash、目標 remote/branch。
- **Decision options**：核准 Push / 暫緩 / 拒絕。
- **Recommended next step**：核准後由 Product Owner 親自執行 `git push`。
- **Required Reading**：`docs/development/execution-permission-policy.md` 2.7。
- **Evidence reference**：對應的 commit hash 記錄。
- **是否需要 Next AI Handoff Package**：否。
- **Target AI**：N/A（不適用）。
- **copy boundary**：N/A（不適用）。
- **notify-gate command requirement**：不附 `next_handoff_path`；使用 `TELEGRAM_CONTENT_MODE=summary`。
- **stop condition**：Commit 尚未完成、commit hash 未確認。
- **Telegram content mode**：`summary`（固定）。

### 3.13 `retrospective_content_approval`

- **Gate ID**：`retrospective_content_approval`

- **Gate name**：Sprint Retrospective 內容核准
- **Notification purpose**：讓 Product Owner 核准 Retrospective 內容與 Decision 區塊。
- **Product Owner action required**：審閱 Retrospective 內容，填寫 Product Owner Decision。
- **Decision options**：核准 / 要求補充 Lessons Learned 或 Process Improvement / 退回。
- **Recommended next step**：核准後進入 `product_owner_closure_approval`。
- **Required Reading**：`docs/development/development-principles.md` 第 3 節（Rule 6 Mandatory Template）、Retrospective 內容本身。
- **Evidence reference**：本輪 Sprint Retrospective 文件。
- **是否需要 Next AI Handoff Package**：否。
- **Target AI**：N/A（不適用）。
- **copy boundary**：N/A（不適用）。
- **notify-gate command requirement**：不附 `next_handoff_path`；使用 `TELEGRAM_CONTENT_MODE=summary`。
- **stop condition**：Retrospective 缺少 Product Owner Decision 區塊。
- **Telegram content mode**：`summary`（固定）。

### 3.14 `product_owner_closure_approval`

- **Gate ID**：`product_owner_closure_approval`

- **Gate name**：Sprint 結案核准
- **Notification purpose**：讓 Product Owner 確認 Definition of Done 並給予最終結案核准。
- **Product Owner action required**：確認 Definition of Done 全部項目完成。
- **Decision options**：結案 / 指出未完成項目，暫緩結案。
- **Recommended next step**：結案後 Sprint 生命週期正式結束。
- **Required Reading**：`docs/development/development-principles.md` 第 5 節（Definition of Done）。
- **Evidence reference**：本 Sprint 所有 round 的正式 artifact。
- **是否需要 Next AI Handoff Package**：否。
- **Target AI**：N/A（不適用）。
- **copy boundary**：N/A（不適用）。
- **notify-gate command requirement**：不附 `next_handoff_path`；使用 `TELEGRAM_CONTENT_MODE=summary`。
- **stop condition**：Definition of Done 未全部滿足。
- **Telegram content mode**：`summary`（固定）。

## 4. Summary Table

| gate_id | 是否需要 Next AI Handoff | Target AI | copy boundary | Telegram content mode（預設） | Claude report push to PO |
|---|---|---|---|---|---|
| `sprint_start_approval` | 是 | ChatGPT | BEGIN/END COPY TO CHATGPT | handoff | — |
| `architecture_definition_approval` | 是 | Claude Code | BEGIN/END COPY TO CLAUDE | handoff | — |
| `claude_implementation_approval` | 是 | Claude Code | BEGIN/END COPY TO CLAUDE | handoff | — |
| `claude_implementation_report_acceptance` | 是 | Codex | BEGIN/END COPY TO CODEX | handoff | **YES** |
| `codex_review_result_decision` | 視結果而定 | Claude Code（Must Fix 時） | BEGIN/END COPY TO CLAUDE（Must Fix 時） | handoff / summary | — |
| `claude_must_fix_approval` | 是 | Claude Code | BEGIN/END COPY TO CLAUDE | handoff | — |
| `claude_must_fix_report_acceptance`（新增） | 是 | Codex | BEGIN/END COPY TO CODEX | handoff | **YES** |
| `codex_final_review_result_decision` | 預設否 | （視情況）Claude Code | BEGIN/END COPY TO CLAUDE（僅需要再修正時） | summary | — |
| `product_owner_validation_approval` | 是 | Codex | BEGIN/END COPY TO CODEX | handoff | — |
| `codex_git_review_result_decision` | 預設否 | N/A（不適用；視情況為 Codex） | N/A（不適用；視情況為 BEGIN/END COPY TO CODEX） | summary | — |
| `commit_approval` | 否 | N/A（不適用） | N/A（不適用） | summary | — |
| `push_approval` | 否 | N/A（不適用） | N/A（不適用） | summary | — |
| `retrospective_content_approval` | 否 | N/A（不適用） | N/A（不適用） | summary | — |
| `product_owner_closure_approval` | 否 | N/A（不適用） | N/A（不適用） | summary | — |

「Claude report push to PO」欄標示 **YES** 的兩個 Gate（`claude_implementation_report_acceptance`、`claude_must_fix_report_acceptance`）是「Claude Completion Gate」，另外還有 `Report artifact`、`PO review required`、`PO manually sends to Codex`、`Auto send to Codex`、`Codex review checklist authority` 5 個欄位，見各自章節；其餘 12 個 Gate 這 6 個欄位不適用（標示 `—`），因為它們不是「Claude 剛完成報告」的情境。

## 5. 與既有系統的關係

本矩陣不新增、不修改 `scripts/review_bridge.sh` 的 `GATE_WHITELIST`、`_gate_resolve_metadata()`、`cmd_notify_gate()` 或任何 notify-gate 執行邏輯——14 個 Gate 全部是既有 21-Gate canonical whitelist 的子集，`notify-gate` 已經原生支援。本矩陣只是「操作準則」文件，指導 Product Owner（或代為準備 Handoff Package 的 Claude Code）在呼叫 `notify-gate` 時，如何為這 14 個 Gate 決定 `summary_path`、`next_handoff_path`、`TELEGRAM_CONTENT_MODE` 三個參數。
