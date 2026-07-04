# Template Engine MVP Implementation Spec

## 結論

本文件將 `template_engine_design.md` 與 `template_engine_design_review.md` 收斂成 Template Engine MVP 的實作前規格。

本 Sprint 只實作 Template Engine 的核心 library 能力：

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

本 Sprint 不實作 API、不呼叫 LLM、不執行 Workflow、不整合 ACE Lite、不建立資料庫儲存。

## 1. 本 Sprint Scope Decision

### 本 Sprint 要實作

- Template Schema models。
- Template Loader。
- Template Validator。
- Template Renderer。
- TemplateRuntimePlan models。
- `templates/boardroom.yaml` sample。
- Unit tests。

### 本 Sprint 不實作

- REST API。
- Workflow Engine。
- Perspective Engine execution。
- Prompt Registry。
- Provider client。
- Model Router。
- Decision Engine。
- Moderator Engine。
- Consensus Engine。
- Memory Engine。
- Knowledge Engine。
- Database persistence。
- Admin UI。
- Frontend。
- ACE Lite Orchestrator integration。
- Review Bridge integration。

### Scope Rationale

`template_engine_design_review.md` 已指出 API 是否納入本 Sprint 需要 Product Owner 決定。為避免 MVP 範圍過大，本規格明確決定：

```text
本 Sprint 不納入 API。
```

原因：

- Template Engine 的第一個可驗收價值是 config load / validate / render。
- API 可以在核心 schema 穩定後再加。
- 先完成 library 能力可降低後續 Workflow / API dependency 風險。

## 2. Runtime Plan 必填欄位

Renderer 必須輸出 `TemplateRuntimePlan`。

`TemplateRuntimePlan` 是後續 Workflow / Decision layer 的輸入計畫，不是 execution result。

### Required Top-Level Fields

```yaml
template:
  template_id: boardroom
  name: Boardroom Decision Template
  version: 1.0.0
  status: active

input:
  question: 是否要進入日本市場？
  context: 公司目前已有台灣與香港市場。

workflow:
  workflow_id: multi_perspective_decision_v1
  mode: parallel_perspectives

perspectives:
  - perspective_id: ceo
    required: true
    order: 10

output_schema:
  schema_id: structured_decision_v1
```

### Optional Top-Level Fields

```yaml
prompt_policy:
  prompt_set_id: boardroom_default_prompts_v1

provider_policy:
  provider_policy_id: default_multi_model_policy_v1

moderator:
  strategy_id: synthesize_conflicts_v1

consensus:
  strategy_id: majority_with_risk_override_v1

metadata:
  category: strategy
  tags:
    - boardroom
    - decision
```

### Runtime Plan Field Rules

`template`

- Required。
- Must contain `template_id`、`name`、`version`、`status`。
- Values come from Template Definition。

`input`

- Required。
- Must contain `question`。
- May contain `context`。
- Values come from render input。

`workflow`

- Required。
- Must contain `workflow_id`。
- May contain `mode`。
- Values come from Template Definition。

`perspectives`

- Required。
- Must contain at least one item。
- Must be sorted by `order` ascending when `order` is present。
- Each item must contain `perspective_id` and `required`。
- Each item may contain `order`。

`output_schema`

- Required。
- Must contain `schema_id`。

Optional policy fields

- If present in Template Definition, renderer must copy them into Runtime Plan.
- If absent, renderer must omit them or return `null` consistently. MVP 建議：omit absent optional fields。

### Runtime Plan Must Not Contain

Runtime Plan 禁止包含：

- API key。
- Provider credentials。
- Provider base URL。
- Prompt full text。
- Python function path。
- LLM response。
- Workflow execution result。
- Decision result。
- Memory content。

## 3. status 允許值

Template Definition 必須包含 `status`。

### Allowed Values

MVP 只允許：

```text
active
disabled
```

### status Semantics

`active`

- Template 可以被 `load()`。
- Template 可以被 `render()`。
- Template 會出現在 `load_all()` 結果。

`disabled`

- Template 可以被 `load()`，讓管理與診斷可讀取。
- Template 不可以被 `render()`。
- Template 是否出現在 `load_all()`：MVP 保留在結果中，但呼叫端可依 status 過濾。

### Validation Rules

- `status` 必填。
- `status` 不可空白。
- `status` 必須是 `active` 或 `disabled`。
- 其他值一律 validation error。

### Render Rule

- 若 Template status 是 `disabled`，renderer 必須拒絕 render。
- 錯誤訊息需包含 `template_id` 與 `disabled`。

## 4. input_schema MVP 驗證範圍

MVP 不實作完整 JSON Schema validation。

MVP 只支援最小輸入規格：

```yaml
input_schema:
  type: decision_request_v1
  required_fields:
    - question
```

### Template Definition Validation

`input_schema` 必須符合：

- `input_schema.type` 必填且不可空白。
- `input_schema.required_fields` 必填。
- `required_fields` 必須是 list。
- `required_fields` 必須包含 `question`。
- MVP 不允許 `required_fields` 為空。

### Render Input Validation

Renderer 對 `user_input` 只驗證：

