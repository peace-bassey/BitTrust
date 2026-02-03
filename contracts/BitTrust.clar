;; Title: BitTrust DeFi Lending Protocol
;;
;; Summary:
;; An innovative Bitcoin-secured lending ecosystem that rewards financial 
;; responsibility through adaptive risk assessment and reputation-based pricing.
;;
;; Description:
;; BitTrust revolutionizes decentralized finance by creating a merit-based lending 
;; platform where borrowers earn better terms through proven repayment history.
;; Our sophisticated algorithm adjusts collateral requirements and interest rates 
;; in real-time based on individual reputation scores, fostering a trustworthy 
;; lending environment. Built on Stacks blockchain, it leverages Bitcoin's security 
;; while enabling advanced DeFi functionality through STX token collateralization.
;; The protocol incentivizes responsible borrowing behavior by continuously 
;; rewarding users who demonstrate reliability, creating a self-sustaining 
;; ecosystem of trust and financial opportunity.

;; CONSTANTS & CONFIGURATION

;; Protocol governance
(define-constant CONTRACT-OWNER tx-sender)

;; Error handling codes
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INSUFFICIENT-BALANCE (err u2))
(define-constant ERR-INVALID-AMOUNT (err u3))
(define-constant ERR-LOAN-NOT-FOUND (err u4))
(define-constant ERR-LOAN-DEFAULTED (err u5))
(define-constant ERR-INSUFFICIENT-SCORE (err u6))
(define-constant ERR-ACTIVE-LOAN (err u7))
(define-constant ERR-NOT-DUE (err u8))
(define-constant ERR-INVALID-DURATION (err u9))
(define-constant ERR-INVALID-LOAN-ID (err u10))

;; Reputation system parameters
(define-constant MIN-SCORE u50) ;; Minimum reputation threshold
(define-constant MAX-SCORE u100) ;; Maximum achievable reputation
(define-constant MIN-LOAN-SCORE u70) ;; Minimum score for loan eligibility

;; DATA STORAGE ARCHITECTURE

;; User reputation and financial history tracking
(define-map UserScores
  { user: principal }
  {
    score: uint,
    total-borrowed: uint,
    total-repaid: uint,
    loans-taken: uint,
    loans-repaid: uint,
    last-update: uint,
  }
)

;; Comprehensive loan record management
(define-map Loans
  { loan-id: uint }
  {
    borrower: principal,
    amount: uint,
    collateral: uint,
    due-height: uint,
    interest-rate: uint,
    is-active: bool,
    is-defaulted: bool,
    repaid-amount: uint,
  }
)

;; Active loan portfolio tracking per user
(define-map UserLoans
  { user: principal }
  { active-loans: (list 20 uint) }
)

;; PROTOCOL STATE VARIABLES

;; Unique loan identifier management
(define-data-var next-loan-id uint u0)

;; Total value locked monitoring
(define-data-var total-stx-locked uint u0)

;; CORE PROTOCOL FUNCTIONS

;; Initialize user reputation profile
;; Establishes baseline creditworthiness for new protocol participants
(define-public (initialize-score)
  (let ((sender tx-sender))
    (asserts! (is-none (map-get? UserScores { user: sender })) ERR-UNAUTHORIZED)
    (ok (map-set UserScores { user: sender } {
      score: MIN-SCORE,
      total-borrowed: u0,
      total-repaid: u0,
      loans-taken: u0,
      loans-repaid: u0,
      last-update: stacks-block-height,
    }))
  )
)

;; Execute loan origination with dynamic risk assessment
;; Creates new lending agreement with personalized terms based on reputation
(define-public (request-loan
    (amount uint)
    (collateral uint)
    (duration uint)
  )
  (let (
      (sender tx-sender)
      (loan-id (+ (var-get next-loan-id) u1))
      (user-score (unwrap! (map-get? UserScores { user: sender }) ERR-UNAUTHORIZED))
      (active-loans (default-to { active-loans: (list) } (map-get? UserLoans { user: sender })))
    )
    ;; Comprehensive eligibility validation
    (asserts! (>= (get score user-score) MIN-LOAN-SCORE) ERR-INSUFFICIENT-SCORE)
    (asserts! (<= (len (get active-loans active-loans)) u5) ERR-ACTIVE-LOAN)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (and (> duration u0) (<= duration u52560)) ERR-INVALID-DURATION)
    ;; Maximum ~1 year duration (10-minute block assumption)

    ;; Dynamic collateral calculation based on reputation
    (let ((required-collateral (calculate-required-collateral amount (get score user-score))))
      (asserts! (>= collateral required-collateral) ERR-INSUFFICIENT-BALANCE)

      ;; Secure collateral transfer
      (try! (stx-transfer? collateral sender (as-contract tx-sender)))

      ;; Create comprehensive loan record
      (map-set Loans { loan-id: loan-id } {
        borrower: sender,
        amount: amount,
        collateral: collateral,
        due-height: (+ stacks-block-height duration),
        interest-rate: (calculate-interest-rate (get score user-score)),
        is-active: true,
        is-defaulted: false,
        repaid-amount: u0,
      })

      ;; Update user's active loan portfolio
      (try! (update-user-loans sender loan-id))

      ;; Disburse loan funds
      (as-contract (try! (stx-transfer? amount tx-sender sender)))

      ;; Update protocol state
      (var-set next-loan-id loan-id)
      (var-set total-stx-locked (+ (var-get total-stx-locked) collateral))
      (ok loan-id)
    )
  )
)

