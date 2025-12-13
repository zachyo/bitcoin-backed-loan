;; Bitcoin-Backed Loan: Vault contract (initial skeleton)
;; Written to be compatible with Clarity; includes asset protection & verification hooks

(define-constant ERR-NOT-OWNER u100)
(define-constant ERR-ZERO-INPUT u101)
(define-constant ERR-INSUFFICIENT u102)
(define-constant ERR-PROTECTED u200)
;; Borrowing / loan errors
(define-constant ERR-LTV-VIOLATION u201)
(define-constant ERR-NO-DEBT u202)
(define-constant ERR-BORROW-LOW u203)

;; Owner is set at deployment
(define-data-var owner principal tx-sender)

;; Map of collateral balances by user
(define-map collateral principal uint)

;; Map of outstanding debt by user (uint: principal currency)
(define-map debt principal uint)

;; Price oracle mock (asset symbol -> price as uint; price units are abstract)
(define-map price-oracle (string-ascii 32) uint)

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
    ;; Ensure STX is transferred from depositor to the contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (let ((current (default-to u0 (map-get? collateral tx-sender))))
      (let ((new-balance (+ current amount)))
        (map-set collateral tx-sender new-balance)
        ;; Return depositor and new balance as a tuple for richer client-side handling
        (ok {depositor: tx-sender, balance: new-balance})))))

(define-public (withdraw-collateral (amount uint))
  (begin
    (asserts! (> amount u0) (err ERR-ZERO-INPUT))
    (let ((protected (default-to false (map-get? asset-protection "STX")))
          (user tx-sender))
      (asserts! (not protected) (err ERR-PROTECTED))
      (let ((current (default-to u0 (map-get? collateral user))))
        (asserts! (>= current amount) (err ERR-INSUFFICIENT))
        (map-set collateral user (- current amount))
        ;; Transfer STX from contract back to the user
        (try! (as-contract (stx-transfer? amount tx-sender user)))
        (ok (- current amount))))))

;; Read-only balance
(define-read-only (get-collateral (owner-principal principal))
  (default-to u0 (map-get? collateral owner-principal)))

;; Read-only: Get debt for owner
(define-read-only (get-debt (owner-principal principal))
  (default-to u0 (map-get? debt owner-principal)))

;; Contract STX balance
(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender)))

;; Owner sets price (mock oracle)
(define-public (set-price (asset-symbol (string-ascii 32)) (price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err ERR-NOT-OWNER))
    (map-set price-oracle asset-symbol price)
    (ok price)))

;; Read-only: get price for asset
(define-read-only (get-price (asset-symbol (string-ascii 32)))
  (default-to u0 (map-get? price-oracle asset-symbol)))

;; LTV and thresholds (expressed in percent points e.g., 50 == 50%)
(define-constant INITIAL_LTV u50)
(define-constant MAINTENANCE_LTV u75)
(define-constant LIQUIDATION_BONUS u5) ;; 5% bonus to liquidator

;; -------------------------
;; Borrowing / repaying
;; -------------------------

;; Interest model: simple per-block interest (numerator/denominator)
;; INTEREST_PER_BLOCK = INTEREST_NUMERATOR / INTEREST_DENOMINATOR per block
(define-constant INTEREST_NUMERATOR u1)
(define-constant INTEREST_DENOMINATOR u10)

;; Track last accrual block per borrower to compute interest since last snapshot
(define-map debt-last-accrual principal uint)

;; Accrue interest for a specific borrower up to the current block-height
(define-public (accrue-for (owner-principal principal))
  (let ((current stacks-block-height)
        (last (default-to stacks-block-height (map-get? debt-last-accrual owner-principal)))
        (existing (default-to u0 (map-get? debt owner-principal))))
    (let ((delta (if (>= current last) (- current last) u0)))
      (begin
        (asserts! (is-eq u1 u1) (err ERR-ZERO-INPUT))
        (if (or (<= delta u0) (<= existing u0))
            (begin 
              (map-set debt-last-accrual owner-principal current)
              (ok u0))
            (begin
              (let ((interest (/ (* (* existing INTEREST_NUMERATOR) delta) INTEREST_DENOMINATOR)))
                (map-set debt owner-principal (+ existing interest))
                (map-set debt-last-accrual owner-principal current)
                (ok interest))))))))

;; Helper: compute collateral value for user in price units
(define-read-only (get-collateral-value (owner-principal principal))
  (let ((stx-amount (default-to u0 (map-get? collateral owner-principal)))
        (stx-price (default-to u1 (map-get? price-oracle "STX"))))
    (* stx-amount stx-price)))

;; Helper: compute LTV (scaled to percentage)
(define-read-only (get-ltv (owner-principal principal))
  (let ((col-val (get-collateral-value owner-principal))
        (debt-amount (default-to u0 (map-get? debt owner-principal))))
    (if (<= col-val u0)
        u0
        (/ (* debt-amount u100) col-val))))

;; Borrow: user borrows if collateral allows (simple model)
(define-public (borrow (amount uint))
  (begin
    (asserts! (> amount u0) (err ERR-BORROW-LOW))
    ;; apply accrued interest up to current block for borrower
    (try! (accrue-for tx-sender))
    (let ((col-val (get-collateral-value tx-sender))
          (existing-debt (default-to u0 (map-get? debt tx-sender))))
      ;; Max borrowable = col-val * INITIAL_LTV/100 - existing_debt
      (let ((max-borrow (- (/ (* col-val INITIAL_LTV) u100) existing-debt)))
        (asserts! (>= max-borrow amount) (err ERR-LTV-VIOLATION))
        (map-set debt tx-sender (+ existing-debt amount))
        (ok (+ existing-debt amount))))))

;; Repay: user repays outstanding debt; if amount >= debt, debt is cleared
(define-public (repay (amount uint))
  (begin
    (asserts! (> amount u0) (err ERR-ZERO-INPUT))
    ;; apply accrued interest before accepting repayment
    (try! (accrue-for tx-sender))
    (let ((existing (default-to u0 (map-get? debt tx-sender))))
      (asserts! (> existing u0) (err ERR-NO-DEBT))
      (let ((new (if (>= amount existing) u0 (- existing amount))))
        (map-set debt tx-sender new)
        (ok new)))))

;; Liquidate: allows liquidator to clear borrower's debt if LTV exceeds maintenance threshold
(define-public (liquidate (borrower principal))
  (begin
    ;; ensure borrower's debt is up-to-date
    (try! (accrue-for borrower))
    (let ((col-val (get-collateral-value borrower))
          (borrower-debt (default-to u0 (map-get? debt borrower))))
      ;; Only proceed if LTV above threshold and there is debt
      (asserts! (> borrower-debt u0) (err ERR-NO-DEBT))
      (let ((denominator (if (<= col-val u0) u1 col-val)))
        (let ((current-ltv (/ (* borrower-debt u100) denominator)))
          (asserts! (> current-ltv MAINTENANCE_LTV) (err ERR-LTV-VIOLATION))
          ;; Liquidator repays debt and receives collateral minus bonus
          ;; Bonus: liquidator receives (bonus %) of collateral value as reward
          (let ((bonus (/ (* col-val LIQUIDATION_BONUS) u100))
                (transferable (- col-val bonus)))
            ;; For simplicity we clear borrower state: debt 0 and collateral 0
            (map-set debt borrower u0)
            (map-set collateral borrower u0)
            ;; Return amount refunded to liquidator and bonus as a tuple
            (ok {refunded: transferable, bonus: bonus})))))))