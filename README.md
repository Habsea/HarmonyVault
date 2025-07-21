# HarmonyVault

A decentralized music royalty distribution platform built on Stacks blockchain that enables transparent and automated royalty payments to artists.

## Features

- **Track Registration**: Artists can register their music tracks with custom royalty rates
- **Streaming Payments**: Automatic royalty distribution when fans stream tracks
- **Verification System**: Platform admin verification for track authenticity
- **Analytics**: Real-time streaming analytics and engagement tracking

## Smart Contract Functions

### Public Functions
- `register-track`: Register a new music track with metadata
- `stream-track`: Stream a track and pay royalties to the artist
- `verify-track`: Verify track authenticity (admin only)

### Read-Only Functions
- `get-track`: Retrieve track information
- `get-streaming-record`: Get specific streaming record
- `get-stream-count`: Get total stream count for a track

## Usage

Deploy the contract and start registering tracks to build a decentralized music ecosystem with transparent royalty distribution.
```

**PR Title**: feat: implement decentralized music royalty distribution platform

**PR Description**: 
Introduces HarmonyVault, a blockchain-based music royalty distribution system that automates payments to artists. Features include track registration, streaming payments, admin verification, and real-time analytics. Built with Clarity smart contracts for transparent and trustless royalty management.

**README Commit**: docs: add comprehensive documentation for HarmonyVault platform

**Code Commit**: feat: implement core music streaming and royalty distribution logic

**Branch Name**: feature/harmony-vault-royalty-system

---

## PROJECT 2: DECENTRALIZED CARBON CREDIT MARKETPLACE

<CodeProject id="music-royalty">

```clarity file="contracts/eco-ledger.clar"
;; EcoLedger: Decentralized carbon credit marketplace
;; Enables companies to mint carbon credits, buyers to purchase offsets, and validators to certify projects

(define-data-var registry-authority principal tx-sender)

(define-map credit-inventory
  { credit-id: uint }
  {
    issuer: principal,
    price-per-ton: uint,
    project-name: (string-ascii 50),
    environmental-impact: (string-ascii 500),
    validity-period: uint,
    certified: bool
  })

(define-map transaction-history
  { credit-id: uint, transaction-id: uint }
  {
    purchaser: principal,
    purchase-date: uint,
    offset-status: (string-ascii 20)
  })

(define-data-var next-credit-id uint u1)

(define-map purchase-tracker
  { credit-id: uint }
  { total-purchases: uint })

;; Mint new carbon credits
(define-public (mint-credits (project-input (string-ascii 50)) (impact-input (string-ascii 500)) (period-input uint) (price-input uint))
  (let
    (
      (credit-id (var-get next-credit-id))
      (transaction-id u0)
      (project project-input)
      (impact impact-input)
      (period period-input)
      (price price-input)
    )
    ;; Input validation
    (asserts! (> price u0) (err u1))
    (asserts! (> (len project) u0) (err u5))
    (asserts! (> (len impact) u0) (err u6))
    (asserts! (> period u0) (err u7))
    
    (map-set credit-inventory
      { credit-id: credit-id }
      {
        issuer: tx-sender,
        price-per-ton: price,
        project-name: project,
        environmental-impact: impact,
        validity-period: period,
        certified: false
      }
    )
    (map-set transaction-history
      { credit-id: credit-id, transaction-id: transaction-id }
      {
        purchaser: tx-sender,
        purchase-date: credit-id,
        offset-status: "minted"
      }
    )
    (map-set purchase-tracker
      { credit-id: credit-id }
      { total-purchases: u1 }
    )
    (var-set next-credit-id (+ credit-id u1))
    (ok credit-id)
  ))

;; Purchase carbon credits
(define-public (purchase-credits (credit-id-input uint))
  (let
    (
      (credit-id credit-id-input)
      (credit-info (unwrap! (map-get? credit-inventory { credit-id: credit-id }) (err u2)))
      (price (get price-per-ton credit-info))
      (issuer (get issuer credit-info))
      (tracker-data (default-to { total-purchases: u0 } (map-get? purchase-tracker { credit-id: credit-id })))
      (transaction-id (get total-purchases tracker-data))
      (new-transaction-id (+ transaction-id u1))
    )
    ;; Input validation
    (asserts! (> credit-id u0) (err u8))
    (asserts! (not (is-eq tx-sender issuer)) (err u3))
    
    (try! (stx-transfer? price tx-sender issuer))
    (map-set transaction-history
      { credit-id: credit-id, transaction-id: transaction-id }
      {
        purchaser: tx-sender,
        purchase-date: (var-get next-credit-id),
        offset-status: "purchased"
      }
    )
    (map-set purchase-tracker
      { credit-id: credit-id }
      { total-purchases: new-transaction-id }
    )
    (ok true)
  ))

;; Certify carbon credits (registry authority only)
(define-public (certify-credits (credit-id-input uint))
  (let
    (
      (credit-id credit-id-input)
      (credit-info (unwrap! (map-get? credit-inventory { credit-id: credit-id }) (err u2)))
      (tracker-data (default-to { total-purchases: u0 } (map-get? purchase-tracker { credit-id: credit-id })))
      (transaction-id (get total-purchases tracker-data))
      (new-transaction-id (+ transaction-id u1))
    )
    ;; Input validation
    (asserts! (> credit-id u0) (err u8))
    (asserts! (is-eq tx-sender (var-get registry-authority)) (err u4))
    
    (map-set credit-inventory
      { credit-id: credit-id }
      (merge credit-info { certified: true })
    )
    (map-set transaction-history
      { credit-id: credit-id, transaction-id: transaction-id }
      {
        purchaser: (get issuer credit-info),
        purchase-date: (var-get next-credit-id),
        offset-status: "certified"
      }
    )
    (map-set purchase-tracker
      { credit-id: credit-id }
      { total-purchases: new-transaction-id }
    )
    (ok true)
  ))

;; Get credit details
(define-read-only (get-credit (credit-id uint))
  (map-get? credit-inventory { credit-id: credit-id }))

;; Get transaction history entry
(define-read-only (get-transaction-history (credit-id uint) (transaction-id uint))
  (map-get? transaction-history { credit-id: credit-id, transaction-id: transaction-id }))

;; Get total purchases for credits
(define-read-only (get-purchase-count (credit-id uint))
  (let
    (
      (tracker-data (default-to { total-purchases: u0 } (map-get? purchase-tracker { credit-id: credit-id })))
    )
    (get total-purchases tracker-data)
  ))