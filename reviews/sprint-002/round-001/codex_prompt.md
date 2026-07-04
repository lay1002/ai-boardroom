# codex_prompt.md

Sprint: sprint-002
Round: round-001
Sprint Type: implementation
Feature: Template Engine MVP

---

## 說明：本檔案為歷史 Sprint-002 artifact 補件

本檔案是 Review Bridge 角色下「Preparing Codex review prompts」這一步的回溯記錄，重建當時實際交給 Codex session 執行、並產出 `reviews/sprint-002/round-001/codex_review.md` 的 Review Prompt 內容。

本檔案**不改變任何既有 Review 結論**。`codex_review.md`、`codex_final_review.md` 的內容維持原樣，本檔案只是補齊 Consensus Workflow 要求的輸入 artifact 清單，讓 `reviews/sprint-002/round-001/` 具備完整的 Implementation Sprint 六項輸入檔案。依 `docs/development/consensus-workflow.md`，`codex_prompt.md` 是「a review prompt artifact」，不是 review 結果，不代表也不取代實際的 Claude 或 Codex review 內容。

---

## 交付給 Codex 的原始 Prompt

請閱讀：

- PROJECT_BOOTSTRAP.md
- AGENTS.md
- docs/development/consensus-workflow.md
- docs/development/development-workflow.md
- reviews/sprint-002/round-001/architecture.md
- reviews/sprint-002/round-001/template_engine_implementation_spec.md
- reviews/sprint-002/round-001/claude_report.md

工作：

為 Sprint-002 Template Engine MVP 產生正式 Codex Code Review。

請 review 以下範圍：

- backend/__init__.py
- backend/app/__init__.py
- backend/app/engines/__init__.py
- backend/app/engines/template/
- templates/boardroom.yaml
- tests/engines/template/
- pytest.ini
- requirements.txt

請覆寫：

reviews/sprint-002/round-001/codex_review.md

要求：

1. 判斷是否符合 Architecture / Implementation Spec。
2. 判斷是否有 scope creep。
3. 判斷是否有 Architecture Conflict。
4. 判斷是否有 Must Fix。
5. 驗證測試：
   - .venv/bin/pytest tests/engines/template -q
6. 輸出：
   - Gate Status
   - Must Fix
   - Architecture Conflict
   - Final Recommendation

限制：

- 不修改 source code。
- 不 stage。
- 不 commit。
- 不 push。
- 只允許更新 reviews/sprint-002/round-001/codex_review.md。

---

## 產出結果

Codex 依上述 Prompt 執行後，產出 `reviews/sprint-002/round-001/codex_review.md`，結論為：

```text
Gate Status: PASS
Must Fix: None
Architecture Conflict: None
Final Recommendation: PASS
```

Claude Code 依此結果產出 `claude_reply.md`，Codex 再依 `claude_reply.md` 產出 `codex_final_review.md`（結論同樣為 PASS）。
