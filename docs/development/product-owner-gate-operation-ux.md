# Product Owner Gate Operation UX

Version: 1.4 (Sprint-018; Claude Report Push to PO added in Must Fix Round 2; 13→14 Gate wording and Gate 6→Gate 14 semantic fix in Must Fix Round 3; Claude Report Push execution responsibility fixed in Must Fix Round 5; conditional-invocation gap fixed to unconditional invocation in Must Fix Round 6)

## 0. 為何新增本文件

Sprint-013–017 陸續建立了 Telegram Gate Notification 的完整能力（Notification Package、Content Mode、Product Owner Summary、Next AI Handoff Package、Section-aware 訊息拆分），但這些能力分散記錄在多份規格文件（`docs/development/notification-package-specification.md`、`docs/development/telegram-po-gate-notification-specification.md`、`docs/development/product-owner-gate-metadata.md`）裡，沒有一份文件是「Product Owner 打開來看，就知道自己該怎麼操作整個系統」的入口。Sprint-018 新增本文件，作為 Product Owner 實際操作 Gate 通知系統的統一入口與心智模型，不重複定義既有規格內容，只負責串接與導覽。

## 1. 三層文件關係

```text
docs/development/product-owner-gate-operation-ux.md（本文件，操作導覽入口）
  └── docs/development/product-owner-gate-metadata.md（21 個 canonical Gate 的完整 metadata）
  └── docs/development/telegram-po-gate-notification-specification.md（notify-gate 的完整技術規格）
  └── docs/development/execution-permission-policy.md（Claude/Codex 執行權限與 Safety Level）
  └── reviews/sprint-018/round-001/gate_notification_matrix.md（14 個操作性 Gate 的具體操作準則）
  └── reviews/sprint-018/round-001/codex_review_handoff_policy.md（Codex Review Handoff 的治理規則）
```

## 2. Product Owner 的典型操作循環

1. 收到 Telegram 通知（`notify-gate` 送出的訊息，依 Content Mode 拆成 1–4+ 則）。
2. 閱讀「🇹🇼 Product Owner Summary」（若有）或「🔔/⚠️ Header」，理解目前狀態。
3. 依「✅ Product Owner Decision Options」做出決策。
4. 若該 Gate 需要轉交下一位 AI（見 `gate_notification_matrix.md` 的「是否需要 Next AI Handoff Package」欄位），直接複製「🤖 Next AI Handoff Package」訊息（`===== BEGIN COPY TO <TARGET_AI> =====` 到 `===== END COPY TO <TARGET_AI> =====` 之間的完整內容），貼給對應的 AI（ChatGPT / Claude Code / Codex）。
5. 需要時查閱「📎 Evidence Reference」列出的路徑，或手動加上 `TELEGRAM_CONTENT_MODE=full` 重新執行 `notify-gate` 以取得完整原始佐證。
6. 若該 Gate 是 Commit/Push 類高風險 Gate，一律親自確認並執行，不透過 AI Handoff 自動化（見 `docs/development/execution-permission-policy.md` Safety Level 3）。

## 3. 何時使用哪種 Content Mode

- **`summary`**：純決策型 Gate，不需要轉交下一位 AI（例如 `commit_approval`、`push_approval`、`retrospective_content_approval`、`product_owner_closure_approval`）。
- **`handoff`（預設）**：Gate 核准後緊接著要轉交某個 AI 執行下一步（例如 `claude_implementation_approval`、`product_owner_validation_approval`）。
- **`full`**：需要完整原始佐證時才手動加上，通常用於仔細審閱 Codex/Claude 產出的完整報告原文。

完整規則見 `docs/development/telegram-po-gate-notification-specification.md` 第 23 節；14 個操作性 Gate 各自建議的預設模式見 `reviews/sprint-018/round-001/gate_notification_matrix.md`。

## 4. Codex Review Handoff 的治理原則（摘要）

