# Claude Fix Report — Sprint-018 Must Fix Round 1

## 1. Summary

依 `reviews/sprint-018/round-001/codex_review.md` 的 MUST FIX 結論，修正 `gate_notification_matrix.md` 的欄位完整性問題（5 個 Gate 缺少明確的 `Target AI` / `copy boundary` 欄位），並將 `scripts/test_review_bridge.sh` 的 Test 33 從「檢查欄位字串是否出現在整份文件某處」強化為「逐 Gate、逐欄位」的 182 項獨立檢查。本輪只處理 Codex Review 指出的 2 項 Must Fix，未擴大 scope，未修改 `scripts/review_bridge.sh`、未回頭修改 Sprint-017。

## 2. Context Completeness Check

- Full required reading list provided: PASS
- Missing context files: None
- Did missing context affect implementation or review: NO
- Notes: 11 份必讀文件全部存在並已閱讀（`PROJECT_BOOTSTRAP.md`、`docs/development/consensus-workflow.md`、`docs/development/telegram-po-gate-notification-specification.md`、`docs/development/product-owner-gate-operation-ux.md`、`scripts/review_bridge.sh`、`scripts/test_review_bridge.sh`、`reviews/sprint-018/round-001/architecture.md`、`claude_report.md`、`gate_notification_matrix.md`、`codex_review_handoff_policy.md`、`codex_review.md`）。

## 3. Required Reading Completion

11 份必讀文件皆存在且已閱讀，未縮減必讀清單。

## 4. Codex MUST FIX Items Addressed

### Must Fix 1：補齊 `gate_notification_matrix.md` 的 13 個 Gate 14 欄位完整性

Codex 指出 5 個 Gate 有欄位缺漏：

| gate_id | 缺漏內容（修正前） | 修正後 |
|---|---|---|
| `codex_git_review_result_decision` | 有 Target AI，缺 copy boundary | Target AI 改為「N/A（不適用）；若 Product Owner 選擇透過 Codex Commit Mode 準備 commit 內容，則為 `Codex`」；新增 copy boundary「N/A（不適用）；若上述情況成立，則為 `===== BEGIN COPY TO CODEX =====` / `===== END COPY TO CODEX =====`」 |
| `commit_approval` | 缺 Target AI、缺 copy boundary | 新增 Target AI：`N/A（不適用）`；新增 copy boundary：`N/A（不適用）` |
| `push_approval` | 缺 Target AI、缺 copy boundary | 同上，皆補為 `N/A（不適用）` |
| `retrospective_content_approval` | 缺 Target AI、缺 copy boundary | 同上 |
| `product_owner_closure_approval` | 缺 Target AI、缺 copy boundary | 同上 |

另外，為了讓「14 個欄位全部明確」這件事可以被逐一驗證，而不是依賴文件結構隱含推論，在全部 13 個 Gate 的章節下新增明確的 `- **Gate ID**：\`gate_id\`` bullet（原本只以章節標題 `### 3.N \`gate_id\`` 隱含表達，Codex 未特別點名此項缺漏，但既然本輪目標就是「不得用空白、隱含、省略」取代欄位，一併補上以求一致）。

同時依 Codex 的 Nit 建議，修正 Section 2 欄位定義的措辭：把「Target AI（若需要）」「copy boundary（若需要）」改為「全部 14 個欄位在每個 Gate 都必須明確填寫」+ 明確規則「若不需要 Handoff，Target AI / copy boundary 仍須填 `N/A（不適用）`，不得省略」，避免未來 Sprint 再次誤解為「可省略」。

Section 4 Summary Table 也同步更新：新增 `copy boundary` 欄位、把原本用 `—` 表示的「不需要」改為與內文一致的 `N/A（不適用）`。

### Must Fix 2：強化 `scripts/test_review_bridge.sh` Test 33

原本的 Test 33 只用「Product Owner action required」等關鍵字對整份 `gate_notification_matrix.md` 做一次全文 `assert_contains`，沒有逐 Gate 檢查，也沒有真正驗證 `Target AI`/`copy boundary` 兩欄的值本身。本輪重寫為：

1. 新增 `_sprint18_extract_gate_section()`：用 awk 依 `### 3.N \`gate_id\`` 標題切出每個 Gate 自己的區塊內容。
2. 新增 `SPRINT18_FIELDS` 陣列（14 個欄位標籤）與 `SPRINT18_GATE_SECTIONS` 關聯陣列（快取每個 Gate 的區塊內容）。
3. **33m**：對 13 個 Gate × 14 個欄位，逐一 `assert_contains` 驗證該欄位標籤確實出現在**該 Gate 自己的區塊**裡（而非整份文件），共 182 項獨立斷言，每項失敗都能精確定位是哪個 Gate 缺哪個欄位。
4. **33n / 33o**：對 5 個「不需要 Handoff」的 Gate（`SPRINT18_NA_GATES`），逐一擷取 `Target AI`/`copy boundary` 欄位那一行的實際內容，驗證確實包含 `N/A` 或 `不適用` 字樣，而不是只驗證欄位標籤存在。
5. **33f / 33g**：對 6 個「需要 Handoff」的 Gate（`SPRINT18_HANDOFF_GATES`），驗證 Target AI 欄位「不是」N/A/不適用（是真正的 AI 名稱），且 copy boundary 欄位確實包含 `BEGIN COPY TO` 字樣。

