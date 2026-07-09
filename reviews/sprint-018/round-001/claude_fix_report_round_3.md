# Claude Fix Report — Sprint-018 Must Fix Round 3

## 1. Summary

依 `codex_final_review_round_2.md` 的 REMAINING MUST FIX 結論，修正 `consensus-workflow.md` 與 `product-owner-gate-operation-ux.md` 殘留的 13/8 Gate 數字與「Gate 6 承接 Fix Report Ready」錯誤語意；並實際落地「Claude Report Push to PO」機制——新增 `scripts/review_bridge.sh` 的 `push-claude-report` 指令（方案 A），讓 Product Owner 有真正可執行的 command 能收到 Claude Report 的 Telegram 推播，不再只是文件描述。因本環境未配置真實 Telegram 憑證（`TELEGRAM_BOT_TOKEN`/`TELEGRAM_CHAT_ID`/`NOTIFICATION_ENABLED` 均未設定），本輪**未執行真實 live delivery**，已在第 11 節提供 Product Owner 可直接複製執行的完整指令。

## 2. Context Completeness Check

- Full required reading list provided: PASS
- Missing context files: None
- Did missing context affect implementation or review: NO
- Notes: 15 份必讀文件全部存在並已閱讀（`PROJECT_BOOTSTRAP.md`、`docs/development/consensus-workflow.md`、`docs/development/telegram-po-gate-notification-specification.md`、`docs/development/product-owner-gate-operation-ux.md`、`scripts/review_bridge.sh`、`scripts/test_review_bridge.sh`、`reviews/sprint-018/round-001/architecture.md`、`gate_notification_matrix.md`、`codex_review_handoff_policy.md`、`claude_report.md`、`codex_review.md`、`claude_fix_report.md`、`codex_final_review.md`、`claude_fix_report_round_2.md`、`codex_final_review_round_2.md`）。

## 3. Required Reading Completion

15 份必讀文件皆存在且已閱讀，未縮減必讀清單。

## 4. Remaining Must Fix Items Addressed

1. **`consensus-workflow.md` 仍寫 `13 of the 21 canonical Product Owner Gates` 與 `remaining 8`**：已修正為 `14 of the 21` / `remaining 7`，並附註 Round 2 新增 `claude_must_fix_report_acceptance` 作為 Claude Fix Report Ready 的操作性 Gate。
2. **`product-owner-gate-operation-ux.md` 第 1 節與第 3 節仍寫「13 個操作性 Gate」**：已全部修正為「14 個操作性 Gate」。
3. **`product-owner-gate-operation-ux.md` 第 6.4 節仍把 Fix Report Ready 指向 `claude_must_fix_approval` / Gate 6**：已重寫為新的第 5.5 節，明確寫出：`claude_must_fix_approval`（Gate 6）是 Must Fix **開始前**的執行授權 Gate，明確排除於 Claude Completion Gate 之外；`claude_must_fix_report_acceptance`（Gate 14）才是 Claude Fix Report **完成後**的驗收 Gate，與 Gate 4 `claude_implementation_report_acceptance` 對稱。
4. **補 stale wording 的 regression check**：已在 Test 34 新增 34m–34p 共 6 項斷言（見第 8 節）。

## 5. Document Consistency Fix

- `docs/development/consensus-workflow.md`：Sprint-018 段落的 Gate 數字從 13/8 修正為 14/7。
- `docs/development/product-owner-gate-operation-ux.md`：
  - 第 1 節文件關係圖：「13 個操作性 Gate」→「14 個操作性 Gate」。
  - 第 3 節 Content Mode 說明：同上修正。
  - 章節編號缺口修正（原本第 4 節後直接跳到第 6 節）：原第 6 節「Claude Report Push to PO」重新編號為第 5 節，原第 7 節「本文件不涵蓋的內容」重新編號為第 6 節，章節連續無缺口。
  - 新增第 5.5 節「適用 Gate」，明確列出 2 個對稱的 Claude Completion Gate（Gate 4 / Gate 14），並用「明確排除」段落點名 `claude_must_fix_approval`（Gate 6）不適用本節流程，說明原因（開始前授權 vs. 完成後驗收，時間點相反）。
  - Version 更新為 1.2，記錄本輪修正內容。

