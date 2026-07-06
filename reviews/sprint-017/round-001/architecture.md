# Sprint-017 Architecture — Handoff Template Standardization & Notification Gate Execution Policy

## 0. Provenance Note

此 Architecture 內容來源為 Product Owner 已核准的 Sprint-017 決策（方向、Architecture Definition、Architecture Artifact 三項皆已核准），由 Product Owner 直接於 Claude Code Implementation Handoff Package 中提供。這不是 Claude Code 自行設計的 Architecture；Claude Code 只負責依此進行 Implementation，不得自行擴大或縮小範圍。

## 1. Sprint Goal

將 Sprint-016 Retrospective 中確認的流程改善項，正式納入 AI Workspace 的文件、Handoff Package Template、Claude / Codex report template、Review Bridge 行為、validation 與 tests。

## 2. In Scope（6 項必須完成項目）

1. Full Reading List Standardization — 所有正式 Handoff Package 開頭必須包含完整 10 項閱讀清單，不得使用縮短版。
2. Context Completeness Check — Claude Implementation Report / Claude Must Fix Report / Codex Review Report / Codex Final Review Report 必須包含此區塊。
3. Telegram Notification Block — 所有正式 Handoff Package 必須新增此區塊，gate_id 必須來自 `docs/development/product-owner-gate-metadata.md` 的 canonical metadata，不得使用 placeholder。
4. notify-gate Execution Policy — 正式固化「Claude/Codex 不得自動觸發 Telegram、notify-gate 一律由 Product Owner 手動決定執行」。
5. Manual Handoff vs. Formal Telegram Gate Notification — 明確區分兩者，只有實際執行 `notify-gate` 且 Telegram 收到通知才算正式完成。
6. Retrospective / Actual Flow Report 補強 — 新增 Flow Deviation Check 區塊。

## 3. Out of Scope

不得擴大 scope；不得修改 n8n JSON；不得自動觸發 Telegram；不得執行 notify-gate；不得 commit；不得 push；不得處理 unrelated dirty / untracked files；不得修改 Sprint-013/014/015/016 已 CLOSED artifacts；不得進入 Git / Codex Review / Codex Git Review（本階段只允許 Claude Code Implementation）。

## 4. Allowed Candidate Files

```text
docs/development/development-workflow.md
docs/development/consensus-workflow.md
docs/development/telegram-po-gate-notification-specification.md
docs/development/execution-permission-policy.md
scripts/review_bridge.sh
scripts/test_review_bridge.sh
reviews/sprint-017/round-001/architecture.md
reviews/sprint-017/round-001/claude_report.md
```

若 repo 中已有更精準的 handoff template / report template 檔案（非上述清單），Claude Code 可依 Architecture 目標更新，但必須在 `claude_report.md` 中明確列出並說明理由。

## 5. Prohibited Files

```text
configs/n8n/*.json
reviews/notification_history.jsonl
reviews/*/notifications/
Sprint-013 / Sprint-014 / Sprint-015 / Sprint-016 已 CLOSED artifacts
unrelated dirty / untracked files（AGENTS.md、CLAUDE.md、CODEX.md、GPT.md、docs/architecture.md、docs/development/n8n-*.md、docs/vision.md、reviews/sprint-004/、docs/principles.md、docs/roadmap.md、reviews/notification-gap-review.md、reviews/sprint-006/、reviews/sprint-007/、reviews/sprint-009/ 等）
```

不得使用 `git add .` / `git add -A` / `git add docs/` / `git add reviews/`。本階段不得 commit、不得 push。

## 6. Required Content Detail

### 6.1 Full Reading List（正式 Handoff Package 開頭）

```text
請閱讀：

- PROJECT_BOOTSTRAP.md
- AGENTS.md
- GPT.md
- CLAUDE.md
- CODEX.md
- docs/development/development-workflow.md
- docs/development/consensus-workflow.md
- docs/development/n8n-claude-done-notification.md
- docs/development/n8n-codex-review-done-notification.md
- scripts/review_bridge.sh

若上述文件不存在，請在 report 中記錄為 Missing Context，不要自行建立或補寫。
```

### 6.2 Context Completeness Check（Claude / Codex report 適用）

