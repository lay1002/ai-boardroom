# Sprint Retrospective

Sprint: sprint-019
Round: round-001
Sprint Name: Product Owner Approved Execution Queue MVP

## 1. Objective

Sprint-019 的目標是建立一個安全、檔案式、可稽核的 Product Owner Approved Execution Queue MVP，作為 AI Workspace 在 Sprint-020 收斂為 Workflow v1.0 之前的流程安全補強——不是完整 automation platform，不是 workflow engine，不是 AI Decision Assistant 主產品功能。

核心驗收要求（Architecture Artifact 第 3 節）：Product Owner 必須在 Sprint-019 workflow 內**實際收到** live push，且 `reviews/notification_history.jsonl` 記錄 `delivery_status=delivered`，否則不得進入 Git Review / Commit / Push / Closure。

**實際完成內容**：

1. Approval Request Schema（`docs/development/approval-request-schema.md`）
2. Approved Job Manifest Schema（`docs/development/approved-job-manifest-schema.md`，含 Round 3 新增的 5 個補充欄位）
3. Queue Directory Structure（`reviews/approved-execution-queue/{requests,approved,dry-run,audit}/`）
4. Validator（`scripts/approved_execution_queue.py` 的 `validate-request` / `validate-approved-job`）
5. Dry-run Worker（`dry-run` 單檔案 + `consume-approved` 批次消費 `approved/`）
6. Audit Trail（append-only `reviews/approved-execution-queue/audit/audit.jsonl`）
7. Mandatory Live Push Validation（`live-push` / `confirm-live-push`，繁體中文、3 則獨立訊息、Codex Handoff Package 可直接複製）
8. Product Owner 決策記錄機制（`record-po-decision`，approve/reject 的 CLI 替代方案，取代原本要求的 Telegram 真實按鍵）
9. Product Owner Live Push Validation Checklist（含 4 輪 Amendment 歷程）
10. 48 項自動化測試（`scripts/test_approved_execution_queue.py`），全數通過

Definition of Done 第 1-15 項（架構第 26 節）皆已達成；第 16-19 項（Commit/Push/Closure）狀態見第 7、8 節。

## 2. Root Cause（各輪 Must Fix 的根因與修正）

### 2.1 Product Owner Live Push Validation：初次 FAIL → Must Fix Round 1

**根因**：第一次 live push 內容是純英文、扁平欄位列表（`Sprint ID: ... / Job/Request ID: ...`），沒有中文化、沒有 Handoff Package，不符合 Product Owner 對既有 Telegram Gate Notification（`telegram-po-gate-notification-specification.md`）已建立的 UX 標準。

**修正**：重寫 `cmd_live_push` 訊息為繁體中文、12 個必要區塊，內嵌 `===== BEGIN COPY TO CODEX REVIEW =====` 包住的 Codex Handoff Package。過程中額外發現並修正一個既有缺陷：`_post_telegram_message()` 只捕捉 `urllib.error.URLError`，未捕捉 `TimeoutError`（`OSError` 子類別），導致網路逾時時整個指令 crash、漏寫 audit/history——已擴大例外捕捉範圍修正。

### 2.2 Must Fix Round 2：Handoff Package 未獨立成一則訊息 + 要求審核按鍵

**根因**：Round 1 修正後，Codex Handoff Package 仍與 Product Owner Summary、Evidence Reference 混在同一則長訊息內，手機端無法乾淨複製；Product Owner 同時要求加入 Telegram「同意/不同意」互動按鍵。

**架構衝突（已揭露，非自行決定）**：真實 Telegram 按鍵需要接收 `callback_query` 的程序（webhook 或長輪詢），這正是已核准 Architecture Section 4.2 明確禁止的「Telegram callback 真實串接」，且該程序需常駐也違反「不做長期 worker daemon」。Claude Code 未自行擴大 scope，而是把衝突完整揭露給 Product Owner 裁決。

**Product Owner 裁決**：不新增真實 callback，改用 `record-po-decision` CLI 作為安全替代方案。

**修正**：`_build_live_push_messages()` 拆成 3 則依序訊息（Summary / **只含** Handoff Package / Evidence & Checklist），Handoff Package 超過安全長度會 Fail Loudly 而非默默截斷；新增 `record-po-decision`（approve 寫入 Approved Job Manifest、reject 只寫 audit event）與 `consume-approved`（人工觸發的一次性批次 dry-run，非排程器/daemon）。

