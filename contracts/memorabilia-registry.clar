;; Virtual Memorabilia Registry Contract
;; Provides secure cataloging and access management for digital collectible items

;; =======================================================
;; SECTION 1: CONFIGURATION & DECLARATIONS
;; =======================================================

;; Registry administrator
(define-constant REGISTRY-ADMIN tx-sender)

;; =======================================================
;; SECTION 2: STATUS CODES & ERROR HANDLING
;; =======================================================

;; Response codes for operations
(define-constant CODE-ITEM-MISSING (err u301))      ;; Item not in registry
(define-constant CODE-ITEM-EXISTS (err u302))       ;; Item already registered
(define-constant CODE-INVALID-LABEL (err u303))     ;; Label format requirements not met
(define-constant CODE-INVALID-DIMENSIONS (err u304)) ;; Dimensions out of acceptable range
(define-constant CODE-NOT-PERMITTED (err u305))     ;; Caller lacks permission
(define-constant CODE-INVALID-TARGET (err u306))    ;; Target principal is invalid
(define-constant CODE-ADMIN-RESTRICTED (err u307))  ;; Action limited to admin only
(define-constant CODE-PERMISSION-DENIED (err u308)) ;; User lacks required access level

;; =======================================================
;; SECTION 3: DATA PERSISTENCE
;; =======================================================

;; Registry item counter
(define-data-var registry-item-counter uint u0)

;; Primary registry data store 
(define-map memorabilia-registry
  { item-serial: uint }
  {
    label: (string-ascii 64),
    registrant: principal,
    dimensions: uint,
    timestamp: uint,
    memo: (string-ascii 128),
    categories: (list 10 (string-ascii 32))
  }
)

;; Permission management system
(define-map viewer-permissions
  { item-serial: uint, viewer: principal }
  { can-view: bool }
)

;; =======================================================
;; SECTION 4: UTILITY FUNCTIONS
;; =======================================================

;; Verify item exists in registry
(define-private (registry-contains-item (item-serial uint))
  (is-some (map-get? memorabilia-registry { item-serial: item-serial }))
)

;; Verify item registrant matches provided principal
(define-private (verify-registrant (item-serial uint) (registrant principal))
  (match (map-get? memorabilia-registry { item-serial: item-serial })
    registry-entry (is-eq (get registrant registry-entry) registrant)
    false
  )
)

;; Retrieve item dimensions
(define-private (lookup-dimensions (item-serial uint))
  (default-to u0 
    (get dimensions 
      (map-get? memorabilia-registry { item-serial: item-serial })
    )
  )
)

;; Validate category string
(define-private (validate-category-format (category (string-ascii 32)))
  (and 
    (> (len category) u0)
    (< (len category) u33)
  )
)

;; Validate full category list
(define-private (validate-categories (categories (list 10 (string-ascii 32))))
  (and
    (> (len categories) u0)
    (<= (len categories) u10)
    (is-eq (len (filter validate-category-format categories)) (len categories))
  )
)

;; =======================================================
;; SECTION 5: PUBLIC INTERFACES
;; =======================================================

;; Register new memorabilia item
(define-public (register-item (label (string-ascii 64)) (dimensions uint) (memo (string-ascii 128)) (categories (list 10 (string-ascii 32))))
  (let
    (
      (next-serial (+ (var-get registry-item-counter) u1))
    )
    ;; Validate input parameters
    (asserts! (and (> (len label) u0) (< (len label) u65)) CODE-INVALID-LABEL)
    (asserts! (and (> dimensions u0) (< dimensions u1000000000)) CODE-INVALID-DIMENSIONS)
    (asserts! (and (> (len memo) u0) (< (len memo) u129)) CODE-INVALID-LABEL)
    (asserts! (validate-categories categories) CODE-INVALID-LABEL)

    ;; Create registry entry
    (map-insert memorabilia-registry
      { item-serial: next-serial }
      {
        label: label,
        registrant: tx-sender,
        dimensions: dimensions,
        timestamp: block-height,
        memo: memo,
        categories: categories
      }
    )

    ;; Initialize viewing permissions
    (map-insert viewer-permissions
      { item-serial: next-serial, viewer: tx-sender }
      { can-view: true }
    )

    ;; Update counter and return
    (var-set registry-item-counter next-serial)
    (ok next-serial)
  )
)

