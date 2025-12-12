import { tx, types } from "@hirosystems/clarinet-sdk";
import { Cl } from "@stacks/transactions";

describe("vault contract", () => {
  test("deposit-collateral increments user balance", async () => {
    const accounts = await simnet.getAccounts();
    const wallet1 = accounts.get("wallet_1")!;

    const block = await simnet.mineBlock([
      tx.contractCall("vault", "deposit-collateral", [types.uint(100)], "wallet_1"),
    ]);

    // should return ok(tuple (depositor ...) (balance 100))
    expect(block.receipts[0].result).toBeOk(Cl.tuple({ depositor: Cl.standardPrincipal(wallet1), balance: Cl.uint(100) }));
  });

  test("withdraw-collateral fails when asset protection enabled", async () => {
    const accounts = await simnet.getAccounts();
    const wallet1 = accounts.get("wallet_1")!;

    await simnet.mineBlock([
      tx.contractCall("vault", "deposit-collateral", [types.uint(50)], "wallet_1"),
    ]);

    await simnet.mineBlock([
      tx.contractCall("vault", "set-asset-protection", [types.ascii("STX"), types.bool(true)], "deployer"),
    ]);

    const block = await simnet.mineBlock([
      tx.contractCall("vault", "withdraw-collateral", [types.uint(10)], "wallet_1"),
    ]);

    expect(block.receipts[0].result).toBeErr();
  });

  test("owner can transfer ownership and non-owner cannot", async () => {
    const accounts = await simnet.getAccounts();
    const wallet1 = accounts.get("wallet_1")!;
    const wallet2 = accounts.get("wallet_2")!;

    let block = await simnet.mineBlock([
      tx.contractCall("vault", "transfer-ownership", [types.principal(wallet1)], "deployer"),
    ]);
    expect(block.receipts[0].result).toBeOk();

    const call = simnet.callReadOnlyFn(new (globalThis as any).CallFnArgs("vault", "is-owner", [types.principal(wallet1)], wallet1));
    expect(call.result).toBeOk(true);

    block = await simnet.mineBlock([
      tx.contractCall("vault", "transfer-ownership", [types.principal(wallet2)], "wallet_2"),
    ]);
    expect(block.receipts[0].result).toBeErr();
  });
});
