# DRIFE Blockchain Projects

This repository contains the blockchain components for the DRIFE platform, built on SUI blockchain.

## Projects

### 1. DRIFE M1 Wallet Project
Smart contract for wallet management.

### 2. DRIFE M2 Ride Sync Project
Smart contract for ride lifecycle management, tracking ride requests, driver matching, ride completion, and cancellations.

### 3. DRIFE M2 Backend
API backend for interacting with the M2 Ride Sync smart contract.

### 4. DRIFE M3 Rewards Project
Smart contract for managing rewards and incentives.

### 5. DRIFE Token Project
Smart contract for the DRIFE token implementation.

## Setup and Deployment

### Smart Contract Deployment
The M2 Ride Sync contract has been deployed to the SUI testnet with the following IDs:
- Package ID: `0xc1e28ae1e7ed67a5d9f32e53d4fec24a2eb48a0d9a58450ba605c0a4b2febf23`
- Role Manager ID: `0x3d220fd5f521a3b6e062b4a76399501c0386e64e73332d79b0575af138664433`
- Ride Sync State ID: `0xb7d367a4498c25a6044a1e6e4dab8a4a2b6cb443b2660a0cea0b94d06cb5a837`

### Backend Deployment
The M2 Backend is deployed on Vercel at: https://drife-m2-backend.vercel.app

## Development

### Prerequisites
- Node.js v16+
- SUI CLI
- Vercel CLI (for backend deployment)

### Local Development
1. Clone this repository
2. Set up environment variables in `.env.local`
3. Run `npm install` and `npm run dev` in the project directory

## License
Proprietary - All rights reserved 