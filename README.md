# SoundStream 🎵🎨

A decentralized music rights management system built on Stacks blockchain, enabling musicians to register their tracks as NFTs, manage royalties, and control streaming permissions with full transparency and multi-artist collaboration support.

## 🌟 Key Features

### 🎤 **Track Management**
- **Solo Track Registration**: Artists can register individual tracks with custom pricing
- **Collaboration Tracks**: Support for up to 10 collaborators per track with automatic royalty splits
- **Dynamic Pricing**: Update streaming prices anytime
- **Track Status Control**: Enable/disable track availability instantly
- **Multi-Artist Support**: Seamless collaboration with transparent revenue sharing

### 🎨 **NFT Integration**
- **Track-to-NFT Conversion**: Transform any track into a unique, collectible NFT
- **Free Streaming for Holders**: NFT owners enjoy unlimited free streaming
- **Streaming Rights Control**: Toggle streaming privileges on/off
- **Complete Provenance**: Immutable ownership history tracking
- **SIP-009 Compliance**: Full compatibility with Stacks NFT standards
- **Transferable Benefits**: Streaming rights transfer with NFT ownership

### 💰 **Advanced Payment System**
- **Batch Streaming Credits**: Purchase 5-1000 streaming credits in bulk with **10% discount**
- **Prepaid Streaming**: Use credits for friction-free streaming without per-transaction payments
- **Automatic Royalty Distribution**: Payments split instantly based on predefined percentages
- **Real-time Earnings**: Transparent tracking of individual artist earnings
- **NFT-Enhanced Pricing**: Multiple payment tiers (NFT holders, credit users, pay-per-stream)
- **Revenue Predictability**: Artists receive upfront payment for bulk credit purchases

### 📊 **Analytics & Insights**
- **Stream Analytics**: Real-time tracking of streams per track and artist
- **Listener Profiles**: Track individual streaming patterns and credit balances
- **Platform Statistics**: Global stream counts and platform metrics
- **Artist Performance**: Detailed earnings and stream data per artist
- **NFT Analytics**: Ownership patterns and streaming benefit utilization
- **Credit Monitoring**: Real-time balance tracking for all listeners

### 🔒 **Security & Validation**
- **Comprehensive Input Validation**: All parameters validated for security
- **Artist Authorization**: Only track owners/collaborators can modify tracks
- **Principal Validation**: Prevents invalid wallet addresses
- **Payment Security**: Secure STX token transfers with failure handling
- **NFT Transfer Protection**: Protected NFT minting and transfer operations
- **Credit Security**: Secure balance management with timestamp tracking

## 💡 How It Works

### For Solo Artists
1. **Register Track**: Use `register-track` with title, album, duration, and price
2. **Mint NFT** (Optional): Convert track to NFT using `mint-track-nft` for collectible value
3. **Set Pricing**: Define per-stream cost in STX tokens
4. **Manage Availability**: Toggle track active/inactive status
5. **Monitor Performance**: Track streams, earnings, and credit purchases in real-time

### For Collaborations
1. **Create Collaboration**: Use `register-collaboration-track` with all collaborators and splits
2. **Define Splits**: Set royalty percentages that sum to exactly 100%
3. **Add Members**: Add new collaborators to existing tracks dynamically
4. **Shared Control**: All collaborators can update pricing
5. **NFT Benefits**: Primary artist can mint NFT for collaborative tracks

### For Listeners
1. **Discover Tracks**: Browse available tracks by ID
2. **Choose Payment Method**:
   - **Pay-per-Stream**: Use `stream-track` for single streams
   - **Bulk Credits**: Buy 5-1000 credits with `purchase-streaming-credits` (10% off)
   - **NFT Ownership**: Purchase track NFTs for unlimited free streaming
3. **Stream Efficiently**: Use `stream-with-credits` for prepaid streaming
4. **Track Activity**: Monitor streaming history and credit balance
5. **Support Artists**: Direct payments with zero intermediaries

