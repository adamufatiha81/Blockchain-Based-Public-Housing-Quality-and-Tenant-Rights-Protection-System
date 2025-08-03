;; Housing Inspection Automation Contract
;; Schedules and tracks safety and habitability inspections

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PROPERTY (err u101))
(define-constant ERR-INVALID-INSPECTOR (err u102))
(define-constant ERR-INSPECTION-EXISTS (err u103))
(define-constant ERR-INSPECTION-NOT-FOUND (err u104))
(define-constant ERR-INVALID-STATUS (err u105))

;; Data Variables
(define-data-var next-inspection-id uint u1)
(define-data-var next-property-id uint u1)

;; Data Maps
(define-map properties
  { property-id: uint }
  {
    address: (string-ascii 100),
    landlord: principal,
    unit-count: uint,
    property-type: (string-ascii 50),
    last-inspection: uint,
    compliance-status: (string-ascii 20)
  }
)

(define-map inspections
  { inspection-id: uint }
  {
    property-id: uint,
    inspector: principal,
    scheduled-date: uint,
    completed-date: (optional uint),
    status: (string-ascii 20),
    score: (optional uint),
    notes: (string-ascii 500),
    follow-up-required: bool
  }
)

(define-map inspectors
  { inspector: principal }
  {
    name: (string-ascii 50),
    certification: (string-ascii 50),
    active: bool,
    total-inspections: uint
  }
)

(define-map property-inspections
  { property-id: uint, inspection-id: uint }
  { created-at: uint }
)

;; Public Functions

;; Register a new property
(define-public (register-property (address (string-ascii 100)) (landlord principal) (unit-count uint) (property-type (string-ascii 50)))
  (let ((property-id (var-get next-property-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set properties
      { property-id: property-id }
      {
        address: address,
        landlord: landlord,
        unit-count: unit-count,
        property-type: property-type,
        last-inspection: u0,
        compliance-status: "pending"
      }
    )
    (var-set next-property-id (+ property-id u1))
    (ok property-id)
  )
)

;; Register a new inspector
(define-public (register-inspector (inspector principal) (name (string-ascii 50)) (certification (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set inspectors
      { inspector: inspector }
      {
        name: name,
        certification: certification,
        active: true,
        total-inspections: u0
      }
    )
    (ok true)
  )
)

;; Schedule an inspection
(define-public (schedule-inspection (property-id uint) (inspector principal) (scheduled-date uint))
  (let ((inspection-id (var-get next-inspection-id)))
    (asserts! (is-some (map-get? properties { property-id: property-id })) ERR-INVALID-PROPERTY)
    (asserts! (is-some (map-get? inspectors { inspector: inspector })) ERR-INVALID-INSPECTOR)
    (map-set inspections
      { inspection-id: inspection-id }
      {
        property-id: property-id,
        inspector: inspector,
        scheduled-date: scheduled-date,
        completed-date: none,
        status: "scheduled",
        score: none,
        notes: "",
        follow-up-required: false
      }
    )
    (map-set property-inspections
      { property-id: property-id, inspection-id: inspection-id }
      { created-at: block-height }
    )
    (var-set next-inspection-id (+ inspection-id u1))
    (ok inspection-id)
  )
)

;; Complete an inspection
(define-public (complete-inspection (inspection-id uint) (score uint) (notes (string-ascii 500)) (follow-up-required bool))
  (let ((inspection (unwrap! (map-get? inspections { inspection-id: inspection-id }) ERR-INSPECTION-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get inspector inspection)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status inspection) "scheduled") ERR-INVALID-STATUS)
    (asserts! (and (>= score u0) (<= score u100)) ERR-INVALID-STATUS)
    (map-set inspections
      { inspection-id: inspection-id }
      (merge inspection {
        completed-date: (some block-height),
        status: "completed",
        score: (some score),
        notes: notes,
        follow-up-required: follow-up-required
      })
    )
    ;; Update property compliance status
    (let ((property-id (get property-id inspection)))
      (map-set properties
        { property-id: property-id }
        (merge (unwrap-panic (map-get? properties { property-id: property-id })) {
          last-inspection: block-height,
          compliance-status: (if (>= score u70) "compliant" "violation")
        })
      )
    )
    ;; Update inspector stats
    (let ((inspector-data (unwrap-panic (map-get? inspectors { inspector: (get inspector inspection) }))))
      (map-set inspectors
        { inspector: (get inspector inspection) }
        (merge inspector-data {
          total-inspections: (+ (get total-inspections inspector-data) u1)
        })
      )
    )
    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-property (property-id uint))
  (map-get? properties { property-id: property-id })
)

(define-read-only (get-inspection (inspection-id uint))
  (map-get? inspections { inspection-id: inspection-id })
)

(define-read-only (get-inspector (inspector principal))
  (map-get? inspectors { inspector: inspector })
)

(define-read-only (get-next-inspection-id)
  (var-get next-inspection-id)
)

(define-read-only (get-next-property-id)
  (var-get next-property-id)
)
