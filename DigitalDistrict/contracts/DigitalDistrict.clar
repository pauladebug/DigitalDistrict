;; DigitalDistricts - Virtual Commercial Zone Contract
;; A smart contract for managing virtual offices, coworking spaces, and business meetings

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-payment (err u103))
(define-constant err-not-authorized (err u104))
(define-constant err-space-occupied (err u105))

;; Data Variables
(define-data-var next-space-id uint u1)
(define-data-var platform-fee-percentage uint u5) ;; 5% platform fee

;; Data Maps
(define-map spaces
  { space-id: uint }
  {
    owner: principal,
    space-type: (string-ascii 20), ;; "office", "coworking", "meeting"
    name: (string-ascii 50),
    description: (string-ascii 200),
    price-per-hour: uint,
    max-capacity: uint,
    is-active: bool,
    amenities: (string-ascii 100)
  }
)

(define-map bookings
  { booking-id: uint }
  {
    space-id: uint,
    renter: principal,
    start-time: uint,
    end-time: uint,
    total-cost: uint,
    is-active: bool
  }
)

(define-map user-profiles
  { user: principal }
  {
    name: (string-ascii 50),
    company: (string-ascii 50),
    reputation-score: uint,
    total-bookings: uint
  }
)

(define-data-var next-booking-id uint u1)

;; Public Functions

;; Create a new virtual space
(define-public (create-space 
  (space-type (string-ascii 20))
  (name (string-ascii 50))
  (description (string-ascii 200))
  (price-per-hour uint)
  (max-capacity uint)
  (amenities (string-ascii 100))
)
  (let ((space-id (var-get next-space-id)))
    (map-set spaces
      { space-id: space-id }
      {
        owner: tx-sender,
        space-type: space-type,
        name: name,
        description: description,
        price-per-hour: price-per-hour,
        max-capacity: max-capacity,
        is-active: true,
        amenities: amenities
      }
    )
    (var-set next-space-id (+ space-id u1))
    (ok space-id)
  )
)

;; Book a space for specific time period
(define-public (book-space 
  (space-id uint)
  (start-time uint)
  (end-time uint)
)
  (let (
    (space (unwrap! (map-get? spaces { space-id: space-id }) err-not-found))
    (duration-hours (/ (- end-time start-time) u3600)) ;; Convert seconds to hours
    (total-cost (* (get price-per-hour space) duration-hours))
    (platform-fee (/ (* total-cost (var-get platform-fee-percentage)) u100))
    (owner-payment (- total-cost platform-fee))
    (booking-id (var-get next-booking-id))
  )
    ;; Check if space is active
    (asserts! (get is-active space) err-not-found)
    
    ;; Check if user has sufficient STX
    (asserts! (>= (stx-get-balance tx-sender) total-cost) err-insufficient-payment)
    
    ;; Transfer payment to space owner
    (try! (stx-transfer? owner-payment tx-sender (get owner space)))
    
    ;; Transfer platform fee to contract owner
    (try! (stx-transfer? platform-fee tx-sender contract-owner))
    
    ;; Create booking record
    (map-set bookings
      { booking-id: booking-id }
      {
        space-id: space-id,
        renter: tx-sender,
        start-time: start-time,
        end-time: end-time,
        total-cost: total-cost,
        is-active: true
      }
    )
    
    ;; Update user profile
    (update-user-booking-count tx-sender)
    
    (var-set next-booking-id (+ booking-id u1))
    (ok booking-id)
  )
)

;; Cancel a booking (only by renter or space owner)
(define-public (cancel-booking (booking-id uint))
  (let ((booking (unwrap! (map-get? bookings { booking-id: booking-id }) err-not-found)))
    (asserts! 
      (or 
        (is-eq tx-sender (get renter booking))
        (is-eq tx-sender (get-space-owner (get space-id booking)))
      ) 
      err-not-authorized
    )
    
    (map-set bookings
      { booking-id: booking-id }
      (merge booking { is-active: false })
    )
    (ok true)
  )
)

;; Update space details (only by space owner)
(define-public (update-space 
  (space-id uint)
  (name (string-ascii 50))
  (description (string-ascii 200))
  (price-per-hour uint)
  (max-capacity uint)
  (amenities (string-ascii 100))
)
  (let ((space (unwrap! (map-get? spaces { space-id: space-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get owner space)) err-not-authorized)
    
    (map-set spaces
      { space-id: space-id }
      (merge space {
        name: name,
        description: description,
        price-per-hour: price-per-hour,
        max-capacity: max-capacity,
        amenities: amenities
      })
    )
    (ok true)
  )
)

;; Toggle space active status
(define-public (toggle-space-status (space-id uint))
  (let ((space (unwrap! (map-get? spaces { space-id: space-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get owner space)) err-not-authorized)
    
    (map-set spaces
      { space-id: space-id }
      (merge space { is-active: (not (get is-active space)) })
    )
    (ok true)
  )
)

;; Create or update user profile
(define-public (update-profile 
  (name (string-ascii 50))
  (company (string-ascii 50))
)
  (let ((existing-profile (map-get? user-profiles { user: tx-sender })))
    (match existing-profile
      profile (map-set user-profiles
        { user: tx-sender }
        (merge profile { name: name, company: company })
      )
      (map-set user-profiles
        { user: tx-sender }
        {
          name: name,
          company: company,
          reputation-score: u100,
          total-bookings: u0
        }
      )
    )
    (ok true)
  )
)

;; Private Functions

;; Get space owner
(define-private (get-space-owner (space-id uint))
  (match (map-get? spaces { space-id: space-id })
    space (get owner space)
    contract-owner
  )
)

;; Update user booking count
(define-private (update-user-booking-count (user principal))
  (let ((profile (default-to 
    { name: "", company: "", reputation-score: u100, total-bookings: u0 }
    (map-get? user-profiles { user: user })
  )))
    (map-set user-profiles
      { user: user }
      (merge profile { total-bookings: (+ (get total-bookings profile) u1) })
    )
  )
)

;; Read-only Functions

;; Get space details
(define-read-only (get-space (space-id uint))
  (map-get? spaces { space-id: space-id })
)

;; Get booking details
(define-read-only (get-booking (booking-id uint))
  (map-get? bookings { booking-id: booking-id })
)

;; Get user profile
(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles { user: user })
)

;; Get current space ID counter
(define-read-only (get-next-space-id)
  (var-get next-space-id)
)

;; Get current booking ID counter
(define-read-only (get-next-booking-id)
  (var-get next-booking-id)
)

;; Get platform fee percentage
(define-read-only (get-platform-fee)
  (var-get platform-fee-percentage)
)

;; Check if space is available for a time period
(define-read-only (is-space-available (space-id uint) (start-time uint) (end-time uint))
  (match (map-get? spaces { space-id: space-id })
    space (get is-active space)
    false
  )
)

;; Admin Functions (only contract owner)

;; Update platform fee
(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u20) (err u106)) ;; Max 20% fee
    (var-set platform-fee-percentage new-fee)
    (ok true)
  )
)