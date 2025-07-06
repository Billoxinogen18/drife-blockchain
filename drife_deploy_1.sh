#!/bin/bash

# ==============================================================================
# DRIFE MILESTONE 1: FULL BACKEND AUTOMATION SCRIPT (FIXED)
# Version: 1.9 (Final - Based on user's v1.7 with TypeScript build fix)
# Description: This script resolves the TypeScript build error by correctly
#              handling the 'unknown' error type in the catch blocks, while
#              preserving the user's core logic for keypair detection.
# ==============================================================================

# --- Strict Mode ---
set -e
set -u
set -o pipefail

# --- Configuration & Variables ---
BASE_PATH="/Users/israelbill/Development/DrifeProjects"
BACKEND_DIR_NAME="drife_m1_backend"
PROJECT_PATH="${BASE_PATH}/${BACKEND_DIR_NAME}"
# The admin private key is now hardcoded as requested.
ADMIN_PRIVATE_KEY="suiprivkey1qyt8h6svpxgnfeyvp9yzg4unyhy4mvq7v8ang8ct7zhm7gmh3fma5nvsd6l"

# --- Helper Functions & Colors for Logging ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_NC='\033[0m' # No Color

info() {
    echo -e "${C_BLUE}INFO:${C_NC} $1"
}

success() {
    echo -e "${C_GREEN}SUCCESS:${C_NC} $1"
}

warn() {
    echo -e "${C_YELLOW}WARNING:${C_NC} $1"
}

error() {
    echo -e "${C_RED}ERROR:${C_NC} $1" >&2
    exit 1
}

# --- Prerequisite Checks ---
info "Checking for required tools: node, npm..."
if ! command -v node &> /dev/null; then
    error "'node' is not installed. Please install Node.js (which includes npm)."
fi
success "All required tools are installed."

# --- Project Directory Setup ---
info "Setting up project directory at: ${PROJECT_PATH}"
if [ -d "$PROJECT_PATH" ]; then
    warn "Project directory already exists. Backing it up and creating a new one."
    mv "$PROJECT_PATH" "${PROJECT_PATH}_backup_$(date +%Y%m%d_%H%M%S)"
fi
mkdir -p "$PROJECT_PATH"
cd "$PROJECT_PATH"
success "Project directory is ready."

# --- File Generation ---

info "Generating project files with corrected TypeScript error handling..."

# 1. Create subdirectories
mkdir -p "${PROJECT_PATH}/pages/api"
mkdir -p "${PROJECT_PATH}/services"

# 2. Generate package.json
cat > "${PROJECT_PATH}/package.json" << 'EOF'
{
  "name": "drife-m1-backend",
  "version": "1.9.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "@mysten/sui": "^1.18.0",
    "next": "14.2.3",
    "react": "^18",
    "react-dom": "^18"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "eslint": "^8",
    "eslint-config-next": "14.2.3",
    "typescript": "^5"
  }
}
EOF

# 3. Generate .env.local
cat > "${PROJECT_PATH}/.env.local" << EOF
# --- SERVER-SIDE ENVIRONMENT VARIABLES ---
# The private key for your admin account.
DRIFE_ADMIN_SUI_PRIVATE_KEY="${ADMIN_PRIVATE_KEY}"
EOF

# 4. Generate vercel.json
cat > "${PROJECT_PATH}/vercel.json" << 'EOF'
{
  "version": 2,
  "builds": [
    {
      "src": "next.config.js",
      "use": "@vercel/next"
    }
  ]
}
EOF
info "Created vercel.json to ensure Vercel uses the Next.js builder."

# 5. Generate services/sui.ts with the final TypeScript fix
cat > "${PROJECT_PATH}/services/sui.ts" << 'EOF'
import { SuiClient } from '@mysten/sui/client';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import { Secp256k1Keypair } from '@mysten/sui/keypairs/secp256k1';
import { Transaction } from '@mysten/sui/transactions';
import type { SuiTransactionBlockResponse } from '@mysten/sui/client';

