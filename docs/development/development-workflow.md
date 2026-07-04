# Development Workflow

> AI Decision Assistant V3 Development Standard

Version: 1.0

---

# 0. Development Principles Authority

This document operates under `docs/development/development-principles.md`, the AI Workspace Development Constitution.

Development Principles v2.0 and the canonical Definition of Done are defined there as the single source of truth. This document does not redefine them; it only describes the operational workflow steps and gates that implement them.

---

# 1. Purpose

本文件定義 AI Decision Assistant V3 的標準開發流程。

目的：

* 建立一致的 AI 協作流程
* 降低大型專案開發風險
* 保持 Platform First 設計
* 確保每個 Sprint 都能被驗證
* 避免 AI 任意修改專案架構

---

# 1.1 Development Priority

AI Workspace 的開發流程遵守：

```text
MVP First
Architecture Second
Platform Last
```

流程目的不是增加儀式，而是協助目前 Sprint 交付可驗證成果。

原則：

* 一次只做一件最重要的事情。
* 優先完成目前 Sprint。
* Architecture 必須支援 MVP，不得阻礙 MVP。
* 只有在兩個以上功能需要共用、已有重複實作、能降低維護成本，且不延後 MVP 時，才新增 Framework、Platform 或抽象層。
* 若 Product Owner 表示「先完成產品，再優化架構」，所有 AI Agent 必須優先協助完成產品。

---

# 2. AI Collaboration Architecture

```text
                Product Owner
                      │
                      ▼
          Chief Product Architect (ChatGPT)
                      │
          Vision / Architecture / Specification
                      │
                      ▼
                 ACE Lite
      (Requirement Discussion & Final Prompt)
                      │
                      ▼
               Claude Code
          (Implementation)
                      │
                      ▼
                 Codex Review
          (Architecture / Code Review)
                      │
          ┌───────────┴───────────┐
          │                       │
        PASS                   NEED FIX
          │                       │
          ▼                       │
      Product Gate                │
          │                       │
          ▼                       │
      Git Commit          Claude Code Fix
                                  │
                                  └──────────────► Review Again
```

---

# 3. Responsibility

## Product Owner

負責：

* Product Vision
* Business Decision
* Sprint Priority
* Final Approval

---

## Chief Product Architect

負責：

* Vision
* Architecture
* Config Design
* Workflow
* Engine Design
* API Contract
* Technical Specification

不直接修改程式。

---

## ACE Lite

負責：

* Requirement Discussion
* Multi-round Discussion
* Requirement Refinement
* Final Prompt
* Discussion Summary

ACE 不屬於 Runtime。

ACE 是 Development Tool。

---

## Claude Code

負責：

* 程式實作
* 小範圍重構
* Test
* Bug Fix

不得自行改變產品架構。

---

## Codex

負責：

* Code Review
* Architecture Review
* Risk Analysis
* Commit Scope Review

不得新增需求。

---

# 4. Standard Development Flow

每個 Feature 必須遵循：

```text
Requirement

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

不得跳過任何 Gate。

---

# 5. Manual Gate

目前採用：

Manual Gate

禁止：

* Auto Claude Loop
* Auto Codex Loop
* Auto Commit

每個重要階段都由 Product Owner 確認。

---

## Gate 1

Architecture Approval

確認：

* Product Direction
* Architecture
* Scope

---

## Gate 2

Implementation Review

確認：

* Claude 完成
* Codex Review PASS
* Known Limitation

---

## Gate 3

Quality Verification

確認：

* pytest PASS
* E2E PASS
* API Contract 未破壞

---

## Gate 4

Commit Approval

確認：

* Commit Scope
* Git Status
* Staged Files

---

# 6. Approval Allowlist

建議將以下指令加入：

**Yes, and don't ask again**

避免 AI 在正常開發過程中反覆等待人工確認。

## Python

```text
python
python3
pytest
.venv/bin/pytest
pip
uv
```

---

## Git

```text
git status
git diff
git add
git log
git show
git branch
git checkout
```

---

## Linux

```text
ls
cat
pwd
find
grep
tree
mkdir
cp
mv
```

---

## Project Scripts

```text
./run_e2e.sh

scripts/ace_discuss.sh

scripts/run_tests.sh

scripts/lint.sh

make test

make lint
```

---

## Docker

```text
docker ps

docker compose ps

docker logs
```

---

# 7. Commands Requiring Manual Approval

以下操作必須再次確認：

```text
git push

git reset --hard

git clean -fd

rm -rf

Database Migration

Production Deployment

Drop Table

Delete Data
```

---

# 8. Commit Policy

一個 Feature

=

一個 Commit

不得：

* 混入文件
* 混入重構
* 混入測試修正
* 混入其他 Feature

Commit 必須保持 Atomic。

---

# 9. Review Policy

Codex 必須 Review：

* Scope
* Architecture
* API
* Test
* Risk
* Commit

Claude 必須修正所有合理 Review。

若有不同意見：

由 Product Owner 決定。

---

# 10. Testing Policy

每次 Feature 必須至少執行：

```bash
.venv/bin/pytest
```

若有 E2E：

```bash
./run_e2e.sh
```

不得宣稱完成而未驗證。

---

# 11. Known Limitation Policy

每次完成後必須列出：

* Known Limitation
* Future Improvement
* Technical Debt

避免把暫時方案誤認為最終設計。

---

# 12. Roadmap Principle

目前：

```text
Manual Gate
```

未來：

```text
ACE V2

↓

Consensus Loop

↓

Claude

↓

Codex

↓

Claude

↓

Codex

↓

Consensus PASS

↓

Product Approval
```

在 Consensus Loop 完成前，所有 Feature 均採 Manual Gate。

---

# 13. Core Principles

所有開發皆遵循：

* Platform First
* Configuration over Code
* Perspective over Agent
* Decision over Chat

所有能力應保持：

* Config Driven
* Template Driven
* Workflow Driven

不得寫死：

* Perspective
* Provider
* Workflow
* Prompt
* Template
* Model

---

# 14. Definition of Done

Definition of Done 由 `docs/development/development-principles.md`（AI Workspace Development Constitution）第 5 節定義為 AI Workspace 唯一標準，本文件不重複列出完整項目。

本文件第 4 節 Standard Development Flow 與第 5 節 Manual Gate（Gate 1–4）描述的流程，對應滿足該 Definition of Done 的下列項目：Architecture Approved（Gate 1）、Implementation Review PASS（Gate 2）、End-to-End Validation PASS（Gate 3：pytest / E2E）、Git Review PASS（Gate 4）。

Sprint Retrospective Completed、Product Owner Decision Recorded 為 Development Principles v2.0 新增的必要項目（見 `development-principles.md` 第 2 節 Principle 6），本文件描述的 Gate 流程完成後，仍必須額外完成 Sprint Retrospective 與 Product Owner Decision 紀錄，才符合完整 Definition of Done。

完整定義請見 `docs/development/development-principles.md` 第 5、6 節。
