# Bitcoin-Backed Loan Platform (Stacks)

## Overview

This project is a decentralized lending protocol built on the **Stacks** blockchain using **Clarity** smart contracts. It allows users to lock **STX** (or other SIP-010 tokens) as collateral to borrow stablecoins or other assets.

The protocol leverages Stacks' unique connection to Bitcoin, utilizing **Bitcoin block height** for time-based logic (such as interest accrual and loan duration) and potentially integrating with Bitcoin state for advanced liquidation mechanisms.

## Core Features

### 1. Collateralized Lending

- Users can deposit STX as collateral.
- Users can borrow assets against their collateral up to a specific Loan-to-Value (LTV) ratio.

### 2. Bitcoin-Native Time Logic

- Interest rates and loan durations are calculated based on **Bitcoin block height**, ensuring a secure and predictable timeline anchored to the most secure blockchain.

### 3. Liquidation Mechanism

- If the value of the collateral drops below a maintenance threshold, the position becomes eligible for liquidation.
- Liquidators can repay a portion of the debt in exchange for the collateral (plus a liquidation bonus).

### 4. Oracle Integration (Planned)

- Integration with trusted price feeds (e.g., Pyth or RedStone on Stacks) to ensure accurate asset pricing for collateral and borrowed assets.

## Tech Stack

- **Blockchain:** Stacks (Layer 2 for Bitcoin)
- **Smart Contract Language:** Clarity
- **Token Standard:** SIP-010 (Fungible Tokens)
- **Development Framework:** Clarinet

## Project Structure

- `contracts/`: Contains the Clarity smart contracts.
- `tests/`: TypeScript/JavaScript tests for the contracts.
- `Clarinet.toml`: Configuration file for the Clarinet environment.

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet): The Stacks smart contract development tool.
- Node.js & NPM (for running tests).

### Installation

1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd bitcoin-backed-loan
   ```
2. Initialize the project (if starting fresh):
   ```bash
   clarinet new .
   ```

### Running Tests

```bash
clarinet test
```

## Roadmap

- [ ] Implement basic Vault contract (Deposit/Withdraw).
- [ ] Implement Loan logic (Borrow/Repay).
- [ ] Add Interest Rate model based on utilization.
- [ ] Integrate Price Oracle mock for testing.
- [ ] Build Liquidation bot logic.
