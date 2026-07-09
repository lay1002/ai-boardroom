# Claude Fix Report — Sprint-019 Codex Review Must Fix (Round 4)

## 1. Summary

Codex Review 判定 MUST FIX：Product Owner 實際收到並確認的 live push（`sprint-019-implementation-must-fix-1-live-push.md`）是 **Round 2 版本**，不含 Round 3 才新增的 `--handoff-package-path` 與獨立 `*-codex-handoff.md` 檔案——因為 Round 3 只修改了程式碼與文件，**沒有重新執行 live-push**，Product Owner 當時確認收到的是舊內容。已用檔案時間戳確認此發現屬實（artifact `22:30`，Round 3 程式碼修改 `22:43`，前者早於後者）。

本輪重新產生新 ref（`sprint-019-implementation-must-fix-4`）的 live-push artifact，不覆寫任何舊 artifact；補上 Codex Review 明確要求的 2 項測試缺口（approve 指令是否內嵌 `--handoff-package-path`、artifact front matter 是否包含 `handoff_package_path`）。

Scope Expansion: No——沒有修改程式邏輯本身（Round 3 的程式碼已經正確），只是重新執行既有指令產生新證據，並補測試覆蓋。

## 2. Context Completeness Check

- Full required reading list provided: PASS
- Missing context files: 同前幾輪已揭露的兩項
- Did missing context affect implementation or review: NO
- Notes: 本輪額外確認 `scripts/approved_execution_queue.py` 與 `sprint-019-implementation-must-fix-1-live-push.md` 的檔案時間戳記，佐證 Codex 的發現。

## 3. 根因

Round 3 修改了 `cmd_live_push()`（新增獨立 handoff 檔案寫入、approve 指令範本新增 `--handoff-package-path`）與 `cmd_record_po_decision()`（approve 新增必填欄位與 manifest 補充欄位），但 Round 3 的驗證只用**本機暫存目錄**（`REVIEWS_OVERRIDE`）跑過端對端流程，**沒有針對 Sprint-019 真實 live-push artifact 重新執行 `live-push` 指令**。Product Owner 因此看到的、確認收到的、拿去對照 Round 3 回覆的，其實是 Round 2 時期產生的舊 artifact——內容與 Round 3 程式碼描述的行為不一致。

## 4. 修正內容

### 4.1 新 ref 的 live-push artifact

```bash
python3 scripts/approved_execution_queue.py live-push \
  --sprint-id sprint-019 --round round-001 --ref sprint-019-implementation-must-fix-4 \
  --gate-type claude_implementation_report_acceptance --target-actor product_owner \
  --risk-level low \
  --next-step "請審閱 Round 3 完整閉環後的推播內容（含 handoff_package_path），並視需要以 record-po-decision 記錄決策" \
  --artifact-path reviews/sprint-019/round-001/claude_report.md \
  --audit-reference reviews/approved-execution-queue/audit/audit.jsonl \
  --dry-run-status n/a
```

Claude Code 在本機（無 Telegram 憑證環境）執行過一次以產生並驗證 artifact 內容，結果為 `delivery_status=disabled`（見第 6 節）——**這不是最終送達結果**，Product Owner 仍需在自己的環境用真實憑證重新執行同一指令才能拿到 `delivered` 記錄（第 9 節）。舊 artifact（`sprint-019-implementation-live-push.md`、`sprint-019-implementation-must-fix-1-live-push.md`）完全未被覆寫或刪除。

### 4.2 驗證結果（本機產生的新 artifact）

- 新 artifact：`reviews/sprint-019/round-001/notifications/sprint-019-implementation-must-fix-4-live-push.md`
- 新獨立 handoff 檔：`reviews/sprint-019/round-001/notifications/sprint-019-implementation-must-fix-4-codex-handoff.md`
- Telegram Message 1 的 approve 指令**已包含** `--handoff-package-path /home/ivan/AI/reviews/sprint-019/round-001/notifications/sprint-019-implementation-must-fix-4-codex-handoff.md`
- artifact YAML front matter**已包含** `handoff_package_path` 欄位，值與上述獨立 handoff 檔案路徑一致
- 獨立 handoff 檔案內容與 Telegram Message 2 逐位元組相同（已用 Python 直接比對確認 `match: True`）

### 4.3 新增測試（Codex Review 要求的補測項目 2、3）

- Test 47：`_build_live_push_messages()` 產生的 Message 1 必須包含 `--handoff-package-path` 字串。
- Test 48：`live-push` 寫入的 artifact，其 YAML front matter 必須包含 `handoff_package_path` 鍵，且指向的檔案必須實際存在。

其餘 Codex 要求的補測項目（1、4-10）已由 Round 3 的 Test 44-46 與既有 Test 30/42/43 涵蓋（見第 6 節逐項對照）。

## 5. Files Modified

- `scripts/test_approved_execution_queue.py`：新增 Test 47-48。
- `reviews/sprint-019/round-001/notifications/sprint-019-implementation-must-fix-4-live-push.md`（新增，Claude Code 本機產生，`delivery_status=disabled`）
- `reviews/sprint-019/round-001/notifications/sprint-019-implementation-must-fix-4-codex-handoff.md`（新增，獨立 handoff 檔）
- `reviews/notification_history.jsonl`（新增一筆 `disabled` 記錄，append-only，見第 6 節）
- `reviews/approved-execution-queue/audit/audit.jsonl`（新增 `live_push_attempted` → `live_push_failed`(status=disabled) 配對，append-only）
- `reviews/sprint-019/round-001/claude_fix_report_round_4.md`（本檔案）
- `reviews/sprint-019/round-001/product_owner_live_push_validation_checklist.md`（新增 Round 4 Amendment，明確標註 Round 3 確認的 evidence 已過期，見第 8 節）

