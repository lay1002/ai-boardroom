# Product Owner Gate Metadata

Version: 1.1 (Sprint-016; `current_status_zh` field added in Sprint-016 Must Fix round)

## 1. Purpose

本文件是 21 個 Product Owner Gate metadata 的 **canonical source of truth**。Sprint-014 在 `scripts/review_bridge.sh` 的 `_gate_resolve_metadata()` 中為每個 Gate 填入了 `gate_name_zh`、`next_actor`、`recommended_execution_mode`、`risk_level`、`current_status_zh`、`product_owner_next_action_zh`，並在 `claude_report.md` 中揭露這是「實作填補」而非逐項核准的 Architecture 決策。Sprint-016 將這些值正式提升為 canonical metadata：本文件的內容與 `_gate_resolve_metadata()` 的實際程式碼**完全一致**（Sprint-016 未變更任何一個 Gate 的既有值，只是把它們正式記錄下來，並補上先前沒有的欄位）。

日後若要調整任何 Gate 的 metadata，應先修改本文件（經 Product Owner 核准），再同步修改 `scripts/review_bridge.sh`——本文件是規格，`_gate_resolve_metadata()` 是實作。

## 2. Field Definitions

每個 Gate 記錄 15 個欄位：

1. **gate_id** — whitelist 中的識別碼。
2. **中文名稱**（gate_name_zh）。
3. **Gate 說明** — 這個 Gate 代表什麼決策情境（靜態描述，不隨時間變化）。
4. **notification_recipient** — 固定為 `Product Owner`（見 `docs/development/telegram-po-gate-notification-specification.md` 第 8 節）。
5. **next_actor** — `Product Owner` / `ChatGPT` / `Claude Code` / `Codex` 之一。
6. **recommended_execution_mode** — `docs/development/execution-permission-policy.md` 定義的 7 個 mode 之一，或 `N/A（Product Owner 決策點）` 類型的值。
7. **risk_level** — `low` / `medium` / `high`。
8. **現況狀態**（current_status_zh）— Telegram Gate 通知中「📍 目前狀態」實際顯示的繁體中文文字，逐字對齊 `scripts/review_bridge.sh` 的 `GATE_STATUS_ZH`（見第 5 節）。
9. **Product Owner 下一步**（product_owner_next_action_zh）。
10. **Handoff Package 用途** — 這個 Gate 的可複製區塊，實際上是用來讓 Product Owner 做什麼轉交動作。
11. **是否 high-risk gate** — 是否套用高風險 Telegram 格式（`docs/development/telegram-po-gate-notification-specification.md` 第 7 節）。
12. **是否 commit / push sensitive** — 是否直接涉及 repository / remote state 變更。
13. **是否允許 sandboxed read-only auto-approval** — 見第 3 節說明；這一律回答的是「Level 0 唯讀指令是否可用於準備此 Gate」，**不是**「此 Gate 的核准是否可以自動同意」。
14. **Manual Gate requirement** — 是否需要 Product Owner 明確核准（21 個 Gate 全部為「是」）。
15. **metadata completeness status** — 本文件建立後，21 個 Gate 皆為 `Complete`。

## 3. 關於「是否允許 sandboxed read-only auto-approval」的重要澄清

`docs/development/execution-permission-policy.md` 的 Safety Level 0（Read-Only Sandbox Safe）定義的是**工具/指令層級**的自動同意（例如 `git status --short`、`cat`、`grep`），不是「Gate 核准」層級的自動同意。

**21 個 Product Owner Gate 的核准動作本身，一律不允許自動同意**——這是 Product Owner Manual Gate 的核心原則，不因為某個 Gate 的風險等級是 `low` 就可以自動通過。因此本文件第 4 節每個 Gate 的「是否允許 sandboxed read-only auto-approval」欄位，回答的是「Claude Code / Codex 在準備這個 Gate 的 Handoff Package 或蒐集判斷所需資訊時，是否可以自由使用 Level 0 唯讀指令而不需要逐一詢問」——由於 Level 0 由定義上就是安全、不改變任何狀態的，這個答案對全部 21 個 Gate 都是「是（僅限 Level 0 唯讀指令，不代表 Gate 本身可自動核准）」。

