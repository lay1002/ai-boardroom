# Claude Fix Report — Sprint-019 Must Fix Round 2

## 1. Summary

依 Product Owner 的 Sprint-019 Must Fix Round 2 指令，本輪處理兩項 Must Fix：

1. **Must Fix 1（已完全實作）**：Codex Handoff Package 拆成獨立、不混雜其他內容的 Telegram 訊息。
2. **Must Fix 2（Architecture 衝突已揭露，Product Owner 已裁決，CLI 替代方案已完整實作並收斂）**：Telegram 真實互動按鍵與已核准的 Sprint-019 Architecture Artifact（Section 4.2 Out of Scope）直接衝突——真實按鍵需要 Telegram callback 真實串接與長期接收程序，兩者皆為 Architecture 明確禁止項目。Claude Code 在上一輪揭露此衝突後，**Product Owner 已明確裁決**：本輪不新增真實 Telegram callback / webhook / polling listener，改用 `record-po-decision` CLI 作為安全替代方案，並要求補齊「approve 寫入 Approved Job Manifest、reject 只寫 audit event、`consume-approved` 只消費 approved 目錄且僅 dry-run」的完整閉環。本輪已依此裁決完整實作。

Scope Expansion: No——`record-po-decision` 與 `consume-approved` 都只使用 Sprint-019 既有的 Approved Job Manifest schema（Section 9）與既有 dry-run worker（Section 11），未新增新的 schema、新的 queue 目錄、新的 Telegram callback、新的 webhook、新的常駐程序。

## 2. Context Completeness Check

- Full required reading list provided: PASS
- Missing context files: 同 `claude_report.md` 第 15.3 節已揭露的兩項（Sprint-019 Architecture Definition 獨立檔案、Sprint-018 Retrospective / Actual Flow Report 獨立檔案）
- Did missing context affect implementation or review: NO
- Notes: 本輪重新閱讀 Architecture Section 4.2（Out of Scope）、Section 9（Approved Job Manifest Schema）、Section 11（Dry-run Worker Requirements），確認新增的 `record-po-decision --decision approve` 產生的 manifest 完全符合 Section 9 的必填欄位與固定安全值，`consume-approved` 完全重用 Section 11 既有的 dry-run 邏輯，未新增執行能力。

## 3. Must Fix 2：Architecture 衝突與 Product Owner 裁決

### 3.1 衝突回顧（上一輪已揭露）

| Architecture 條文 | 原文 |
|---|---|
| Section 4.2 Out of Scope 第 1 項 | 「不做 Telegram callback 真實串接。」 |
| Section 4.2 Out of Scope 第 9 項 | 「不讓 Telegram / LINE button 直接觸發 shell command。」 |
| Section 4.2 Out of Scope 第 10 項 | 「不做長期 worker daemon。」 |

真實 Telegram 按鍵需要接收 `callback_query` 的程序（webhook 或長輪詢），且該程序需隨時待命——分別對應上表第 1、10 項禁止事項。

### 3.2 Product Owner 裁決（本輪採用）

> Sprint-019 不在本輪新增真實 Telegram callback / webhook / polling listener。真實 Telegram button/callback UX 列為 Sprint-020 或後續 Sprint 的 Architecture Definition 項目。CLI 替代方案（`record-po-decision`）必須補足 Approved Execution Queue 的核心閉環：approve 寫入 approved manifest、reject 寫入 audit event、`consume-approved`（Product Owner 明確排除「timer」字面意義下的排程/常駐程序，見 3.3 節）只能消費 approved job，且僅 dry-run。

**明確聲明（中英文皆記錄，依 Product Owner 要求）**：

> Telegram true approve/reject buttons are deferred because they require Architecture Amendment. Sprint-019 uses `record-po-decision` CLI as the approved safe substitute.
>
> Sprint-019 本輪不實作真實 Telegram callback 按鍵。PO 同意/不同意改由 `record-po-decision` CLI 記錄。真實 Telegram 按鍵列入後續 Sprint Architecture Amendment。

（同一段聲明也已寫入 `docs/development/approved-execution-queue.md` 第 8 節與 `docs/development/product-owner-live-push-validation.md` 第 3.2 節。）

### 3.3 「timer / worker」的合規解讀（判斷依據需揭露）

