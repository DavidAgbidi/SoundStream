# SoundStream 🎵

A decentralized music rights management system built on Stacks blockchain, enabling musicians to register their tracks, manage royalties, and control streaming permissions with full transparency and multi-artist collaboration support.

## Features

### 🎤 **Track Management**
- **Solo Track Registration**: Artists can register individual tracks with custom pricing
- **Collaboration Tracks**: Support for up to 10 collaborators per track with custom royalty splits
- **Dynamic Pricing**: Artists can update streaming prices for their tracks
- **Track Status Control**: Enable/disable track availability

### 💰 **Advanced Royalty System**
- **Automatic Split Distribution**: Payments automatically distributed based on predefined royalty percentages
- **Real-time Earnings Tracking**: Transparent tracking of individual artist earnings
- **Collaboration Management**: Add new collaborators to existing tracks
- **Validation System**: Ensures royalty splits total exactly 100%

### 📊 **Analytics & Insights**
- **Stream Analytics**: Real-time tracking of streams per track and artist
- **Listener History**: Track individual listener streaming patterns
- **Platform Statistics**: Global stream counts and platform metrics
- **Artist Performance**: Detailed earnings and stream data per artist

### 🔒 **Security & Validation**
- **Comprehensive Input Validation**: All parameters validated for security
- **Artist Authorization**: Only track owners/collaborators can modify tracks
- **Principal Validation**: Prevents invalid wallet addresses
- **Payment Security**: Secure STX token transfers with failure handling

## How It Works

### For Solo Artists
1. **Register Track**: Use `register-track` with title, album, duration, and price
2. **Set Pricing**: Define per-stream cost in STX tokens
3. **Manage Availability**: Toggle track active/inactive status
4. **Monitor Performance**: Track streams and earnings in real-time

### For Collaborations
1. **Create Collaboration**: Use `register-collaboration-track` with all collaborators
2. **Define Splits**: Set royalty percentages that sum to 100%
3. **Add Members**: Add new collaborators to existing tracks
4. **Shared Control**: Collaborators can update pricing and manage tracks

### For Listeners
1. **Discover Tracks**: Browse available tracks by ID
2. **Stream Music**: Pay artists directly via `stream-track`
3. **Track History**: View personal streaming history
4. **Support Artists**: Direct payments with no intermediaries

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

### 🎧 **Streaming & Payments**
```clarity
(stream-track track-id)
```
Stream a track and automatically pay all collaborators based on their royalty splits.

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
Retrieve complete track information and metadata.

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

## Technical Specifications

### **Blockchain Infrastructure**
- **Platform**: Stacks Blockchain
- **Language**: Clarity Smart Contract
- **Payment Token**: STX
- **Storage**: On-chain metadata and analytics

### **System Limits**
- **Max Collaborators**: 10 per track
- **Title/Album Length**: 100 characters maximum
- **Price Range**: 1 to 1,000,000 micro-STX
- **Royalty Range**: 0-100% (must sum to exactly 100% for collaborations)

### **Data Structures**
- **Track Counter**: Global track ID management
- **Stream History**: Per-listener tracking
- **Artist Earnings**: Cumulative earnings and stream counts
- **Collaboration Data**: Multi-artist royalty management

## Security Features

### **Input Validation**
- String length validation for titles and albums
- Price range validation (prevents zero or excessive pricing)
- Principal validation (prevents invalid wallet addresses)
- Royalty percentage validation (0-100% range)

### **Access Controls**
- Owner-only functions for sensitive operations
- Collaborator verification for track modifications
- Primary artist privileges for adding collaborators

### **Payment Security**
- Atomic STX transfers with failure handling
- Automatic royalty distribution
- Protected against insufficient payment errors

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

## Getting Started

### **For Artists**
1. Deploy the SoundStream contract to Stacks
2. Register your tracks using `register-track` or `register-collaboration-track`
3. Set competitive pricing for your streams
4. Monitor earnings through `get-artist-earnings`

### **For Developers**
1. Import the contract into your Stacks project
2. Integrate streaming functionality into your music app
3. Use read-only functions for analytics and discovery
4. Build user interfaces around the public functions

### **For Listeners**
1. Connect your Stacks wallet
2. Browse tracks using `get-track` function
3. Stream music via `stream-track` with automatic payments
4. Track your listening history

## Future Roadmap

- **NFT Integration**: Convert tracks into unique NFTs with streaming rights
- **Playlist Creation**: Allow users to create and monetize curated playlists
- **Fan Engagement Rewards**: Loyalty tokens for frequent listeners of specific artists
- **Advanced Analytics Dashboard**: Detailed demographic and geographic streaming data
- **Label Management System**: Multi-artist management for record labels
- **Concert Ticket Integration**: Link streaming history to concert ticket discounts
- **Cross-Platform Streaming**: Integration with traditional streaming platforms
- **Artist Verification System**: Blue check verification for legitimate artists
- **Social Features**: Following artists, sharing tracks, and community building

## Contributing

SoundStream is open for community contributions. Areas of focus:
- Frontend interfaces for track discovery
- Mobile applications
- Analytics dashboards
- Integration with existing music platforms
- Security audits and improvements

---

**Built with ❤️ for the decentralized music community**