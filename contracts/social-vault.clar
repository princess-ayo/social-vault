;; Title: SocialVault - Decentralized Social Network Protocol
;;
;; Summary: 
;; A cutting-edge decentralized social networking protocol built on Stacks Layer 2 
;; that combines Bitcoin's security with advanced privacy controls and intelligent 
;; batch processing for enterprise-grade social interactions.
;;
;; Description:
;; SocialVault transforms social networking by leveraging Bitcoin's immutable ledger
;; through Stacks Layer 2 smart contracts. The protocol implements zero-knowledge 
;; privacy architecture, adaptive transaction batching, and sophisticated rate limiting
;; to deliver a censorship-resistant social platform that prioritizes user sovereignty.
;;

;; ERROR CODES & PROTOCOL CONSTANTS

;; Protocol Error Definitions
(define-constant ERR_NOT_FOUND (err u100)) ;; Resource does not exist
(define-constant ERR_ALREADY_EXISTS (err u101)) ;; Duplicate resource creation
(define-constant ERR_UNAUTHORIZED (err u102)) ;; Access denied
(define-constant ERR_INVALID_INPUT (err u103)) ;; Malformed input parameters
(define-constant ERR_BLOCKED (err u104)) ;; User access blocked
(define-constant ERR_DEACTIVATED (err u105)) ;; Account deactivated
(define-constant ERR_RATE_LIMITED (err u106)) ;; Rate limit exceeded
(define-constant ERR_BATCH_FULL (err u107)) ;; Batch capacity reached
(define-constant ERR_BATCH_EXPIRED (err u108)) ;; Batch processing timeout

;; User Account Status Enumeration
(define-constant STATUS_DEACTIVATED u0) ;; Account suspended
(define-constant STATUS_ACTIVE u1) ;; Fully operational
(define-constant STATUS_SUSPENDED u2) ;; Temporarily restricted

;; Social Relationship Status Types
(define-constant FRIENDSHIP_PENDING u0) ;; Awaiting acceptance
(define-constant FRIENDSHIP_ACTIVE u1) ;; Confirmed connection
(define-constant FRIENDSHIP_BLOCKED u2) ;; Access denied

;; Rate Limiting Configuration Parameters
(define-constant MAX_ACTIONS_PER_DAY u100) ;; Daily action threshold
(define-constant MAX_FRIEND_REQUESTS_PER_DAY u20) ;; Friend request limit
(define-constant MAX_STATUS_UPDATES_PER_DAY u24) ;; Status update ceiling
(define-constant RATE_LIMIT_RESET_PERIOD u86400) ;; 24-hour reset cycle

;; Batch Processing Optimization Settings
(define-constant MIN_BATCH_SIZE u10) ;; Minimum batch efficiency
(define-constant MAX_BATCH_SIZE u100) ;; Maximum batch capacity
(define-constant BATCH_EXPIRY_PERIOD u3600) ;; 1-hour batch timeout

;; DATA STRUCTURES & STORAGE ARCHITECTURE

;; Primary User Identity Registry
;; Comprehensive user profile and identity management system
(define-map Users
  principal
  {
    name: (string-ascii 64), ;; Public display name
    status: uint, ;; Account status code
    timestamp: uint, ;; Registration timestamp
    metadata: (optional (string-utf8 256)), ;; Encrypted profile data
    deactivation-time: (optional uint), ;; Suspension timestamp
    encryption-key: (optional (buff 32)), ;; Client encryption key
    profile-image: (optional (string-utf8 256)), ;; Avatar URI/hash
  }
)

;; Advanced Privacy Control Matrix
;; Granular privacy configuration for comprehensive user control
(define-map UserPrivacy
  principal
  {
    friend-list-visible: bool, ;; Social graph visibility
    status-visible: bool, ;; Activity status sharing
    metadata-visible: bool, ;; Profile data exposure
    last-seen-visible: bool, ;; Online presence tracking
    profile-image-visible: bool, ;; Avatar display control
    encryption-enabled: bool, ;; E2E encryption toggle
    last-updated: uint, ;; Settings modification time
  }
)

;; Intelligent Rate Limiting Engine
;; Multi-tier action tracking for abuse prevention
(define-map RateLimits
  principal
  {
    daily-actions: uint, ;; Total daily actions
    friend-requests: uint, ;; Friend requests sent
    status-updates: uint, ;; Profile updates made
    last-reset: uint, ;; Counter reset timestamp
  }
)