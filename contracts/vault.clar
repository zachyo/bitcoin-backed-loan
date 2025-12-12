;; Bitcoin-Backed Loan: Vault contract (initial skeleton)
;; Written to be compatible with Clarity; includes asset protection & verification hooks

(define-constant ERR-NOT-OWNER u100)
(define-constant ERR-ZERO-INPUT u101)
(define-constant ERR-INSUFFICIENT u102)
(define-constant ERR-PROTECTED u200)

;; Owner is set at deployment
(define-data-var owner principal tx-sender)

;; Map of collateral balances by user
(define-map collateral principal uint)

;; Asset protection flags: string-ascii -> bool (true = protected, cannot withdraw)
(define-map asset-protection (string-ascii 32) bool)

;; --- Initialization / Verification ---
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err ERR-NOT-OWNER))
    (ok true)))

;; Read-only helper to verify the caller is owner
(define-read-only (is-owner (p principal))
  (is-eq p (var-get owner)))

;; Allow the owner to transfer ownership to a new principal
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err ERR-NOT-OWNER))
    (var-set owner new-owner)
    (ok new-owner)))

;; Verification hook - placeholder for Clarity 4 contract verification features
(define-read-only (verify-contract)
  ;; In Clarity 4 this could call into verifier APIs; for now, we assert the owner is set
  (ok (var-get owner)))

;; --- Asset protection management ---
(define-public (set-asset-protection (asset-symbol (string-ascii 32)) (flag bool))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err ERR-NOT-OWNER))
    (map-set asset-protection asset-symbol flag)
    (ok flag)))

(define-read-only (is-protected (asset-symbol (string-ascii 32)))
  (default-to false (map-get? asset-protection asset-symbol)))

;; --- Core actions ---
(define-public (deposit-collateral (amount uint))
  (begin
    (asserts! (> amount u0) (err ERR-ZERO-INPUT))
    (let ((current (default-to u0 (map-get? collateral tx-sender))))
      (let ((new-balance (+ current amount)))
        (map-set collateral tx-sender new-balance)
        ;; Return depositor and new balance as a tuple for richer client-side handling
        (ok {depositor: tx-sender, balance: new-balance})))))

(define-public (withdraw-collateral (amount uint))
  (begin
    (asserts! (> amount u0) (err ERR-ZERO-INPUT))
    (let ((protected (default-to false (map-get? asset-protection "STX"))))
      (asserts! (not protected) (err ERR-PROTECTED))
      (let ((current (default-to u0 (map-get? collateral tx-sender))))
        (asserts! (>= current amount) (err ERR-INSUFFICIENT))
        (map-set collateral tx-sender (- current amount))
        ;; Note: STX transfer back to user must be handled by off-chain or additional logic
        (ok (- current amount))))))

;; Read-only balance
(define-read-only (get-collateral (owner-principal principal))
  (default-to u0 (map-get? collateral owner-principal)))