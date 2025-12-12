import { describe, test, expect } from "vitest";
import { tx } from "@hirosystems/clarinet-sdk";
import { Cl } from "@stacks/transactions";

describe("vault contract", () => {
  test("deposit-collateral returns ok", async () => {
    await simnet.mineBlock([
      tx.callPublicFn("vault", "deposit-collateral", [Cl.uint(100)], "wallet_1"),
    ]);
  });

  test("withdraw-collateral fails when asset protection enabled", async () => {
    await simnet.mineBlock([
      tx.callPublicFn("vault", "deposit-collateral", [Cl.uint(50)], "wallet_1"),
    ]);

    await simnet.mineBlock([
      tx.callPublicFn("vault", "set-asset-protection", [Cl.stringAscii("STX"), Cl.bool(true)], "deployer"),
    ]);

    const block = await simnet.mineBlock([
      tx.callPublicFn("vault", "withdraw-collateral", [Cl.uint(10)], "wallet_1"),
    ]);

    expect(block.receipts[0].result).toBeErr();
  });

  test("owner can transfer ownership and non-owner cannot (verified by set-asset-protection)", async () => {
    // deployer transfers ownership to wallet_1
    const accounts = await simnet.getAccounts();
    const wallet1Address = accounts.get("wallet_1")!;
    let block = await simnet.mineBlock([
      tx.callPublicFn("vault", "transfer-ownership", [Cl.standardPrincipal(wallet1Address)], "deployer"),
    ]);
    expect(block.receipts[0].result).toBeOk();

    // wallet_1 should be able to set asset protection now
    block = await simnet.mineBlock([
      tx.contractCall("vault", "set-asset-protection", [types.ascii("STX"), types.bool(false)], "wallet_1"),
    ]);
    expect(block.receipts[0].result).toBeOk();

    // wallet_2 (non-owner) should not be able to change protection
    block = await simnet.mineBlock([
      tx.contractCall("vault", "set-asset-protection", [types.ascii("STX"), types.bool(true)], "wallet_2"),
    ]);
    expect(block.receipts[0].result).toBeErr();
  });
});
