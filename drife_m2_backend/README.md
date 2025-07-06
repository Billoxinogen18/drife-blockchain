# DRIFE M2 Ride Sync Backend

This is the backend service for interacting with DRIFE's M2 Ride Sync smart contract on the SUI blockchain. It provides a set of REST API endpoints to manage rides, roles, and contract states.

## Overview

The DRIFE M2 Ride Sync backend is built using:
- Next.js API routes
- SUI SDK for blockchain interactions
- TypeScript for type safety

## Prerequisites

- Node.js 16.x or higher
- npm 8.x or higher
- Access to DRIFE M2 deployed smart contracts
- SUI admin private key with appropriate permissions

## Installation

1. Clone the repository
2. Install dependencies:

```bash
cd drife_m2_backend
chmod +x setup.sh
./setup.sh
```

The setup script will:
- Install all required dependencies
- Create a template `.env.local` file if it doesn't exist
- Build the application

## Configuration

Edit the `.env.local` file with your specific values:

```
# SUI Network Configuration
M2_RIDE_SYNC_PACKAGE_ID=0x__YOUR_PACKAGE_ID_HERE__
M2_RIDE_SYNC_STATE_ID=0x__YOUR_STATE_ID_HERE__
M2_ROLE_MANAGER_ID=0x__YOUR_ROLE_MANAGER_ID_HERE__

# Admin Private Key
DRIFE_ADMIN_SUI_PRIVATE_KEY=YOUR_ADMIN_PRIVATE_KEY_HERE

# API Port (optional)
PORT=3000
```

## Running the Service

### Development Mode

```bash
npm run dev
```

### Production Mode

```bash
npm run build
npm run start
```

## API Endpoints

All endpoints accept POST requests with JSON payloads.

### Role Management

#### Assign Role

```
POST /api/assign-role
```

Payload:
```json
{
  "userAddress": "0x123...abc",
  "role": "Rider" // One of: "Admin", "Rider", "Driver", "Writer"
}
```

#### Revoke Role

```
POST /api/revoke-role
```

Payload:
```json
{
  "userAddress": "0x123...abc",
  "role": "Rider" // One of: "Admin", "Rider", "Driver", "Writer"
}
```

### Ride Management

#### Request Ride

```
POST /api/request-ride
```

Payload:
```json
{
  "rideId": "unique_ride_identifier",
  "fare": 1000 // Must be positive
}
```

#### Match Driver

```
POST /api/match-driver
```

Payload:
```json
{
  "rideId": "unique_ride_identifier",
  "driverAddress": "0x456...def"
}
```

#### Complete Ride

```
POST /api/complete-ride
```

Payload:
```json
{
  "rideId": "unique_ride_identifier"
}
```

#### Cancel Ride

```
POST /api/cancel-ride
```

Payload:
```json
{
  "rideId": "unique_ride_identifier"
}
```

#### Archive Ride

```
POST /api/archive-ride
```

Payload:
```json
{
  "rideId": "unique_ride_identifier"
}
```

#### Emit Full Ride Information (for Indexers)

```
POST /api/emit-ride-info
```

Payload:
```json
{
  "rideId": "unique_ride_identifier"
}
```

### Contract Control

```
POST /api/contract-control
```

Payload:
```json
{
  "action": "pause" // One of: "pause", "unpause"
}
```

## Testing

A test script is included to validate the API endpoints:

```bash
chmod +x test.sh
./test.sh
```

This will run a series of tests against your local instance to ensure everything is working correctly.

## Response Format

All API endpoints return JSON responses in the following format:

Success response:
```json
{
  "message": "Operation successful",
  "digest": "transaction_digest_from_sui"
}
```

Error response:
```json
{
  "message": "Error description",
  "error": "Error message",
  "errorStack": "Stack trace (in development mode)"
}
```

## Architecture

The backend follows a layered architecture:

1. **API Layer**: Next.js API routes handling HTTP requests and responses
2. **Service Layer**: SUI service for interacting with the blockchain
3. **Blockchain Layer**: DRIFE M2 Ride Sync smart contract

## Security Considerations

- The admin private key should be kept secure and never committed to version control
- Only authorized users should have access to the API endpoints
- Consider implementing API authentication for production deployments
- Validate all user inputs before processing

## Version Information

- Current Version: 1.0.0
- Target Network: SUI Testnet
- Contract Version: 3.6 (Post-Audit Final)

## License

Copyright © 2025 DRIFE Technologies 