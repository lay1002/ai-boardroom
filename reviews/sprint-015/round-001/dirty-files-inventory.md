# Sprint-015 Dirty / Untracked Files Inventory

Captured via `git status --short` at implementation time. This inventory reflects the working tree state at the time Sprint-015 Implementation ran; it is a snapshot, not a live view.

## 1. Method

Every entry below was classified using the 7-category model in `docs/development/repository-hygiene-policy.md` Section 2, then checked against Sprint-015's Allowed Files / Prohibited Files (`reviews/sprint-015/round-001/architecture.md` Sections 3–4) to determine Sprint-015 Commit Eligibility. Directories with many files (`reviews/sprint-006/`, `reviews/sprint-007/`, `reviews/sprint-009/`, `reviews/sprint-013/round-001/notifications/`) are recorded as a single directory-level entry — the reason is noted in each row: they are internally homogeneous (all files in the directory share the same classification and disposition), so a per-file breakdown would not change the Recommendation.

## 2. Inventory

| File Path | Git Status | Classification | Sprint-015 Scope | Recommendation | PO Decision Required | Commit Eligibility |
|---|---|---|---|---|---|---|
| `AGENTS.md` | M | Development Documentation Artifact | Not in scope | Do not commit under Sprint-015 | Yes — modified by an unrecorded prior change, not by this Sprint; root cause and intended disposition unknown | Not eligible |
| `CLAUDE.md` | M | Development Documentation Artifact | Not in scope | Do not commit under Sprint-015 | Yes — same as `AGENTS.md` | Not eligible |
| `CODEX.md` | M | Development Documentation Artifact | Not in scope | Do not commit under Sprint-015 | Yes — same as `AGENTS.md` | Not eligible |
| `GPT.md` | M | Development Documentation Artifact | Not in scope | Do not commit under Sprint-015 | Yes — same as `AGENTS.md` | Not eligible |
| `docs/architecture.md` | M | Development Documentation Artifact | Not in scope | Do not commit under Sprint-015 | Yes — same as `AGENTS.md` | Not eligible |
| `docs/vision.md` | M | Development Documentation Artifact | Not in scope | Do not commit under Sprint-015 | Yes — same as `AGENTS.md` | Not eligible |
| `docs/development/n8n-claude-done-notification.md` | M | Development Documentation Artifact | Not in scope; describes n8n runtime this Sprint must not touch | Do not commit under Sprint-015 | Yes | Not eligible |
| `docs/development/n8n-codex-review-done-notification.md` | M | Development Documentation Artifact | Not in scope; describes n8n runtime this Sprint must not touch | Do not commit under Sprint-015 | Yes | Not eligible |
| `reviews/sprint-004/round-001/architecture.md` | M | Sprint Review Artifact (Sprint-004, historical) | Not in scope | Do not commit under Sprint-015 | Yes — Sprint-004 is not the active Sprint; disposition needs a dedicated Sprint if PO wants to formally reconcile it | Not eligible |
| `reviews/sprint-004/round-001/claude_report.md` | M | Sprint Review Artifact (Sprint-004, historical) | Not in scope | Do not commit under Sprint-015 | Yes — same as above | Not eligible |
| `reviews/sprint-004/round-001/codex_review.md` | M | Sprint Review Artifact (Sprint-004, historical) | Not in scope | Do not commit under Sprint-015 | Yes — same as above | Not eligible |
| `docs/principles.md` | ?? (untracked) | Development Documentation Artifact | Not created by Sprint-015 | Do not commit under Sprint-015 | Yes — origin and intended Sprint unclear | Not eligible |
| `docs/roadmap.md` | ?? (untracked) | Development Documentation Artifact | Not created by Sprint-015 | Do not commit under Sprint-015 | Yes — same as above | Not eligible |
| `reviews/notification-gap-review.md` | ?? (untracked) | Historical / Unrelated Artifact (ad-hoc analysis note) | Not in scope | Do not commit under Sprint-015 | Yes — unclear which Sprint, if any, owns this artifact | Not eligible |
| `reviews/notification_history.jsonl` | ?? (untracked) | Runtime Evidence | Explicitly listed as a Sprint-015 **Prohibited File** | Must not be modified, staged, or committed | No — policy is already explicit (see `docs/development/runtime-evidence-exclusion-policy.md`) | **Not eligible — Prohibited** |
| `reviews/sprint-006/` (7 files: `sprint_meta.env`, `round-001/{architecture,claude_report,claude_reply,codex_review,codex_prompt,codex_final_review}.md`) | ?? (untracked, directory-level entry) | Sprint Review Artifact (Sprint-006, historical/unrelated) | Not in scope | Do not commit under Sprint-015; leave as-is pending a dedicated hygiene Sprint | Yes — whether to commit, archive, or discard Sprint-006 as a whole needs a separate decision | Not eligible |
| `reviews/sprint-007/` (7 files, same shape as sprint-006) | ?? (untracked, directory-level entry) | Sprint Review Artifact (Sprint-007, historical/unrelated) | Not in scope | Do not commit under Sprint-015; leave as-is pending a dedicated hygiene Sprint | Yes — same as sprint-006 | Not eligible |
| `reviews/sprint-009/` (2 files: `round-001/{codex_review,codex_final_review}.md`) | ?? (untracked, directory-level entry) | Sprint Review Artifact (Sprint-009, historical/unrelated, incomplete artifact set) | Not in scope | Do not commit under Sprint-015; leave as-is pending a dedicated hygiene Sprint | Yes — same as sprint-006; also incomplete (missing architecture.md/claude_report.md) which itself may need PO attention | Not eligible |
| `reviews/sprint-013/round-001/notifications/` (2 files: `codex_final_review_done.md`, `codex_review_done.md`) | ?? (untracked, directory-level entry) | Runtime Evidence (Notification Packages generated by Sprint-013 `notify`) | Explicitly listed as a Sprint-015 **Prohibited File** | Must not be modified, staged, or committed | No — policy is already explicit | **Not eligible — Prohibited** |

