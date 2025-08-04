;; Alvora Synth Token Contract
;; Clarity v2
;; A robust synthetic asset token logic with minting, burning, collateral backing, and peg controls

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Constants & Errors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-INSUFFICIENT-COLLATERAL u101)
(define-constant ERR-INSUFFICIENT-BALANCE u102)
(define-constant ERR-MINTING-PAUSED u103)
(define-constant ERR-ZERO-ADDRESS u104)
(define-constant ERR-BAD-RATIO u105)
(define-constant ERR-ASSET-NOT-REGISTERED u106)
(define-constant DECIMALS u6)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Admin State
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-data-var admin principal tx-sender)
(define-data-var minting-paused bool false)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Collateral and Synth Asset State
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-map collateral-balances principal uint)
(define-map synth-balances { user: principal, asset: (string-ascii 32) } uint)
(define-map synth-supplies (string-ascii 32) uint)
(define-map asset-collateral-ratios (string-ascii 32) uint) ;; e.g. 150 = 150% overcollateralized

(define-constant DEFAULT-RATIO u150) ;; 150%

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Utilities & Access Control
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

(define-private (assert-minting-enabled)
  (asserts! (not (var-get minting-paused)) (err ERR-MINTING-PAUSED))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Admin Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-public (set-minting-paused (pause bool))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (var-set minting-paused pause)
    (ok pause)
  )
)

(define-public (register-asset (ticker string-ascii 32) (ratio uint))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (asserts! (> ratio u100) (err ERR-BAD-RATIO))
    (map-set asset-collateral-ratios ticker ratio)
    (ok true)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Core Logic
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-public (deposit-collateral (amount uint))
  (begin
    (map-set collateral-balances tx-sender
      (+ amount (default-to u0 (map-get? collateral-balances tx-sender))))
    (ok true)
  )
)

(define-public (withdraw-collateral (amount uint))
  (let ((current (default-to u0 (map-get? collateral-balances tx-sender))))
    (asserts! (>= current amount) (err ERR-INSUFFICIENT-COLLATERAL))
    (map-set collateral-balances tx-sender (- current amount))
    (ok true)
  )
)

(define-public (mint-synth (ticker string-ascii 32) (amount uint))
  (begin
    (assert-minting-enabled)
    (asserts! (is-some (map-get? asset-collateral-ratios ticker)) (err ERR-ASSET-NOT-REGISTERED))
    (let (
      (collateral (default-to u0 (map-get? collateral-balances tx-sender)))
      (ratio (default-to DEFAULT-RATIO (map-get? asset-collateral-ratios ticker)))
      (required-collateral (/ (* amount ratio) u100))
    )
      (asserts! (>= collateral required-collateral) (err ERR-INSUFFICIENT-COLLATERAL))
      (map-set collateral-balances tx-sender (- collateral required-collateral))
      (map-set synth-balances { user: tx-sender, asset: ticker }
        (+ amount (default-to u0 (map-get? synth-balances { user: tx-sender, asset: ticker }))))
      (map-set synth-supplies ticker
        (+ amount (default-to u0 (map-get? synth-supplies ticker))))
      (ok true)
    )
  )
)

(define-public (burn-synth (ticker string-ascii 32) (amount uint))
  (begin
    (asserts! (is-some (map-get? asset-collateral-ratios ticker)) (err ERR-ASSET-NOT-REGISTERED))
    (let ((current (default-to u0 (map-get? synth-balances { user: tx-sender, asset: ticker })))
          (ratio (default-to DEFAULT-RATIO (map-get? asset-collateral-ratios ticker)))
          (refundable (/ (* amount ratio) u100)))
      (asserts! (>= current amount) (err ERR-INSUFFICIENT-BALANCE))
      (map-set synth-balances { user: tx-sender, asset: ticker } (- current amount))
      (map-set synth-supplies ticker
        (- (default-to u0 (map-get? synth-supplies ticker)) amount))
      (map-set collateral-balances tx-sender
        (+ refundable (default-to u0 (map-get? collateral-balances tx-sender))))
      (ok true)
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Read-Only Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-read-only (get-collateral (account principal))
  (ok (default-to u0 (map-get? collateral-balances account)))
)

(define-read-only (get-synth-balance (account principal) (ticker string-ascii 32))
  (ok (default-to u0 (map-get? synth-balances { user: account, asset: ticker })))
)

(define-read-only (get-total-supply (ticker string-ascii 32))
  (ok (default-to u0 (map-get? synth-supplies ticker)))
)

(define-read-only (get-collateral-ratio (ticker string-ascii 32))
  (ok (default-to u0 (map-get? asset-collateral-ratios ticker)))
)

(define-read-only (get-admin)
  (ok (var-get admin))
)

(define-read-only (is-minting-paused)
  (ok (var-get minting-paused))
)