import { describe, test, expect, beforeEach } from "vitest";
import { tx } from "@hirosystems/clarinet-sdk";
import { Cl } from "@stacks/transactions";

const CONTRACT_NAME = "vault";

describe("vault contract", () => {
  test("deposit-collateral returns ok", async () => {
    const accounts = simnet.getAccounts();
    const wallet1Address = accounts.get("wallet_1")!;

    const block = simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "deposit-collateral", [Cl.uint(100)], wallet1Address),
    ]);

    expect(block[0].result).toBeOk(Cl.tuple({
      depositor: Cl.standardPrincipal(wallet1Address),
      balance: Cl.uint(100)
    }));
  });

  test("withdraw-collateral fails when asset protection enabled", async () => {
    const accounts = simnet.getAccounts();
    const wallet1Address = accounts.get("wallet_1")!;
    const deployerAddress = accounts.get("deployer")!;

    simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "deposit-collateral", [Cl.uint(50)], wallet1Address),
    ]);

    simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "set-asset-protection", [Cl.stringAscii("STX"), Cl.bool(true)], deployerAddress),
    ]);

    const block = simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "withdraw-collateral", [Cl.uint(10)], wallet1Address),
    ]);

    expect(block[0].result).toBeErr(Cl.uint(200));
  });

  test("owner can transfer ownership and non-owner cannot (verified by set-asset-protection)", async () => {
    const accounts = simnet.getAccounts();
    const wallet1Address = accounts.get("wallet_1")!;
    const deployerAddress = accounts.get("deployer")!;
    const wallet2Address = accounts.get("wallet_2")!;

    // deployer transfers ownership to wallet_1
    let block = simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "transfer-ownership", [Cl.standardPrincipal(wallet1Address)], deployerAddress),
    ]);
    expect(block[0].result).toBeOk(Cl.standardPrincipal(wallet1Address));

    // wallet_1 should be able to set asset protection now
    block = simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "set-asset-protection", [Cl.stringAscii("STX"), Cl.bool(false)], wallet1Address),
    ]);
    expect(block[0].result).toBeOk(Cl.bool(false));

    // wallet_2 (non-owner) should not be able to change protection
    block = simnet.mineBlock([
      tx.callPublicFn(CONTRACT_NAME, "set-asset-protection", [Cl.stringAscii("STX"), Cl.bool(true)], wallet2Address),
    ]);
    expect(block[0].result).toBeErr(Cl.uint(100));
  });
});