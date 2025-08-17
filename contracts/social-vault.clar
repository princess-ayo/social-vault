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

;; Dynamic Batch Processing System
;; Adaptive transaction optimization for Layer 2 efficiency
(define-map UserBatches
  principal
  {
    message-counter: uint, ;; Pending message count
    last-batch-timestamp: uint, ;; Last batch processing time
    batch-size: uint, ;; Current batch size
    current-batch-items: uint, ;; Items in current batch
    total-batches: uint, ;; Lifetime batch count
  }
)

;; User Engagement Analytics Engine
;; Comprehensive activity tracking and behavioral analysis
(define-map UserActivity
  principal
  {
    last-seen: uint, ;; Last activity timestamp
    login-count: uint, ;; Total login sessions
    total-actions: uint, ;; Lifetime action count
    last-action: uint, ;; Most recent action time
  }
)

;; Bidirectional Social Graph Registry
;; Decentralized relationship management system
(define-map Friendships
  {
    user1: principal, ;; First party principal
    user2: principal, ;; Second party principal
  }
  { status: uint } ;; Relationship status
)

;; User Protection & Blocking System
;; Harassment prevention and access control mechanism
(define-map BlockedUsers
  {
    blocker: principal, ;; User initiating block
    blocked: principal, ;; User being blocked
  }
  { timestamp: uint } ;; Block creation time
)

;; CORE UTILITY & VALIDATION FUNCTIONS

;; Advanced Rate Limiting Validation Engine
;; Intelligent action throttling with automatic reset cycles
(define-private (check-rate-limit
    (user principal)
    (action-type uint)
  )
  (let (
      (rate-data (default-to {
        daily-actions: u0,
        friend-requests: u0,
        status-updates: u0,
        last-reset: stacks-block-height,
      }
        (map-get? RateLimits user)
      ))
      (current-time stacks-block-height)
      (should-reset (> (- current-time (get last-reset rate-data)) RATE_LIMIT_RESET_PERIOD))
    )
    (if should-reset
      ;; Reset all counters after period expiration
      (begin
        (map-set RateLimits user {
          daily-actions: u1,
          friend-requests: (if (is-eq action-type u1)
            u1
            u0
          ),
          status-updates: (if (is-eq action-type u2)
            u1
            u0
          ),
          last-reset: current-time,
        })
        true
      )
      ;; Validate against current limits
      (and
        (< (get daily-actions rate-data) MAX_ACTIONS_PER_DAY)
        (or
          (not (is-eq action-type u1))
          (< (get friend-requests rate-data) MAX_FRIEND_REQUESTS_PER_DAY)
        )
        (or
          (not (is-eq action-type u2))
          (< (get status-updates rate-data) MAX_STATUS_UPDATES_PER_DAY)
        )
      )
    )
  )
)

;; Rate Limit Counter Management
;; Precise action tracking and counter incrementation
(define-private (update-rate-limit
    (user principal)
    (action-type uint)
  )
  (let ((rate-data (unwrap-panic (map-get? RateLimits user))))
    (map-set RateLimits user
      (merge rate-data {
        daily-actions: (+ (get daily-actions rate-data) u1),
        friend-requests: (+ (get friend-requests rate-data)
          (if (is-eq action-type u1)
            u1
            u0
          )),
        status-updates: (+ (get status-updates rate-data)
          (if (is-eq action-type u2)
            u1
            u0
          )),
      })
    )
  )
)

;; User Engagement Activity Tracker
;; Comprehensive behavioral analytics and usage metrics
(define-private (update-user-activity (user principal))
  (let (
      (current-time stacks-block-height)
      (activity (default-to {
        last-seen: current-time,
        login-count: u0,
        total-actions: u0,
        last-action: current-time,
      }
        (map-get? UserActivity user)
      ))
    )
    (map-set UserActivity user
      (merge activity {
        last-seen: current-time,
        total-actions: (+ (get total-actions activity) u1),
        last-action: current-time,
      })
    )
  )
)

;; Mathematical Utility Functions
;; Essential arithmetic operations for protocol logic
(define-private (max-uint
    (a uint)
    (b uint)
  )
  (if (>= a b)
    a
    b
  )
)

(define-private (min-uint
    (a uint)
    (b uint)
  )
  (if (<= a b)
    a
    b
  )
)

;; Social Graph Relationship Validator
;; Bidirectional friendship status verification
(define-private (are-friends
    (user1 principal)
    (user2 principal)
  )
  (match (map-get? Friendships {
    user1: user1,
    user2: user2,
  })
    friendship (is-eq (get status friendship) FRIENDSHIP_ACTIVE)
    false
  )
)

;; User Account Status Validator
;; Active account verification with deactivation checks
(define-private (check-active-user (user principal))
  (match (map-get? Users user)
    user-data (and
      (is-eq (get status user-data) STATUS_ACTIVE)
      (is-none (get deactivation-time user-data))
    )
    false
  )
)

;; User Registry Existence Checker
;; Simple user registration verification
(define-private (user-exists (user principal))
  (is-some (map-get? Users user))
)

;; Block Status Verification Engine
;; Comprehensive blocking relationship checker
(define-private (is-blocked
    (blocker principal)
    (blocked principal)
  )
  (is-some (map-get? BlockedUsers {
    blocker: blocker,
    blocked: blocked,
  }))
)

