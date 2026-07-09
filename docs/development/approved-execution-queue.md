# Approved Execution Queue（Sprint-019）

## 1. 這是什麼

Approved Execution Queue 是 AI Workspace 在 Sprint-019 建立的一個**檔案式、可稽核**的安全補強機制，讓「Product Owner 核准」與「實際執行」之間，永遠隔著一層**只會產生描述、不會真實執行任何動作**的 validator 與 dry-run worker。

它不是完整 automation platform，不是 workflow engine，也不是 AI Decision Assistant 主產品功能。它只是 AI Workspace 在 Sprint-020 收斂為 Workflow v1.0 之前的流程安全補強。完整範圍定義見 [reviews/sprint-019/round-001/architecture.md](../../reviews/sprint-019/round-001/architecture.md)。

## 2. Queue Directory Structure

```
reviews/approved-execution-queue/
├── requests/    # Approval Request 草稿。不得被 worker 當作 approved job。
├── approved/    # 只存放 Product Owner 明確核准後的 Approved Job Manifest。
├── dry-run/     # 只存放 dry-run worker 的模擬執行報告，不得存放真實執行結果。
└── audit/       # append-only audit trail（audit.jsonl）。
```

基本規則：

1. `requests/` 內檔案不得被執行。
2. `approved/` 內 manifest 必須有 Product Owner approval metadata。
3. `dry-run/` 只能記錄模擬執行。
4. `audit/` 必須 append-only，不得覆寫既有紀錄。
5. 任一檔案不得包含 secret、token、credential。

## 3. Approval Request 與 Approved Job Manifest 的差異

| | Approval Request | Approved Job Manifest |
|---|---|---|
| 意義 | 「請求核准」 | 「已核准」的資料描述 |
| 存放位置 | `requests/` | `approved/` |
| 誰建立 | 任何提出需求的角色 | 只有 Product Owner 核准後才可能存在 |
| 是否可被 dry-run | 否（validator 與 dry-run worker 都會拒絕） | 是（唯一可被 dry-run 的檔案） |
| 詳細欄位 | 見 [approval-request-schema.md](approval-request-schema.md) | 見 [approved-job-manifest-schema.md](approved-job-manifest-schema.md) |

Approval Request **不是**已核准的執行憑證；Approved Job Manifest **不是** shell script，也不是 command wrapper——它是一段描述「Product Owner 核准了什麼」的資料，且固定要求 `dry_run_required: true`、`commit_allowed: false`、`push_allowed: false`、`closure_allowed: false`、`auto_handoff_allowed: false`、`shell_command_allowed: false`。

## 4. Validator

實作於 `scripts/approved_execution_queue.py`。安全規則詳見 [approved-execution-validator.md](approved-execution-validator.md)。

```bash
python scripts/approved_execution_queue.py validate-request <path>
python scripts/approved_execution_queue.py validate-approved-job <path>
```

Validator 只做驗證與回報，永遠不會執行 shell command、呼叫 Claude/Codex CLI、commit、push、closure，也不會自動建立 approved job 或自動呼叫下一個 AI。

## 5. Dry-run Worker

```bash
python scripts/approved_execution_queue.py dry-run <path>
```

流程：讀取 Approved Job Manifest → 執行 validator → 依結果寫出 `blocked` 或 `would-execute` 的 dry-run report 到 `reviews/approved-execution-queue/dry-run/` → 寫入 audit record。

若輸入檔案是 Approval Request（而非 Approved Job Manifest），dry-run worker 會直接拒絕處理，並記錄 `dry_run_blocked` 事件——這是 Architecture 明訂的安全邊界：Approval Request 永遠不能被當成 approved job 執行。

Dry-run worker 不會呼叫 Claude CLI、Codex CLI，不會執行任何 shell command，不會 commit / push / closure，也不會 auto handoff / auto approval。

## 5a. Product Owner 決策記錄與 consume-approved（Sprint-019 Must Fix Round 2）

Product Owner 曾要求在 Telegram live push 中加入「同意/不同意」互動按鍵。真實 Telegram 按鍵需要一個接收 `callback_query` 的程序（webhook 或長輪詢），這正是 Architecture Section 4.2 明確禁止的「Telegram callback 真實串接」，且該接收程序本身若要隨時待命，也會構成同樣被禁止的「長期 worker daemon」。因此 Sprint-019 不實作真實按鍵，改以下列 CLI 指令作為功能對等、且完全符合 Architecture 的替代方案：

```bash
# 同意：寫入 audit event，並產生一份有效的 Approved Job Manifest 到 approved/
python scripts/approved_execution_queue.py record-po-decision \
  --sprint-id <id> --ref <job_id> --decision approve \
  --target-actor <actor> --job-type <type> --allowed-action "<描述>" \
  --input-artifact <path> --expected-output-artifact <reviews/ 底下的路徑> \
  --safety-level <low|medium|high> \
  --handoff-package-path <live-push 產生的獨立 Codex Handoff 檔案路徑>

# 不同意：只寫入 audit event，不產生任何 manifest
python scripts/approved_execution_queue.py record-po-decision \
  --sprint-id <id> --ref <job_id> --decision reject
```

