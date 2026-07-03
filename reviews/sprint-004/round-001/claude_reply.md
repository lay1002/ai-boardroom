# Claude Reply — Sprint-004 Remaining Must Fix 修正

## 修正摘要

修正 Codex Final Review 中剩餘的 2 項 Must Fix。

## Must Fix 1：validate-final-consensus 必須呼叫 validate_id

**問題**：`cmd_validate_final_consensus` 直接使用 `sprint_id` 組路徑 `$REVIEWS_DIR/$sprint_id`，未呼叫 `validate_id`，仍可被 `../` 等 path traversal 輸入影響。

**修正**：在 `cmd_validate_final_consensus` 中 `parse_dry_run` 之後加入 `validate_id "$sprint_id" "sprint-id"`。現在所有 6 個指令（init、skeleton、check、validate-final-consensus、consensus、finalize）均完整覆蓋 path traversal 驗證。

**驗證**：
- `validate-final-consensus ../etc` → 拒絕（invalid sprint-id）
- `validate-final-consensus "sprint/004"` → 拒絕（invalid sprint-id）
- `validate-final-consensus sprint-004` → 通過

## Must Fix 2：SPRINT_TYPE 白名單驗證

**問題**：`sprint_meta.env` 中的 `SPRINT_TYPE` 讀取後未驗證合法性。非法值（如 `malicious`）會讓 `case` 比對不到 `implementation` 或 `documentation`，導致 required artifact 陣列為空，gate 檢查結果不可靠。

**修正**：在 `cmd_check`、`cmd_consensus`、`cmd_finalize` 的 `load_meta` 之後、使用 `$stype` 之前，加入白名單檢查：
```bash
[[ "$stype" == "implementation" || "$stype" == "documentation" ]] \
  || die "SPRINT_TYPE must be 'implementation' or 'documentation', got: '$stype'"
```

**驗證**：
- `SPRINT_TYPE=malicious` → `check` / `consensus` / `finalize` 全部拒絕
- `SPRINT_TYPE=implementation` → 正常通過
- `SPRINT_TYPE=documentation` → 正常通過

## 驗證結果

- 全流程 E2E 通過（init → skeleton → check → consensus → finalize → validate）
- Path traversal 覆蓋全部 6 個指令
- SPRINT_TYPE 白名單覆蓋 check / consensus / finalize 三處
- 正常 flow 不受影響

## 符合 Architecture

- 僅修改 `scripts/review_bridge.sh`
- 未修改 docs、reviews（除 claude_reply.md）、ace-lite、ai-boardroom
- 未 commit
- 未擴大 scope

Must Fix Addressed: Yes
Architecture Conflict Addressed: Yes
Final Recommendation: PASS
