;; HarmonyVault: Decentralized music royalty distribution platform
;; Enables artists to register tracks, fans to stream, and distributors to manage payments

(define-data-var platform-admin principal tx-sender)

(define-map track-registry
  { track-id: uint }
  {
    artist: principal,
    royalty-rate: uint,
    track-title: (string-ascii 50),
    album-metadata: (string-ascii 500),
    release-timestamp: uint,
    verified: bool
  })

(define-map streaming-records
  { track-id: uint, stream-id: uint }
  {
    listener: principal,
    play-timestamp: uint,
    engagement-level: (string-ascii 20)
  })

(define-data-var next-track-id uint u1)

(define-map stream-analytics
  { track-id: uint }
  { total-streams: uint })

;; Register a new music track
(define-public (register-track (title-input (string-ascii 50)) (metadata-input (string-ascii 500)) (timestamp-input uint) (rate-input uint))
  (let
    (
      (track-id (var-get next-track-id))
      (stream-id u0)
      (title title-input)
      (metadata metadata-input)
      (timestamp timestamp-input)
      (rate rate-input)
    )
    ;; Input validation
    (asserts! (> rate u0) (err u1))
    (asserts! (> (len title) u0) (err u5))
    (asserts! (> (len metadata) u0) (err u6))
    (asserts! (> timestamp u0) (err u7))
    
    (map-set track-registry
      { track-id: track-id }
      {
        artist: tx-sender,
        royalty-rate: rate,
        track-title: title,
        album-metadata: metadata,
        release-timestamp: timestamp,
        verified: false
      }
    )
    (map-set streaming-records
      { track-id: track-id, stream-id: stream-id }
      {
        listener: tx-sender,
        play-timestamp: track-id,
        engagement-level: "registered"
      }
    )
    (map-set stream-analytics
      { track-id: track-id }
      { total-streams: u1 }
    )
    (var-set next-track-id (+ track-id u1))
    (ok track-id)
  ))

;; Stream a music track
(define-public (stream-track (track-id-input uint))
  (let
    (
      (track-id track-id-input)
      (track-info (unwrap! (map-get? track-registry { track-id: track-id }) (err u2)))
      (rate (get royalty-rate track-info))
      (artist (get artist track-info))
      (analytics-data (default-to { total-streams: u0 } (map-get? stream-analytics { track-id: track-id })))
      (stream-id (get total-streams analytics-data))
      (new-stream-id (+ stream-id u1))
    )
    ;; Input validation
    (asserts! (> track-id u0) (err u8))
    (asserts! (not (is-eq tx-sender artist)) (err u3))
    
    (try! (stx-transfer? rate tx-sender artist))
    (map-set streaming-records
      { track-id: track-id, stream-id: stream-id }
      {
        listener: tx-sender,
        play-timestamp: (var-get next-track-id),
        engagement-level: "streamed"
      }
    )
    (map-set stream-analytics
      { track-id: track-id }
      { total-streams: new-stream-id }
    )
    (ok true)
  ))

;; Verify a track (platform admin only)
(define-public (verify-track (track-id-input uint))
  (let
    (
      (track-id track-id-input)
      (track-info (unwrap! (map-get? track-registry { track-id: track-id }) (err u2)))
      (analytics-data (default-to { total-streams: u0 } (map-get? stream-analytics { track-id: track-id })))
      (stream-id (get total-streams analytics-data))
      (new-stream-id (+ stream-id u1))
    )
    ;; Input validation
    (asserts! (> track-id u0) (err u8))
    (asserts! (is-eq tx-sender (var-get platform-admin)) (err u4))
    
    (map-set track-registry
      { track-id: track-id }
      (merge track-info { verified: true })
    )
    (map-set streaming-records
      { track-id: track-id, stream-id: stream-id }
      {
        listener: (get artist track-info),
        play-timestamp: (var-get next-track-id),
        engagement-level: "verified"
      }
    )
    (map-set stream-analytics
      { track-id: track-id }
      { total-streams: new-stream-id }
    )
    (ok true)
  ))

;; Get track details
(define-read-only (get-track (track-id uint))
  (map-get? track-registry { track-id: track-id }))

;; Get streaming record entry
(define-read-only (get-streaming-record (track-id uint) (stream-id uint))
  (map-get? streaming-records { track-id: track-id, stream-id: stream-id }))

;; Get total streams for a track
(define-read-only (get-stream-count (track-id uint))
  (let
    (
      (analytics-data (default-to { total-streams: u0 } (map-get? stream-analytics { track-id: track-id })))
    )
    (get total-streams analytics-data)
  ))