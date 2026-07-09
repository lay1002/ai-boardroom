# Claude Fix Report — Sprint-018 Must Fix Round 4

## 1. Summary

依 `codex_final_review_round_3.md` 的 REMAINING MUST FIX 結論，修正 `push-claude-report` 指令，使其第一則 Telegram 訊息固定輸出 Telegram spec 第 26.2 節要求的全部 16 項欄位（先前版本缺少 Claude Report summary、Files changed、Tests run、Test result、Deviations/Risks/Not Done 共 5 類欄位）。新增 `_push_claude_report_extract_section()` 輔助函式，以 Markdown 標題文字為依據，從真實報告內容中 best-effort 擷取對應區段；解析不到時固定顯示 `Not found in report`，不省略欄位、不捏造內容。過程中發現並修正一個實作 bug：最初把「pipe 傳資料」與「heredoc 傳 script」同時用在同一個 `python3 -` 呼叫上，兩者都搶佔 stdin，導致所有欄位一律回報「Not found in report」；已改用與既有 `_gate_write_history()` 一致的 argv 傳遞慣例修正。

## 2. Context Completeness Check

- Full required reading list provided: PASS
- Missing context files: None
- Did missing context affect implementation or review: NO
- Notes: 17 份必讀文件全部存在並已閱讀（`PROJECT_BOOTSTRAP.md`、`docs/development/consensus-workflow.md`、`docs/development/telegram-po-gate-notification-specification.md`、`docs/development/product-owner-gate-operation-ux.md`、`scripts/review_bridge.sh`、`scripts/test_review_bridge.sh`、`reviews/sprint-018/round-001/architecture.md`、`gate_notification_matrix.md`、`codex_review_handoff_policy.md`、`claude_report.md`、`codex_review.md`、`claude_fix_report.md`、`codex_final_review.md`、`claude_fix_report_round_2.md`、`codex_final_review_round_2.md`、`claude_fix_report_round_3.md`、`codex_final_review_round_3.md`）。

## 3. Required Reading Completion

17 份必讀文件皆存在且已閱讀，未縮減必讀清單。

## 4. Remaining Must Fix Item Addressed

1. **`push-claude-report` 未固定輸出 16 項必要欄位，缺 Claude Report summary / Files changed / Tests run / Test result / Deviations-Risks-Not Done**：已修正，見第 5 節。
2. **Test 35 未覆蓋這 5 類欄位**：已補齊，見第 7 節（35c-06 至 35c-10、35c-2、35h-5 至 35h-11）。
3. **若無法解析必須 fail loudly 或顯示明確 fallback，不可省略欄位**：已實作，見第 5.2 節與 Test 35c-2。

本輪嚴格只處理上述項目，未處理 `codex_final_review_round_3.md` 提到的 3 個 Nit（`telegram-po-gate-notification-specification.md` 第 26.3 節、`codex_review_handoff_policy.md` 第 6.1 節、`gate_notification_matrix.md` 第 2 節仍引用 UX 文件「第 6 節」而非 Round 3 改過的「第 5 節」）——這些屬於 Should Fix 以下的 Nit，Handoff Package 明確要求「不得擴大 scope 處理其他 Should Fix」，故保留給後續輪次。

## 5. `push-claude-report` 16-Field Content Contract Implementation

### 5.1 新增輔助函式 `_push_claude_report_extract_section()`

以 Markdown 標題（`^#{1,6}\s+...`）文字為依據，接受一或多個 pattern（大小寫不敏感），逐一比對每個標題文字：命中的標題，擷取「該標題到下一個標題之間」的內容作為區段本文；多個 pattern 各自命中的區段依序串接（例如 Files Changed 同時比對 `Files Changed` 與 `Files Added` 兩個 pattern，兩段都命中時會依文件順序合併呈現）。全部 pattern 都沒有命中時，回傳固定字串 `Not found in report`。

### 5.2 修正 `cmd_push_claude_report()`

在讀入 `report_content` 之後，呼叫 7 次 `_push_claude_report_extract_section()`：

```text
report_summary        <- 'Summary'
report_files_changed  <- 'Files Changed', 'Files Added'
report_tests_run      <- 'Tests Run', 'Test Changes'
report_test_result    <- 'Test Result'
report_deviations     <- 'Deviations'
report_risks          <- 'Risks'
report_not_done       <- 'Not Done'
```

