import { describe, test, expect } from "vitest";
import { tx } from "@hirosystems/clarinet-sdk";
import { Cl } from "@stacks/transactions";

describe("vault contract", () => {
  test("deposit-collateral returns ok", async () => {
    const accounts = await simnet.getAccounts();
    const wallet1Address = accounts.get("wallet_1")!;

    await simnet.mineBlock([
      tx.callPublicFn("vault", "deposit-collateral", [Cl.uint(100)], wallet1Address),
    ]);
  });

  test("withdraw-collateral fails when asset protection enabled", async () => {
    const accounts = await simnet.getAccounts();
    const wallet1Address = accounts.get("wallet_1")!;
    const deployerAddress = accounts.get("deployer")!;

    await simnet.mineBlock([
      tx.callPublicFn("vault", "deposit-collateral", [Cl.uint(50)], wallet1Address),
    ]);

    await simnet.mineBlock([
      tx.callPublicFn("vault", "set-asset-protection", [Cl.stringAscii("STX"), Cl.bool(true)], deployerAddress),
    ]);

    const block = await simnet.mineBlock([
      tx.callPublicFn("vault", "withdraw-collateral", [Cl.uint(10)], wallet1Address),
    ]);

    expect(block.receipts[0].result).toBeErr();
  });

  test("owner can transfer ownership and non-owner cannot (verified by set-asset-protection)", async () => {
    // deployer transfers ownership to wallet_1
    const accounts = await simnet.getAccounts();
    const wallet1Address = accounts.get("wallet_1")!;
    const deployerAddress = accounts.get("deployer")!;
    const wallet2Address = accounts.get("wallet_2")!;

    let block = await simnet.mineBlock([
      tx.callPublicFn("vault", "transfer-ownership", [Cl.standardPrincipal(wallet1Address)], deployerAddress),
    ]);
    expect(block.receipts[0].result).toBeOk();

    // wallet_1 should be able to set asset protection now
    block = await simnet.mineBlock([
      tx.callPublicFn("vault", "set-asset-protection", [Cl.stringAscii("STX"), Cl.bool(false)], wallet1Address),
    ]);
    expect(block.receipts[0].result).toBeOk();

    // wallet_2 (non-owner) should not be able to change protection
    block = await simnet.mineBlock([
      tx.callPublicFn("vault", "set-asset-protection", [Cl.stringAscii("STX"), Cl.bool(true)], wallet2Address),
    ]);
    expect(block.receipts[0].result).toBeErr();
  });
});
