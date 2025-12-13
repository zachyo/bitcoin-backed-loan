import { describe, test, expect, beforeEach } from "vitest";
import { tx } from "@hirosystems/clarinet-sdk";
import { Cl } from "@stacks/transactions";

const CONTRACT_NAME = "vault";

describe("loan & liquidation", () => {
  test("borrow and repay updates debt map", async () => {
    const accounts = simnet.getAccounts();
    const wallet1Address = accounts.get("wallet_1")!;
    const deployerAddress = accounts.get("deployer")!;

    // set STX price for value computations
    simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "set-price", [Cl.stringAscii("STX"), Cl.uint(1)], deployerAddress),
    ]);

    // deposit collateral
    simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "deposit-collateral", [Cl.uint(100)], wallet1Address),
    ]);

    // borrow 40 (allowed at 50% LTV of 100 = 50 max)
    let block = simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "borrow", [Cl.uint(40)], wallet1Address),
    ]);
    expect(block[0].result).toBeOk(Cl.uint(40));

    // repay 20
    block = simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "repay", [Cl.uint(20)], wallet1Address),
    ]);
    expect(block[0].result).toBeOk(Cl.uint(24));
  });

  test("liquidation clears debt when LTV crosses maintenance threshold", async () => {
    const accounts = simnet.getAccounts();
    const wallet1Address = accounts.get("wallet_1")!;
    const deployerAddress = accounts.get("deployer")!;
    const liquidator = accounts.get("wallet_2")!;

    // set STX price initially 10 (higher to allow more borrowing headroom)
    simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "set-price", [Cl.stringAscii("STX"), Cl.uint(10)], deployerAddress),
    ]);

    // deposit collateral
    simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "deposit-collateral", [Cl.uint(100)], wallet1Address),
    ]);

    // borrow 450 (collateral value = 100*10=1000, max at 50% LTV = 500)
    let block = simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "borrow", [Cl.uint(450)], wallet1Address),
    ]);
    expect(block[0].result).toBeOk(Cl.uint(450));

    // Now reduce price to 5 (simulate price drop)
    // New collateral value = 100*5 = 500
    // LTV = 450/500 * 100 = 90% (above maintenance threshold of 75%)
    simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "set-price", [Cl.stringAscii("STX"), Cl.uint(5)], deployerAddress),
    ]);

    // Call liquidate via wallet_2; should succeed as LTV > 75%
    block = simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "liquidate", [Cl.standardPrincipal(wallet1Address)], liquidator),
    ]);

    // Should return ok with a tuple
    expect(block[0].result).toBeOk(Cl.tuple({
      refunded: Cl.uint(475), // 500 - 25 (5% bonus)
      bonus: Cl.uint(25)
    }));
  });

  test("interest accrues across blocks for borrower", async () => {
    const accounts = simnet.getAccounts();
    const wallet1Address = accounts.get("wallet_1")!;
    const deployerAddress = accounts.get("deployer")!;

    // set STX price
    simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "set-price", [Cl.stringAscii("STX"), Cl.uint(1)], deployerAddress),
    ]);

    // deposit and borrow
    simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "deposit-collateral", [Cl.uint(100)], wallet1Address),
    ]);

    // Get initial block height after deposit
    const borrowBlock = simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "borrow", [Cl.uint(10)], wallet1Address),
    ]);
    expect(borrowBlock[0].result).toBeOk(Cl.uint(10));

    // The borrow call happens in block N, setting last-accrual to N
    // We need to advance blocks AFTER the borrow
    simnet.mineBlock([]); // Block N+1
    simnet.mineBlock([]); // Block N+2

    // Now call accrue-for in block N+3, delta = 3 blocks from borrow
    const accrueBlock = simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "accrue-for", [Cl.standardPrincipal(wallet1Address)], deployerAddress),
    ]);

    // Interest calculation: (10 * 1 * 3) / 10 = 3
    // After borrow (block N), we advanced 2 blocks (N+1, N+2), then accrue-for in block N+3
    // Delta from N to N+3 = 3 blocks
    expect(accrueBlock[0].result).toBeOk(Cl.uint(3));

    // debt should have increased to 13
    const call = simnet.callReadOnlyFn(CONTRACT_NAME, "get-debt", [Cl.standardPrincipal(wallet1Address)], wallet1Address);
    expect(call.result).toBeUint(13);
  });

  test("interest rounding behavior over multiple blocks", async () => {
    const accounts = simnet.getAccounts();
    const wallet1Address = accounts.get("wallet_1")!;
    const deployerAddress = accounts.get("deployer")!;

    // set STX price
    simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "set-price", [Cl.stringAscii("STX"), Cl.uint(1)], deployerAddress),
    ]);

    // deposit and borrow 1
    simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "deposit-collateral", [Cl.uint(100)], wallet1Address),
    ]);
    const borrowBlock = simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "borrow", [Cl.uint(1)], wallet1Address),
    ]);
    expect(borrowBlock[0].result).toBeOk(Cl.uint(1));

    // Advance 10 blocks after borrow
    for (let i = 0; i < 10; i++) simnet.mineBlock([]);
    
    // Call accrue-for in block N+11
    // Delta = 11 blocks, interest = (1 * 1 * 11) / 10 = 1 (rounded down)
    const accrueBlock = simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "accrue-for", [Cl.standardPrincipal(wallet1Address)], deployerAddress),
    ]);
    expect(accrueBlock[0].result).toBeOk(Cl.uint(1));

    // Verify debt increased to 2
    const call = simnet.callReadOnlyFn(CONTRACT_NAME, "get-debt", [Cl.standardPrincipal(wallet1Address)], wallet1Address);
    expect(call.result).toBeUint(2);
  });
});