### 2.3 Must Fix Round 3：Manifest 欄位與獨立 Handoff 檔案的補充要求

**根因**：Product Owner 進一步要求 approved manifest 能引用一份**獨立**的 Codex Handoff 檔案，並包含 `next_ai`、`handoff_package_path`、`source_artifact_path`、`audit_reference`、`status` 等具體欄位——這些不在 Architecture Section 9 的必填清單內，Round 2 的 manifest 也確實沒有。

**修正**：`live-push` 額外寫出獨立檔案 `<ref>-codex-handoff.md`（與 Telegram Message 2 逐位元組相同）；manifest 新增 5 個補充描述欄位（不影響 validator 判定，因為都不在 `FORBIDDEN_FIELD_NAMES` 之列）。

### 2.4 Codex Review MUST FIX（Round 4）：Evidence 與程式碼不同步

**根因（本輪最關鍵的流程缺陷）**：Round 3 修改了程式碼（`cmd_live_push`、`cmd_record_po_decision`），但**只在暫存目錄（`REVIEWS_OVERRIDE`）驗證過**，沒有針對 Sprint-019 真實的 live-push artifact 重新執行指令。Product Owner 因此確認收到、並依此填寫 Checklist PASS 的推播（`sprint-019-implementation-must-fix-1-live-push.md`），其檔案時間戳（`2026-07-09 22:30`）早於 Round 3 程式碼修改完成的時間（`22:43`）——換句話說，Product Owner 驗收的其實是 Round 2 版本的內容，approve 指令缺少 `--handoff-package-path`，也沒有獨立 handoff 檔案。Codex Review 用檔案時間戳直接抓出這個落差，判定 MUST FIX。

**修正**：補上 Codex 點名的 2 項測試缺口（Test 47：Message 1 是否內嵌 `--handoff-package-path`；Test 48：artifact front matter 是否包含 `handoff_package_path`）；用新 ref `sprint-019-implementation-must-fix-4` 重新執行 live-push（不覆寫舊 artifact），Checklist 新增 Round 4 Amendment 區塊，明確標註舊 PASS 決定基於已過期 evidence，保留歷史紀錄但不再視為當前有效。

## 3. Round 4 完整閉環（Product Owner 實際執行，逐一以 audit trail 驗證）

依 `reviews/notification_history.jsonl` 與 `reviews/approved-execution-queue/audit/audit.jsonl` 的實際紀錄重建時間線（`sprint-019-implementation-must-fix-4`）：

| 時間（UTC） | 事件 | 結果 |
|---|---|---|
| 15:55:34 | `live-push` 嘗試（Claude Code 本機驗證，無憑證） | `disabled` |
| 16:14:40 | `live-push` 嘗試（Product Owner，憑證錯誤） | `failed`（`HTTP Error 404: Not Found`） |
| 16:25:53 → 16:25:56 | `live-push` 嘗試（Product Owner，憑證修正後） | **`delivered`** |
| 16:29:55 | `record-po-decision --decision approve` | `product_owner_decision_recorded` + `approved_job_manifest_created`（`reviews/approved-execution-queue/approved/sprint-019-implementation-must-fix-4.md`） |
| 16:30:44 | `consume-approved` | `dry_run_executed` → `dry_run_passed`（`reviews/approved-execution-queue/dry-run/sprint-019-implementation-must-fix-4-dry-run-report.md`） |
| 16:32:21 | `confirm-live-push` | `product_owner_live_push_confirmed` |

這個時間線本身就是「append-only audit trail 設計正確性」的實例：`disabled` 與 `failed` 的失敗嘗試都被誠實保留，沒有被覆寫或刪除，最終的 `delivered` 記錄與前面的失敗嘗試並存，稽核者可以重建完整的除錯過程。

## 4. Codex Review PASS / Codex Git Review APPROVE 證據（誠實揭露一項流程落差）

Product Owner 回報 Codex Review 結果為 MUST FIX → Round 4 修正後 PASS，Codex Git Review 結果為 APPROVE。**這些判定的實際內容，是透過本次對話由 Product Owner 轉達給 Claude Code，並未產生對應的獨立 committed 檔案**（`reviews/sprint-019/round-001/` 底下沒有 `codex_review.md`、`codex_final_review.md`、`codex_git_review.md`、`consensus_report.md`、`final_consensus.md`——已用 `find` 確認不存在）。

