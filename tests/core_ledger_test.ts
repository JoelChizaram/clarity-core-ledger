// [Previous test content remains unchanged]

Clarinet.test({
    name: "Can retrieve paginated transaction history",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // Create account and transactions
        let block = chain.mineBlock([
            Tx.contractCall('core_ledger', 'create-account', [
                types.ascii("Test Account")
            ], wallet1.address)
        ]);
        
        // Add multiple transactions
        for (let i = 0; i < 5; i++) {
            chain.mineBlock([
                Tx.contractCall('core_ledger', 'record-transaction', [
                    types.uint(1),
                    types.uint(100 * (i + 1)),
                    types.ascii("Test"),
                    types.ascii(`Transaction ${i}`),
                    types.ascii("INCOME")
                ], wallet1.address)
            ]);
        }
        
        // Test pagination
        let result = chain.callReadOnlyFn(
            'core_ledger',
            'get-account-transactions',
            [types.uint(1), types.uint(3), types.uint(0)],
            wallet1.address
        );
        
        result.result.expectOk();
        // Add assertions for transaction list
    }
});

// [Additional tests remain unchanged]
