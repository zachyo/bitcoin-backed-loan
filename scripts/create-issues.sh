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



create_issue "Add simnet/integration harness and test matrix for epoch variations" 'Ensure contract works across Clarity/Stacks epoch versions by running tests in different simulated environments.' tests integration

create_issue "Add a documentation site and developer HOWTOs" 'Expand `README.md` with architecture diagrams, contract docs, and a `DEVELOPING.md` for how to run tests locally and contribute.' docs

create_issue "Add a liquidation bot reference implementation" 'Implement a small off-chain bot (TypeScript) that scans positions and performs liquidations in a simulated environment.' feature bot tools

create_issue "Design & implement interest rate model (utilization curve)" 'Implement a parametrizable interest rate model based on pool utilization (e.g., kinked curves), and add tests.' design feature

create_issue "Implement collateral valuation (oracle integration) and LTV checks" 'Add valuation helpers that consult the oracle and compute LTV with slippage margins.' contracts oracle risk

create_issue "Add upgrade / migration strategy and scripts" 'Define how to migrate state if the contract needs upgrades (e.g., migration helper contract or data export/import plan).' ops enhancement

create_issue "Security audit checklist and formal verification tasks" 'Prepare a checklist for external audits (threat model, test plan, boundary conditions) and investigate formal verification options.' security audit

create_issue "Add multisig/guarded administration for sensitive ops" 'Support multisig or timelocked operations for `transfer-ownership`, `pause`, or critical upgrades to limit single-point-of-failure risk.' security enhancement

echo "All issues created."
