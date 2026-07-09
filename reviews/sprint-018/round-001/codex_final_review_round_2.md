# Codex Final Review Supplement — Sprint-018 Must Fix Round 2

## Summary

Sprint-018 Must Fix Round 2 的核心調整大致正確落地：`gate_notification_matrix.md` 已從 13 個操作性 Gate 擴充為 14 個，新增 `claude_must_fix_report_acceptance` 作為「Claude Fix Report Ready」後的驗收 Gate；Gate 4 與 Gate 14 都補上 Claude Report Push to PO 的 6 個欄位；`telegram-po-gate-notification-specification.md` 與 `codex_review_handoff_policy.md` 也明確保留「Claude Report 是 input，不是 Codex Review authority」的安全邊界。

但本輪仍有 Remaining Must Fix：`docs/development/consensus-workflow.md` 仍寫「13 of the 21 canonical Product Owner Gates / remaining 8」，而 `docs/development/product-owner-gate-operation-ux.md` 仍在操作入口中寫「13 個操作性 Gate」，且第 6.4 節把 Fix Report Ready 情境指向 `claude_must_fix_approval` / Gate 6。這與 Round 2 已確認的 Gate 14 語意矛盾，會讓 Product Owner Validation 時不知道應以 Gate 6 還是 Gate 14 作為 Claude Fix Report Ready 的正式通知點。

Final Review Result: REMAINING MUST FIX

Must Fix: Present

Final Recommendation: Do not proceed to Product Owner Validation until the stale 13-Gate / Gate-6 references are corrected.

## Final Review Result

REMAINING MUST FIX

原因：Round 2 的 Matrix / Telegram spec / handoff policy 已補齊主要契約，但正式 workflow SSOT 與 Product Owner 操作入口仍保留與 Gate 14 相衝突的文字。這不是單純 Nit，因為 Sprint-018 的交付目標正是 Product Owner Gate Operation UX；操作入口若仍把 Fix Report Ready 寫成 Gate 6，會阻擋可靠的 Product Owner Validation。

## Context Completeness Check

- Full required reading list provided: PASS
- Missing context files: None
- Did missing context affect final review: NO
- Notes: 已閱讀 `PROJECT_BOOTSTRAP.md`、`docs/development/consensus-workflow.md`、`docs/development/telegram-po-gate-notification-specification.md`、`docs/development/product-owner-gate-operation-ux.md`、`scripts/review_bridge.sh`、`scripts/test_review_bridge.sh`、`reviews/sprint-018/round-001/architecture.md`、`claude_report.md`、`gate_notification_matrix.md`、`codex_review_handoff_policy.md`、`codex_review.md`、`claude_fix_report.md`、`codex_final_review.md`、`claude_fix_report_round_2.md`。本次只審查 Must Fix Round 2 的流程調整，未擴大 implementation scope。

## Must Fix Round 2 Verification

PASS with Remaining Must Fix on stale workflow/UX wording.

已正確落地：

- PASS：Claude Report Push to PO 已文件化於 `product-owner-gate-operation-ux.md` 第 6 節與 Telegram spec 第 26 節。
- PASS：文件明確區分 Claude Report Push to PO 不等於 Formal Codex Review Approval、不等於 Auto Handoff to Codex、不等於 Auto Gate Approval。
- PASS：Gate 4 `claude_implementation_report_acceptance` 已補上 `Claude report push to PO: YES`、`PO review required: YES`、`PO manually sends to Codex: YES`、`Auto send to Codex: NO`、`Codex review checklist authority: canonical template / codex_review_handoff_policy.md`。
- PASS：Gate 14 `claude_must_fix_report_acceptance` 已新增，並補上同一組 Claude Completion Gate 欄位。
- PASS：`gate_notification_matrix.md` 清楚記錄 Round 1 為 13 Gate、Round 2 依 Product Owner 指示新增第 14 Gate，且其餘 canonical Gate 變為 7 個未列入矩陣。
- PASS：安全邊界仍保留：Claude 不得自動呼叫 Codex、不得自動核准 Gate、不得自動決定 Codex Review scope/checklist，Product Owner 必須手動審核後再決定是否送 Codex。

未完整落地：

