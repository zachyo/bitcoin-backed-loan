#!/usr/bin/env bash
set -euo pipefail

# Create GitHub issues for items listed in ISSUES.md
# Requires: gh CLI authenticated and repository access

REPO="zachyo/bitcoin-backed-loan"

# Ensure labels exist (create if missing). Using '#000000' color format for compatibility.
labels=(
	feat
	contracts
	backend
	math
	oracle
	security
	tests
	integration
	tooling
	enhancement
	token
	bug
	reliability
	research
	clarity4
	perf
	optimization
	ci
	devops
	docs
	feature
	bot
	tools
	design
	risk
	ops
	audit
)

for lbl in "${labels[@]}"; do
	gh label create "$lbl" --color "#000000" --repo "$REPO" || true
done

# Helper: check whether an issue with this exact title already exists
issue_exists() {
	local title="$1"
	# Search existing issues (open + closed) for exact title match (case-sensitive)
	gh issue list --repo "$REPO" --state all --limit 200 --json title 2>/dev/null \
		| grep -F "\"title\": \"$title\"" >/dev/null 2>&1
}

# Helper: create an issue unless it already exists; log outcome
create_issue() {
	local title="$1" body="$2" labels=(${@:3})
	if issue_exists "$title"; then
		echo "Skipping existing issue: $title"
		return 0
	fi

	echo "Creating issue: $title"
	# Build label flags
	local label_flags=()
	for lbl in "${labels[@]}"; do
		label_flags+=("--label" "$lbl")
	done

	if ! gh issue create --repo "$REPO" --title "$title" --body "$body" "${label_flags[@]}"; then
		echo "Failed to create issue: $title" >&2
		return 1
	fi
	return 0
}

# Use create_issue with title, body, and label list (labels are created above and will be attached if present)

create_issue "Implement borrow & repay logic" 'Add `borrow` and `repay` functions to `contracts/vault.clar` with safe accounting, interest snapshotting, and tests. See `ISSUES.md` for full acceptance criteria.' feat contracts

create_issue "Interest accrual model anchored to Bitcoin block height" 'Implement interest accrual using Bitcoin block height. Add functions to compute and apply accrued interest to loans. See `ISSUES.md`.' feat math oracle

create_issue "Implement liquidation mechanism and bonus" 'Add liquidation logic that lets third-party liquidators repay undercollateralized loans in exchange for collateral plus a bonus.' feat security

create_issue "Integrate mock price oracle for tests" 'Add an oracle mock contract and an integration test harness so price feeds can be simulated in unit tests (e.g., Pyth-like mock).' tests integration

create_issue "Support SIP-010 tokens as collateral" 'Expand collateral logic to accept SIP-010 fungible tokens, with per-token LTV parameters.' enhancement token

create_issue "Finish withdraw flow to actually transfer STX" 'Currently withdraw updates internal accounting but does not transfer STX. Implement transfer or document custody model.' bug contracts

create_issue "Add emergency pause / circuit-breaker mechanism" 'Owner or multisig should be able to pause protocol actions (borrow, withdraw, liquidate) in emergencies. Implement and add tests.' feat security

create_issue "Add comprehensive unit tests and edge case coverage" 'Expand the test suite (unit, property-like scenarios) to cover overflows, rounding, reentrancy, and access-control edge cases.' tests reliability

create_issue "Add property-based tests & invariants for financial safety" 'Use fuzzing/property tests to verify invariants (e.g., collateral + repayment cannot shrink below 0; fairness invariants for liquidators).' tests research

create_issue "Add contract verification artifacts using Clarity 4 features" 'Use Clarity 4 contract verification and add verification hooks or metadata for automated contract checks.' security clarity4

create_issue "Gas-cost profiling and optimizations" 'Measure function costs and optimize expensive operations (maps, loops). Add cost-conscious implementations where needed.' perf optimization

create_issue "Add GitHub Actions CI for `clarinet check` and `vitest` runs" 'Create a GitHub Actions workflow that runs `clarinet check` and `npm test` on PRs and pushes.' ci devops

create_issue "Add simnet/integration harness and test matrix for epoch variations" 'Ensure contract works across Clarity/Stacks epoch versions by running tests in different simulated environments.' tests integration

create_issue "Add a documentation site and developer HOWTOs" 'Expand `README.md` with architecture diagrams, contract docs, and a `DEVELOPING.md` for how to run tests locally and contribute.' docs

create_issue "Add a liquidation bot reference implementation" 'Implement a small off-chain bot (TypeScript) that scans positions and performs liquidations in a simulated environment.' feature bot tools

create_issue "Design & implement interest rate model (utilization curve)" 'Implement a parametrizable interest rate model based on pool utilization (e.g., kinked curves), and add tests.' design feature

create_issue "Implement collateral valuation (oracle integration) and LTV checks" 'Add valuation helpers that consult the oracle and compute LTV with slippage margins.' contracts oracle risk

create_issue "Add upgrade / migration strategy and scripts" 'Define how to migrate state if the contract needs upgrades (e.g., migration helper contract or data export/import plan).' ops enhancement

create_issue "Security audit checklist and formal verification tasks" 'Prepare a checklist for external audits (threat model, test plan, boundary conditions) and investigate formal verification options.' security audit

create_issue "Add multisig/guarded administration for sensitive ops" 'Support multisig or timelocked operations for `transfer-ownership`, `pause`, or critical upgrades to limit single-point-of-failure risk.' security enhancement

echo "All issues created."
