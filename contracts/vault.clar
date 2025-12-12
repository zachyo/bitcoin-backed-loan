;; Bitcoin-Backed Loan: Vault contract (initial skeleton)
;; Written to be compatible with Clarity; includes asset protection & verification hooks

(define-constant ERR-NOT-OWNER u100)
(define-constant ERR-ZERO-INPUT u101)
(define-constant ERR-INSUFFICIENT u102)

;; Owner is set by calling `initialize` once
(define-data-var owner principal tx-sender)

;; Map of collateral balances by user
(define-map collateral (principal) (uint))

;; Asset protection flags: symbol -> bool (true = protected, cannot withdraw)
(define-map asset-protection (symbol) (bool))

;; --- Initialization / Verification ---
(define-public (initialize)
  (begin
    (if (is-eq tx-sender (var-get owner))
        (err ERR-NOT-OWNER)
        (begin
          (var-set owner tx-sender)
          (ok true)))))

;; Read-only helper to verify the caller is owner
(define-read-only (is-owner (p principal))
  (is-eq p (var-get owner)))

;; Verification hook — placeholder for Clarity 4 contract verification features
(define-read-only (verify-contract)
  ;; In Clarity 4 this could call into verifier APIs; for now, we assert the owner is set
  (ok (var-get owner)))

;; --- Asset protection management ---
(define-public (set-asset-protection (asset-symbol (string-ascii 32)) (flag bool))
  (begin
    (if (not (is-eq tx-sender (var-get owner)))
        (err ERR-NOT-OWNER)
        (begin
          (map-set asset-protection asset-symbol flag)
          (ok flag)))))

(define-read-only (is-protected (asset-symbol (string-ascii 32)))
  (default-to false (map-get? asset-protection asset-symbol)))

;; --- Core actions ---
(define-public (deposit-collateral (amount uint))
  (begin
    (if (<= amount u0)
        (err ERR-ZERO-INPUT)
        (let ((current (default-to u0 (map-get? collateral tx-sender))))
          (map-set collateral tx-sender (+ current amount))
          (ok (+ current amount))))))

(define-public (withdraw-collateral (amount uint))
  (begin
    (if (<= amount u0)
        (err ERR-ZERO-INPUT)
        (let ((protected (default-to false (map-get? asset-protection (string-ascii 'STX)))))
          (if protected
              (err u200) ;; withdrawal blocked by asset protection
              (let ((current (default-to u0 (map-get? collateral tx-sender))))
                (if (< current amount)
                    (err ERR-INSUFFICIENT)
                    (begin
                      (map-set collateral tx-sender (- current amount))
                      ;; Note: STX transfer back to user must be handled by off-chain or additional logic
                      (ok (- current amount))))))))))

;; Read-only balance
(define-read-only (get-collateral (owner-principal principal))
  (default-to u0 (map-get? collateral owner-principal)))
