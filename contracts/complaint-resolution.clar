;; Tenant Complaint Resolution Contract
;; Manages and tracks resolution of housing quality complaints

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-COMPLAINT-NOT-FOUND (err u301))
(define-constant ERR-INVALID-STATUS (err u302))
(define-constant ERR-INVALID-PRIORITY (err u303))
(define-constant ERR-INVALID-PROPERTY (err u304))

;; Data Variables
(define-data-var next-complaint-id uint u1)

;; Data Maps
(define-map complaints
  { complaint-id: uint }
  {
    property-id: uint,
    tenant: principal,
    complaint-type: (string-ascii 50),
    description: (string-ascii 500),
    priority: (string-ascii 20),
    status: (string-ascii 20),
    filed-date: uint,
    assigned-to: (optional principal),
    resolution-date: (optional uint),
    resolution-notes: (string-ascii 500)
  }
)

(define-map complaint-updates
  { complaint-id: uint, update-date: uint }
  {
    updater: principal,
    status: (string-ascii 20),
    notes: (string-ascii 300)
  }
)

(define-map property-complaint-history
  { property-id: uint }
  {
    total-complaints: uint,
    resolved-complaints: uint,
    average-resolution-time: uint,
    last-complaint-date: uint
  }
)

(define-map complaint-categories
  { category: (string-ascii 50) }
  {
    priority-level: (string-ascii 20),
    max-resolution-days: uint,
    requires-inspection: bool
  }
)

;; Initialize complaint categories
(map-set complaint-categories { category: "heating" } { priority-level: "high", max-resolution-days: u3, requires-inspection: true })
(map-set complaint-categories { category: "plumbing" } { priority-level: "high", max-resolution-days: u3, requires-inspection: true })
(map-set complaint-categories { category: "electrical" } { priority-level: "high", max-resolution-days: u1, requires-inspection: true })
(map-set complaint-categories { category: "pest-control" } { priority-level: "medium", max-resolution-days: u7, requires-inspection: false })
(map-set complaint-categories { category: "noise" } { priority-level: "low", max-resolution-days: u14, requires-inspection: false })
(map-set complaint-categories { category: "structural" } { priority-level: "emergency", max-resolution-days: u1, requires-inspection: true })

;; Public Functions

;; File a new complaint
(define-public (file-complaint (property-id uint) (complaint-type (string-ascii 50)) (description (string-ascii 500)))
  (let ((complaint-id (var-get next-complaint-id))
        (category-info (map-get? complaint-categories { category: complaint-type }))
        (priority (if (is-some category-info) (get priority-level (unwrap-panic category-info)) "medium")))
    (map-set complaints
      { complaint-id: complaint-id }
      {
        property-id: property-id,
        tenant: tx-sender,
        complaint-type: complaint-type,
        description: description,
        priority: priority,
        status: "open",
        filed-date: block-height,
        assigned-to: none,
        resolution-date: none,
        resolution-notes: ""
      }
    )
    ;; Update property complaint history
    (let ((history (default-to
                     { total-complaints: u0, resolved-complaints: u0, average-resolution-time: u0, last-complaint-date: u0 }
                     (map-get? property-complaint-history { property-id: property-id }))))
      (map-set property-complaint-history
        { property-id: property-id }
        (merge history {
          total-complaints: (+ (get total-complaints history) u1),
          last-complaint-date: block-height
        })
      )
    )
    (var-set next-complaint-id (+ complaint-id u1))
    (ok complaint-id)
  )
)

;; Assign complaint to staff member
(define-public (assign-complaint (complaint-id uint) (assignee principal))
  (let ((complaint (unwrap! (map-get? complaints { complaint-id: complaint-id }) ERR-COMPLAINT-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status complaint) "open") ERR-INVALID-STATUS)
    (map-set complaints
      { complaint-id: complaint-id }
      (merge complaint {
        assigned-to: (some assignee),
        status: "investigating"
      })
    )
    ;; Add update record
    (map-set complaint-updates
      { complaint-id: complaint-id, update-date: block-height }
      {
        updater: tx-sender,
        status: "investigating",
        notes: "Complaint assigned for investigation"
      }
    )
    (ok true)
  )
)

;; Update complaint status
(define-public (update-complaint-status (complaint-id uint) (new-status (string-ascii 20)) (notes (string-ascii 300)))
  (let ((complaint (unwrap! (map-get? complaints { complaint-id: complaint-id }) ERR-COMPLAINT-NOT-FOUND)))
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER)
                  (is-eq (some tx-sender) (get assigned-to complaint))) ERR-NOT-AUTHORIZED)
    (map-set complaints
      { complaint-id: complaint-id }
      (merge complaint { status: new-status })
    )
    ;; Add update record
    (map-set complaint-updates
      { complaint-id: complaint-id, update-date: block-height }
      {
        updater: tx-sender,
        status: new-status,
        notes: notes
      }
    )
    (ok true)
  )
)

;; Resolve complaint
(define-public (resolve-complaint (complaint-id uint) (resolution-notes (string-ascii 500)))
  (let ((complaint (unwrap! (map-get? complaints { complaint-id: complaint-id }) ERR-COMPLAINT-NOT-FOUND))
        (resolution-time (- block-height (get filed-date complaint))))
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER)
                  (is-eq (some tx-sender) (get assigned-to complaint))) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq (get status complaint) "resolved")) ERR-INVALID-STATUS)
    (map-set complaints
      { complaint-id: complaint-id }
      (merge complaint {
        status: "resolved",
        resolution-date: (some block-height),
        resolution-notes: resolution-notes
      })
    )
    ;; Update property complaint history
    (let ((property-id (get property-id complaint))
          (history (unwrap-panic (map-get? property-complaint-history { property-id: (get property-id complaint) }))))
      (map-set property-complaint-history
        { property-id: property-id }
        (merge history {
          resolved-complaints: (+ (get resolved-complaints history) u1),
          average-resolution-time: (/ (+ (* (get average-resolution-time history) (get resolved-complaints history)) resolution-time)
                                     (+ (get resolved-complaints history) u1))
        })
      )
    )
    ;; Add final update record
    (map-set complaint-updates
      { complaint-id: complaint-id, update-date: block-height }
      {
        updater: tx-sender,
        status: "resolved",
        notes: "Complaint resolved"
      }
    )
    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-complaint (complaint-id uint))
  (map-get? complaints { complaint-id: complaint-id })
)

(define-read-only (get-complaint-update (complaint-id uint) (update-date uint))
  (map-get? complaint-updates { complaint-id: complaint-id, update-date: update-date })
)

(define-read-only (get-property-complaint-history (property-id uint))
  (map-get? property-complaint-history { property-id: property-id })
)

(define-read-only (get-complaint-category (category (string-ascii 50)))
  (map-get? complaint-categories { category: category })
)

(define-read-only (get-next-complaint-id)
  (var-get next-complaint-id)
)

(define-read-only (is-complaint-overdue (complaint-id uint))
  (let ((complaint (map-get? complaints { complaint-id: complaint-id })))
    (if (is-some complaint)
      (let ((complaint-data (unwrap-panic complaint))
            (category-info (map-get? complaint-categories { category: (get complaint-type complaint-data) })))
        (if (is-some category-info)
          (let ((max-days (get max-resolution-days (unwrap-panic category-info)))
                (days-passed (/ (- block-height (get filed-date complaint-data)) u144))) ;; ~144 blocks per day
            (and (not (is-eq (get status complaint-data) "resolved"))
                 (> days-passed max-days)))
          false))
      false))
)
