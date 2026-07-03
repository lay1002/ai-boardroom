# Sprint-008 Architecture

# AI 協作 Prompt 自動產生器 MVP

## 1. Sprint 名稱

AI 協作 Prompt 自動產生器 MVP

---

## 2. Sprint 目標

建立第一個可以立即使用的 **AI 協作 Prompt 自動產生器（Prompt Generator）**。

此功能用來減少 Product Owner 在 ChatGPT、Claude Code、Codex 之間手動撰寫與搬運 Prompt 的時間。

本 Sprint 只做一件事：

> 根據 Product Owner 的需求描述，自動產生一組可直接貼給不同 AI 使用的協作 Prompt。

---

## 3. MVP 使用情境

Product Owner 輸入一段需求，例如：

```text
我要新增登入功能
```

系統輸出：

1. ChatGPT Architecture Prompt
2. Claude Code Implementation Prompt
3. Codex Review Prompt
4. Next Step

---

## 4. In Scope

本 Sprint 只包含：

* 接收一段需求文字
* 產生 ChatGPT Architecture Prompt
* 產生 Claude Code Implementation Prompt
* 產生 Codex Review Prompt
* 產生 Next Step
* 輸出 Markdown 格式結果

---

## 5. Out of Scope

本 Sprint 不包含：

* 不自動呼叫 ChatGPT
* 不自動呼叫 Claude Code
* 不自動呼叫 Codex
* 不新增 AI Runtime
* 不新增 Memory
* 不新增 Learning
* 不新增多 Domain
* 不新增 Template Framework
* 不新增 Discussion Framework
* 不修改 Review Bridge
* 不修改 Consensus Algorithm
* 不修改既有 Sprint Workflow
* 不處理 Decision Report MVP

---

## 6. 輸入格式

最小輸入只需要一段文字：

```text
<需求描述>
```

例如：

```text
我要新增一個可以產生 Claude / Codex Prompt 的工具
```

---

## 7. 輸出格式

輸出必須是 Markdown，並包含以下四個固定區塊：

```markdown
# AI 協作 Prompt

## 1. ChatGPT Architecture Prompt

<給 ChatGPT 的 Prompt>

## 2. Claude Code Implementation Prompt

<給 Claude Code 的 Prompt>

## 3. Codex Review Prompt

<給 Codex 的 Prompt>

## 4. Next Step

<下一步建議>
```

---

## 8. Prompt 內容要求

### ChatGPT Architecture Prompt

必須要求 ChatGPT：

* 先確認需求範圍
* 產生最小 Architecture
* 明確列出 In Scope / Out of Scope
* 遵守 MVP First
* 不擴大架構
* 一次只做一件最重要的事情

### Claude Code Implementation Prompt

必須要求 Claude Code：

* 閱讀必要文件
* 依照已批准 Architecture 實作
* 不擴大範圍
* 不修改 Review Bridge
* 不 commit
* 完成後更新 `claude_report.md`
* 回報測試方式與結果

### Codex Review Prompt

必須要求 Codex：

* 只做 Review
* 檢查是否符合 Architecture
* 檢查是否有擴大範圍
* 檢查是否有修改禁止項目
* 檢查測試是否足夠
* 輸出 `codex_review.md`
* 不修改程式碼
* 不 commit

### Next Step

必須清楚告訴 Product Owner：

* 下一步應該交給哪一個 AI
* 應該做 Architecture、Implementation 或 Review
* 不應該同時做多個步驟

---

## 9. 實作限制

* 可以新增最小必要檔案。
* 可以新增簡單 CLI 或 Script。
* 不得修改 `scripts/review_bridge.sh`。
* 不得修改 Review Bridge 行為。
* 不得新增複雜 Framework。
* 不得新增資料庫。
* 不得新增 UI。
* 不得新增 AI API 呼叫。
* 不得自動執行任何 AI。
* 不得 commit。

---

## 10. Definition of Done

完成後必須能做到：

給定一段需求文字，系統可以輸出完整 Markdown，包含：

* ChatGPT Architecture Prompt
* Claude Code Implementation Prompt
* Codex Review Prompt
* Next Step

並且：

* 輸出可直接複製使用
* 不需要 Product Owner 再手動組 Prompt
* 不修改 Review Bridge
* 不新增自動 AI Runtime
* 有基本測試或可驗證的執行方式
* `claude_report.md` 已更新

---

## 11. Gate Status

Architecture Gate: PASS