## 4. 21 Gate Canonical Metadata

### 4.1 Quick Reference

| gate_id | 中文名稱 | next_actor | recommended_execution_mode | risk_level | high-risk gate | commit/push sensitive |
|---|---|---|---|---|---|---|
| `sprint_start_approval` | Sprint 啟動核准 | ChatGPT | N/A（Product Owner 決策點） | low | 否 | 否 |
| `architecture_definition_approval` | Architecture 定義核准 | Claude Code | N/A（Product Owner 決策點） | low | 否 | 否 |
| `architecture_artifact_approval` | Architecture Artifact 確認 | Claude Code | N/A（Product Owner 決策點） | low | 否 | 否 |
| `claude_implementation_approval` | Claude Implementation 執行核准 | Claude Code | Claude Implementation Mode | medium | 否 | 否 |
| `claude_implementation_report_acceptance` | Claude Implementation Report 驗收 | Codex | N/A（Product Owner 決策點） | low | 否 | 否 |
| `codex_review_approval` | Codex Review 執行核准 | Codex | Codex Review Mode | low | 否 | 否 |
| `codex_review_result_decision` | Codex Review 結果決策 | Claude Code | N/A（Product Owner 決策點） | low | 否 | 否 |
| `claude_must_fix_approval` | Claude Must Fix 執行核准 | Claude Code | Claude Must Fix Mode | medium | 否 | 否 |
| `claude_must_fix_report_acceptance` | Claude Must Fix Report 驗收 | Codex | N/A（Product Owner 決策點） | low | 否 | 否 |
| `codex_final_review_approval` | Codex Final Review 執行核准 | Codex | Codex Final Review Mode | low | 否 | 否 |
| `codex_final_review_result_decision` | Codex Final Review 結果決策 | Product Owner | N/A（Product Owner 決策點） | low | 否 | 否 |
| `product_owner_validation_approval` | Product Owner Validation 核准 | Product Owner | N/A（Product Owner 決策點） | low | 否 | 否 |
| `codex_git_review_approval` | Codex Git Review 執行核准 | Codex | Codex Git Review Mode | medium | 否 | 否 |
| `codex_git_review_result_decision` | Codex Git Review 結果決策 | Product Owner | N/A（Product Owner 決策點） | medium | 否 | 否 |
| `commit_approval` | Commit 核准 | Product Owner | N/A（Commit 需人工核准，不可低中斷） | high | **是** | **是（commit）** |
| `codex_commit_approval` | Codex Commit 執行核准 | Codex | Codex Commit Mode | high | **是** | **是（commit）** |
| `push_approval` | Push 核准 | Product Owner | N/A（Push 需人工核准，不可低中斷） | high | **是** | **是（push）** |
| `codex_push_approval` | Codex Push 執行核准 | Codex | Codex Push Mode | high | **是** | **是（push）** |
| `retrospective_entry_approval` | Sprint Retrospective 啟動核准 | Claude Code | N/A（Product Owner 決策點） | low | 否 | 否 |
| `retrospective_content_approval` | Sprint Retrospective 內容核准 | Product Owner | N/A（Product Owner 決策點） | low | 否 | 否 |
| `product_owner_closure_approval` | Sprint 結案核准 | Product Owner | N/A（Product Owner 決策點） | low | 否 | 否 |

所有 21 個 Gate：`notification_recipient` = `Product Owner`；`是否允許 sandboxed read-only auto-approval` = 是（僅限 Level 0 唯讀指令，見第 3 節）；`Manual Gate requirement` = 是；`metadata completeness status` = Complete。

### 4.2 Per-Gate Detail

#### `sprint_start_approval`
- **Gate 說明**：Product Owner 決定是否啟動一個新 Sprint，是 Sprint 生命週期的起點。
- **現況狀態**（current_status_zh）：已收到新 Sprint 需求，等待 Product Owner 確認是否啟動。
- **Product Owner 下一步**：請確認是否啟動本 Sprint；確認後請 ChatGPT 開始 Architecture 設計。
- **Handoff Package 用途**：讓 Product Owner 將啟動決定與需求脈絡轉交給 ChatGPT，作為 Architecture 設計的起點依據。

