# Handoff Package

## 1. Target AI

Codex

## 2. Current Stage

Claude Implementation Completed

## 3. Objective

依已核准的 Architecture，Review sprint-010 round-001 的 Claude Code Implementation，並產出 codex_review.md。

## 4. Required Reading

- PROJECT_BOOTSTRAP.md
- docs/development/consensus-workflow.md
- scripts/review_bridge.sh
- reviews/sprint-010/round-001/architecture.md
- reviews/sprint-010/round-001/claude_report.md

## 5. Scope

- 檢查實作是否符合已核准的 Architecture。
- 檢查是否有 scope creep（範圍是否被自行擴大）。
- 檢查測試是否足夠、是否通過。
- 判斷是否有 Must Fix 或 Architecture Conflict。

## 6. Out of Scope

- 不新增 AI 自動互叫
- 不新增 Workflow Engine
- 不新增 Prompt Generator
- 不新增 Queue / Database
- 不改變 Manual Gate
- 不改變既有角色分工
- 不得修改程式碼（Codex 僅負責 Review）
- 不得 commit

## 7. Acceptance Criteria

- 產出 reviews/sprint-010/round-001/codex_review.md
- 明確標示 Gate Status、Must Fix、Architecture Conflict、Final Recommendation
- 未修改任何程式碼、未 commit

## 8. Copyable Prompt

請閱讀：

- PROJECT_BOOTSTRAP.md
- docs/development/consensus-workflow.md
- scripts/review_bridge.sh
- reviews/sprint-010/round-001/architecture.md
- reviews/sprint-010/round-001/claude_report.md

工作：

為 sprint-010 round-001 產生正式 Codex Review。

請完成以下工作：

1. 判斷是否符合 Architecture / Implementation Spec。
2. 判斷是否有 scope creep。
3. 判斷是否有 Architecture Conflict。
4. 判斷是否有 Must Fix。
5. 依 claude_report.md 描述的測試方式重新驗證測試。
6. 輸出：
   - Gate Status
   - Must Fix
   - Architecture Conflict
   - Final Recommendation

請覆寫：

reviews/sprint-010/round-001/codex_review.md

限制：

- 不修改 source code。
- 不 stage。
- 不 commit。
- 不 push。
- 只允許更新 reviews/sprint-010/round-001/codex_review.md。
