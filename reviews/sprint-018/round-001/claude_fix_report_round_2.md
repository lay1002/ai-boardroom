# Claude Fix Report — Sprint-018 Must Fix Round 2

## 1. Summary

依 Product Owner 直接指示（非 Codex Review 發現），把「Claude Code 完成 Implementation / Fix 後如何讓 Product Owner 知道」這件事正式流程化：新增「Claude Report Push to PO」通知類別，明確規定 Claude Report 完成後應推播給 Product Owner，Product Owner 審核後再手動把報告內容與 Codex Review 要求貼給 Codex，全程不引入 AI Auto Loop、不自動呼叫 Codex、不自動核准 Gate。實作過程中發現「Gate 6」的語意指認落差（詳見第 4 節），已依 Product Owner 澄清後的指示解決：把 `claude_must_fix_report_acceptance` 加回 Gate Notification Matrix，矩陣從 13 個 Gate 擴充為 14 個。

## 2. Context Completeness Check

- Full required reading list provided: PASS
- Missing context files: None
- Did missing context affect implementation or review: NO
- Notes: 13 份必讀文件全部存在並已閱讀（`PROJECT_BOOTSTRAP.md`、`docs/development/consensus-workflow.md`、`docs/development/telegram-po-gate-notification-specification.md`、`docs/development/product-owner-gate-operation-ux.md`、`scripts/review_bridge.sh`、`scripts/test_review_bridge.sh`、`reviews/sprint-018/round-001/architecture.md`、`claude_report.md`、`gate_notification_matrix.md`、`codex_review_handoff_policy.md`、`codex_review.md`、`claude_fix_report.md`、`codex_final_review.md`）。

## 3. Required Reading Completion

13 份必讀文件皆存在且已閱讀，未縮減必讀清單。

## 4. Must Fix Round 2 Item Addressed

### 4.1 核心目標

把 Sprint-018 流程修正為：Claude Code 完成後，把 Claude Report 推播給 Product Owner；Product Owner 審核後，再手動把報告內容與 Codex Review 要求貼給 Codex。已透過以下 4 份文件 + 測試落地。

### 4.2 執行中發現並解決的落差：Gate 6 語意不一致（Gate Notification Matrix 從 13 個 Gate 擴充為 14 個）

Handoff Package 指示「Gate 6：Claude Fix Report Ready」應補上 Claude Report Push to PO 欄位，但矩陣原本的「Gate 6」（3.6 節 `claude_must_fix_approval`）語意是「Must Fix **開始前**的執行授權」，不是「Fix Report **完成後**的驗收」。經向 Product Owner 提出澄清問題，Product Owner 明確指示：

1. 「Gate 6：Claude Fix Report Ready」對應到 `claude_must_fix_report_acceptance`（原本在 Sprint-018 Round 1 被排除在 13-Gate 矩陣之外的 canonical Gate）。
2. 把 `claude_must_fix_report_acceptance` 加回矩陣，成為第 14 個 Gate。
3. 這是 Product Owner 對 Sprint-018 流程語意的直接修正指示，不是 Claude Code 自行擴大 scope。

已依此指示執行：`gate_notification_matrix.md` 新增 3.7 節 `claude_must_fix_report_acceptance`（Claude Completion Gate），原本 3.7–3.13 節（`codex_final_review_result_decision` 至 `product_owner_closure_approval`）依序重新編號為 3.8–3.14。**`reviews/sprint-018/round-001/architecture.md`（Round 1 的核准決策紀錄）本身未修改**，保留原始 13-Gate 決策的歷史軌跡；`gate_notification_matrix.md` 新增第 0 節「Round 2 變更說明」，完整記錄擴充原因與依據，避免未來閱讀矩陣時誤以為 14-Gate 是 Round 1 原始決策。

## 5. Flow Change Implemented

```text
Claude Code 完成 Implementation / Fix
  ↓
Claude Code 產生 Implementation Report / Fix Report
  ↓
（Product Owner 手動執行 notify-gate）
Claude Report 推播給 Product Owner（Claude Report Push to PO —— 純通知，不等於核准、不等於轉交）
  ↓
Product Owner 審核報告
  ↓
Product Owner 手動把報告內容 + canonical Codex Review 要求（codex_review_handoff_policy.md）貼給 Codex
  ↓
Codex 進行獨立 Review
```

適用 Gate（Claude Completion Gate）：`claude_implementation_report_acceptance`（Gate 4）、`claude_must_fix_report_acceptance`（Gate 14，Round 2 新增）。

