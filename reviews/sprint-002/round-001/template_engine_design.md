# Template Engine MVP Design

## 結論

Template Engine MVP 的目標是建立 AI Decision Assistant V3 的第一個 Runtime 核心邊界：

```text
Template 可配置
Perspective 可引用
Workflow 可引用
Output Schema 可引用
Provider 不寫死
Boardroom 只是 Template
```

本次只做 Design，不做 Implementation。Template Engine MVP 不呼叫 LLM、不執行 Workflow、不產生最終 Decision，只負責載入、驗證、解析與 render 一份可交給後續 Engine 使用的 Template Runtime Plan。

## 1. Responsibilities

Template Engine 負責 Template Definition 的生命週期。

主要職責：

- 從設定來源載入 Template Definition。
- 驗證 Template Schema 是否正確。
- 驗證必要欄位是否存在。
- 驗證 Template ID 與檔名一致。
- 驗證 Template references 格式正確。
- 保留 Perspective、Workflow、Prompt、Provider、Output Schema 的引用關係。
- 將 Template Definition render 成 Runtime Plan。
- 提供 Template list / get / render 的讀取能力。
- 確保 Boardroom 只是其中一個 Template，不是系統核心。

Template Engine 不負責：

- 不執行 Perspective。
- 不組 prompt 內容。
- 不呼叫 LLM。
- 不選擇實際 Provider。
- 不執行 Workflow steps。
- 不執行 Moderator。
- 不計算 Consensus。
- 不寫入 Memory。
- 不產生 Decision Output。
- 不處理使用者長期記憶。

Template Engine 的輸出應是結構化的 runtime planning data，而不是聊天文字。

## 2. 與 Perspective Engine 的責任邊界

Template Engine 與 Perspective Engine 的邊界必須清楚，避免回到固定 Agent 設計。

### Template Engine 負責

- 定義此 Template 需要哪些 perspective references。
- 定義 perspective 的執行順序或分組。
- 定義 perspective 是否必填。
- 定義此 Template 預期使用的 prompt references。
- 定義此 Template 預期使用的 provider policy reference。
- 定義此 Template 預期輸出 schema。

Template Engine 只知道：

```text
這個 Template 需要 ceo、cto、risk 這些 perspective_id
```

Template Engine 不知道：

```text
ceo prompt 內容是什麼
ceo 要用哪個實際 model
ceo 如何執行
ceo 的 LLM response 如何 parse
```

### Perspective Engine 負責

- 依 `perspective_id` 載入 Perspective Definition。
- 驗證 Perspective Definition。
- 組合 perspective-level prompt metadata。
- 定義 perspective 的 role、purpose、input variables、output format。
- 將 perspective definition 提供給後續 execution layer。

Perspective Engine 不負責：

- 不決定某次決策要使用哪些 perspectives。
- 不決定 Template 使用哪個 Workflow。
- 不決定整體 consensus strategy。
- 不管理 Template lifecycle。

### 邊界原則

正確關係：

```text
Template Engine
  └── references perspective_id

Perspective Engine
  └── resolves perspective_id into Perspective Definition
```

錯誤關係：

```text
Template Engine 直接寫死 CEO prompt
Perspective Engine 自行決定 Boardroom 要跑哪些角色
```

## 3. Template Schema 設計

MVP 使用 YAML 作為 Template Definition 格式。

建議位置：

```text
templates/<template_id>.yaml
```

範例：

```yaml
template_id: boardroom
name: Boardroom Decision Template
version: 1.0.0
status: active
description: Multi-perspective structured decision analysis.

input_schema:
  type: decision_request_v1
  required_fields:
    - question

workflow:
  workflow_id: multi_perspective_decision_v1
  mode: parallel_perspectives

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
  prompt_set_id: boardroom_default_prompts_v1

provider_policy:
  provider_policy_id: default_multi_model_policy_v1

moderator:
  strategy_id: synthesize_conflicts_v1

consensus:
  strategy_id: majority_with_risk_override_v1

output_schema:
  schema_id: structured_decision_v1

metadata:
  category: strategy
  tags:
    - boardroom
    - decision
```

