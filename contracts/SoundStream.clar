;; SoundStream - Decentralized Music Rights Management System
;; This contract enables musicians to register their tracks, manage royalties, and control streaming permissions

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

;; Data Variables
(define-data-var track-counter uint u0)
(define-data-var total-streams uint u0)

;; Data Maps
(define-map tracks
    { track-id: uint }
    {
        artist: principal,
        title: (string-ascii 100),
        album: (string-ascii 100),
        duration: uint,
        price-per-stream: uint,
        royalty-rate: uint,
        total-streams: uint,
        created-at: uint,
        active: bool
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

(define-read-only (calculate-stream-cost (track-id uint))
    (if (is-valid-track-id track-id)
        (match (map-get? tracks { track-id: track-id })
            track-data (ok (get price-per-stream track-data))
            (err err-not-found)
        )
        (err err-not-found)
    )
)

;; Private functions
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

;; Public functions
(define-public (register-track (title (string-ascii 100)) 
                              (album (string-ascii 100)) 
                              (duration uint) 
                              (price-per-stream uint) 
                              (royalty-rate uint))
    (let ((new-track-id (+ (var-get track-counter) u1)))
        (asserts! (is-valid-string title) (err err-invalid-price))
        (asserts! (is-valid-string album) (err err-invalid-price))
        (asserts! (is-valid-price price-per-stream) (err err-invalid-price))
        (asserts! (is-valid-royalty-rate royalty-rate) (err err-invalid-royalty))
        (asserts! (> duration u0) (err err-invalid-price))
        
        (map-set tracks 
            { track-id: new-track-id }
            {
                artist: tx-sender,
                title: title,
                album: album,
                duration: duration,
                price-per-stream: price-per-stream,
                royalty-rate: royalty-rate,
                total-streams: u0,
                created-at: stacks-block-height,
                active: true
            }
        )
        
        (map-set artist-tracks 
            { artist: tx-sender, track-id: new-track-id }
            { active: true }
        )
        
        (var-set track-counter new-track-id)
        (ok new-track-id)
    )
)

(define-public (stream-track (track-id uint))
    (let ((track-data (unwrap! (map-get? tracks { track-id: track-id }) (err err-not-found)))
          (stream-cost (get price-per-stream track-data))
          (artist (get artist track-data))
          (current-history (default-to { stream-count: u0, last-streamed: u0 } 
                                      (map-get? stream-history { listener: tx-sender, track-id: track-id }))))
        
        (asserts! (is-valid-track-id track-id) (err err-not-found))
        (asserts! (get active track-data) (err err-not-found))
        (asserts! (> stream-cost u0) (err err-invalid-price))
        
        ;; Transfer payment to artist
        (unwrap! (stx-transfer? stream-cost tx-sender artist) (err err-insufficient-payment))
        
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
        
        ;; Update artist earnings
        (update-artist-earnings artist stream-cost)
        
        ;; Update total streams
        (var-set total-streams (+ (var-get total-streams) u1))
        
        (ok true)
    )
)

(define-public (update-track-price (track-id uint) (new-price uint))
    (let ((track-data (unwrap! (map-get? tracks { track-id: track-id }) (err err-not-found))))
        (asserts! (is-valid-track-id track-id) (err err-not-found))
        (asserts! (is-eq tx-sender (get artist track-data)) (err err-unauthorized))
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
        (asserts! (is-eq tx-sender (get artist track-data)) (err err-unauthorized))
        
        (map-set tracks 
            { track-id: track-id }
            (merge track-data { active: (not (get active track-data)) })
        )
        
        (ok true)
    )
)