### For NFT Collectors
1. **Mint Track NFTs**: Artists convert tracks into unique collectible NFTs
2. **Free Streaming**: NFT owners stream associated tracks at no cost
3. **Transfer Rights**: Trade NFTs with full streaming privileges included
4. **Control Access**: Toggle streaming rights on/off as desired
5. **Build Collection**: Accumulate NFTs from favorite artists

## 📖 Contract Functions

### 🎵 **Track Registration**

#### `register-track`
```clarity
(register-track title album duration price-per-stream)
```
Register a solo track with metadata and pricing.

**Parameters:**
- `title`: Track title (max 100 characters)
- `album`: Album name (max 100 characters)
- `duration`: Track duration in seconds
- `price-per-stream`: Cost per stream in micro-STX (1-1,000,000)

**Returns:** `(ok track-id)` or error

**Example:**
```clarity
(contract-call? .soundstream register-track "Summer Nights" "Debut Album" u240 u100)
```

---

#### `register-collaboration-track`
```clarity
(register-collaboration-track title album duration price collaborators royalty-splits)
```
Register a collaborative track with multiple artists and automatic royalty distribution.

**Parameters:**
- `title`: Track title (max 100 characters)
- `album`: Album name (max 100 characters)
- `duration`: Track duration in seconds
- `price`: Cost per stream in micro-STX
- `collaborators`: List of artist principals (max 10)
- `royalty-splits`: List of percentages (must sum to 100)

**Returns:** `(ok track-id)` or error

**Example:**
```clarity
(contract-call? .soundstream register-collaboration-track 
  "Epic Collab" 
  "Joint Album" 
  u300 
  u150
  (list 'SP123... 'SP456... 'SP789...)
  (list u40 u35 u25))
```

---

### 🎨 **NFT Operations**

#### `mint-track-nft`
```clarity
(mint-track-nft track-id token-uri)
```
Convert a track into a unique SIP-009 compliant NFT (primary artist only).

**Parameters:**
- `track-id`: ID of the track to convert
- `token-uri`: Metadata URI (max 256 characters)

**Returns:** `(ok nft-id)` or error

**Example:**
```clarity
(contract-call? .soundstream mint-track-nft u1 "ipfs://QmXx.../metadata.json")
```

---

#### `transfer-track-nft`
```clarity
(transfer-track-nft nft-id sender recipient)
```
Transfer NFT ownership along with streaming privileges.

**Parameters:**
- `nft-id`: ID of the NFT to transfer
- `sender`: Current owner's principal
- `recipient`: New owner's principal

**Returns:** `(ok true)` or error

---

#### `toggle-nft-streaming-rights`
```clarity
(toggle-nft-streaming-rights nft-id)
```
Enable/disable streaming benefits for NFT holders (owner only).

**Returns:** `(ok true)` or error

---

### 💳 **Streaming & Payments**

#### `stream-track`
```clarity
(stream-track track-id)
```
Stream a track with automatic payment distribution. NFT owners stream for free.

**Payment Logic:**
- NFT owners with streaming rights enabled: **FREE**
- Regular listeners: Pay `price-per-stream`
- Automatic royalty distribution to all collaborators

**Returns:** `(ok true)` or error

**Example:**
```clarity
(contract-call? .soundstream stream-track u1)
```

---

#### `purchase-streaming-credits`
```clarity
(purchase-streaming-credits track-id quantity)
```
Purchase streaming credits in bulk (min 5, max 1000) with automatic 10% discount.

**Parameters:**
- `track-id`: Track to purchase credits for
- `quantity`: Number of credits (5-1000)

**Pricing:**
- Base price: `quantity * price-per-stream`
- Discount: 10% off total
- Final price: `base * 0.9`

**Returns:** `(ok quantity)` or error

**Example:**
```clarity
;; Buy 20 credits for track #1 (100 micro-STX per stream)
;; Regular price: 20 * 100 = 2000
;; With 10% discount: 1800 micro-STX
(contract-call? .soundstream purchase-streaming-credits u1 u20)
```