### 必填欄位

MVP 必填：

- `template_id`
- `name`
- `version`
- `description`
- `input_schema`
- `workflow`
- `perspectives`
- `output_schema`

MVP 可選但建議保留：

- `status`
- `prompt_policy`
- `provider_policy`
- `moderator`
- `consensus`
- `metadata`

### 欄位說明

`template_id`

- Template 唯一識別碼。
- 必須與檔名一致。
- 例：`boardroom` 對應 `templates/boardroom.yaml`。

`version`

- Template Definition 版本。
- 用於未來 template migration 與相容性檢查。

`input_schema`

- 描述此 Template 接受的輸入結構。
- MVP 只做 reference，不實作完整 JSON Schema engine。

`workflow`

- 指向 Workflow Definition。
- Template 不直接定義完整 workflow steps。

`perspectives`

- Template 使用的 perspective references。
- 只放 `perspective_id` 與 execution metadata。
- 不放 prompt content。
- 不放 provider API key。

`prompt_policy`

- 指向 Prompt Registry 或 prompt set。
- MVP 可先保留為 reference。

`provider_policy`

- 指向 provider selection policy。
- MVP 可先保留為 reference。

`moderator`

- 指向 moderator strategy。
- MVP 不執行 moderator。

`consensus`

- 指向 consensus strategy。
- MVP 不執行 consensus。

`output_schema`

- 指向 Decision Output schema。
- MVP 只驗證 reference 存在與格式。

### Validation Rules

MVP validation rules：

- YAML 必須是 mapping。
- `template_id` 不可空白。
- `template_id` 必須與檔名一致。
- `name` 不可空白。
- `version` 不可空白。
- `perspectives` 至少一個。
- `perspectives[].perspective_id` 不可空白。
- `perspectives[].perspective_id` 不可重複。
- `perspectives[].order` 若存在，必須為正整數。
- `workflow.workflow_id` 不可空白。
- `output_schema.schema_id` 不可空白。
- 不允許未知 top-level fields，避免 config drift。

MVP 不驗證：

- Perspective Definition 是否真的完整可執行。
- Provider credentials 是否存在。
- Workflow steps 是否可執行。
- Prompt Registry 是否完整。
- Output Schema 是否能 parse LLM response。

這些驗證屬於後續 Engine 或 integration validation。

## 4. Template Loader 設計

Template Loader 是 Template Engine 的 I/O 邊界。

### Loader 職責

- 依 `template_id` 找到 YAML。
- 讀取 YAML。
- 解析成 raw mapping。
- 交給 Template Validator。
- 回傳 Template Definition。
- 支援列出所有 templates。
- 提供清楚錯誤訊息。

### Loader 輸入

```text
template_id
base_dir
```

MVP 預設：

```text
base_dir = templates/
```

### Loader 輸出

```text
TemplateDefinition
```

### Loader 錯誤類型

MVP 至少要區分：

- Template file not found。
- Invalid YAML。
- YAML is not mapping。
- Schema validation failed。
- Template ID mismatch。

錯誤訊息要能讓 Claude Code 或人工開發者直接定位問題。

### Caching

MVP 可使用 process-level read cache，但要保持簡單。

建議：

- `load(template_id)` 可 cache 已載入 Template。
- `load_all()` 可排序回傳。
- 不做 hot reload。
- 不做 distributed cache。
- 不做 database-backed cache。

### Loader 不做的事

- 不讀 Perspective YAML。
- 不讀 Workflow YAML。
- 不讀 Prompt 檔案。
- 不讀 Provider credentials。
- 不呼叫 LLM。
- 不寫 DB。

## 5. Template Render Flow

Template Render 的目標是把 Template Definition 轉成後續 Runtime 可使用的計畫，而不是執行計畫。

### Render Input

```text
template_id
user_input
```

