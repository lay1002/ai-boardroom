# Sprint Checklist

> AI Decision Assistant V3 — Sprint Gate Checklist

Version: 1.0

---

# Purpose

本文件定義每一個 Sprint 的標準 Gate。

所有 Sprint 必須完成所有 Gate，才能進入下一個 Sprint。

---

# Sprint Flow

```text
Vision
↓

Architecture
↓

Specification
↓

ACE Discussion
↓

Final Prompt
↓

Claude Code

↓

Codex Review

↓

Claude Fix

↓

pytest

↓

E2E

↓

Product Gate

↓

Git Commit
```

---

# Gate 1 — Vision

確認：

* [ ] 問題已定義
* [ ] Business Goal 清楚
* [ ] Sprint Scope 明確

未完成不得開始 Coding。

---

# Gate 2 — Architecture

確認：

* [ ] Architecture 完成
* [ ] Engine Design 完成
* [ ] Config Design 完成
* [ ] API Contract 完成

未完成不得 Coding。

---

# Gate 3 — Specification

確認：

* [ ] Folder Structure
* [ ] Config Schema
* [ ] Workflow
* [ ] Prompt Design
* [ ] Output Schema

全部完成才能交 Claude。

---

# Gate 4 — ACE Discussion

確認：

* [ ] Requirement 收斂
* [ ] Discussion 完成
* [ ] Final Prompt 產生

不得直接跳到 Coding。

---

# Gate 5 — Claude Code

確認：

* [ ] Scope 正確
* [ ] 無 Scope Creep
* [ ] 無大型重構
* [ ] 修改範圍合理

---

# Gate 6 — Codex Review

確認：

* [ ] Architecture PASS
* [ ] API PASS
* [ ] Config PASS
* [ ] Git Scope PASS
* [ ] Risk 評估完成

若 FAIL：

返回 Claude 修正。

---

# Gate 7 — Testing

確認：

* [ ] pytest PASS
* [ ] E2E PASS（若有）
* [ ] Known Limitation 已列出

不得跳過。

---

# Gate 8 — Product Gate

Product Owner 確認：

* [ ] Feature 完成
* [ ] Scope 正確
* [ ] 可以 Commit

若不同意：

返回 Claude。

---

# Gate 9 — Commit

確認：

* [ ] Git Status 正常
* [ ] Commit Scope 正確
* [ ] Commit Message 合理

Commit 完成後：

進入下一個 Sprint。

---

# Sprint Completion Checklist

每個 Sprint 必須全部完成：

* [ ] Vision
* [ ] Architecture
* [ ] Specification
* [ ] ACE Discussion
* [ ] Final Prompt
* [ ] Claude Code
* [ ] Codex Review
* [ ] Claude Fix
* [ ] pytest PASS
* [ ] E2E PASS（若有）
* [ ] Product Owner Approval
* [ ] Git Commit

---

# Definition of Done

只有當下列全部成立，Sprint 才算完成：

* Scope 完成
* 測試完成
* Review 完成
* Commit 完成
* Product Owner 同意
* 可以開始下一個 Sprint

---

# Current Development Policy

目前 AI Decision Assistant V3 採用：

**Manual Gate**

Consensus Loop、Auto Commit、Auto Claude/Codex Workflow 屬於未來 ACE V2 的規劃，不納入目前 Sprint。
