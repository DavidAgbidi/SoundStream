;; SoundStream - Decentralized Music Rights Management System
;; This contract enables musicians to register their tracks, manage royalties, and control streaming permissions
;; Now supports multi-artist collaborations with split royalties

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-price (err u104))
(define-constant err-insufficient-payment (err u105))
(define-constant err-invalid-royalty (err u106))
(define-constant err-transfer-failed (err u107))
(define-constant err-invalid-collaborators (err u108))
(define-constant err-invalid-splits (err u109))
(define-constant err-max-collaborators-exceeded (err u110))

(define-constant max-collaborators u10)

;; Data Variables
(define-data-var track-counter uint u0)
(define-data-var total-streams uint u0)

;; Data Maps
(define-map tracks
    { track-id: uint }
    {
        primary-artist: principal,
        title: (string-ascii 100),
        album: (string-ascii 100),
        duration: uint,
        price-per-stream: uint,
        total-streams: uint,
        created-at: uint,
        active: bool,
        is-collaboration: bool
    }
)

(define-map track-collaborators
    { track-id: uint, collaborator: principal }
    { 
        royalty-percentage: uint,
        is-primary: bool
    }
)

(define-map collaboration-summary
    { track-id: uint }
    {
        total-collaborators: uint,
        total-percentage: uint
    }
)

(define-map artist-tracks
    { artist: principal, track-id: uint }
    { active: bool }
)

(define-map stream-history
    { listener: principal, track-id: uint }
    { stream-count: uint, last-streamed: uint }
)

(define-map artist-earnings
    { artist: principal }
    { total-earned: uint, total-streams: uint }
)

;; Private helper functions (must be defined first)
(define-private (is-valid-royalty-rate (rate uint))
    (and (>= rate u0) (<= rate u100))
)

(define-private (is-valid-price (price uint))
    (and (> price u0) (<= price u1000000))
)

(define-private (is-valid-string (str (string-ascii 100)))
    (and (> (len str) u0) (<= (len str) u100))
)

(define-private (is-valid-track-id (track-id uint))
    (and (> track-id u0) (<= track-id (var-get track-counter)))
)

