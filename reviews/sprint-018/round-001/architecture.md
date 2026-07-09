# Sprint-018 Architecture — Product Owner Gate Operation UX MVP

## 0. Provenance Note

此 Architecture 內容來源為 Product Owner 已核准的 Sprint-018 決策，由 Product Owner 直接於 Claude Code Implementation Handoff Package 中提供。這不是 Claude Code 自行設計的 Architecture；Claude Code 只負責依此進行 Implementation。

**重要揭露（實作填補，非 Architecture 決策）**：Handoff Package 提到「13 個 Gate 的 Gate Notification Matrix」，但未列出具體是哪 13 個 gate_id。經向 Product Owner 確認，由 Claude Code 從現有 21 個 canonical Gate（`docs/development/product-owner-gate-metadata.md`）中挑選 13 個最具「操作性」的 Gate，選擇標準與結果記錄於本文件第 3 節，供 Product Owner 之後審閱、確認或調整。

## 1. Sprint Goal

把 Sprint-017 已完成的 Telegram / Handoff 能力，正式套用到未來開發流程中，讓所有需要 Product Owner 介入的 Gate 都能收到足夠、便利、可操作的通知；同時建立 Independent Review Handoff Authority 與 Review Bridge Self-Modification Safety Rule 兩項治理規則。

## 2. In Scope

1. 更新或建立 Product Owner Gate Operation UX 文件。
2. 建立 13 個 Gate 的 Gate Notification Matrix。
3. 每個 Gate 定義 14 項欄位（見第 3 節選擇結果與 `gate_notification_matrix.md`）。
4. 將 Telegram / Handoff 正式納入未來開發流程文件（`docs/development/consensus-workflow.md`）。
5. 落地 Independent Review Handoff Authority：Claude Implementation Report 可作為 Codex Review Handoff 的 input，但 Claude 不得單獨決定 Codex Review 的 scope/checklist/Required Reading/forbidden actions；Codex Review Handoff 必須由 approved canonical template / Review Bridge 組成。
6. 落地 Review Bridge Self-Modification Safety Rule：若某 Sprint 修改 Review Bridge / Handoff Template / notify-gate / Telegram renderer / copy boundary generation，該輪 Codex Review 不得只依賴新修改後的 Review Bridge 輸出，必須直接檢查 Architecture、fixed checklist、source diff、test evidence。
7. 更新必要測試。
8. 產生 Claude Implementation Report。

## 3. 13 個 Gate 的挑選標準與結果（實作填補）

**挑選標準**：保留「PO 需要實際評估、判斷、或授權重大新階段工作」的 Gate；排除「機械式的『請開始檢查』前置授權」（這類 Gate 通常緊跟在上一個 Gate 的決策之後、幾乎不需要獨立判斷）與近乎自動確認的中介 Gate。具體保留：(a) 授權重大新工作階段的 Gate、(b) 所有「result_decision」分支判斷 Gate、(c) 2 個高風險 Commit/Push Gate、(d) 2 個終局治理 Gate。

**結果（13 個）**：

```text
sprint_start_approval
architecture_definition_approval
claude_implementation_approval
claude_implementation_report_acceptance
codex_review_result_decision
claude_must_fix_approval
codex_final_review_result_decision
product_owner_validation_approval
codex_git_review_result_decision
commit_approval
push_approval
retrospective_content_approval
product_owner_closure_approval
```

**排除（8 個，仍存在於 21-Gate canonical whitelist，未從系統移除，只是不列入本 Sprint 的操作性 Matrix）**：`architecture_artifact_approval`、`codex_review_approval`、`claude_must_fix_report_acceptance`、`codex_final_review_approval`、`codex_git_review_approval`、`codex_commit_approval`、`codex_push_approval`、`retrospective_entry_approval`。

## 4. Allowed Files

```text
docs/development/consensus-workflow.md
docs/development/telegram-po-gate-notification-specification.md
scripts/review_bridge.sh
scripts/test_review_bridge.sh
reviews/sprint-018/round-001/architecture.md
reviews/sprint-018/round-001/claude_report.md
reviews/sprint-018/round-001/gate_notification_matrix.md
reviews/sprint-018/round-001/codex_review_handoff_policy.md
docs/development/product-owner-gate-operation-ux.md（如新增，須在 claude_report.md 說明原因）
```

## 5. Prohibited Files / 禁止事項

```text
configs/n8n/*.json
```

不得自動觸發 Telegram、不得自動呼叫 Codex、不得 commit、不得 push、不得回頭修改 Sprint-017、不得順手處理 unrelated dirty/untracked files、不得讓 Claude Report 成為 Codex Review Handoff 的唯一來源。

## 6. Definition of Done

1. `gate_notification_matrix.md` 涵蓋全部 13 個 Gate，每個 Gate 14 項欄位齊全。
2. `codex_review_handoff_policy.md` 落地 Independent Review Handoff Authority 與 Self-Modification Safety Rule，涵蓋全部 16 項測試要求對應內容。
3. `docs/development/consensus-workflow.md` 正式引用 Telegram/Handoff 能力與兩項新治理規則。
4. 若本 Sprint 未修改 Review Bridge 程式碼，須在報告中明確聲明「未修改，不需要 full regression test」以外，仍執行既有測試確保零迴歸；若有新增測試，須全數通過。
5. 未修改 Prohibited Files、未 `git add`/`commit`/`push`、未觸發 Telegram、未回頭修改 Sprint-017。