Product Owner 指令中的流程圖寫「timer / worker dry-run consume approved job」。Architecture Section 4.2 第 10 項「不做長期 worker daemon」**從未被本輪裁決撤銷**——Product Owner 本輪裁決只撤銷了「Telegram callback」的絕對禁止（改為明確排除，見「明確排除」清單第 1-3 項仍然保留），未提及要撤銷「長期 daemon」的禁止。一個真正的「timer」（排程器、常駐輪詢程序）本質上就是被禁止的長期 worker daemon，不論它只做 dry-run 與否。

**Claude Code 的解讀**：`consume-approved` 實作為一個**人工手動觸發的一次性批次 CLI 指令**（掃描 `approved/` 底下全部 manifest，逐一 dry-run），而非排程器或常駐程序。若 Product Owner 未來想要「自動定期執行」，那是 repo 之外的基礎設施（例如作業系統的 cron 呼叫這個既有 CLI 指令），不屬於 Sprint-019 範圍，也不需要 Sprint-019 自己實作/常駐一個 Python 程序。此解讀已在 `scripts/test_approved_execution_queue.py` Test 43 明確驗證原始碼中不存在 `while True`、`schedule.`、`threading.Timer`、`apscheduler` 等常駐/排程跡象。若這個解讀不符合 Product Owner 的原意，請明確告知，Claude Code 會再依指示調整。

## 4. Must Fix 1：Codex Handoff Package 獨立成一則訊息（完全實作）

`scripts/approved_execution_queue.py` 新增 `_build_live_push_messages()`，把原本的單一長訊息拆成三則依序傳送、彼此不混雜的訊息：

- **Message 1**：Sprint/Round/Gate 資訊、目前狀態、Product Owner 現在要做什麼、下一個 AI 是誰、Product Owner 審核（`record-po-decision` 完整指令）、Safety Notice、Evidence Reference、Notification/Audit Reference。
- **Message 2**：**只**包含 `===== BEGIN COPY TO CODEX REVIEW =====` 到 `===== END COPY TO CODEX REVIEW =====` 之間的內容。
- **Message 3**：Evidence & Checklist（路徑、`consume-approved`／`confirm-live-push` 指令、checklist 路徑、PASS/FAIL 提醒）。

新增 `_SINGLE_MESSAGE_LIMIT = 3500` 安全上限：若 Handoff Package 本身超過此上限，`live-push` 直接失敗（Fail Loudly），不會默默切成兩則（實際內容約 1809 字元，遠低於上限）。寫入磁碟的 artifact 檔案以 `===== MESSAGE N: ... =====` 標記保留三則訊息的完整內容供事後稽核。

## 5. Must Fix 2 CLI 替代方案：完整閉環實作

### 5.1 `record-po-decision`（approve 寫入 manifest，reject 只寫 audit event）

```bash
# 同意：寫入 audit event，並產生一份有效的 Approved Job Manifest 到 approved/
python3 scripts/approved_execution_queue.py record-po-decision \
  --sprint-id sprint-019 --ref <job_id> --decision approve \
  --target-actor codex --job-type review \
  --allowed-action "Review Sprint-019 implementation and produce codex_review.md" \
  --input-artifact reviews/sprint-019/round-001/claude_report.md \
  --expected-output-artifact reviews/sprint-019/round-001/codex_review.md \
  --safety-level low

# 不同意：只寫入 audit event，不產生任何 manifest
python3 scripts/approved_execution_queue.py record-po-decision \
  --sprint-id sprint-019 --ref <job_id> --decision reject
```

行為：

- `approve`：寫入 `product_owner_decision_recorded` audit event，並在通過 `validate_approved_job()` 全部檢查後，把一份**固定安全欄位**（`dry_run_required: true`、`commit_allowed/push_allowed/closure_allowed/auto_handoff_allowed/shell_command_allowed: false`）的 Approved Job Manifest 寫入 `reviews/approved-execution-queue/approved/<ref>.md`，並額外寫入 `approved_job_manifest_created` audit event。若必要欄位缺漏（`--target-actor` 等 6 項），或產生的 manifest 未通過 validator，指令會 Fail Loudly（exit code 1），**不會**寫入任何檔案。
- `reject`：只寫入 `product_owner_decision_recorded` audit event（`status: reject`），**不建立任何檔案**——`approved/` 目錄不會出現對應項目，因此結構上不存在「rejected job 被誤消費」的可能。
- 兩者皆不執行 shell command、不呼叫 Claude/Codex CLI、不 commit/push/closure，僅供 Product Owner 本人執行。