// --- Configuration Constants (from Milestone 1 Docs) ---
const SUI_TESTNET_RPC_URL = 'https://fullnode.testnet.sui.io:443';

const M1_WALLET_PACKAGE_ID = '0xb527efb9252944cb36c454c02a599c62244f509021208b401a403000d52af576';
const M1_WALLET_STATE_ID = '0x74eff8e36662cd47344b8fdf76443a55c22c8d67dbfaf7b67224e223ddede728';
const M1_WALLET_ADMIN_CAP_ID = '0xeca87408e738979e76ec3bf9793b92a850359e6a75b8b23c3183771e73e32abf';
const SUI_CLOCK_OBJECT_ID = '0x6';

let client: SuiClient;
let keypair: Ed25519Keypair | Secp256k1Keypair;

async function initializeSuiClient() {
  if (client && keypair) return;
  console.log(`[${new Date().toISOString()}] Initializing Sui client...`);

  const privateKey = process.env.DRIFE_ADMIN_SUI_PRIVATE_KEY;
  if (!privateKey) {
    console.error(`[${new Date().toISOString()}] CRITICAL: DRIFE_ADMIN_SUI_PRIVATE_KEY is not set!`);
    throw new Error('DRIFE_ADMIN_SUI_PRIVATE_KEY environment variable is not set!');
  }

  try {
    client = new SuiClient({ url: SUI_TESTNET_RPC_URL });
    
    // This is your correct logic for determining the keypair type.
    try {
      // First try Ed25519
      keypair = Ed25519Keypair.fromSecretKey(privateKey);
      console.log(`[${new Date().toISOString()}] Using Ed25519 keypair`);
    } catch (ed25519Error) {
      console.log(`[${new Date().toISOString()}] Ed25519 failed, trying Secp256k1...`);
      try {
        // If Ed25519 fails, try Secp256k1
        keypair = Secp256k1Keypair.fromSecretKey(privateKey);
        console.log(`[${new Date().toISOString()}] Using Secp256k1 keypair`);
      } catch (secp256k1Error) {
        // ** THE FIX IS HERE **
        // Helper function to safely get an error message from an 'unknown' type.
        const getErrorMessage = (error: unknown) => {
          if (error instanceof Error) return error.message;
          return String(error);
        };
        
        console.error(`[${new Date().toISOString()}] Both Ed25519 and Secp256k1 failed:`, {
          ed25519Error: getErrorMessage(ed25519Error),
          secp256k1Error: getErrorMessage(secp256k1Error)
        });
        throw new Error('Private key format not supported. Must be Ed25519 or Secp256k1.');
      }
    }
    
    const adminAddress = keypair.getPublicKey().toSuiAddress();
    console.log(`[${new Date().toISOString()}] Sui admin client initialized successfully. Admin address: ${adminAddress}`);
  } catch (e: any) {
    console.error(`[${new Date().toISOString()}] Failed to initialize Sui client:`, e);
    throw new Error(`Could not initialize Sui client: ${e.message}`);
  }
}

// Initialize client on module load
initializeSuiClient().catch(console.error);

const stringToVectorU8 = (str: string): number[] => Array.from(new TextEncoder().encode(str));

function getUniqueNonce(): bigint {
  return BigInt(Date.now());
}

export async function registerNewWallet(userId: string, userSuiAddress: string, role: string): Promise<SuiTransactionBlockResponse> {
  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Attempting to register single wallet for userId: ${userId}`);
  if (!client || !keypair) await initializeSuiClient();
  
  const tx = new Transaction();

  tx.moveCall({
    target: `${M1_WALLET_PACKAGE_ID}::drife_wallet::register_wallet`,
    arguments: [
      tx.object(M1_WALLET_ADMIN_CAP_ID),
      tx.object(M1_WALLET_STATE_ID),
      tx.pure.vector('u8', stringToVectorU8(userId)),
      tx.pure.address(userSuiAddress),
      tx.pure.vector('u8', stringToVectorU8(role)),
      tx.pure.u64(getUniqueNonce()),
      tx.object(SUI_CLOCK_OBJECT_ID),
    ],
  });

  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Signing and executing transaction for single wallet...`);
  return client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair,
    options: { showEffects: true, showEvents: true },
  });
}

