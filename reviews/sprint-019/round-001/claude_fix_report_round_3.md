# Claude Fix Report — Sprint-019 Must Fix Round 3

## 1. Summary

Product Owner 確認 Round 2 的 Telegram live push 內容(3 則訊息、繁體中文、Codex Handoff Package 獨立可複製)已符合驗收要求，並確認接受 CLI 替代 Telegram 真實按鈕（`record-po-decision`），因為 Sprint-019 已核准 Architecture 不支援 Telegram callback / webhook / polling listener。Product Owner 進一步要求驗證並補強核心閉環：`record-po-decision approve` → 產生 approved manifest（含 Codex Handoff 指令檔參照）→ audit trail 記錄 → `consume-approved` 只消費 approved job。

比對現有實作與 Product Owner 這次列出的具體欄位要求（`next_ai`、`handoff_package_path`、`source_artifact_path`、`audit_reference`、`status`）後，發現 Round 2 的 manifest **缺少**這些欄位，且 Codex Handoff Package 當時只存在於合併的 notification artifact 內，**沒有獨立檔案**可供 manifest 引用。本輪據實修正這兩項缺口，不隱藏落差。

Scope Expansion: No——新增欄位皆為描述性補充（見第 4 節），未新增 Architecture Section 9 之外的必填規則，未新增新的 queue 目錄，未新增 Telegram callback。

## 2. Context Completeness Check

- Full required reading list provided: PASS
- Missing context files: 同前兩輪已揭露的兩項
- Did missing context affect implementation or review: NO
- Notes: 重新比對 Architecture Section 9（Approved Job Manifest 必填欄位）與 `FORBIDDEN_FIELD_NAMES`，確認新增欄位不與任何禁止欄位名稱衝突，也不影響任何既有驗證規則。

## 3. 逐項確認（依 Product Owner 第 1-10 項要求）

### 3.1 approve CLI 指令

```bash
python3 scripts/approved_execution_queue.py record-po-decision \
  --sprint-id sprint-019 --ref <job_id> --decision approve \
  --target-actor codex --job-type review \
  --allowed-action "Review Sprint-019 implementation and produce codex_review.md" \
  --input-artifact reviews/sprint-019/round-001/claude_report.md \
  --expected-output-artifact reviews/sprint-019/round-001/codex_review.md \
  --safety-level low \
  --handoff-package-path reviews/sprint-019/round-001/notifications/<ref>-codex-handoff.md
```

此指令現已完整內嵌在 live-push 的 Telegram Message 1（「🗳️ Product Owner 審核」區塊），`--handoff-package-path` 的值會自動指向 live-push 剛寫入的實際檔案路徑，Product Owner 不需要自己拼路徑。

### 3.2 reject CLI 指令

```bash
python3 scripts/approved_execution_queue.py record-po-decision \
  --sprint-id sprint-019 --ref <job_id> --decision reject
```

不需要、也不接受任何其他欄位——傳入多餘欄位會被忽略，因為 reject 分支在寫入 audit event 後立即回傳，不進入 manifest 組裝邏輯。

### 3.3 approve 後產生的 approved manifest 檔案

`reviews/approved-execution-queue/approved/<safe_ref>.md`（`safe_ref` 是 `--ref` 經過 `[^A-Za-z0-9_-]` 過濾後的檔名安全版本）。

### 3.4 approved manifest 是否引用獨立 Codex Handoff Package 檔案

**是（本輪新增）**。`live-push` 執行時，除了原本的合併 notification artifact，現在**額外**把 Telegram Message 2（Codex Handoff Package 原文，逐位元組相同）寫入獨立檔案 `reviews/<sprint>/<round>/notifications/<ref>-codex-handoff.md`。`record-po-decision --decision approve` 的 `--handoff-package-path` 必須指向這份檔案（不存在會直接失敗，見 Test 45），並把它記錄進 manifest 的 `handoff_package_path` 欄位。

