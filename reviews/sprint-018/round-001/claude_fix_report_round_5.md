# Claude Fix Report — Sprint-018 Must Fix Round 5

## 1. Summary

Sprint-018 Codex Final Review Supplement Round 4 判定 PASS：`push-claude-report` 的 16 項欄位內容契約已完成，Product Owner 手動執行該指令後，Telegram 確實能送達且內容完整。但 Product Owner Telegram Live Validation 仍判定 **NOT PASS**——原因不在內容契約，而在**執行責任**：`push-claude-report` 一直是純人工 CLI 指令，Claude Code 完成 Implementation / Fix Report 之後，沒有任何流程會觸發它，Product Owner 必須自己記得、自己手動執行指令才會收到通知。這正是 Sprint-018 從一開始要解決的問題（「Claude 完成後，Product Owner 應該主動知道」），Round 2–4 都只把內容契約做對，沒有把「誰來執行」這個責任缺口補上。

本輪只處理這一個缺口，不擴大 scope：新增「Claude Report Completion Notification Step」規則，讓 Claude Code 在完成報告後，於嚴格限定條件下親自執行 `push-claude-report`；同時修正 `scripts/review_bridge.sh` 的一個既有不一致（`NOTIFICATION_ENABLED` 未設定時完全不寫入 Notification History，導致「是否曾嘗試推播」無法被稽核）。

## 2. Context Completeness Check

- Full required reading list provided: PASS
- Missing context files: None
- Did missing context affect implementation or review: NO
- Notes: Handoff 指定的 11 份必讀文件（`PROJECT_BOOTSTRAP.md`、`docs/development/consensus-workflow.md`、`docs/development/telegram-po-gate-notification-specification.md`、`docs/development/product-owner-gate-operation-ux.md`、`scripts/review_bridge.sh`、`scripts/test_review_bridge.sh`、`reviews/sprint-018/round-001/architecture.md`、`gate_notification_matrix.md`、`codex_review_handoff_policy.md`、`claude_fix_report_round_4.md`、`codex_final_review_round_4.md`）全部存在並已閱讀。

## 3. Required Reading Completion

11 份必讀文件皆存在且已閱讀，未縮減必讀清單。

## 4. 分析（依 Handoff 要求逐項回答）

### 4.1 目前 `push-claude-report` 是否只是手動 CLI command？

**是**。`scripts/review_bridge.sh` 的 dispatcher（檔案最末的 `case "$COMMAND" in ... push-claude-report) cmd_push_claude_report "$@" ;;`）是 `cmd_push_claude_report()` 唯一的呼叫入口；除此之外，本檔案內沒有任何函式呼叫 `cmd_push_claude_report`（已用既有 Test 35k 靜態驗證：函式本體不含任何自我呼叫或 Codex 呼叫）。它必須由人在終端機明確輸入完整指令才會執行。

### 4.2 Claude Code 完成 report 後，是否有任何流程會自動或半自動觸發 push-claude-report？

**沒有**。`cmd_check()`（`check` 指令）在 `claude_report.md` 變成 READY 時，只會：(a) 呼叫 `write_handoff_package_claude_to_codex()` 產生 `handoff_package.md`，(b) 呼叫 `notify_claude_report_done()`（僅在設定 `N8N_CLAUDE_DONE_WEBHOOK_URL` 時才動作，且對象是 n8n webhook，不是 Telegram、也不是 `push-claude-report`）。沒有任何程式路徑、hook、或既有規則要求 Claude Code 在完成報告後執行 `push-claude-report`；`docs/development/telegram-po-gate-notification-specification.md` 第 26.3 節（Round 4 之前）反而明文寫「必須由 Product Owner 手動執行」（原文誤植成 `notify-gate`，但語意上就是要求人工執行 `push-claude-report`）。

### 4.3 這是否代表 Sprint-018「Claude 完成後通知 PO」需求尚未真正完成？