export interface UserBatchData {
  userId: string;
  suiAddress: string;
  role: string;
}

export async function registerWalletsInBatch(users: UserBatchData[]): Promise<SuiTransactionBlockResponse> {
  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Attempting to register batch of ${users.length} wallets.`);
  if (!client || !keypair) await initializeSuiClient();
  
  const tx = new Transaction();

  const userIds = users.map(u => stringToVectorU8(u.userId));
  const addresses = users.map(u => u.suiAddress);
  const roles = users.map(u => stringToVectorU8(u.role));

  tx.moveCall({
    target: `${M1_WALLET_PACKAGE_ID}::drife_wallet::batch_register_wallets`,
    arguments: [
      tx.object(M1_WALLET_ADMIN_CAP_ID),
      tx.object(M1_WALLET_STATE_ID),
      tx.pure.vector('vector<u8>', userIds),
      tx.pure.vector('address', addresses),
      tx.pure.vector('vector<u8>', roles),
      tx.pure.u64(getUniqueNonce()),
      tx.object(SUI_CLOCK_OBJECT_ID),
    ],
  });
  
  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Signing and executing transaction for batch wallets...`);
  return client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair,
    options: { showEffects: true, showEvents: true },
  });
}
EOF

# 6. Generate pages/api/register-wallet.ts
cat > "${PROJECT_PATH}/pages/api/register-wallet.ts" << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next';
import { registerNewWallet } from '../../services/sui';
type ResponseData = { message: string; digest?: string; error?: string; errorStack?: string; };
export default async function handler(req: NextApiRequest, res: NextApiResponse<ResponseData>) {
  const timestamp = `[${new Date().toISOString()}]`;
  console.log(`${timestamp} API_HIT: /api/register-wallet`);
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ message: 'Method Not Allowed' });
  }
  console.log(`${timestamp} API_BODY:`, JSON.stringify(req.body, null, 2));
  const { userId, suiAddress, role } = req.body;
  if (!userId || !suiAddress || !role) {
    return res.status(400).json({ message: 'Missing required fields: userId, suiAddress, role' });
  }
  try {
    const result = await registerNewWallet(userId, suiAddress, role);
    res.status(200).json({ message: 'Wallet registered successfully', digest: result.digest });
  } catch (error: any) {
    res.status(500).json({ message: 'Failed to register wallet', error: error.message, errorStack: error.stack });
  }
}
EOF

# 7. Generate pages/api/batch-register-wallets.ts
cat > "${PROJECT_PATH}/pages/api/batch-register-wallets.ts" << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next';
import { registerWalletsInBatch, UserBatchData } from '../../services/sui';
type ResponseData = { message: string; digest?: string; error?: string; errorStack?: string; };
export default async function handler(req: NextApiRequest, res: NextApiResponse<ResponseData>) {
  const timestamp = `[${new Date().toISOString()}]`;
  console.log(`${timestamp} API_HIT: /api/batch-register-wallets`);
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ message: 'Method Not Allowed' });
  }
  console.log(`${timestamp} API_BODY:`, JSON.stringify(req.body, null, 2));
  const { users } = req.body;
  if (!Array.isArray(users) || users.length === 0) {
    return res.status(400).json({ message: 'Request body must contain a non-empty array of users.' });
  }
  try {
    const result = await registerWalletsInBatch(users as UserBatchData[]);
    res.status(200).json({ message: 'Wallets registered successfully in batch', digest: result.digest });
  } catch (error: any) {
    res.status(500).json({ message: 'Failed to register wallets in batch', error: error.message, errorStack: error.stack });
  }
}
EOF

