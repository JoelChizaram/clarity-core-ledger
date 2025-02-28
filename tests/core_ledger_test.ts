[Previous test content with additional tests for new features]

Clarinet.test({
    name: "Transaction updates account balance correctly",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // Create account
        let block = chain.mineBlock([
            Tx.contractCall('core_ledger', 'create-account', [
                types.ascii("Test Account")
            ], wallet1.address)
        ]);
        
        // Record income
        let incomeBlock = chain.mineBlock([
            Tx.contractCall('core_ledger', 'record-transaction', [
                types.uint(1),
                types.uint(1000),
                types.ascii("Salary"),
                types.ascii("Test income"),
                types.ascii("INCOME")
            ], wallet1.address)
        ]);
        
        // Check balance
        let account = chain.callReadOnlyFn(
            'core_ledger',
            'get-account',
            [types.uint(1)],
            wallet1.address
        );
        
        account.result.expectSome().expectTuple()['balance'].expectUint(1000);
        
        // Record expense
        let expenseBlock = chain.mineBlock([
            Tx.contractCall('core_ledger', 'record-transaction', [
                types.uint(1),
                types.uint(300),
                types.ascii("Food"),
                types.ascii("Test expense"),
                types.ascii("EXPENSE")
            ], wallet1.address)
        ]);
        
        // Check updated balance
        account = chain.callReadOnlyFn(
            'core_ledger',
            'get-account',
            [types.uint(1)],
            wallet1.address
        );
        
        account.result.expectSome().expectTuple()['balance'].expectUint(700);
    }
});