---

#### `stream-with-credits`
```clarity
(stream-with-credits track-id)
```
Stream a track using pre-purchased credits (no additional payment required).

**Requirements:**
- Must have at least 1 credit balance
- Deducts 1 credit per stream

**Returns:** `(ok true)` or error

**Example:**
```clarity
(contract-call? .soundstream stream-with-credits u1)
```

---

### ⚙️ **Track Management**

#### `update-track-price`
```clarity
(update-track-price track-id new-price)
```
Update streaming price (owner/collaborators only).

**Parameters:**
- `track-id`: Track to update
- `new-price`: New price in micro-STX (1-1,000,000)

**Returns:** `(ok true)` or error

---

#### `toggle-track-status`
```clarity
(toggle-track-status track-id)
```
Enable/disable track availability (primary artist only).

**Returns:** `(ok true)` or error

---

#### `add-collaborator`
```clarity
(add-collaborator track-id collaborator royalty-percentage)
```
Add a new collaborator to an existing track (primary artist only).

**Requirements:**
- Total collaborators must be ≤ 10
- Total royalty percentages must not exceed 100%

**Returns:** `(ok true)` or error

---

### 📊 **Analytics & Queries**

#### `get-track`
```clarity
(get-track track-id)
```
Retrieve complete track information including NFT status.

**Returns:** Track data or `none`

---

#### `get-track-nft`
```clarity
(get-track-nft nft-id)
```
Get NFT metadata and ownership information.

**Returns:** NFT data or `none`

---

#### `get-artist-earnings`
```clarity
(get-artist-earnings artist)
```
View artist's total earnings and stream count.

**Returns:** `{total-earned: uint, total-streams: uint}` or `none`

---

#### `get-stream-history`
```clarity
(get-stream-history listener track-id)
```
Get listener's streaming history for a specific track.

**Returns:** `{stream-count: uint, last-streamed: uint}` or `none`

---

#### `get-streaming-credits`
```clarity
(get-streaming-credits listener)
```
Check available streaming credits for a listener.

**Returns:** `{credits: uint, last-updated: uint}` or `none`

**Example:**
```clarity
(contract-call? .soundstream get-streaming-credits tx-sender)
;; Returns: (some {credits: u15, last-updated: u12345})
```

---

#### `calculate-batch-price`
```clarity
(calculate-batch-price quantity base-price)
```
Calculate discounted price for bulk credit purchase before committing.

**Parameters:**
- `quantity`: Number of credits (5-1000)
- `base-price`: Price per stream

**Returns:** `(ok discounted-price)` or error

**Example:**
```clarity
(contract-call? .soundstream calculate-batch-price u50 u100)
;; Returns: (ok u4500) ; 50 * 100 * 0.9 = 4500
```

---

#### `get-track-collaborator`
```clarity
(get-track-collaborator track-id collaborator)
```
View collaborator details and royalty percentage.

---

#### `get-collaboration-summary`
```clarity
(get-collaboration-summary track-id)
```
Get collaboration overview (total collaborators, total percentage).

---

#### `calculate-stream-cost`
```clarity
(calculate-stream-cost track-id)
```
Calculate cost to stream a specific track.

---

#### `get-nft-ownership-history`
```clarity
(get-nft-ownership-history nft-id owner)
```
Retrieve NFT ownership history and transfer records.

---

### 🔍 **SIP-009 Compliance Functions**

#### `get-token-uri`
```clarity
(get-token-uri nft-id)
```
Get NFT metadata URI (standard NFT function).

---

#### `get-last-token-id`
```clarity
(get-last-token-id)
```
Get the most recently minted NFT ID.

---

#### `get-owner`
```clarity
(get-owner nft-id)
```
Get current owner of a specific NFT.

---

## 🎯 Technical Specifications

