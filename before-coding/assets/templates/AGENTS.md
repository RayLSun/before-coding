# Project Guidance

## Source of Truth

- Product behavior and confirmed invariants: [`docs/product-contract.md`](docs/product-contract.md)
- Architecture and module boundaries: [`docs/architecture.md`](docs/architecture.md)
- Verification commands and acceptance scenarios: [`docs/verification.md`](docs/verification.md)

## Change Agreements

Before a change, state its goal, scope, behavior that must remain unchanged, acceptance criteria, and regression checks. Keep small fixes concise. Record new features and cross-module changes under `docs/changes/`.

Keep edits scoped to the request. Treat confirmed product behavior as a baseline. Ask the user to decide when intent is ambiguous, a confirmed behavior would change, or a consequential technical trade-off is required. Record ordinary implementation details without creating approval overhead.

After implementation, run checks appropriate to the change, report what was and was not verified, and update the current baseline only after the behavior is accepted.

## Project-Specific Rules

- Status: `TBD`
- Verified setup and test commands: see [`docs/verification.md`](docs/verification.md)