**安全邊界維持不變**（逐項確認）：

1. Claude 不得自動呼叫 Codex——本輪未新增任何自動呼叫 Codex 的程式碼或流程；`scripts/review_bridge.sh` 未修改。
2. Claude 不得自動核准 Gate——`Claude report push to PO` 明確定義為「純通知」，`docs/development/product-owner-gate-operation-ux.md` 第 6.3 節與 `telegram-po-gate-notification-specification.md` 第 26.3 節都明確寫「不代表任何 Gate 已核准」。
3. Claude 不得自動決定 Codex Review scope——`codex_review_handoff_policy.md` 第 6.2 節重申 Claude Report 是 input 不是 authority。
4. Claude 不得自動決定 Codex Review checklist——Gate 4 / Gate 14 的 `Codex review checklist authority` 欄位固定指向 `codex_review_handoff_policy.md`，不是 Claude Report 自訂。
5. Claude 不得自動 commit / 6. push——本輪未執行任何 git 寫入操作。
7. Product Owner 必須手動審核 Claude Report——`PO review required：YES` 明確寫入 Gate 4 / Gate 14 欄位。
8. Product Owner 必須手動決定是否送 Codex Review——`PO manually sends to Codex：YES`、`Auto send to Codex：NO` 明確寫入。
9. Codex Review 仍須依固定 checklist、Architecture、git diff、git status、tests、scope、runtime evidence 獨立審查——`codex_review_handoff_policy.md` 第 2、3、6 節皆重申此點，本輪未削弱。

## 6. Files Changed

```text
docs/development/product-owner-gate-operation-ux.md                — 新增第 6 節 Claude Report Push to PO（用途、明確區分、完整流程）
reviews/sprint-018/round-001/gate_notification_matrix.md           — 新增第 0 節 Round 2 變更說明；新增 3.7 節 claude_must_fix_report_acceptance（第 14 個 Gate）；Gate 4 補上 6 個 Claude Report Push to PO 欄位；重新編號 3.7–3.13 為 3.8–3.14；更新 Section 1/2/4/5 的 13→14 Gate 措辭；Summary Table 新增 copy boundary 與 Claude report push to PO 欄位
docs/development/telegram-po-gate-notification-specification.md    — 新增第 26 節 Claude Report Push to Product Owner（16 項推播內容規則、明確區分、Codex Review 指令來源）；第 25 節措辭更新為 14 Gate
reviews/sprint-018/round-001/codex_review_handoff_policy.md        — 新增第 6 節：Claude Report Push to PO 之後 PO 手動送 Codex 的規則；同時補上前輪 Codex Review Should Fix 2 建議的「只修改測試檔不算 Self-Modification」說明（見第 6.3 節）
scripts/test_review_bridge.sh                                       — SPRINT18_GATES 陣列新增 claude_must_fix_report_acceptance（13→14）；SPRINT18_HANDOFF_GATES 同步新增；新增 Test 34（34 項斷言，驗證 Claude Report Push to PO 的 6 個欄位、Telegram 規格章節、Policy 文件規則）
```

**未修改**：`scripts/review_bridge.sh`（本輪不涉及任何 notify-gate 執行邏輯變更，Claude Report Push to PO 沿用既有 `notify-gate` 基礎設施，由 Product Owner 手動組出對應的 `summary_path`/`artifact_path` 呼叫）、`reviews/sprint-018/round-001/architecture.md`（保留 Round 1 原始決策紀錄，不回頭改寫）。

## 7. Test Changes

1. `SPRINT18_GATES` 陣列從 13 個 gate_id 擴充為 14 個，新增 `claude_must_fix_report_acceptance`；相應斷言描述從「exactly 13 gates」改為「exactly 14 gates (13 from Round 1 + 1 added in Round 2)」。
2. `SPRINT18_HANDOFF_GATES` 同步新增 `claude_must_fix_report_acceptance`（因為它是需要 Handoff 的 Gate，Target AI=Codex）。
3. Test 33 原本的「182 項逐 Gate 逐欄位」註解更新為「196 項」（14 Gate × 14 欄位），實際迴圈邏輯不變（本來就是走 `SPRINT18_GATES` 陣列，陣列變長後自動涵蓋新 Gate）。
4. 新增 Test 34（34 項斷言）：`SPRINT18_CLAUDE_COMPLETION_GATES` 陣列列出 2 個 Claude Completion Gate；`SPRINT18_PUSH_TO_PO_FIELDS` 列出 6 個新欄位；逐 Gate 驗證欄位存在（34a，12 項）+ 逐 Gate 驗證欄位值正確（34b–34f，10 項）+ Telegram 規格章節存在（34g）+ Policy 文件 2 項規則存在（34h/34i）+ UX 文件 3 項內容存在（34j-1/2/3）+ 真實 notification_history.jsonl 未受影響（34k）+ n8n 未變（34l）。

