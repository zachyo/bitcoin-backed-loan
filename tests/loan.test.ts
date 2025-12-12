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
    expect(block[0].result).toBeOk(Cl.uint(20));
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
});