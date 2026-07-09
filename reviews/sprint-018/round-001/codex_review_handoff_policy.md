# Codex Review Handoff Policy

Version: 1.1 (Sprint-018; Must Fix Round 2 新增第 6 節 Claude Report Push to PO 手動送 Codex 規則)

## 1. 目的

落地 Sprint-018 要求的兩項治理規則：**Independent Review Handoff Authority**（Codex Review Handoff 不得只由 Claude Implementation Report 單獨決定）與 **Review Bridge Self-Modification Safety Rule**（若本 Sprint 修改了 Review Bridge / Handoff Template / notify-gate / Telegram renderer / copy boundary generation，Codex Review 不得只依賴新修改後的 Review Bridge 輸出）。

本文件是 canonical template 本身，`docs/development/consensus-workflow.md` 引用它作為「Codex Review Handoff 必須依循此 policy 組成」的依據。

## 2. Independent Review Handoff Authority

### 2.1 規則

1. **Claude Implementation Report 可以作為 Codex Review Handoff 的 input**——Codex 需要知道 Claude 做了什麼，`claude_report.md` 是重要的參考來源之一。
2. **但 Claude 不得單獨決定 Codex Review 的 scope、checklist、Required Reading 或 forbidden actions**。這些必須來自本文件（canonical template）與 `docs/development/consensus-workflow.md` / `docs/development/git-review-checklist.md` 等既有治理文件，不能由 Claude 在 `claude_report.md` 裡自行加註「請 Codex 只檢查 XXX」而讓 Codex Review 的範圍被 Claude 片面限縮或擴大。
3. **Codex Review Handoff 必須由 approved canonical template / Review Bridge 組成**——具體來說：
   - Required Reading 清單固定引用 `docs/development/consensus-workflow.md` 的 Handoff Package Standard（10 項完整清單），不得由 Claude 自行縮減。
   - Checklist 固定引用 `docs/development/git-review-checklist.md`（Git Review 情境）或本文件第 3 節（一般 Implementation/Must Fix Review 情境），不得由 Claude 自訂一份新的 checklist。
   - Forbidden actions 固定引用 `docs/development/execution-permission-policy.md` 的 Safety Level 3 清單，不得由 Claude 增減。

### 2.2 Claude 在 Codex Review Handoff 準備過程中的角色

Claude Code 可以：協助把 canonical template（本文件 + 既有 checklist 文件）套用實際的 Sprint/Round/檔案路徑，產生具體的 Codex Review Handoff 內容（例如 Sprint-017 的 `codex_git_review_handoff_zh.md` 就是這樣產生的）。

Claude Code 不可以：發明新的 checklist 項目取代既有文件、刪減既有 checklist 項目、在 Handoff 裡加入「Codex 只需要相信 claude_report.md 的說法」之類的措辭、把 `claude_report.md` 當成唯一的驗證依據。

## 3. Codex Review Handoff 必須包含的內容（Canonical Checklist）

任何 Codex Review Handoff（不論是 Implementation Review、Must Fix Review、Final Review、或 Git Review）都必須包含以下區塊：

### 3.1 Review Independence Requirement

```markdown
## Review Independence Requirement

Codex 的結論必須基於直接檢查（source diff、實際執行測試、直接讀取 Architecture/checklist 文件），
不得只依賴 claude_report.md 的自我陳述作為結論依據。若 claude_report.md 的說法與實際檢查結果不符，
以實際檢查結果為準，並在 Review 中明確指出落差。
```

### 3.2 Git Diff / Git Status 檢查要求

```markdown
## Git Diff / Git Status Check

- 必須實際執行 `git status --short` 與 `git diff --name-only`（唯讀指令，Codex Git Review Mode / Codex Review Mode 皆允許）。
- 必須逐一核對輸出的檔案清單，與 Handoff 聲明的 Allowed Files / Files Changed 是否一致。
- 任何未被 Claude Report 提及、但 `git status`/`git diff` 顯示已變更的檔案，視為 Blocking 問題。
```

### 3.3 Scope / Out of Scope Check

```markdown
## Scope / Out of Scope Check

- 逐一核對本輪 Architecture 的 In Scope 項目是否都已完成、有無擴大範圍（scope creep）。
- 逐一核對本輪 Architecture 的 Out of Scope / 禁止事項是否被誤觸碰。
- 確認未修改 Prohibited Files（見對應 Sprint 的 architecture.md 或 Handoff Package）。
```

### 3.4 Runtime Evidence Exclusion Check