**是**。Sprint-018 的目的（見 `docs/development/telegram-po-gate-notification-specification.md` 第 26.1 節）是「讓 Product Owner 不需要主動回頭檢查 terminal 就能得知進度」。但只要執行責任仍完全落在 Product Owner 身上，Product Owner 就必須「主動」記得執行指令才能得知進度——這與需求的字面目的直接矛盾。Round 2–4 做對的是「執行後內容夠不夠好」，沒有做的是「誰來執行、什麼時候執行」。這是一個流程責任缺口，不是內容契約缺陷，Round 4 的 PASS 判斷範圍本來就不涵蓋這一項（見 `codex_final_review_round_4.md` 的 Scope Reviewed 只列內容契約相關項目）。

### 4.4 在不違反安全邊界的前提下，應如何修正？

新增一條範圍嚴格限定於 `push-claude-report`（不含 `notify-gate`）的「Claude Report Completion Notification Step」規則：Claude Code 完成報告、跑完測試後，唯讀檢查本機環境是否已具備 `NOTIFICATION_ENABLED`/`TELEGRAM_BOT_TOKEN`/`TELEGRAM_CHAT_ID`/`PROJECT_ID`/`PROJECT_NAME`；具備才親自執行 `push-claude-report`，不具備則不執行、且在報告中明確記錄未嘗試的原因與手動指令（fail loudly，不假裝已通知）。`notify-gate` 的人工限定（第 18/19 節）完全不變。詳見第 5 節實作內容。

## 5. 修正內容

### 5.1 新規則：Claude Report Completion Notification Step

新增至 `docs/development/consensus-workflow.md`（新章節，緊接在既有「Product Owner Gate Operation UX (Sprint-018)」之後）與 `docs/development/telegram-po-gate-notification-specification.md`（新第 27 節，取代第 26.3 節原本誤植 `notify-gate` 的執行責任敘述）：

1. Claude Code 完成 `claude_report.md` / `claude_fix_report*.md` 並跑完測試後，唯讀檢查本機環境變數是否已具備 `NOTIFICATION_ENABLED=true`、`TELEGRAM_BOT_TOKEN`、`TELEGRAM_CHAT_ID`、`PROJECT_ID`、`PROJECT_NAME`——只檢查是否存在，絕不讀取、印出、記錄其實際值，也絕不要求 Product Owner 把值貼給自己。
2. 全部具備時，Claude Code 親自執行 `./scripts/review_bridge.sh push-claude-report <sprint-id> <round> <implementation|fix> [report-path]`，做為結束該輪工作前的最後一步。
3. 任一項缺少時，Claude Code 不執行、不宣稱已通知，必須在報告內的 `## Telegram Push Status` 區塊明確記錄，並附上可直接複製的手動指令。
4. 這是範圍嚴格限定於 `push-claude-report` 的例外——`docs/development/telegram-po-gate-notification-specification.md` 第 18/19 節「Claude / Codex 不得自動觸發 Telegram」「Claude Code 不得執行 `notify-gate`」完全不變，`notify-gate` 仍然 100% 只能由 Product Owner 人工執行。

同時修正 `docs/development/product-owner-gate-operation-ux.md` 第 5.4 節「完整流程」圖示與說明，反映新流程，並明確記錄「為何 Round 4 的 Product Owner Telegram Live Validation 判定 NOT PASS」這段歷史脈絡，避免未來輪次重蹈覆轍。

### 5.2 程式修正：`scripts/review_bridge.sh` 的 `cmd_push_claude_report()`

發現既有實作的一個不一致：`NOTIFICATION_ENABLED` 不是 `true` 時，函式會直接 `return 0`，完全不寫入 `reviews/notification_history.jsonl`——這與 `cmd_notify()` / `cmd_notify_gate()` 既有的「即使停用也記錄 `delivery_status: disabled`」慣例不一致，導致「Claude Code 是否曾經嘗試執行 push-claude-report」這件事無法被 Notification History 稽核（只能看 Claude Report 自己的陳述，不能交叉驗證）。

