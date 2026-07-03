# Development Workflow

> AI Decision Assistant V3 Development Standard

Version: 1.0

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

一個 Sprint 完成需符合：

* Product Owner Scope 確認
* Claude Code 完成
* Codex Review 通過
* pytest 通過
* E2E 通過（若有）
* Commit Scope 正確
* Known Limitation 已紀錄
* Product Owner 同意進入下一個 Sprint