;; Process loan repayment with reputation enhancement
;; Handles partial and full payments while updating creditworthiness
(define-public (repay-loan
    (loan-id uint)
    (amount uint)
  )
  (let (
      (sender tx-sender)
      (loan (unwrap! (map-get? Loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
    )
    ;; Authorization and status verification
    (asserts! (is-eq sender (get borrower loan)) ERR-UNAUTHORIZED)
    (asserts! (get is-active loan) ERR-LOAN-NOT-FOUND)
    (asserts! (not (get is-defaulted loan)) ERR-LOAN-DEFAULTED)
    (asserts! (<= loan-id (var-get next-loan-id)) ERR-INVALID-LOAN-ID)

    ;; Calculate total obligation including interest
    (let ((total-due (calculate-total-due loan)))
      (asserts! (>= amount u0) ERR-INVALID-AMOUNT)

      ;; Process repayment transaction
      (try! (stx-transfer? amount sender (as-contract tx-sender)))

      ;; Update loan repayment status
      (let ((new-repaid-amount (+ (get repaid-amount loan) amount)))
        (map-set Loans { loan-id: loan-id }
          (merge loan {
            repaid-amount: new-repaid-amount,
            is-active: (< new-repaid-amount total-due),
          })
        )

        ;; Handle loan completion and reputation boost
        (if (>= new-repaid-amount total-due)
          (begin
            (try! (update-credit-score sender true loan))
            (as-contract (try! (stx-transfer? (get collateral loan) tx-sender sender)))
            (var-set total-stx-locked
              (- (var-get total-stx-locked) (get collateral loan))
            )
          )
          true
        )
        (ok true)
      )
    )
  )
)

;; RISK ASSESSMENT & PRICING ENGINE

;; Calculate reputation-based collateral requirements
;; Higher reputation scores unlock reduced collateral ratios
(define-private (calculate-required-collateral
    (amount uint)
    (score uint)
  )
  (let ((collateral-ratio (- u100 (/ (* score u50) u100))))
    (/ (* amount collateral-ratio) u100)
  )
)

;; Determine personalized interest rate based on creditworthiness
;; Superior reputation translates to preferential borrowing rates
(define-private (calculate-interest-rate (score uint))
  (let ((base-rate u10))
    (- base-rate (/ (* score u5) u100))
  )
)

;; Compute total repayment obligation including interest
(define-private (calculate-total-due (loan {
  borrower: principal,
  amount: uint,
  collateral: uint,
  due-height: uint,
  interest-rate: uint,
  is-active: bool,
  is-defaulted: bool,
  repaid-amount: uint,
}))
  (let ((interest (* (get amount loan) (get interest-rate loan))))
    (+ (get amount loan) (/ interest u100))
  )
)

;; REPUTATION MANAGEMENT SYSTEM

;; Update borrower reputation based on payment behavior
;; Rewards reliability while penalizing defaults to maintain ecosystem integrity
(define-private (update-credit-score
    (user principal)
    (success bool)
    (loan {
      borrower: principal,
      amount: uint,
      collateral: uint,
      due-height: uint,
      interest-rate: uint,
      is-active: bool,
      is-defaulted: bool,
      repaid-amount: uint,
    })
  )
  (let (
      (current-score (unwrap! (map-get? UserScores { user: user }) ERR-UNAUTHORIZED))
      (new-score (if success
        (if (<= (+ (get score current-score) u2) MAX-SCORE)
          (+ (get score current-score) u2)
          MAX-SCORE
        )
        (if (>= (- (get score current-score) u10) MIN-SCORE)
          (- (get score current-score) u10)
          MIN-SCORE
        )
      ))
    )
    (if success
      (map-set UserScores { user: user }
        (merge current-score {
          score: new-score,
          total-repaid: (+ (get total-repaid current-score) (get amount loan)),
          loans-repaid: (+ (get loans-repaid current-score) u1),
          last-update: stacks-block-height,
        })
      )
      (map-set UserScores { user: user }
        (merge current-score {
          score: new-score,
          last-update: stacks-block-height,
        })
      )
    )
    (ok true)
  )
)

;; Maintain user's active loan portfolio
(define-private (update-user-loans
    (user principal)
    (loan-id uint)
  )
  (let ((user-loans (default-to { active-loans: (list) } (map-get? UserLoans { user: user }))))
    (map-set UserLoans { user: user } { active-loans: (unwrap! (as-max-len? (append (get active-loans user-loans) loan-id) u20)
      ERR-ACTIVE-LOAN
    ) }
    )
    (ok true)
  )
)

;; DATA QUERY INTERFACE

;; Retrieve comprehensive user reputation profile
(define-read-only (get-user-score (user principal))
  (map-get? UserScores { user: user })
)

;; Access detailed loan information
(define-read-only (get-loan (loan-id uint))
  (map-get? Loans { loan-id: loan-id })
)

;; View user's current active loan portfolio
(define-read-only (get-user-active-loans (user principal))
  (map-get? UserLoans { user: user })
)

;; PROTOCOL ADMINISTRATION

;; Process loan default when payment obligations are not met
;; Maintains protocol integrity through timely default recognition
(define-public (mark-loan-defaulted (loan-id uint))
  (let ((loan (unwrap! (map-get? Loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (>= stacks-block-height (get due-height loan)) ERR-NOT-DUE)
    (asserts! (get is-active loan) ERR-LOAN-NOT-FOUND)
    (asserts! (<= loan-id (var-get next-loan-id)) ERR-INVALID-LOAN-ID)

    ;; Update loan default status
    (map-set Loans { loan-id: loan-id }
      (merge loan {
        is-defaulted: true,
        is-active: false,
      })
    )

    ;; Apply reputation penalty
    (try! (update-credit-score (get borrower loan) false loan))
    (ok true)
  )
)