兩份文件現在與 `gate_notification_matrix.md`（14 Gate、Gate 14 = `claude_must_fix_report_acceptance`）完全一致，不再互相矛盾。

## 6. Claude Report Push to PO Implementation

### 6.1 方案選擇：方案 A（新增 Review Bridge command）

新增 `scripts/review_bridge.sh` 的 `push-claude-report` 指令：

```bash
./scripts/review_bridge.sh push-claude-report <sprint-id> <round> <implementation|fix> [report-path]
```

選擇方案 A（而非方案 B）的原因：`notify-gate` 已經是這個 repo 裡「PO 手動觸發 Telegram 通知」的標準操作模式，Product Owner 已經很熟悉這個 CLI 慣例（env vars、`--dry-run`、REVIEWS_OVERRIDE 隔離測試）；新增一個同樣風格的 command 比引入全新的 artifact-only 機制更符合現有使用習慣，也更容易維護（可以直接複用 `_notify_split_for_telegram`、`_gate_write_history` 等既有 helper function，不需要重新發明）。

### 6.2 設計重點

1. **讀取真實 Claude Report artifact**（`report_type=implementation` 預設讀 `claude_report.md`；`report_type=fix` 預設讀 `claude_fix_report.md`；皆可用第 4 個參數覆寫成任意路徑，例如本輪的 `claude_fix_report_round_2.md`／`claude_fix_report_round_3.md`）——找不到檔案時直接 `die`，不會生出空白或捏造內容的推播。
2. **產生 Product Owner 可讀的 Telegram Report Push**：檔案寫入 `reviews/<sprint>/round-<round>/notifications/claude-report-push-<gate_id>.md`，同時包含固定 metadata 區塊與逐字引用的完整報告內容（未經摘要或改寫，Artifact-First 原則不變）。
3. **明確標示不是 Gate approval**：固定的「⚠️ Safety Warning」區塊三行——`Claude did not call Codex.`、`Claude did not approve the Gate.`、`Product Owner must manually decide whether to send this report to Codex.`
4. **明確標示不是 Auto Handoff to Codex**：`Suggested next actor: Codex` 只是建議，不是自動轉交；`📋 Copy Guidance` 明確寫「Product Owner 若決定送交 Codex，請把...一起貼給 Codex」，動作主體是 Product Owner，不是這個指令本身。
5. **PO 必須審核後手動決定下一步**：`✅ Product Owner Action Required` 與 `✅ Product Owner Decision Options`（依 `report_type` 對應 Gate 4 / Gate 14 在 `gate_notification_matrix.md` 裡已核准的 canonical Decision options 文字，非本指令自行發明）。
6. **附上 Codex Review authority 提醒**：`📋 Codex Review Instruction Source` 明確寫「canonical template / codex_review_handoff_policy.md（Claude Report 只是 review input，不是 review authority；...必須同時附上...canonical Codex Review 要求，不得只貼 Claude Report 本身）」。

### 6.3 執行方式與安全邊界

- **執行時機**：跟 `notify-gate` 一樣，只能由 Product Owner 手動在終端機執行；`cmd_push_claude_report` 未被此檔案內任何其他函式呼叫，Claude / Codex 不會自動觸發。
- **Telegram 送出**：沿用 `notify-gate` 的 opt-in 機制（`NOTIFICATION_ENABLED=true` + `TELEGRAM_BOT_TOKEN`/`TELEGRAM_CHAT_ID`），未設定時只寫入本機檔案、明確印出「skipping Telegram delivery」，不會靜默失敗也不會誤導使用者以為已送達。
- **`reviews/notification_history.jsonl` 記錄**：沿用既有 `_gate_write_history()`，`next_actor` 固定填 `"Codex"`（建議下一位執行者，非自動轉交對象），`risk_level` 固定填 `"low"`（純通知，非 Commit/Push 類高風險操作）。
- **未修改 `cmd_notify_gate()` 或 `cmd_notify()` 任何一行**：新函式 `cmd_push_claude_report()` 完全獨立新增在 `cmd_notify_gate()` 結尾與「Main dispatcher」之間，`git diff scripts/review_bridge.sh` 確認全部 210 行變更皆為新增（`+`），零刪除、零修改既有程式碼行（見第 9 節 Repository Hygiene Check）。