#### `architecture_definition_approval`
- **Gate 說明**：Product Owner 核准 ChatGPT 提出的 Architecture 定義（決策層級，尚未落成正式 artifact 檔案）。
- **現況狀態**（current_status_zh）：ChatGPT 已完成 Architecture 定義，等待 Product Owner 核准。
- **Product Owner 下一步**：請審閱 Architecture 定義是否符合預期；核准後可交給 Claude Code 開始實作。
- **Handoff Package 用途**：讓 Product Owner 將 Architecture 定義轉交給 Claude Code，作為後續實作的依據來源。

#### `architecture_artifact_approval`
- **Gate 說明**：Product Owner 確認 Architecture Artifact（`architecture.md`）內容與先前核准的決策一致。
- **現況狀態**（current_status_zh）：Architecture Artifact（architecture.md）已建立，等待 Product Owner 確認內容正確。
- **Product Owner 下一步**：請確認 `architecture.md` 內容與先前核准的決策一致；確認後可交給 Claude Code 實作。
- **Handoff Package 用途**：讓 Product Owner 將已確認的 `architecture.md` 轉交給 Claude Code 開始實作。

#### `claude_implementation_approval`
- **Gate 說明**：Product Owner 授權 Claude Code 依已核准 Architecture 開始實作（進入 Claude Implementation Mode）。
- **現況狀態**（current_status_zh）：Architecture 已核准，等待 Product Owner 授權 Claude Code 開始實作。
- **Product Owner 下一步**：請授權 Claude Code 依已核准 Architecture 開始實作。
- **Handoff Package 用途**：讓 Product Owner 將實作授權連同 Architecture 位置轉交給 Claude Code。

#### `claude_implementation_report_acceptance`
- **Gate 說明**：Product Owner 驗收 Claude Code 產出的 `claude_report.md`，確認實作內容與範圍相符。
- **現況狀態**（current_status_zh）：Claude Code 已完成實作並產出 claude_report.md，等待 Product Owner 驗收。
- **Product Owner 下一步**：請審閱 `claude_report.md`；驗收後可交給 Codex 進行 Review。
- **Handoff Package 用途**：讓 Product Owner 將驗收結果與 report 位置轉交給 Codex 進行 Review。

#### `codex_review_approval`
- **Gate 說明**：Product Owner 授權 Codex 開始對 Claude Code 的實作進行 Review（進入 Codex Review Mode）。
- **現況狀態**（current_status_zh）：Claude Implementation Report 已驗收，等待 Product Owner 授權 Codex 開始 Review。
- **Product Owner 下一步**：請授權 Codex 開始進行 Review。
- **Handoff Package 用途**：讓 Product Owner 將 Review 授權轉交給 Codex。

#### `codex_review_result_decision`
- **Gate 說明**：Product Owner 依 `codex_review.md` 結論決定下一步（進入 Must Fix 或直接進入下一階段）。
- **現況狀態**（current_status_zh）：Codex 已完成 Review，等待 Product Owner 決定下一步。
- **Product Owner 下一步**：請審閱 `codex_review.md` 結論；若有 Must Fix，請授權 Claude Code 進行修正，否則可進入下一階段。
- **Handoff Package 用途**：讓 Product Owner 將 Review 結論與後續決定（如需要）轉交給 Claude Code。

#### `claude_must_fix_approval`
- **Gate 說明**：Product Owner 授權 Claude Code 依 Codex 指出的 Must Fix 項目進行修正（進入 Claude Must Fix Mode）。
- **現況狀態**（current_status_zh）：Codex Review 指出 Must Fix 項目，等待 Product Owner 授權 Claude Code 進行修正。
- **Product Owner 下一步**：請授權 Claude Code 依 `codex_review.md` 的 Must Fix 項目進行修正。
- **Handoff Package 用途**：讓 Product Owner 將 Must Fix 授權與範圍轉交給 Claude Code。

