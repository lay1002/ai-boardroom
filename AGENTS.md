# AGENTS.md — AI Decision Assistant V3 專案工作規範

本文件是 AI Decision Assistant V3 專案的共同工作規範。

適用於：

* Codex
* Claude Code
* Cursor
* 其他 AI Coding Agent
* 人工開發者

除非專案另有明確規定，所有開發、修改、重構、測試、文件撰寫與除錯工作，都必須遵守本文件。

---

# 0. 專案定位

## 0.1 專案名稱

AI Decision Assistant V3

---

## 0.2 核心定位

AI Decision Assistant V3 不是聊天機器人。

它是一套：

AI Decision Operating System

核心目標是協助使用者針對任何複雜問題，透過多觀點、多模型、多流程進行結構化決策。

---

## 0.3 產品核心流程

任何問題

→ 選擇 Perspective

→ 多個 AI Model 平行分析

→ Moderator 統整

→ Consensus 收斂

→ Decision 輸出

→ Memory 儲存

→ Learning 優化

---

## 0.4 核心引擎

系統應以 Engine 為核心模組設計：

* Decision Engine
* Perspective Engine
* Consensus Engine
* Memory Engine
* Knowledge Engine
* Workflow Engine
* Prompt Engine
* Model Router
* Moderator Engine

---

## 0.5 重要產品原則

AI Boardroom 不是整個產品。

AI Boardroom 只是 AI Decision Assistant V3 裡的一種 Template。

正確關係是：

```text
AI Decision Assistant V3
└── Templates
    ├── Boardroom Template
    ├── Investment Template
    ├── Strategy Template
    ├── Personal Decision Template
    ├── Research Template
    └── Custom Template
```

不可把 Boardroom 寫死成系統核心。

---

# 1. 核心工作原則

所有工作遵守以下優先順序：

```text
正確性優先於速度
理解優先於猜測
簡單優先於複雜
可維護性優先於炫技
可配置優先於寫死
```

---

# 2. 語言與溝通規範

## 2.1 回覆語言

所有回覆一律使用繁體中文。

使用台灣常用術語。

專有名詞可以保留英文，例如：

* Backend
* Frontend
* Workflow
* Agent
* Engine
* Prompt
* Template
* API
* Database

---

## 2.2 回覆風格

回覆應：

* 清楚
* 直接
* 精簡
* 可執行
* 避免冗長說明

不要使用模糊語氣。

不要為了看起來完整而加入不必要內容。

---

## 2.3 需求不明確時

若需求不明確，必須先說明目前理解。

必要時提出問題。

不可自行假設。

若存在多種可能解讀，必須明確指出差異。

---

# 3. 執行前必須先理解

開始任何工作前，必須先理解：

* 需求目標
* 現有架構
* 相關程式碼
* 呼叫流程
* 共用元件
* 相依關係
* 成功條件
* 驗證方式
* 完成標準

不可未理解就直接修改。

---

# 4. 簡單優先

預設使用最簡單可行方案。

禁止：

* 過度設計
* 預先設計未來可能用不到的抽象層
* 增加目前需求沒有要求的功能
* 為了彈性而犧牲可讀性
* 為了架構漂亮而增加維護負擔

只有當需求已經明確需要擴充性時，才允許增加抽象層。

---

# 5. 只修改必要範圍

每次修改只處理與需求直接相關的內容。

禁止：

* 順便重構
* 順便優化
* 順便調整格式
* 順便改命名
* 修改無關程式碼
* 改變未被要求的行為

必須遵循現有專案風格。

---

# 6. 可配置優先，禁止寫死

AI Decision Assistant V3 的核心原則是：

所有決策流程都應可配置。

禁止在程式碼中寫死：

* AI Model
* Agent
* Perspective
* Workflow
* Prompt
* Template
* Decision Tree
* Moderator 規則
* Consensus 規則
* Memory 策略
* Knowledge Source
* 評分權重
* 輸出格式

應放在：

* Database
* Config
* YAML
* JSON
* Admin UI
* Template Definition
* Prompt Registry

---

# 7. 建議技術方向

目前專案建議架構如下。

## 7.1 Backend

* Python
* FastAPI
* Pydantic
* SQLAlchemy
* PostgreSQL
* pgvector
* Redis

---

## 7.2 Frontend

* Next.js
* TypeScript
* Tailwind CSS

---

## 7.3 AI / LLM

系統應支援多模型，不可綁死單一供應商。

可支援：

* OpenAI
* Claude
* Gemini
* Agnes API
* Local Model

模型選擇應透過 Model Router 處理。

---

## 7.4 Database

優先使用 PostgreSQL。

向量記憶使用 pgvector。

---

## 7.5 Workflow

