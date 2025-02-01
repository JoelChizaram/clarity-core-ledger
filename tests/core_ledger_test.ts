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
    name: "Can set and get budget with alerts",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('core_ledger', 'set-budget', [
                types.ascii("Groceries"),
                types.uint(50000),
                types.ascii("MONTHLY"),
                types.bool(true),
                types.uint(80)
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
        assertEquals(budgetData['alerts-enabled'].expectBool(true), true);
        assertEquals(budgetData['alert-threshold'].expectUint(80), types.uint(80));
    }
});

Clarinet.test({
    name: "Budget enforcement and alerts work correctly",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // Create account and budget
        let setupBlock = chain.mineBlock([
            Tx.contractCall('core_ledger', 'create-account', [
                types.ascii("Test Account")
            ], wallet1.address),
            Tx.contractCall('core_ledger', 'set-budget', [
                types.ascii("Food"),
                types.uint(1000),
                types.ascii("MONTHLY"),
                types.bool(true),
                types.uint(80)
            ], wallet1.address)
        ]);
        
        // Record transaction that exceeds budget
        let txBlock = chain.mineBlock([
            Tx.contractCall('core_ledger', 'record-transaction', [
                types.uint(1),
                types.uint(1100),
                types.ascii("Food"),
                types.ascii("Groceries"),
                types.ascii("EXPENSE")
            ], wallet1.address)
        ]);
        
        txBlock.receipts[0].result.expectErr().expectUint(103); // err-budget-exceeded
        
        // Check budget status
        let status = chain.callReadOnlyFn(
            'core_ledger',
            'get-budget-status',
            [types.ascii("Food")],
            wallet1.address
        );
        
        let statusData = status.result.expectOk().expectTuple();
        assertEquals(statusData['remaining'].expectUint(1000), types.uint(1000));
        assertEquals(statusData['used-percentage'].expectUint(0), types.uint(0));
        assertEquals(statusData['alert-triggered'].expectBool(false), false);
    }
});