#### `claude_must_fix_report_acceptance`
- **Gate 說明**：Product Owner 驗收 Claude Code 的 Must Fix 修正報告。
- **現況狀態**（current_status_zh）：Claude Code 已完成 Must Fix 修正並產出報告，等待 Product Owner 驗收。
- **Product Owner 下一步**：請審閱 Must Fix Report；驗收後可交給 Codex 進行 Final Review。
- **Handoff Package 用途**：讓 Product Owner 將驗收結果轉交給 Codex 進行 Final Review。

#### `codex_final_review_approval`
- **Gate 說明**：Product Owner 授權 Codex 開始 Final Review，確認 Must Fix 是否已解決（進入 Codex Final Review Mode）。
- **現況狀態**（current_status_zh）：Must Fix Report 已驗收，等待 Product Owner 授權 Codex 進行 Final Review。
- **Product Owner 下一步**：請授權 Codex 開始 Final Review。
- **Handoff Package 用途**：讓 Product Owner 將 Final Review 授權轉交給 Codex。

#### `codex_final_review_result_decision`
- **Gate 說明**：Product Owner 依 Final Review 結論決定是否進入 Product Owner Validation 或需要再一輪修正。
- **現況狀態**（current_status_zh）：Codex 已完成 Final Review，等待 Product Owner 決定是否進入下一階段。
- **Product Owner 下一步**：請審閱 `codex_final_review.md` 結論，決定是否進入 Product Owner Validation 或需要再一輪修正。
- **Handoff Package 用途**：讓 Product Owner 記錄此決策脈絡，作為後續（進入 Validation 或重新進入 Must Fix）的依據。

#### `product_owner_validation_approval`
- **Gate 說明**：Product Owner 實際驗證本輪成果（例如功能是否運作），確認後進入 Git Review。
- **現況狀態**（current_status_zh）：Final Review 已 PASS，等待 Product Owner 進行最終驗證。
- **Product Owner 下一步**：請實際驗證本輪成果，確認後可進入 Git Review 階段。
- **Handoff Package 用途**：讓 Product Owner 記錄驗證結果，作為進入 Git Review 的依據。

#### `codex_git_review_approval`
- **Gate 說明**：Product Owner 授權 Codex 檢查目前 git 變更範圍是否乾淨、是否符合本 Sprint 範圍（進入 Codex Git Review Mode）。
- **現況狀態**（current_status_zh）：Product Owner Validation 已完成，等待授權 Codex 進行 Git Review。
- **Product Owner 下一步**：請授權 Codex 檢查 git 變更範圍是否乾淨、是否符合本 Sprint 範圍。
- **Handoff Package 用途**：讓 Product Owner 將 Git Review 授權轉交給 Codex。
- **補充**：本身不執行 commit/push，屬於 Commit 前置檢查，故「commit/push sensitive」標記為否，但 `risk_level` 因緊接在 Commit 之前而標示為 `medium`。

#### `codex_git_review_result_decision`
- **Gate 說明**：Product Owner 依 Git Review 結果決定是否進入 Commit 階段。
- **現況狀態**（current_status_zh）：Codex 已完成 Git Review，等待 Product Owner 決定是否進入 Commit 階段。
- **Product Owner 下一步**：請審閱 Git Review 結果，確認 commit scope 乾淨後再決定是否核准 Commit。
- **Handoff Package 用途**：讓 Product Owner 記錄 Git Review 結果與是否核准進入 Commit 的決策。

#### `commit_approval`（High-Risk）
- **Gate 說明**：Product Owner 明確核准是否執行 Commit，涉及 repository state 變更。
- **現況狀態**（current_status_zh）：Git Review 已通過，等待 Product Owner 明確核准 Commit。
- **Product Owner 下一步**：請確認 commit scope、排除檔案與訊息內容後，明確核准是否執行 Commit。
- **Handoff Package 用途**：讓 Product Owner 記錄 commit scope、排除檔案與訊息內容的核准依據。
- **Manual Gate**：嚴格（不可低中斷，每一步都需要 Product Owner 明確核准）。