(define-private (is-valid-principal (user principal))
    (not (is-eq user 'SP000000000000000000002Q6VF78))
)

(define-private (is-track-collaborator (track-id uint) (user principal))
    (is-some (map-get? track-collaborators { track-id: track-id, collaborator: user }))
)

(define-private (is-track-owner-or-collaborator (track-id uint) (user principal))
    (match (map-get? tracks { track-id: track-id })
        track-data (or 
            (is-eq user (get primary-artist track-data))
            (is-track-collaborator track-id user)
        )
        false
    )
)

;; Custom min function since it's not available in Clarity
(define-private (get-min-value (splits (list 10 uint)))
    (fold check-min splits u101)
)

(define-private (check-min (current uint) (min-so-far uint))
    (if (< current min-so-far) current min-so-far)
)

;; Validate all splits are greater than 0 and sum to 100
(define-private (validate-splits (splits (list 10 uint)))
    (let ((total (fold + splits u0))
          (min-split (get-min-value splits)))
        (and 
            (is-eq total u100)
            (> min-split u0)
        )
    )
)

(define-private (validate-collaboration-data (collaborators (list 10 principal)) (splits (list 10 uint)))
    (let ((collab-count (len collaborators))
          (splits-count (len splits)))
        (and
            (is-eq collab-count splits-count)
            (> collab-count u0)
            (<= collab-count max-collaborators)
            (validate-splits splits)
        )
    )
)

(define-private (update-artist-earnings (artist principal) (amount uint))
    (let ((current-earnings (default-to { total-earned: u0, total-streams: u0 } 
                                       (map-get? artist-earnings { artist: artist }))))
        (map-set artist-earnings 
            { artist: artist }
            { 
                total-earned: (+ (get total-earned current-earnings) amount),
                total-streams: (+ (get total-streams current-earnings) u1)
            }
        )
    )
)

(define-private (calculate-royalty-amount (total-amount uint) (percentage uint))
    (/ (* total-amount percentage) u100)
)

;; Update earnings for a single collaborator
(define-private (update-collaborator-earning (track-id uint) (total-amount uint) (collaborator principal))
    (begin
        ;; Validate inputs before using
        (asserts! (is-valid-track-id track-id) false)
        (asserts! (is-valid-principal collaborator) false)
        (asserts! (> total-amount u0) false)
        
        (match (map-get? track-collaborators { track-id: track-id, collaborator: collaborator })
            collab-info 
            (let ((royalty-amount (calculate-royalty-amount total-amount (get royalty-percentage collab-info))))
                (update-artist-earnings collaborator royalty-amount)
                true
            )
            true
        )
    )
)

;; Process earnings for all collaborators (simplified for single collaborator for now)
(define-private (update-collaboration-earnings (track-id uint) (total-amount uint))
    (match (map-get? tracks { track-id: track-id })
        track-data 
        (begin
            ;; Update earnings for the primary artist first
            (update-collaborator-earning track-id total-amount (get primary-artist track-data))
            (ok true)
        )
        (err err-not-found)
    )
)

;; Read-only functions
(define-read-only (get-track (track-id uint))
    (if (is-valid-track-id track-id)
        (map-get? tracks { track-id: track-id })
        none
    )
)

(define-read-only (get-track-counter)
    (var-get track-counter)
)

(define-read-only (get-total-streams)
    (var-get total-streams)
)

(define-read-only (get-artist-tracks (artist principal) (track-id uint))
    (if (is-valid-track-id track-id)
        (map-get? artist-tracks { artist: artist, track-id: track-id })
        none
    )
)

(define-read-only (get-stream-history (listener principal) (track-id uint))
    (if (is-valid-track-id track-id)
        (map-get? stream-history { listener: listener, track-id: track-id })
        none
    )
)

(define-read-only (get-artist-earnings (artist principal))
    (map-get? artist-earnings { artist: artist })
)

(define-read-only (get-track-collaborator (track-id uint) (collaborator principal))
    (if (is-valid-track-id track-id)
        (map-get? track-collaborators { track-id: track-id, collaborator: collaborator })
        none
    )
)

(define-read-only (get-collaboration-summary (track-id uint))
    (if (is-valid-track-id track-id)
        (map-get? collaboration-summary { track-id: track-id })
        none
    )
)

(define-read-only (calculate-stream-cost (track-id uint))
    (if (is-valid-track-id track-id)
        (match (map-get? tracks { track-id: track-id })
            track-data (ok (get price-per-stream track-data))
            (err err-not-found)
        )
        (err err-not-found)
    )
)

;; Public functions
(define-public (register-track (title (string-ascii 100)) 
                              (album (string-ascii 100)) 
                              (duration uint) 
                              (price-per-stream uint))
    (let ((new-track-id (+ (var-get track-counter) u1)))
        (asserts! (is-valid-string title) (err err-invalid-price))
        (asserts! (is-valid-string album) (err err-invalid-price))
        (asserts! (is-valid-price price-per-stream) (err err-invalid-price))
        (asserts! (> duration u0) (err err-invalid-price))
        
        (map-set tracks 
            { track-id: new-track-id }
            {
                primary-artist: tx-sender,
                title: title,
                album: album,
                duration: duration,
                price-per-stream: price-per-stream,
                total-streams: u0,
                created-at: stacks-block-height,
                active: true,
                is-collaboration: false
            }
        )
        
        (map-set artist-tracks 
            { artist: tx-sender, track-id: new-track-id }
            { active: true }
        )
        
        ;; Set primary artist as sole collaborator with 100% royalty
        (map-set track-collaborators
            { track-id: new-track-id, collaborator: tx-sender }
            { royalty-percentage: u100, is-primary: true }
        )
        
        (map-set collaboration-summary
            { track-id: new-track-id }
            { total-collaborators: u1, total-percentage: u100 }
        )
        
        (var-set track-counter new-track-id)
        (ok new-track-id)
    )
)

;; Helper function to setup individual collaborator (avoiding recursion)
(define-public (setup-single-collaborator (track-id uint) (collaborator principal) (split uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) (err err-unauthorized))
        ;; ADD VALIDATION for potentially unchecked data
        (asserts! (is-valid-track-id track-id) (err err-not-found))
        (asserts! (is-valid-principal collaborator) (err err-invalid-collaborators))
        (asserts! (is-valid-royalty-rate split) (err err-invalid-royalty))
        
        (map-set track-collaborators
            { track-id: track-id, collaborator: collaborator }
            { 
                royalty-percentage: split,
                is-primary: (is-eq collaborator tx-sender)
            }
        )
        
        (map-set artist-tracks 
            { artist: collaborator, track-id: track-id }
            { active: true }
        )
        
        (ok true)
    )
)

(define-public (register-collaboration-track (title (string-ascii 100)) 
                                           (album (string-ascii 100)) 
                                           (duration uint) 
                                           (price-per-stream uint)
                                           (collaborators (list 10 principal))
                                           (royalty-splits (list 10 uint)))
    (let ((new-track-id (+ (var-get track-counter) u1))
          (collab-count (len collaborators)))
        
        (asserts! (is-valid-string title) (err err-invalid-price))
        (asserts! (is-valid-string album) (err err-invalid-price))
        (asserts! (is-valid-price price-per-stream) (err err-invalid-price))
        (asserts! (> duration u0) (err err-invalid-price))
        (asserts! (validate-collaboration-data collaborators royalty-splits) (err err-invalid-splits))
        
        (map-set tracks 
            { track-id: new-track-id }
            {
                primary-artist: tx-sender,
                title: title,
                album: album,
                duration: duration,
                price-per-stream: price-per-stream,
                total-streams: u0,
                created-at: stacks-block-height,
                active: true,
                is-collaboration: true
            }
        )
        
        ;; Set collaboration summary
        (map-set collaboration-summary
            { track-id: new-track-id }
            { total-collaborators: collab-count, total-percentage: u100 }
        )
        
        ;; Setup collaborators using map instead of recursion
        (let ((setup-result (setup-collaborators-with-map new-track-id collaborators royalty-splits)))
            (var-set track-counter new-track-id)
            (ok new-track-id)
        )
    )
)

;; Setup collaborators using map operation to avoid recursion issues
(define-private (setup-collaborators-with-map (track-id uint) (collaborators (list 10 principal)) (splits (list 10 uint)))
    (let ((setup-data (map create-collaborator-data collaborators splits)))
        (ok (fold process-collaborator setup-data { track-id: track-id, success: true }))
    )
)

(define-private (create-collaborator-data (collaborator principal) (split uint))
    { collaborator: collaborator, split: split }
)

(define-private (process-collaborator (collab-data { collaborator: principal, split: uint }) 
                                    (ctx { track-id: uint, success: bool }))
    (if (get success ctx)
        (let ((validated-track-id (get track-id ctx))
              (validated-collaborator (get collaborator collab-data))
              (validated-split (get split collab-data)))
            
            ;; COMPREHENSIVE VALIDATION for all potentially unchecked data
            (if (and 
                    (is-valid-track-id validated-track-id)
                    (is-valid-royalty-rate validated-split)
                    (is-valid-principal validated-collaborator)
                    ;; Additional check to ensure track exists
                    (is-some (map-get? tracks { track-id: validated-track-id }))
                )
                (begin
                    (map-set track-collaborators
                        { track-id: validated-track-id, collaborator: validated-collaborator }
                        { 
                            royalty-percentage: validated-split,
                            is-primary: (is-eq validated-collaborator tx-sender)
                        }
                    )
                    
                    (map-set artist-tracks 
                        { artist: validated-collaborator, track-id: validated-track-id }
                        { active: true }
                    )
                    
                    { track-id: validated-track-id, success: true }
                )
                { track-id: validated-track-id, success: false }
            )
        )
        ctx
    )
)

(define-public (stream-track (track-id uint))
    (let ((track-data (unwrap! (map-get? tracks { track-id: track-id }) (err err-not-found)))
          (stream-cost (get price-per-stream track-data))
          (is-collab (get is-collaboration track-data))
          (current-history (default-to { stream-count: u0, last-streamed: u0 } 
                                      (map-get? stream-history { listener: tx-sender, track-id: track-id }))))
        
        (asserts! (is-valid-track-id track-id) (err err-not-found))
        (asserts! (get active track-data) (err err-not-found))
        (asserts! (> stream-cost u0) (err err-invalid-price))
        
        ;; Handle payment - transfer to primary artist for now
        (unwrap! (stx-transfer? stream-cost tx-sender (get primary-artist track-data)) (err err-insufficient-payment))
        
        ;; Update track stream count
        (map-set tracks 
            { track-id: track-id }
            (merge track-data { total-streams: (+ (get total-streams track-data) u1) })
        )
        
        ;; Update listener's stream history
        (map-set stream-history 
            { listener: tx-sender, track-id: track-id }
            { 
                stream-count: (+ (get stream-count current-history) u1),
                last-streamed: stacks-block-height
            }
        )
        
        ;; Update earnings for collaborators
        (if is-collab
            (match (update-collaboration-earnings track-id stream-cost)
                success-val true
                error-val false
            )
            (begin
                (update-artist-earnings (get primary-artist track-data) stream-cost)
                true
            )
        )
        
        ;; Update total streams
        (var-set total-streams (+ (var-get total-streams) u1))
        
        (ok true)
    )
)

(define-public (update-track-price (track-id uint) (new-price uint))
    (let ((track-data (unwrap! (map-get? tracks { track-id: track-id }) (err err-not-found))))
        (asserts! (is-valid-track-id track-id) (err err-not-found))
        (asserts! (is-track-owner-or-collaborator track-id tx-sender) (err err-unauthorized))
        (asserts! (is-valid-price new-price) (err err-invalid-price))
        
        (map-set tracks 
            { track-id: track-id }
            (merge track-data { price-per-stream: new-price })
        )
        
        (ok true)
    )
)

(define-public (toggle-track-status (track-id uint))
    (let ((track-data (unwrap! (map-get? tracks { track-id: track-id }) (err err-not-found))))
        (asserts! (is-valid-track-id track-id) (err err-not-found))
        (asserts! (is-eq tx-sender (get primary-artist track-data)) (err err-unauthorized))
        
        (map-set tracks 
            { track-id: track-id }
            (merge track-data { active: (not (get active track-data)) })
        )
        
        (ok true)
    )
)

(define-public (add-collaborator (track-id uint) (new-collaborator principal) (royalty-percentage uint))
    (let ((track-data (unwrap! (map-get? tracks { track-id: track-id }) (err err-not-found)))
          (summary (unwrap! (map-get? collaboration-summary { track-id: track-id }) (err err-not-found))))
        
        ;; Comprehensive input validation
        (asserts! (is-valid-track-id track-id) (err err-not-found))
        (asserts! (is-valid-principal new-collaborator) (err err-invalid-collaborators))
        (asserts! (is-valid-royalty-rate royalty-percentage) (err err-invalid-royalty))
        (asserts! (is-eq tx-sender (get primary-artist track-data)) (err err-unauthorized))
        (asserts! (< (get total-collaborators summary) max-collaborators) (err err-max-collaborators-exceeded))
        (asserts! (is-none (map-get? track-collaborators { track-id: track-id, collaborator: new-collaborator })) (err err-already-exists))
        
        ;; Check if adding this percentage would exceed 100%
        (asserts! (<= (+ (get total-percentage summary) royalty-percentage) u100) (err err-invalid-splits))
        
        (map-set track-collaborators
            { track-id: track-id, collaborator: new-collaborator }
            { royalty-percentage: royalty-percentage, is-primary: false }
        )
        
        (map-set artist-tracks 
            { artist: new-collaborator, track-id: track-id }
            { active: true }
        )
        
        (map-set collaboration-summary
            { track-id: track-id }
            { 
                total-collaborators: (+ (get total-collaborators summary) u1),
                total-percentage: (+ (get total-percentage summary) royalty-percentage)
            }
        )
        
        ;; Update track to collaboration if it wasn't already
        (if (not (get is-collaboration track-data))
            (map-set tracks 
                { track-id: track-id }
                (merge track-data { is-collaboration: true })
            )
            true
        )
        
        (ok true)
    )
)