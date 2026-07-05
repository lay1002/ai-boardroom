# Sprint-015 Architecture — Workspace Repository Hygiene & Scope Isolation Baseline

## 0. Provenance Note

此 Architecture 內容來源為 Product Owner 已核准的 Sprint-015 Handoff Package（Product Owner Decision / Architecture Definition / Architecture Artifact 三項皆已核准），由 Product Owner 直接於 Claude Code Implementation Handoff Package 中提供。這不是 Claude Code 自行設計的 Architecture；Claude Code 只負責依此進行 Implementation，不得自行擴大或縮小範圍。

## 1. Sprint Goal

本 Sprint 的目標不是新增產品功能，也不是清理所有歷史檔案，而是建立 repository hygiene 與 Sprint scope isolation baseline，讓後續每個 Sprint 可以清楚判斷：哪些檔案可以 commit、哪些不可 commit、哪些屬於 runtime evidence、哪些屬於 local state、哪些屬於 historical/unrelated artifact、哪些需要 Product Owner 額外決策，以及 Codex Git Review 應如何檢查 scope contamination。

## 2. Scope Boundary

### In Scope

1. 建立 `reviews/sprint-015/round-001/` 目錄。
2. 建立 `reviews/sprint-015/round-001/architecture.md`（本檔案）。
3. 建立 `docs/development/repository-hygiene-policy.md`。
4. 建立 `docs/development/sprint-scope-isolation-policy.md`。
5. 建立 `docs/development/runtime-evidence-exclusion-policy.md`。
6. 建立 `docs/development/git-review-checklist.md`。
7. 建立 `reviews/sprint-015/round-001/dirty-files-inventory.md`。
8. 盤點目前 working tree dirty / untracked files。
9. 將 dirty / untracked files 依分類模型歸類。
10. 標記每個檔案是否可納入 Sprint-015 commit。
11. 建立 `reviews/sprint-015/round-001/claude_report.md`。

### Out of Scope

不得刪除 unrelated files；不得搬移 unrelated files；不得 stage unrelated files；不得 commit；不得 push；不得修改 n8n workflow JSON；不得修改 Telegram notification runtime；不得修改 Sprint-013 / Sprint-014 已 CLOSED 結論；不得自動呼叫 Codex；不得擴大成 repository restructuring；不得做 Product Owner Gate Metadata Canonicalization；不得新增自動化執行 Claude / Codex；不得修改 runtime delivery behavior。

## 3. Allowed Files

```text
docs/development/repository-hygiene-policy.md
docs/development/sprint-scope-isolation-policy.md
docs/development/runtime-evidence-exclusion-policy.md
docs/development/git-review-checklist.md
reviews/sprint-015/round-001/architecture.md
reviews/sprint-015/round-001/dirty-files-inventory.md
reviews/sprint-015/round-001/claude_report.md
```

若 Claude Code 認為必須新增其他檔案，須在 `claude_report.md` 中說明新增原因、與 Sprint-015 scope 的關係、為何不構成 scope expansion、是否需要 Product Owner 額外核准。

## 4. Prohibited Files

不得被修改、stage、commit：

```text
configs/n8n/*.json
reviews/notification_history.jsonl
reviews/*/notifications/
reviews/sprint-013/round-001/notifications/
reviews/sprint-014/round-001/notifications/
```

可列入 inventory，但不得在 Sprint-015 未經 Product Owner 額外核准時納入 commit：

```text
AGENTS.md
CLAUDE.md
CODEX.md
GPT.md
docs/architecture.md
docs/vision.md
docs/principles.md
docs/roadmap.md
docs/development/n8n-*.md
reviews/notification-gap-review.md
reviews/sprint-004/
reviews/sprint-006/
reviews/sprint-007/
reviews/sprint-009/
reviews/sprint-013/round-001/notifications/
```

## 5. File Classification Model

見 `docs/development/repository-hygiene-policy.md` 第 2 節：Source Artifact / Development Documentation Artifact / Sprint Review Artifact / Runtime Evidence / Local State / Historical-Unrelated Artifact / Unknown-Product Owner Decision Required，共 7 類。本文件不重複定義，僅引用。

## 6. Required Documents

1. `docs/development/repository-hygiene-policy.md` — Repository hygiene 原則、檔案分類模型、commit/prohibited 判斷規則、Product Owner 決策情境。
2. `docs/development/sprint-scope-isolation-policy.md` — 每個 Sprint 的 Allowed/Prohibited/Commit Candidate Files 定義責任、Claude Report/Codex Review/Codex Git Review 各自的檢查責任、Commit/Push 前置確認。
3. `docs/development/runtime-evidence-exclusion-policy.md` — Runtime evidence / notification history / generated notification packages / dry-run / live-run evidence 預設不 commit 的規則與例外流程。
4. `docs/development/git-review-checklist.md` — Codex Git Review 固定 12 項 checklist。
5. `reviews/sprint-015/round-001/dirty-files-inventory.md` — 目前 working tree 的完整盤點與分類結果。

## 7. Claude Implementation Boundary

Claude Code 只負責：依本 Architecture 建立第 6 節列出的文件與 `dirty-files-inventory.md`、`claude_report.md`；盤點並分類現有 dirty/untracked 檔案；標記 Sprint-015 commit eligibility。Claude Code 不得刪除、搬移、stage、commit 任何檔案，不得修改本 Architecture 的決策內容，不得修改 Prohibited Files 清單中的任何檔案。

## 8. Codex Review Boundary

Codex Review 依 `docs/development/sprint-scope-isolation-policy.md` 第 6 節確認：Claude Code 回報的 Modified/Added Files 是否與本 Architecture 的 Allowed Files 一致；是否有未回報但 `git status` 顯示已變更的檔案；是否有 Prohibited Files 被觸碰；四份新文件的內容是否符合第 8（Required Documents Content）節要求；`dirty-files-inventory.md` 的分類是否合理、完整。

## 9. Codex Git Review Boundary

Sprint-015 本身不執行 commit / push（本 Sprint 的產出是 policy 與 inventory，供未來所有 Sprint 的 Codex Git Review 使用）。Codex Git Review 依 `docs/development/git-review-checklist.md` 的 12 項固定清單執行，適用於本 Sprint 之後的所有 Sprint。

## 10. Validation Strategy

本 Sprint 未修改任何 script/runtime 程式碼，因此不需要執行 `bash scripts/test_review_bridge.sh` 完整回歸測試（見 `claude_report.md` 第 10 節的明確聲明）。驗證方式為：確認 4 份必要文件與 inventory、report 皆已建立且內容符合第 8/9 節要求；確認 `git status --short`、`git diff --name-only` 顯示的變更範圍與 Allowed Files 完全一致；確認 Prohibited Files 未被觸碰。

## 11. Definition of Done

1. 4 份 policy 文件皆已建立且內容符合本文件第 8 節要求。
2. `dirty-files-inventory.md` 已建立，涵蓋目前 working tree 所有 dirty/untracked 項目（可用 directory-level entry 並說明原因）。
3. 每個 inventory 項目皆已標記 Classification、Sprint-015 Scope、Recommendation、PO Decision Required、Commit Eligibility。
4. `claude_report.md` 已建立，涵蓋第 11 節（Claude Implementation Report 要求）全部項目。
5. 未修改、刪除、搬移、stage、commit 任何 Prohibited Files 或 unrelated files。
6. 未執行 `git add` / `git commit` / `git push`。
7. Next Actor 標示為 Codex，Recommended Execution Mode 標示為 Codex Review Mode。
