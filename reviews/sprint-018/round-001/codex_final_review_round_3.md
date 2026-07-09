# Codex Final Review Supplement — Sprint-018 Must Fix Round 3

## Summary

Must Fix Round 3 已修正前輪指出的文件一致性問題：`consensus-workflow.md` 已從 13/8 修正為 14/7，`product-owner-gate-operation-ux.md` 也已改為 14 個操作性 Gate，並明確區分 `claude_must_fix_approval`（Gate 6，Must Fix 開始前授權）與 `claude_must_fix_report_acceptance`（Gate 14，Claude Fix Report Ready 後的報告驗收 Gate）。

但本輪仍不能 PASS。新增的 `push-claude-report` 指令已具備可執行骨架、讀取真實 report、opt-in Telegram 送出、fake curl 測試與安全警告；然而它沒有把 Telegram spec 第 26.2 節要求的 16 項推播內容全部固定呈現。尤其缺少明確欄位化的 `Claude Report summary`、`Files changed`、`Tests run`、`Test result`、`Deviations / Risks / Not Done`。Test 35 也跳過了 35c-07 至 35c-10，未驗證這些必要欄位。

Final Review Result: REMAINING MUST FIX

Must Fix: Present

Final Recommendation: Do not proceed to Product Owner Telegram live validation until `push-claude-report` emits and tests all 16 required fields.

## Final Review Result

REMAINING MUST FIX

文件一致性 Must Fix 已解決，但「Claude Report Push to PO 實際可操作」尚未完整達到 Sprint-018 Round 3 要求。現在的 command 能送出一段 metadata 加完整 report 原文，但 Product Owner 在 Telegram 第一則訊息中仍看不到規格要求的 16 項固定欄位；而完整 report 原文是否含 Files changed / Tests run / Risks 等資訊，取決於 report 本身格式，不能替代推播內容契約。

## Context Completeness Check

- Full required reading list provided: PASS
- Missing context files: None
- Did missing context affect final review: NO
- Notes: 已閱讀 `PROJECT_BOOTSTRAP.md`、`docs/development/consensus-workflow.md`、`docs/development/telegram-po-gate-notification-specification.md`、`docs/development/product-owner-gate-operation-ux.md`、`scripts/review_bridge.sh`、`scripts/test_review_bridge.sh`、`reviews/sprint-018/round-001/architecture.md`、`gate_notification_matrix.md`、`codex_review_handoff_policy.md`、`claude_report.md`、`codex_review.md`、`claude_fix_report.md`、`codex_final_review.md`、`claude_fix_report_round_2.md`、`codex_final_review_round_2.md`、`claude_fix_report_round_3.md`。本次只驗證 Must Fix Round 3，未擴大 scope。

## Document Consistency Verification

PASS.

- PASS：`docs/development/consensus-workflow.md` 已寫 `14 of the 21 canonical Product Owner Gates`。
- PASS：同段已寫 `remaining 7 canonical Gates`。
- PASS：未再找到 `13 of the 21 canonical` 或 `remaining 8 canonical`。
- PASS：`docs/development/product-owner-gate-operation-ux.md` 已把「13 個操作性 Gate」改為「14 個操作性 Gate」。
- PASS：UX 文件第 5.5 節明確列出 `claude_implementation_report_acceptance`（Gate 4）與 `claude_must_fix_report_acceptance`（Gate 14）為 Claude Completion Gate。
- PASS：UX 文件明確排除 `claude_must_fix_approval`（Gate 6），並說明它是 Must Fix 開始前授權 Gate，不是 Fix Report Ready 後的完成報告驗收 Gate。

## Claude Report Push Command Review

REMAINING MUST FIX.

已符合項目：

