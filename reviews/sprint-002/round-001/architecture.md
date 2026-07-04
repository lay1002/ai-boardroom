# AI Decision Assistant V3 Architecture Review

## 結論

目前專案已具備三個可辨識層次：

1. `AI Decision Assistant V3` 的產品規範與開發治理文件。
2. `ACE Lite` 作為可運作的 AI collaboration development tool。
3. 舊 `ai-boardroom` 作為早期 Boardroom Template / Perspective Engine prototype。

目前最重要的架構判斷是：`ACE Lite` 不應直接併入 V3 Runtime 核心；它最合理的位置是開發流程工具，用來把需求討論收斂成 `final_prompt.md`。V3 Runtime 應另建以 Template / Workflow / Perspective / Model Router / Consensus / Memory 為核心的可配置 Decision System。

下一個最優先開發模組只能選一個：**Template Engine MVP**。

原因：Template Engine 是避免把 Boardroom 寫死、串接 Perspective / Workflow / Prompt / Output Schema 的最低成本核心邊界。沒有 Template Engine，後續 Decision Engine、Consensus Engine、Memory Engine 都會被迫寫死流程。

## 1. 目前已完成的功能

### 1.1 專案治理與開發流程

已完成：

- `AGENTS.md` 定義 AI Decision Assistant V3 的產品定位、工作規範、禁止事項與架構原則。
- `PROJECT_BOOTSTRAP.md` 定義進入專案前必讀文件與目前 Sprint 狀態。
- `docs/development/development-workflow.md` 定義 Manual Gate 開發流程。
- `docs/development/review-checklist.md` 定義 Codex Review 標準。
- `docs/development/sprint-checklist.md` 定義 Sprint Gate 與 Definition of Done。
- `docs/development/consensus-workflow.md` 定義目前唯一核准的 AI collaboration gate。
- `scripts/review_bridge.sh` 提供 deterministic Review Bridge gate automation。

目前開發治理重點很清楚：

```text
ChatGPT Architecture
↓
Claude Code Implementation
↓
Codex Review
↓
Claude Reply
↓
Codex Final Review
↓
Review Bridge Consensus
↓
final_consensus.md
↓
Product Owner Gate
↓
Commit
```

### 1.2 Root Review Bridge

`scripts/review_bridge.sh` 已完成：

- `init`：建立 sprint directory 與 `sprint_meta.env`。
- `skeleton`：依 Sprint Type 建立 canonical artifacts。
- `check`：檢查必要 artifacts 是否存在。
- `consensus`：依 deterministic markers 產生 `consensus_report.md`。
- `finalize`：只在 Gate PASS 時產生 `final_consensus.md`。
- `validate-final-consensus`：檢查 `final_consensus.md` 是否只存在 final round。

值得注意的是，Root Review Bridge 已支援：

- Implementation Sprint。
- Documentation Sprint。
- 固定 artifact 檔名。
- placeholder marker 防呆。
- deterministic marker gate。
- no final consensus, no commit 原則。

### 1.3 ACE Lite

`ace-lite/` 已是一個可運作 MVP，功能包含：

- FastAPI REST API。
- Session lifecycle。
- Developer / Reviewer / Finalizer 三角色 Orchestrator。
- Provider Adapter。
- Fake Provider。
- Agnes Provider。
- OpenAI-compatible Provider。
- role-level provider credentials。
- PostgreSQL schema。
- SQLite 測試支援。
- Alembic migrations。
- Round Summary deterministic extraction。
- CLI discussion script。
- E2E script。
- pytest 測試。

主要 API：

- `GET /health`
- `POST /providers/test`
- `POST /sessions`
- `POST /sessions/{session_id}/run`
- `GET /sessions/{session_id}`
- `GET /sessions/{session_id}/messages`
- `GET /sessions/{session_id}/summaries`

核心流程：

```text
User Request
↓
Developer proposal
↓
Reviewer JSON gate
↓
Developer revision if needed
↓
Reviewer approved
↓
Finalizer final_prompt
```

目前 Review Gate 條件：

```text
decision = approved
score >= 8
blockers = []
```

ACE Lite 目前資料模型：

- `sessions`
- `messages`
- `round_summaries`

### 1.4 舊 ai-boardroom prototype

`ai-boardroom/` 已具備早期 Boardroom 能力：

- FastAPI endpoint：`POST /api/boardroom`
- Boardroom orchestrator。
- 多 perspective 平行執行。
- Moderator 統整。
- Response builder。
- Board history persistence。
- Perspective config loader。
- Template config loader。
- Prompt builder。
- YAML perspective configs。
- YAML boardroom template config。

