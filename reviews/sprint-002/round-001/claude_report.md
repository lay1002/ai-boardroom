# claude_report.md

Sprint: sprint-002
Round: round-001
Sprint Type: implementation
Feature: Template Engine MVP

---

## 說明：本報告為歷史補件

Template Engine MVP 的程式碼與測試已於本 workspace 完成並存在於 working tree（`backend/app/engines/template/`、`templates/boardroom.yaml`、`tests/engines/template/`），但當時未依 `docs/development/consensus-workflow.md` 走完 Claude Report 這一步。本報告是依 Product Owner 指示，針對既有實作**如實回溯記錄**，不修改、不新增、不重構任何 Template Engine 程式碼，也不新增功能。

---

## 1. 實作範圍

依 `reviews/sprint-002/round-001/architecture.md`（Architecture Review，建議下一步為 Template Engine MVP）與 `reviews/sprint-002/round-001/template_engine_implementation_spec.md`（實作規格，收斂自 `template_engine_design.md`），本 Sprint 實作 Template Engine 的核心 library 能力：

```text
YAML Template Definition
↓
Loader
↓
Validator
↓
Renderer
↓
TemplateRuntimePlan
```

範圍限定在：Template Schema models、Template Loader、Template Validator、Template Renderer、TemplateRuntimePlan models、`templates/boardroom.yaml` sample、對應 unit tests。不含 API、不呼叫 LLM、不執行 Workflow、不整合 ACE Lite、不建立資料庫儲存。

---

## 2. 實作檔案

```text
backend/__init__.py                          — package marker（空檔）
backend/app/__init__.py                      — package marker（空檔）
backend/app/engines/__init__.py              — package marker（空檔）
backend/app/engines/template/__init__.py     — 公開介面匯出（Loader / Renderer / schemas / errors）
backend/app/engines/template/errors.py       — 錯誤類型（TemplateNotFoundError、InvalidYAMLError、
                                                TemplateRootNotMappingError、TemplateValidationError、
                                                TemplateIDMismatchError、TemplateDisabledError、
                                                RenderInputError）
backend/app/engines/template/schemas.py      — Pydantic models：TemplateDefinition 與
                                                TemplateRuntimePlan 及其巢狀 Ref models，
                                                含 kebab-case ID_PATTERN 驗證
backend/app/engines/template/loader.py       — TemplateLoader：依 template_id 尋找/讀取/快取
                                                templates/<template_id>.yaml
backend/app/engines/template/validator.py    — validate_template_definition：raw dict → TemplateDefinition
backend/app/engines/template/renderer.py     — TemplateRenderer：Template + user_input → TemplateRuntimePlan
templates/boardroom.yaml                     — 唯一 sample template（ceo/cto/cfo/risk/execution
                                                perspective 皆為 YAML 引用，無 Python 寫死）
tests/engines/template/conftest.py           — project_templates_dir fixture
tests/engines/template/test_loader.py        — 9 個測試
tests/engines/template/test_validator.py     — 11 個測試
tests/engines/template/test_renderer.py      — 9 個測試
pytest.ini                                   — pythonpath = .（讓 backend.app.* import 生效）
requirements.txt                             — pydantic>=2.6,<3、PyYAML>=6.0、pytest>=8.0
```

---

## 3. 未實作項目

以下項目依規格書第 5、14 節（`template_engine_implementation_spec.md`）明確排除於本 Sprint，**是刻意的範圍邊界，非遺漏**：

- **API**：無 FastAPI route / controller，`GET /templates`、`GET /templates/{id}`、`POST /templates/{id}/render` 僅存在於 `template_engine_design.md` 作為 future design，未落地。
- **CLI**：Template Engine 本身無任何命令列入口（僅供其他模組 import 使用）。
- **DB**：無資料庫 model、無 Alembic migration，Template 定義純粹來自檔案系統 YAML。
- **UI**：無 Admin UI、無 Frontend。
- **Workflow Engine**：Template 只保存 `workflow_id` reference，不執行任何 workflow steps。
- **Prompt Generator**：與本 Sprint 無關；Prompt Generator 是 Sprint-008 的獨立產出（`backend/app/engines/prompt_generator/`），已另行 commit（`5f5682c`），不在本次盤點與本報告範圍內。
- **Provider / LLM integration**：Template Engine 不呼叫任何 LLM、不建立 provider client、不解析 API key，只保存 `provider_policy_id` reference。
- **Memory**：不寫入、不讀取任何 Memory。
- **Consensus**：不執行 consensus 計算，只保存 `consensus.strategy_id` reference。

---

## 4. 測試結果

```bash
source .venv/bin/activate
PYTHONDONTWRITEBYTECODE=1 python -m pytest tests/engines/template/ -p no:cacheprovider -v
```

結果：**29 passed**（0 failed），執行時間 0.60s。

分佈：