修正：移除該 `return 0` 提早返回，改為與 `cmd_notify()`/`cmd_notify_gate()` 相同的結構——不論 `NOTIFICATION_ENABLED` 是否為 `true`，一律呼叫 `_gate_write_history()` 寫入歷史紀錄：

- `NOTIFICATION_ENABLED` 不是 `true` → `delivery_status="disabled"`（新增，先前完全不寫入）。
- `NOTIFICATION_ENABLED=true` 但缺少 `TELEGRAM_BOT_TOKEN`/`TELEGRAM_CHAT_ID` → `delivery_status="disabled"`（先前誤標為 `"failed"`，與 `cmd_notify()`/`cmd_notify_gate()` 的既有慣例不一致，予以修正）。
- 其餘分支（`curl` 不存在 / 實際送出成功或失敗）行為不變。

### 5.3 Claude Report 必須新增 `## Telegram Push Status` 區塊

`docs/development/telegram-po-gate-notification-specification.md` 第 27.4 節定義固定格式：Push attempted（YES/NO）、Reason（未嘗試時的原因）、Delivery status（delivered/failed/disabled/not_attempted）、Push artifact path、Notification history reference、Manual command（未嘗試時提供）。本報告第 11 節即依此格式填寫，作為本規則的第一個示範案例。

## 6. Files Changed

```text
scripts/review_bridge.sh                                          — cmd_push_claude_report() 移除 NOTIFICATION_ENABLED 為 false 時的提早 return，改為與 cmd_notify/cmd_notify_gate 一致地無條件寫入 Notification History（disabled/failed/delivered 三態）；更新函式上方註解說明 Round 5 執行責任調整
scripts/test_review_bridge.sh                                     — Test 35 新增 35m（disabled 狀態確實寫入歷史）、35n（token/chat_id 缺少時記錄為 disabled 而非 failed）；新增 Test 36（10 項文件內容斷言，驗證三份文件的新規則、勘誤、與 notify-gate 不受影響的敘述）
docs/development/consensus-workflow.md                            — 新增「Claude Report Completion Notification Step (Sprint-018 Must Fix Round 5)」章節
docs/development/telegram-po-gate-notification-specification.md  — 新增第 27 節（Claude Report Push 執行責任）；第 26.4 節後新增勘誤說明；版本號更新為 1.10
docs/development/product-owner-gate-operation-ux.md               — 第 5.4 節「完整流程」改寫為 Round 5 版本，新增歷史脈絡說明；版本號更新為 1.3
```

**未修改**：`reviews/sprint-018/round-001/architecture.md`（依 Round 2 已確立的慣例，Round 1 核准決策紀錄保留原始軌跡，不因後續 Must Fix 回頭修改）、`gate_notification_matrix.md`、`codex_review_handoff_policy.md`（本輪 Must Fix 範圍不涉及這兩份文件的內容）、`configs/n8n/*.json`。

## 7. Test Changes

1. Test 35 新增：
   - `35m`：驗證 `NOTIFICATION_ENABLED` 未設定時，`_gate_write_history()` 確實寫入一筆 `delivery_status: disabled` 的紀錄（先前完全不寫入）。
   - `35n`/`35n-2`/`35n-3`/`35n-4`：驗證 `NOTIFICATION_ENABLED=true` 但缺少 Token/Chat ID 時，記錄為 `disabled`（不是先前的 `failed`），且 `error_message` 說明原因，並確認真實 repo 的 `notification_history.jsonl` 不受影響。
2. 新增 Test 36（10 項）：以既有 Test 34 的「讀取文件內容做字串斷言」模式為範本，逐一驗證三份文件（`telegram-po-gate-notification-specification.md`、`consensus-workflow.md`、`product-owner-gate-operation-ux.md`）都包含本輪新增的關鍵規則文字，以及 `configs/n8n/*.json` 無 diff、真實 `notification_history.jsonl` 不受影響。