MVP 的 `user_input` 最小格式：

```yaml
question: 使用者問題
context: 可選背景
```

### Render Output

輸出稱為：

```text
TemplateRuntimePlan
```

建議結構：

```yaml
template:
  template_id: boardroom
  name: Boardroom Decision Template
  version: 1.0.0

input:
  question: 是否要進入日本市場？
  context: optional

workflow:
  workflow_id: multi_perspective_decision_v1
  mode: parallel_perspectives

perspectives:
  - perspective_id: ceo
    required: true
    order: 10
  - perspective_id: cto
    required: true
    order: 20

prompt_policy:
  prompt_set_id: boardroom_default_prompts_v1

provider_policy:
  provider_policy_id: default_multi_model_policy_v1

moderator:
  strategy_id: synthesize_conflicts_v1

consensus:
  strategy_id: majority_with_risk_override_v1

output_schema:
  schema_id: structured_decision_v1
```

### Render Steps

```text
1. Template Loader 載入 Template Definition
2. Template Validator 驗證 Template Definition
3. Render 驗證 user_input 符合 input_schema 的 MVP 要求
4. Render 依 perspectives order 排序
5. Render 組出 TemplateRuntimePlan
6. 回傳 Runtime Plan 給 Workflow / Decision layer
```

### Render 不做的事

- 不呼叫 Perspective Engine resolve prompt。
- 不執行 Workflow。
- 不呼叫 Provider。
- 不產生 Moderator input。
- 不做 Consensus。
- 不寫 Memory。

Render 是 planning step，不是 execution step。

## 6. Template 與 Workflow 的關係

Template 定義「這類決策要用什麼結構」。

Workflow 定義「這個結構要怎麼被執行」。

### Template 負責 What

Template 回答：

- 這是什麼決策場景？
- 需要哪些 perspectives？
- 使用哪個 workflow？
- 使用哪個 output schema？
- 使用哪個 consensus strategy reference？
- 使用哪個 provider policy reference？

### Workflow 負責 How

Workflow 回答：

- perspectives 是平行或序列執行？
- 哪一步呼叫 Moderator？
- 哪一步執行 Consensus？
- 哪一步產生 Decision Output？
- 失敗時如何停止？
- 是否需要 human review？

### 關係圖

```text
Template Definition
  ├── workflow_id
  ├── perspectives[]
  ├── provider_policy_id
  ├── moderator.strategy_id
  ├── consensus.strategy_id
  └── output_schema.schema_id

Workflow Engine
  └── uses TemplateRuntimePlan to execute steps
```

### MVP 原則

Template Engine 只保存 `workflow_id` 與簡單 execution metadata。

不在 Template 內寫完整 workflow steps，避免 Template 變成 Workflow Engine。

## 7. 未來如何支援多 Provider

多 Provider 不應由 Template Engine 直接實作。

Template Engine 只引用 Provider Policy。

### Provider Policy Reference

Template 中只放：

```yaml
provider_policy:
  provider_policy_id: default_multi_model_policy_v1
```

未來 Provider Policy 可定義：

```yaml
provider_policy_id: default_multi_model_policy_v1
default_provider: agnes
default_model: agnes-2.0-flash
role_overrides:
  ceo:
    provider: openai
    model: gpt-4.1
  risk:
    provider: claude
    model: claude-sonnet
fallback:
  provider: local
  model: llama
```

### 責任分工

Template Engine：

- 保存 provider policy reference。
- 在 Runtime Plan 中傳遞 provider policy reference。
- 不解析 API key。
- 不建立 provider client。
- 不選 model。

Model Router / Provider Layer：

- 載入 Provider Policy。
- 選擇實際 provider。
- 選擇 model。
- 管理 fallback。
- 管理 credentials。
- 管理 timeout / retry。

### 避免 Hardcode

禁止在 Template Engine 中寫死：

- OpenAI。
- Claude。
- Gemini。
- Agnes。
- Local model。
- model name。
- API base URL。
- API key。

