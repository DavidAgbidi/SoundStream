;; SoundStream - Decentralized Music Rights Management System with NFT Integration
;; This contract enables musicians to register their tracks as NFTs, manage royalties, and control streaming permissions
;; Now supports multi-artist collaborations with split royalties and NFT minting

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
(define-constant err-nft-not-found (err u111))
(define-constant err-nft-already-minted (err u112))
(define-constant err-invalid-token-uri (err u113))
(define-constant err-nft-transfer-failed (err u114))

(define-constant max-collaborators u10)

;; NFT Definition
(define-non-fungible-token track-nft uint)

;; Data Variables
(define-data-var track-counter uint u0)
(define-data-var total-streams uint u0)
(define-data-var nft-counter uint u0)

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
        is-collaboration: bool,
        nft-id: (optional uint),
        has-nft: bool
    }
)

(define-map track-nfts
    { nft-id: uint }
    {
        track-id: uint,
        owner: principal,
        token-uri: (string-ascii 256),
        minted-at: uint,
        streaming-rights: bool
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

(define-map nft-ownership-history
    { nft-id: uint, owner: principal }
    { acquired-at: uint, is-current: bool }
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

(define-private (is-valid-token-uri (uri (string-ascii 256)))
    (and (> (len uri) u0) (<= (len uri) u256))
)

(define-private (is-valid-track-id (track-id uint))
    (and (> track-id u0) (<= track-id (var-get track-counter)))
)

(define-private (is-valid-nft-id (nft-id uint))
    (and (> nft-id u0) (<= nft-id (var-get nft-counter)))
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

(define-private (has-streaming-rights (nft-id uint) (user principal))
    (match (map-get? track-nfts { nft-id: nft-id })
        nft-data (and
            (is-eq user (get owner nft-data))
            (get streaming-rights nft-data)
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

;; NFT URI function for SIP-009 compliance
(define-read-only (get-token-uri (nft-id uint))
    (if (is-valid-nft-id nft-id)
        (match (map-get? track-nfts { nft-id: nft-id })
            nft-data (ok (some (get token-uri nft-data)))
            (ok none)
        )
        (ok none)
    )
)

;; Get last token ID for SIP-009 compliance
(define-read-only (get-last-token-id)
    (ok (var-get nft-counter))
)

;; Get NFT owner for SIP-009 compliance
(define-read-only (get-owner (nft-id uint))
    (if (is-valid-nft-id nft-id)
        (ok (nft-get-owner? track-nft nft-id))
        (ok none)
    )
)

;; Read-only functions
(define-read-only (get-track (track-id uint))
    (if (is-valid-track-id track-id)
        (map-get? tracks { track-id: track-id })
        none
    )
)

(define-read-only (get-track-nft (nft-id uint))
    (if (is-valid-nft-id nft-id)
        (map-get? track-nfts { nft-id: nft-id })
        none
    )
)

(define-read-only (get-track-counter)
    (var-get track-counter)
)

(define-read-only (get-nft-counter)
    (var-get nft-counter)
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

(define-read-only (get-nft-ownership-history (nft-id uint) (owner principal))
    (if (is-valid-nft-id nft-id)
        (map-get? nft-ownership-history { nft-id: nft-id, owner: owner })
        none
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
                is-collaboration: false,
                nft-id: none,
                has-nft: false
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
                is-collaboration: true,
                nft-id: none,
                has-nft: false
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

;; NEW NFT FUNCTIONS

(define-public (mint-track-nft (track-id uint) (token-uri (string-ascii 256)))
    (let ((track-data (unwrap! (map-get? tracks { track-id: track-id }) (err err-not-found)))
          (new-nft-id (+ (var-get nft-counter) u1)))
        
        ;; Comprehensive validation
        (asserts! (is-valid-track-id track-id) (err err-not-found))
        (asserts! (is-valid-token-uri token-uri) (err err-invalid-token-uri))
        (asserts! (is-eq tx-sender (get primary-artist track-data)) (err err-unauthorized))
        (asserts! (not (get has-nft track-data)) (err err-nft-already-minted))
        
        ;; Mint the NFT
        (unwrap! (nft-mint? track-nft new-nft-id tx-sender) (err err-nft-transfer-failed))
        
        ;; Update NFT data
        (map-set track-nfts
            { nft-id: new-nft-id }
            {
                track-id: track-id,
                owner: tx-sender,
                token-uri: token-uri,
                minted-at: stacks-block-height,
                streaming-rights: true
            }
        )
        
        ;; Update track with NFT info
        (map-set tracks 
            { track-id: track-id }
            (merge track-data { 
                nft-id: (some new-nft-id),
                has-nft: true
            })
        )
        
        ;; Record ownership history
        (map-set nft-ownership-history
            { nft-id: new-nft-id, owner: tx-sender }
            { acquired-at: stacks-block-height, is-current: true }
        )
        
        (var-set nft-counter new-nft-id)
        (ok new-nft-id)
    )
)

(define-public (transfer-track-nft (nft-id uint) (sender principal) (recipient principal))
    (let ((nft-data (unwrap! (map-get? track-nfts { nft-id: nft-id }) (err err-nft-not-found))))
        
        ;; Comprehensive validation
        (asserts! (is-valid-nft-id nft-id) (err err-nft-not-found))
        (asserts! (is-valid-principal sender) (err err-invalid-collaborators))
        (asserts! (is-valid-principal recipient) (err err-invalid-collaborators))
        (asserts! (is-eq tx-sender sender) (err err-unauthorized))
        (asserts! (is-eq sender (get owner nft-data)) (err err-unauthorized))
        
        ;; Transfer the NFT
        (unwrap! (nft-transfer? track-nft nft-id sender recipient) (err err-nft-transfer-failed))
        
        ;; Update NFT ownership
        (map-set track-nfts
            { nft-id: nft-id }
            (merge nft-data { owner: recipient })
        )
        
        ;; Update ownership history
        (map-set nft-ownership-history
            { nft-id: nft-id, owner: sender }
            { acquired-at: stacks-block-height, is-current: false }
        )
        
        (map-set nft-ownership-history
            { nft-id: nft-id, owner: recipient }
            { acquired-at: stacks-block-height, is-current: true }
        )
        
        (ok true)
    )
)

(define-public (toggle-nft-streaming-rights (nft-id uint))
    (let ((nft-data (unwrap! (map-get? track-nfts { nft-id: nft-id }) (err err-nft-not-found))))
        
        ;; Comprehensive validation
        (asserts! (is-valid-nft-id nft-id) (err err-nft-not-found))
        (asserts! (is-eq tx-sender (get owner nft-data)) (err err-unauthorized))
        
        (map-set track-nfts
            { nft-id: nft-id }
            (merge nft-data { streaming-rights: (not (get streaming-rights nft-data)) })
        )
        
        (ok true)
    )
)

(define-public (stream-track (track-id uint))
    (let ((track-data (unwrap! (map-get? tracks { track-id: track-id }) (err err-not-found)))
          (stream-cost (get price-per-stream track-data))
          (is-collab (get is-collaboration track-data))
          (has-nft-check (get has-nft track-data))
          (current-history (default-to { stream-count: u0, last-streamed: u0 } 
                                      (map-get? stream-history { listener: tx-sender, track-id: track-id }))))
        
        (asserts! (is-valid-track-id track-id) (err err-not-found))
        (asserts! (get active track-data) (err err-not-found))
        (asserts! (> stream-cost u0) (err err-invalid-price))
        
        ;; Check NFT streaming rights if NFT exists
        (if has-nft-check
            (match (get nft-id track-data)
                nft-id-val 
                (if (has-streaming-rights nft-id-val tx-sender)
                    ;; NFT owner can stream for free
                    (begin
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
                        
                        ;; Update total streams
                        (var-set total-streams (+ (var-get total-streams) u1))
                        true
                    )
                    ;; Non-NFT owner pays regular price
                    (begin
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
                        true
                    )
                )
                false
            )
            ;; No NFT - regular payment required
            (begin
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
                true
            )
        )
        
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
        
        ;; Add the collaborator
        (map-set track-collaborators
            { track-id: track-id, collaborator: new-collaborator }
            { royalty-percentage: royalty-percentage, is-primary: false }
        )
        
        (map-set artist-tracks 
            { artist: new-collaborator, track-id: track-id }
            { active: true }
        )
        
        ;; Update collaboration summary
        (map-set collaboration-summary
            { track-id: track-id }
            { 
                total-collaborators: (+ (get total-collaborators summary) u1),
                total-percentage: (+ (get total-percentage summary) royalty-percentage)
            }
        )
        
        ;; Return success response
        (ok true)
    )
)