## 5. Files Changed

```text
reviews/sprint-018/round-001/gate_notification_matrix.md   — 補齊 5 個 Gate 的 Target AI / copy boundary 欄位（皆為 N/A 情境）；為 13 個 Gate 新增明確 Gate ID bullet；修正 Section 2 欄位定義措辭；更新 Section 4 Summary Table
scripts/test_review_bridge.sh                               — 重寫 Test 33 的欄位驗證邏輯，從全文關鍵字檢查改為逐 Gate、逐欄位（182 項）+ N/A 值驗證（10 項）+ 真實 Target AI/copy boundary 驗證（2 項）
```

**未修改**：`scripts/review_bridge.sh`（本輪 Must Fix 不涉及任何 notify-gate / Telegram renderer 程式邏輯變更，純粹是文件欄位補齊與測試斷言強化）、`docs/development/consensus-workflow.md`、`docs/development/telegram-po-gate-notification-specification.md`、`docs/development/product-owner-gate-operation-ux.md`、`reviews/sprint-018/round-001/codex_review_handoff_policy.md`（Codex Review 對這些檔案的結論是 PASS，本輪未觸碰）。

## 6. Test Changes

見上方 Must Fix 2 說明。新增/修改的斷言全部集中在 Test 33 區塊內，未影響 Test 1–32 既有斷言。

## 7. Tests Run

```bash
bash scripts/test_review_bridge.sh
```

連續執行 3 次確認結果穩定。

## 8. Test Result

```text
Results: 536 passed, 0 failed
```

（348（Sprint-018 Round 1 提交 Codex Review 時）+ 本輪 Test 33 欄位驗證邏輯重寫後淨增 188 項斷言（182 項逐 Gate 逐欄位 + 10 項 N/A 驗證 + 2 項真實 Target AI/copy boundary 驗證，扣除移除的 8 項舊版聚合斷言）= 536，零失敗，連續 3 次執行結果一致。）

## 9. Deviations

無。本輪嚴格依 Codex Review 的 2 項 Must Fix 執行，未擴大 scope。額外為全部 13 個 Gate 新增顯式 `Gate ID` bullet 一項，雖未被 Codex 逐一點名，但屬於「不得用空白、隱含、省略取代欄位」這個 Must Fix 1 精神的直接延伸（原本 Gate ID 只隱含在章節標題），判斷為 Must Fix 範圍內的必要一致性修正，非新增功能或擴大 scope。

## 10. Risks

1. `SPRINT18_NA_GATES` 與 `SPRINT18_HANDOFF_GATES` 兩個陣列是根據目前 `gate_notification_matrix.md` 的內容手動列舉，若未來矩陣新增第 14 個 Gate 或改變某個 Gate 的 Handoff 需求，測試需要同步更新陣列內容，否則新 Gate 不會被納入這兩類檢查（但仍會被 33m 的通用逐欄位檢查涵蓋）。
2. `codex_git_review_result_decision` 目前歸類在 `SPRINT18_NA_GATES`（因為預設值為「否」），但其 Target AI/copy boundary 欄位內容包含「視情況為 Codex」的條件說明；33n/33o 只驗證該行「包含 N/A 或不適用」，不驗證條件說明本身的正確性——這部分正確性仍依賴人工審閱。

## 11. Not Done

未變更（與 Sprint-018 原始報告的 Not Done 一致）：未實際針對這 13 個 Gate 執行真實 `notify-gate`（連上真實 Telegram）；未把 8 個排除在矩陣外的 Gate 也建立對應矩陣項目；未修改 `docs/development/product-owner-gate-metadata.md`。Should Fix 項目（Gate 4 具體 notify-gate 範例 command、`codex_review_handoff_policy.md` 補一句測試檔變更說明）本輪未處理——Codex Review 明確標示為 Should Fix 而非 Must Fix，且 Handoff Package 指示「本次 Must Fix 只允許處理 Codex Review 指出的問題，不得擴大 scope」，故保留給後續輪次或 Product Owner 決定是否處理。

## 12. Product Owner Next Action

1. 審閱本輪修正是否確實解決 Codex Review 的 2 項 Must Fix。
2. 決定是否將 Should Fix 2 項（Gate 4 範例 command、policy 文件補充說明）併入後續輪次。
3. 決定是否授權重新送交 Codex 進行 Final Review（正式的 Codex Review Handoff 指令依 Independent Review Handoff Authority 原則，不得由本報告單獨決定，須依 `codex_review_handoff_policy.md` 準備）。
