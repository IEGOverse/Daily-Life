# Resume Prompt

Use this prompt when an AI coding session is interrupted:

> Resume the Daily Life project from the repository state.
>
> 1. Read `docs/AI_CONTEXT.md` first — this is the token-efficient operational snapshot.
> 2. Read `AGENTS.md` for autonomous development rules and approval gates.
> 3. Read `docs/PROGRESS.md` and `docs/ROADMAP.md` only when needed for the current task.
> 4. Read only detailed source-of-truth documents relevant to the current task (PRD, ARCHITECTURE, DATABASE, UI_UX).
> 5. Inspect the actual source code and Git state (`git status`, recent commits, current diff).
> 6. Continue from the latest checkpoint — never repeat completed work unnecessarily.
> 7. Work in small checkpoints. After a meaningful stable increment, format, analyze, test, update `docs/PROGRESS.md`, and create a focused Git commit.
>
> Do not implement future modules or introduce unnecessary dependencies.
>
> At the end, report changes, verification results, `docs/PROGRESS.md` status, remaining issues, and the next task.