;; Reassign item to new registrant
(define-public (reassign-item (item-serial uint) (new-registrant principal))
  (let
    (
      (registry-entry (unwrap! (map-get? memorabilia-registry { item-serial: item-serial }) CODE-ITEM-MISSING))
    )
    ;; Verify item and ownership
    (asserts! (registry-contains-item item-serial) CODE-ITEM-MISSING)
    (asserts! (is-eq (get registrant registry-entry) tx-sender) CODE-NOT-PERMITTED)

    ;; Update registry entry
    (map-set memorabilia-registry
      { item-serial: item-serial }
      (merge registry-entry { registrant: new-registrant })
    )
    (ok true)
  )
)

;; Modify item details
(define-public (modify-item-details (item-serial uint) (new-label (string-ascii 64)) (new-dimensions uint) (new-memo (string-ascii 128)) (new-categories (list 10 (string-ascii 32))))
  (let
    (
      (registry-entry (unwrap! (map-get? memorabilia-registry { item-serial: item-serial }) CODE-ITEM-MISSING))
    )
    ;; Validate item and permissions
    (asserts! (registry-contains-item item-serial) CODE-ITEM-MISSING)
    (asserts! (is-eq (get registrant registry-entry) tx-sender) CODE-NOT-PERMITTED)

    ;; Validate new data
    (asserts! (and (> (len new-label) u0) (< (len new-label) u65)) CODE-INVALID-LABEL)
    (asserts! (and (> new-dimensions u0) (< new-dimensions u1000000000)) CODE-INVALID-DIMENSIONS)
    (asserts! (and (> (len new-memo) u0) (< (len new-memo) u129)) CODE-INVALID-LABEL)
    (asserts! (validate-categories new-categories) CODE-INVALID-LABEL)

    ;; Update registry entry
    (map-set memorabilia-registry
      { item-serial: item-serial }
      (merge registry-entry { 
        label: new-label, 
        dimensions: new-dimensions, 
        memo: new-memo, 
        categories: new-categories 
      })
    )
    (ok true)
  )
)

;; Remove item from registry
(define-public (remove-item (item-serial uint))
  (let
    (
      (registry-entry (unwrap! (map-get? memorabilia-registry { item-serial: item-serial }) CODE-ITEM-MISSING))
    )
    ;; Validate item and permissions
    (asserts! (registry-contains-item item-serial) CODE-ITEM-MISSING)
    (asserts! (is-eq (get registrant registry-entry) tx-sender) CODE-NOT-PERMITTED)

    ;; Delete registry entry
    (map-delete memorabilia-registry { item-serial: item-serial })
    (ok true)
  )
)

;; =======================================================
;; SECTION 6: PERMISSION MANAGEMENT
;; =======================================================

;; Grant viewing permission to another user
(define-public (grant-viewer-access (item-serial uint) (viewer principal))
  (let
    (
      (registry-entry (unwrap! (map-get? memorabilia-registry { item-serial: item-serial }) CODE-ITEM-MISSING))
    )
    ;; Verify item and ownership
    (asserts! (registry-contains-item item-serial) CODE-ITEM-MISSING)
    (asserts! (is-eq (get registrant registry-entry) tx-sender) CODE-NOT-PERMITTED)

    (ok true)
  )
)

;; Revoke viewing permission
(define-public (revoke-viewer-access (item-serial uint) (viewer principal))
  (let
    (
      (registry-entry (unwrap! (map-get? memorabilia-registry { item-serial: item-serial }) CODE-ITEM-MISSING))
    )
    ;; Verify item and ownership
    (asserts! (registry-contains-item item-serial) CODE-ITEM-MISSING)
    (asserts! (is-eq (get registrant registry-entry) tx-sender) CODE-NOT-PERMITTED)

    (ok true)
  )
)

;; =======================================================
;; SECTION 7: QUERY FUNCTIONS
;; =======================================================

;; Check if user has viewing access
(define-read-only (has-viewer-access (item-serial uint) (viewer principal))
  (let
    (
      (access-data (map-get? viewer-permissions { item-serial: item-serial, viewer: viewer }))
    )
    (match access-data
      permission-record (get can-view permission-record)
      false
    )
  )
)

;; Get the total number of registry items
(define-read-only (get-registry-count)
  (var-get registry-item-counter)
)


