# Claude Reply — Sprint-005 Should Fix 修正

## 修正摘要

修正 Codex Review 指出的 Should Fix：`codex_prompt.md` 的 placeholder 不應阻擋 consensus。

**根因**：`cmd_check` 與 `cmd_consensus` 原本對 placeholder 的偵測都是對整個 `required` 陣列（含 `codex_prompt.md`）做判斷，沒有依照 `docs/development/consensus-workflow.md` Fill Artifacts Step 明確排除 `codex_prompt.md` 的定義。

**修正方式**：新增一組「consensus 是否被 placeholder 阻擋」的過濾邏輯，不改動既有 consensus 演算法與 marker 規則本身：

- 新增常數 `CONSENSUS_BLOCKING_EXEMPT=("codex_prompt.md")` 與輔助函式 `blocking_artifacts()`，把 `required` 過濾成 `fill_artifacts`（即 Fill Artifacts Step 明列的 5 個檔案：`architecture.md`/`reviewed_document.md`、`claude_report.md`、`codex_review.md`、`claude_reply.md`、`codex_final_review.md`）。
- `cmd_check`：新增 `blocking_placeholder` 計算，只統計 `fill_artifacts` 中的 placeholder。整體判斷改為：missing→FAIL（不變）；`fill_artifacts` 中有 placeholder→WARNING/PLACEHOLDER（會擋 consensus）；只有 `codex_prompt.md` 是 placeholder 時→PASS，並註明「N non-blocking placeholder(s)（codex_prompt.md is not required for consensus）」。
- `cmd_consensus`：`placeholders` 陣列的來源從 `required` 改成 `fill_artifacts`，因此 `codex_prompt.md` 的 placeholder 狀態不會再被加進 `fail_reasons`，`Gate Status` 不再因它而 FAIL。

## 影響範圍

- **只修改** `scripts/review_bridge.sh`（`is_placeholder`/`blocking_artifacts` 區塊、`cmd_check`、`cmd_consensus`）與 `scripts/test_review_bridge.sh`（新增 2 個測試）。
- **check 第 1 項要求**：`codex_prompt.md` 的逐檔狀態顯示（Missing/Placeholder/Ready）完全不變，仍會標示 `PLACEHOLDER`，只是不再計入「阻擋 consensus」的統計與整體判斷。
- **consensus 第 2 項要求**：blocking placeholder 判斷只套用在 `fill_artifacts`（5 個真正需要人工填寫並參與 consensus 的檔案），`codex_prompt.md` 被排除。
- **consensus algorithm 未改**（第 3 項）：8 個 deterministic marker 的比對邏輯（`Must Fix`、`Architecture Conflict`、`Final Recommendation` ×3、`Must Fix Addressed`、`Architecture Conflict Addressed`、`Scope Expansion`）與 `parse_marker()` 完全沒有變動，只改變了餵進「placeholder 阻擋」判斷的輸入陣列。
- **deterministic markers 未改**（第 4 項）：marker 名稱、必須值（`None`/`PASS`/`Yes`/`No`）皆未變動。
- **CLI command 未新增**（第 5 項）：仍是 `init`/`skeleton`/`check`/`validate-final-consensus`/`consensus`/`finalize` 6 個指令。
- **workflow 未改**（第 6 項）：`init → skeleton → 填寫 artifact → check → consensus → finalize → validate-final-consensus` 順序與必要檔名完全不變；`codex_prompt.md` 仍是 `check`/`consensus` 的必要存在檔案（缺少仍會 MISSING/FAIL），只有「placeholder 阻擋」的判斷排除它。
- **文件未改**：`docs/development/consensus-workflow.md` 本身已明確排除 `codex_prompt.md`，不需修改；這次是讓程式碼與既有文件對齊，而非改文件配合程式碼。未觸碰任何不相關檔案。

## 測試結果

新增 2 個 regression test（`scripts/test_review_bridge.sh`）：

- **Test 16**：5 個 fill artifact 皆為真實內容且 marker 皆 PASS-worthy，`codex_prompt.md` 維持 skeleton placeholder → `check` exit 0、仍顯示 `codex_prompt.md: PLACEHOLDER`、整體 `PASS:`；`consensus` → `Gate Status: PASS`。
- **Test 17**：在上述情境下刪除 `codex_prompt.md`（模擬遺失）→ `check` exit 1、顯示 `codex_prompt.md: MISSING`，確認「存在性檢查」未被這次修正影響。

`bash scripts/test_review_bridge.sh` → **56 passed, 0 failed**（原 50 + 新增 6 項斷言），exit code 0。

另外手動驗證：

- 對真實 `reviews/sprint-004/round-001/`（唯讀）跑 `check` → 6 項全部 `READY`，`PASS`，與修正前結果一致，確認 Sprint-004 相容性不受影響。
- 修正前後皆重跑一次完整測試，確認 `git status --porcelain reviews/` 除了本 Sprint 自己建立的 `reviews/sprint-005/` 外，沒有任何新的未追蹤目錄（無測試污染）。

## 是否仍需 Product Owner 決策

**不需要。** 本次修正即是依照 Product Owner／Codex Review 的明確指示（排除 `codex_prompt.md` 於 consensus blocking 之外），且此結果與既有 `docs/development/consensus-workflow.md` 的文字定義一致，不需修改文件，也沒有留下新的衝突。

若 Product Owner 未來想讓「哪些檔案豁免於 consensus blocking」更容易擴充或更明確寫進文件，可以是後續 Sprint 的 Should Have，但非本輪必要項目。

Must Fix Addressed: Yes

Architecture Conflict Addressed: Yes

Final Recommendation: PASS