Claude Implementation Report 可以是 Codex Review Handoff 的參考輸入，但不能單獨決定 Codex Review 的範圍、checklist、必讀清單或禁止事項——這些必須來自 canonical template（`reviews/sprint-018/round-001/codex_review_handoff_policy.md`）與既有治理文件。若某輪 Sprint 修改了 Review Bridge 本身（`notify-gate`、Telegram renderer、copy boundary 產生邏輯等），該輪 Codex Review 必須額外觸發 Self-Modification Safety Rule，不得只依賴修改後的程式輸出作為驗證依據。完整規則見 `codex_review_handoff_policy.md`。

## 5. Claude Report Push to PO（Sprint-018 Must Fix Round 2；Gate 對應修正於 Round 3）

### 5.1 為何新增

Claude Code 完成 Implementation 或 Fix 後，若只在 terminal / chat 中回報完成，Product Owner 可能不知道目前已經可以進入 Codex Review。因此新增「Claude Report Push to PO」這個獨立的通知類別：Claude Code 完成後，把 Claude Implementation Report / Fix Report 推播給 Product Owner，讓 Product Owner 不需要主動回頭檢查 terminal 就能得知進度。

### 5.2 用途

1. 通知 Product Owner：Claude Implementation Report / Fix Report 已完成。
2. 讓 Product Owner 可以直接在 Telegram 查看報告摘要與報告內容。
3. 讓 Product Owner 決定是否進入 Codex Review / Codex Final Review。
4. 讓 Product Owner 手動複製報告內容給 Codex。
5. **不**自動呼叫 Codex。
6. **不**自動核准 Gate。

### 5.3 明確區分（不得混淆）

```text
Claude Report Push to PO
≠ Formal Codex Review Approval        （不是 Codex Review 已核准）
≠ Auto Handoff to Codex               （不是自動轉交給 Codex）
≠ Auto Gate Approval                  （不是自動核准任何 Gate）
```

Claude Report Push to PO 純粹是「通知」，跟 `notify-gate` 送出的 Formal Gate Notification 一樣，都必須由 Product Owner 手動執行 `notify-gate`（Claude / Codex 不得自動觸發 Telegram），且送出通知這個動作本身**不代表**任何 Gate 已經被核准、也**不代表**已經轉交給下一位 AI 執行者。是否送給 Codex、何時送、送什麼內容，全部由 Product Owner 決定並手動操作。

### 5.4 完整流程（Sprint-018 Must Fix Round 5 建立；Round 6 修正為一律呼叫）

```text
Claude Code 完成 Implementation / Fix
  ↓
Claude Code 產生 Implementation Report / Fix Report
  ↓
Claude Code 一律執行（不設前置條件）：
PROJECT_ID=ai-workspace PROJECT_NAME="AI Workspace" \
  ./scripts/review_bridge.sh push-claude-report <sprint-id> <round> <implementation|fix> [report-path]
（見 telegram-po-gate-notification-specification.md 第 27 節；
 PROJECT_ID/PROJECT_NAME 非機密，由 Claude Code 直接帶入，確保指令不會因缺參數而中止）
  ↓
指令本身依本機是否已有 Telegram 設定（NOTIFICATION_ENABLED / TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID）決定結果：
  ↓
   已具備 → delivery_status: delivered（Telegram 送達）      未具備 → delivery_status: disabled
                                                              （不送 Telegram，但仍寫入 history + push artifact）
  ↓                                                                        ↓
Claude Report 推播給 Product Owner                          reviews/notification_history.jsonl 與
（Claude Report Push to PO，若 delivered）                    push artifact 檔案仍然真實產生，
                                                              可供 Product Owner 獨立稽核 completion
                                                              step 確實執行過（見第 27.7 節驗收標準）
  ↓                                                                        ↓
Product Owner 審核報告 ←－－－－－－－－－－－－－－－－－－－－－－－－－－－
  ↓
Product Owner 手動把報告內容與 Codex Review 要求（canonical checklist，見 codex_review_handoff_policy.md）貼給 Codex
  ↓
Codex 進行獨立 Review
```