- PASS：新增 CLI 形狀符合要求：`./scripts/review_bridge.sh push-claude-report <sprint-id> <round> <implementation|fix> [report-path]`。
- PASS：`implementation` 對應 `claude_implementation_report_acceptance`，預設讀 `claude_report.md`。
- PASS：`fix` 對應 `claude_must_fix_report_acceptance`，預設讀 `claude_fix_report.md`，也支援第 4 參數覆寫 round-specific report path。
- PASS：找不到 report artifact 時 fail loudly，不會產生空白或捏造推播。
- PASS：會產生 `reviews/<sprint>/round-<round>/notifications/claude-report-push-<gate_id>.md`。
- PASS：未設定 `NOTIFICATION_ENABLED=true` 時只寫本機 artifact，不會送 Telegram。
- PASS：只有 `NOTIFICATION_ENABLED=true` 且 `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` 存在時才嘗試 Telegram。
- PASS：fake curl 測試驗證 metadata 與 report 內容會送成至少 2 則訊息。
- PASS：程式明確提醒 Claude did not call Codex、Claude did not approve the Gate、Product Owner must manually decide。
- PASS：程式明確提醒 Claude Report 是 review input，不是 review authority，若送 Codex 必須附 `codex_review_handoff_policy.md` 的 canonical Codex Review 要求。
- PASS：未發現自動呼叫 Codex、自動 Gate approval、自動 commit、自動 push。

未符合項目：

- FAIL：固定 metadata block 沒有明確 `Claude Report summary` 欄位。
- FAIL：固定 metadata block 沒有明確 `Files changed` 欄位。
- FAIL：固定 metadata block 沒有明確 `Tests run` 欄位。
- FAIL：固定 metadata block 沒有明確 `Test result` 欄位。
- FAIL：固定 metadata block 沒有明確 `Deviations / Risks / Not Done` 欄位。
- FAIL：Test 35 的 fixture report 只有 `Summary` 與 marker，仍能通過，證明測試沒有驗證 16 項必要欄位完整性。

`📄 Claude Report Content（逐字引用）` 是必要 evidence，但不能取代 Telegram spec 第 26.2 節要求的 Product Owner 可讀推播摘要欄位。這些欄位應在第一則 metadata / summary message 中固定呈現，即使無法解析也應明確顯示 `Not found in report` / `Not stated`，而不是靠 Product Owner 自行在完整 report 內搜尋。

## Telegram Safety Boundary Review

PASS.

- PASS：`push-claude-report` 是 dispatcher command，未被其他函式自動呼叫。
- PASS：沒有修改 `cmd_notify()`。
- PASS：沒有修改 `cmd_notify_gate()`。
- PASS：沒有修改 Sprint-017 handoff mode 三訊息模型。
- PASS：沒有修改 section-aware split、copy boundary extraction、Next AI Handoff fail-loudly behavior。
- PASS：`scripts/review_bridge.sh` diff 為純新增：`210 insertions, 0 deletions`。
- PASS：`configs/n8n/*.json` 無 diff。
- PASS：本次 Codex 未執行 Telegram live delivery。

注意：`push-claude-report` 是新的 Telegram-bound command；雖然不會改壞既有 `notify-gate` 三訊息模型，但它本身仍需要補齊第 26.2 節的固定內容契約後，才適合進行 Product Owner live validation。

## Test Verification

Executed:

```bash
bash scripts/test_review_bridge.sh
```

Result reproduced:

```text
Results: 620 passed, 0 failed
```

可信部分：

- PASS：既有 Test 1–34 未回退。
- PASS：Test 34 新增 regression checks，攔截 13/8 舊文字與 Gate 6/Gate 14 語意混淆。
- PASS：Test 35 驗證 command usage、缺檔 fail loudly、無效 report type fail loudly、path override、fake curl delivery、REVIEWS_OVERRIDE 隔離 history、n8n 無 diff。
- PASS：測試未觸發真實 Telegram，未增加真實 `reviews/notification_history.jsonl`。

不足部分：

- FAIL：Test 35 未驗證 16 項必要欄位中的第 6–10 項。
- FAIL：Test 35 的斷言從 `35c-06` 直接跳到 `35c-11`，漏掉 `Claude Report summary`、`Files changed`、`Tests run`、`Test result`、`Deviations / Risks / Not Done`。
- FAIL：fake curl 只驗證「至少 2 則訊息」與 report marker 存在，未驗證 Telegram 第一則訊息是否含完整 16 項 Product Owner 可讀內容。

因此 `620 passed, 0 failed` 可重現，但不足以支撐「push-claude-report 已完整符合 16 項推播內容規則」。

## Scope / Git / Evidence Check

PASS for safety boundaries, with expected Sprint dirty state.

確認本輪相關變更：

