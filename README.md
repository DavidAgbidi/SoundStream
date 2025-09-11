# SoundStream 🎵🎨

A decentralized music rights management system built on Stacks blockchain, enabling musicians to register their tracks as NFTs, manage royalties, and control streaming permissions with full transparency and multi-artist collaboration support.

## Features

### 🎤 **Track Management**
- **Solo Track Registration**: Artists can register individual tracks with custom pricing
- **Collaboration Tracks**: Support for up to 10 collaborators per track with custom royalty splits
- **Dynamic Pricing**: Artists can update streaming prices for their tracks
- **Track Status Control**: Enable/disable track availability

### 🎨 **NFT Integration**
- **Track-to-NFT Conversion**: Convert any track into a unique NFT with streaming rights
- **NFT Ownership Benefits**: NFT holders can stream tracks for free
- **Streaming Rights Control**: NFT owners can enable/disable streaming privileges
- **Ownership History Tracking**: Complete provenance tracking for all NFT transfers
- **SIP-009 Compliance**: Full compatibility with Stacks NFT standards

### 💰 **Advanced Royalty System**
- **Automatic Split Distribution**: Payments automatically distributed based on predefined royalty percentages
- **Real-time Earnings Tracking**: Transparent tracking of individual artist earnings
- **Collaboration Management**: Add new collaborators to existing tracks
- **Validation System**: Ensures royalty splits total exactly 100%
- **NFT-Enhanced Royalties**: Different pricing tiers for NFT holders vs regular listeners

### 📊 **Analytics & Insights**
- **Stream Analytics**: Real-time tracking of streams per track and artist
- **Listener History**: Track individual listener streaming patterns
- **Platform Statistics**: Global stream counts and platform metrics
- **Artist Performance**: Detailed earnings and stream data per artist
- **NFT Analytics**: Track NFT ownership patterns and streaming benefits

### 🔒 **Security & Validation**
- **Comprehensive Input Validation**: All parameters validated for security
- **Artist Authorization**: Only track owners/collaborators can modify tracks
- **Principal Validation**: Prevents invalid wallet addresses
- **Payment Security**: Secure STX token transfers with failure handling
- **NFT Transfer Security**: Protected NFT minting and transfer operations

## How It Works

### For Solo Artists
1. **Register Track**: Use `register-track` with title, album, duration, and price
2. **Mint NFT**: Convert track to NFT using `mint-track-nft`
3. **Set Pricing**: Define per-stream cost in STX tokens
4. **Manage Availability**: Toggle track active/inactive status
5. **Monitor Performance**: Track streams and earnings in real-time

### For Collaborations
1. **Create Collaboration**: Use `register-collaboration-track` with all collaborators
2. **Define Splits**: Set royalty percentages that sum to 100%
3. **Add Members**: Add new collaborators to existing tracks
4. **Shared Control**: Collaborators can update pricing and manage tracks
5. **NFT Benefits**: Primary artist can mint NFT for collaborative tracks

### For Listeners
1. **Discover Tracks**: Browse available tracks by ID
2. **Stream Music**: Pay artists directly via `stream-track`
3. **Purchase NFTs**: Buy NFTs for unlimited streaming access
4. **Track History**: View personal streaming history
5. **Support Artists**: Direct payments with no intermediaries

### For NFT Collectors
1. **Mint Track NFTs**: Artists can convert tracks into collectible NFTs
2. **Free Streaming**: NFT owners stream associated tracks at no cost
3. **Transfer Rights**: Trade NFTs with full streaming privileges
4. **Control Access**: Toggle streaming rights on/off
5. **Build Collection**: Accumulate NFTs from favorite artists

## Contract Functions

### 🎵 **Track Registration**
```clarity
(register-track title album duration price-per-stream)
```
Register a solo track with metadata and pricing.

```clarity
(register-collaboration-track title album duration price collaborators royalty-splits)
```
Register a collaborative track with multiple artists and split percentages.

