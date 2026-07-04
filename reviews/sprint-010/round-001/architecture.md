# Sprint-010：Handoff Package MVP

## Architecture Baseline v1.0

## 1. Sprint 資訊

Sprint ID：sprint-010

Sprint Name：Handoff Package MVP

Sprint Type：architecture / implementation preparation

Status：Approved by Product Owner

## 2. 背景

Workflow 1 與 Workflow 2 已完成 Telegram Notification 能力。

目前 Product Owner 已能收到：

* Claude 完成通知
* Codex Review 完成通知

但實際使用後發現，Notification 只解決「知道事件發生」，沒有解決「如何把完整交接內容交給下一位 AI」。

目前 Product Owner 仍需手動：

* 閱讀 Claude Report
* 閱讀 Codex Review
* 整理下一步任務
* 整理限制條件
* 整理可貼給下一位 AI 的 Prompt

因此真正缺口不是新的通知，而是標準化 Handoff Package。

## 3. Problem Statement

Review Bridge 目前可以協助產生 Review / Consensus / Notification 相關流程，但 Manual Gate 仍缺少一個標準 Artifact：

handoff_package.md

這會造成：

* Product Owner 每次都要自行整理交接內容
* AI 之間交接格式不一致
* 下一位 AI 需要依賴對話歷史才能理解任務
* Workflow 1、Workflow 2 已完成，但交接成本仍偏高

## 4. Sprint 目標

Sprint-010 的唯一目標：

讓每一個 Manual Gate 都能產生一份可直接複製給下一位 AI 的 Handoff Package。

標準流程：

Claude 完成
→ Review Bridge
→ 產生 Handoff Package
→ Telegram
→ Product Owner
→ 複製
→ Codex

或：

Codex Review 完成
→ Review Bridge
→ 產生 Handoff Package
→ Telegram
→ Product Owner
→ 複製
→ Claude

## 5. 核心原則

### 5.1 Review Bridge 是唯一 Handoff Producer

Handoff Package 必須由 Review Bridge / AI Workspace 產生。

不得由：

* ChatGPT 日常臨時產生
* Claude Code 自行整理
* Codex 自行整理
* Telegram Workflow 自行組裝

### 5.2 Product Owner 保留 Manual Gate

Handoff Package 只提供可複製內容。

不得自動呼叫下一個 AI。

Product Owner 仍是唯一決定者：

* 是否交給下一位 AI
* 是否修改內容
* 是否暫停流程
* 是否進入下一階段

### 5.3 Notification 與 Handoff 分離

Notification 的用途是通知事件。

Handoff Package 的用途是工作交接。

Telegram 可以推播 Handoff Package 的內容或摘要，但 Telegram 不應成為 Handoff 內容的來源。

### 5.4 不新增 AI 自動化

Sprint-010 不得新增：

* AI 自動互相呼叫
* Claude 自動叫 Codex
* Codex 自動叫 Claude
* AI Runner
* Workflow Engine
* Queue
* Database
* Agent Loop

## 6. 新增 Artifact

Sprint-010 新增標準 Artifact：

handoff_package.md

建議位置：

reviews/{sprint_id}/round-{round_id}/handoff_package.md

例如：

reviews/sprint-010/round-001/handoff_package.md

此 Artifact 與以下檔案同層級：

* architecture.md
* claude_report.md
* codex_review.md
* consensus_report.md
* final_consensus.md

## 7. Handoff Package 標準格式

handoff_package.md 必須採固定 Markdown 結構。

最小格式如下：

# Handoff Package

## 1. Target AI

下一位應接手的 AI。

允許值：

* Claude Code
* Codex
* ChatGPT

Sprint-010 MVP 主要支援：

* Claude Code → Codex
* Codex → Claude Code

## 2. Current Stage

目前流程階段。

例如：

* Claude Implementation Completed
* Codex Review Completed
* Codex Final Review Completed
* Architecture Approved

## 3. Objective

下一位 AI 要完成的唯一任務。

必須簡潔、明確、不可包含多個不相關目標。

## 4. Required Reading

