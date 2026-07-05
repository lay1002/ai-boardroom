# Sprint Scope Isolation Policy

Version: 1.0 (Sprint-015)

## 1. 目的

每個 Sprint 的 Implementation、Review、Git Review、Commit、Push 都必須在明確定義的檔案範圍內進行，避免歷史累積的 dirty / untracked 檔案，或其他 Sprint 的變更，意外混入目前 Sprint 的 commit。本政策定義每個 Sprint 在 `architecture.md` 或 Handoff Package 中必須包含的範圍宣告，以及 Codex Review / Git Review / Commit / Push 各階段對此範圍的檢查責任。

本政策依賴 `docs/development/repository-hygiene-policy.md` 的檔案分類模型，不重複定義分類本身。

## 2. 每個 Sprint 必須定義 Allowed Files

每個 Sprint 的 Architecture Artifact（或 Product Owner 提供的 Handoff Package）必須明確列出一份 **Allowed Files** 清單：本 Sprint 預期會新增或修改的具體檔案路徑。

- 清單必須具體到檔案層級，而非只寫「相關文件」這種模糊描述。
- 若實作過程中發現必須新增清單外的檔案，Claude Code 必須在 `claude_report.md` 中明確說明：新增原因、與 Sprint scope 的關係、為何不構成 scope expansion、是否需要 Product Owner 額外核准。

## 3. 每個 Sprint 必須定義 Prohibited Files

每個 Sprint 的 Architecture Artifact 必須明確列出 **Prohibited Files**：本 Sprint 明確不得修改、stage、commit 的檔案或路徑。

Prohibited Files 至少必須包含：

1. Runtime Evidence（`docs/development/runtime-evidence-exclusion-policy.md` 定義的路徑）。
2. 其他已 CLOSED 或不相關 Sprint 的正式 artifact。
3. n8n workflow JSON、Telegram notification runtime 等本 Sprint 未被授權變更的既有系統行為。

## 4. 每個 Sprint 必須定義 Commit Candidate Files

除了 Allowed Files（實作過程中「可以碰」的檔案）之外，每個 Sprint 在準備 Commit 前，必須另外明確列出 **Commit Candidate Files**：實際要進入這次 commit 的檔案子集。

Allowed Files 不等於 Commit Candidate Files——例如某個檔案在實作過程中被讀取、暫時修改後又還原，或屬於 Runtime Evidence 的暫時輸出，即使在 Allowed Files 範圍內產生，也不必然是 Commit Candidate。

## 5. Claude Implementation Report 必須列 Changed Files

`claude_report.md` 必須明確列出：

1. 本次新增的檔案清單。
2. 本次修改的檔案清單。
3. 若 working tree 存在與本 Sprint 無關的既有 dirty / untracked 檔案，必須明確聲明「未處理、未修改」，不得略而不提。

## 6. Codex Review 必須檢查 Scope Contamination

Codex Review（`codex_review.md`）必須包含一個 Scope Review 段落，明確確認：

1. Claude Code 回報的 Modified/Added Files 是否與該 Sprint Architecture 的 Allowed Files 一致。
2. 是否有 Claude Code 未回報、但 `git status` 顯示已變更的檔案（未回報的變更視為 Blocking 問題）。
3. 是否有 Prohibited Files 被觸碰。

## 7. Codex Git Review 必須檢查 Staged Files

進入 Commit 之前的 Codex Git Review（見 `docs/development/git-review-checklist.md`）必須實際執行 `git status` / `git diff --name-only`，確認：

1. 即將被 stage 的檔案是否全部屬於該 Sprint 的 Commit Candidate Files。
2. 是否有 Prohibited Files 出現在 staged 或即將 staged 的變更中。
3. 是否有未預期的 unrelated dirty / untracked 檔案被連帶 `git add`。

## 8. Commit 前必須確認 Git Status

執行 `git add` 前，必須先執行 `git status` 並人工核對輸出，確認即將加入的檔案清單與 Commit Candidate Files 完全一致。禁止使用 `git add .` 或 `git add -A` 等萬用字元方式一次性加入整個 working tree（見 `docs/development/execution-permission-policy.md` 第 1 節）。

## 9. Push 前必須確認 Remote / Branch / Commit Hash

執行 `git push` 前，必須確認：

1. 目標 remote 名稱是否正確（例如 `origin`）。
2. 目標 branch 是否正確。
3. 即將 push 的 commit hash 是否為 Product Owner 已核准 commit 的 hash。
4. 是否為 force push——若是，必須另外取得 Product Owner 的明確授權（見 `docs/development/execution-permission-policy.md` 2.7 Codex Push Mode）。

## 10. 與其他文件的關係

- 檔案分類本身由 `docs/development/repository-hygiene-policy.md` 定義。
- Runtime Evidence 的排除規則由 `docs/development/runtime-evidence-exclusion-policy.md` 定義。
- Codex Git Review 的具體 checklist 項目由 `docs/development/git-review-checklist.md` 定義。
- Claude / Codex 各執行 mode 的低中斷與核准規則由 `docs/development/execution-permission-policy.md` 定義。