Template Engine 永遠只處理 reference。

## 8. MVP 範圍

### MVP 要做

MVP 做最小但完整的 Template Engine：

- 建立 Template Schema 設計。
- 建立 YAML-based Template Definition。
- 支援 `templates/<template_id>.yaml`。
- 支援 Boardroom Template sample。
- 支援 Template Loader。
- 支援 Template Validator。
- 支援 `load(template_id)`。
- 支援 `load_all()`。
- 支援 Template Runtime Plan render。
- 驗證 required fields。
- 驗證 duplicate perspectives。
- 驗證 template ID 與檔名一致。
- 定義清楚錯誤類型。
- 設計未來 API contract：
  - List Templates
  - Get Template
  - Render Template Plan

### MVP 不做

MVP 不做以下事項：

- 不建立完整 Decision Engine。
- 不建立完整 Workflow Engine。
- 不建立完整 Perspective Engine execution。
- 不呼叫 LLM。
- 不接 ACE Lite Orchestrator。
- 不接 Root Review Bridge。
- 不做 Memory Engine。
- 不做 Knowledge Engine。
- 不做 Prompt Registry 實作。
- 不做 Provider client。
- 不做 Model Router。
- 不做 Admin UI。
- 不做 Frontend。
- 不做多租戶。
- 不做權限系統。
- 不做資料庫儲存 Template。
- 不做 hot reload。
- 不做 template version migration。

## 9. 建議 API Contract

本節只做設計，不代表本次實作。

### List Templates

```http
GET /templates
```

Response：

```yaml
templates:
  - template_id: boardroom
    name: Boardroom Decision Template
    version: 1.0.0
    description: Multi-perspective structured decision analysis.
```

### Get Template

```http
GET /templates/{template_id}
```

Response：

```yaml
template_id: boardroom
name: Boardroom Decision Template
version: 1.0.0
description: Multi-perspective structured decision analysis.
workflow:
  workflow_id: multi_perspective_decision_v1
perspectives:
  - perspective_id: ceo
    required: true
    order: 10
output_schema:
  schema_id: structured_decision_v1
```

### Render Template Plan

```http
POST /templates/{template_id}/render
```

Request：

```yaml
question: 是否要進入日本市場？
context: 公司目前已有台灣與香港市場。
```

Response：

```yaml
template:
  template_id: boardroom
  version: 1.0.0
workflow:
  workflow_id: multi_perspective_decision_v1
perspectives:
  - perspective_id: ceo
    required: true
    order: 10
output_schema:
  schema_id: structured_decision_v1
```

## 10. Folder Structure 建議

本節只做設計。

```text
backend/
└── app/
    ├── engines/
    │   └── template/
    │       ├── loader
    │       ├── schemas
    │       ├── validator
    │       └── renderer
    ├── api/
    │   └── templates
    └── schemas/
        └── templates

templates/
└── boardroom.yaml
```

若 Sprint 目標需要更小，MVP 可先不建立 API，只完成 loader / validator / renderer 與測試。

## 11. Acceptance Criteria

Template Engine MVP 完成時，應能驗證：

- 可以列出所有 template definitions。
- 可以載入 `boardroom` template。
- 無效 YAML 會回傳明確錯誤。
- 缺少必填欄位會回傳明確錯誤。
- 重複 perspective 會被拒絕。
- `template_id` 與檔名不一致會被拒絕。
- Render 後會產生 TemplateRuntimePlan。
- Runtime Plan 不包含 provider credentials。
- Runtime Plan 不包含 hardcoded Boardroom logic。
- Boardroom 僅存在於 `templates/boardroom.yaml`。

## 12. Design Decision

Template Engine MVP 應採取：

```text
YAML first
Reference only
No execution
No provider call
No workflow steps inside Template
Boardroom as sample Template
```

這是目前最符合 AI Decision Assistant V3 的設計方向，也最能避免把 Boardroom、Provider、Prompt 或 Workflow 寫死在程式碼中。
