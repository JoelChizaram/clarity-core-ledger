;; Core Ledger Contract 
;; Personal finance management on the blockchain

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

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
    { limit: uint, period: (string-ascii 16) }
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
        err-unauthorized
    )
)

(define-public (set-budget (category (string-ascii 32)) (limit uint) (period (string-ascii 16)))
    (begin
        (map-set budgets
            { owner: tx-sender, category: category }
            { limit: limit, period: period }
        )
        (ok true)
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