- FAIL：`consensus-workflow.md` 仍寫 13 / 8，與最新 Matrix 14 / 7 矛盾。
- FAIL：`product-owner-gate-operation-ux.md` 的文件關係與 Content Mode 說明仍寫 13 個操作性 Gate。
- FAIL：`product-owner-gate-operation-ux.md` 第 6.4 節仍把 Fix Report Ready 情境描述成 `claude_must_fix_approval` / Gate 6；最新 Matrix 已明確說 Gate 6 是 Must Fix 開始前授權，Fix Report Ready 應由 Gate 14 `claude_must_fix_report_acceptance` 承接。

## Gate 14 Addition Review

PASS.

新增 Gate 14 合理且必要。`claude_must_fix_approval` 是 Must Fix 開始前的執行授權 Gate；它不能代表「Claude Fix Report 已完成，等待 Product Owner 審核並決定是否送 Codex Final Review」的 post-fix checkpoint。`claude_must_fix_report_acceptance` 才是與 Gate 4 `claude_implementation_report_acceptance` 對稱的 Claude Completion Gate。

Gate 14 欄位完整性：

- Gate ID: present
- Gate name: present
- Notification purpose: present
- Product Owner action required: present
- Decision options: present
- Recommended next step: present
- Required Reading: present
- Evidence reference: present
- 是否需要 Next AI Handoff Package: present
- Target AI: Codex
- copy boundary: `BEGIN/END COPY TO CODEX`
- notify-gate command requirement: present
- stop condition: present
- Telegram content mode: `handoff`
- Claude Report Push to PO 6 個欄位: present and correctly valued

## Claude Report Push to PO Flow Review

PASS with Remaining Must Fix on the Product Owner UX entrypoint.

正確部分：

- Claude Completion Gate 的 Telegram 推播被定義為通知 Product Owner 報告已完成。
- Product Owner 必須審核報告。
- Product Owner 手動把報告內容與 canonical Codex Review 要求貼給 Codex。
- Auto send to Codex 明確為 NO。
- Claude / Codex 仍不得自動觸發 Telegram。
- 送出通知不代表 Gate approval，也不代表 Codex Review 已開始或已核准。

缺口：

- UX 文件仍在適用 Gate 區段使用 Gate 6 語意描述 Fix Report Ready。這會讓 Product Owner 可能對錯 Gate 執行通知或手動交接，必須修正為 Gate 14。

## Codex Review Handoff Authority Review

PASS.

`codex_review_handoff_policy.md` 第 6 節已明確規定：

- Claude Report 是 review input，不是 review authority。
- Product Owner 貼給 Codex 時必須同時附上 canonical Codex Review 要求。
- Codex 必須獨立檢查 Architecture、git diff、git status、tests、scope、runtime evidence。
- Codex 不得只依 Claude Report 做結論。

這符合 Independent Review Handoff Authority；Claude Report Push to PO 沒有削弱 Codex Review 的獨立性。

## Test Verification

Executed:

```bash
bash scripts/test_review_bridge.sh
```

Result reproduced:

```text
Results: 580 passed, 0 failed
```

Test 33 verification:

- PASS：`SPRINT18_GATES` 已擴充為 14 個 Gate。
- PASS：Test 33 對 14 Gate x 14 欄位做逐 Gate 驗證。
- PASS：需要 handoff 的 Gate 會驗證 Target AI 非 N/A、copy boundary 包含 `BEGIN COPY TO`。
- PASS：不需要 handoff 的 Gate 會驗證 Target AI / copy boundary 為 N/A / 不適用。

Test 34 verification:

- PASS：Test 34 對 Gate 4 與 Gate 14 驗證 Claude Report Push to PO 的 6 個欄位。
- PASS：Test 34 驗證 `YES / NO` 值與 `codex_review_handoff_policy.md` authority reference。
- PASS：Test 34 驗證 policy 中「Claude Report 是 input，不是 authority」與「PO 必須附 canonical requirements」。
- PASS：Test 34 驗證 UX doc 有 Claude Report Push to PO 與 non-equivalence wording。

Test coverage gap:

- Test 33 / 34 沒有攔截 `consensus-workflow.md` 仍寫 13 / 8。
- Test 34 沒有攔截 `product-owner-gate-operation-ux.md` 仍把 Fix Report Ready 指向 Gate 6，而不是 Gate 14。

因此 `580 passed, 0 failed` 是可重現且可信的 contract regression suite 結果，但不足以證明所有 Round 2 user-facing workflow wording 都已同步。