`metadata_block`（Telegram 第一則訊息內容）新增對應區塊，緊接在既有的 Sprint/Round/Gate/Actor/Path metadata 之後、Safety Warning 之前：

```text
📝 Claude Report Summary
📂 Files Changed
🧪 Tests Run
✅ Test Result
⚠️ Deviations
⚠️ Risks
⚠️ Not Done
```

（Telegram spec 第 26.2 節第 10 項「Deviations / Risks / Not Done」在此拆成三個獨立標籤區塊呈現，而非合併成一段文字——這樣 Product Owner 更容易在手機上分辨三者，且與各報告本身把這三項分成三個獨立章節的既有慣例一致；三個關鍵字皆確實出現，不影響 Telegram spec 條文的實質要求。）

### 5.3 修正過程中發現並修正的實作 bug

第一版實作誤用 `printf '%s' "$content" | python3 - "$@" <<'PY' ... PY`：pipe 與 heredoc 同時作用在 `python3 -` 的 stdin 上，bash 對同一個檔案描述符的多個重導向以「最後一個生效」為準，heredoc 覆蓋了 pipe，導致 `python3 -` 讀到的「script」其實是 heredoc 內容（正確），但腳本內部又呼叫 `sys.stdin.read()` 想再讀一次 stdin 取得 report 內容——此時 stdin 已經沒有東西可讀，回傳空字串，造成 7 個欄位全部顯示 `Not found in report`（即使報告內容明明有對應章節）。已改為比照本檔案既有的 `_gate_write_history()` 慣例，把 `content` 透過 argv（`python3 - "$content" "$@"`）傳入，而非 stdin pipe，徹底避開這個衝突。已用手動 smoke test 確認修正後能正確擷取多行、含 code fence 的真實區段內容。

### 5.4 未變更的安全邊界（逐項確認）

- 未修改 `cmd_notify_gate()`：`git diff scripts/review_bridge.sh` 顯示自 Round 3 以來全部為新增行，本輪新增的擷取邏輯完全獨立在 `cmd_push_claude_report()` 與新的 `_push_claude_report_extract_section()` 輔助函式內。
- 未破壞 Sprint-017 handoff mode 三訊息模型、section-aware split、copy boundary：這些邏輯只存在於 `cmd_notify_gate()`，本輪完全未觸碰。
- 未自動呼叫 Codex、未自動核准 Gate：`cmd_push_claude_report()` 內沒有任何呼叫 `cmd_notify_gate` 或其他 Codex 呼叫邏輯的程式碼（已用 Test 35k 靜態驗證函式本體）。
- 未自動 commit / push：本輪未執行任何 git 寫入操作。
- 仍維持 opt-in Telegram delivery：`NOTIFICATION_ENABLED=true` 判斷邏輯未變（已用 Test 35l 驗證函式本體確實含此判斷）。

## 6. Files Changed

```text
scripts/review_bridge.sh       — 新增 _push_claude_report_extract_section() 輔助函式；cmd_push_claude_report() 新增 7 次欄位擷取呼叫並在 metadata_block 插入對應區塊（純新增，未修改/刪除既有行）
scripts/test_review_bridge.sh  — Test 35 fixture 新增 6 個可辨識 marker（Files/Tests Run/Test Result/Deviations/Risks/Not Done）與一份「無可辨識章節」的 minimal fixture；新增 35c-06 至 35c-10（7 項）、35c-2（Not found fallback，1 項）、35h-5 至 35h-11（7 項）、35k/35l（靜態安全邊界檢查，2 項）
```

**未修改**：`docs/development/consensus-workflow.md`、`docs/development/product-owner-gate-operation-ux.md`、`docs/development/telegram-po-gate-notification-specification.md`、`reviews/sprint-018/round-001/gate_notification_matrix.md`、`reviews/sprint-018/round-001/codex_review_handoff_policy.md`（本輪 Must Fix 範圍不涉及這些檔案；`codex_final_review_round_3.md` 提到的 3 個章節編號 Nit 刻意不在本輪處理，見第 4 節說明）、`configs/n8n/*.json`。

## 7. Test Changes

