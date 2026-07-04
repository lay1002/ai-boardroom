# Template Engine Design Review

## Summary

Template Engine Design = PASS

`template_engine_design.md` 可以接受。設計方向符合 `ARCHITECTURE.md` 所列的核心元件與 Config-Driven 原則，也符合 `AGENTS.md` 對 AI Decision Assistant V3 的要求：Boardroom 只能是 Template，不能是核心；Perspective、Workflow、Prompt、Provider、Output Schema 都不能寫死在程式碼中。

本次 Review 沒有發現 Must Fix。

## Good

- 明確將 Template Engine 定位為 Template Definition lifecycle 與 Runtime Plan generator，不負責執行 LLM、Workflow、Moderator、Consensus 或 Memory。
- 符合 Config Driven：Template 以 YAML 定義，程式只負責 load / validate / render，不把 Boardroom、Perspective、Provider、Workflow 寫死。
- 與 Perspective Engine 邊界清楚：Template Engine 只引用 `perspective_id`，Perspective Engine 才解析 Perspective Definition。
- 與 Workflow Engine 解耦：Template 只引用 `workflow_id` 與簡單 metadata，不把 workflow steps 寫進 Template。
- Provider 擴充方向正確：Template 只保存 `provider_policy_id`，實際 provider/model/credential/fallback 留給 Model Router / Provider Layer。
- MVP 範圍合理：聚焦 schema、loader、validator、runtime plan render、Boardroom sample，不碰 LLM、Memory、Admin UI、多租戶、DB-backed template。
- 可作為後續 Implementation 的主要設計依據，範圍足夠清楚。

## Review Items

### 1. 是否符合 ARCHITECTURE.md 的設計原則

結論：PASS。

`ARCHITECTURE.md` 指出核心元件包含 Template Engine、Perspective Engine、Workflow Engine、Decision Engine、Provider Layer、Memory Layer，並強調 Config-Driven Design 與不可 hardcode。設計文件符合這些方向，尤其明確定義 Template Engine 不跨界執行其他 Engine 的責任。

### 2. 是否真正做到 Config Driven，而不是 Code Driven

結論：PASS。

設計採用：

- `templates/<template_id>.yaml`
- `workflow_id`
- `perspective_id`
- `prompt_set_id`
- `provider_policy_id`
- `strategy_id`
- `schema_id`

這些都是 reference，而不是 code-level hardcode。Boardroom 也只作為 `templates/boardroom.yaml` sample，方向正確。

### 3. 是否與 Perspective Engine 的責任邊界清楚

結論：PASS。

文件清楚定義：

- Template Engine 決定要用哪些 `perspective_id`。
- Perspective Engine 負責解析 `perspective_id` 成 Perspective Definition。
- Template Engine 不讀 Perspective YAML、不組 prompt、不執行 perspective。

這個邊界符合 Perspective over Agent 原則。

### 4. 是否與 Workflow Engine 解耦

結論：PASS。

Template 只定義 What，Workflow 定義 How。文件也明確禁止把完整 workflow steps 放進 Template，避免 Template Engine 變成 Workflow Engine。

### 5. 是否具備未來 Provider 擴充能力

結論：PASS。

設計用 `provider_policy_id` 作為 provider policy reference，並把 provider selection、model selection、credential、fallback、retry 全部交給 Model Router / Provider Layer。這保留多 Provider 擴充能力，也避免把 Agnes / OpenAI / Claude 等供應商寫死在 Template Engine。

### 6. MVP 範圍是否合理

結論：PASS。

MVP 範圍夠小，且符合目前最優先目標：

- 要做：schema、loader、validator、render plan、Boardroom sample、必要驗證。
- 不做：LLM execution、Workflow execution、Perspective execution、Memory、Provider client、Model Router、Admin UI。

這個切法合理，沒有明顯過度設計。

### 7. 是否可以作為後續 Implementation 的唯一設計依據

結論：PASS with Should Fix。

可以作為後續 Implementation 的主要設計依據。為了讓 Claude Code 實作時更少歧義，建議在 Implementation 前補強幾個細節，但不是阻塞項。

## Must Fix

None。

## Should Fix

- 建議在設計文件補一段 `TemplateRuntimePlan` 的必填欄位清單，避免 implementation 時 response schema 過度自由。
- 建議明確指定 `status` 允許值，例如 `active` / `disabled`，或 MVP 先移除 `status`，避免 validator 實作時歧義。
- 建議明確說明 `input_schema.required_fields` 在 MVP 只驗證 `question` 是否存在且非空，不做完整 JSON Schema validation。
- 建議在 API Contract 標註本 Sprint 是否要實作 API；目前文件同時寫「設計未來 API contract」與「MVP 可先不建立 API」，後續 Sprint 需要 PO 決定。
- 建議定義 `template_id` / `perspective_id` 的命名規則，例如 lowercase alphanumeric、hyphen、underscore 擇一，避免 config file naming 不一致。

## Risks

- `ace-lite/ARCHITECTURE.md` 目前仍是高階目錄式綱要，細節不足；本 Review 主要依賴 `AGENTS.md`、已通過的 Architecture Review 與本設計文件本身判斷。
- 若 Implementation Sprint 同時實作 API、Loader、Validator、Renderer，範圍可能偏大；建議 PO 在 Sprint scope 明確決定是否包含 API。
- 若未明確定義 Runtime Plan schema，後續 Workflow Engine 可能依賴不穩定欄位。

## Suggestions

- 接受 `template_engine_design.md` 作為 Template Engine MVP 設計基礎。
- Implementation 前先補 Should Fix 中的 schema 細節即可，不需要重新設計整個 Template Engine。
- 第一個 Implementation Sprint 建議聚焦 loader / validator / renderer / sample template / tests；API 可視 Sprint scope 決定是否納入。

## Merge Decision

Template Engine Design = PASS

Must Fix: None

Should Fix: 有，但不阻塞 Design PASS。