## 7. Files Changed

```text
docs/development/consensus-workflow.md                            — Sprint-018 段落 13/8 修正為 14/7
docs/development/product-owner-gate-operation-ux.md                — 13 Gate 措辭修正為 14 Gate；重寫第 5 節（原第 6 節）Fix Report Ready 適用 Gate 為 Gate 14；修正章節編號缺口；Version 更新
scripts/review_bridge.sh                                            — 新增 cmd_push_claude_report() 函式、push-claude-report dispatcher case、usage() 說明文字（純新增，未修改既有函式）
scripts/test_review_bridge.sh                                       — Test 33/34 註解與陣列的 13→14 Gate 措辭同步修正；Test 34 新增 34m–34p（6 項 stale wording regression check）；新增 Test 35（33 項斷言，驗證 push-claude-report 指令）
```

**未修改**：`reviews/sprint-018/round-001/architecture.md`（Round 1 決策紀錄保留）、`reviews/sprint-018/round-001/gate_notification_matrix.md`（Round 2 已完成，本輪未發現此檔案有 Must Fix）、`reviews/sprint-018/round-001/codex_review_handoff_policy.md`（同上）、`configs/n8n/*.json`。

## 8. Test Changes

1. Test 33：`SPRINT18_GATES`/`SPRINT18_HANDOFF_GATES` 陣列與斷言描述中殘留的「13 selected gates」「all 13 gates」等註解與字串，同步修正為「14」。
2. Test 34：新增 34m（`consensus-workflow.md` 不再含 `13 of the 21 canonical`）、34n（不再含 `remaining 8 canonical`）、34o（`product-owner-gate-operation-ux.md` 不再含「13 個操作性 Gate」）、34p-1/2/3（UX 文件正確列出 `claude_must_fix_report_acceptance` 且「明確排除」段落正確點名 `claude_must_fix_approval` 不適用）。
3. 新增 Test 35（33 項斷言）：35a 驗證 help/usage 文字；35b–35c 驗證 `implementation` 模式產生的推播檔案包含全部必要內容且不含 NOTIFICATION_ENABLED 時正確跳過 Telegram；35d 驗證 `fix` 模式對應到 Gate 14；35e 驗證第 4 參數路徑覆寫功能；35f/35g 驗證缺檔案／無效 report-type 皆 fail loudly；35h 用假 curl stub 驗證實際送出至少 2 則訊息（metadata + report 內容）；35i 驗證 history 記錄欄位正確且真實 `notification_history.jsonl` 不受影響；35j 驗證 n8n 未變。

## 9. Tests Run

```bash
bash scripts/test_review_bridge.sh
```

連續執行 3 次確認結果穩定。

## 10. Test Result

```text
Results: 620 passed, 0 failed
```

（586（Round 2 結束時）+ Test 34 新增 6 項（34m–34p）+ 新增 Test 35 共 33 項 + Test 33/34 陣列相關的既有斷言因文字修正保持不變、無新增或刪除項目 = 620，零失敗，連續 3 次執行結果一致。）

## 11. Telegram Push Command / Artifact

### 11.1 本輪產出的 report artifact

```text
reviews/sprint-018/round-001/claude_fix_report_round_3.md（本檔案）
```

### 11.2 Product Owner 可直接複製執行的完整指令

因本環境未配置真實 `TELEGRAM_BOT_TOKEN`/`TELEGRAM_CHAT_ID`/`NOTIFICATION_ENABLED`，以下指令由 Product Owner 在已設定好真實憑證的環境中執行（`PROJECT_ID`/`PROJECT_NAME` 沿用本 repo 既有真實記錄中一致使用的值）：