**未修改** `scripts/approved_execution_queue.py` 本身——Round 3 的程式邏輯是正確的，問題純粹是「沒有針對它重新產生 evidence」，因此本輪不需要改動程式碼行為。

## 6. Test Results

全部 **48 項**測試通過（Round 1-3 的 46 項 + 本輪新增 2 項）：

```bash
python3 scripts/test_approved_execution_queue.py   # Ran 48 tests ... OK
bash scripts/test_approved_execution_queue.sh      # Ran 48 tests ... OK
```

Codex Review「必須補測」10 項逐一對照：

| # | 要求 | 對應測試 |
|---|---|---|
| 1 | live-push 產生獨立 `*-codex-handoff.md` | Test 44 |
| 2 | approve 指令包含 `--handoff-package-path` | **Test 47（本輪新增）** |
| 3 | front matter 包含 `handoff_package_path` | **Test 48（本輪新增）** |
| 4 | approve 缺 `--handoff-package-path` 時 fail loudly | Test 45 |
| 5 | 用印出的完整指令可成功寫入 manifest | Test 46（端對端） |
| 6 | manifest 的 `handoff_package_path` 指向存在的檔案 | Test 46 |
| 7 | codex-handoff 檔與 Message 2 逐位元組一致 | Test 44 |
| 8 | consume-approved 僅 dry-run，不呼叫真實 CLI | Test 30, 42 |
| 9 | 不得產生 daemon/scheduler/cron/systemd timer | Test 43 |
| 10 | token/credential 不得寫入 repo | Test 23, 40（另見第 10 節手動掃描） |

## 7. Safety Boundary Confirmation

與前四輪一致：不執行 shell command、不呼叫 Claude/Codex CLI、不 commit/push/closure、不修改 `configs/n8n/*.json`、不修改 `scripts/review_bridge.sh`。本輪未新增任何執行能力，僅重新產生 evidence 與補測試。

## 8. Checklist Amendment（誠實揭露，未假裝舊確認仍然有效）

`product_owner_live_push_validation_checklist.md` 已新增 Round 4 Amendment 區塊，明確記載：Product Owner 先前確認並填寫 PASS 所依據的 `sprint-019-implementation-must-fix-1-live-push.md` **不含** Round 3 的 `handoff_package_path` 閉環，該次確認的 evidence 已過期；Product Owner 需要針對新 ref（`sprint-019-implementation-must-fix-4`）的推播重新確認並重新決定 PASS/FAIL，才能視為當前有效。原有 PASS 記錄予以保留（不刪除歷史），但標註為「基於已過期 evidence，需重新確認」。

## 9. Product Owner 需要執行的指令

### 9.1 重新送出 live-push（使用真實 Telegram 憑證）

```bash
NOTIFICATION_ENABLED=true TELEGRAM_BOT_TOKEN=<你的TOKEN> TELEGRAM_CHAT_ID=<你的CHAT_ID> \
python3 scripts/approved_execution_queue.py live-push \
  --sprint-id sprint-019 --round round-001 --ref sprint-019-implementation-must-fix-4 \
  --gate-type claude_implementation_report_acceptance --target-actor product_owner \
  --risk-level low \
  --next-step "請審閱 Round 3 完整閉環後的推播內容（含 handoff_package_path），並視需要以 record-po-decision 記錄決策" \
  --artifact-path reviews/sprint-019/round-001/claude_report.md \
  --audit-reference reviews/approved-execution-queue/audit/audit.jsonl \
  --dry-run-status n/a
```

（會覆寫 Claude Code 剛才本機產生的 `disabled` 版本 artifact 檔案內容，但 `notification_history.jsonl` 與 `audit.jsonl` 會新增一筆新記錄，append-only，不影響先前紀錄。）

### 9.2 確認新推播後執行

```bash
python3 scripts/approved_execution_queue.py confirm-live-push \
  --sprint-id sprint-019 --ref sprint-019-implementation-must-fix-4 \
  reviews/sprint-019/round-001/notifications/sprint-019-implementation-must-fix-4-live-push.md
```

### 9.3 重新填寫 checklist

確認 Telegram 實際收到的 3 則訊息中，approve 指令包含 `--handoff-package-path`，並在 `product_owner_live_push_validation_checklist.md` 的 Round 4 Amendment 區塊重新勾選/填寫決策。

## 10. Token / Credential 掃描結果

```bash
grep -rE "[0-9]{6,}:[A-Za-z0-9_-]{25,}" reviews/sprint-019/ reviews/approved-execution-queue/ scripts/approved_execution_queue.py scripts/test_approved_execution_queue.py
```

結果：無匹配（none found）。

## 11. Product Owner Validation Notes

在 Product Owner 完成以下事項之前，Product Owner Validation 不得判定 PASS：

1. 執行第 9.1 節指令，確認 `delivery_status=delivered`。
2. 確認 Telegram 收到的 approve 指令包含 `--handoff-package-path`。
3. 執行第 9.2 節 `confirm-live-push`。
4. 重新填寫 checklist 的 Round 4 Amendment 區塊。
5. 交回 Codex Review 確認本輪 Must Fix 已修正。

在此之前，本 Sprint 不得進入 Codex Git Review、不得 Commit、不得 Push、不得 Closure、不得自動呼叫 Codex。
