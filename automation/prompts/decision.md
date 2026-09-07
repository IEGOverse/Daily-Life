# Decision Escalation Prompt Template

## Purpose

This prompt template is used by the orchestrator when it needs to escalate a decision to a human. It provides the context and specific information needed for the human to make an informed decision.

## Template

```
## HUMAN DECISION REQUIRED

The automated orchestrator has encountered a situation that requires human judgment.

### Task Context
- **Phase**: {{CURRENT_PHASE}}
- **Sprint**: {{CURRENT_SPRINT}}
- **Task**: {{CURRENT_TASK}}
- **Retry Count**: {{RETRY_COUNT}} of 3

### Issue Description
{{ISSUE_DESCRIPTION}}

### What Has Been Tried
1. Attempt 1: {{ATTEMPT_1}}
2. Attempt 2: {{ATTEMPT_2}}
3. Attempt 3: {{ATTEMPT_3}}

### Validation Results
- Format: {{FORMAT_RESULT}}
- Analyze: {{ANALYZE_RESULT}}
- Test: {{TEST_RESULT}}
- Build: {{BUILD_RESULT}}
- Review: {{REVIEW_RESULT}}

### Possible Actions
{{POSSIBLE_ACTIONS}}

### Recommendation
{{RECOMMENDATION}}

### Required Decision
What would you like to do?
1. Approve the current implementation as-is
2. Request a different approach
3. Update the roadmap/architecture
4. Defer this task
5. Stop the orchestrator

Please respond with your decision.
```

## Escalation Triggers

The orchestrator uses this template when:

1. **Validation Exhaustion**: All 3 retry attempts for validation have failed.
2. **Review Exhaustion**: All 3 retry attempts for review have failed.
3. **Architectural Change**: A task requires changes to the architecture not in existing docs.
4. **SDK/Tool Issue**: The Flutter/Dart SDK or OpenCode has compatibility issues.
5. **Roadmap Change**: A task's scope needs to be changed.
6. **Critical Blocker**: An issue cannot be resolved by the orchestrator.

## Human Decision Required Examples

- "Validation fails after 3 attempts: `colorSchemeSeed` and `colorScheme` conflict in ThemeData."
- "OpenCode is unavailable and no alternative invocation method exists."
- "A new feature is needed that is not in the approved roadmap."
- "The database schema needs fundamental changes to existing tables."

## Constraints

- The prompt does not include any hard-coded secrets.
- The prompt does not include any API keys.
- The prompt does not invent any AI providers.
- The prompt clearly states the required human action.
- The prompt provides all context needed for an informed decision.

## After Human Decision

After receiving a human response:
1. Update `automation/state/checkpoint.json` with the decision.
2. Update `docs/PROGRESS.md` with the decision.
3. If approved, continue to the next task.
4. If deferred, update the roadmap and continue.
5. If stopped, generate an incident report and stop.
