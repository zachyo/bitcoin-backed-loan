#!/usr/bin/env bash
set -euo pipefail

# Create GitHub issues for items listed in ISSUES.md
# Requires: gh CLI authenticated and repository access

REPO="zachyo/bitcoin-backed-loan"

gh issue create --repo "$REPO" --title "Implement borrow & repay logic" --body 'Add `borrow` and `repay` functions to `contracts/vault.clar` with safe accounting, interest snapshotting, and tests. See `ISSUES.md` for full acceptance criteria.' --label feat --label contracts

gh issue create --repo "$REPO" --title "Interest accrual model anchored to Bitcoin block height" --body 'Implement interest accrual using Bitcoin block height. Add functions to compute and apply accrued interest to loans. See `ISSUES.md`.' --label feat --label math --label oracle

gh issue create --repo "$REPO" --title "Implement liquidation mechanism and bonus" --body 'Add liquidation logic that lets third-party liquidators repay undercollateralized loans in exchange for collateral plus a bonus.' --label feat --label security

gh issue create --repo "$REPO" --title "Integrate mock price oracle for tests" --body 'Add an oracle mock contract and an integration test harness so price feeds can be simulated in unit tests (e.g., Pyth-like mock).' --label tests --label integration

gh issue create --repo "$REPO" --title "Support SIP-010 tokens as collateral" --body 'Expand collateral logic to accept SIP-010 fungible tokens, with per-token LTV parameters.' --label enhancement --label token

gh issue create --repo "$REPO" --title "Finish withdraw flow to actually transfer STX" --body 'Currently withdraw updates internal accounting but does not transfer STX. Implement transfer or document custody model.' --label bug --label contracts

gh issue create --repo "$REPO" --title "Add emergency pause / circuit-breaker mechanism" --body 'Owner or multisig should be able to pause protocol actions (borrow, withdraw, liquidate) in emergencies. Implement and add tests.' --label feat --label security

gh issue create --repo "$REPO" --title "Add comprehensive unit tests and edge case coverage" --body 'Expand the test suite (unit, property-like scenarios) to cover overflows, rounding, reentrancy, and access-control edge cases.' --label tests --label reliability

gh issue create --repo "$REPO" --title "Add property-based tests & invariants for financial safety" --body 'Use fuzzing/property tests to verify invariants (e.g., collateral + repayment cannot shrink below 0; fairness invariants for liquidators).' --label tests --label research

gh issue create --repo "$REPO" --title "Add contract verification artifacts using Clarity 4 features" --body 'Use Clarity 4 contract verification and add verification hooks or metadata for automated contract checks.' --label security --label clarity4

gh issue create --repo "$REPO" --title "Gas-cost profiling and optimizations" --body 'Measure function costs and optimize expensive operations (maps, loops). Add cost-conscious implementations where needed.' --label perf --label optimization

gh issue create --repo "$REPO" --title "Add GitHub Actions CI for `clarinet check` and `vitest` runs" --body 'Create a GitHub Actions workflow that runs `clarinet check` and `npm test` on PRs and pushes.' --label ci --label devops

gh issue create --repo "$REPO" --title "Add simnet/integration harness and test matrix for epoch variations" --body 'Ensure contract works across Clarity/Stacks epoch versions by running tests in different simulated environments.' --label tests --label integration

gh issue create --repo "$REPO" --title "Add a documentation site and developer HOWTOs" --body 'Expand `README.md` with architecture diagrams, contract docs, and a `DEVELOPING.md` for how to run tests locally and contribute.' --label docs

gh issue create --repo "$REPO" --title "Add a liquidation bot reference implementation" --body 'Implement a small off-chain bot (TypeScript) that scans positions and performs liquidations in a simulated environment.' --label feature --label bot --label tools

gh issue create --repo "$REPO" --title "Design & implement interest rate model (utilization curve)" --body 'Implement a parametrizable interest rate model based on pool utilization (e.g., kinked curves), and add tests.' --label design --label feature

gh issue create --repo "$REPO" --title "Implement collateral valuation (oracle integration) and LTV checks" --body 'Add valuation helpers that consult the oracle and compute LTV with slippage margins.' --label contracts --label oracle --label risk

gh issue create --repo "$REPO" --title "Add upgrade / migration strategy and scripts" --body 'Define how to migrate state if the contract needs upgrades (e.g., migration helper contract or data export/import plan).' --label ops --label enhancement

gh issue create --repo "$REPO" --title "Security audit checklist and formal verification tasks" --body 'Prepare a checklist for external audits (threat model, test plan, boundary conditions) and investigate formal verification options.' --label security --label audit

gh issue create --repo "$REPO" --title "Add multisig/guarded administration for sensitive ops" --body 'Support multisig or timelocked operations for `transfer-ownership`, `pause`, or critical upgrades to limit single-point-of-failure risk.' --label security --label enhancement

echo "All issues created."
