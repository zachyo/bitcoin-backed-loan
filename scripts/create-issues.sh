#!/usr/bin/env bash
set -euo pipefail

# Create GitHub issues for items listed in ISSUES.md
# Requires: gh CLI authenticated and repository access

REPO="zachyo/bitcoin-backed-loan"

gh issue create --repo "$REPO" --title "Implement borrow & repay logic" --body "Add `borrow` and `repay` functions to `contracts/vault.clar` with safe accounting, interest snapshotting, and tests. See `ISSUES.md` for full acceptance criteria." --label "feat,contracts" 

gh issue create --repo "$REPO" --title "Interest accrual model anchored to Bitcoin block height" --body "Implement interest accrual using Bitcoin block height. Add functions to compute and apply accrued interest to loans. See `ISSUES.md`." --label "feat,math,oracle"

gh issue create --repo "$REPO" --title "Implement liquidation mechanism and bonus" --body "Add liquidation logic allowing third-party liquidators to repay undercollateralized loans for collateral + liquidation bonus. Tests required." --label "feat,security"

gh issue create --repo "$REPO" --title "Integrate mock price oracle for tests" --body "Add an oracle mock contract and integration test harness so price feeds can be simulated in unit tests (Pyth-like mock)." --label "tests,integration"

gh issue create --repo "$REPO" --title "Support SIP-010 tokens as collateral" --body "Expand collateral logic to accept SIP-010 fungible tokens, with per-token LTV parameters and tests." --label "enhancement,token"

gh issue create --repo "$REPO" --title "Finish withdraw flow to actually transfer STX" --body "Currently withdraw updates accounting but doesn't transfer STX. Implement transfer or document custody model." --label "bug,contracts"

gh issue create --repo "$REPO" --title "Add emergency pause / circuit-breaker mechanism" --body "Owner or multisig should be able to pause protocol actions in emergencies. Implement and add tests." --label "feat,security"

gh issue create --repo "$REPO" --title "Add comprehensive unit tests and edge case coverage" --body "Expand test coverage for overflows, rounding, reentrancy, and access-control edge cases; aim for high test coverage." --label "tests,reliability"

gh issue create --repo "$REPO" --title "Add property-based tests & invariants" --body "Create property/fuzz tests to verify invariants such as non-negative balances and liquidation safety." --label "tests,research"

gh issue create --repo "$REPO" --title "Add contract verification artifacts using Clarity 4" --body "Use Clarity 4 contract verification features and add integration/verification tests. Document verification in README." --label "security,clarity4"

gh issue create --repo "$REPO" --title "Gas-cost profiling and optimizations" --body "Measure and optimize gas-cost for hot paths; add benchmarks and document cost improvements." --label "perf,optimization"

gh issue create --repo "$REPO" --title "Add GitHub Actions CI for clarinet check and vitest" --body "Create a CI workflow that runs `clarinet check` and `npm test` on PRs and pushes." --label "ci,devops"

gh issue create --repo "$REPO" --title "Add simnet/integration harness and test matrix" --body "Ensure contract behaviour across Clarity/Stacks epoch versions by running tests in different simulated environments." --label "tests,integration"

gh issue create --repo "$REPO" --title "Add documentation site and developer HOWTOs" --body "Expand `README.md` and add `DEVELOPING.md` with architecture diagrams and contributor setup instructions." --label "docs"

gh issue create --repo "$REPO" --title "Add a liquidation bot reference implementation" --body "Implement a simple off-chain bot (TypeScript) that scans positions and performs liquidations in a simulated environment." --label "feature,bot,tools"

gh issue create --repo "$REPO" --title "Design & implement interest rate model (utilization curve)" --body "Implement a parametrizable interest rate model based on pool utilization (kinked curve) and add tests." --label "design,feature"

gh issue create --repo "$REPO" --title "Implement collateral valuation & LTV checks" --body "Add valuation helpers that consult the oracle and compute LTV with slippage margins; tests required." --label "contracts,oracle,risk"

gh issue create --repo "$REPO" --title "Add upgrade/migration strategy and scripts" --body "Document migration plan and add scripts to migrate state to a new contract instance." --label "ops,enhancement"

gh issue create --repo "$REPO" --title "Security audit checklist and formal verification tasks" --body "Prepare an `AUDIT.md` checklist for external audits and evaluate formal verification options." --label "security,audit"

gh issue create --repo "$REPO" --title "Add multisig/guarded administration" --body "Support multisig/timelock for sensitive operations (transfer-ownership, pause) and add tests." --label "security,enhancement"

echo "All issues created."
