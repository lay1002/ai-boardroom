# Review Checklist

> AI Decision Assistant V3 — Codex Review Standard

Version: 1.0

---

# Purpose

本文件定義 Codex 在 AI Decision Assistant V3 專案中的標準 Review 流程。

目標：

* 保持產品架構一致性
* 降低大型重構風險
* 避免 Scope Creep
* 確保 Platform First 原則

---

# Review Scope

每次 Review 必須確認：

* Architecture
* Config
* Workflow
* API
* Testing
* Git Scope

---

# 1. Product Review

確認：

* 是否符合產品 Vision
* 是否符合 AI Decision Assistant V3 定位
* 是否把 Boardroom 當成 Template，而不是核心
* 是否沒有偏離 Sprint Scope

Checklist：

* [ ] 符合產品定位
* [ ] 沒有新增未要求功能
* [ ] 沒有 Scope Creep

---

# 2. Architecture Review

確認：

* 是否符合 Platform First
* 是否符合 Configuration over Code
* 是否符合 Perspective over Agent

Checklist：

* [ ] 沒有寫死 Perspective
* [ ] 沒有寫死 Workflow
* [ ] 沒有寫死 Provider
* [ ] 沒有寫死 Prompt
* [ ] 沒有寫死 Template

---

# 3. Config Review

確認：

* Config 是否合理
* 是否可以由 YAML / JSON 驅動
* 是否避免 Hardcode

Checklist：

* [ ] Config 可讀
* [ ] Config 可維護
* [ ] Config 可擴充

---

# 4. Code Review

確認：

* 是否只修改必要範圍
* 是否沒有大型重構
* 是否保持現有 API Contract

Checklist：

* [ ] API Contract 不變
* [ ] Repository 未破壞
* [ ] Database 未破壞
* [ ] 無不必要重構

---

# 5. Testing Review

確認：

* pytest 是否通過
* E2E 是否通過（若有）
* 是否新增必要測試

Checklist：

* [ ] pytest PASS
* [ ] E2E PASS（若有）
* [ ] 新增測試符合需求

---

# 6. Git Review

確認：

* Commit Scope 是否乾淨
* 是否混入無關修改

Checklist：

* [ ] Commit Scope 正確
* [ ] 無 docs 混入
* [ ] 無 review 文件混入
* [ ] 無實驗檔案混入

---

# 7. Known Limitation

每次 Review 必須列出：

* Known Limitation
* Future Improvement
* Technical Debt

不得省略。

---

# 8. Risk Assessment

請評估：

* Risk Level：Low / Medium / High
* 是否可以 Commit
* 是否需要修改

---

# 9. Review Output Format

每次 Review 使用固定格式：

```text
## Summary

## Product Review

## Architecture Review

## Code Review

## Testing Review

## Git Review

## Known Limitation

## Suggestions

## Risk Level

## Commit Recommendation
```

---

# 10. Final Decision

Codex 只能提出建議。

不得：

* 自行改需求
* 自行新增功能
* 自行改產品方向

最終決策權：

Product Owner
