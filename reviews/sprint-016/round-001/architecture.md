# Sprint-016 Architecture — Product Owner Gate Metadata Canonicalization, Validation Hardening, and Sandboxed Low-Risk Auto-Approval Policy

## 0. Provenance Note

此 Architecture 內容來源為 Product Owner 已核准的 Sprint-016 Handoff Package（Product Owner Decision / Architecture Definition / Architecture Artifact 三項皆已核准），由 Product Owner 直接於 Claude Code Implementation Handoff Package 中提供。這不是 Claude Code 自行設計的 Architecture；Claude Code 只負責依此進行 Implementation。

## 1. Sprint Goal

三件事：(1) 建立 Product Owner Gate Metadata canonical artifact；(2) 強化 `notify-gate` validation 與必要測試；(3) 建立 Claude / Codex sandboxed low-risk auto-approval safety model。不導入 AI Auto Loop，不讓 Claude / Codex 自動互相呼叫，不讓 commit / push / high-risk Gate 自動通過。

## 2. Scope Boundary

### Allowed Files

```text
docs/development/product-owner-gate-metadata.md
docs/development/telegram-po-gate-notification-specification.md
docs/development/execution-permission-policy.md
scripts/review_bridge.sh
scripts/test_review_bridge.sh
reviews/sprint-016/round-001/architecture.md
reviews/sprint-016/round-001/claude_report.md
```

`scripts/review_bridge.sh` / `scripts/test_review_bridge.sh` 只在 validation hardening 確實需要時修改；若判斷不需要，`claude_report.md` 必須明確聲明未修改、不需要 full regression test。

### Prohibited Files

```text
configs/n8n/*.json
reviews/notification_history.jsonl
reviews/*/notifications/
reviews/sprint-013/round-001/notifications/
reviews/sprint-014/round-001/notifications/
reviews/sprint-015/round-001/dirty-files-inventory.md
```

以下 unrelated dirty/untracked files 不得混入：`AGENTS.md`、`CLAUDE.md`、`CODEX.md`、`GPT.md`、`docs/architecture.md`、`docs/vision.md`、`docs/principles.md`、`docs/roadmap.md`、`docs/development/n8n-*.md`、`reviews/notification-gap-review.md`、`reviews/sprint-004/`、`reviews/sprint-006/`、`reviews/sprint-007/`、`reviews/sprint-009/`、`reviews/sprint-013/round-001/notifications/`。

### Out of Scope

AI Auto Loop、Claude/Codex 自動互相呼叫、commit/push/high-risk Gate 自動通過、修改 n8n workflow JSON、修改 Telegram delivery behavior、修改 Sprint-013/014 已 CLOSED 結論、刪除或搬移檔案、清理 unrelated dirty/untracked files。

## 3. Implementation Requirements

1. 建立 `reviews/sprint-016/round-001/architecture.md`（本檔案）。
2. 建立 `docs/development/product-owner-gate-metadata.md`：21 個 Gate 的 canonical metadata，每個 Gate 含 14 個欄位（gate_id、中文名稱、Gate 說明、notification_recipient、next_actor、recommended_execution_mode、risk_level、Product Owner 下一步、Handoff Package 用途、是否 high-risk gate、是否 commit/push sensitive、是否允許 sandboxed read-only auto-approval、Manual Gate requirement、metadata completeness status）。
3. 有限度更新 `docs/development/telegram-po-gate-notification-specification.md`：引用 canonical metadata artifact、補上 21-Gate metadata table 參照、補強 `notify-gate` CLI usage、釐清 delivery_status wording、釐清 notification_recipient 與 next_actor 差異、釐清 high-risk Gate message wording、釐清 commit/push Gate 必須 Product Owner Manual Gate。
4. 有限度更新 `docs/development/execution-permission-policy.md`：新增 Sandboxed Low-Risk Auto-Approval Policy（Safety Level 0/1/2/3）、Level 0 read-only 自動同意條件、forbidden auto-approval actions、明確保留 commit/push/high-risk Gate 的 Manual Gate、明確禁止 AI Auto Loop、明確禁止 Claude/Codex 自動互相呼叫。
5. 若需要，對 `scripts/review_bridge.sh` 的 `notify-gate` 相關程式碼做 validation hardening（gate_id/next_actor/recommended_execution_mode/risk_level 驗證、high-risk wording 驗證、delivery_status wording 釐清），不得改變 Telegram delivery behavior、n8n behavior、AI execution behavior，且**僅限 Sprint-014 新增的 `notify-gate` 相關程式碼，不得觸碰 Sprint-013 的 `notify`（事件通知）程式碼**——因為 Sprint-013 已 CLOSED，且其規格文件 `docs/development/notification-package-specification.md` 不在本 Sprint Allowed Files 之列。
6. 若修改 script，`scripts/test_review_bridge.sh` 補齊對應測試；若未修改 script，明確聲明不需要 full regression test。