## 3. Checked but Currently Clean (no dirty/untracked state to record)

The following paths are named in Sprint-015's Prohibited Files list but currently show no dirty or untracked state, so there is nothing to inventory for them; they are listed here so the absence is documented rather than silently omitted:

| Path | Status |
|---|---|
| `configs/n8n/claude-done-notification.workflow.json` | Clean (tracked, no pending changes) |
| `configs/n8n/codex-review-done-notification.workflow.json` | Clean (tracked, no pending changes) |
| `reviews/sprint-014/round-001/notifications/` | Does not exist (no Sprint-014 Gate notification has been generated in the real repository) |

## 4. Note on Already-Closed Sprints Not Appearing in this Inventory

`reviews/sprint-013/round-001/{architecture.md, codex_review.md, codex_final_review.md, claude_must_fix_report.md, git_review.md}` and `reviews/sprint-014/round-001/{architecture.md, claude_report.md, codex_review.md, codex_git_review.md}` are **not** in this inventory because `git status` and `git ls-files` confirm they are already tracked and committed (clean) — Sprint-013 and Sprint-014 have already been committed to the repository (see `git log`: `a2b2070` and `1970140`). They are not dirty/untracked, so Sprint-015's Repository Hygiene scope has nothing to classify for them.

## 5. Summary

- Total dirty/untracked entries recorded: 19 (11 modified-tracked files + 8 untracked file/directory entries).
- Eligible for Sprint-015 commit: **0**. Sprint-015's own Commit Candidate Files are the newly created policy/architecture/report documents listed in `architecture.md` Section 3, not any of the pre-existing dirty/untracked items above.
- Explicitly Prohibited (Runtime Evidence): 2 entries (`reviews/notification_history.jsonl`, `reviews/sprint-013/round-001/notifications/`).
- Requiring Product Owner decision before any future commit: all 17 remaining entries.