這部分有可保留的 prototype 價值，但不能作為 V3 核心直接延伸，因為仍存在固定 Boardroom 與固定 Perspective function resolver。

## 2. 目前整體 Architecture

目前實際 Architecture 可描述為三層並存：

```text
AI Decision Assistant V3 Workspace
│
├── Governance Layer
│   ├── AGENTS.md
│   ├── PROJECT_BOOTSTRAP.md
│   ├── docs/development/*.md
│   └── scripts/review_bridge.sh
│
├── Development Tool Layer
│   └── ace-lite/
│       ├── FastAPI API
│       ├── ACELiteOrchestrator
│       ├── Developer / Reviewer / Finalizer Providers
│       ├── Sessions / Messages / Round Summaries
│       └── CLI / E2E / Tests
│
└── Runtime Prototype Layer
    └── ai-boardroom/
        ├── Boardroom API
        ├── Perspective Loader
        ├── Template Loader
        ├── Prompt Builder
        ├── Agent Functions
        ├── Moderator
        └── Board Repository
```

### 2.1 Governance Layer

這層目前最成熟，已經明確定義：

- Platform First。
- Configuration over Code。
- Perspective over Agent。
- Decision over Chat。
- Manual Gate。
- Product Owner Gate。
- Codex 不實作、Claude Code 不 Review。

### 2.2 ACE Lite Layer

ACE Lite 架構相對完整，但定位應保持在 Development Tool：

```text
Requirement
↓
ACE Lite Discussion
↓
final_prompt.md
↓
Claude Code Implementation
↓
Codex Review
↓
Review Bridge Consensus
```

它適合處理需求收斂，不適合直接承擔 V3 Runtime 的 Decision Engine。

### 2.3 ai-boardroom Layer

舊 `ai-boardroom` 是 Runtime prototype，但目前仍偏 Boardroom-specific：

- API 名稱是 `/api/boardroom`。
- App title 是 `AI Boardroom`。
- `_PERSPECTIVE_MAP` 寫死 `ceo / cto / cfo / risk / execution` 到 Python function。
- Provider config 綁定 Agnes。
- Moderator 是單一固定流程。

它可以提供 Template / Perspective Engine 的早期實作參考，但不應直接成為 V3 核心架構。

## 3. 值得保留的設計

### 3.1 Manual Gate 與 Review Bridge

值得保留。

理由：

- 明確分離 ChatGPT / Claude Code / Codex / Product Owner 職責。
- 避免 auto-loop 造成範圍失控。
- deterministic marker 比純 LLM 判斷更適合作為 commit gate。
- artifact naming 規則清楚，方便稽核。

### 3.2 ACE Lite 的 Session / Message / Round Summary 模型

值得保留為 development discussion record 的基礎。

理由：

- `sessions` 保存一次討論狀態。
- `messages` 保存完整原文。
- `round_summaries` 降低後續 LLM context 成本。
- 錯誤會保存為 system error message，具備除錯價值。

### 3.3 Provider Adapter Pattern

值得保留。

理由：

- 已支援 fake / Agnes / openai-compatible。
- role-level provider config 已能支援不同 role 使用不同 provider / model。
- Health 不洩漏 API key。
- Provider factory 是後續 Model Router 的可用雛形。

### 3.4 ai-boardroom 的 Template / Perspective YAML 概念

值得保留概念，不建議保留原樣。

理由：

- 用 YAML 定義 perspective 與 template 符合 V3 可配置方向。
- `PerspectiveLoader`、`TemplateLoader`、`PromptBuilder` 是可演進的 prototype。
- 但需移除 Boardroom-specific resolver 與固定角色函式。

### 3.5 Reviewer JSON Gate

值得保留作為 ACE Lite 內部 gate。

理由：

- 結構簡單。
- 可測試。
- 可 deterministic parse。
- 比自由文字 review 更容易自動判斷狀態。

## 4. 需要重構的地方

### 4.1 主專案 Architecture / Vision 文件是空的

目前：

- `docs/architecture.md` 為空。
- `docs/vision.md` 為空。

風險：

- `PROJECT_BOOTSTRAP.md` 要求必讀這兩份文件，但文件沒有實質內容。
- 新 Agent 接手時只能依賴 `AGENTS.md`，缺少正式 Architecture single source of truth。

建議：

- 先補 `docs/vision.md` 與 `docs/architecture.md`。
- 不要把 ACE Lite 或 Boardroom 寫成 V3 核心。
- 明確定義 Runtime Engine 邊界。

### 4.2 ACE Lite 與 Root Review Bridge 有重疊

目前存在兩套 Review Bridge：

