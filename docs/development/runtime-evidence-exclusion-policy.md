# Runtime Evidence Exclusion Policy

Version: 1.0 (Sprint-015)

## 1. 目的

Sprint-013／Sprint-014 建立的 Telegram 通知 runtime（`scripts/review_bridge.sh notify` / `notify-gate`）在執行時會產生 Notification Package 檔案與 `reviews/notification_history.jsonl` 紀錄。這些是「執行的證據（evidence）」，不是「原始碼」。本政策明確定義：這些 runtime evidence 預設不進入 git commit，以及例外情境的處理方式。

## 2. Runtime Evidence 預設不 Commit

Runtime Evidence（依 `docs/development/repository-hygiene-policy.md` 2.4 分類）預設一律不納入 commit，包含但不限於：

- `reviews/notification_history.jsonl`
- `reviews/*/round-*/notifications/*.md`（Sprint-013 事件通知與 Sprint-014 Gate 通知產生的 Notification Package）
- 任何 dry-run 或 live-run 過程中產生的暫存輸出

## 3. Notification History 預設不 Commit

`reviews/notification_history.jsonl` 是 append-only 的執行紀錄檔（見 `docs/development/notification-package-specification.md`、`docs/development/telegram-po-gate-notification-specification.md`），會隨每次 `notify` / `notify-gate` 執行持續增長，內容反映的是「這台機器、這個時間點實際執行了什麼」，而不是可追蹤、可 review 的原始碼變更。**預設不 commit。**

## 4. Generated Notification Packages 預設不 Commit

`reviews/<sprint-id>/round-<round>/notifications/*.md` 是 `notify` / `notify-gate` 執行當下產生的輸出檔案，內容由 runtime 動態產生（時間戳記、hash、實際狀態），每次重新執行都可能不同。**預設不 commit。**

## 5. Dry-Run Evidence 預設不 Commit

`--dry-run` 模式下即使沒有實際寫入檔案，任何為了驗證行為而產生的暫存輸出、log、或截圖，都屬於 Runtime Evidence，**預設不 commit**。

## 6. Live-Run Evidence 預設不 Commit

實際對 Telegram 發送訊息後產生的 evidence（例如送出成功/失敗的紀錄、送出內容的暫存副本），**預設不 commit**。若需要向 Product Owner 證明「這次 Sprint 的 Telegram 功能真的可以送達」，應以文字方式摘要記錄在對應的 `claude_report.md` 或 review artifact 中（見第 8 節），而不是把原始 runtime state 本身加入 commit。

## 7. Local Runtime State 不 Commit

任何只對執行當下的機器/環境有意義的狀態（暫存目錄、cache、機器特定路徑），一律不 commit（見 `docs/development/repository-hygiene-policy.md` 2.5 Local State）。

## 8. 例外情境必須經 Product Owner 核准

若某次 Sprint 有正當理由需要把特定 runtime evidence 納入 commit（例如作為長期回歸測試的 fixture、或作為稽核用途的固定快照），必須：

1. 在該 Sprint 的 Architecture Artifact 中明確列出這是例外，並說明理由。
2. 取得 Product Owner 的明確核准（不得由 Claude Code 或 Codex 自行決定納入）。
3. 明確標示這份被 commit 的 evidence 是「固定快照」，未來執行不會、也不應該持續覆寫它。

## 9. 若需要保留 Evidence，應以摘要方式納入正式 Artifact

當需要讓 Product Owner 或未來的 Review 知道「某次執行的結果」時，正確做法是：把關鍵結論（例如：測試通過筆數、Telegram 是否送達、delivery_status 為何）**摘要成文字**寫進 `claude_report.md`、`codex_review.md` 等正式 Sprint Review Artifact 內，而不是直接把 runtime 產生的原始檔案（`notification_history.jsonl`、Notification Package `.md`）加入 commit。

這樣可以讓正式 artifact 保持精簡、可讀、可長期追蹤，而不會被逐次執行都會變化的 runtime 輸出稀釋。