- `test_loader.py`：9 passed（boardroom 載入、missing file、invalid YAML、root not mapping、id mismatch、`load_all()` 排序、cache、invalid id 提早拒絕、path traversal 提早拒絕）
- `test_validator.py`：11 passed（合法 template、root not mapping、缺欄位、未知欄位、id mismatch、非法 id 命名、非法 status、重複 perspective、空 perspectives、非法 order、`required_fields` 缺 question）
- `test_renderer.py`：9 passed（active template render 成功、perspectives 依 order 排序、disabled 拒絕、缺 question/空白 question/非字串 question/非字串 context 皆拒絕、optional policy 欄位省略、boardroom 端到端 render 且輸出不含 api_key/credential/base_url/prompt_text）

驗證方式：以 `PYTHONDONTWRITEBYTECODE=1` 與 `-p no:cacheprovider` 執行，執行後以 `find` 確認 `backend/`、`tests/` 底下未產生任何 `__pycache__/` 或 `*.pyc`，`git status` 執行前後無變化。

---

## 5. 是否符合 Architecture / Implementation Spec

**符合。** 逐項比對 `template_engine_implementation_spec.md` 第 15 節「驗收標準」與實際程式碼／測試：

| 驗收標準 | 對應實作 | 結果 |
|---|---|---|
| `templates/boardroom.yaml` 可成功載入 | `test_load_boardroom_from_project_templates_dir` | PASS |
| Loader 可載入單一 template / `load_all()` 排序 | `loader.py: load()/load_all()` | PASS |
| Validator 拒絕 invalid YAML / missing / unknown 欄位 / invalid ID | `validator.py` + `schemas.py: ID_PATTERN` | PASS |
| Validator 拒絕重複 perspectives / 空 perspectives / 非法 order | `schemas.py: _check_perspectives / _check_order` | PASS |
| Validator 拒絕 `template_id` 與檔名不一致 | `loader.py` → `validator.py: TemplateIDMismatchError` | PASS |
| Validator 拒絕非 active/disabled 的 status | `schemas.py: TemplateStatus = Literal["active","disabled"]` | PASS |
| Renderer 將 active template 轉成 `TemplateRuntimePlan` | `renderer.py: render()` | PASS |
| Renderer 拒絕 disabled template | `renderer.py` → `TemplateDisabledError` | PASS |
| Renderer 驗證 question 存在/字串/非空白，context 選填且需為字串 | `renderer.py: _validate_user_input` | PASS |
| Runtime Plan 含必填欄位（template/input/workflow/perspectives/output_schema） | `schemas.py: TemplateRuntimePlan` | PASS |
| Runtime Plan 不含 provider credentials / prompt 全文 | `test_render_boardroom_from_project_templates_dir` 明確斷言 forbidden terms | PASS |
| Python 不寫死 Boardroom / CEO / CTO / CFO / Risk / Execution | `schemas.py: PerspectiveRef` 完全泛型，角色值僅存在於 `templates/boardroom.yaml` | PASS |
| 測試通過 | 29 passed | PASS |

ID 命名規則（規格第 6 節）採 kebab-case（`^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$`），與 `schemas.py: ID_PATTERN` 及 `templates/boardroom.yaml` 完全一致。

---

## 6. 是否有 Architecture Conflict

**無 blocking conflict。** 有一項**已由規格書自行解決、非隱藏問題**的落差，於此揭露：

- `template_engine_design.md` 第 3 節的範例使用 snake_case ID（例如 `decision_request_v1`、`multi_perspective_decision_v1`、`boardroom_default_prompts_v1`）。
- `template_engine_implementation_spec.md` 第 6 節明確將 ID 命名規則統一收斂為 **kebab-case**，並在第 7 節的 Schema 範例中改用 `decision-request-v1`、`multi-perspective-decision-v1` 等連字號格式。
- 實際程式碼（`schemas.py: ID_PATTERN`）與 `templates/boardroom.yaml` 完全遵循 implementation_spec.md 的 kebab-case 決定，而非 design.md 的早期草案格式。

這是 Design → Spec 收斂過程中預期會發生、且已被 spec 文件明文記錄的設計決策更新，不是實作偏離規格，故不列為 Architecture Conflict。

---

## 7. 是否有 Must Fix

**無 Must Fix。** 未發現會導致功能錯誤、範圍外實作、或違反 Architecture 邊界的問題。

---

## Scope Expansion

Scope Expansion: No

本報告是對既有 Template Engine MVP 實作的回溯記錄，過程中未新增功能、未修改 Template Engine 程式碼、未擴大 `template_engine_implementation_spec.md` 定義的範圍（見第 1、3 節）。

---

## 8. 結論

**READY FOR CODEX REVIEW**

Template Engine MVP 的實作內容、測試覆蓋、與 `architecture.md` / `template_engine_implementation_spec.md` 的驗收標準逐項比對後一致，未發現 Must Fix 或未解決的 Architecture Conflict。本報告為歷史補件，下一步應由 Codex 針對本報告與既有程式碼進行正式 Review，產出 `codex_review.md`（目前 `reviews/sprint-002/round-001/codex_review.md` 內容是先前的 Architecture Review Review，尚非本 Fill Artifacts Step 所需的 Code Review，需另行處理或由 Product Owner 決定如何銜接），以推進至 `claude_reply.md` → `codex_final_review.md` → `consensus_report.md` → `final_consensus.md` → Product Owner Gate。

尚未 commit，等待後續 Consensus Workflow 步驟。