### 3.5 approved manifest 是否包含 next_ai / target_actor / handoff_package_path / source_artifact_path / audit_reference / status

**現在全部包含**（Round 2 只有 `target_actor`，其餘五項本輪新增）：

| 欄位 | 值來源 |
|---|---|
| `target_actor` | `--target-actor`（Architecture Section 9 必填，白名單檢查） |
| `next_ai` | 由 `target_actor` 自動映射的人類可讀名稱（`codex` → `Codex Review`），避免手動填寫與 `target_actor` 不一致 |
| `handoff_package_path` | `--handoff-package-path`（執行前驗證檔案存在） |
| `source_artifact_path` | 與 `input_artifact` 相同值（Product Owner 要求的明確欄位名） |
| `audit_reference` | 固定為 `reviews/approved-execution-queue/audit/audit.jsonl` 實際路徑 |
| `status` | 固定為 `approved`（manifest 只在 approve 分支才會被寫入，因此恆為此值） |

### 3.6 approve audit event 路徑與 event name

- 路徑：`reviews/approved-execution-queue/audit/audit.jsonl`
- 兩筆事件：`product_owner_decision_recorded`（`status: approve`）、`approved_job_manifest_created`（`status: created`，`request_id` 帶 `approval_request_id` 值）

### 3.7 reject audit event 路徑與 event name

- 路徑：同上 `reviews/approved-execution-queue/audit/audit.jsonl`
- 一筆事件：`product_owner_decision_recorded`（`status: reject`）。**不會**出現 `approved_job_manifest_created`。

### 3.8 consume-approved 如何只消費 approved job

`cmd_consume_approved()` 只呼叫 `APPROVED_DIR.glob("*.md")`（`APPROVED_DIR` 固定指向 `reviews/approved-execution-queue/approved/`），程式碼中**沒有任何一處**讀取 `REQUESTS_DIR`。`reject` 決策從不產生檔案，所以 `approved/` 目錄裡永遠不會出現「被拒絕的 job」——結構上不存在可以被誤消費的 pending 或 rejected 檔案（Test 41 額外驗證：即使故意在 `requests/` 放一個檔案，`consume-approved` 的輸出完全不提及它）。

### 3.9 consume-approved 是否仍為 dry-run，不呼叫真實 CLI

是。`cmd_consume_approved()` 對每個檔案呼叫既有的 `cmd_dry_run()`（未新增任何執行路徑），輸出固定是 `would-execute`（模擬）或 `blocked`。程式原始碼不含 `subprocess`、`os.system(`、`os.popen(`、`eval(`、`exec(`（Test 30、42 靜態驗證），也不含任何排程/常駐程序跡象（`while True`、`schedule.`、`threading.Timer`、`apscheduler`，Test 43 驗證）。

### 3.10 相關測試是否通過

全部 **46 項**測試通過（Round 1 的 30 + Round 2 的 13 + 本輪新增 3 項：Test 44-46）。詳見第 6 節。

## 4. Files Modified

- `scripts/approved_execution_queue.py`
  - 新增 `_TARGET_ACTOR_DISPLAY_NAMES` 映射（`target_actor` → `next_ai` 人類可讀名稱）。
  - `cmd_live_push()`：額外寫入獨立 Codex Handoff 檔案（`<ref>-codex-handoff.md`），並在合併 artifact 的 front matter 加入 `handoff_package_path` 供事後稽核比對。
  - `_build_live_push_messages()`：簽名新增 `handoff_path` 參數，approve 指令範本內嵌 `--handoff-package-path`。
  - `cmd_record_po_decision()`：approve 分支新增 `--handoff-package-path` 必要欄位檢查（含檔案存在性檢查）與 5 個補充 manifest 欄位（`next_ai`/`handoff_package_path`/`source_artifact_path`/`audit_reference`/`status`）。
  - `build_parser()`：新增 `--handoff-package-path` CLI 參數。
