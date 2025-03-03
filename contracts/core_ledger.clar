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
(define-constant err-invalid-range (err u106))
(define-constant err-invalid-limit (err u107))

;; [Previous data structures remain unchanged]

;; Helper functions
(define-private (validate-transaction-type (tx-type (string-ascii 16)))
    (or (is-eq tx-type "INCOME") (is-eq tx-type "EXPENSE"))
)

(define-private (validate-block-range (from-block uint) (to-block uint))
    (and 
        (>= to-block from-block)
        (<= to-block block-height)
    )
)

;; [Previous private functions remain unchanged]

;; Enhanced read-only functions
(define-read-only (get-account-transactions (account-id uint) (limit uint) (offset uint))
    (let
        (
            (tx-list (list ))
            (current-tx-id (var-get last-tx-id))
            (start-tx (if (> current-tx-id offset)
                (- current-tx-id offset)
                u0
            ))
        )
        (if (> limit u50)
            (err err-invalid-limit)
            (ok (filter get-transaction-if-matches 
                (range start-tx (- start-tx limit))))
        )
    )
)

(define-private (get-transaction-if-matches (tx-id uint))
    (match (map-get? transactions {tx-id: tx-id})
        tx-data tx-data
        none
    )
)

(define-read-only (get-account-balance-history (account-id uint) (from-block uint) (to-block uint))
    (if (validate-block-range from-block to-block)
        (let
            (
                (balance-history (list ))
                (transactions (get-transactions-in-range account-id from-block to-block))
            )
            (ok transactions)
        )
        (err err-invalid-range)
    )
)

(define-private (get-transactions-in-range (account-id uint) (from-block uint) (to-block uint))
    (filter is-transaction-in-range 
        (map unwrap-transaction 
            (range from-block to-block)))
)

(define-private (is-transaction-in-range (tx-data (optional {account-id: uint, amount: uint, category: (string-ascii 32), description: (string-ascii 128), tx-type: (string-ascii 16), timestamp: uint, balance-after: uint})))
    (match tx-data
        value (and 
            (is-eq (get account-id value) account-id)
            (>= (get timestamp value) from-block)
            (<= (get timestamp value) to-block)
        )
        false
    )
)

;; [Rest of the contract remains unchanged]
