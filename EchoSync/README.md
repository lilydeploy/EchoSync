# Music Streaming Platform Smart Contract

A comprehensive smart contract built on the Stacks blockchain using Clarity that manages a decentralized music streaming platform with track ownership, marketplace functionality, and artist profiles.

## 🎵 Overview

This smart contract enables artists and record labels to:
- Release and manage music tracks
- Transfer track ownership
- Create a streaming marketplace with custom fees
- Manage artist profiles with fan metrics
- Batch operations for efficient gas usage

## 🏗️ Architecture

### Core Components

1. **Track Management**: Release, transfer, and manage music tracks
2. **Streaming Marketplace**: Upload tracks for streaming with custom fees
3. **Artist Profiles**: Manage fan count and fame levels
4. **Batch Operations**: Efficient bulk operations for albums

### Data Structures

#### Music Tracks
```clarity
{
  track-id: uint,
  artist: principal,
  audio-metadata-uri: string-utf8 256,
  streamable: bool
}
```

#### Streaming Marketplace
```clarity
{
  track-id: uint,
  track-owner: principal,
  fee-per-stream: uint,
  uploaded-at: uint
}
```

#### Artist Profiles
```clarity
{
  artist: principal,
  fan-count: uint,
  fame-level: uint
}
```

## 🚀 Features

### Track Management
- **Single Track Release**: Release individual tracks with metadata
- **Batch Track Release**: Release up to 10 tracks in one transaction (album support)
- **Track Transfer**: Transfer ownership between artists
- **Batch Transfer**: Transfer multiple tracks efficiently

### Streaming Marketplace
- **Upload for Streaming**: List tracks with custom streaming fees
- **Stream Tracks**: Pay to stream tracks (transfers ownership)
- **Remove from Streaming**: Delist tracks from marketplace

### Artist Profiles
- **Profile Management**: Update fan count and fame level metrics
- **Validation**: Enforced limits on fan count (10,000) and fame level (100)

## 📋 Constants & Limits

| Constant | Value | Description |
|----------|-------|-------------|
| `max-fame-level` | 100 | Maximum fame level for artists |
| `max-fan-count` | 10,000 | Maximum fan count for artists |
| `max-audio-metadata-length` | 256 | Maximum URI length for metadata |
| `max-album-size` | 10 | Maximum tracks per batch operation |

## 🔧 Functions

### Public Functions

#### Track Management

**`release-track`**
```clarity
(release-track (audio-metadata-uri (string-utf8 256)) (streamable bool))
```
Release a single music track. Only callable by the record label.

**`batch-release-tracks`**
```clarity
(batch-release-tracks 
  (audio-metadata-uris (list 10 (string-utf8 256))) 
  (streamable-list (list 10 bool)))
```
Release multiple tracks in one transaction. Ideal for album releases.

**`transfer-track`**
```clarity
(transfer-track (track-id uint) (new-artist principal))
```
Transfer track ownership to another artist. Only the current owner can transfer.

**`batch-transfer-tracks`**
```clarity
(batch-transfer-tracks 
  (track-ids (list 10 uint)) 
  (new-artists (list 10 principal)))
```
Transfer multiple tracks in one transaction.

#### Streaming Marketplace

**`upload-track-for-streaming`**
```clarity
(upload-track-for-streaming (track-id uint) (fee-per-stream uint))
```
List a track on the streaming marketplace with a custom fee.

**`stream-track`**
```clarity
(stream-track (track-id uint))
```
Stream a track by paying the required fee. Transfers ownership to the streamer.

**`remove-from-streaming`**
```clarity
(remove-from-streaming (track-id uint))
```
Remove a track from the streaming marketplace.

#### Artist Profiles

**`update-artist-profile`**
```clarity
(update-artist-profile (fan-count uint) (fame-level uint))
```
Update artist profile with fan metrics.

### Read-Only Functions

**`get-track-details`**
```clarity
(get-track-details (track-id uint))
```
Retrieve track information by ID.

**`get-streaming-marketplace-entry`**
```clarity
(get-streaming-marketplace-entry (track-id uint))
```
Get marketplace listing details for a track.

**`get-artist-profile`**
```clarity
(get-artist-profile (artist principal))
```
Retrieve artist profile information.

**`get-total-tracks`**
```clarity
(get-total-tracks)
```
Get the total number of tracks released.

## 🛡️ Security Features

### Access Control
- **Record Label Only**: Track release restricted to record label address
- **Owner Validation**: Only track owners can transfer or list tracks
- **Self-Transfer Prevention**: Prevents transferring tracks to oneself

### Input Validation
- **URI Length Validation**: Ensures metadata URIs are within limits
- **Batch Size Limits**: Prevents gas issues with large batch operations
- **Range Validation**: Validates track IDs against released tracks
- **Fee Validation**: Ensures streaming fees are greater than zero

### Error Handling
- `err-label-only (u100)`: Only record label can perform action
- `err-track-missing (u101)`: Track does not exist
- `err-permission-denied (u102)`: Insufficient permissions
- `err-invalid-input (u103)`: Invalid input parameters
- `err-invalid-streaming-fee (u104)`: Invalid streaming fee

## 🔄 Workflow Examples

### Album Release Workflow
1. Record label calls `batch-release-tracks` with album metadata
2. Tracks are assigned sequential IDs and stored
3. Record label can transfer tracks to artists
4. Artists can list tracks on streaming marketplace

### Streaming Workflow
1. Artist uploads track to marketplace with `upload-track-for-streaming`
2. Users discover track via marketplace queries
3. User streams track with `stream-track`, paying the fee
4. Ownership transfers to the streamer
5. Track is removed from marketplace

### Artist Profile Management
1. Artist updates profile with `update-artist-profile`
2. Fan count and fame level are validated and stored
3. Profile information can be queried by anyone

## 🎯 Use Cases

- **Independent Artists**: Release and monetize music directly
- **Record Labels**: Manage artist catalogs and batch operations
- **Music Streaming Platforms**: Integrate decentralized music ownership
- **Fan Engagement**: Artists can track and display fan metrics
- **Music NFTs**: Each track acts as a unique digital asset

## ⚡ Gas Optimization

- **Batch Operations**: Reduce transaction costs for multiple tracks
- **Size Limits**: Prevent excessive gas usage with reasonable limits
- **Efficient Data Structures**: Optimized storage patterns
- **Single Transaction Transfers**: Minimize blockchain interactions

## 🧪 Testing Considerations

When testing this contract, consider:
- Boundary testing for all limits (fan count, fame level, batch sizes)
- Access control validation for different user roles
- Edge cases like self-transfers and duplicate operations
- Gas usage optimization for batch operations
- Error handling for invalid inputs


*Built with ❤️ on the Stacks blockchain using Clarity*