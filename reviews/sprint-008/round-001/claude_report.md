# claude_report.md

Sprint: sprint-008
Round: round-001
Sprint Type: implementation
Story: Story-001 — AI 協作 Prompt 自動產生器（Prompt Generator）MVP

---

## Implementation Summary

依照 `reviews/sprint-008/round-001/architecture.md`（Gate: PASS）實作 Prompt Generator MVP：輸入一段 Product Owner 需求描述文字，輸出固定四區塊 Markdown（ChatGPT Architecture Prompt / Claude Code Implementation Prompt / Codex Review Prompt / Next Step），可直接複製貼給對應 AI 使用。純字串樣板組合，無任何 AI/Runtime 呼叫、無資料庫、無 UI，未修改 Review Bridge。

### 新增檔案

```text
backend/app/engines/prompt_generator/__init__.py
backend/app/engines/prompt_generator/errors.py
backend/app/engines/prompt_generator/generator.py
scripts/generate_prompt.py
tests/engines/prompt_generator/test_generator.py
```

### 修改檔案

```text
reviews/sprint-008/round-001/architecture.md   （由 TEMPLATE ONLY 佔位內容替換為已核准的正式 Architecture 文件內容，內容與 Product Owner 提供版本逐字相同）
```

### Migration

無。本 Sprint 不涉及資料庫，無 Migration。

---

## 設計說明

- **`generator.py: generate_prompt_markdown(requirement: str) -> str`**：核心且唯一的公開函式。將需求文字 strip 後分別代入三個私有樣板函式（`_chatgpt_architecture_prompt`、`_claude_code_implementation_prompt`、`_codex_review_prompt`）與一個固定內容函式（`_next_step`），組成 architecture.md 第 7 節規定的固定四區塊 Markdown。
- 每個樣板函式內容對應 architecture.md 第 8 節列出的必要條件（例如 ChatGPT block 必含 In Scope / Out of Scope / MVP First；Claude block 必含「不修改 Review Bridge」「不要 commit」「claude_report.md」；Codex block 必含「只做 Review」「codex_review.md」）。
- **`errors.py`**：`PromptGeneratorError` 基底類別、`BlankRequirementError` 處理空白需求輸入，沿用既有 `template` engine 的 error 分類慣例。
- 未使用 Pydantic model：需求輸入僅為單一字串（architecture.md 第 6 節明定「最小輸入只需要一段文字」），若為此建立 schema class 屬過度抽象，故以型別提示的純函式取代，符合「簡單優先」原則。
- **`scripts/generate_prompt.py`**：薄 CLI 包裝層，讀取 argv 或 stdin 的需求文字，呼叫 `generate_prompt_markdown` 並印出結果；捕捉 `PromptGeneratorError` 並以非零 exit code 回報錯誤。完全獨立於 `scripts/review_bridge.sh`，未修改該檔案任何內容。
- 目錄結構比照既有 `backend/app/engines/template/` 慣例（`errors.py` / 核心邏輯 / `__init__.py` 匯出公開介面），維持專案一致性。

---

## 使用方式

### 方式一：直接呼叫 Python 函式

```python
from backend.app.engines.prompt_generator.generator import generate_prompt_markdown

markdown = generate_prompt_markdown("我要新增登入功能")
print(markdown)
```

### 方式二：CLI

```bash
# 以參數傳入需求
python scripts/generate_prompt.py "我要新增登入功能"

# 或以 stdin 傳入需求
echo "我要新增登入功能" | python scripts/generate_prompt.py
```

輸出為完整 Markdown，可直接複製貼給 ChatGPT / Claude Code / Codex 使用。

---

## 已完成功能

- [x] 接收一段需求文字（CLI 參數或 stdin）
- [x] 產生 ChatGPT Architecture Prompt（含確認範圍、In/Out Scope、MVP First、不擴大架構、一次一件事）
- [x] 產生 Claude Code Implementation Prompt（含閱讀文件、不擴大範圍、不修改 Review Bridge、不 commit、更新 claude_report.md、回報測試）
- [x] 產生 Codex Review Prompt（含只做 Review、檢查範圍/禁止項目/測試、輸出 codex_review.md、不修改程式碼、不 commit）
- [x] 產生 Next Step（明確指出下一步交給哪個 AI，且一次只做一步）
- [x] 輸出固定 Markdown 格式（四區塊，順序固定）
- [x] 空白需求輸入回傳明確錯誤（`BlankRequirementError` / CLI 非零 exit code）

---

## 未完成功能

無。本 Sprint 範圍內功能（architecture.md 第 4、10 節）已全數完成。

依 architecture.md 第 5 節 Out of Scope，以下項目「刻意不實作」，非遺漏：

- 不自動呼叫 ChatGPT / Claude Code / Codex
- 不新增 AI Runtime / Memory / Learning
- 不新增多 Domain、Template Framework、Discussion Framework
- 不修改 Review Bridge / Consensus Algorithm / 既有 Sprint Workflow
- 不處理 Decision Report MVP

---

## 測試方式

### 自動化測試

```bash
source .venv/bin/activate
python -m pytest tests/engines/prompt_generator/ -v
```

結果：13 個測試全數通過，涵蓋：

- 四區塊順序與標題正確（`test_generate_prompt_markdown_contains_four_sections_in_order`）
- 需求文字正確嵌入前三個 block（`test_generate_prompt_markdown_embeds_requirement_in_first_three_blocks`）
- 前後空白會被 strip（`test_generate_prompt_markdown_strips_surrounding_whitespace`）
- 各 block 內容符合 architecture.md 第 8 節必要條件逐項檢查（In Scope / Out of Scope / MVP First / 不修改 Review Bridge / 不要 commit / claude_report.md / 只做 Review / codex_review.md / 不要同時執行多個角色）
- 空白 / 空字串需求會拋出 `BlankRequirementError`
- CLI：正常輸出、stdin 輸入、空白輸入時 exit code 非零並印出 ERROR 訊息

### 迴歸測試

```bash
python -m pytest tests/ -q
```

結果：42 個測試全數通過（29 個既有 template engine 測試 + 13 個新增 prompt_generator 測試），未造成既有功能迴歸。

註：對整個 repo 執行不帶路徑的 `pytest` 會在 `ace-lite/`、`ai-boardroom/` 子專案觸發既存的 collection error（缺少 `psycopg2` 等套件），此為既有問題，與本次修改無關，未在本 Sprint 範圍內處理。

### 手動驗證

```bash
python scripts/generate_prompt.py "我要新增登入功能"
```

已實際執行並確認輸出符合 architecture.md 第 7 節格式，四區塊順序正確、內容可直接複製使用。

---

## 已知限制

- Prompt 內容為固定樣板字串組合，非 AI 生成；若需求描述本身語意模糊，產生的 Prompt 只會原樣嵌入該文字，不會自動追問或改寫（符合本 Sprint「不自動呼叫 AI」的範圍限制，非缺陷）。
- 未提供 Windows 原生執行方式驗證（僅在 Linux + bash 環境驗證），CLI 為標準 Python script 理論上跨平台可執行。

## 風險

- 無新增外部依賴、無資料庫變更、無 API 變更，變更風險低。
- 未修改 `scripts/review_bridge.sh` 或既有 `backend/app/engines/template/` 任何檔案，不影響既有功能。

---

尚未 commit，等待 Codex Review。