### 🎨 **NFT Operations**
```clarity
(mint-track-nft track-id token-uri)
```
Convert a track into a unique NFT with streaming rights (primary artist only).

```clarity
(transfer-track-nft nft-id sender recipient)
```
Transfer NFT ownership along with streaming privileges.

```clarity
(toggle-nft-streaming-rights nft-id)
```
Enable/disable streaming benefits for NFT holders (owner only).

### 🎧 **Streaming & Payments**
```clarity
(stream-track track-id)
```
Stream a track with automatic payment distribution. NFT owners stream for free.

### ⚙️ **Track Management**
```clarity
(update-track-price track-id new-price)
```
Update streaming price (owner/collaborators only).

```clarity
(toggle-track-status track-id)
```
Enable/disable track availability (primary artist only).

```clarity
(add-collaborator track-id collaborator royalty-percentage)
```
Add a new collaborator to an existing track (primary artist only).

### 📊 **Analytics & Queries**
```clarity
(get-track track-id)
```
Retrieve complete track information including NFT status.

```clarity
(get-track-nft nft-id)
```
Get NFT metadata and ownership information.

```clarity
(get-artist-earnings artist)
```
View artist's total earnings and stream count.

```clarity
(get-stream-history listener track-id)
```
Get listener's streaming history for a specific track.

```clarity
(get-track-collaborator track-id collaborator)
```
View collaborator details and royalty percentage.

```clarity
(get-collaboration-summary track-id)
```
Get collaboration overview (total collaborators, total percentage).

```clarity
(calculate-stream-cost track-id)
```
Calculate cost to stream a specific track.

```clarity
(get-nft-ownership-history nft-id owner)
```
Retrieve NFT ownership history and transfer records.

### 🔍 **SIP-009 Compliance Functions**
```clarity
(get-token-uri nft-id)
```
Get NFT metadata URI (standard NFT function).

```clarity
(get-last-token-id)
```
Get the most recently minted NFT ID.

```clarity
(get-owner nft-id)
```
Get current owner of a specific NFT.

## Technical Specifications

### **Blockchain Infrastructure**
- **Platform**: Stacks Blockchain
- **Language**: Clarity Smart Contract
- **Payment Token**: STX
- **NFT Standard**: SIP-009 Compliant
- **Storage**: On-chain metadata and analytics

### **System Limits**
- **Max Collaborators**: 10 per track
- **Title/Album Length**: 100 characters maximum
- **Token URI Length**: 256 characters maximum
- **Price Range**: 1 to 1,000,000 micro-STX
- **Royalty Range**: 0-100% (must sum to exactly 100% for collaborations)

### **Data Structures**
- **Track Counter**: Global track ID management
- **NFT Counter**: Sequential NFT ID assignment
- **Stream History**: Per-listener tracking
- **Artist Earnings**: Cumulative earnings and stream counts
- **Collaboration Data**: Multi-artist royalty management
- **NFT Metadata**: Token URI, ownership, and streaming rights
- **Ownership History**: Complete NFT transfer provenance

## NFT Integration Benefits

### **For Artists**
- **New Revenue Stream**: Monetize tracks through NFT sales
- **Fan Engagement**: Offer exclusive streaming benefits to supporters
- **Collectible Value**: Create scarcity and collectible appeal
- **Royalty Control**: Maintain ongoing streaming revenue even after NFT sale

### **For Collectors**
- **Utility Value**: NFTs provide actual streaming benefits, not just ownership
- **Cost Savings**: Free streaming for owned tracks over time
- **Supporting Artists**: Direct support through NFT purchases
- **Transferable Rights**: Can sell NFTs with streaming privileges intact

### **For the Ecosystem**
- **Reduced Friction**: NFT holders don't need to pay per stream
- **Increased Engagement**: Ownership creates stronger connection to music
- **Market Dynamics**: Creates secondary market for music rights
- **Innovation Showcase**: Demonstrates practical NFT utility beyond speculation

## Security Features