- `docs/development/consensus-workflow.md`: modified。
- `docs/development/product-owner-gate-operation-ux.md`: untracked Sprint-018 doc artifact，目前內容已是 Version 1.2。
- `scripts/review_bridge.sh`: modified，diff 為純新增 command。
- `scripts/test_review_bridge.sh`: modified。

確認未修改：

- `configs/n8n/*.json`: no diff。

確認未執行：

- 未 commit。
- 未 push。
- 未自動呼叫 Codex。
- 未自動核准 Gate。
- 未觸發 Telegram live delivery。
- 未要求 Product Owner 提供 Telegram token 給 Codex。

Runtime evidence:

- `reviews/notification_history.jsonl` 目前仍是 untracked runtime evidence，後續 Git Review / commit scope 必須排除。
- 本次測試使用 `REVIEWS_OVERRIDE` 與 fake curl，未增加真實 repository 的 notification history。
- 本次 Codex Review 只新增本 review report，未修改 implementation 檔案。

## Remaining Must Fix

1. 補齊 `push-claude-report` 的 16 項固定推播內容欄位。

   第一則 Product Owner 可讀訊息至少必須固定呈現 Telegram spec 第 26.2 節的 16 項：Sprint ID、Round ID、Current Gate、Completed actor、Completed artifact path、Claude Report summary、Files changed、Tests run、Test result、Deviations / Risks / Not Done、Product Owner Action Required、Product Owner Decision Options、Suggested next actor、Safety warning、Codex review instruction source、Copy guidance。

2. 強化 Test 35，逐項驗證 16 項必要欄位。

   Test 35 應補上目前缺失的 `35c-06` 到 `35c-10` 類斷言，且 fixture report 應包含可辨識的 Files changed / Tests run / Test result / Deviations / Risks / Not Done 內容，確認 command 真的把它們呈現在推播 summary 裡。也應驗證 fake Telegram Message 1 含完整 16 項，而不只是 on-disk artifact 含 marker。

3. 若無法可靠解析 report section，也必須 fail loudly 或顯示明確 fallback。

   可接受的簡單 MVP 做法是：從 report 內常見 heading 擷取內容；若找不到，固定欄位顯示 `Not found in report`。不可完全省略欄位，也不可只附完整 report 原文後宣稱已包含 16 項。

## Remaining Should Fix

1. 降低 `push-claude-report` 與 Matrix 的 decision options drift 風險。

   現在 `po_decision_options` 在 shell case statement 中硬編碼，與 `gate_notification_matrix.md` 分開維護。短期可接受，但後續應至少用測試比對 Gate 4 / Gate 14 的 Decision options 與 command 輸出一致，避免文件與 runtime 漂移。

2. Product Owner Telegram live validation 可在 Remaining Must Fix 解完後進行。

   目前未執行 live delivery 是可接受的安全狀態，不是單獨的 Must Fix；但因 command 內容契約尚未完整，不建議現在就進入 live validation。修完 16 欄位後，Product Owner 可在已配置真實 Telegram credentials 的環境手動執行，不需要把 token 提供給 Codex。

## Nit

1. `docs/development/telegram-po-gate-notification-specification.md` 第 26.3 節仍引用 `product-owner-gate-operation-ux.md` 第 6 節；UX 文件 Round 3 已改為第 5 節。

2. `codex_review_handoff_policy.md` 第 6.1 節也仍引用 UX 第 6 節；應同步改為第 5 節。

3. `gate_notification_matrix.md` 第 2 節仍寫「完整規則見 `product-owner-gate-operation-ux.md` 第 6 節」，同樣應同步改為第 5 節。

## Product Owner Next Action

請不要進入 Product Owner Telegram live validation。請要求 Claude Code 做一個小範圍 Must Fix Round 4：

1. 讓 `push-claude-report` 第一則訊息固定輸出 Telegram spec 第 26.2 節的 16 項必要欄位。
2. 補強 Test 35，逐項驗證 16 欄位，特別是目前漏掉的 `Claude Report summary`、`Files changed`、`Tests run`、`Test result`、`Deviations / Risks / Not Done`。
3. 重新執行 `bash scripts/test_review_bridge.sh` 並回報新結果。

本輪 Review 未 commit、未 push、未修改 implementation 檔案、未觸發 Telegram live delivery、未自動呼叫 Claude / Codex。