### 5a.1 Approved Job Manifest 的補充欄位（Sprint-019 Must Fix Round 3）

Product Owner 要求 approve 產生的 manifest 能追溯到獨立的 Codex Handoff Package 檔案與更多上下文。`live-push` 執行時，除了原本合併的 notification artifact，現在**也會**把 Codex Handoff Package（Telegram Message 2 的原文，逐位元組相同）額外寫入一份獨立檔案：`reviews/<sprint>/<round>/notifications/<ref>-codex-handoff.md`。`record-po-decision --decision approve` 必須以 `--handoff-package-path` 指向這份既存檔案（不存在會直接失敗），並在 manifest 中新增以下**補充欄位**（非 Architecture Section 9 必填欄位，純粹描述性、不影響 validator 判定）：

| 欄位 | 說明 |
|---|---|
| `next_ai` | 由 `target_actor` 自動對應的人類可讀名稱（例如 `codex` → `Codex Review`），避免與 `target_actor` 手動填寫產生不一致 |
| `handoff_package_path` | 獨立 Codex Handoff Package 檔案路徑（`--handoff-package-path` 提供，執行前會驗證檔案存在） |
| `source_artifact_path` | 與 `input_artifact` 相同值，提供 Product Owner 要求的明確欄位名 |
| `audit_reference` | `reviews/approved-execution-queue/audit/audit.jsonl` 的實際路徑 |
| `status` | 固定為 `approved`（manifest 只在 approve 時才會被寫入，因此永遠是這個值） |

這些欄位不在 `FORBIDDEN_FIELD_NAMES` 之列，`validate_approved_job()` 不會因為它們的存在或內容而拒絕 manifest。

兩者皆不執行 shell command、不呼叫 Claude/Codex CLI、不 commit/push/closure，且僅供 Product Owner 本人執行（Claude Code / Codex 不得代為呼叫）。

```bash
# 批次 dry-run approved/ 底下的每一份 manifest（人工手動執行，不是排程/常駐程序）
python scripts/approved_execution_queue.py consume-approved
```

`consume-approved` 只讀取 `approved/`，永遠不會讀取 `requests/`；`reject` 決策從不產生任何檔案，因此結構上不存在「消費到 pending 或 rejected job」的可能。它只呼叫既有的 dry-run 邏輯，永遠不會真實執行 Claude CLI / Codex CLI。真實 Telegram 互動按鍵已列為未來 Sprint 的 Architecture Amendment 候選項目，Sprint-019 本輪不實作。

## 6. Audit Trail

Append-only JSONL，路徑：`reviews/approved-execution-queue/audit/audit.jsonl`。每筆記錄包含 `event_id / event_type / project_id / sprint_id / job_id / request_id / actor / status / artifact_path / created_at`。記錄的事件涵蓋 request/manifest 建立、validator 執行結果、dry-run 執行結果，以及 live push 的嘗試 / 送達 / 失敗 / Product Owner 親自確認。Audit Trail 不記錄 secret、token、credential。

## 7. Mandatory Live Push Validation

Sprint-019 的硬性驗收條件——Product Owner 必須實際收到 workflow-generated live push，且 `reviews/notification_history.jsonl` 記錄 `delivery_status=delivered`——完整說明見 [product-owner-live-push-validation.md](product-owner-live-push-validation.md)。**`delivery_status=disabled` 不足以通過 Sprint-019 驗收**，只能作為診斷 evidence。

## 8. 安全邊界（重申）

- 不做 Telegram / LINE callback 真實串接；不讓 callback 觸發 shell command。
- 不做真實 Claude CLI / Codex CLI 自動執行。
- 不做 commit / push automation；不做 Sprint closure automation。
- 不做長期 worker daemon / 排程器；`consume-approved` 是人工觸發的一次性批次指令。
- 不修改 `configs/n8n/*.json`。
- 本模組（`scripts/approved_execution_queue.py`）不引入 `subprocess`、`os.system`、`os.popen`、`eval`、`exec` 等任何可執行外部指令的能力，也不引入任何 Telegram callback/webhook/inline keyboard 相關程式碼（`InlineKeyboard`、`reply_markup`、`callback_query`）——這點由 `scripts/test_approved_execution_queue.py` 的第 19-21、28-30、36、43 項測試直接驗證。

Telegram true approve/reject buttons are deferred because they require Architecture Amendment. Sprint-019 uses the `record-po-decision` CLI as the approved safe substitute.

Sprint-019 本輪不實作真實 Telegram callback 按鍵。PO 同意/不同意改由 `record-po-decision` CLI 記錄。真實 Telegram 按鍵列入後續 Sprint Architecture Amendment。
