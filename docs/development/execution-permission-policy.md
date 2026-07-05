# Execution Permission Policy

> Claude Code / Codex Execution Mode Policy — Sprint-014, extended in Sprint-016

Version: 1.1 (Sprint-014; Sandboxed Low-Risk Auto-Approval Policy added in Sprint-016)

---

## 0. Authority

This document operates under `docs/development/development-principles.md` (the AI Workspace Development Constitution) and `docs/development/consensus-workflow.md`. It does not redefine Development Principles, the Definition of Done, or Review Bridge gate mechanics. It defines the **Execution Permission Policy**: which actions Claude Code and Codex may perform under low-interruption execution, and which actions always require explicit, synchronous Product Owner approval.

This document governs AI Workspace V1 only. It does not define AI Collaboration Engine or AI Decision Assistant runtime behavior.

---

## 1. Core Rule

**可低中斷不等於完全 bypass sandbox（"Low-interruption" does not mean "fully bypass the sandbox").**

Every mode below still operates inside this workspace's existing sandbox, permission, and tool-approval mechanisms. "Low-interruption" only means the human does not need to approve *every single step* of a Review-type task in real time — it never means unrestricted, unattended execution.

Global rules that apply to every mode without exception:

1. Review 類任務可低中斷執行（Review-type tasks may run with low interruption）.
2. Claude Implementation / Must Fix 可在核准 scope 內低中斷執行（may run with low interruption only inside an already-approved scope）.
3. Commit / Push 不得低中斷（Commit / Push must never run with low interruption）.
4. Commit / Push 必須 Product Owner 明確核准（must always have explicit, synchronous Product Owner approval）.
5. 不得 `git add .`（never stage with a wildcard; only named, reviewed files）.
6. 不得自動 commit。
7. 不得自動 push。
8. 不得自動呼叫 Claude / Codex（no mode may programmatically invoke another AI role）.
9. 不得自動進入下一個 Gate（no mode may auto-advance to the next Product Owner Gate; see `docs/development/telegram-po-gate-notification-specification.md`）.

---

## 2. Modes

Each mode is defined by: 適用情境 (When it applies) / 允許動作 (Allowed actions) / 禁止動作 (Forbidden actions) / 是否可低中斷執行 (Low-interruption allowed?) / 是否需要 Product Owner 明確核准 (Explicit PO approval required?) / 風險等級 (Risk level) / sandbox / permission 原則.

### 2.1 Claude Implementation Mode

- **適用情境**：Claude Code 依已核准的 Architecture 執行實作（Sprint 的 `claude_implementation_approval` Gate 通過後）。
- **允許動作**：在已核准 Scope 內新增/修改檔案、撰寫測試、執行測試、讀取相關文件與程式碼。
- **禁止動作**：擴大 Scope、修改未核准 Architecture、自行新增 Framework/Platform、執行 `git commit`、執行 `git push`、呼叫 Codex 或其他 AI。
- **是否可低中斷執行**：可以，但僅限已核准 Scope 內；一旦需要超出 Scope 的判斷，必須停下請示 Product Owner。
- **是否需要 Product Owner 明確核准**：進入本 mode 前需要（對應 `claude_implementation_approval` Gate）；mode 執行過程中的個別步驟不需要逐一核准。
- **風險等級**：medium。
- **sandbox / permission 原則**：一般檔案讀寫權限；不得繞過既有的 Bash 工具權限提示機制；不得停用或跳過任何安全檢查。

### 2.2 Claude Must Fix Mode

- **適用情境**：Claude Code 依 Codex Review 指出的 Must Fix / Should Fix 項目進行修正（`claude_must_fix_approval` Gate 通過後）。
- **允許動作**：僅修正 Codex 指出的項目、撰寫/更新對應測試、產出 Must Fix Report。
- **禁止動作**：修正 Codex 未提及的項目、擴大 Scope、執行 `git commit`、執行 `git push`、呼叫 Codex。
- **是否可低中斷執行**：可以，僅限已核准 Scope（即 Codex 指出的項目清單）內。
- **是否需要 Product Owner 明確核准**：進入本 mode 前需要（對應 `claude_must_fix_approval` Gate）。
- **風險等級**：medium。
- **sandbox / permission 原則**：同 Claude Implementation Mode。

### 2.3 Codex Review Mode

