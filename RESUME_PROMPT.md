# Resume Prompt

Use this prompt when an AI coding session is interrupted:

> Resume the Daily Life project from the repository state.
>
> First read AGENTS.md and docs/PROGRESS.md. Then inspect `git status`, the latest Git commits, the current diff, and the relevant source files.
>
> Determine exactly what has already been completed and what remains. Do not redo completed work.
>
> Continue from the first incomplete item in docs/PROGRESS.md. Stay within the current sprint scope.
>
> If the repository and PROGRESS.md disagree, inspect the code and update PROGRESS.md to reflect reality before continuing.
>
> Work in small checkpoints. After a meaningful stable increment, format, analyze, test, update PROGRESS.md, and create a focused Git commit.
>
> Do not implement future modules or introduce unnecessary dependencies.
>
> At the end, report changes, verification results, PROGRESS.md status, remaining issues, and the next task.
