# Daily Life — AI Decision Policy

## Purpose

This policy defines which decisions AI agents may make autonomously and which decisions require explicit human approval.

## Decision Levels

### Level 0 — Fully Autonomous

No approval required.

Examples:

- bug fixes;
- regression fixes;
- refactoring that preserves approved behavior;
- unit/widget tests;
- analyzer and formatter fixes;
- build and code-generation fixes;
- implementation-level performance improvements;
- loading, empty, and error-state improvements within approved UX requirements;
- dependency maintenance that does not materially change the product or architecture;
- documentation updates reflecting approved behavior;
- Git commits/checkpoints.

### Level 1 — Autonomous With Documentation

AI may proceed, but must record the decision in the development report or relevant documentation.

Examples:

- choosing between equivalent implementation approaches;
- extracting reusable components;
- changing internal folder/file organization;
- adding internal abstractions required by existing architecture;
- resolving technical debt without changing product behavior.

### Level 2 — Human Approval Required

AI must stop before implementing the change.

Examples:

- adding a new user-facing feature not already approved;
- removing or substantially reducing an existing feature;
- changing a product requirement;
- changing the product roadmap or MVP scope;
- materially changing UX behavior or user workflows beyond the approved specification;
- changing core architecture;
- replacing the primary framework, database, state-management approach, or other major technology;
- introducing a paid API/service;
- introducing cloud services that materially change privacy or data handling;
- changing data ownership, retention, synchronization, or privacy behavior;
- destructive or difficult-to-reverse migrations when the intended product behavior is uncertain.

## Approval Request Format

When Level 2 approval is required, stop the affected work and provide:

1. Decision required
2. Why it is required
3. Current requirement
4. Proposed change
5. Product/technical impact
6. Alternatives considered
7. AI recommendation
8. Exact approval options

Do not continue past the decision gate until the human responds.

## Ambiguity Rule

If ambiguity can be resolved from existing documentation without changing product intent, resolve it autonomously and document the interpretation.

If resolving ambiguity would create a new feature, remove a feature, materially alter product behavior, or expand scope, request human approval.

## Safety Rule

Never use autonomy as permission to silently change product scope. When in doubt about product intent, stop and ask.

## Principle

> AI owns implementation decisions inside the approved boundary. The human owns product decisions outside that boundary.
