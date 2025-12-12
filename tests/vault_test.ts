import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from 'https://deno.land/x/clarinet@v1.0.5/index.ts';

Clarinet.test({
  name: "deposit-collateral increments user balance",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;

    const block = chain.mineBlock([
      Tx.contractCall("vault", "deposit-collateral", [types.uint(100)], wallet_1.address),
    ]);

    block.receipts.forEach((receipt) => {
      // ensure the tx returned an ok
      receipt.result.expectOk();
    });

    // read the collateral balance
    const call = chain.callReadOnlyFn("vault", "get-collateral", [types.principal(wallet_1.address)], wallet_1.address);
    call.result.expectUint(100);
  },
});

Clarinet.test({
  name: "withdraw-collateral fails when asset protection enabled",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;

    // deposit first
    chain.mineBlock([
      Tx.contractCall("vault", "deposit-collateral", [types.uint(50)], wallet_1.address),
    ]);

    // owner (deployer) enables protection for STX
    chain.mineBlock([
      Tx.contractCall("vault", "set-asset-protection", [types.ascii("STX"), types.bool(true)], deployer.address),
    ]);

    // try to withdraw
    const block = chain.mineBlock([
      Tx.contractCall("vault", "withdraw-collateral", [types.uint(10)], wallet_1.address),
    ]);

    // withdrawal should error
    block.receipts.forEach((receipt) => {
      receipt.result.expectErr();
    });
  },
});