- `question` 必須存在。
- `question` 必須是 string。
- `question.strip()` 不可空白。
- `context` 可選。
- 若 `context` 存在，必須是 string。

### MVP 不驗證

- 不驗證完整 JSON Schema。
- 不驗證 nested fields。
- 不驗證 field type beyond `question` / `context`。
- 不驗證 business semantics。
- 不驗證 question 是否可回答。

### Error Message Requirements

錯誤訊息必須明確指出：

- 缺少哪個欄位。
- 哪個欄位型別不正確。
- 哪個欄位不可空白。

## 5. API 是否納入本 Sprint

本 Sprint 不實作 API。

### API Contract Status

`template_engine_design.md` 中的 API Contract 保留為 future design：

- `GET /templates`
- `GET /templates/{template_id}`
- `POST /templates/{template_id}/render`

### 本 Sprint Implementation Boundary

本 Sprint 只實作可被 API layer 呼叫的核心能力：

- `load(template_id)`
- `load_all()`
- `render(template_id, user_input)`

但不建立 FastAPI route。

### API Deferred Rationale

API 延後原因：

- 避免第一個 Template Engine Sprint 同時處理 module design、schema、file I/O、validation、render、HTTP contract。
- 保持 Sprint 可測試且範圍乾淨。
- 等核心 models 穩定後再暴露 API，降低 API contract churn。

## 6. ID 命名規則

MVP 統一採用 lowercase kebab-case。

### Allowed Pattern

所有 config ID 使用：

```text
^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$
```

適用欄位：

- `template_id`
- `perspective_id`
- `workflow_id`
- `prompt_set_id`
- `provider_policy_id`
- `strategy_id`
- `schema_id`

### Examples

Valid：

```text
boardroom
personal-decision
multi-perspective-decision-v1
structured-decision-v1
default-provider-policy-v1
```

Invalid：

```text
Boardroom
board_room
boardroom_v1
boardroom.v1
boardroom/v1
-boardroom
boardroom-
```

### File Naming Rule

Template file path：

```text
templates/<template_id>.yaml
```

Rules：

- File stem must equal `template_id`。
- Example：`templates/boardroom.yaml` must contain `template_id: boardroom`。
- Mismatch must raise validation error。

### Rationale

使用 kebab-case 的原因：

- 適合 URL path。
- 適合 YAML config。
- 避免 Python identifier、file path、URL encoding 混淆。
- 避免 underscore / hyphen 混用。

## 7. Template Definition Schema

MVP Template YAML 必須符合以下結構。

```yaml
template_id: boardroom
name: Boardroom Decision Template
version: 1.0.0
status: active
description: Multi-perspective structured decision analysis.

input_schema:
  type: decision-request-v1
  required_fields:
    - question

workflow:
  workflow_id: multi-perspective-decision-v1
  mode: parallel-perspectives

perspectives:
  - perspective_id: ceo
    required: true
    order: 10
  - perspective_id: cto
    required: true
    order: 20
  - perspective_id: cfo
    required: true
    order: 30
  - perspective_id: risk
    required: true
    order: 40
  - perspective_id: execution
    required: true
    order: 50

prompt_policy:
  prompt_set_id: boardroom-default-prompts-v1

provider_policy:
  provider_policy_id: default-multi-model-policy-v1

moderator:
  strategy_id: synthesize-conflicts-v1

consensus:
  strategy_id: majority-with-risk-override-v1

output_schema:
  schema_id: structured-decision-v1

metadata:
  category: strategy
  tags:
    - boardroom
    - decision
```

### Required Top-Level Fields

- `template_id`
- `name`
- `version`
- `status`
- `description`
- `input_schema`
- `workflow`
- `perspectives`
- `output_schema`

### Optional Top-Level Fields

- `prompt_policy`
- `provider_policy`
- `moderator`
- `consensus`
- `metadata`

### Unknown Fields

Unknown top-level fields are not allowed.

Reason：

- 避免 config drift。
- 避免拼字錯誤被 silently ignored。
- 保持 MVP 行為可預測。

## 8. Loader Spec

### Required Methods

`load(template_id)`

- Loads one Template Definition。
- Validates YAML and schema。
- Validates file stem equals `template_id`。
- Returns Template Definition。

`load_all()`

- Loads all `*.yaml` files from template directory。
- Sorts by `template_id` ascending。
- Returns all valid Template Definitions。
- If any file is invalid, MVP should fail fast with a clear error。

### Base Directory

MVP default：

```text
templates/
```

Implementation may allow dependency injection of `base_dir` for tests.

### Loader Must Not

- Must not read Perspective config。
- Must not read Workflow config。
- Must not read Prompt files。
- Must not read Provider credentials。
- Must not call LLM。
- Must not write DB。

## 9. Validator Spec

Validator must check：