```bash
PROJECT_ID="ai-workspace" \
PROJECT_NAME="AI Workspace" \
NOTIFICATION_ENABLED=true \
TELEGRAM_BOT_TOKEN="<your-real-bot-token>" \
TELEGRAM_CHAT_ID="<your-real-chat-id>" \
./scripts/review_bridge.sh push-claude-report sprint-018 001 fix \
  reviews/sprint-018/round-001/claude_fix_report_round_3.md
```

執行後應收到至少 2 則 Telegram 訊息：第 1 則是固定的 metadata / Safety Warning / Decision Options 區塊；第 2 則（或更多，視報告長度而定，超過安全長度會自動用既有 `_notify_split_for_telegram` 切分）是本報告的逐字內容。

## 12. Live Delivery Result

**本輪未執行真實 live delivery。**

- 是否 enabled：否——檢查本 shell 環境，`NOTIFICATION_ENABLED`、`TELEGRAM_BOT_TOKEN`、`TELEGRAM_CHAT_ID`、`PROJECT_ID`、`PROJECT_NAME` 皆為 unset（已用 `echo ${VAR:-<unset>}` 逐一確認，未在本報告中印出任何實際憑證值）。
- 是否成功送達：不適用（未嘗試執行）。
- 未送達原因：本環境缺少真實 Telegram Bot 憑證，Claude Code 不會、也不應該自行發明或猜測這些憑證；依專案既有安全邊界（`docs/development/execution-permission-policy.md`），Telegram 憑證屬於 Product Owner 管理範疇。
- 已改為提供 Product Owner 可直接複製執行的完整指令（見第 11.2 節），並用假 curl stub（Test 35h）驗證了「若憑證存在，指令會正確送出 metadata + report 內容兩則以上訊息」的行為，證明指令邏輯本身正確，只差真實憑證。

## 13. Deviations

無。本輪嚴格依 `codex_final_review_round_2.md` 的 4 項 Remaining Must Fix 與 Handoff Package 的 Must Fix 1/2 執行，未擴大 scope。方案 A vs 方案 B 的選擇已在第 6.1 節說明理由。

## 14. Risks

1. `push-claude-report` 是全新指令，尚未經過 Codex Review 的獨立審視——需要下一輪 Review 驗證其安全邊界與內容規則是否真的滴水不漏。
2. Decision Options 文字（`po_decision_options`）目前是在 `cmd_push_claude_report()` 內以 case statement 硬編碼，與 `gate_notification_matrix.md` Gate 4 / Gate 14 的 Decision options 文字保持一致，但兩處是分開維護的字串——若未來有人只改了矩陣文件、忘記同步改程式碼裡的硬編碼字串，兩者可能出現不一致，且目前沒有自動化機制偵測這種漂移（只能靠人工比對）。
3. 尚未實際驗證真實 Telegram 送達（見第 12 節）；push-claude-report 的邏輯正確性目前只有 fake curl stub 驗證過。

## 15. Not Done

1. 未執行真實 Telegram live delivery（已在第 11/12 節說明原因與替代方案）。
2. Codex Final Review Round 2 的 2 項 Remaining Should Fix（Gate 4/14 具體範例 command、Telegram live validation）：第 1 項本輪已透過 `push-claude-report` 指令本身變得可操作（不再需要另外撰寫範例，因為指令本身就是可直接照抄的操作方式）；第 2 項仍待 Product Owner 執行第 11.2 節指令後才能完成。
3. 未新增自動偵測「`po_decision_options` 硬編碼字串」與「`gate_notification_matrix.md` 文件內容」是否一致的機制（見 Risk 2）——若 Product Owner 認為有必要，可列入未來輪次。

## 16. Product Owner Next Action

1. 審閱文件一致性修正（`consensus-workflow.md`、`product-owner-gate-operation-ux.md`）是否確實解決 Codex Final Review Round 2 的 4 項 Remaining Must Fix。
2. 在已配置真實 Telegram 憑證的環境中，執行第 11.2 節的指令，確認能實際收到 Claude Report Push to PO 的 Telegram 推播。
3. 決定是否授權重新送交 Codex 進行 Review（正式的 Codex Review Handoff 指令依 Independent Review Handoff Authority 原則，不得由本報告單獨決定，須依 `codex_review_handoff_policy.md` 準備）。