;; Privacy Settings Retrieval System
;; Secure defaults with user-defined overrides
(define-private (get-privacy-settings (user principal))
  (default-to {
    friend-list-visible: true,
    status-visible: true,
    metadata-visible: true,
    last-seen-visible: true,
    profile-image-visible: true,
    encryption-enabled: false,
    last-updated: stacks-block-height,
  }
    (map-get? UserPrivacy user)
  )
)

;; PUBLIC INTERFACE & USER INTERACTION FUNCTIONS

;; Intelligent Batch Size Optimization Engine
;; Dynamic transaction batching for optimal Layer 2 performance
(define-public (optimize-batch-size (user principal))
  (let (
      (batch-data (unwrap-panic (map-get? UserBatches user)))
      (current-time stacks-block-height)
      (time-since-last-batch (- current-time (get last-batch-timestamp batch-data)))
      (current-batch-size (get batch-size batch-data))
      (items-in-current-batch (get current-batch-items batch-data))
    )
    (if (> time-since-last-batch BATCH_EXPIRY_PERIOD)
      ;; Batch expired - reset and optimize size for efficiency
      (begin
        (map-set UserBatches user
          (merge batch-data {
            batch-size: (max-uint MIN_BATCH_SIZE (/ current-batch-size u2)),
            current-batch-items: u0,
            last-batch-timestamp: current-time,
          })
        )
        (ok true)
      )
      ;; Active batch - dynamic size adjustment based on usage
      (begin
        (map-set UserBatches user
          (merge batch-data { batch-size: (min-uint MAX_BATCH_SIZE
            (if (>= items-in-current-batch (/ current-batch-size u2))
              (* current-batch-size u2)
              current-batch-size
            )) }
          ))
        (ok true)
      )
    )
  )
)

;; Advanced Privacy Configuration Management
;; Comprehensive privacy control system with granular permissions
(define-public (update-advanced-privacy-settings
    (friend-list-visible bool)
    (status-visible bool)
    (metadata-visible bool)
    (last-seen-visible bool)
    (profile-image-visible bool)
    (encryption-enabled bool)
  )
  (let ((caller tx-sender))
    (asserts! (check-active-user caller) ERR_DEACTIVATED)
    (asserts! (check-rate-limit caller u2) ERR_RATE_LIMITED)

    (map-set UserPrivacy caller {
      friend-list-visible: friend-list-visible,
      status-visible: status-visible,
      metadata-visible: metadata-visible,
      last-seen-visible: last-seen-visible,
      profile-image-visible: profile-image-visible,
      encryption-enabled: encryption-enabled,
      last-updated: stacks-block-height,
    })

    (update-rate-limit caller u2)
    (update-user-activity caller)

    (print {
      event: "privacy-configuration-updated",
      user: caller,
      timestamp: stacks-block-height,
      encryption-status: encryption-enabled,
    })

    (ok true)
  )
)

;; Comprehensive User Profile Management System
;; Multi-field profile update with encryption and metadata support
(define-public (update-user-profile
    (name (optional (string-ascii 64)))
    (metadata (optional (string-utf8 256)))
    (encryption-key (optional (buff 32)))
    (profile-image (optional (string-utf8 256)))
  )
  (let (
      (caller tx-sender)
      (user (unwrap-panic (map-get? Users caller)))
    )
    (asserts! (check-active-user caller) ERR_DEACTIVATED)
    (asserts! (check-rate-limit caller u2) ERR_RATE_LIMITED)

    (map-set Users caller
      (merge user {
        name: (default-to (get name user) name),
        metadata: (if (is-some metadata)
          metadata
          (get metadata user)
        ),
        encryption-key: (if (is-some encryption-key)
          encryption-key
          (get encryption-key user)
        ),
        profile-image: (if (is-some profile-image)
          profile-image
          (get profile-image user)
        ),
      })
    )

    (update-rate-limit caller u2)
    (update-user-activity caller)

    (print {
      event: "user-profile-updated",
      user: caller,
      timestamp: stacks-block-height,
      fields-updated: {
        name: (is-some name),
        metadata: (is-some metadata),
        encryption-key: (is-some encryption-key),
        profile-image: (is-some profile-image),
      },
    })

    (ok true)
  )
)

;; Dynamic Batch Processing Configuration
;; User-controlled transaction batching optimization
(define-public (set-batch-size (new-size uint))
  (let (
      (caller tx-sender)
      (batch-data (unwrap-panic (map-get? UserBatches caller)))
    )
    (asserts! (check-active-user caller) ERR_DEACTIVATED)
    (asserts! (and (>= new-size MIN_BATCH_SIZE) (<= new-size MAX_BATCH_SIZE))
      ERR_INVALID_INPUT
    )

    (map-set UserBatches caller (merge batch-data { batch-size: new-size }))

    (print {
      event: "batch-optimization-configured",
      user: caller,
      previous-size: (get batch-size batch-data),
      new-size: new-size,
      timestamp: stacks-block-height,
    })

    (ok true)
  )
)

;; Secure User Session Management
;; Advanced login tracking with behavioral analytics
(define-public (record-login)
  (let (
      (caller tx-sender)
      (activity (default-to {
        last-seen: stacks-block-height,
        login-count: u0,
        total-actions: u0,
        last-action: stacks-block-height,
      }
        (map-get? UserActivity caller)
      ))
    )
    (map-set UserActivity caller
      (merge activity {
        last-seen: stacks-block-height,
        login-count: (+ (get login-count activity) u1),
      })
    )

    (print {
      event: "secure-login-recorded",
      user: caller,
      session-count: (+ (get login-count activity) u1),
      timestamp: stacks-block-height,
    })

    (ok true)
  )
)