- YAML root is mapping。
- Required top-level fields exist。
- Unknown top-level fields are rejected。
- `template_id` follows ID naming rule。
- file stem equals `template_id`。
- `name` non-empty。
- `version` non-empty string。
- `status` in `active | disabled`。
- `description` non-empty string。
- `input_schema.type` follows ID naming rule。
- `input_schema.required_fields` is non-empty list and includes `question`。
- `workflow.workflow_id` follows ID naming rule。
- `workflow.mode` if present follows ID naming rule。
- `perspectives` is non-empty list。
- each `perspectives[].perspective_id` follows ID naming rule。
- `perspectives[].perspective_id` has no duplicates。
- `perspectives[].required` is boolean。
- `perspectives[].order` if present is positive integer。
- `output_schema.schema_id` follows ID naming rule。
- optional policy / strategy IDs follow ID naming rule when present。

## 10. Renderer Spec

Renderer input：

```text
template_id
user_input
```

Renderer output：

```text
TemplateRuntimePlan
```

Renderer steps：

1. Load Template Definition by `template_id`。
2. Reject render if status is `disabled`。
3. Validate render input according to MVP input rules。
4. Sort perspectives by `order` ascending.
5. Build TemplateRuntimePlan.
6. Copy optional reference fields if present.
7. Return TemplateRuntimePlan.

Renderer must not：

- Resolve Perspective Definition。
- Resolve Workflow Definition。
- Resolve Prompt text。
- Resolve Provider credentials。
- Execute LLM。
- Execute Workflow。
- Generate Decision。

## 11. Boardroom Sample Template

本 Sprint 必須提供一個 sample：

```text
templates/boardroom.yaml
```

Required content：

- `template_id: boardroom`
- `status: active`
- Workflow reference。
- Perspectives：
  - `ceo`
  - `cto`
  - `cfo`
  - `risk`
  - `execution`
- Output schema reference。
- Provider policy reference。
- Prompt policy reference。
- Moderator strategy reference。
- Consensus strategy reference。

Boardroom-specific logic must remain only in YAML references。

不可在 Python 中寫死：

- Boardroom。
- CEO / CTO / CFO / Risk / Execution。
- Agnes。
- Any workflow behavior。

## 12. Testing Spec

本 Sprint 測試至少涵蓋：

### Loader Tests

- `load("boardroom")` succeeds。
- Missing template file raises clear error。
- Invalid YAML raises clear error。
- YAML root is not mapping raises clear error。
- `load_all()` returns templates sorted by `template_id`。

### Validator Tests

- Missing required field fails。
- Unknown top-level field fails。
- `template_id` and file stem mismatch fails。
- Invalid ID naming fails。
- Invalid status fails。
- Duplicate perspective fails。
- Empty perspectives fails。
- Invalid `order` fails。
- Missing `question` in `required_fields` fails。

### Renderer Tests

- Active template renders TemplateRuntimePlan。
- Disabled template cannot render。
- Missing `question` fails。
- Blank `question` fails。
- Non-string `question` fails。
- Non-string `context` fails。
- Perspectives are sorted by `order`。
- Runtime Plan contains required fields。
- Runtime Plan omits provider credentials。
- Runtime Plan does not contain prompt full text。

## 13. 本 Sprint 要實作什麼

本 Sprint 實作：

- Template Definition schema。
- Template Runtime Plan schema。
- Template Loader。
- Template Validator。
- Template Renderer。
- Boardroom YAML sample。
- Unit tests for loader / validator / renderer。

## 14. 本 Sprint 不實作什麼

本 Sprint 不實作：

- REST API routes。
- FastAPI controller。
- Database model。
- Alembic migration。
- Workflow Engine。
- Perspective Engine execution。
- Prompt Engine。
- Prompt Registry。
- Provider Layer。
- Model Router。
- Decision Engine。
- Moderator Engine。
- Consensus Engine。
- Memory Engine。
- Knowledge Engine。
- ACE Lite integration。
- Frontend / Admin UI。

## 15. 驗收標準

本 Sprint 完成必須符合：

- `templates/boardroom.yaml` 可被成功載入。
- Template Loader 可載入單一 template。
- Template Loader 可列出所有 templates。
- Template Validator 會拒絕 invalid YAML / missing fields / unknown fields / invalid IDs。
- Template Validator 會拒絕 duplicate perspectives。
- Template Validator 會拒絕 `template_id` 與檔名不一致。
- Template Validator 會拒絕非 `active` / `disabled` status。
- Renderer 可把 active template 轉成 TemplateRuntimePlan。
- Renderer 會拒絕 disabled template。
- Renderer 會驗證 `question` 存在、為 string、且非空白。
- TemplateRuntimePlan 包含必填欄位：
  - `template`
  - `input`
  - `workflow`
  - `perspectives`
  - `output_schema`
- TemplateRuntimePlan 不包含 provider credentials。
- TemplateRuntimePlan 不包含 prompt full text。
- Python 程式不得寫死 Boardroom / CEO / CTO / CFO / Risk / Execution 流程。
- 測試通過。

## 16. Implementation Guardrails

後續實作時必須遵守：

- Configuration over Code。
- Perspective over Agent。
- Decision over Chat。
- Boardroom as Template。
- Reference only。
- No provider call。
- No workflow execution。
- No database persistence。

若實作需要超出本文件範圍，必須先回到 Product Owner Gate，不可自行擴大 Sprint。
