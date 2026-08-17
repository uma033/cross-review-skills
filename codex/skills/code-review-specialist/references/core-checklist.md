# Core Review Checklist

## Engineering Principles

- Verify reuse-before-build: prefer existing library or project utility when adequate.
- Flag unnecessary abstraction and speculative extensibility (YAGNI).
- Flag harmful duplication in logic, validation, and data access paths (DRY).
- Prefer simple, explicit control flow over layered indirection (KISS).

## Correctness And Regressions

- Verify changed logic for off-by-one, nil/null handling, and empty input behavior.
- Check backward compatibility of function signatures, API payloads, and config fields.
- Validate error handling paths and rollback behavior on partial failures.
- Confirm state transitions remain valid across retries and timeouts.

## Security

- Identify trust boundary crossings and ensure validation/sanitization at boundaries.
- Check authorization and data exposure risks for new endpoints or query paths.
- Confirm secrets/tokens are never logged or hardcoded.
- Review command execution, file I/O, and deserialization changes for abuse vectors.

## Reliability And Operability

- Confirm retry logic has bounded backoff and no infinite loops.
- Ensure failures are observable via logs, metrics, or alerts.
- Verify idempotency for handlers or jobs that may run multiple times.
- Check timeout/circuit-breaker behavior for new network or storage dependencies.

## Performance

- Flag unbounded loops, N+1 data access, and expensive operations in request paths.
- Review memory growth risks from buffering, caching, or large object retention.
- Assess hot-path allocations and lock contention if concurrency changed.

## Data And Migrations

- Validate schema/config changes are backward compatible during rollout.
- Check migration safety, ordering, and rollback path.
- Confirm default values preserve existing behavior.

## Tests

- Confirm tests validate the changed behavior and failure modes.
- Ensure at least one regression test exists for each fixed bug.
- Flag missing coverage for boundary cases and concurrent execution when relevant.