- Root：`scripts/review_bridge.sh`
- ACE Lite：`ace-lite/scripts/review_bridge.py`

風險：

- artifact naming 不完全一致。
- final consensus 位置規則不同。
- gate status 與 marker 判斷規則不同。
- 未來 Product Owner / Claude / Codex 可能不知道哪一套是 canonical。

建議：

- Root `scripts/review_bridge.sh` 應保留為 workspace canonical gate。
- ACE Lite 的 `review_bridge.py` 應降級為 historical / local utility，或未來移除。
- ACE Lite 整合 Root workflow 時，只產生 `final_prompt.md`，不要管理 commit consensus。

### 4.3 ACE Lite role 固定為 Developer / Reviewer / Finalizer

目前 ACE Lite 的角色是固定的：

- Developer
- Reviewer
- Finalizer

這對 development tool 合理，但不能直接映射成 V3 Runtime 的 Perspective Engine。

風險：

- 若直接併入 Runtime，會把多觀點決策誤建模成開發審查流程。
- Developer / Reviewer / Finalizer 是開發協作角色，不是使用者決策 perspectives。

建議：

- ACE Lite 維持 development tool。
- V3 Runtime 另建可配置 Perspective / Workflow / Consensus schema。

### 4.4 ai-boardroom 仍有硬編碼 Perspective resolver

目前 `ai-boardroom/backend/orchestrator.py` 有 `_PERSPECTIVE_MAP`：

```text
ceo -> agents.ceo.ask_ceo
cto -> agents.cto.ask_cto
cfo -> agents.cfo.ask_cfo
risk -> agents.risk.ask_risk
execution -> agents.execution.ask_execution
```

風險：

- 違反 Perspective over Agent。
- 新增 perspective 必須改 Python。
- Boardroom 會被誤當成核心產品。

建議：

- 保留 YAML loader 概念。
- 移除 fixed function resolver。
- Perspective execution 應透過 generic provider / model router / prompt registry 執行。

### 4.5 Provider / Model Router 尚未成為 V3 通用能力

目前 provider adapter 存在於 ACE Lite。

風險：

- V3 Runtime 尚無通用 Model Router。
- ai-boardroom 舊 config 仍綁 Agnes。
- 未來可能出現 ACE Lite 一套 provider、Runtime 另一套 provider 的重複設計。

建議：

- 短期不要抽大平台。
- 等 Template Engine MVP 完成後，再把 ACE Lite provider factory 的好設計抽象成 Runtime Model Router。

### 4.6 Prompt Registry 尚未形成

目前 prompt 分散在：

- `ace-lite/app/prompts/*.md`
- `ai-boardroom/backend/prompts/*.md`
- YAML perspective prompt fields。

風險：

- Prompt 版本、用途、input variables、output format 未集中管理。
- 不符合 AGENTS.md 對 Prompt Registry 的要求。

建議：

- Template Engine MVP 先定義 prompt reference，不急著做完整 Prompt Registry。
- 下一階段再建立 Prompt Registry schema。

### 4.7 Runtime Engine 邊界尚未落地

AGENTS.md 定義了多個核心 Engine：

- Decision Engine
- Perspective Engine
- Consensus Engine
- Memory Engine
- Knowledge Engine
- Workflow Engine
- Prompt Engine
- Model Router
- Moderator Engine

目前只有 prototype 層的 Perspective / Template 概念，尚未形成 V3 Runtime backend。

建議：

- 不要一次建立所有 Engine。
- 先用 Template Engine MVP 建立最小 schema 與 loader。
- 後續 Engine 依實際流程逐步接上。

## 5. 與 ACE Lite 最合理的整合方式

### 5.1 正確定位

ACE Lite 應定位為：

```text
Development Tool
```

不是：

```text
V3 Runtime Engine
```

最合理關係：

```text
Product Owner Requirement
↓
ACE Lite
↓
final_prompt.md
↓
Claude Code
↓
Codex Review
↓
Root Review Bridge
↓
Product Owner Gate
↓
V3 Runtime Codebase
```

### 5.2 Integration Boundary

ACE Lite 只負責輸出：

- `final_prompt.md`
- discussion history
- round summaries

ACE Lite 不負責：

- V3 Runtime execution。
- Decision Engine。
- Perspective Engine。
- Consensus Engine。
- Memory Engine。
- Commit gate。
- Product Owner approval。

### 5.3 不建議直接整併程式碼

不建議把 ACE Lite 的 Orchestrator 直接搬進 V3 Runtime。

理由：

