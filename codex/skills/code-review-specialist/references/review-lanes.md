# Review Lanes

Use these lanes to parallelize review. Keep each lane focused, then merge.

## Lane: Security

- Check trust boundaries, authz/authn, input validation, secret handling.
- Review command execution, deserialization, path/file access risks.
- Flag data exposure in logs, metrics, tracing, and errors.
- Detect anti-patterns from `references/lane-anti-patterns.md` (Security section).

## Lane: Correctness/Logic

- Verify algorithm and state-transition correctness.
- Check edge cases: empty input, nil/null, retries, concurrency effects.
- Confirm error paths are safe and observable.
- Detect anti-patterns from `references/lane-anti-patterns.md` (Correctness/Logic section).

## Lane: Reliability/Operability

- Check resilience patterns: retries, timeouts, idempotency, fallback paths.
- Confirm failures are observable and actionable (logs/metrics/alerts).
- Flag hot-path performance risks that can degrade service behavior.
- Detect anti-patterns from `references/lane-anti-patterns.md` (Reliability/Operability section).

## Lane: Data/Migration/Compatibility

- Check API/schema/config compatibility for rollout and rollback.
- Verify migration ordering, safety, and default-value behavior.
- Flag contract changes that can break callers or downstream consumers.
- Detect anti-patterns from `references/lane-anti-patterns.md` (Data/Migration/Compatibility section).

## Lane: Quality/Tests

- Verify tests cover changed behavior and failure modes.
- Flag missing regression tests, flaky test patterns, weak assertions.
- Check readability/maintainability issues that create future bug risk.
- Detect anti-patterns from `references/lane-anti-patterns.md` (Quality/Tests and Cross-Cutting sections).

## Merge Guidance

- Deduplicate overlapping findings across lanes.
- Keep the clearest location and strongest evidence.
- Prefer severity from impact, not lane type.
- If findings overlap, keep one owner lane for the consolidated item.
- Add a short principles note for YAGNI/DRY/reuse and anti-pattern summary.
