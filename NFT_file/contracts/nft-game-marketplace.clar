;; NFT Game Assets Contract - Enhanced Version
;; Feature Branch: enhanced-marketplace

(define-non-fungible-token game-asset uint)

;; Enhanced Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-listing-not-found (err u102))
(define-constant err-wrong-price (err u103))
(define-constant err-invalid-commission (err u104))
(define-constant err-game-not-registered (err u105))
(define-constant err-asset-locked (err u106))

;; Enhanced Data Structures
(define-map asset-details
    uint 
    {
        name: (string-ascii 50),
        description: (string-ascii 200),
        image-uri: (string-ascii 200),
        game-id: uint,
        creator: principal,
        attributes: (list 10 {trait: (string-ascii 20), value: (string-ascii 20)}),
        created-at: uint,
        rarity-score: uint,
        is-locked: bool
    }
)

(define-map market-listings
    uint
    {
        seller: principal,
        price: uint,
        listed: bool,
        expires-at: (optional uint),
        min-bid: (optional uint)
    }
)

(define-map registered-games
    uint
    {
        name: (string-ascii 50),
        developer: principal,
        commission-rate: uint,
        verified: bool
    }
)

(define-map game-asset-usage
    {game-id: uint, asset-id: uint}
    {
        equipped: bool,
        last-used: uint,
        usage-count: uint
    }
)

;; Enhanced Asset Creation
(define-public (mint-asset (asset-id uint) 
                          (name (string-ascii 50))
                          (description (string-ascii 200))
                          (image-uri (string-ascii 200))
                          (game-id uint)
                          (attributes (list 10 {trait: (string-ascii 20), value: (string-ascii 20)}))
                          (rarity-score uint))
    (let ((game (unwrap! (map-get? registered-games game-id) err-game-not-registered)))
        (begin
            (asserts! (or (is-eq tx-sender contract-owner)
                         (is-eq tx-sender (get developer game)))
                     err-owner-only)
            (try! (nft-mint? game-asset asset-id tx-sender))
            (map-set asset-details asset-id
                {
                    name: name,
                    description: description,
                    image-uri: image-uri,
                    game-id: game-id,
                    creator: tx-sender,
                    attributes: attributes,
                    created-at: block-height,
                    rarity-score: rarity-score,
                    is-locked: false
                }
            )
            (ok true)
        )
    )
)

;; Enhanced Market Functions
(define-public (list-asset-with-auction (asset-id uint) 
                                      (price uint)
                                      (min-bid uint)
                                      (expires-at uint))
    (begin
        (asserts! (is-eq (nft-get-owner? game-asset asset-id) (some tx-sender)) 
                 err-not-token-owner)
        (asserts! (not (get is-locked (default-to 
            {name: "", description: "", image-uri: "", game-id: u0, creator: tx-sender,
             attributes: (list ), created-at: u0, rarity-score: u0, is-locked: false}
            (map-get? asset-details asset-id)))) 
            err-asset-locked)
        (map-set market-listings asset-id 
            {
                seller: tx-sender,
                price: price,
                listed: true,
                expires-at: (some expires-at),
                min-bid: (some min-bid)
            }
        )
        (ok true)
    )
)

;; Enhanced Purchase with Royalties
(define-public (buy-asset (asset-id uint))
    (let (
        (listing (unwrap! (map-get? market-listings asset-id) err-listing-not-found))
        (price (get price listing))
        (seller (get seller listing))
        (asset (unwrap! (map-get? asset-details asset-id) err-listing-not-found))
        (game (unwrap! (map-get? registered-games (get game-id asset)) err-game-not-registered))
        (commission (/ (* price (get commission-rate game)) u100))
    )
        (begin
            (asserts! (is-eq (get listed listing) true) err-listing-not-found)
            ;; Pay commission to game developer
            (try! (stx-transfer? commission tx-sender (get developer game)))
            ;; Pay seller
            (try! (stx-transfer? (- price commission) tx-sender seller))
            (try! (nft-transfer? game-asset asset-id seller tx-sender))
            (map-delete market-listings asset-id)
            (ok true)
        )
    )
)

;; Game Integration Functions
(define-public (register-game (game-id uint) 
                             (name (string-ascii 50))
                             (commission-rate uint))
    (begin
        (asserts! (< commission-rate u30) err-invalid-commission)
        (map-set registered-games game-id
            {
                name: name,
                developer: tx-sender,
                commission-rate: commission-rate,
                verified: false
            }
        )
        (ok true)
    )
)

(define-public (verify-game (game-id uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set registered-games game-id
            (merge (unwrap! (map-get? registered-games game-id) err-game-not-registered)
                  {verified: true})
        )
        (ok true)
    )
)

(define-public (use-asset-in-game (game-id uint) (asset-id uint))
    (let (
        (current-usage (default-to 
            {equipped: false, last-used: u0, usage-count: u0}
            (map-get? game-asset-usage {game-id: game-id, asset-id: asset-id})))
    )
        (begin
            (asserts! (is-eq (nft-get-owner? game-asset asset-id) (some tx-sender)) 
                     err-not-token-owner)
            (map-set game-asset-usage 
                {game-id: game-id, asset-id: asset-id}
                {
                    equipped: true,
                    last-used: block-height,
                    usage-count: (+ (get usage-count current-usage) u1)
                }
            )
            (ok true)
        )
    )
)

;; Enhanced Getter Functions
(define-read-only (get-asset-full-details (asset-id uint))
    (let (
        (asset (unwrap! (map-get? asset-details asset-id) err-listing-not-found))
        (usage-stats (map-get? game-asset-usage 
            {game-id: (get game-id asset), asset-id: asset-id}))
    )
        (ok {
            asset: asset,
            usage: usage-stats,
            listing: (map-get? market-listings asset-id)
        })
    )
)