- **適用情境**：Codex 對 Claude Code 的實作進行 Review（`codex_review_approval` Gate 通過後）。
- **允許動作**：讀取程式碼與文件、執行測試以驗證回報結果、產出 `codex_review.md`。
- **禁止動作**：修改任何程式碼或文件、執行 `git commit`、執行 `git push`、呼叫 Claude Code 要求其修正（只能在報告中提出，不能主動觸發）。
- **是否可低中斷執行**：可以（Review 類任務）。
- **是否需要 Product Owner 明確核准**：進入本 mode 前需要（對應 `codex_review_approval` Gate）。
- **風險等級**：low。
- **sandbox / permission 原則**：唯讀為主；若需執行測試指令，僅限專案既有測試指令（例如 `pytest`、`bash scripts/test_review_bridge.sh`），不得執行任意 shell 指令。

### 2.4 Codex Final Review Mode

- **適用情境**：Codex 確認 Must Fix / Should Fix 是否已解決（`codex_final_review_approval` Gate 通過後）。
- **允許動作**：讀取 Must Fix Report 與相關程式碼、重跑測試、產出 `codex_final_review.md`。
- **禁止動作**：同 Codex Review Mode。
- **是否可低中斷執行**：可以（Review 類任務）。
- **是否需要 Product Owner 明確核准**：進入本 mode 前需要（對應 `codex_final_review_approval` Gate）。
- **風險等級**：low。
- **sandbox / permission 原則**：同 Codex Review Mode。

### 2.5 Codex Git Review Mode

- **適用情境**：Codex 檢查目前 git 變更範圍是否乾淨、是否符合本 Sprint 範圍（`codex_git_review_approval` Gate 通過後）。
- **允許動作**：執行 `git status`、`git diff`、`git log` 等唯讀指令，確認 commit scope 是否包含 unrelated 檔案。
- **禁止動作**：`git add`（含 `git add .`）、`git commit`、`git push`、`git reset`、`git checkout --`、任何會改變 working tree 或 git 狀態的指令。
- **是否可低中斷執行**：可以，僅限唯讀的 git 檢查類指令。
- **是否需要 Product Owner 明確核准**：進入本 mode 前需要（對應 `codex_git_review_approval` Gate）。
- **風險等級**：medium（因為緊接在 Commit 之前，判斷錯誤的後果較高）。
- **sandbox / permission 原則**：僅允許唯讀 git 指令；任何寫入類 git 指令一律視為違反本 mode。

### 2.6 Codex Commit Mode

- **適用情境**：Product Owner 已核准 Commit 方向，Codex 協助準備 commit 訊息與範圍草案（`codex_commit_approval` Gate 通過後）。
- **允許動作**：草擬 commit message、列出建議 stage 的檔案清單（明確列出檔名，而非萬用字元）、標示應排除的檔案。
- **禁止動作**：實際執行 `git add`（含 `git add .`）、`git commit`、`git push`；不得自行決定最終 commit scope。
- **是否可低中斷執行**：**不可以**。Commit 類任務不得低中斷。
- **是否需要 Product Owner 明確核准**：**是，每一步都需要**——包含是否採用建議的 commit scope、commit message 是否需要修改、是否實際執行 commit。
- **風險等級**：high。
- **sandbox / permission 原則**：即使準備 commit 草案，也不得自行執行任何會改變 git 狀態的指令；實際 `git add` / `git commit` 只能由 Product Owner 親自執行或明確授權後才可執行。

### 2.7 Codex Push Mode

- **適用情境**：Product Owner 已核准 Push 方向，Codex 協助確認 push 前檢查清單（`codex_push_approval` Gate 通過後）。
- **允許動作**：確認目前 commit hash、目標 remote/branch、是否有未預期的 upstream 變更（唯讀檢查）。
- **禁止動作**：實際執行 `git push`、`git push --force`、任何寫入類 git 指令。
- **是否可低中斷執行**：**不可以**。Push 類任務不得低中斷。
- **是否需要 Product Owner 明確核准**：**是，每一步都需要**。
- **風險等級**：high。
- **sandbox / permission 原則**：唯讀檢查為主；實際 `git push` 只能由 Product Owner 親自執行或明確授權後才可執行。

---

## 3. Mode Summary Table