Workflow 不應寫死在程式裡。

應以 Workflow Definition 描述：

* workflow_id
* name
* description
* input_schema
* steps
* perspectives
* models
* moderator
* consensus_strategy
* output_schema

---

# 8. 建議專案目錄

建議目錄如下：

```text
ai-decision-assistant/
├── AGENTS.md
├── README.md
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── api/
│   │   ├── core/
│   │   ├── engines/
│   │   │   ├── decision/
│   │   │   ├── perspective/
│   │   │   ├── consensus/
│   │   │   ├── memory/
│   │   │   ├── knowledge/
│   │   │   ├── workflow/
│   │   │   └── prompt/
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── services/
│   │   └── repositories/
│   ├── tests/
│   └── pyproject.toml
│
├── frontend/
│   ├── app/
│   ├── components/
│   ├── lib/
│   └── package.json
│
├── docs/
│   ├── vision.md
│   ├── architecture.md
│   ├── workflow.md
│   ├── prompt.md
│   ├── memory.md
│   └── api.md
│
└── templates/
    ├── boardroom.yaml
    ├── investment.yaml
    ├── strategy.yaml
    └── personal-decision.yaml
```

---

# 9. Coding Rules

## 9.1 通用規則

所有程式碼必須：

* 清楚
* 可讀
* 可維護
* 可測試
* 避免重複
* 避免過度抽象
* 避免隱藏副作用

---

## 9.2 Python 規則

Python 程式碼必須：

* 使用 type hints
* 使用 Pydantic 驗證資料
* 使用清楚的 function name
* 避免大型 function
* 避免全域狀態
* 避免 hardcode config
* 錯誤處理要明確

---

## 9.3 API 規則

API 必須：

* 使用 RESTful 設計
* 輸入輸出 schema 明確
* 錯誤訊息清楚
* 不回傳內部錯誤堆疊給前端
* 不在 Controller 寫商業邏輯

---

## 9.4 Frontend 規則

Frontend 必須：

* 使用 TypeScript
* Component 職責清楚
* 不把商業邏輯塞進 UI
* API 呼叫集中管理
* 狀態管理簡單優先
* UI 命名清楚

---

# 10. Prompt 規則

Prompt 是系統核心資產。

禁止把 Prompt 散落在程式碼中。

Prompt 應集中管理。

每個 Prompt 應包含：

* prompt_id
* name
* purpose
* role
* input_variables
* output_format
* version
* created_at
* updated_at

Prompt 修改必須保留版本概念。

---

# 11. Agent / Perspective 規則

Perspective 不是固定 Agent。

Perspective 應是可配置的觀點角色。

例如：

* CEO
* CTO
* CFO
* Risk Officer
* Execution Officer
* Investor
* Customer
* Legal
* Marketing
* Product Manager
* Buffett
* Munger
* Musk
* Cathie Wood

禁止在程式碼中寫死 Perspective。

Perspective 應由資料或設定載入。

---

# 12. Decision Output 規則

所有 Decision Output 應盡量結構化。

建議包含：

* question
* context
* perspectives
* conflicts
* consensus
* recommendation
* risks
* action_items
* confidence
* assumptions
* next_steps

不可只輸出一段聊天文字。

---

# 13. Memory 規則

Memory Engine 應區分不同記憶類型：

* User Memory
* Project Memory
* Decision Memory
* Workflow Memory
* Knowledge Memory
* Feedback Memory

記憶寫入前應確認：

* 是否值得長期保存
* 是否與決策有關
* 是否可被未來查詢重用
* 是否涉及敏感資訊

---

# 14. Knowledge 規則

Knowledge Engine 應支援多來源：

* User Upload
* Database
* Web Search
* API
* Notes
* Previous Decisions
* Vector Store

Knowledge Source 必須保留來源資訊。

不可輸出無來源的假定內容。

---

# 15. 工具優先於推測

若程式、規則或工具能準確完成工作，優先使用確定性方案。

只有在需要以下任務時才使用 AI 判斷：

* 推論
* 摘要
* 分類
* 內容生成
* 策略分析
* 決策建議

---

# 16. Token 與工作階段限制

單次任務上限：

```text
4,000 tokens
```

單次工作階段上限：

```text
30,000 tokens
```

若接近限制，必須先整理摘要，再建立新工作階段。

不可在上下文混亂時繼續硬做。

---

# 17. 衝突必須揭露

若發現以下情況，必須明確指出：

* 多種實作方式
* 多套規範
* 不一致設計
* 舊架構與新架構衝突
* 需求與現有程式衝突
* 短期需求與長期架構衝突

必須說明：

* 衝突位置
* 建議方案
* 選擇理由

不可混合互相衝突的做法。

---