這與 `docs/development/consensus-workflow.md`「Required Artifact Structure」定義的 Implementation Sprint 標準檔案組不同，也與 Sprint-018 的實際作法不同（Sprint-018 有完整的 `codex_review.md`、`codex_final_review_round_1-6.md`、`codex_git_review.md`、`codex_git_review_supplement.md`）。Sprint-011 的 Retrospective 曾明確記錄一項 Lesson：「AI 不應依賴聊天紀錄。所有 Architecture、Implementation、Review、Validation、Git Scope Review 都必須能從 repo artifact 追溯。」Sprint-019 的 Codex Review / Codex Git Review 環節目前不符合這項既有原則——這是本 Sprint 的一項**已知流程落差**，見第 6 節 Lessons Learned 與第 9 節 Flow Deviation Check，不是 Claude Code 自行認定 PASS，而是誠實記錄「PASS 判定存在，但缺乏獨立可追溯的 repo artifact 佐證」這個事實。

## 5. Commit / Push 證據

- Commit hash：`07ad4f71c44b85099bb1ded7088ba3714b890509`（`git log -1` 確認為目前 `master` HEAD）
- Commit message：`Sprint-019: add approved execution queue MVP`
- Remote / Branch：`origin/master`（已用 `git fetch origin master` 確認 `origin/master` 與本機 `HEAD` 一致，rev 相同）
- 變更範圍：28 個檔案、4260 行新增、0 行刪除（`git show --stat` 確認），皆為 Sprint-019 允許範圍內的新檔案（`docs/development/approved-*.md`、`docs/development/product-owner-live-push-validation.md`、`reviews/approved-execution-queue/`、`reviews/sprint-019/`、`scripts/approved_execution_queue.py`、`scripts/test_approved_execution_queue.py(.sh)`）
- `configs/n8n/*.json`：未出現在變更清單中，確認未被修改
- `scripts/review_bridge.sh`：未出現在變更清單中，確認未被修改

## 6. 剩餘 unrelated dirty / untracked files

Commit 後 `git status --short` 仍顯示以下項目，皆為 Sprint-019 開始**之前**就已存在的既有未提交狀態（與 Sprint 開始時的 git status 逐項比對一致），本 Sprint 全程未觸碰、未修改、未納入 commit：

```
 M AGENTS.md
 M CLAUDE.md
 M CODEX.md
 M GPT.md
 M docs/architecture.md
 M docs/development/n8n-claude-done-notification.md
 M docs/development/n8n-codex-review-done-notification.md
 M docs/vision.md
 M reviews/sprint-004/round-001/architecture.md
 M reviews/sprint-004/round-001/claude_report.md
 M reviews/sprint-004/round-001/codex_review.md
?? docs/principles.md
?? docs/roadmap.md
?? reviews/ai-decision-assistant/
?? reviews/notification-gap-review.md
?? reviews/sprint-006/
?? reviews/sprint-007/
?? reviews/sprint-009/
?? reviews/sprint-013/round-001/notifications/
?? reviews/sprint-017/round-001/notifications/
```

這些項目的清理不屬於 Sprint-019 範圍，建議留給對應 Sprint 或一次專門的 Repository Hygiene Sprint 處理。

## 7. 與原本設計流程的偏差

1. **Codex Review / Codex Git Review 缺乏獨立 committed artifact**（見第 4 節）——與 `consensus-workflow.md` 標準流程及 Sprint-018 實務不同。
2. **Live push 是全新的獨立實作（`approved_execution_queue.py`），未重用 `scripts/review_bridge.sh` 既有的 `push-claude-report` / `notify-gate` 機制**——但這不是實作疏漏：Architecture 明確禁止 Sprint-019 修改 `scripts/review_bridge.sh`，因此新機制必須平行存在。代價是 Round 1、2 花了兩輪才重新趨近 `review_bridge.sh` 已經驗證過的慣例（繁體中文、Section-aware 訊息拆分、Handoff Package copy boundary）——這些能力在 `telegram-po-gate-notification-specification.md` 第 20-24 節其實已經定義過，若 Sprint-019 一開始就參照這些既有規格（而非重新設計），前兩輪 Must Fix 有機會被提早避免。
3. **Round 3 → Codex Review Must Fix Round 4**：程式碼變更後沒有針對真實 artifact 重新產生 evidence，導致 Product Owner 依過期內容驗收（見第 2.4 節）。
4. **Telegram 憑證問題**在 Round 4 造成 3 次真實嘗試（`disabled` → `failed` 404 → `delivered`）才送達成功，屬環境設定問題，非程式邏輯錯誤，append-only audit trail 完整保留了這個除錯過程。