### 5.2 `consume-approved`（只消費 approved，僅 dry-run）

```bash
python3 scripts/approved_execution_queue.py consume-approved
```

行為：掃描 `reviews/approved-execution-queue/approved/*.md`，對每一份逐一呼叫既有的 `cmd_dry_run()`（完全重用 Section 11 的驗證與模擬邏輯，未新增任何執行路徑）。結構上只讀 `APPROVED_DIR`，從不讀取 `REQUESTS_DIR`；rejected 決策從不產生檔案，因此天然不存在「消費到 pending 或 rejected job」的可能（見第 3.3 節「timer」語意澄清：這是人工觸發的一次性批次指令，不是排程器/daemon）。

## 6. Files Modified

- `scripts/approved_execution_queue.py`
  - `write_audit()` 現在回傳 `event_id`，供 `record-po-decision` 產生的 manifest 引用（`product_owner_decision_reference: audit_event:<id>`）。
  - `_build_live_push_messages()`：建構 Message 1/2/3；Message 1 內嵌完整、可直接複製的 `record-po-decision` approve/reject 指令。
  - `_SINGLE_MESSAGE_LIMIT` 常數與 Handoff Package 長度 Fail Loudly 檢查。
  - `cmd_record_po_decision()`：approve 分支寫入 Approved Job Manifest（含欄位完整性與 validator 檢查），reject 分支只寫 audit event。
  - `cmd_consume_approved()`：批次 dry-run `approved/` 目錄，人工觸發、非常駐程序。
  - `build_parser()`：新增 `record-po-decision` 的 6 個 approve-only 欄位、新增 `consume-approved` subcommand。
- `scripts/test_approved_execution_queue.py`：新增 Test 31-43（見第 8 節）。
- `docs/development/approved-execution-queue.md`：新增第 5a 節（決策記錄與 consume-approved 完整說明）、第 8 節補充中英文「按鍵延後」聲明。
- `docs/development/product-owner-live-push-validation.md`：新增 3.1 節（三則訊息說明）、3.2 節（CLI 替代按鍵聲明）。
- `reviews/sprint-019/round-001/claude_fix_report_round_2.md`（本檔案，取代前一版「待裁決」內容）
- `reviews/sprint-019/round-001/product_owner_live_push_validation_checklist.md`（新增本輪證據區塊）
- 新 notification artifact、`reviews/notification_history.jsonl`、`reviews/approved-execution-queue/audit/audit.jsonl`：待 Product Owner 執行第 10 節指令後產生（Claude Code 不持有 Telegram 憑證，不會代為送出）。

## 7. Test Commands Executed

```bash
python3 scripts/test_approved_execution_queue.py
bash scripts/test_approved_execution_queue.sh
```

## 8. Test Results

全部 **43 項**測試通過（原 30 項 + Round 2 累計新增 13 項）：

- Test 31-35：Codex Handoff Package 獨立成訊息、不混雜 PO Summary/Evidence/Metadata（同前一版）。
- Test 36：程式原始碼不含 `InlineKeyboard`/`reply_markup`/`callback_query`（無任何 callback 傳輸層存在）。
- Test 37：`approve` 寫入通過 `validate_approved_job()` 驗證的 manifest，且固定安全欄位（`commit_allowed` 等）皆為 `false`，並產生 `product_owner_decision_recorded` + `approved_job_manifest_created` 兩筆 audit event。
- Test 38：`reject` 不產生任何 manifest 檔案，只寫入 `product_owner_decision_recorded`（`status: reject`），且不出現 `approved_job_manifest_created`。
- Test 39：`approve` 缺少必要欄位時 Fail Loudly（exit code 非 0），不寫入任何檔案。
- Test 40：不合法的 `--decision` 值被拒絕，audit trail 不含任何 token 值。
- Test 41：`consume-approved` 只消費 `approved/` 目錄；即使 `requests/` 目錄內有檔案，也完全不被讀取或印出。
- Test 42：`consume-approved` 印出 `would-execute`（模擬結果），原始碼不含 `subprocess`/`os.system(`。
- Test 43：原始碼不含 `while True`/`schedule.`/`threading.Timer`/`apscheduler` 等排程/常駐程序跡象，佐證 `consume-approved` 是一次性 CLI 指令而非 daemon。

