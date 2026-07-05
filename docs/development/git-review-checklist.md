# Git Review Checklist v1

Version: 1.0 (Sprint-015)

## 1. 目的

本 checklist 是 Codex Git Review（`docs/development/consensus-workflow.md` 定義的 Manual Gate 節點之一）在核准進入 Commit 之前，必須逐項確認的固定清單。目的是把 `docs/development/repository-hygiene-policy.md` 與 `docs/development/sprint-scope-isolation-policy.md` 的原則，轉成一份每次 Git Review 都可以照著檢查、不遺漏的具體清單。

## 2. Checklist

Codex 在執行 Git Review 時，必須針對以下每一項給出明確結論（PASS / FAIL / N/A，並附理由）：

1. **是否只包含 active Sprint allowed files**——即將 commit 的檔案是否都落在該 Sprint Architecture 明確列出的 Allowed Files / Commit Candidate Files 範圍內。
2. **是否排除 unrelated dirty / untracked files**——`git status` 中屬於其他 Sprint 或與本 Sprint 無關的既有 dirty / untracked 檔案，是否被正確排除在外。
3. **是否排除 runtime evidence**——`reviews/notification_history.jsonl`、`reviews/*/round-*/notifications/*.md` 等 Runtime Evidence（見 `docs/development/runtime-evidence-exclusion-policy.md`）是否被排除。
4. **是否排除 local state**——cache、log、機器特定檔案是否被排除。
5. **是否排除 prohibited files**——該 Sprint Architecture 明確列出的 Prohibited Files（例如 n8n workflow JSON、Telegram runtime、其他已 CLOSED Sprint 的 artifact）是否確實未被觸碰。
6. **是否包含必要 Sprint artifacts**——該 Sprint 要求產出的正式 artifact（`architecture.md`、`claude_report.md`、規範文件等）是否都存在且完整，沒有遺漏。
7. **是否有測試或 validation evidence**——若本 Sprint 修改了 script/runtime 程式碼，`claude_report.md` 是否附上測試指令與測試結果；若本 Sprint 未修改任何 script，是否有明確聲明「未修改，不需要 full regression test」。
8. **是否有 Product Owner commit approval**——是否已取得 Product Owner 對本次 commit 範圍（scope）與 commit message 的明確核准，而非由 Claude Code 或 Codex 自行決定進入 commit。
9. **是否有 Product Owner push approval**——是否已取得 Product Owner 對本次 push 的明確核准（commit 核准不等於 push 核准，兩者是分開的 Gate，見 `docs/development/telegram-po-gate-notification-specification.md` 的 `commit_approval` 與 `push_approval` 兩個獨立 Gate）。
10. **commit message 是否符合 Sprint scope**——commit message 是否準確反映本次 commit 實際包含的變更範圍，沒有誇大或遺漏。
11. **push target 是否正確**——目標 remote（例如 `origin`）與 branch 是否正確，是否為非預期的 force push。
12. **commit hash 是否回報**——commit 完成後，是否已將實際產生的 commit hash 回報給 Product Owner，供其在 push 前核對。

## 3. 使用方式

1. 本 checklist 適用於每一個 Sprint 的 Codex Git Review 階段，是固定格式，不因 Sprint 不同而增減項目（若某 Sprint 的情境使某一項不適用，標示 N/A 並說明原因，而不是省略該項）。
2. 任何一項為 FAIL，Git Review 的 Final Recommendation 即為 FAIL，不得進入 Commit。
3. 本 checklist 不取代 `docs/development/consensus-workflow.md` 定義的 Manual Gate 流程，只是該流程中 Codex Git Review 這一步的具體操作依據。