下一位 AI 必須閱讀的檔案清單。

例如：

* PROJECT_BOOTSTRAP.md
* docs/development/consensus-workflow.md
* scripts/review_bridge.sh
* reviews/{sprint_id}/round-{round_id}/architecture.md
* reviews/{sprint_id}/round-{round_id}/claude_report.md
* reviews/{sprint_id}/round-{round_id}/codex_review.md

## 5. Scope

明確列出本次允許處理的範圍。

## 6. Out of Scope

明確列出本次禁止處理的範圍。

至少必須包含：

* 不新增 AI 自動互叫
* 不新增 Workflow Engine
* 不新增 Prompt Generator
* 不新增 Queue / Database
* 不改變 Manual Gate
* 不改變既有角色分工

## 7. Acceptance Criteria

下一位 AI 完成任務後，必須滿足的驗收條件。

## 8. Copyable Prompt

可直接複製貼給下一位 AI 的完整 Prompt。

此區塊是 Product Owner 最主要使用的內容。

必須完整、自包含，不依賴 Telegram 訊息上下文。

## 8. Review Bridge 行為要求

Sprint-010 實作時，Review Bridge 應支援產生 handoff_package.md。

產生方式應以既有 Review Artifact 為資料來源，不應呼叫 LLM 重新生成內容。

資料來源包含但不限於：

* architecture.md
* claude_report.md
* codex_review.md
* consensus_report.md
* final_consensus.md
* sprint_meta.env

若必要資料不存在，Review Bridge 應明確失敗或輸出 PLACEHOLDER，不應靜默產生錯誤內容。

## 9. Telegram 行為要求

Telegram Workflow 可以讀取 handoff_package.md，並將其推播給 Product Owner。

但 Telegram 不得負責組裝 Handoff Package。

Handoff Package 的產生責任仍屬於 Review Bridge。

## 10. MVP 支援場景

Sprint-010 MVP 至少支援以下兩種 Manual Gate：

### 10.1 Claude 完成後交給 Codex Review

輸入：

* architecture.md
* claude_report.md

輸出：

* handoff_package.md

Target AI：

Codex

Copyable Prompt 目的：

要求 Codex 依 Architecture Review Claude Implementation。

### 10.2 Codex Review 完成後交給 Claude 修正

輸入：

* architecture.md
* claude_report.md
* codex_review.md

輸出：

* handoff_package.md

Target AI：

Claude Code

Copyable Prompt 目的：

要求 Claude 只修正 Codex Review 指出的問題，不擴大 Scope。

## 11. Definition of Done

Sprint-010 完成後必須滿足：

* Review Bridge 可以產生 handoff_package.md
* 每個 Manual Gate 可以同時具備 Notification 與 Handoff Package
* Handoff Package 可直接複製給下一位 AI
* Product Owner 不需自行整理交接 Prompt
* Manual Gate 保留
* 不新增 AI 自動互相呼叫
* 不新增 Workflow Engine / AI Runner / Queue / Database
* 既有 Workflow 1、Workflow 2 不被破壞
* 既有測試必須通過

## 12. Explicit Non-Goals

Sprint-010 明確不處理：

* 自動派工給 Claude
* 自動派工給 Codex
* 自動 Review Loop
* 多 AI 對話引擎
* Web UI
* Database Schema
* Prompt Generator Service
* n8n 大改版
* Telegram Bot 指令互動
* Git Commit / Push 自動化

## 13. Implementation Guidance

後續 Implementation 應優先採用最小改動。

建議：

* 延伸 scripts/review_bridge.sh 既有指令
* 不重構整個 Review Bridge
* 不改變既有檔案命名規則，除非必要
* 不破壞目前 Workflow 1 / Workflow 2
* 新增測試覆蓋 handoff_package.md 產生邏輯
* PLACEHOLDER 與 READY 判斷需與既有 Review Bridge 行為一致

## 14. Product Owner Approval

此 Architecture Baseline v1.0 已由 Product Owner 核准。

後續 Claude Code Implementation 必須嚴格依此 Architecture 執行，不得自行擴大 Scope。