# 8. Generate tsconfig.json, next.config.js, .gitignore, pages/index.tsx
cat > "${PROJECT_PATH}/tsconfig.json" << 'EOF'
{ "compilerOptions": { "lib": ["dom", "dom.iterable", "esnext"], "allowJs": true, "skipLibCheck": true, "strict": true, "noEmit": true, "esModuleInterop": true, "module": "esnext", "moduleResolution": "bundler", "resolveJsonModule": true, "isolatedModules": true, "jsx": "preserve", "incremental": true, "plugins": [{"name": "next"}], "paths": {"@/*": ["./*"]}}, "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"], "exclude": ["node_modules"]}
EOF
cat > "${PROJECT_PATH}/next.config.js" << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = { reactStrictMode: true, swcMinify: true, experimental: { serverComponentsExternalPackages: ['@mysten/sui'] }, env: { CUSTOM_KEY: process.env.CUSTOM_KEY, },}
module.exports = nextConfig
EOF
cat > "${PROJECT_PATH}/.gitignore" << 'EOF'
/node_modules
/.pnp
.pnp.js
/coverage
/.next/
/out/
/build
.DS_Store
*.pem
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.env*.local
.env
.vercel
*.tsbuildinfo
next-env.d.ts
EOF
cat > "${PROJECT_PATH}/pages/index.tsx" << 'EOF'
import { NextPage } from 'next';
import Head from 'next/head';
const Home: NextPage = () => {
  return (
    <div>
      <Head>
        <title>DRIFE M1 Backend</title>
        <meta name="description" content="DRIFE Milestone 1 Backend Service" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main style={{ padding: '2rem', fontFamily: 'Arial, sans-serif' }}>
        <h1>DRIFE Milestone 1 Backend</h1>
        <p>Backend service is running successfully!</p>
        <div style={{ marginTop: '2rem' }}>
          <h2>API Endpoints:</h2>
          <ul><li><code>POST /api/register-wallet</code></li><li><code>POST /api/batch-register-wallets</code></li></ul>
        </div>
      </main>
    </div>
  );
};
export default Home;
EOF

success "All project files have been generated."

# --- Installation and Build ---
info "Installing project dependencies with npm..."
npm install > /dev/null 2>&1
success "Dependencies installed."

info "Building the project to verify everything works..."
npm run build
success "Project built successfully."

# --- Deployment Function ---
deploy_to_vercel() {
    echo
    info "Checking for Vercel CLI..."
    if ! command -v vercel &> /dev/null; then
        warn "Vercel CLI is not installed. Please run 'npm install -g vercel' to enable auto-deployment."
        return
    fi
    success "Vercel CLI found."
    echo
    read -p "Do you want to deploy this project to Vercel for production now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Starting Vercel deployment..."
        cd "$PROJECT_PATH"
        vercel --prod
        success "Vercel deployment process initiated. Check your Vercel dashboard."
    else
        info "Skipping Vercel deployment."
    fi
}

# --- Final Instructions ---
echo
echo -e "${C_GREEN}======================================================================${C_NC}"
echo -e "${C_GREEN} MILESTONE 1 BACKEND SETUP COMPLETE! (Build Error Fixed) ${C_NC}"
echo -e "${C_GREEN}======================================================================${C_NC}"
echo
echo -e "${C_YELLOW}Your new backend project is ready at:${C_NC}"
echo -e "  ${PROJECT_PATH}"
echo
echo -e "${C_YELLOW}To start the local development server, run:${C_NC}"
echo -e "  cd ${PROJECT_PATH}"
echo -e "  npm run dev"
echo
echo -e "${C_YELLOW}IMPORTANT - Environment Variables for Vercel:${C_NC}"
echo -e "  Before deploying, you MUST set the DRIFE_ADMIN_SUI_PRIVATE_KEY environment"
echo -e "  variable in your Vercel project's settings page."
echo
echo -e "${C_GREEN}Key Changes in This Version (1.9):${C_NC}"
echo -e "  ✓ FIXED: The script now correctly handles the 'unknown' error type from"
echo -e "    the catch block, which will allow the project to build successfully."
echo -e "  ✓ Your logic for detecting Ed25519 vs. Secp256k1 has been preserved and fixed."
echo -e "======================================================================="

# --- Run Deployment Step ---
deploy_to_vercel

echo
success "Script finished. This version should build successfully."