- `scripts/test_approved_execution_queue.py`：新增 Test 44-46，並更新 `approve_argv()` fixture（新增 `--handoff-package-path`）、`_live_push_messages()` helper（同步新簽名）、Test 37 補充欄位斷言。
- `docs/development/approved-execution-queue.md`：第 5a 節新增 5a.1 子節，說明補充欄位與獨立 handoff 檔案機制。
- `docs/development/approved-job-manifest-schema.md`：新增第 10 節，明確區分「Architecture 必填欄位」與「Sprint-019 Round 3 補充欄位」，避免混淆兩者的權威性。
- `reviews/sprint-019/round-001/claude_fix_report_round_3.md`（本檔案）

## 5. Test Commands Executed

```bash
python3 scripts/test_approved_execution_queue.py
bash scripts/test_approved_execution_queue.sh
```

## 6. Test Results

全部 **46 項**測試通過：

- Test 37（更新）：額外驗證 approve 產生的 manifest 包含 `next_ai=Codex Review`、`handoff_package_path` 非空、`source_artifact_path == input_artifact`、`audit_reference` 含 `audit.jsonl`、`status == approved`。
- Test 44：`live-push` 產生的獨立 handoff 檔案存在、有正確 BEGIN/END 標記，且與 Telegram Message 2 逐位元組相同。
- Test 45：`--handoff-package-path` 指向不存在的檔案時，approve 直接失敗（exit code 非 0），不寫入任何 manifest。
- Test 46：完整閉環端對端測試——`live-push` 產生 handoff 檔案 → `record-po-decision approve` 引用該檔案並成功產生 manifest → `consume-approved` 成功消費並輸出 `would-execute`。

本機另以真實 CLI（非測試框架）手動跑過一次完整閉環（`live-push` → 複製 Telegram Message 1 印出的 approve 指令直接執行 → 檢查 manifest 內容 → `consume-approved`），確認實際指令與測試斷言的行為一致（見對話中的手動驗證輸出）。

## 7. Safety Boundary Confirmation（與前兩輪一致，未新增例外）

- 不執行 shell command、不呼叫 Claude/Codex CLI：`consume-approved` 完全重用既有 `cmd_dry_run()`，未新增執行路徑。
- 不 commit/push/closure：manifest 六個固定安全欄位邏輯未變。
- 不新增 Telegram callback：新增的 `--handoff-package-path` 只是一個本機檔案路徑參數，與網路/callback 無關。
- Token/credential 未寫入 repo：本輪新增欄位（`audit_reference` 等）皆為路徑或描述文字，已用 `grep` 掃描確認無 token-like 字串混入 manifest 或 audit trail。

## 8. Known Limitations

1. `next_ai` 由固定映射表 `_TARGET_ACTOR_DISPLAY_NAMES` 推導，只涵蓋 Architecture Section 9 的 4 個 `target_actor` 白名單值——若未來白名單擴充，需同步更新此映射表（否則會 fallback 顯示原始 `target_actor` 值，不會出錯，但可讀性較差）。
2. `handoff_package_path` 檔案存在性檢查只確認檔案存在，不驗證內容是否確實包含 `BEGIN/END COPY TO CODEX REVIEW` 標記——若 Product Owner 手動指向一個無關檔案，approve 仍會成功（這是刻意的最小驗證，避免過度設計；Product Owner 若發現有必要，可再要求加強）。

## 9. Product Owner Validation Notes

第 3 節已逐項回答 Product Owner 提出的 10 個確認項目。在 Product Owner 完成以下事項之前，Product Owner Validation 不得判定 PASS：

1. 確認第 3 節逐項回覆是否滿足要求。
2. 確認 `next_ai`/`handoff_package_path`/`source_artifact_path`/`audit_reference`/`status` 欄位設計是否符合原意。
3. 執行 `confirm-live-push` 指令。
4. 完成 `reviews/sprint-019/round-001/product_owner_live_push_validation_checklist.md` 並填寫 PASS/FAIL。

在此之前，本 Sprint 不得進入 Codex Git Review、不得 Commit、不得 Push、不得 Closure。
