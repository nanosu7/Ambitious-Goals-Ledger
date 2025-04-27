;; Ambitious Goals Ledger


;; System-wide error definitions for standardized responses
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-DUPLICATE-ENTRY (err u409))
(define-constant ERR-INVALID-INPUT (err u400))

;; Primary data structure for objective storage
;; Associates user identities with their objective information
(define-map user-objectives
    principal
    {
        objective-text: (string-ascii 100),
        is-completed: bool
    }
)

;; Supporting data structure for objective completion timing
;; Tracks target completion blocks and notification status
(define-map objective-timelines
    principal
    {
        target-block: uint,
        notification-delivered: bool
    }
)

;; Supplementary structure for objective categorization
;; Enables importance-based filtering and organization
(define-map objective-importance
    principal
    {
        importance-rating: uint
    }
)

;; Updates an existing objective with new information
;; Allows modification of both text and completion status
(define-public (update-objective
    (objective-text (string-ascii 100))
    (is-completed bool))
