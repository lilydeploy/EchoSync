;; Music Streaming Platform Smart Contract
;; Handles music track ownership and streaming marketplace

;; Constants
(define-constant record-label tx-sender)
(define-constant err-label-only (err u100))
(define-constant err-track-missing (err u101))
(define-constant err-permission-denied (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-invalid-streaming-fee (err u104))
(define-constant max-fame-level u100)
(define-constant max-fan-count u10000)
(define-constant max-audio-metadata-length u256)
(define-constant max-album-size u10)  ;; Limit album operations to prevent potential gas issues

;; Data Variables
(define-map music-tracks 
    { track-id: uint }
    { artist: principal, audio-metadata-uri: (string-utf8 256), streamable: bool })

(define-map streaming-fees
    { track-id: uint }
    { fee-per-stream: uint })

(define-map artist-profiles
    { artist: principal }
    { fan-count: uint, fame-level: uint })

(define-map streaming-marketplace
    { track-id: uint }
    { track-owner: principal, fee-per-stream: uint, uploaded-at: uint })

;; Track Counter
(define-data-var track-counter uint u0)

;; Helper Functions

;; Validate track exists and return track data
(define-private (get-track-confirmed (track-id uint))
    (let ((track (map-get? music-tracks { track-id: track-id })))
        (asserts! (and 
                (is-some track)
                (<= track-id (var-get track-counter)))
            err-track-missing)
        (ok (unwrap-panic track))))

;; Validate audio metadata URI length
(define-private (validate-audio-metadata-uri (uri (string-utf8 256)))
    (let ((uri-length (len uri)))
        (and 
            (> uri-length u0)
            (<= uri-length max-audio-metadata-length))))

;; Public Functions

;; Batch Release new music tracks
(define-public (batch-release-tracks 
    (audio-metadata-uris (list 10 (string-utf8 256))) 
    (streamable-list (list 10 bool)))
    (begin
        (asserts! (is-eq tx-sender record-label) err-label-only)
        (asserts! (and 
            (> (len audio-metadata-uris) u0)
            (<= (len audio-metadata-uris) max-album-size)
            (is-eq (len audio-metadata-uris) (len streamable-list))) 
            err-invalid-input)
        (let ((released-tracks 
            (map release-single-track 
                audio-metadata-uris 
                streamable-list)))
            (ok released-tracks))))

;; Helper function for batch releasing
(define-private (release-single-track 
    (uri (string-utf8 256))
    (streamable bool))
    (let 
        ((track-id (+ (var-get track-counter) u1)))
        (asserts! (validate-audio-metadata-uri uri) err-invalid-input)
        (map-set music-tracks
            { track-id: track-id }
            { artist: record-label,
              audio-metadata-uri: uri,
              streamable: streamable })
        (var-set track-counter track-id)
        (ok track-id)))

;; Batch Transfer music tracks
(define-public (batch-transfer-tracks 
    (track-ids (list 10 uint)) 
    (new-artists (list 10 principal)))
    (begin
        (asserts! (and 
            (> (len track-ids) u0)
            (<= (len track-ids) max-album-size)
            (is-eq (len track-ids) (len new-artists))) 
            err-invalid-input)
        (let ((transfers 
            (map transfer-single-track 
                track-ids 
                new-artists)))
            (ok transfers))))

;; Helper function for batch transfer
(define-private (transfer-single-track 
    (track-id uint)
    (new-artist principal))
    (let 
        ((track (unwrap-panic (get-track-confirmed track-id))))
        (asserts! (and
                (is-eq (get artist track) tx-sender)
                (get streamable track)
                (not (is-eq new-artist tx-sender)))  ;; Prevent self-transfers
            err-permission-denied)
        (map-set music-tracks
            { track-id: track-id }
            { artist: new-artist,
              audio-metadata-uri: (get audio-metadata-uri track),
              streamable: (get streamable track) })
        (ok true)))  ;; Changed to return (ok true)

;; Release single music track
(define-public (release-track (audio-metadata-uri (string-utf8 256)) (streamable bool))
    (let
        ((track-id (+ (var-get track-counter) u1)))
        (asserts! (is-eq tx-sender record-label) err-label-only)
        (asserts! (validate-audio-metadata-uri audio-metadata-uri) err-invalid-input)
        (map-set music-tracks
            { track-id: track-id }
            { artist: tx-sender,
              audio-metadata-uri: audio-metadata-uri,
              streamable: streamable })
        (var-set track-counter track-id)
        (ok track-id)))

;; Transfer track ownership
(define-public (transfer-track (track-id uint) (new-artist principal))
    (begin
        (asserts! (<= track-id (var-get track-counter)) err-invalid-input)
        (let ((track (try! (get-track-confirmed track-id))))
            (asserts! (and
                    (is-eq (get artist track) tx-sender)
                    (get streamable track)
                    (not (is-eq new-artist tx-sender)))  ;; Prevent self-transfers
                err-permission-denied)
            (map-set music-tracks
                { track-id: track-id }
                { artist: new-artist,
                  audio-metadata-uri: (get audio-metadata-uri track),
                  streamable: (get streamable track) })
            (ok true))))

;; Upload track for streaming with enhanced marketplace upload
(define-public (upload-track-for-streaming (track-id uint) (fee-per-stream uint))
    (begin
        (asserts! (<= track-id (var-get track-counter)) err-invalid-input)
        (let ((track (try! (get-track-confirmed track-id))))
            (asserts! (and 
                    (is-eq (get artist track) tx-sender)
                    (> fee-per-stream u0)
                    (get streamable track))  ;; Ensure track is streamable
                err-invalid-streaming-fee)
            (map-set streaming-marketplace
                { track-id: track-id }
                { track-owner: tx-sender, 
                  fee-per-stream: fee-per-stream, 
                  uploaded-at: block-height })
            (ok true))))

;; Stream uploaded track with enhanced streaming mechanics
(define-public (stream-track (track-id uint))
    (begin
        (asserts! (<= track-id (var-get track-counter)) err-invalid-input)
        (let
            ((track (try! (get-track-confirmed track-id)))
             (marketplace-entry (unwrap! (map-get? streaming-marketplace { track-id: track-id }) err-track-missing)))
            (asserts! (and
                    (not (is-eq (get track-owner marketplace-entry) tx-sender))
                    (get streamable track))
                err-permission-denied)
            (try! (stx-transfer? (get fee-per-stream marketplace-entry) tx-sender (get track-owner marketplace-entry)))
            (map-set music-tracks
                { track-id: track-id }
                { artist: tx-sender,
                  audio-metadata-uri: (get audio-metadata-uri track),
                  streamable: (get streamable track) })
            (map-delete streaming-marketplace { track-id: track-id })
            (ok true))))

;; Remove track from streaming marketplace
(define-public (remove-from-streaming (track-id uint))
    (begin
        ;; Validate track-id is within the range of released tracks
        (asserts! (<= track-id (var-get track-counter)) err-invalid-input)
        
        ;; Try to get the marketplace entry, return error if not found
        (let ((marketplace-entry (unwrap! (map-get? streaming-marketplace { track-id: track-id }) err-track-missing)))
            ;; Ensure only the track owner can remove
            (asserts! (is-eq tx-sender (get track-owner marketplace-entry)) err-permission-denied)
            
            ;; Delete the streaming marketplace entry
            (map-delete streaming-marketplace { track-id: track-id })
            
            ;; Return success
            (ok true))))

;; Update artist profile with validation
(define-public (update-artist-profile (fan-count uint) (fame-level uint))
    (begin
        (asserts! (<= fan-count max-fan-count) err-invalid-input)
        (asserts! (<= fame-level max-fame-level) err-invalid-input)
        (map-set artist-profiles
            { artist: tx-sender }
            { fan-count: fan-count, fame-level: fame-level })
        (ok true)))

;; Read-only Functions

;; Get track details
(define-read-only (get-track-details (track-id uint))
    (if (<= track-id (var-get track-counter))
        (map-get? music-tracks { track-id: track-id })
        none))

;; Get streaming marketplace details
(define-read-only (get-streaming-marketplace-entry (track-id uint))
    (map-get? streaming-marketplace { track-id: track-id }))

;; Get artist profile
(define-read-only (get-artist-profile (artist principal))
    (map-get? artist-profiles { artist: artist }))

;; Get total tracks released
(define-read-only (get-total-tracks)
    (var-get track-counter))