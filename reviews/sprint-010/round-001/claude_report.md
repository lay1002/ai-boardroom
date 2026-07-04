# claude_report.md

Sprint: sprint-010
Round: round-001
Sprint Type: implementation
Feature: Handoff Package MVP

---

## Implementation Summary

依 `reviews/sprint-010/round-001/architecture.md`（Architecture Baseline v1.0，Approved by Product Owner）實作 Handoff Package MVP：`scripts/review_bridge.sh check` 在判定 `claude_report.md` 或 `codex_review.md` 為 READY 時，除既有的 n8n Notification（Workflow 1/2）之外，同時產生 `reviews/<sprint_id>/round-<round>/handoff_package.md`，內容為 Architecture 第 7 節定義的固定 8 節 Markdown 格式，純樣板拼接，不呼叫 LLM，資料來源完全取自既有 Review Artifact 的檔案路徑與既有 `ready[]` 分類結果。

實作 Architecture 第 10 節明確定義的兩個 MVP 場景：

- **10.1 Claude 完成 → Codex**：`claude_report.md` READY 時觸發，Target AI = Codex。
- **10.2 Codex Review 完成 → Claude**：`codex_review.md` READY 時觸發，Target AI = Claude Code。

`codex_final_review.md` READY 時只觸發既有 Notification（Workflow 2），不產生新的 Handoff 場景——因為 Architecture 只定義了以上兩個方向，未定義第三個場景。

---

## 修改檔案

```text
scripts/review_bridge.sh        — 新增 Handoff Package 產生邏輯
scripts/test_review_bridge.sh   — 新增 Test 20（13 項子案例）
```

未新增任何文件檔案；`handoff_package.md` 是執行期依實際 Sprint 資料動態產生的 artifact。

### `scripts/review_bridge.sh` 新增內容

- `_array_contains`：對 `cmd_check` 已算好的 `ready[]`/`missing[]`/`placeholder[]` 陣列做成員檢查，不重新掃描檔案系統。
- `_handoff_ref`：依成員檢查結果回傳真實檔案路徑，或明確的 `PLACEHOLDER: ...` 字串（Architecture 第 8 節要求：必要資料不存在時應明確失敗或輸出 PLACEHOLDER，不應靜默產生錯誤內容）。
- `write_handoff_package_claude_to_codex` / `write_handoff_package_codex_to_claude`：純樣板拼接產生固定 8 節格式的 `handoff_package.md`，皆支援 `--dry-run`（不寫檔，只印 would-write 訊息）。
- `cmd_check` 內既有的 `ready[]` 分派迴圈（原本只呼叫 Notification）擴充為同時呼叫對應的 Handoff Package 產生函式，沿用同一個 `ready[]` 陣列，未新增第二套 READY 判斷邏輯。

---

## 測試方式與結果

```bash
bash scripts/test_review_bridge.sh
```

結果：**90 passed, 0 failed**（原有 77 個測試 + 新增 Test 20 的 13 項子案例，涵蓋 PLACEHOLDER 標示、READY 後升級為真實路徑、多階段覆寫、`--dry-run` 不寫檔、documentation Sprint Type 正確引用 `reviewed_document.md`）。同時重跑 Workflow 1、Workflow 2 既有測試，零迴歸。

另以 `bash -n scripts/review_bridge.sh` 語法檢查通過，並手動以真實命名格式（`sprint-010`）跑過一次端對端 demo，確認產生內容格式正確、路徑文字無誤（曾發現並修正一個文字重複的 bug：模板原本寫死 `sprint-$sprint_id` 前綴，導致對真實 sprint_id（本身已含 `sprint-` 前綴）產生 `sprint-sprint-010` 的重複文字，已修正為直接使用 `$sprint_id`）。

---

## 已知限制

- `handoff_package.md` 未加入 `required`/consensus 判斷陣列，不影響 Gate Status 判定，純粹是額外產生的輔助 artifact（Architecture 未要求它參與 Gate 判斷）。
- 沿用既有 Notification 的已知限制：`check` 重複執行時 `handoff_package.md` 會被重新覆寫，沒有版本歷程或去重機制。
- 目前 n8n Workflow 1/2 的 Webhook payload 只包含 `claude_report.md`/`codex_review.md`/`codex_final_review.md` 的路徑，尚未包含 `handoff_package.md` 的路徑或內容，Telegram 通知目前無法直接推播 Handoff Package 內容（此為 Architecture 第 9 節已預期但尚未實作的銜接點）。

---

## 是否符合 Architecture / Definition of Done

符合。逐項對照 Architecture 第 11 節 Definition of Done：Review Bridge 可產生 handoff_package.md、每個 Manual Gate 同時具備 Notification 與 Handoff Package（claude_report.md、codex_review.md 兩個 Gate）、Handoff Package 可直接複製給下一位 AI、Manual Gate 保留、未新增 AI 自動互相呼叫、未新增 Workflow Engine/AI Runner/Queue/Database、既有 Workflow 1/2 未被破壞、既有測試全數通過。

## Scope Expansion

Scope Expansion: No

本次僅依 Architecture 定義的兩個 MVP 場景（10.1、10.2）實作，未新增 Architecture 未定義的第三個場景，未新增任何 AI 自動呼叫、Workflow Engine、Queue、Database。

---

尚未 commit，等待 Codex Review。