```markdown
## Context Completeness Check

- Full required reading list provided: PASS / FAIL
- Missing context files: None / list
- Did missing context affect implementation or review: YES / NO
- Notes:
```

適用範圍：Claude Implementation Report、Claude Must Fix Report、Codex Review Report、Codex Final Review Report。

### 6.3 Telegram Notification Block（正式 Handoff Package 適用）

```text
Telegram Notification:

- Should notify Product Owner: YES / NO
- gate_id: <actual_gate_id>
- sprint_id: sprint-017
- round_id: 001
- artifact_path: <path>
- Expected Telegram result: Product Owner receives copyable Handoff Package for next actor
```

gate_id 必須來自 `docs/development/product-owner-gate-metadata.md` 的 canonical 21-Gate 清單，不得使用 placeholder 或猜測值。

### 6.4 notify-gate Execution Policy

Claude / Codex 不得自動觸發 Telegram；Product Owner 決定是否手動執行 `notify-gate`；`notify-gate` 屬於外部通知操作，預設需要 Product Owner 明確允許。正確 CLI 格式：

```bash
./scripts/review_bridge.sh notify-gate <gate_id> <sprint_id> <round_id> <artifact_path>
```

第一個參數是 `gate_id`，不是 `sprint_id`。Claude Code 不得執行 `notify-gate`。

### 6.5 Manual Handoff vs. Formal Telegram Gate Notification

- **聊天中手動交接**：Product Owner 直接在 ChatGPT 對話中取得 Handoff Package，並手動複製給 Claude Code 或 Codex。此模式**不代表** Telegram 已通知。
- **正式 Telegram Gate Notification**：Product Owner 明確允許並執行 `notify-gate`，使 Telegram 收到正式 Gate Notification。只有實際執行 `notify-gate` 且 Telegram 收到通知後，才可記錄為正式 Telegram Gate Notification 完成。

### 6.6 Retrospective / Actual Flow Report Flow Deviation Check

```markdown
## Flow Deviation Check

- Full reading list used in all formal Handoff Packages: PASS / FAIL
- Any shortened reading list used: YES / NO
- Context Completeness Check present in Claude / Codex reports: PASS / FAIL
- Missing context files recorded: YES / NO / N/A
- Telegram Notification block present in formal Handoff Packages: PASS / FAIL
- notify-gate expected: YES / NO
- notify-gate executed by Product Owner: YES / NO
- Telegram notification received: YES / NO / NOT VERIFIED
- Manual handoff used instead of Telegram notification: YES / NO
- Manual Gate skipped: YES / NO
- Review scope drift occurred: YES / NO
- unrelated dirty / untracked files mixed into Sprint scope: YES / NO
- Notes:
```

## 7. Test Requirements

至少驗證：Handoff Package 含完整 reading list、不使用縮短版、含 Telegram Notification 區塊與其必要欄位、Claude/Codex report template 含 Context Completeness Check、Missing context 規則已文件化、notify-gate 不會被 Claude/Codex 自動執行、manual handoff 不會被誤記為 Telegram notification completed、Retrospective template 含 Flow Deviation Check。Expected result: All tests passed, 0 failed。

## 8. Definition of Done

1. 兩個既有的自動產生 Handoff Package 函式（`write_handoff_package_claude_to_codex`、`write_handoff_package_codex_to_claude`）皆已改用完整 10 項閱讀清單，並新增 Telegram Notification 區塊，gate_id 取自 canonical metadata（非 placeholder）。
2. `docs/development/consensus-workflow.md` 明確記錄 Full Reading List、Context Completeness Check、Telegram Notification Block 為正式 Handoff Package / Report 的必要規範。
3. `docs/development/telegram-po-gate-notification-specification.md` 明確記錄 notify-gate Execution Policy 與 Manual Handoff vs. Formal Telegram Gate Notification 區分。
4. Sprint Retrospective 的 Mandatory Template 新增 Flow Deviation Check 區塊。
5. 新增測試涵蓋全部 10 項 Test Requirements，且既有測試零迴歸。
6. 未修改 Prohibited Files、未 `git add`/`commit`/`push`、未觸發任何 Telegram 送出或 `notify-gate` 執行。