1. Test 35 fixture 擴充：`claude_report.md`/`claude_fix_report.md` 新增 Files Changed（10 章節）/Tests Run/Test Result/Deviations/Risks/Not Done 章節，各自帶有獨立的 marker 字串（`GATE35_FILES_MARKER` 等 6 個新變數），讓斷言能驗證「真的從報告擷取到正確內容」而非只驗證「欄位標籤存在」。
2. 新增 `sprint-gate35-minimal` fixture（只有標題、無任何可辨識章節），用於驗證 fallback 行為。
3. 新增斷言：
   - `35c-06`～`35c-10d`（8 項）：驗證 push artifact 對應欄位含真實擷取內容。
   - `35c-2`（1 項）：驗證 minimal fixture 產生的 push artifact，7 個報告衍生欄位全部顯示 `Not found in report`（用 `grep -c '^Not found in report$'` 精確計數為 7，不是概略字串比對）。
   - `35h-5`～`35h-11`（7 項）：驗證假 Telegram 送出的「第一則訊息」本身（不是完整報告原文那則）就包含全部 7 個報告衍生欄位的真實內容，符合 Codex Round 3 Review 的要求（「應驗證 fake Telegram Message 1 含完整 16 項，而不只是 on-disk artifact 含 marker」）。
   - `35k`/`35l`（2 項）：靜態檢查 `cmd_push_claude_report` 函式本體不含 Codex 呼叫、且 Telegram 送出路徑確實被 `NOTIFICATION_ENABLED` 判斷式包住。

## 8. Tests Run

```bash
bash scripts/test_review_bridge.sh
```

連續執行 3 次確認結果穩定。

## 9. Test Result

```text
Results: 637 passed, 0 failed
```

（620（Round 3 結束時）+ 本輪新增 17 項斷言 = 637，零失敗，連續 3 次執行結果一致。）

## 10. Deviations

無。本輪嚴格依 `codex_final_review_round_3.md` 的 Remaining Must Fix 執行，未擴大 scope、未處理該報告列出的 Nit 或 Should Fix。

## 11. Risks

1. `_push_claude_report_extract_section()` 的擷取邏輯依賴「標題文字包含指定關鍵字」的簡單比對，若未來報告改用完全不同的標題措辭（例如把「Files Changed」寫成「變更檔案」），目前的英文 pattern 不會命中，會退回顯示 `Not found in report`——這是刻意的 fail-safe 行為（顯示明確 fallback 而非猜測或留白），但代表擷取品質仍依賴報告作者維持既有的英文標題慣例。
2. `_push_claude_report_extract_section()` 同一個 pattern 若命中多個標題（例如報告中出現兩次「Summary」），目前只取第一個命中的標題內容，不會合併全部命中——這符合目前所有已知報告只有一個 Summary 章節的實際情況，但若未來報告格式改變，行為可能需要調整。

## 12. Not Done

1. 未修正 `codex_final_review_round_3.md` 指出的 3 個 Nit（`telegram-po-gate-notification-specification.md`/`codex_review_handoff_policy.md`/`gate_notification_matrix.md` 仍引用 UX 文件「第 6 節」而非 Round 3 改過的「第 5 節」）——依 Handoff Package 明確指示不擴大 scope，保留給後續輪次。
2. 未新增「`po_decision_options` 硬編碼字串」與「`gate_notification_matrix.md` 文件內容」一致性的自動化比對（`codex_final_review_round_2.md` 的 Remaining Should Fix 1）——本輪範圍不含此項。
3. 未執行真實 Telegram live delivery——本環境仍未配置真實憑證；`reviews/sprint-018/round-001/claude_fix_report_round_3.md` 第 11.2 節提供的指令仍然有效，Product Owner 可在配置好真實憑證後執行，現在會看到完整 16 欄位的第一則訊息，而不是只有 metadata 骨架。

## 13. Product Owner Next Action

1. 審閱 `push-claude-report` 第一則訊息是否確實固定呈現全部 16 項必要欄位。
2. 在已配置真實 Telegram 憑證的環境中，執行 `claude_fix_report_round_3.md` 第 11.2 節的指令（`report-path` 建議改指向本檔案 `reviews/sprint-018/round-001/claude_fix_report_round_4.md`），確認能實際收到完整 16 欄位的 Claude Report Push to PO 推播。
3. 決定是否授權重新送交 Codex 進行 Review（正式的 Codex Review Handoff 指令依 Independent Review Handoff Authority 原則，不得由本報告單獨決定，須依 `codex_review_handoff_policy.md` 準備）。