## 8. Lessons Learned

- **改了程式碼，不等於改了 evidence**：Round 3 的核心教訓——修改一個會產生 artifact 的指令之後，必須針對「真正要拿去驗收的那份 artifact」重新執行一次，光在暫存目錄驗證邏輯正確不夠，Product Owner 看到的必須是同一份東西。
- **「timer」這類詞彙容易被誤解為排程/daemon**：Round 2 的流程圖用了「timer / worker」字眼，需要额外一輪釐清這是否與 Architecture 禁止的「長期 worker daemon」衝突——未來下指令時，若涉及「自動執行」，應明確區分「人工觸發的批次指令」與「常駐排程程序」，避免各自解讀。
- **既有規格是最快的合規路徑**：`telegram-po-gate-notification-specification.md` 早就定義了 Section-aware 訊息拆分、Handoff Package copy boundary 等模式，Sprint-019 重新發明了一次類似機制，若一開始就對照既有規格設計，可少走 1-2 輪 Must Fix。
- **Append-only 設計在真實故障中證明價值**：Round 4 的 3 次真實送出嘗試（disabled/failed/delivered）都被完整保留，讓根因（憑證設定錯誤）可以被事後追溯，而不是被覆寫掩蓋。
- **Architecture 衝突要揭露、不要默默擴權，也不要默默拒絕**：Round 2 的 Telegram 按鍵要求與已核准 Architecture 直接衝突時，明確列出衝突條文、提出功能對等的合規替代方案、交由 Product Owner 裁決，是比自行擴大 scope 或直接拒絕都更負責任的處理方式。
- **口頭/聊天轉達的 Review 結果應盡快落地為 repo artifact**：本 Sprint 的 Codex Review／Git Review 判定只存在於對話中，若對話紀錄遺失，這兩個關鍵 Gate 的判斷依據將無法被獨立稽核（見第 4 節）。

## 9. Flow Deviation Check

```markdown
- Full reading list used in all formal Handoff Packages: PASS（Codex Handoff Package 每次皆內嵌完整必讀清單）
- Any shortened reading list used: NO
- Context Completeness Check present in Claude / Codex reports: PASS（各輪 claude_fix_report*.md 皆含此區塊）
- Missing context files recorded: YES（Sprint-019 Architecture Definition 獨立檔案、Sprint-018 Retrospective / Actual Flow Report 獨立檔案，兩者皆不存在，已於 claude_report.md 第 15.3 節揭露）
- Telegram Notification block present in formal Handoff Packages: PASS
- notify-gate expected: NO（Sprint-019 使用獨立的 `approved_execution_queue.py live-push`，非 `review_bridge.sh notify-gate`；`scripts/review_bridge.sh` 全程未被修改或呼叫）
- notify-gate executed by Product Owner: N/A
- Telegram notification received: YES（Round 1-4 皆有 Product Owner 實際確認收到，Round 4 為最終有效版本）
- Manual handoff used instead of Telegram notification: NO
- Manual Gate skipped: NO
- Review scope drift occurred: NO（Round 2-3 的功能擴充皆由 Product Owner 明確要求並裁決，非 Claude Code 自行擴大）
- unrelated dirty / untracked files mixed into Sprint scope: NO（見第 6 節，皆為既有狀態，未被觸碰或納入 commit）
- Codex Review / Codex Git Review 判定是否有獨立 committed artifact: NO（見第 4 節，這是本輪明確記錄的流程落差）
- Notes: Codex Review 與 Codex Git Review 的 PASS/APPROVE 判定僅透過本次對話轉達，未產生 `codex_review.md` / `codex_final_review.md` / `codex_git_review.md` / `consensus_report.md` / `final_consensus.md`。
```

## 10. Process Improvement / Backlog（Sprint-020 建議）

**明確排除於「Sprint-019 未完成項目」之外**：以下建議是 Sprint-020（或後續 Sprint）的**新範圍候選項目**，不是 Sprint-019 Definition of Done 的缺口——Sprint-019 的 Architecture 明確要求「不做長期 worker daemon」「不做 Telegram callback 真實串接」，`consume-approved` 與 `record-po-decision` 的 CLI-only 設計是**依 Architecture 與 Product Owner 裁決刻意做出的安全邊界**，不是尚待補完的半成品。