## 4. Sandboxed Low-Risk Auto-Approval Safety Model

### Level 0: Read-Only Sandbox Safe（可自動同意）

必須同時符合：sandboxed、read-only、non-destructive、pre-planned、no file modification、no git state change、no runtime state change、no external service operation、no credential/secret access、no scope expansion。允許範例：`ls`、`pwd`、`cat`、`sed -n`、`grep`、`find`、`git status --short`、`git diff --name-only`、`git diff --cached --name-only`、`git branch --show-current`、`git remote -v`、`git log -1 --oneline`。

### Level 1: Local Write, Sprint-Allowed Files Only（不可自動同意，需明確 Handoff Package 授權）

### Level 2: Review / Validation（不可完全自動同意，需明確 Handoff Package 授權）

### Level 3: High Risk / Manual Gate Required（必須 Product Owner 手動核准）

包含：`git add`、`git commit`、`git push`、`rm`、`mv`、`chmod`、`chown`、`curl`、`wget`、`scp`、`ssh`、`docker exec`、`docker compose up/down`、修改 n8n workflow JSON、修改 Telegram runtime、修改 notification delivery behavior、自動呼叫 Claude、自動呼叫 Codex、credential/secret access、scope expansion、high-risk gate、commit gate、push gate。

**重要限制**：Safety Level 是「工具/指令層級」的分類，不是「Gate 核准」的分類。21 個 Product Owner Gate 的核准動作本身，不論其 Safety Level 為何，一律仍需要 Product Owner 明確決策——Level 0 的存在只是允許 Claude/Codex 在準備 Gate 所需資訊時，可以自由使用唯讀指令而不需逐一詢問，不代表 Gate 本身可以被自動核准。

## 5. Delivery Status Wording Clarification

必須明確區分 **Notification Package Status**（Notification Package 檔案產生當下記錄的狀態，一律為 `pending`，代表「尚未嘗試送出」）與 **Actual Delivery Status**（Telegram 實際送出後的真實結果，只記錄在 `reviews/notification_history.jsonl`，`delivered`/`failed`/`disabled`/`skipped_duplicate` 之一）。Telegram message wording 必須避免讓 Product Owner 誤以為 Package 裡的 `delivery_status: pending` 就是「已確認送達」。

## 6. High-Risk Gate Wording

`commit_approval`、`codex_commit_approval`、`push_approval`、`codex_push_approval` 必須明確表示：此 Gate 涉及 repository state / remote state；必須 Product Owner Manual Gate；不得自動同意；不得自動 commit/push；Codex 只能在 Product Owner 核准後執行。

## 7. Claude Implementation Boundary

Claude Code 只負責依本 Architecture 建立/更新第 3 節列出的檔案，不得修改 Sprint-013/014 已 CLOSED 的規格文件或 `notify`（事件通知）程式碼，不得刪除/搬移任何檔案，不得 `git add`/`commit`/`push`。

## 8. Codex Review Boundary

確認：canonical metadata 是否與 `scripts/review_bridge.sh` 的 `_gate_resolve_metadata()` 完全一致；規格文件更新是否僅限授權的 7 項內容、未擴大；Execution Permission Policy 的 Safety Level 定義是否清楚、Level 3 是否完整涵蓋 Commit/Push/高風險操作；若有 script 修改，是否確實不改變 Telegram delivery/n8n/AI execution behavior；測試是否涵蓋 Testing Requirements 全部 9 項。

## 9. Validation Strategy

若修改 `scripts/review_bridge.sh` 或 `scripts/test_review_bridge.sh`，執行 `bash scripts/test_review_bridge.sh` 並回報 total passed/failed、是否新增測試、是否涵蓋 Sprint-016 validation hardening；若未修改，明確聲明 `No script/runtime code modified; full regression test not required.`

## 10. Definition of Done

1. `product-owner-gate-metadata.md` 完整涵蓋 21 個 Gate、每個 14 個欄位，且與 runtime 完全一致。
2. Telegram 規格文件與 Execution Permission Policy 依授權範圍更新完成。
3. 若有 validation hardening，測試全數通過且新增測試涵蓋 9 項 Testing Requirements。
4. 未修改 Prohibited Files、未刪除/搬移任何檔案、未 `git add`/`commit`/`push`。
5. Next Actor = Codex，Recommended Execution Mode = Codex Review Mode。