```markdown
## Runtime Evidence Exclusion Check

- 確認 `reviews/notification_history.jsonl` 未被 stage 或 commit。
- 確認 `reviews/*/notifications/*.md`（Gate/事件通知 Notification Package）未被 stage 或 commit。
- 確認本輪 Review 過程中沒有在真實 repository 產生新的 runtime evidence（測試應使用隔離的暫存目錄）。
- 依 `docs/development/runtime-evidence-exclusion-policy.md` 逐項核對。
```

## 4. Review Bridge Self-Modification Safety Rule

### 4.1 觸發條件

若某個 Sprint 的 Implementation 修改了以下任一項：

```text
scripts/review_bridge.sh（尤其是 notify-gate / cmd_notify_gate / _telegram_notification_block /
  _notify_split_for_telegram / _notify_gate_extract_target_ai / write_handoff_package_* /
  任何 Handoff Package 或 Telegram renderer 相關函式）
Handoff Package Template（例如 docs/development/consensus-workflow.md 的 Handoff Package Standard、
  docs/development/telegram-po-gate-notification-specification.md 的訊息格式規則）
copy boundary generation 邏輯
```

則本輪 Codex Review **必須觸發 Self-Modification Safety Rule**。

### 4.2 規則內容

1. **Codex Review 不得只依賴新修改後的 Review Bridge 輸出作為驗證依據**——例如：若本輪修改了 `_notify_gate_extract_target_ai()`，Codex 不能只跑一次 `notify-gate` 看輸出「看起來對」就判定 PASS，因為如果這個函式本身有邏輯錯誤，它產生的輸出可能「自圓其說」但實際上是錯的（例如函式本身的驗證邏輯被削弱，導致它自己產生的測試也跟著弱化）。
2. **必須直接檢查 Architecture**：確認本輪修改的行為，與該 Sprint 的 `architecture.md` 記錄的決策一致，而不是「看程式碼現在做什麼就當作那是對的」。
3. **必須直接檢查 fixed checklist**：例如 Round 7 的「Next AI Handoff message 不得含 6 類雜訊」，Codex 應該直接列出這 6 項逐一核對原始碼與測試斷言，而不是只看 `notify-gate` 執行後說「看起來訊息是乾淨的」。
4. **必須直接檢查 source diff**：實際閱讀 `git diff` 中 `scripts/review_bridge.sh` 的變更內容，確認新增/修改的函式邏輯正確，不是只信任「測試都通過了」這個間接證據。
5. **必須直接檢查 test evidence**：確認新增測試本身的斷言邏輯是否真的驗證了正確的行為（例如 Sprint-017 Round 7 曾經發生測試斷言本身有 bug、卻恰好因為 fixture 文字巧合而通過的案例——Codex 應該具備類似的懷疑態度，检查測試斷言本身的正確性，不是只看「測試都綠燈」）。

### 4.3 本 Sprint（Sprint-018）是否觸發

Sprint-018 的實作範圍**不修改** `scripts/review_bridge.sh` 或任何 Handoff Package Template 的程式邏輯（見 `reviews/sprint-018/round-001/claude_report.md` 的 Implementation Details 說明）——本 Sprint 純粹是文件與治理政策層級的工作，套用 Sprint-017 已完成且已通過 Codex Final Review 的既有能力。因此嚴格來說，**本輪 Self-Modification Safety Rule 不觸發**；但本規則從本 Sprint 起正式文件化，適用於未來任何觸碰 Review Bridge / Handoff Template / notify-gate / Telegram renderer / copy boundary generation 的 Sprint。

## 5. Codex Review Handoff 產出範例對照

`reviews/sprint-017/round-001/codex_git_review_handoff_zh.md` 是本政策生效前，依相近精神手動撰寫的範例（Git Review 情境）。未來的 Codex Review Handoff 應明確包含本文件第 3 節列出的 4 個區塊（Review Independence Requirement、Git Diff/Git Status Check、Scope/Out of Scope Check、Runtime Evidence Exclusion Check），若涉及 Self-Modification Safety Rule 觸發條件，另外加上第 4.2 節的 5 項規則內容。

## 6. Claude Report Push to PO 之後，PO 手動送給 Codex 的規則（Sprint-018 Must Fix Round 2）

### 6.1 背景

Sprint-018 Must Fix Round 2 新增「Claude Report Push to PO」流程（見 `docs/development/product-owner-gate-operation-ux.md` 第 6 節、`docs/development/telegram-po-gate-notification-specification.md` 第 26 節）：Claude Code 完成 Implementation / Fix 後，把 Claude Report 推播給 Product Owner，Product Owner 審核後，再手動把報告內容貼給 Codex。本節明確規範這個「手動貼給 Codex」的動作必須遵守的規則，避免 Claude Report 在轉手過程中被誤用為 Codex Review 的唯一依據。

### 6.2 規則

1. **Claude Report 是 review input，不是 review authority**——這與本文件第 2 節 Independent Review Handoff Authority 的原則完全一致，Claude Report Push to PO 只是新增了一個「通知」管道，不改變這個底線。
2. **Codex 必須獨立檢查 Architecture、git diff、git status、tests、scope、runtime evidence**——不論 Claude Report 是透過 Telegram 推播、或透過其他方式交給 Codex，Codex 的結論都不能只基於 Claude Report 的自我陳述。
3. **當 Product Owner 把 Claude Report 內容貼給 Codex 時，必須同時附上 canonical Codex Review 要求**——也就是本文件第 3 節的 4 個必要區塊（Review Independence Requirement、Git Diff/Git Status Check、Scope/Out of Scope Check、Runtime Evidence Exclusion Check）。只貼 Claude Report 本身、不附上這些要求，視為不完整的 Codex Review Handoff。
4. **Codex 不得只依 Claude Report 做結論**——若 Product Owner 貼給 Codex 的內容缺少 canonical review checklist，Codex 應主動要求補上，而不是逕自依 Claude Report 的自我陳述判斷 PASS / MUST FIX。

### 6.3 與 Self-Modification Safety Rule 的關係（Nit 修正，Sprint-018 Round 1 Codex Review 建議）

若某個 Sprint 只修改了 `scripts/test_review_bridge.sh`（測試檔本身），不修改 Review Bridge runtime（`notify-gate`、Telegram renderer、copy boundary generation 等），**不算**觸發第 4 節的 Review Bridge Self-Modification Safety Rule；但 Codex 仍必須審查新增測試本身的斷言邏輯是否足夠嚴謹（例如是否真的逐一驗證了聲稱驗證的行為，而不是只確認「測試都是綠燈」），因為測試斷言本身若寫得不夠嚴謹，也可能讓「348 passed, 0 failed」這類數字看起來可信、實際上覆蓋不足——Sprint-018 Round 1 的 Codex Review 本身就是一個實例（發現 Test 33 只做全文關鍵字檢查，不夠逐 Gate 驗證）。
