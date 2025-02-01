;; Core Ledger Contract 
;; Personal finance management on the blockchain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-budget-exceeded (err u103))
(define-constant err-invalid-period (err u104))

;; Data structures
(define-map accounts 
    { owner: principal, account-id: uint }
    { name: (string-ascii 64), balance: uint, created-at: uint }
)

(define-map transactions 
    { tx-id: uint }
    { 
        account-id: uint,
        amount: uint,
        category: (string-ascii 32),
        description: (string-ascii 128),
        tx-type: (string-ascii 16),
        timestamp: uint
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

(define-private (check-budget-period (period (string-ascii 16)))
    (or 
        (is-eq period "DAILY")
        (is-eq period "WEEKLY") 
        (is-eq period "MONTHLY")
        (is-eq period "YEARLY")
    )
)

(define-private (get-period-blocks (period (string-ascii 16)))
    (match period
        "DAILY" u144
        "WEEKLY" u1008
        "MONTHLY" u4320
        "YEARLY" u52560
        u0
    )
)

(define-private (should-reset-budget (budget-data {limit: uint, period: (string-ascii 16), used: uint, last-reset: uint, alerts-enabled: bool, alert-threshold: uint}))
    (let
        (
            (period-blocks (get-period-blocks (get period budget-data)))
            (blocks-since-reset (- block-height (get last-reset budget-data)))
        )
        (> blocks-since-reset period-blocks)
    )
)

;; Public functions
(define-public (create-account (name (string-ascii 64)))
    (let
        (
            (new-id (+ (var-get last-account-id) u1))
        )
        (map-set accounts 
            { owner: tx-sender, account-id: new-id }
            { 
                name: name,
                balance: u0,
                created-at: block-height
            }
        )
        (var-set last-account-id new-id)
        (ok new-id)
    )
)

(define-public (record-transaction 
    (account-id uint)
    (amount uint)
    (category (string-ascii 32))
    (description (string-ascii 128))
    (tx-type (string-ascii 16))
)
    (if (is-account-owner account-id)
        (let
            (
                (new-tx-id (+ (var-get last-tx-id) u1))
                (budget-data (map-get? budgets {owner: tx-sender, category: category}))
            )
            (match budget-data
                budget (if (and (is-eq tx-type "EXPENSE") (> (+ amount (get used budget)) (get limit budget)))
                    err-budget-exceeded
                    (begin
                        (if (should-reset-budget budget)
                            (map-set budgets 
                                {owner: tx-sender, category: category}
                                {
                                    limit: (get limit budget),
                                    period: (get period budget),
                                    used: amount,
                                    last-reset: block-height,
                                    alerts-enabled: (get alerts-enabled budget),
                                    alert-threshold: (get alert-threshold budget)
                                }
                            )
                            (map-set budgets
                                {owner: tx-sender, category: category}
                                {
                                    limit: (get limit budget),
                                    period: (get period budget),
                                    used: (+ amount (get used budget)),
                                    last-reset: (get last-reset budget),
                                    alerts-enabled: (get alerts-enabled budget),
                                    alert-threshold: (get alert-threshold budget)
                                }
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
                                timestamp: block-height
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
                            timestamp: block-height
                        }
                    )
                    (var-set last-tx-id new-tx-id)
                    (ok new-tx-id)
                )
            )
        )
        err-unauthorized
    )
)

(define-public (set-budget 
    (category (string-ascii 32)) 
    (limit uint) 
    (period (string-ascii 16))
    (alerts-enabled bool)
    (alert-threshold uint)
)
    (if (check-budget-period period)
        (begin
            (map-set budgets
                { owner: tx-sender, category: category }
                { 
                    limit: limit, 
                    period: period,
                    used: u0,
                    last-reset: block-height,
                    alerts-enabled: alerts-enabled,
                    alert-threshold: alert-threshold
                }
            )
            (ok true)
        )
        err-invalid-period
    )
)

;; Read only functions
(define-read-only (get-account (account-id uint))
    (map-get? accounts { owner: tx-sender, account-id: account-id })
)

(define-read-only (get-transaction (tx-id uint))
    (map-get? transactions { tx-id: tx-id })
)

(define-read-only (get-budget (category (string-ascii 32)))
    (map-get? budgets { owner: tx-sender, category: category })
)

(define-read-only (get-budget-status (category (string-ascii 32)))
    (match (map-get? budgets { owner: tx-sender, category: category })
        budget (ok {
            remaining: (- (get limit budget) (get used budget)),
            used-percentage: (/ (* (get used budget) u100) (get limit budget)),
            needs-reset: (should-reset-budget budget),
            alert-triggered: (and 
                (get alerts-enabled budget)
                (>= (/ (* (get used budget) u100) (get limit budget)) (get alert-threshold budget))
            )
        })
        err-not-found
    )
)
