# Lane Anti-Patterns

Use this catalog to detect representative anti-patterns in each lane. Mark "none found" when clean.

## Security

- Missing validation at trust boundaries.
- SQL/command/path injection primitives built from unsanitized input.
- Secrets in code, logs, or error messages.
- Authorization checks missing on sensitive actions.

## Correctness/Logic

- Flag-driven branching that obscures mutually exclusive states.
- Hidden side effects in helper functions.
- Non-deterministic behavior caused by map iteration, clock dependence, or shared mutable state.
- Error swallowing that allows invalid state progression.

## Reliability/Operability

- Infinite or aggressive retry loops without backoff/jitter.
- Network/storage calls without timeout or cancellation.
- Silent failure paths with weak observability.
- Heavy synchronous work in request path causing latency spikes.

## Data/Migration/Compatibility

- Backward-incompatible schema or API changes without rollout plan.
- Destructive migrations without rollback path.
- Renames/removals without compatibility bridge or feature flag.
- Default value changes that silently alter behavior.

## Quality/Tests

- Copy-paste tests that duplicate setup and hide intent.
- Tests asserting implementation details instead of behavior.
- Missing regression tests for fixed bugs.
- Over-abstracted test helpers that reduce failure diagnosability.

## Cross-Cutting

- Reinventing existing project/library capabilities.
- Premature optimization that increases complexity with no measured bottleneck.
- Generic abstractions added without present requirements (YAGNI violation).

