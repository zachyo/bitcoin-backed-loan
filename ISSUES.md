# Issue backlog — Bitcoin-Backed Loan (Stacks)

This file lists 20 prioritized, actionable issues for collaboration on the `bitcoin-backed-loan` project. Each entry includes a short description, suggested labels, priority, estimated effort, and acceptance criteria to make it easy for contributors to pick up work.

---

1) Implement borrow & repay logic
- Description: Add `borrow` and `repay` functions to `contracts/vault.clar` with safe accounting for outstanding debt, interest snapshotting, and event-like returns.
- Labels: feat, contracts, backend
- Priority: P0
- Estimated effort: 5-8 points
- Acceptance criteria: Borrow increases user's debt and decreases available collateral; repay reduces debt; tests cover basic and edge cases; test file `tests/loan.test.ts` added.

2) Interest accrual model anchored to Bitcoin block height
- Description: Implement interest accrual using Bitcoin block height for timekeeping. Add functions to compute and apply accrued interest to loans.
- Labels: feat, math, oracle
- Priority: P0
- Estimated effort: 8-13 points
- Acceptance criteria: Interest is calculated deterministically from block height; tests verify accrual across multiple blocks and rounding behavior.

3) Implement liquidation mechanism and liquidation bonus
- Description: Add liquidation logic that lets third-party liquidators repay undercollateralized loans in exchange for collateral plus a bonus.
- Labels: feat, contracts, security
- Priority: P0
- Estimated effort: 8-13 points
- Acceptance criteria: Liquidation can only occur when LTV > maintenance threshold; collateral moved to liquidator; tests for valid / invalid liquidation scenarios.

4) Integrate a mock price oracle for tests
- Description: Add an oracle mock contract and an integration test harness so price feeds can be simulated in unit tests (e.g., Pyth-like mock).
- Labels: tests, integration, tooling
- Priority: P1
- Estimated effort: 3-5 points
- Acceptance criteria: Tests can set and change price values; loan risk logic uses the mock prices to determine LTV and liquidation eligibility.

5) Support SIP-010 tokens as collateral (multi-token collateral)
- Description: Expand collateral logic to accept SIP-010 fungible tokens, with per-token LTV parameters.
- Labels: enhancement, contracts, token
- Priority: P1
- Estimated effort: 8-13 points
- Acceptance criteria: Deposit, withdraw, and valuation work for any SIP-010 token; tests cover multiple tokens and failure modes.

6) Finish withdraw flow to actually transfer STX/NFTs
- Description: Currently withdraw updates internal accounting but doesn't send STX back. Implement STX transfer or clear specification for custody model.
- Labels: bug, contracts
- Priority: P0
- Estimated effort: 2-4 points
- Acceptance criteria: Withdraw either transfers STX via `stx-transfer?` or clearly documents an off-chain settlement step; tests must assert expected token movement or documented behavior.

7) Add emergency pause / circuit-breaker mechanism
- Description: Owner or multisig should be able to pause protocol actions (borrow, withdraw, liquidate) in emergencies.
- Labels: feat, security
- Priority: P1
- Estimated effort: 3-5 points
- Acceptance criteria: Pause/unpause functions only callable by admin; tests ensure paused state blocks sensitive calls.

8) Add comprehensive unit tests and edge case coverage
- Description: Expand the test suite (unit, property-like scenarios) to cover overflows, rounding, reentrancy, and access-control edge cases.
- Labels: tests, reliability
- Priority: P0
- Estimated effort: 8-13 points
- Acceptance criteria: Tests added under `tests/` with >90% coverage on logic-critical files; failing scenarios are captured and expected.

9) Add property-based tests & invariants for financial safety
- Description: Use fuzzing/property tests to verify invariants (e.g., collateral + repayment cannot shrink below 0; fairness invariants for liquidators).
- Labels: tests, research
- Priority: P2
- Estimated effort: 5-8 points
- Acceptance criteria: At least 5 invariants with property tests included and passing in CI.

