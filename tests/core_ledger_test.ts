import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create new account",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('core_ledger', 'create-account', [
                types.ascii("My Savings")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        let account = chain.callReadOnlyFn(
            'core_ledger',
            'get-account',
            [types.uint(1)],
            wallet1.address
        );
        
        account.result.expectSome().expectTuple()['name'].expectAscii("My Savings");
    }
});

Clarinet.test({
    name: "Can record transaction",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // First create an account
        let block = chain.mineBlock([
            Tx.contractCall('core_ledger', 'create-account', [
                types.ascii("My Account")
            ], wallet1.address)
        ]);
        
        // Then record a transaction
        let txBlock = chain.mineBlock([
            Tx.contractCall('core_ledger', 'record-transaction', [
                types.uint(1),
                types.uint(100000),
                types.ascii("Salary"),
                types.ascii("Monthly salary"),
                types.ascii("INCOME")
            ], wallet1.address)
        ]);
        
        txBlock.receipts[0].result.expectOk().expectUint(1);
        
        let transaction = chain.callReadOnlyFn(
            'core_ledger',
            'get-transaction',
            [types.uint(1)],
            wallet1.address
        );
        
        let txData = transaction.result.expectSome().expectTuple();
        assertEquals(txData['amount'].expectUint(100000), types.uint(100000));
        assertEquals(txData['category'].expectAscii("Salary"), "Salary");
    }
});

Clarinet.test({
    name: "Can set and get budget",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('core_ledger', 'set-budget', [
                types.ascii("Groceries"),
                types.uint(50000),
                types.ascii("MONTHLY")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        let budget = chain.callReadOnlyFn(
            'core_ledger',
            'get-budget',
            [types.ascii("Groceries")],
            wallet1.address
        );
        
        let budgetData = budget.result.expectSome().expectTuple();
        assertEquals(budgetData['limit'].expectUint(50000), types.uint(50000));
        assertEquals(budgetData['period'].expectAscii("MONTHLY"), "MONTHLY");
    }
});