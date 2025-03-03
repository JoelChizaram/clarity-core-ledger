# CoreLedger

[Previous content remains unchanged]

## Transaction History
The enhanced transaction history system provides:
- Paginated transaction lists
- Efficient balance history tracking
- Block range validation
- Transaction filtering by account

### Usage
```clarity
;; Get paginated transactions
(get-account-transactions account-id limit offset)

;; Get balance history
(get-account-balance-history account-id from-block to-block)
```

[Rest of README remains unchanged]
