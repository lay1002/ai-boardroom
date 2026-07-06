# Codex Git Review Handoff Package — sprint-017 / round-001

## 1. Target AI

Codex

## 2. Current Stage

Product Owner Validation Approved

## 3. 語言規則

結論、風險說明、checklist 結果須用繁體中文；程式碼、路徑、指令、gate_id 可保留英文。

## 4. Required Reading

請閱讀：

- PROJECT_BOOTSTRAP.md
- AGENTS.md
- GPT.md
- CLAUDE.md
- CODEX.md
- docs/development/development-workflow.md
- docs/development/consensus-workflow.md
- docs/development/n8n-claude-done-notification.md
- docs/development/n8n-codex-review-done-notification.md
- scripts/review_bridge.sh
- docs/development/git-review-checklist.md
- docs/development/repository-hygiene-policy.md
- docs/development/runtime-evidence-exclusion-policy.md
- reviews/sprint-017/round-001/architecture.md
- reviews/sprint-017/round-001/claude_report.md
- reviews/sprint-017/round-001/codex_final_review.md

若不存在，記錄為 Missing Context，不要自行建立或補寫。

## 5. Context Completeness Check（報告必須包含）

```markdown
## Context Completeness Check
- Full required reading list provided: PASS / FAIL
- Missing context files: None / list
- Did missing context affect implementation or review: YES / NO
- Notes:
```

## 6. Task Objective / Review Target

依 `docs/development/git-review-checklist.md` 12 項清單，檢查 Sprint-017 round-001（Must Fix Round 1–7）目前 git 變更範圍是否乾淨、是否只含授權範圍檔案，是否可安全進入 Commit。**不執行 commit，只做檢查與報告。** 審查對象：`git status --short` / `git diff --name-only` / `git diff --cached --name-only`。

## 7. Allowed Files

`docs/development/consensus-workflow.md`、`telegram-po-gate-notification-specification.md`、`product-owner-gate-metadata.md`、`scripts/review_bridge.sh`、`scripts/test_review_bridge.sh`、`reviews/sprint-017/round-001/` 下全部檔案（含本次應產出的 `codex_git_review.md`）。

## 8. Prohibited Files

`configs/n8n/*.json`、`reviews/notification_history.jsonl`、`reviews/*/notifications/`、Sprint-013/014/015/016 既有 artifacts（未修改部分維持原狀）；以下 unrelated dirty/untracked files 不得納入 commit 範圍：`AGENTS.md`、`CLAUDE.md`、`CODEX.md`、`GPT.md`、`docs/architecture.md`、`docs/vision.md`、`docs/principles.md`、`docs/roadmap.md`、`docs/development/n8n-*.md`、`reviews/notification-gap-review.md`、`reviews/sprint-004/`、`reviews/sprint-006/`、`reviews/sprint-007/`、`reviews/sprint-009/`。

## 9. Repository Hygiene / Runtime Evidence Exclusion Checks

依 `docs/development/repository-hygiene-policy.md` 與 `docs/development/runtime-evidence-exclusion-policy.md`：確認第 7 節 Allowed Files 對應 Sprint-017 授權範圍；確認第 8 節 Prohibited Files 未出現在 `git status`/`git diff`；確認無 runtime evidence（如 `notification_history.jsonl`）被 stage。

## 10. 產出報告路徑

`reviews/sprint-017/round-001/codex_git_review.md`，須含 Context Completeness Check（第 5 節）、12 項 checklist 逐一結果、Final Recommendation（PASS / FAIL / REQUEST_CHANGES）。

## 11. 嚴格限制

不得 `git add`、不得 `commit`、不得 `push`、不得執行 `notify-gate`、不得觸發 Telegram、不得修改 n8n JSON。只允許唯讀 git 指令與撰寫第 10 節報告。

## 12. Copyable Prompt

```text
請閱讀第 4 節完整清單。工作：依 docs/development/git-review-checklist.md 12 項清單，對 Sprint-017 round-001（含 Must Fix Round 1-7）的 git 變更範圍做 Git Review，確認是否只含 Allowed Files（第 7 節）、排除 Prohibited Files（第 8 節）、符合 Repository Hygiene / Runtime Evidence Exclusion（第 9 節）。請產出 reviews/sprint-017/round-001/codex_git_review.md，含 Context Completeness Check、12 項 checklist 結果、Final Recommendation。輸出語言：繁體中文。限制：不得 git add/commit/push、不得執行 notify-gate、不得觸發 Telegram、不得修改 n8n JSON。
```
