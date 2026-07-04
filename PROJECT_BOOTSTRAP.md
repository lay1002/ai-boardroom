# AI Decision Assistant V3

## Development Priority

This workspace follows:

```text
MVP First
Architecture Second
Platform Last
```

Meaning:

1. Build the smallest usable product first.
2. Architecture must support MVP delivery, not delay it.
3. Create Platform or Framework abstractions only after repeated real needs appear.
4. Avoid over-engineering for possible future requirements.
5. Every Sprint must produce a verifiable and deliverable outcome.
6. Prefer usable product functionality over complete architecture.

AI Collaboration Principle:

- AI should improve development speed, not increase process weight.
- Do one most important thing at a time.
- Finish the current Sprint before proposing more architecture.
- Do not create new Sprints only because more architecture could be designed.
- Architecture serves the product; the product does not serve architecture.

Architecture Control Rule:

Suggest a new Framework, Platform, or abstraction only when at least one condition is true:

- Two or more features need the same capability.
- Duplicate implementation already exists.
- The abstraction clearly reduces future maintenance cost.
- It does not delay MVP delivery.

Otherwise, keep the design simple.

Product Owner Priority:

If the Product Owner says: "先完成產品，再優化架構", AI must prioritize product completion and must not expand Architecture scope proactively.

---

Before doing ANYTHING:

Read in order:

1. PROJECT_BOOTSTRAP.md
2. docs/development/development-principles.md
3. docs/development/development-workflow.md
4. docs/development/consensus-workflow.md
5. Current Sprint Architecture

This reading order is defined by `docs/development/development-principles.md` (the AI Workspace Development Constitution) and has higher authority than any older reading order previously listed in this file.

If any file is missing:

STOP

Report missing files.

Do NOT continue.

--------------------------------

After loading:

Output:

Project Knowledge Loaded

--------------------------------

Then wait for Product Owner instructions.

================================

Project Knowledge Loaded

Version

AI Decision Assistant V3

Sprint

Sprint-002

Current Feature

Template Engine MVP

Role

Codex Reviewer

Workflow

Manual Gate

Ready

YES

================================