## 8. Tests Run

```bash
bash scripts/test_review_bridge.sh
```

連續執行 3 次確認結果穩定。

## 9. Test Result

```text
Results: 580 passed, 0 failed
```

（536（Sprint-018 Round 1 Final Review 時）+ Test 33 因 SPRINT18_GATES 從 13→14 自動增加 14 項（14 欄位 × 1 個新 Gate）+ 33j/33n-33o/33f-33g 因新 Gate 加入而各增加對應項目 + 新增 Test 34 共 34 項 = 580，零失敗，連續 3 次執行結果一致。）

## 10. Deviations

1. Gate Notification Matrix 從 13 個 Gate 擴充為 14 個 Gate——已在第 4.2 節完整說明原因，這是 Product Owner 對「Gate 6」語意的直接澄清指示，不是 Claude Code 自行擴大 scope。已在 `gate_notification_matrix.md` 新增第 0 節記錄此決策軌跡，`architecture.md`（Round 1 決策記錄）本身未回頭修改。
2. 實作過程中因「Gate 4 / Gate 6」編號與矩陣實際章節編號的語意落差，在動手修改矩陣前先以 `AskUserQuestion` 向 Product Owner 提出澄清問題，取得明確指示後才執行——這是遵循「資訊不足時先詢問，不自行假設」的原則，非流程delay。

## 11. Risks

1. Gate Notification Matrix 現在是 14 個 Gate，若之後 ChatGPT／Product Owner 在其他文件中仍以「13 個 Gate」描述 Sprint-018 成果，需要留意用詞是否已過期——本輪已同步更新 `telegram-po-gate-notification-specification.md`、`product-owner-gate-operation-ux.md` 的措辭，但 `docs/development/consensus-workflow.md` 先前 Round 1 新增的段落（Product Owner Gate Operation UX 一節）仍寫「13 個」，本輪未修改該檔案（不在本輪要求的更新清單內），可能需要下一輪一併同步。
2. `codex_review_handoff_policy.md` 第 6 節的規則是「治理文件層級」的約束，實際是否被遵守（Product Owner 貼給 Codex 時是否真的附上 canonical checklist）仍依賴人工執行，無法用自動化測試驗證「Product Owner 真的這樣做了」，只能驗證「文件確實這樣規定」。

## 12. Not Done

1. 未更新 `docs/development/consensus-workflow.md` 中 Round 1 提到「13 個 Gate」的既有段落（見上方 Risk 1）——本輪 Handoff Package 未列出此檔案為本輪更新目標，故未觸碰，避免擴大 scope。
2. 未執行任何 `notify-gate`（包含 Claude Report Push to PO 情境）以驗證真實 Telegram live delivery——僅在隔離暫存環境測試過欄位定義與文件內容；真實 live delivery 驗證需要 Product Owner 依 `codex_final_review.md` 的 Product Owner Next Action 指示自行執行。
3. Sprint-018 Round 1 Codex Final Review 的 2 項 Remaining Should Fix（Gate 4/Gate 6 具體 notify-gate 範例 command、policy 文件補充說明）：第 2 項已在本輪第 6.3 節順便補上；第 1 項（具體範例 command）仍未處理，留待後續輪次或 Product Owner Validation 階段。

## 13. Product Owner Next Action

1. 審閱 Gate Notification Matrix 從 13→14 Gate 的擴充是否符合預期。
2. 審閱「Claude Report Push to PO」流程的 4 份文件更新內容。
3. 決定是否要求同步更新 `docs/development/consensus-workflow.md` 中過期的「13 個 Gate」措辭（見 Risk 1，本輪未處理）。
4. 決定是否授權重新送交 Codex 進行 Review（正式的 Codex Review Handoff 指令依 Independent Review Handoff Authority 原則，不得由本報告單獨決定，須依 `codex_review_handoff_policy.md` 準備，並依本輪新增的第 6 節規則，附上 canonical review 要求）。