# 18. 先閱讀，再修改

修改前必須先閱讀相關檔案。

必須理解：

* 目前程式碼
* 呼叫流程
* 共用模組
* 相依關係
* 設計意圖

若不了解設計原因，必須先提出問題或標記不確定性。

不可直接改動。

---

# 19. 測試與驗證

測試不只驗證表面輸出。

必須驗證：

* 商業邏輯
* 設計目的
* 使用情境
* 錯誤情境
* 邊界條件

完成後必須說明驗證方式。

---

# 20. 建立檢查點

完成重要步驟後，必須說明：

* 已完成內容
* 驗證結果
* 剩餘工作
* 風險事項

若無法描述目前狀態，應停止執行並重新整理現況。

---

# 21. 遵循既有規範

專案一致性優先於個人偏好。

若認為既有規範不理想，可以提出建議，但不可自行改變方向。

---

# 22. 不隱藏問題

若存在以下情況，必須明確說明：

* 未驗證項目
* 已知風險
* 不確定因素
* 尚未完成內容
* 無法確認的假設
* 工具限制
* 測試未通過

不可假裝完成。

---

# 23. 提供完整可使用版本

輸出內容應可直接使用。

例如：

* 程式碼
* JSON
* YAML
* SQL
* 設定檔
* Shell Script
* Markdown 文件

不得使用：

* ...
* 部分省略
* 自行補充
* TODO 代替實作

除非使用者明確要求簡化版。

---

# 24. 一次提供一個最佳方案

預設情況下，只提供最推薦方案。

必須說明推薦原因。

避免列出大量替代方案。

除非使用者明確要求比較。

---

# 25. 根因優先

發生問題時，必須依照順序處理：

1. 找出根因
2. 驗證根因
3. 提出修正方案
4. 說明驗證方式

避免治標不治本。

---

# 26. 保持可維護性

所有修改應考慮：

* 可讀性
* 可維護性
* 一致性
* 可驗證性
* 可擴充性
* 可回滾性

短期修補不應增加長期負擔。

---

# 27. 預設回覆格式

一般回覆預設使用以下格式：

```text
## 結論

## 原因

## 執行步驟

## 驗證方式

## 注意事項
```

若任務很簡單，可以簡化格式。

若使用者要求直接給檔案、程式碼或設定，應優先提供完整內容。

---

# 28. Git 規則

每次修改應保持範圍清楚。

Commit 應描述：

* 修改目的
* 修改範圍
* 影響模組

避免把無關修改放在同一個 commit。

---

# 29. 禁止事項

禁止：

* 未理解需求就修改
* 未閱讀程式就重構
* 把 Boardroom 寫死成核心
* 把 Model 寫死
* 把 Prompt 寫死
* 把 Workflow 寫死
* 把 Perspective 寫死
* 修改無關程式
* 假裝測試通過
* 隱藏錯誤
* 輸出不完整程式碼
* 使用省略號代替實作
* 過度設計
* 建立暫時用不到的抽象層

---

# 30. AI Collaboration 規則

## 30.1 Codex 適合工作

Codex 優先處理：

* 程式碼修改
* API 實作
* 單元測試
* 重構小範圍模組
* 型別修正
* 錯誤修正
* CLI 操作建議
* Repository 內程式碼理解

---

## 30.2 Claude Code 適合工作

Claude Code 優先處理：

* 大範圍架構理解
* 多檔案重構
* 長上下文整理
* 架構文件產生
* Prompt 設計
* Workflow 設計
* 多 Agent 協作規劃

---

## 30.3 共同規則

不論使用哪個工具，都必須遵守本 AGENTS.md。

若工具特定規範與本文件衝突，以本文件為準。

---

# 31. 本專案最重要的架構提醒

AI Decision Assistant V3 的核心不是很多 Agent。

核心是：

```text
可配置的 Decision System
```

所以任何設計都必須避免寫死。

正確方向：

```text
Template 可配置
Perspective 可配置
Model 可配置
Prompt 可配置
Workflow 可配置
Memory 可配置
Output 可配置
```

錯誤方向：

```text
固定 CEO / CTO / CFO
固定 Claude / GPT
固定 Boardroom 流程
固定 Prompt
固定輸出格式
```

---

# 32. 最終判斷標準

任何新增功能或修改，都必須通過以下問題：

1. 是否符合 AI Decision Assistant V3 的產品定位？
2. 是否避免把 Boardroom 寫死？
3. 是否保持可配置？
4. 是否簡單可維護？
5. 是否只修改必要範圍？
6. 是否有驗證方式？
7. 是否沒有隱藏風險？
8. 是否能直接交給下一個 AI Agent 接手？

若任一答案是否定，應停止並重新設計。