- ACE Lite workflow 是 `Developer -> Reviewer -> Finalizer`。
- V3 Runtime workflow 是 `Perspective -> Multi Model Analysis -> Moderator -> Consensus -> Decision -> Memory`。
- 兩者角色語意不同。
- 直接共用 Orchestrator 會造成概念污染。

### 5.4 可借用的 ACE Lite 設計

可借用：

- Provider adapter interface。
- role-level provider config 概念。
- Session / Message / Summary persistence pattern。
- deterministic gate parsing。
- API / Orchestrator 分層。
- Fake mode 測試策略。
- error message redaction。

不可直接借用為 Runtime 核心：

- Developer / Reviewer / Finalizer 固定流程。
- final_prompt 作為決策輸出。
- Reviewer score gate 作為產品 Consensus Engine。

### 5.5 建議整合 Roadmap

建議順序：

1. 保留 ACE Lite 為獨立 development tool。
2. Root Review Bridge 維持唯一 commit consensus gate。
3. V3 Runtime 先建立 Template Engine MVP。
4. Template Engine 支援 Boardroom Template 但不寫死 Boardroom。
5. 之後再從 ACE Lite provider factory 萃取 Model Router 設計。

## 6. 建議下一個最優先開發的模組

### 選擇：Template Engine MVP

只能選一個模組時，建議下一個最優先開發：

```text
Template Engine MVP
```

### 推薦原因

Template Engine 是 V3 Runtime 最小核心邊界。

它能同時解決：

- Boardroom 不再是核心，只是一個 template。
- Perspective 可由 template 引用。
- Workflow 可由 template 定義。
- Model / Prompt / Output Schema 可透過 reference 掛載。
- 後續 Decision Engine 有穩定輸入。

若先做 Decision Engine，會缺少 template definition，只能寫死流程。

若先做 Perspective Engine，會缺少 template context，容易回到固定 CEO / CTO / CFO。

若先做 Memory Engine，會缺少 decision output schema，無法判斷該記什麼。

若先做 Model Router，會先解技術供應商問題，但無法解產品流程可配置問題。

### Template Engine MVP 建議範圍

只做最小可用，不做過度設計。

建議輸入：

```text
templates/*.yaml
```

建議 schema：

```yaml
template_id: boardroom
name: Boardroom Template
description: Multi-perspective executive decision review
version: 1
workflow_id: standard_multi_perspective_decision
perspectives:
  - ceo
  - cto
  - cfo
  - risk
  - execution
models:
  default_router: default
moderator:
  strategy: synthesize_conflicts
consensus:
  strategy: weighted_consensus
output_schema:
  type: decision_output_v1
```

MVP 只需要完成：

- Template YAML load。
- Template schema validation。
- Template list / get API。
- Boardroom template 作為第一個 sample。
- 不執行 LLM。
- 不接 Memory。
- 不做 UI。
- 不做 admin editor。

### 完成標準

Template Engine MVP 完成時應能回答：

- 系統有哪些 templates？
- 每個 template 引用哪些 perspectives？
- 每個 template 使用哪個 workflow？
- 每個 template 使用哪個 consensus strategy？
- 每個 template 的 output schema 是什麼？
- Boardroom 是否只是 template，而不是核心？

## 7. 風險與注意事項

### 7.1 目前 docs/architecture.md 與 docs/vision.md 為空

這是最高優先文件風險。

建議 Template Engine MVP 前，先補最小版 vision / architecture，否則 Claude Code 會缺少正式架構依據。

### 7.2 不要讓 ACE Lite 變成 Runtime

ACE Lite 很完整，但它的成功不代表它應該成為 V3 Runtime。

正確做法是借用 pattern，不搬 workflow。

### 7.3 不要從 ai-boardroom 直接演化成主產品

`ai-boardroom` 應視為 prototype。

可保留：

- YAML template / perspective 概念。
- parallel perspective execution 概念。
- moderator 概念。

需避免：

- 固定 Boardroom API。
- 固定 CEO / CTO / CFO。
- 固定 Agnes config。
- 固定 moderator flow。

### 7.4 本次未執行測試

本次任務是 Architecture Review，且使用者明確要求不要修改程式。

我沒有執行 pytest 或 E2E，避免產生測試快取或其他非必要狀態變動。Review 依據為文件與程式碼靜態閱讀。

## 8. 最終建議

下一步只做一件事：

```text
Template Engine MVP
```

建議 Sprint 目標：

```text
建立 V3 Runtime 的 Template Definition / Loader / Validation / Read API，
並把 Boardroom 定義成第一個 template sample。
```

這會把專案從目前的 prototype / development tooling 狀態，推進到真正符合 AI Decision Assistant V3 定位的可配置 Decision System 基礎。