**Round 5**（Round 2–4 之後）：`push-claude-report` 是純人工 CLI 指令，Claude Code 完成報告後不會有任何動作觸發它，Product Owner 必須自己記得並手動執行才會收到 Telegram 通知——這正是 Sprint-018 Codex Final Review Supplement Round 4 之後，Product Owner Telegram Live Validation 判定 NOT PASS 的原因（詳見 `reviews/sprint-018/round-001/claude_fix_report_round_5.md`）。Round 5 改成「Claude Code 先唯讀檢查 5 個環境變數是否全部齊全，齊全才執行，否則完全不執行」。

**Round 6**：Round 5 的設計仍有缺口——因為 Telegram 相關變數在每一次實際 session 中都尚未設定，Round 5 的規則導致 `push-claude-report` 從未被真正呼叫過，`reviews/notification_history.jsonl` 沒有任何紀錄、也沒有任何 push artifact 檔案，Product Owner 唯一能查核的只有 Claude Report 裡的文字聲明——這正是 Product Owner Live Flow Validation 判定 FAIL 的直接原因（詳見 `reviews/sprint-018/round-001/claude_fix_report_round_6.md`）。Round 6 修正為「Claude Code 一律呼叫 `push-claude-report`，不再自行判斷 Telegram 變數是否齊全後才決定要不要執行」——PROJECT_ID/PROJECT_NAME 由 Claude Code 直接帶入非機密的既有專案識別值，確保指令一定能執行到底；Telegram 是否真的送達，交由指令本身依其既有的 opt-in 機制決定，且不論結果為何都會留下可獨立稽核的 history 紀錄與 push artifact 檔案。完整規則見 `docs/development/telegram-po-gate-notification-specification.md` 第 27 節；Product Owner 驗收標準見第 27.7 節。`notify-gate` 的人工限定（第 18/19 節）完全不受影響。

### 5.5 適用 Gate（Sprint-018 Must Fix Round 3 修正：Gate 6 語意錯誤，正確對應為 Gate 14）

「Claude Completion Gate」（Claude 剛完成一份報告、等待 Product Owner 審核的 Gate）目前有 2 個，兩者語意上是對稱的一組：

- **`claude_implementation_report_acceptance`（Gate 4）**：Claude Implementation Report Ready——Claude Code 完成 Implementation 後產生 `claude_report.md`，等待 Product Owner 驗收。
- **`claude_must_fix_report_acceptance`（Gate 14）**：Claude Fix Report Ready——Claude Code 完成 Must Fix 修正後產生 `claude_fix_report*.md`，等待 Product Owner 驗收。

**明確排除**：`claude_must_fix_approval`（Gate 6）**不是** Claude Completion Gate，也**不適用**本節流程——它的語意是「Must Fix **開始前**，Product Owner 授權 Claude Code 開始修正」，發生在 Claude 動手修正之前；跟「Claude 已經修正完、報告已經產出、等待驗收」是完全相反的時間點。Round 2 曾誤植為「`claude_must_fix_approval` 之後 / Gate 6」，已於 Round 3 修正為 `claude_must_fix_report_acceptance` / Gate 14。

完整欄位定義見 `gate_notification_matrix.md`（Gate 4 = 3.4 節，Gate 14 = 3.7 節）；Telegram 訊息內容規則見 `telegram-po-gate-notification-specification.md` 第 26 節「Claude Report Push to Product Owner」。

## 6. 本文件不涵蓋的內容

本文件不重新定義 21 個 Gate 的 metadata（見 `product-owner-gate-metadata.md`）、不重新定義 `notify-gate` 的 CLI 介面或訊息格式細節（見 `telegram-po-gate-notification-specification.md`）、不重新定義 Claude/Codex 的執行權限規則（見 `execution-permission-policy.md`）。若三者與本文件描述有出入，以各自的權威文件為準，本文件只負責導覽。