| Mode | 可低中斷 | 需 PO 明確核准 | 風險等級 |
|---|---|---|---|
| Claude Implementation Mode | 是（限核准 Scope 內） | 進入前需要 | medium |
| Claude Must Fix Mode | 是（限核准 Scope 內） | 進入前需要 | medium |
| Codex Review Mode | 是 | 進入前需要 | low |
| Codex Final Review Mode | 是 | 進入前需要 | low |
| Codex Git Review Mode | 是（僅唯讀指令） | 進入前需要 | medium |
| Codex Commit Mode | 否 | 每一步都需要 | high |
| Codex Push Mode | 否 | 每一步都需要 | high |

---

## 4. Relationship to Product Owner Gates

Each mode is entered only after its corresponding Product Owner Gate (see `docs/development/telegram-po-gate-notification-specification.md` Section 2) has been explicitly approved. Entering a mode never happens automatically, and completing a mode never automatically advances to the next Gate — Product Owner always reviews the output (report, review, or handoff package) before approving the next Gate.

---

## 5. Sandboxed Low-Risk Auto-Approval Policy (Sprint-016)

This section defines **Safety Levels** for individual tools/commands that Claude Code or Codex may run while operating inside an already-approved mode (Section 2). Safety Levels classify *commands*, not *Product Owner Gate decisions* — see the important distinction in Section 5.5.

### 5.1 Level 0 — Read-Only Sandbox Safe (may be auto-approved)

A command qualifies for Level 0 only if it satisfies **all** of the following simultaneously: sandboxed, read-only, non-destructive, pre-planned, no file modification, no git state change, no runtime state change, no external service operation, no credential / secret access, no scope expansion.

Allowed examples: `ls`, `pwd`, `cat`, `sed -n`, `grep`, `find`, `git status --short`, `git diff --name-only`, `git diff --cached --name-only`, `git branch --show-current`, `git remote -v`, `git log -1 --oneline`.

Level 0 commands may be run without asking Product Owner for permission on each individual invocation, **within the bounds of an already-approved mode**. Level 0 status never extends to approving a Product Owner Gate itself (Section 5.5), and never extends to a command outside this exact list without being re-classified first.

### 5.2 Level 1 — Local Write, Sprint-Allowed Files Only

Writing to files that are explicitly listed as Allowed Files in the active Sprint's Architecture / Handoff Package. Not auto-approved; requires the Handoff Package's existing authorization to enter the mode (Section 2), but does not require a fresh approval for each individual write within that already-approved scope.

### 5.3 Level 2 — Review / Validation

Running tests, linters, or other validation commands scoped to the active Sprint. Not fully auto-approved; requires the mode's existing Handoff Package authorization, same as Level 1.

### 5.4 Level 3 — High Risk / Manual Gate Required (never auto-approved)

Always requires explicit, synchronous Product Owner approval, regardless of mode:

```text
git add
git commit
git push
rm
mv
chmod
chown
curl
wget
scp
ssh
docker exec
docker compose up/down
modifying n8n workflow JSON
modifying Telegram notification runtime behavior
modifying notification delivery behavior
automatically invoking Claude
automatically invoking Codex
credential / secret access
scope expansion
approving a high-risk Product Owner Gate
approving a commit Gate
approving a push Gate
```

### 5.5 Critical Distinction: Command Safety Level ≠ Gate Approval

A Safety Level classifies a **tool invocation**, not a **Product Owner Gate decision**. All 21 Product Owner Gates defined in `docs/development/telegram-po-gate-notification-specification.md` require explicit Product Owner approval regardless of their `risk_level` metadata — a `low`-risk Gate (e.g. `sprint_start_approval`) is never auto-approved just because Level 0 commands could safely be used to gather information for it. Level 0 only means: while preparing information for *any* Gate (including the 4 high-risk Commit/Push Gates), Claude Code / Codex may freely run Level 0 read-only commands like `git status --short` without asking permission for each one — it never means the Gate's own approval can be skipped, automated, or inferred from the results of those commands.

## 6. Out of Scope

This document does not define: Telegram button auto-execution, n8n Execute Command, automatic Claude/Codex invocation, automatic Commit, automatic Push, full sandbox bypass, AI Auto Loop, multi-user permission management, or a Web UI / Notification Center. None of these are introduced by Sprint-014 or Sprint-016. Sprint-016's Sandboxed Low-Risk Auto-Approval Policy (Section 5) does not change this: Level 0 is strictly read-only and cannot be used to implement, approximate, or work around any of the excluded items above.
