# Git Workflow — Daily Life

## Purpose
Git is the second recovery layer after project documentation. Every stable increment should be recoverable.

## Basic Cycle
1. Read documentation and PROGRESS.md.
2. Inspect repository state.
3. Implement one small task.
4. Format.
5. Analyze.
6. Test.
7. Review the diff.
8. Update PROGRESS.md.
9. Commit the stable increment.

## Before Starting
Use:
- `git status`
- `git log --oneline -10`
- inspect relevant files

Never discard unrelated user changes.

## Commit Guidelines
Keep commits small and logically focused.

Examples:
- `chore: initialize flutter foundation`
- `feat: add schedule model`
- `feat: add schedule repository`
- `test: add schedule repository tests`
- `fix: handle empty schedule state`

Avoid:
- `update everything`
- `final app`
- `ai changes`
- commits containing multiple unrelated features

## If Work Is Interrupted
Do not reset or redo work automatically.

Inspect:
- `docs/PROGRESS.md`
- `git status`
- `git diff`
- latest commits

Then continue from the incomplete task.

## Safe Checkpoint
A stable checkpoint should have:
- formatted code;
- no known analyzer errors;
- relevant tests passing;
- PROGRESS.md updated;
- a focused Git commit.

## Recovery Philosophy
The chat session is temporary.
The repository, documentation, tests, and Git history are persistent.
