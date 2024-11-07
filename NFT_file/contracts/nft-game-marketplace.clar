;; NFT Game Assets Contract
;; Initial Implementation

(define-non-fungible-token game-asset uint)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-listing-not-found (err u102))
(define-constant err-wrong-price (err u103))

;; Data Variables
(define-map asset-details
    uint 
    {
        name: (string-ascii 50),
        description: (string-ascii 200),
        image-uri: (string-ascii 200),
        game-id: uint,
        attributes: (list 10 {trait: (string-ascii 20), value: (string-ascii 20)})
    }
)

(define-map market-listings
    uint
    {
        seller: principal,
        price: uint,
        listed: bool
    }
)

;; Asset Creation
(define-public (mint-asset (asset-id uint) 
                          (name (string-ascii 50))
                          (description (string-ascii 200))
                          (image-uri (string-ascii 200))
                          (game-id uint)
                          (attributes (list 10 {trait: (string-ascii 20), value: (string-ascii 20)})))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (try! (nft-mint? game-asset asset-id tx-sender))
        (map-set asset-details asset-id
            {
                name: name,
                description: description,
                image-uri: image-uri,
                game-id: game-id,
                attributes: attributes
            }
        )
        (ok true)
    )
)

;; Market Functions
(define-public (list-asset (asset-id uint) (price uint))
    (begin
        (asserts! (is-eq (nft-get-owner? game-asset asset-id) (some tx-sender)) err-not-token-owner)
        (map-set market-listings asset-id {seller: tx-sender, price: price, listed: true})
        (ok true)
    )
)

(define-public (unlist-asset (asset-id uint))
    (begin
        (asserts! (is-eq (nft-get-owner? game-asset asset-id) (some tx-sender)) err-not-token-owner)
        (map-delete market-listings asset-id)
        (ok true)
    )
)

(define-public (buy-asset (asset-id uint))
    (let (
        (listing (unwrap! (map-get? market-listings asset-id) err-listing-not-found))
        (price (get price listing))
        (seller (get seller listing))
    )
        (begin
            (asserts! (is-eq (get listed listing) true) err-listing-not-found)
            (try! (stx-transfer? price tx-sender seller))
            (try! (nft-transfer? game-asset asset-id seller tx-sender))
            (map-delete market-listings asset-id)
            (ok true)
        )
    )
)

;; Getter Functions
(define-read-only (get-asset-details (asset-id uint))
    (map-get? asset-details asset-id)
)

(define-read-only (get-listing (asset-id uint))
    (map-get? market-listings asset-id)
)