## Scope / Git / Evidence Check

PASS for safety boundaries.

確認未修改 / 未觸碰：

- `scripts/review_bridge.sh`: no tracked diff。
- `configs/n8n/*.json`: no diff。
- `reviews/sprint-018/round-001/architecture.md`: 未出現 tracked diff；目前為 untracked Sprint artifact，保留 Round 1 歷史決策紀錄合理。

確認未執行：

- 未執行 `notify-gate` live delivery。
- 未觸發 Telegram live delivery。
- 未自動呼叫 Claude。
- 未自動呼叫 Codex。
- 未 commit。
- 未 push。
- 未 stage 檔案。

工作樹注意事項：

- 目前工作樹仍有多個 unrelated dirty / untracked files，包含既有文件修改、舊 Sprint artifacts、`reviews/notification_history.jsonl` runtime evidence、以及整個 `reviews/sprint-018/` untracked 目錄。
- 本次 Review 未清理、未 revert、未 stage unrelated dirty / untracked files。
- `reviews/notification_history.jsonl` 仍是 untracked runtime evidence，後續 Git Review / commit scope 必須排除。

## Remaining Must Fix

1. 修正 `docs/development/consensus-workflow.md` 的 Sprint-018 段落。

   目前仍寫 `13 of the 21 canonical Product Owner Gates` 與 `remaining 8`。應更新為 14 / 7，並可簡短註明 Round 2 新增 `claude_must_fix_report_acceptance` 作為 Claude Fix Report Ready 的操作性 Gate。

2. 修正 `docs/development/product-owner-gate-operation-ux.md` 的 13 Gate 舊文字。

   第 1 節與第 3 節仍寫「13 個操作性 Gate」，應更新為 14 個操作性 Gate，與 Matrix / Telegram spec 一致。

3. 修正 `docs/development/product-owner-gate-operation-ux.md` 第 6.4 節的 Gate 6 語意。

   Fix Report Ready 情境應明確指向 `claude_must_fix_report_acceptance` / Gate 14，不應再寫 `claude_must_fix_approval` / Gate 6。Gate 6 是 Must Fix 開始前授權，不是 Fix Report 完成後驗收。

4. 補一個針對 stale wording 的 regression check。

   建議放在 Test 34：驗證 `consensus-workflow.md` / UX doc 不再含 Sprint-018 13-Gate 舊描述，並驗證 UX doc 的 Fix Report Ready 適用 Gate 包含 `claude_must_fix_report_acceptance`，不得把 `claude_must_fix_approval` 當成 Claude Completion Gate。

## Remaining Should Fix

1. 補 Gate 4 / Gate 14 的具體 `notify-gate` 範例 command。

   這項因 Round 2 調整而重要性提高，但仍可列 Should Fix，不升級 Must Fix。原因是 Matrix 已有 `notify-gate command requirement`，Telegram spec 也有通用 CLI 格式；缺少的是可直接照抄的 UX 範例，不是安全邊界或 Gate authority 缺失。原先稱為 Gate 6 的範例應改稱 Gate 14。

2. 後續 Product Owner Validation 應做 Telegram live validation。

   `bash scripts/test_review_bridge.sh` 是 contract validation，不等於 live delivery。Product Owner 應手動執行對應 `notify-gate` command，確認 Telegram 實際收到，並把 live delivery evidence 與 contract test result 分開記錄。

## Nit

1. `scripts/test_review_bridge.sh` Test 33 的註解仍有幾處寫「13 selected gates」或「all 13 gates」，實際陣列已是 14。測試邏輯正確，註解應後續同步。

2. `docs/development/product-owner-gate-operation-ux.md` 章節編號從第 4 節跳到第 6 節，缺第 5 節。這不影響流程正確性，但可在修正文案時一併整理。

## Product Owner Next Action

請不要進入 Product Owner Validation。請要求 Claude Code 做一個小範圍 Must Fix Round 3：

1. 只修正 `consensus-workflow.md` 與 `product-owner-gate-operation-ux.md` 的 13 / Gate 6 舊文字。
2. 補 Test 34 regression check，避免 Gate 14 流程再次被舊 Gate 6 描述覆蓋。
3. 重新執行 `bash scripts/test_review_bridge.sh`，回報新的 passed / failed 結果。

本輪 Review 未 commit、未 push、未觸發 Telegram、未呼叫 Claude / Codex。