## 8. Tests Run

```bash
bash scripts/test_review_bridge.sh
```

連續執行 3 次確認結果穩定。

## 9. Test Result

```text
Results: 655 passed, 0 failed
```

（637（Round 4 結束時）+ 本輪新增 18 項斷言 = 655，零失敗，連續 3 次執行結果一致。）

## 10. Deviations

無。本輪嚴格依 Handoff Package 指定的問題（Claude Report Push Trigger / Execution Responsibility Gap）處理，未處理 Round 4 `codex_final_review_round_4.md` 列出的 Should Fix / Nit（UX 文件章節編號舊引用、report section parser 格式相依風險）——這些不在本輪要求範圍內，保留給後續輪次。

## 11. Telegram Push Status

（依本輪新增的 `docs/development/telegram-po-gate-notification-specification.md` 第 27.4 節格式，示範第一個案例）

- Push attempted: NO
- Reason (if NO): Telegram env not configured locally（`NOTIFICATION_ENABLED`、`TELEGRAM_BOT_TOKEN`、`TELEGRAM_CHAT_ID`、`PROJECT_ID`、`PROJECT_NAME` 五項在本機 shell 環境中皆未設定——已逐一唯讀檢查，僅確認存在與否，未讀取任何實際值）
- Delivery status: not_attempted
- Push artifact path: （尚未產生，因未執行 `push-claude-report`）
- Notification history reference: reviews/notification_history.jsonl（本次未新增紀錄，因指令未執行）
- Manual command (供 Product Owner 在已設定好 Telegram 憑證的環境自行執行):

  ```bash
  PROJECT_ID=<PROJECT_ID> PROJECT_NAME=<PROJECT_NAME> NOTIFICATION_ENABLED=true \
    TELEGRAM_BOT_TOKEN=<TOKEN> TELEGRAM_CHAT_ID=<CHAT_ID> \
    ./scripts/review_bridge.sh push-claude-report sprint-018 001 fix \
    reviews/sprint-018/round-001/claude_fix_report_round_5.md
  ```

## 12. Not Done

1. 未修正 `codex_final_review_round_4.md` 的 Should Fix 2（report section parser 依賴英文 Markdown heading 的格式風險）——不在本輪 Must Fix 範圍。
2. 未修正舊有的 UX 文件章節編號交叉引用 Nit（`telegram-po-gate-notification-specification.md`/`codex_review_handoff_policy.md`/`gate_notification_matrix.md` 引用「第 6 節」應為「第 5 節」）——與本輪問題無關，維持 Round 4 的判斷，保留給後續輪次。
3. 未執行真實 Telegram live delivery——本環境仍未配置真實憑證（見第 11 節 Telegram Push Status，五項環境變數皆未設定），Product Owner 可在配置好真實憑證後，依第 11 節的 Manual command 執行，或讓 Claude Code 在下一輪報告完成時、於已配置好的環境中自動執行。

## 13. Product Owner Next Action

1. 審閱本規則是否符合預期：Claude Code 在「本機環境已具備 Telegram 設定」時親自執行 `push-claude-report`，「未具備」時不執行、且明確記錄。
2. 若要驗證 Round 5 實際效果，請在已設定好 `NOTIFICATION_ENABLED=true`/`TELEGRAM_BOT_TOKEN`/`TELEGRAM_CHAT_ID`/`PROJECT_ID`/`PROJECT_NAME` 的本機環境中，觸發下一輪 Claude Implementation 或 Must Fix，觀察 Claude Code 是否確實在完成報告後主動執行 `push-claude-report`、Product Owner 是否確實在未手動操作任何指令的情況下收到 Telegram 通知。
3. 決定是否授權重新送交 Codex 進行 Review（正式的 Codex Review Handoff 指令依 Independent Review Handoff Authority 原則，不得由本報告單獨決定，須依 `codex_review_handoff_policy.md` 準備）。