### **Blockchain Infrastructure**
- **Platform**: Stacks Blockchain
- **Language**: Clarity Smart Contract
- **Payment Token**: STX
- **NFT Standard**: SIP-009 Compliant
- **Storage**: On-chain metadata and analytics

### **System Limits**
| Parameter | Limit |
|-----------|-------|
| Max Collaborators | 10 per track |
| Title/Album Length | 100 characters |
| Token URI Length | 256 characters |
| Price Range | 1 - 1,000,000 micro-STX |
| Royalty Range | 0-100% (must sum to 100%) |
| Batch Credits Min | 5 streams |
| Batch Credits Max | 1,000 streams |
| Batch Discount | 10% off |

### **Data Structures**
- **Track Counter**: Global track ID management
- **NFT Counter**: Sequential NFT ID assignment
- **Stream History**: Per-listener tracking with timestamps
- **Artist Earnings**: Cumulative earnings and stream counts
- **Collaboration Data**: Multi-artist royalty management
- **NFT Metadata**: Token URI, ownership, and streaming rights
- **Ownership History**: Complete NFT transfer provenance
- **Streaming Credits**: Prepaid credit balances per listener with last-updated timestamps

## 💎 Batch Credits System

### **How It Works**
1. **Purchase Credits**: Buy minimum 5 streaming credits for any track
2. **Get Discount**: Automatic 10% discount applied to all bulk purchases
3. **Use Anytime**: Credits work for streaming the purchased track
4. **Track Balance**: Monitor remaining credits in real-time with `get-streaming-credits`
5. **Flexible Spending**: Use credits as needed without per-stream transaction fees

### **Benefits**

#### **For Listeners:**
- 💰 **Save 10%** on every bulk purchase
- ⚡ **Instant Streaming** - no transaction delays
- 📊 **Budget Control** - prepay for predictable costs
- 🎵 **Better UX** - seamless streaming experience

#### **For Artists:**
- 💵 **Upfront Payment** - receive revenue immediately
- 📈 **Predictable Income** - know exactly how much fans have committed
- 🎯 **Fan Loyalty** - encourage long-term engagement
- 🔄 **Reduced Overhead** - fewer micro-transactions to process

### **Pricing Examples**

| Credits | Regular Price | With 10% Discount | Savings |
|---------|--------------|-------------------|---------|
| 5 | 500 μSTX | 450 μSTX | 50 μSTX |
| 10 | 1,000 μSTX | 900 μSTX | 100 μSTX |
| 25 | 2,500 μSTX | 2,250 μSTX | 250 μSTX |
| 50 | 5,000 μSTX | 4,500 μSTX | 500 μSTX |
| 100 | 10,000 μSTX | 9,000 μSTX | 1,000 μSTX |

*Based on 100 micro-STX per stream*

### **Use Case Example**

```clarity
;; Step 1: Check current price
(contract-call? .soundstream calculate-stream-cost u1)
;; Returns: (ok u100)

;; Step 2: Calculate bulk discount
(contract-call? .soundstream calculate-batch-price u20 u100)
;; Returns: (ok u1800) ; Save 200 μSTX!

;; Step 3: Purchase credits
(contract-call? .soundstream purchase-streaming-credits u1 u20)
;; Returns: (ok u20)

;; Step 4: Check balance
(contract-call? .soundstream get-streaming-credits tx-sender)
;; Returns: (some {credits: u20, last-updated: u12345})

;; Step 5: Stream using credits (repeat 20 times)
(contract-call? .soundstream stream-with-credits u1)
;; Returns: (ok true) ; No payment required!

;; Step 6: Check remaining balance
(contract-call? .soundstream get-streaming-credits tx-sender)
;; Returns: (some {credits: u19, last-updated: u12346})
```

## 🎨 NFT Integration Benefits

