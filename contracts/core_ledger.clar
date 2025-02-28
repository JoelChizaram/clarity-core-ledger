;; Core Ledger Contract 
;; Personal finance management on the blockchain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-budget-exceeded (err u103))
(define-constant err-invalid-period (err u104))
(define-constant err-invalid-amount (err u105))

;; Data structures
(define-map accounts 
    { owner: principal, account-id: uint }
    { 
        name: (string-ascii 64), 
        balance: uint, 
        created-at: uint,
        last-updated: uint
    }
)

(define-map transactions 
    { tx-id: uint }
    { 
        account-id: uint,
        amount: uint,
        category: (string-ascii 32),
        description: (string-ascii 128),
        tx-type: (string-ascii 16),
        timestamp: uint,
        balance-after: uint
    }
)

(define-map budgets
    { owner: principal, category: (string-ascii 32) }
    { 
        limit: uint, 
        period: (string-ascii 16),
        used: uint,
        last-reset: uint,
        alerts-enabled: bool,
        alert-threshold: uint
    }
)

;; Data variables
(define-data-var last-account-id uint u0)
(define-data-var last-tx-id uint u0)

;; Private functions
(define-private (is-owner)
    (is-eq tx-sender contract-owner)
)

(define-private (is-account-owner (account-id uint))
    (match (map-get? accounts { owner: tx-sender, account-id: account-id })
        account true
        false
    )
)

(define-private (update-account-balance (account-id uint) (amount uint) (tx-type (string-ascii 16)))
    (match (map-get? accounts { owner: tx-sender, account-id: account-id })
        account 
        (let
            (
                (new-balance (if (is-eq tx-type "EXPENSE")
                    (- (get balance account) amount)
                    (+ (get balance account) amount)
                ))
            )
            (map-set accounts
                { owner: tx-sender, account-id: account-id }
                {
                    name: (get name account),
                    balance: new-balance,
                    created-at: (get created-at account),
                    last-updated: block-height
                }
            )
            (ok new-balance)
        )
        err-not-found
    )
)

(define-private (reset-budget (budget-data {limit: uint, period: (string-ascii 16), used: uint, last-reset: uint, alerts-enabled: bool, alert-threshold: uint}) (amount uint))
    {
        limit: (get limit budget-data),
        period: (get period budget-data),
        used: amount,
        last-reset: block-height,
        alerts-enabled: (get alerts-enabled budget-data),
        alert-threshold: (get alert-threshold budget-data)
    }
)

;; [Previous functions remain unchanged]

(define-public (record-transaction 
    (account-id uint)
    (amount uint)
    (category (string-ascii 32))
    (description (string-ascii 128))
    (tx-type (string-ascii 16))
)
    (if (and (is-account-owner account-id) (> amount u0))
        (let
            (
                (new-tx-id (+ (var-get last-tx-id) u1))
                (budget-data (map-get? budgets {owner: tx-sender, category: category}))
                (balance-update-result (update-account-balance account-id amount tx-type))
            )
            (match balance-update-result
                new-balance
                (match budget-data
                    budget 
                    (if (and (is-eq tx-type "EXPENSE") (> (+ amount (get used budget)) (get limit budget)))
                        err-budget-exceeded
                        (begin
                            (map-set budgets 
                                {owner: tx-sender, category: category}
                                (if (should-reset-budget budget)
                                    (reset-budget budget amount)
                                    (merge budget { used: (+ amount (get used budget)) })
                                )
                            )
                            (map-set transactions
                                { tx-id: new-tx-id }
                                {
                                    account-id: account-id,
                                    amount: amount,
                                    category: category,
                                    description: description,
                                    tx-type: tx-type,
                                    timestamp: block-height,
                                    balance-after: new-balance
                                }
                            )
                            (var-set last-tx-id new-tx-id)
                            (ok new-tx-id)
                        )
                    )
                    (begin
                        (map-set transactions
                            { tx-id: new-tx-id }
                            {
                                account-id: account-id,
                                amount: amount,
                                category: category,
                                description: description,
                                tx-type: tx-type,
                                timestamp: block-height,
                                balance-after: new-balance
                            }
                        )
                        (var-set last-tx-id new-tx-id)
                        (ok new-tx-id)
                    )
                )
                err-not-found
            )
        )
        err-unauthorized
    )
)

;; New read-only functions
(define-read-only (get-account-transactions (account-id uint) (limit uint))
    (let
        (
            (tx-list (list ))
            (current-tx-id (var-get last-tx-id))
        )
        (ok tx-list) ;; TODO: Implement transaction list building
    )
)

(define-read-only (get-account-balance-history (account-id uint) (from-block uint) (to-block uint))
    (let
        (
            (balance-history (list ))
        )
        (ok balance-history) ;; TODO: Implement balance history tracking
    )
)

;; [Previous read-only functions remain unchanged]