候選 Backlog（Sprint-020 或專屬 Sprint）：

- **Local Trusted Notification Runner**：在 Product Owner 本機（而非 repo 內常駐）建立一個受信任的本地程序，定期或事件觸發呼叫既有 CLI（`live-push` / `consume-approved`），取代目前「Product Owner 手動複製指令執行」的模式。必須明確設計成本機、非 repo 常駐、Product Owner 完全掌控啟停的形式，並在新的 Architecture Artifact 中重新定義安全邊界。
- **真實 Telegram Approve/Reject 按鍵（Architecture Amendment）**：若 Product Owner 認為 CLI 替代方案的操作成本仍然太高，可在專屬 Sprint 中正式核准 Telegram callback / webhook 整合的安全設計（含 token 驗證、rate limiting、審計），取代目前的 `record-po-decision` CLI。
- **Codex Review / Codex Git Review Artifact 落地**：建議後續 Sprint 明確要求 Codex Review 結果必須產生獨立 committed 檔案（`codex_review.md` 等），避免重蹈本 Sprint 第 4 節記錄的落差。
- **`next_ai` 映射表擴充機制**：目前 `_TARGET_ACTOR_DISPLAY_NAMES` 是寫死的 4 筆對應，若 `target_actor` 白名單未來擴充，需同步更新。

## 11. Product Owner Decision（Claude Code 草擬，待 Product Owner 確認/修改）

### 11.1 Accepted

- Approved Execution Queue MVP（Schema、Validator、Dry-run Worker、Audit Trail）正式建立並通過 48 項測試。
- Mandatory Live Push Validation 完成，4 輪 Must Fix 後達成 `delivered` + Product Owner 親自確認。
- `record-po-decision` / `consume-approved` 閉環作為 Telegram 真實按鍵的合規替代方案，已端對端驗證。
- Commit（`07ad4f71c44b85099bb1ded7088ba3714b890509`）與 Push 至 `origin/master` 已完成。

### 11.2 Rejected

None（本輪未有被否決的方案；Round 2 的「真實 Telegram 按鍵」是被 Architecture 排除、Product Owner 另外裁決 CLI 替代方案，不算被否決的 Must Fix 要求）。

### 11.3 Deferred

- 真實 Telegram Approve/Reject 按鍵（Architecture Amendment）——見第 10 節。
- Local Trusted Notification Runner——見第 10 節。

### 11.4 New Backlog

見第 10 節 Sprint-020 候選項目清單。

### 11.5 Strategic Decisions

- Sprint-019 確認 AI Workspace 的 Product Owner Gate 機制可以在「不新增 Telegram callback 真實串接」的前提下，仍然達成「Product Owner 可遠端審核並記錄決策」的目標。

### 11.6 Rationale

CLI 替代方案（`record-po-decision`）在保留 Architecture 安全邊界（不做 callback 串接、不做長期 daemon）的同時，達成了 Product Owner 原始要求的核心閉環（approve → manifest → consume-approved dry-run），且全程可由 audit trail 稽核，是本 Sprint 在安全與可用性之間取得的具體平衡。

### 11.7 Closure 建議

**Claude Code 的建議：可以進入 Closure，但需 Product Owner 先確認第 4 節記錄的 Codex Review/Git Review artifact 落差是否需要補齊，或接受以本對話紀錄作為足夠證據。** 理由：

- Definition of Done 第 1-17 項（Architecture 第 26 節）已逐項達成，含 Commit 與 Push。
- 唯一的開放問題是「Codex Review / Codex Git Review 判定缺乏獨立 committed artifact」（第 4 節）——這是治理可追溯性的落差，不是功能或安全邊界的缺陷；Commit 與 Push 既然已經在 Product Owner 知情下完成，回頭補一份 Codex Review 檔案並不會改變已經發生的結果，但可以決定是否要求「以後」的 Sprint 不再出現這個落差（見第 10 節建議）。
- 若 Product Owner 認為此落差不影響本 Sprint 結案，Claude Code 建議直接核准 Closure；若認為需要正式記錄，建議在 Closure 前請 Codex 補一份簡短的 `codex_git_review.md` 事後摘要（陳述已經做過的判斷，不需要重新審查）。

最終 Closure 決定，依 Architecture 規定，仍須 Product Owner 本人核准。