### **For Artists**
- 💰 **New Revenue Stream**: Monetize tracks through NFT sales
- 🤝 **Fan Engagement**: Offer exclusive streaming benefits to supporters
- 🎁 **Collectible Value**: Create scarcity and collectible appeal
- 📊 **Royalty Control**: Maintain ongoing streaming revenue even after NFT sale
- 🌟 **Premium Positioning**: Position tracks as collectible art

### **For Collectors**
- 🎵 **Utility Value**: NFTs provide actual streaming benefits, not just ownership
- 💵 **Cost Savings**: Free streaming for owned tracks over time
- ❤️ **Supporting Artists**: Direct support through NFT purchases
- 🔄 **Transferable Rights**: Sell NFTs with streaming privileges intact
- 📈 **Investment Potential**: Rare music NFTs may appreciate in value

### **For the Ecosystem**
- ⚡ **Reduced Friction**: NFT holders don't need to pay per stream
- 🎯 **Increased Engagement**: Ownership creates stronger connection to music
- 🏪 **Market Dynamics**: Creates secondary market for music rights
- 🚀 **Innovation Showcase**: Demonstrates practical NFT utility beyond speculation
- 🌐 **Cross-Platform Value**: NFTs can be displayed across platforms

## 🛡️ Security Features

### **Input Validation**
✅ String length validation for titles, albums, and token URIs  
✅ Price range validation (prevents zero or excessive pricing)  
✅ Principal validation (prevents invalid wallet addresses)  
✅ Royalty percentage validation (0-100% range, must sum to 100%)  
✅ NFT ID validation and existence checks  
✅ Credit quantity validation (5-1000 range)  
✅ Track ID bounds checking  

### **Access Controls**
🔐 Owner-only functions for sensitive operations  
🔐 Collaborator verification for track modifications  
🔐 Primary artist privileges for NFT minting and collaborator addition  
🔐 NFT owner-only streaming rights management  
🔐 Protected credit balance modifications  

### **Payment Security**
💳 Atomic STX transfers with failure handling  
💳 Automatic royalty distribution to all collaborators  
💳 Protected against insufficient payment errors  
💳 NFT transfer protection with ownership verification  
💳 Secure credit purchase and deduction with overflow protection  

### **NFT Security**
🎨 SIP-009 standard compliance for interoperability  
🎨 Secure minting with duplicate prevention  
🎨 Protected transfer mechanisms  
🎨 Ownership history immutability  
🎨 Streaming rights toggle protection  

## ⚠️ Error Handling

The contract includes comprehensive error codes for debugging:

| Code | Error | Description |
|------|-------|-------------|
| `u100` | `err-owner-only` | Owner-only access violation |
| `u101` | `err-not-found` | Resource not found |
| `u102` | `err-already-exists` | Resource already exists |
| `u103` | `err-unauthorized` | Unauthorized access |
| `u104` | `err-invalid-price` | Invalid price range |
| `u105` | `err-insufficient-payment` | Insufficient payment |
| `u106` | `err-invalid-royalty` | Invalid royalty percentage |
| `u107` | `err-transfer-failed` | Transfer failed |
| `u108` | `err-invalid-collaborators` | Invalid collaborators |
| `u109` | `err-invalid-splits` | Invalid royalty splits |
| `u110` | `err-max-collaborators-exceeded` | Maximum collaborators exceeded |
| `u111` | `err-nft-not-found` | NFT not found |
| `u112` | `err-nft-already-minted` | NFT already minted for track |
| `u113` | `err-invalid-token-uri` | Invalid token URI format |
| `u114` | `err-nft-transfer-failed` | NFT transfer operation failed |
| `u115` | `err-invalid-quantity` | Invalid quantity (must be 5-1000) |
| `u116` | `err-insufficient-credits` | Insufficient streaming credits |

## 🚀 Getting Started

### **For Artists**
1. 📝 Deploy the SoundStream contract to Stacks
2. 🎵 Register your tracks using `register-track` or `register-collaboration-track`
3. 🎨 Mint NFTs for special tracks using `mint-track-nft`
4. 💰 Set competitive pricing for your streams
5. 📊 Monitor earnings through `get-artist-earnings`
6. 🎯 Encourage fans to purchase bulk credits for better engagement