### **Input Validation**
- String length validation for titles, albums, and token URIs
- Price range validation (prevents zero or excessive pricing)
- Principal validation (prevents invalid wallet addresses)
- Royalty percentage validation (0-100% range)
- NFT ID validation and existence checks

### **Access Controls**
- Owner-only functions for sensitive operations
- Collaborator verification for track modifications
- Primary artist privileges for NFT minting and collaborator addition
- NFT owner-only streaming rights management

### **Payment Security**
- Atomic STX transfers with failure handling
- Automatic royalty distribution
- Protected against insufficient payment errors
- NFT transfer protection with ownership verification

### **NFT Security**
- SIP-009 standard compliance for interoperability
- Secure minting with duplicate prevention
- Protected transfer mechanisms
- Ownership history immutability

## Error Handling

The contract includes comprehensive error codes:
- `u100`: Owner-only access violation
- `u101`: Resource not found
- `u102`: Resource already exists
- `u103`: Unauthorized access
- `u104`: Invalid price range
- `u105`: Insufficient payment
- `u106`: Invalid royalty percentage
- `u107`: Transfer failed
- `u108`: Invalid collaborators
- `u109`: Invalid royalty splits
- `u110`: Maximum collaborators exceeded
- `u111`: NFT not found
- `u112`: NFT already minted for track
- `u113`: Invalid token URI format
- `u114`: NFT transfer operation failed

## Getting Started

### **For Artists**
1. Deploy the SoundStream contract to Stacks
2. Register your tracks using `register-track` or `register-collaboration-track`
3. Mint NFTs for special tracks using `mint-track-nft`
4. Set competitive pricing for your streams
5. Monitor earnings through `get-artist-earnings`

### **For Developers**
1. Import the contract into your Stacks project
2. Integrate streaming and NFT functionality into your music app
3. Use read-only functions for analytics and discovery
4. Build user interfaces around the public functions
5. Implement NFT marketplace features

### **For Collectors**
1. Connect your Stacks wallet
2. Browse tracks and available NFTs
3. Purchase NFTs for streaming benefits
4. Stream music via `stream-track` with automatic discounts
5. Trade NFTs in secondary markets

### **For Listeners**
1. Connect your Stacks wallet
2. Browse tracks using `get-track` function
3. Stream music via `stream-track` with automatic payments
4. Consider purchasing NFTs for frequently played tracks
5. Track your listening history

## Use Cases & Examples

### **Artist Revenue Optimization**
- Release limited edition NFTs for popular tracks
- Offer early access through NFT ownership
- Create tiered pricing (NFT holders vs regular listeners)
- Bundle multiple track NFTs for album collections

### **Fan Engagement**
- VIP streaming access through NFT ownership
- Exclusive content for NFT holders
- Fan club membership via NFT collections
- Artist-fan direct connection through blockchain

### **Music Investment**
- Collect NFTs from emerging artists
- Benefit from free streaming of owned tracks
- Potential appreciation of rare music NFTs
- Portfolio diversification through music assets

## Future Roadmap

- **✅ NFT Integration**: Convert tracks into unique NFTs with streaming rights
- **Playlist NFTs**: Create and monetize curated playlists as NFTs
- **Fan Engagement Tokens**: Loyalty tokens for frequent listeners of specific artists
- **Advanced Analytics Dashboard**: Detailed demographic and geographic streaming data
- **Label Management System**: Multi-artist management for record labels
- **Concert Ticket Integration**: Link NFT ownership to concert ticket discounts
- **Cross-Platform Streaming**: Integration with traditional streaming platforms
- **Artist Verification System**: Blue check verification for legitimate artists
- **Social Features**: Following artists, sharing tracks, and community building
- **Royalty Marketplace**: Trade future royalty streams as financial instruments

## Contributing

SoundStream is open for community contributions. Areas of focus:
- Frontend interfaces for track discovery and NFT management
- Mobile applications with wallet integration
- Analytics dashboards for artists and collectors
- Integration with existing music platforms
- Security audits and improvements
- NFT marketplace development

---