#### `codex_commit_approval`（High-Risk）
- **Gate 說明**：Product Owner 授權 Codex 準備 commit 訊息與範圍草案（進入 Codex Commit Mode），實際 commit 仍須 Product Owner 親自核准並執行。
- **現況狀態**（current_status_zh）：Product Owner 已核准 Commit 方向，等待授權 Codex 準備 commit 內容供人工核准。
- **Product Owner 下一步**：請授權 Codex 準備 commit 訊息與範圍草案，最終仍由 Product Owner 親自核准並執行 commit。
- **Handoff Package 用途**：讓 Product Owner 將 commit 準備授權轉交給 Codex。
- **Manual Gate**：嚴格（Codex 只能在 Product Owner 核准後執行，不得自行 `git add`/`git commit`）。

#### `push_approval`（High-Risk）
- **Gate 說明**：Product Owner 明確核准是否執行 Push，涉及 remote repository state 變更。
- **現況狀態**（current_status_zh）：Commit 已完成，等待 Product Owner 明確核准 Push。
- **Product Owner 下一步**：請確認 commit hash、目標 remote/branch 後，明確核准是否執行 Push。
- **Handoff Package 用途**：讓 Product Owner 記錄 commit hash、目標 remote/branch 的核准依據。
- **Manual Gate**：嚴格（不可低中斷）。

#### `codex_push_approval`（High-Risk）
- **Gate 說明**：Product Owner 授權 Codex 確認 push 前檢查清單（進入 Codex Push Mode），實際 push 仍須 Product Owner 親自核准並執行。
- **現況狀態**（current_status_zh）：Product Owner 已核准 Push 方向，等待授權 Codex 準備 push 前檢查供人工核准。
- **Product Owner 下一步**：請授權 Codex 確認 push 前檢查清單，最終仍由 Product Owner 親自核准並執行 push。
- **Handoff Package 用途**：讓 Product Owner 將 push 前檢查授權轉交給 Codex。
- **Manual Gate**：嚴格（Codex 只能在 Product Owner 核准後執行，不得自行 `git push`）。

#### `retrospective_entry_approval`
- **Gate 說明**：Product Owner 授權開始撰寫 Sprint Retrospective 草稿。
- **現況狀態**（current_status_zh）：本輪主要工作已完成，等待 Product Owner 授權開始 Sprint Retrospective。
- **Product Owner 下一步**：請授權 Claude Code 撰寫 Sprint Retrospective 草稿。
- **Handoff Package 用途**：讓 Product Owner 將撰寫授權轉交給 Claude Code。

#### `retrospective_content_approval`
- **Gate 說明**：Product Owner 核准 Retrospective 內容與 Product Owner Decision 區塊。
- **現況狀態**（current_status_zh）：Sprint Retrospective 草稿已完成，等待 Product Owner 核准內容與 Decision 區塊。
- **Product Owner 下一步**：請審閱 Retrospective 內容，填寫 Product Owner Decision。
- **Handoff Package 用途**：讓 Product Owner 記錄審閱與核准結果。

#### `product_owner_closure_approval`
- **Gate 說明**：Product Owner 確認 Definition of Done 全部項目皆已完成，給予本 Sprint 最終結案核准。
- **現況狀態**（current_status_zh）：Retrospective 已核准，等待 Product Owner 進行最終 Sprint 結案。
- **Product Owner 下一步**：請確認 Definition of Done 全部項目皆已完成，並給予本 Sprint 最終結案核准。
- **Handoff Package 用途**：讓 Product Owner 記錄最終結案決策，正式關閉本 Sprint。

## 5. Consistency with Runtime

本文件第 4 節的 `gate_name_zh`、`next_actor`、`recommended_execution_mode`、`risk_level`、`current_status_zh`、`product_owner_next_action_zh` 欄位值，與 `scripts/review_bridge.sh` 的 `_gate_resolve_metadata()` 函式逐字一致（Sprint-016 未變更任何既有值；`current_status_zh` 於 Sprint-016 Must Fix 回合補齊，值同樣逐字取自 `GATE_STATUS_ZH`，未新增或變更 runtime 既有內容）。若兩者出現不一致，以 Product Owner 最後核准的本文件版本為準，並應同步更新 `_gate_resolve_metadata()`。
