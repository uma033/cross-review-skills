# Coding Principles For Review

Use these as cross-cutting checks in every lane. Report only violations with practical impact.

## Reuse Before Build

- Prefer existing standard library, project utilities, and established dependencies.
- Flag reimplementation of existing functionality without clear benefit.
- Ask whether extension of existing modules is safer than adding parallel implementations.

## YAGNI

- Reject speculative abstractions not required by current scope.
- Flag unused extension points, config knobs, and generic frameworks added "for future use".
- Prefer incremental evolution over preemptive generalization.

## DRY

- Flag duplicated logic, validation rules, and query patterns across files.
- Prefer shared helpers only when they reduce duplication without hiding intent.
- Distinguish healthy duplication (clear locality) from harmful copy-paste drift.

## KISS And Simplicity

- Prefer straightforward control flow over deeply nested condition trees.
- Flag abstraction layers that increase cognitive load without risk reduction.
- Keep interfaces small and explicit for changed behavior.

## Maintainability Guardrails

- Favor cohesive modules with clear responsibilities.
- Flag large multi-purpose functions and classes with mixed concerns.
- Verify naming and structure reveal intent without requiring hidden context.

## Reporting Rules

- Do not treat principles as style-only checks.
- Raise findings only when maintainability, correctness, or operational risk is affected.
- Attach at least one concrete location for each principle violation.

