# Sprint Retrospective

Sprint: sprint-011
Round: round-001
Sprint Name: Development Principles v2.0

## 1. Objective

Sprint-011 的目標是將 Development Principles v2.0 正式制度化，建立 AI Workspace 的 Development Constitution。

本 Sprint 完成以下目標：

- 建立 `docs/development/development-principles.md` 作為 AI Workspace Development Constitution。
- 將 Development Principles v2.0 建立為 Single Source of Truth。
- 讓 `PROJECT_BOOTSTRAP.md` 成為所有 AI session 的入口文件。
- 讓 `development-workflow.md` 與 `consensus-workflow.md` 引用 Development Principles，不再重複定義。
- 將 Definition of Done、Partial Completion is NOT Done、Sprint Retrospective、Product Owner Decision 正式納入治理規範。

## 2. Root Cause

Sprint-011 的根因是 AI Workspace 的開發規範原本分散在多個文件與聊天紀錄中。

這造成以下問題：

- 新 AI session 需要依賴聊天紀錄才能理解最新工作規範。
- Product Owner 需要重複口頭補充流程規則。
- Development Workflow、Consensus Workflow、Sprint Architecture 之間可能出現重複定義或規範漂移。
- Definition of Done 尚未成為所有 Sprint 的共同完成標準。
- Sprint Retrospective 與 Product Owner Decision 尚未成為可追溯的 governance record。

Sprint-011 透過建立 Development Constitution，將這些規範收斂到單一正式來源。

## 3. Lessons Learned

- Repository 必須存在 Architecture Artifact。沒有 repo 內 artifact，Claude / Codex 無法穩定接手，也無法避免依賴聊天紀錄。
- AI 不應依賴聊天紀錄。所有 Architecture、Implementation、Review、Validation、Git Scope Review 都必須能從 repo artifact 追溯。
- Product Owner 不需閱讀程式碼即可完成 Validation。透過 Validation Support，Product Owner 可以依據整理後的 Evidence 判斷是否通過。
- Definition of Done 成功驗證。Sprint-011 實際走完 Architecture、Architecture Artifact、Implementation、Codex Review、Product Owner Validation Support、Git Scope Review，證明 DoD 可作為共同完成標準。
- Scope Check 能有效降低 Git Risk。因 working tree 中存在多個 unrelated dirty changes，Git Scope Review 明確要求 selective staging，避免 Sprint-011 commit 混入其他工作。

## 4. Process Improvement

- Architecture Artifact 成為正式流程。Sprint-011 不再只依賴聊天中的 Architecture Proposal，而是建立 `reviews/sprint-011/round-001/architecture.md` 作為 Claude Implementation 的正式依據。
- Product Owner Validation Support 成功。Codex 可協助 Product Owner 驗證 SSOT、reading order、Acceptance Criteria、禁止項目與實作範圍，讓 Product Owner 不必自行審查技術細節。
- Scope Check 成功降低 Git Risk。`final_consensus.md` 明確列出 Included Files、Excluded Files、Scope Risks 與 selective staging 條件。
- Development Principles v2.0 將 Sprint Retrospective 與 Product Owner Decision 納入 Definition of Done，讓每個 Sprint 都留下治理紀錄。
- Future Sprint 可直接引用 `docs/development/development-principles.md`，不必重複複製七項 Principles。

## 5. Backlog

### Sprint-012: Notification Framework MVP

Sprint-012 建議處理 Notification Framework MVP。

Scope 候選項目：

- Architecture Review PASS Notification
- Architecture Artifact Ready Notification
- Claude Done Notification
- Codex Review Done Notification
- Product Owner Validation Ready Notification
- Git Review PASS Notification
- Commit Done Notification
- Push Done Notification
- Validation Support
- Scenario Validation

Sprint-012 應維持 Manual Gate，不得新增 AI Auto Loop，不得自動呼叫 Claude / Codex，不得自動 Consensus，不得自動 Commit / Push。

## End-to-End Validation Findings

Sprint-011 已完整驗證以下流程：

```text
Architecture
↓
Architecture Artifact
↓
Claude Implementation
↓
Codex Review
↓
Product Owner Validation
↓
Git Scope Review
```

全部流程可正常完成。

但 Sprint-011 End-to-End Validation 也發現：

- Notification 並未覆蓋完整 Manual Gate。
- Product Owner 仍需要主動要求 Validation Support 與 Git Scope Review。
- 現有 notification 能力只覆蓋部分 workflow event，尚未形成完整 Notification Framework。

因此，Notification Framework 已由真實流程驗證需求，正式列入 Sprint-012。

## 6. Product Owner Decision

### 6.1 Accepted

- Development Constitution 正式建立。
- Development Principles v2.0 正式建立。
- Definition of Done 正式建立。
- Validation Support 驗證成功。

### 6.2 Rejected

None.

### 6.3 Deferred

Notification Framework.

Reason:

Sprint-011 End-to-End Validation 已證明目前 Notification 僅覆蓋部分 Workflow。

正式納入 Sprint-012。

### 6.4 New Backlog

Sprint-012: Notification Framework MVP.

Backlog items:

- Architecture Review PASS Notification
- Architecture Artifact Ready Notification
- Claude Done Notification
- Codex Review Done Notification
- Product Owner Validation Ready Notification
- Git Review PASS Notification
- Commit Done Notification
- Push Done Notification
- Validation Support
- Scenario Validation

### 6.5 Strategic Decisions

- Sprint-012 定位為 AI Workspace V1 Final Sprint。
- Sprint-012 完成後 AI Workspace 進入 Maintenance Mode。
- 後續重心轉向：
  - AI Collaboration Engine
  - AI Decision Assistant

### 6.6 Rationale

Sprint-012 定位為最後一個功能 Sprint，原因如下：

- Sprint-011 已完成 Development Constitution、Definition of Done、Product Owner Decision 與 Sprint Retrospective 制度化。
- Sprint-010 已完成 Handoff Package 與 Telegram delivery 的核心交接能力。
- Sprint-011 E2E 顯示剩餘主要缺口不是新的 governance rule，而是完整 Manual Gate notification coverage。
- Notification Framework MVP 完成後，AI Workspace V1 的 Architecture、Implementation、Review、Validation、Git Gate、Notification 與 Manual Gate 協作流程將具備完整閉環。
- 繼續增加 AI Workspace 功能會偏離 MVP First，應改進入 Maintenance Mode，將後續重心轉向產品主線：AI Collaboration Engine 與 AI Decision Assistant。

### 6.7 Decision Principles

Applied Development Principles:

- MVP First
- Architecture Before Implementation
- Evidence Before Assumption
- Process Improvement Never Goes Backwards

Rationale:

- MVP First: Sprint-012 僅處理已由 E2E 驗證出的 notification coverage 缺口，不擴大為 workflow engine 或 AI automation。
- Architecture Before Implementation: Notification Framework 必須先由 Sprint-012 Architecture 定義 scope、non-goals、acceptance criteria，才可 implementation。
- Evidence Before Assumption: Sprint-012 backlog 來自 Sprint-011 真實流程驗證結果，而不是預先假設。
- Process Improvement Never Goes Backwards: Sprint-011 已建立 Definition of Done 與 Retrospective governance，Sprint-012 必須沿用並強化，不得降低 Manual Gate 或 Product Owner Decision 要求。