### **For Developers**
1. 📦 Import the contract into your Stacks project
2. 🔧 Integrate streaming, NFT, and credit functionality
3. 📖 Use read-only functions for analytics and discovery
4. 🎨 Build user interfaces around the public functions
5. 🏪 Implement NFT marketplace features
6. 💳 Create credit purchase and management UI

### **For Collectors**
1. 👛 Connect your Stacks wallet
2. 🔍 Browse tracks and available NFTs
3. 🛒 Purchase NFTs for streaming benefits
4. 🎵 Stream music via `stream-track` with automatic discounts
5. 💱 Trade NFTs in secondary markets
6. 📈 Monitor your collection value

### **For Listeners**
1. 👛 Connect your Stacks wallet
2. 🔍 Browse tracks using `get-track` function
3. 🎵 Choose your preferred payment method:
   - **One-time**: `stream-track` for single streams
   - **Bulk Credits**: `purchase-streaming-credits` (save 10%)
   - **NFT**: Buy NFTs for unlimited free streaming
4. ⚡ Use `stream-with-credits` for prepaid streaming
5. 📊 Track your listening history and credit balance
6. ❤️ Support your favorite artists directly

## 💼 Use Cases & Examples

### **Artist Revenue Optimization**
- 🎨 Release limited edition NFTs for popular tracks
- ⏰ Offer early access through NFT ownership
- 🎯 Create tiered pricing (NFT holders vs credit users vs pay-per-stream)
- 📀 Bundle multiple track NFTs for album collections
- 💳 Encourage bulk credit purchases for loyal fans
- 🎁 Offer credit bonuses for superfans

### **Fan Engagement**
- 👑 VIP streaming access through NFT ownership
- 🎁 Exclusive content for NFT holders
- 🏆 Fan club membership via NFT collections
- 🤝 Artist-fan direct connection through blockchain
- 💰 Prepaid credits for dedicated superfans
- 🎫 Special perks tied to credit purchase history

### **Music Investment**
- 📈 Collect NFTs from emerging artists
- 🎵 Benefit from free streaming of owned tracks
- 💎 Potential appreciation of rare music NFTs
- 📊 Portfolio diversification through music assets
- 💰 Long-term value through streaming credits
- 🔄 Resell NFTs with streaming rights intact

### **Platform Innovation**
- 🌐 Create music streaming dApp with built-in NFT marketplace
- 📱 Build mobile apps with wallet-integrated streaming
- 📊 Develop analytics dashboards for artists
- 🎮 Gamify listening experience with credit rewards
- 🏪 Launch NFT marketplace specifically for music rights
- 🤖 Implement AI-driven track recommendations based on ownership

## 🗺️ Future Roadmap

- ✅ **NFT Integration**: Convert tracks into unique NFTs with streaming rights
- ✅ **Batch Credits System**: Purchase streaming credits in bulk with discounts
- 🔜 **Playlist NFTs**: Create and monetize curated playlists as NFTs
- 🔜 **Fan Engagement Tokens**: Loyalty tokens for frequent listeners of specific artists
- 🔜 **Advanced Analytics Dashboard**: Detailed demographic and geographic streaming data
- 🔜 **Label Management System**: Multi-artist management for record labels
- 🔜 **Concert Ticket Integration**: Link NFT ownership to concert ticket discounts
- 🔜 **Cross-Platform Streaming**: Integration with traditional streaming platforms
- 🔜 **Artist Verification System**: Blue check verification for legitimate artists
- 🔜 **Social Features**: Following artists, sharing tracks, and community building
- 🔜 **Royalty Marketplace**: Trade future royalty streams as financial instruments
- 🔜 **Credit Gifting**: Send streaming credits to other users
- 🔜 **Subscription Models**: Monthly credit packages with additional discounts