## 9. Known Limitations（誠實揭露）

1. 第 3.3 節的「timer」語意解讀（人工觸發的批次 CLI，而非排程器）是 Claude Code 在 Architecture 既有禁令下的合規判斷，若與 Product Owner 原意不符，需要另行明確指示。
2. `approval_request_id` 欄位使用合成參考值 `live-push:<ref>`（而非指向 `requests/` 底下一份實際存在的 Approval Request 檔案）——Sprint-019 的 Gate 驗收流程本身（live push → PO 審核）就是這裡的「請求」，並未另外產生一份獨立的 Approval Request markdown 檔案，這是本輪為求单一操作閉環刻意的簡化，已在此明確揭露，未隱藏。
3. `_chunk_message()` 的區塊切分假設以空行分隔——若 Message 1 或 Message 3 未來成長到單一區塊本身超過 3500 字元，會退回逐字元硬切；目前三則訊息實際長度都在安全範圍內。
4. Product Owner 仍需完成：親自在 Telegram 確認收到 3 則新訊息、執行 `record-po-decision`（可選）、執行 `confirm-live-push`、填寫 checklist PASS/FAIL。

## 10a. 本輪實際送出結果（Product Owner 已執行）

Product Owner 於自己的終端機執行 live-push（沿用既有 `--ref sprint-019-implementation-must-fix-1`，覆寫同一份 artifact 檔案為本輪新內容，而非第 10 節建議的新 ref——功能等價，唯一差別是 artifact 檔名未變）：

- Delivery status: **delivered**（3 則訊息全數送達）
- `notification_history.jsonl`：`created_at: 2026-07-09T14:30:16Z`, `delivered_at: 2026-07-09T14:30:19Z`
- Audit trail：`live_push_attempted`（`6c32bdaf-2ced-40c3-94f7-61231648b6f9`）→ `live_push_delivered`（`1f9acc86-7d4c-484a-b216-00769a960cc9`）
- Notification artifact：`reviews/sprint-019/round-001/notifications/sprint-019-implementation-must-fix-1-live-push.md`（內容已確認含 3 個 `MESSAGE N` 標記，對應本輪新格式）
- Token / credential 掃描：無外洩

## 10. 待 Product Owner 執行的 live-push 指令（本輪修正後，供參考）

```bash
NOTIFICATION_ENABLED=true TELEGRAM_BOT_TOKEN=<your-token> TELEGRAM_CHAT_ID=<your-chat-id> \
python3 scripts/approved_execution_queue.py live-push \
  --sprint-id sprint-019 --round round-001 \
  --ref sprint-019-implementation-must-fix-2 \
  --gate-type claude_implementation_report_acceptance \
  --target-actor product_owner \
  --risk-level low \
  --next-step "請審閱修正後三則推播內容，並視需要以 record-po-decision 記錄決策" \
  --artifact-path reviews/sprint-019/round-001/claude_report.md \
  --audit-reference reviews/approved-execution-queue/audit/audit.jsonl \
  --dry-run-status n/a
```

執行後應在 Telegram 依序收到 3 則獨立訊息（Summary / Codex Handoff Package / Evidence & Checklist）。

## 11. Product Owner Validation Notes

在 Product Owner 完成以下事項之前，Product Owner Validation 不得判定 PASS：

1. 執行第 10 節指令，確認 `delivery_status=delivered`。
2. 確認實際在 Telegram 收到 3 則獨立訊息，且第 2 則只包含可複製的 Codex Handoff Package。
3. 確認第 3.3 節「timer」的合規解讀是否符合原意（一次性 CLI 批次指令，非排程器/daemon）。
4. 視需要執行 `record-po-decision`（approve/reject）與 `consume-approved`，確認 approved manifest / dry-run report 產出符合預期。
5. 執行 `confirm-live-push` 指令。
6. 完成 `reviews/sprint-019/round-001/product_owner_live_push_validation_checklist.md` 並填寫 PASS/FAIL。

在此之前，本 Sprint 不得進入 Codex Git Review、不得 Commit、不得 Push、不得 Closure。
