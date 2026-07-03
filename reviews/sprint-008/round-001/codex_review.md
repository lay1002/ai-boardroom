# Codex Review - Sprint-008 Story-001 Prompt Generator MVP

## Summary

Prompt Generator MVP 符合 `reviews/sprint-008/round-001/architecture.md`：輸入一段 Product Owner 需求文字，輸出固定四區塊 Markdown，供 ChatGPT、Claude Code、Codex 與 Product Owner 下一步使用。

實作範圍保持在最小 MVP：純字串樣板、簡單 Python 函式、薄 CLI wrapper、基本錯誤處理與測試。未發現 DB、UI、AI API 呼叫、Runtime、Memory、Learning、Framework 或 Review Bridge 修改。

## Gate Status: PASS

## Must Fix

Must Fix: None

## Should Fix

- Commit scope 需要嚴格隔離。本 workspace 目前存在多個非本 Story 的既有 modified / untracked 檔案，commit 時只應 stage Prompt Generator MVP 相關檔案與 Sprint-008 review artifacts，不應混入其他 Sprint 或 Template Engine 文件。

## Nit

- `generate_prompt_markdown()` 假設輸入為 `str`，符合目前 architecture 的最小輸入定義；若未來 CLI 以外也開放程式化呼叫，可再考慮對非字串輸入給更明確錯誤。
- CLI 使用 `sys.path.insert()` 讓 standalone script 可直接執行，對 MVP 可接受；若未來正式 package 化，再改為模組執行或 entry point。

## Architecture Compliance

PASS

逐項確認：

1. 符合已核准 architecture.md。

`backend/app/engines/prompt_generator/generator.py` 產生固定 Markdown，包含 architecture 第 7 節要求的四個區塊：

- ChatGPT Architecture Prompt
- Claude Code Implementation Prompt
- Codex Review Prompt
- Next Step

2. 只實作 Prompt Generator MVP。

實作只包含：需求文字輸入、固定 prompt bundle 產生、CLI 輸出、空白輸入錯誤處理與測試。沒有擴大為 Prompt Framework、Template Framework 或 AI Runtime。

3. 沒有修改 Review Bridge。

本次檢查範圍未看到 `scripts/review_bridge.sh` 被 Story-001 實作依賴或修改。`scripts/generate_prompt.py` 是獨立 CLI。

4. 沒有新增 DB / UI / AI API 呼叫。

程式碼只使用 Python standard library 與本地函式；沒有 database、frontend/UI、network request、provider SDK 或 AI API call。

5. 沒有新增 Runtime / Memory / Learning / Framework。

`prompt_generator` 是最小 engine-style module，沒有 orchestration runtime、memory write/read、learning loop、provider registry 或多 domain framework。

6. CLI 簡單可用。

`scripts/generate_prompt.py` 支援 argv 與 stdin，成功時輸出 Markdown，空白輸入時回傳非零 exit code 與 `ERROR` 訊息。

7. Markdown 固定區塊完整。

測試與程式碼確認輸出包含四個固定區塊且順序正確。

8. 測試足夠。

測試涵蓋四區塊順序、title、需求嵌入、strip、各角色 prompt 必要內容、Next Step、空白輸入錯誤、CLI argv、CLI stdin、CLI error path。

9. 安全與維護性可接受。

無 shell interpolation、無檔案寫入、無外部呼叫、無 secret handling。主要維護風險是固定字串樣板未來可能變長，但 MVP 階段可接受。

10. 非本 Sprint 範圍變更。

`git status` 顯示 workspace 存在多個非 Story-001 相關變更，例如 development principles、Product Constitution、Sprint-004/006/007 artifacts、Template Engine 相關檔案等。這些不應與 Prompt Generator MVP 一起 commit。

Architecture Conflict: None

## Test Validation

PASS

已執行：

```bash
.venv/bin/pytest tests/engines/prompt_generator -q
```

結果：

```text
13 passed in 0.43s
```

已補跑 workspace `tests/` 範圍：

```bash
.venv/bin/pytest tests/ -q
```

結果：

```text
42 passed in 0.83s
```

`__pycache__/` 由 `.gitignore` 忽略，顯示為 ignored，不應進 commit。

## Security / Maintainability Review

PASS

Security:

- 無 AI API 呼叫。
- 無 network request。
- 無 database access。
- 無 subprocess shell execution in production code。
- CLI 僅讀 argv/stdin 並輸出 stdout。
- 空白輸入有明確錯誤處理。

Maintainability:

- 核心公開 API 單一：`generate_prompt_markdown(requirement: str) -> str`。
- 錯誤類型獨立於 `errors.py`。
- CLI wrapper 薄且容易測試。
- 測試直接對應 architecture 必要條件。

Residual risk:

- Prompt wording 是硬編碼樣板。這符合 MVP，但若未來 prompt variants 增加，再考慮配置化；目前不應提前抽象。

## Final Recommendation

Final Recommendation: PASS
