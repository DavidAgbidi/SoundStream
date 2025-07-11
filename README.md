# SoundStream 🎵

A decentralized music rights management system built on Stacks blockchain, enabling musicians to register their tracks, manage royalties, and control streaming permissions with full transparency.

## Features

- **Track Registration**: Artists can register their music with custom pricing and royalty rates
- **Decentralized Streaming**: Direct peer-to-peer streaming payments without intermediaries
- **Royalty Management**: Transparent royalty tracking and automatic payments
- **Stream Analytics**: Real-time tracking of streams, earnings, and listener engagement
- **Artist Control**: Full control over track pricing, availability, and permissions

## How It Works

1. **Artists** register their tracks with title, album, duration, and pricing
2. **Listeners** stream tracks by paying the artist-set price directly
3. **Payments** are automatically distributed to artists based on their royalty rates
4. **Analytics** provide transparent insights into streams and earnings

## Contract Functions

### Public Functions

- `register-track`: Register a new track with metadata and pricing
- `stream-track`: Stream a track and pay the artist directly
- `update-track-price`: Update streaming price for owned tracks
- `toggle-track-status`: Enable/disable track availability

### Read-Only Functions

- `get-track`: Retrieve track information by ID
- `get-track-counter`: Get total number of registered tracks
- `get-total-streams`: Get platform-wide stream count
- `get-artist-earnings`: View artist's total earnings and streams
- `calculate-stream-cost`: Calculate cost to stream a specific track

## Technical Details

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity
- **Payment Method**: STX tokens
- **Storage**: On-chain metadata and analytics

## Getting Started

1. Deploy the contract to Stacks blockchain
2. Artists register tracks using `register-track`
3. Set appropriate pricing and royalty rates
4. Listeners can discover and stream tracks
5. Monitor earnings through built-in analytics

## Security Features

- Input validation for all parameters
- Proper error handling throughout
- Artist-only access controls for track management
- Transparent payment processing

## Future Roadmap

