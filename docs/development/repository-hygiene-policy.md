# Repository Hygiene Policy

Version: 1.0 (Sprint-015)

## 1. Repository Hygiene 原則

這個 workspace 由多個 Sprint 累積產生檔案：程式碼、測試、規範文件、Sprint review artifact、以及執行過程中產生的各種 runtime evidence。隨著 Sprint 數量增加，working tree 很容易同時存在「這個 Sprint 該 commit 的東西」與「跟這個 Sprint 無關、但剛好在 working tree 裡」的東西。

Repository Hygiene 的核心原則：

1. **每一次 commit 只包含 active Sprint 明確核准的檔案**，不因為檔案剛好存在於 working tree 就順手納入。
2. **分類先於決策**：任何檔案在被決定「要不要 commit」之前，必須先被歸類到本文件第 2 節的分類模型之一。
3. **不確定就不 commit**：無法明確歸類、或歸類後不確定是否該 commit 的檔案，一律停在 `Unknown / Product Owner Decision Required`，不得自行判斷納入。
4. **歷史包袱不是本 Sprint 的責任**：不屬於 active Sprint 的歷史檔案，即使長期以 dirty/untracked 狀態存在於 working tree，也不需要、也不應該由當下的 Sprint 順手處理，除非另開一個 dedicated Sprint 明確處理。

本政策與 `docs/development/sprint-scope-isolation-policy.md`、`docs/development/runtime-evidence-exclusion-policy.md`、`docs/development/git-review-checklist.md` 共同運作，四者互不重複定義，互相引用。

## 2. 檔案分類模型

每一個 dirty / untracked 檔案（或目錄）必須歸類到以下 7 類之一。

### 2.1 Source Artifact

**定義**：正式 source code、script、test、runtime configuration（例如 `scripts/*.sh`、`configs/n8n/*.json`、測試檔案）。

**Commit 原則**：只有 active Sprint 明確允許時才可納入 commit。不得因為「順手」而納入未被該 Sprint Architecture 列為 In Scope 的 source artifact 修改。

### 2.2 Development Documentation Artifact

**定義**：正式開發文件、規範文件、policy、specification（例如 `docs/development/*.md`、`AGENTS.md`、`CLAUDE.md`、`CODEX.md`、`GPT.md`、`docs/architecture.md`、`docs/vision.md`、`docs/principles.md`、`docs/roadmap.md`）。

**Commit 原則**：只有本 Sprint 明確新增或修改的 development documentation 才可納入 commit。既存但被其他、非本 Sprint 的原因修改過的文件，不因為它「看起來是文件」就自動視為可 commit。

### 2.3 Sprint Review Artifact

**定義**：active Sprint 的 `architecture.md`、`claude_report.md`、`codex_review.md`、`claude_reply.md`、`codex_final_review.md`、`git_review.md`、retrospective 等 Manual Gate 流程 artifact。

**Commit 原則**：只允許 active Sprint 的正式 artifact 納入 commit。歷史 Sprint（例如已 CLOSED 或與目前 Sprint 無關的 Sprint）的 unrelated artifacts 不可順手納入，即使它們也是「Sprint Review Artifact」這個類別。

### 2.4 Runtime Evidence

**定義**：系統執行、notification delivery、dry-run、live-run、runtime history 所產生的 evidence 或 state（例如 `reviews/notification_history.jsonl`、`reviews/*/round-*/notifications/*.md`）。

**Commit 原則**：預設不納入 source commit（見 `docs/development/runtime-evidence-exclusion-policy.md`）。必要時應以摘要方式寫入正式 report artifact，而不是直接 commit 產生出來的原始 evidence 檔案。

### 2.5 Local State

**定義**：只對本機環境有意義的 cache、log、runtime state、machine-specific file（例如 `__pycache__/`、`*.log`、`.venv/`）。

**Commit 原則**：不得納入 commit。這類檔案理想上應由 `.gitignore` 排除；若尚未被排除，視為 Repository Hygiene 的已知落差，記錄但不在單一 Sprint 中順手修補 `.gitignore`（除非該 Sprint 明確以此為 Scope）。

### 2.6 Historical / Unrelated Artifact

**定義**：存在於 working tree，但不屬於 active Sprint scope 的歷史檔案或未追蹤檔案（例如已結束 Sprint 的目錄、與目前 Sprint 無關的分析文件）。

**Commit 原則**：不得混入 active Sprint commit。若需要處理（commit、刪除、歸檔），必須另開 dedicated Sprint，不可作為目前 Sprint 的附帶工作。

### 2.7 Unknown / Product Owner Decision Required

**定義**：無法依現有規則判定應 commit、ignore、保留或刪除的檔案；或雖然可以歸類到 2.1–2.6，但其存在原因、修改來源、或後續處置方式不明確。

**Commit 原則**：不得在未經 Product Owner 明確核准前納入 commit。Claude Code / Codex 不得自行假設「這應該是可以 commit 的」。

## 3. Commit Candidate 判斷規則

一個檔案要成為某個 Sprint 的 commit candidate，必須同時滿足：

1. 歸類於 2.1 / 2.2 / 2.3 之一（Runtime Evidence、Local State、Historical/Unrelated、Unknown 皆不合格）。
2. 明確屬於 active Sprint 的 Allowed Files（見 `docs/development/sprint-scope-isolation-policy.md`）。
3. 不在 active Sprint 的 Prohibited Files 清單中。
4. 該檔案的修改內容可追溯到本 Sprint 的 Architecture / Implementation 範圍，而不是來自其他 Sprint 或未知來源的既存修改。

## 4. Prohibited Files 判斷規則

一個檔案若符合以下任一條件，即為該 Sprint 的 Prohibited File，不論其分類為何：

1. 屬於 Runtime Evidence（2.4），除非該 Sprint 的 Architecture 明確核准例外。
2. 屬於另一個已 CLOSED 或未被本 Sprint Architecture 列為範圍的 Sprint 的 Sprint Review Artifact。
3. 屬於 n8n workflow JSON 或 Telegram notification runtime 等被明確標示為「本 Sprint 不得修改」的既有系統行為。
4. 該 Sprint 的 Architecture / Handoff Package 明確列為 Prohibited Files。

## 5. Product Owner 額外決策情境

以下情境必須停下、明確請示 Product Owner，不得由 Claude Code 或 Codex 自行決定：

1. 一個檔案的分類本身有爭議（例如同時像是 Development Documentation Artifact，又像是 Historical/Unrelated Artifact）。
2. 一個已追蹤（tracked）檔案顯示為 modified（`M`），但目前 Sprint 的 Implementation 過程中並未修改過它——代表這個修改來自更早、未被記錄清楚的來源。
3. 是否要為長期累積的 Historical / Unrelated Artifact 開一個 dedicated 的清理 Sprint。
4. 是否要更新 `.gitignore` 以排除某一類 Local State 或 Runtime Evidence。
