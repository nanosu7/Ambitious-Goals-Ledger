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
    (let
        (
            (current-user tx-sender)
            (existing-entry (map-get? user-objectives current-user))
        )
        (if (is-some existing-entry)
            (begin
                (if (is-eq objective-text "")
                    (err ERR-INVALID-INPUT)
                    (begin
                        (if (or (is-eq is-completed true) (is-eq is-completed false))
                            (begin
                                (map-set user-objectives current-user
                                    {
                                        objective-text: objective-text,
                                        is-completed: is-completed
                                    }
                                )
                                (ok "Objective successfully updated.")
                            )
                            (err ERR-INVALID-INPUT)
                        )
                    )
                )
            )
            (err ERR-NOT-FOUND)
        )
    )
)

;; Completely removes an objective from the system
;; Provides permanent deletion capability
(define-public (delete-objective)
    (let
        (
            (current-user tx-sender)
            (existing-entry (map-get? user-objectives current-user))
        )
        (if (is-some existing-entry)
            (begin
                (map-delete user-objectives current-user)
                (ok "Objective successfully removed.")
            )
            (err ERR-NOT-FOUND)
        )
    )
)

;; Establishes timeline expectations for objective completion
;; Sets block height targets for accountability
(define-public (establish-objective-timeline (blocks-ahead uint))
    (let
        (
            (current-user tx-sender)
            (existing-entry (map-get? user-objectives current-user))
            (completion-block (+ block-height blocks-ahead))
        )
        (if (is-some existing-entry)
            (if (> blocks-ahead u0)
                (begin
                    (map-set objective-timelines current-user
                        {
                            target-block: completion-block,
                            notification-delivered: false
                        }
                    )
                    (ok "Objective timeline successfully established.")
                )
                (err ERR-INVALID-INPUT)
            )
            (err ERR-NOT-FOUND)
        )
    )
)

;; Creates a new objective entry for the calling user
;; Prevents creation when existing records are present
(define-public (create-objective 
    (objective-text (string-ascii 100)))
    (let
        (
            (current-user tx-sender)
            (existing-entry (map-get? user-objectives current-user))
        )
        (if (is-none existing-entry)
            (begin
                (if (is-eq objective-text "")
                    (err ERR-INVALID-INPUT)
                    (begin
                        (map-set user-objectives current-user
                            {
                                objective-text: objective-text,
                                is-completed: false
                            }
                        )
                        (ok "Objective successfully recorded.")
                    )
                )
            )
            (err ERR-DUPLICATE-ENTRY)
        )
    )
)

;; Allows retrieval of complete objective details
;; Returns both descriptive text and completion status
(define-read-only (get-objective-full-details (user-id principal))
    (match (map-get? user-objectives user-id)
        entry (ok {
            objective-text: (get objective-text entry),
            is-completed: (get is-completed entry)
        })
        ERR-NOT-FOUND
    )
)

;; Simplified status check for objective completion
;; Returns boolean completion status only
(define-read-only (check-objective-completion (user-id principal))
    (match (map-get? user-objectives user-id)
        entry (ok (get is-completed entry))
        ERR-NOT-FOUND
    )
)


;; Enables third-party delegation of objectives
;; Facilitates team coordination and task assignment
(define-public (delegate-objective
    (recipient-user principal)
    (objective-text (string-ascii 100)))
    (let
        (
            (existing-entry (map-get? user-objectives recipient-user))
        )
        (if (is-none existing-entry)
            (begin
                (if (is-eq objective-text "")
                    (err ERR-INVALID-INPUT)
                    (begin
                        (map-set user-objectives recipient-user
                            {
                                objective-text: objective-text,
                                is-completed: false
                            }
                        )
                        (ok "Objective successfully delegated.")
                    )
                )
            )
            (err ERR-DUPLICATE-ENTRY)
        )
    )
)

;; Configuration function for objective priority levels
;; Supports organizational filtering with three tiers
(define-public (configure-objective-importance (importance-rating uint))
    (let
        (
            (current-user tx-sender)
            (existing-entry (map-get? user-objectives current-user))
        )
        (if (is-some existing-entry)
            (if (and (>= importance-rating u1) (<= importance-rating u3))
                (begin
                    (map-set objective-importance current-user
                        {
                            importance-rating: importance-rating
                        }
                    )
                    (ok "Objective importance successfully configured.")
                )
                (err ERR-INVALID-INPUT)
            )
            (err ERR-NOT-FOUND)
        )
    )
)

;; Performs validation checks on user objectives without modification
;; Provides pre-operation diagnostics to prevent transaction failures
(define-public (validate-user-objective)
    (let
        (
            (current-user tx-sender)
            (existing-entry (map-get? user-objectives current-user))
        )
        (if (is-some existing-entry)
            (let
                (
                    (current-record (unwrap! existing-entry ERR-NOT-FOUND))
                    (objective-description (get objective-text current-record))
                    (objective-status (get is-completed current-record))
                )
                (ok {
                    is-valid: true,
                    text-length: (len objective-description),
                    completion-status: objective-status
                })
            )
            (ok {
                is-valid: false,
                text-length: u0,
                completion-status: false
            })
        )
    )
)