10) Add contract verification artifacts using Clarity 4 features
- Description: Use Clarity 4 contract verification and add verification hooks or metadata for automated contract checks.
- Labels: security, clarity4
- Priority: P1
- Estimated effort: 3-5 points
- Acceptance criteria: Add `verify-contract` integration tests and document the verification process in `README.md`.

11) Gas-cost profiling and optimizations
- Description: Measure function costs and optimize expensive operations (maps, loops). Add cost-conscious implementations where needed.
- Labels: perf, optimization
- Priority: P2
- Estimated effort: 3-5 points
- Acceptance criteria: Add benchmarks in tests and reduce hot-path costs; document changes and expected cost improvements.

12) Add GitHub Actions CI for `clarinet check` and `vitest` runs
- Description: Create a GitHub Actions workflow that runs `clarinet check` and `npm test` on PRs and pushes.
- Labels: ci, devops
- Priority: P0
- Estimated effort: 2-4 points
- Acceptance criteria: Workflow in `.github/workflows/ci.yml` runs and reports results on PRs.

13) Add simnet/integration harness and test matrix for epoch variations
- Description: Ensure contract works across Clarity/Stacks epoch versions by running tests in different simulated environments.
- Labels: tests, integration
- Priority: P2
- Estimated effort: 5-8 points
- Acceptance criteria: Tests include runs for target epoch versions, failures flagged in CI.

14) Add a documentation site and developer HOWTOs
- Description: Expand `README.md` with architecture diagrams, contract docs, and a `DEVELOPING.md` for how to run tests locally and contribute.
- Labels: docs
- Priority: P1
- Estimated effort: 3-5 points
- Acceptance criteria: `README.md` and `DEVELOPING.md` updated with clear steps; at least one contributor gets environment working following instructions.

15) Add a liquidation bot reference implementation + simulator
- Description: Implement a small off-chain bot (TypeScript) that scans positions and performs liquidations in a simulated environment.
- Labels: feature, bot, tools
- Priority: P1
- Estimated effort: 8-13 points
- Acceptance criteria: A `scripts/liquidator` folder with bot code and a simulator harness; integration test demonstrates liquidation end-to-end.

16) Design & implement interest rate model (utilization curve)
- Description: Implement a parametrizable interest rate model based on pool utilization (e.g., kinked curves), and add tests.
- Labels: design, feature
- Priority: P1
- Estimated effort: 8-13 points
- Acceptance criteria: Interest recalculations use utilization; parameters are configurable; tests verify expected behavior at different utilizations.

17) Implement collateral valuation (oracle integration) and LTV checks
- Description: Add valuation helpers that consult the oracle and compute LTV with slippage margins.
- Labels: contracts, oracle, risk
- Priority: P0
- Estimated effort: 5-8 points
- Acceptance criteria: LTV logic accurate under mock price changes; tests include edge cases and rounding considerations.

18) Add upgrade / migration strategy and scripts
- Description: Define how to migrate state if the contract needs upgrades (e.g., migration helper contract or data export/import plan).
- Labels: ops, enhancement
- Priority: P2
- Estimated effort: 5-8 points
- Acceptance criteria: Documented migration plan and a test script that migrates mock state to a new contract instance.

19) Security audit checklist and formal verification tasks
- Description: Prepare a checklist for external audits (threat model, test plan, boundary conditions) and investigate formal verification options.
- Labels: security, audit
- Priority: P0
- Estimated effort: 3-5 points
- Acceptance criteria: An `AUDIT.md` checklist and at least one external verification tool (or write-up on feasibility) attached.

20) Add multisig/guarded administration for sensitive ops
- Description: Support multisig or timelocked operations for `transfer-ownership`, `pause`, or critical upgrades to limit single-point-of-failure risk.
- Labels: security, enhancement
- Priority: P1
- Estimated effort: 5-8 points
- Acceptance criteria: Admin operations require multisig or timelock; tests verify admin constraints.

---

How to use this file
- - Create GitHub issues from items above (copy title & description). Add links back to this file for context.
- - Use the Labels and Priority suggestions when creating issues to keep the backlog consistent.
