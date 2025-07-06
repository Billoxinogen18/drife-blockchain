import { SuiClient } from '@mysten/sui/client';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import { Secp256k1Keypair } from '@mysten/sui/keypairs/secp256k1';
import { Transaction } from '@mysten/sui/transactions';
import type { SuiTransactionBlockResponse } from '@mysten/sui/client';

const SUI_TESTNET_RPC_URL = 'https://fullnode.testnet.sui.io:443';

// Package IDs from the deployed contract
const M2_RIDE_SYNC_PACKAGE_ID = process.env.M2_RIDE_SYNC_PACKAGE_ID || '0xc1e28ae1e7ed67a5d9f32e53d4fec24a2eb48a0d9a58450ba605c0a4b2febf23';
const M2_RIDE_SYNC_STATE_ID = process.env.M2_RIDE_SYNC_STATE_ID || '0xb7d367a4498c25a6044a1e6e4dab8a4a2b6cb443b2660a0cea0b94d06cb5a837';
const M2_ROLE_MANAGER_ID = process.env.M2_ROLE_MANAGER_ID || '0x3d220fd5f521a3b6e062b4a76399501c0386e64e73332d79b0575af138664433';
const SUI_CLOCK_OBJECT_ID = '0x6';

// Role constants for better type safety
export enum RideStatus {
  REQUESTED = 0,
  MATCHED = 1,
  COMPLETED = 2,
  CANCELLED = 3,
}

export enum Role {
  ADMIN = "Admin",
  RIDER = "Rider",
  DRIVER = "Driver",
  WRITER = "Writer",
}

let client: SuiClient;

// Set to true temporarily to add admin role to our wallet
let testMode = true;

// For testing purposes, use a mock keypair if we're not in production
class MockKeypair {
  private mockAddress = "0x06acf160d41f755876b761fadd44c277a07b5f56c9f3989b2a67071d36660504";
  
  getPublicKey() {
    return {
      toSuiAddress: () => this.mockAddress
    };
  }
  
  signTransactionBlock(tx: any) {
    console.log(`[MOCK] Would sign transaction: ${JSON.stringify(tx)}`);
    return { signature: "mockSignature" };
  }
}

let keypair: Ed25519Keypair | Secp256k1Keypair | MockKeypair;

async function initializeSuiClient() {
  if (client && keypair) return;
  console.log(`[${new Date().toISOString()}] Initializing Sui client...`);

  try {
    client = new SuiClient({ url: SUI_TESTNET_RPC_URL });
    
    if (testMode) {
      console.log(`[${new Date().toISOString()}] Using mock keypair for testing`);
      keypair = new MockKeypair();
      
      const adminAddress = (keypair as MockKeypair).getPublicKey().toSuiAddress();
      console.log(`[${new Date().toISOString()}] Sui client initialized in TEST mode. Mock admin address: ${adminAddress}`);
      return;
    }
    
    const privateKey = process.env.DRIFE_ADMIN_SUI_PRIVATE_KEY || '';
    if (!privateKey || privateKey === 'YOUR_DEFAULT_PRIVATE_KEY') {
      console.error(`[${new Date().toISOString()}] No valid private key found. Set DRIFE_ADMIN_SUI_PRIVATE_KEY environment variable.`);
      throw new Error('Missing or invalid private key');
    }
    
    console.log(`[${new Date().toISOString()}] Attempting to create keypair from private key...`);
    
    try {
      // Convert from base64 to Uint8Array for Ed25519
      const privateKeyBytes = Buffer.from(privateKey, 'base64');
      keypair = Ed25519Keypair.fromSecretKey(privateKeyBytes);
      
      // Log success but not the actual key
      console.log(`[${new Date().toISOString()}] Successfully created Ed25519 keypair`);
      const adminAddress = keypair.getPublicKey().toSuiAddress();
      console.log(`[${new Date().toISOString()}] Admin address: ${adminAddress}`);
    } catch (error) {
      console.error(`[${new Date().toISOString()}] Failed to create keypair:`, error);
      throw new Error(`Could not create keypair from private key: ${error instanceof Error ? error.message : String(error)}`);
    }
  } catch (e: any) {
    console.error(`[${new Date().toISOString()}] Failed to initialize Sui client:`, e);
    throw new Error(`Could not initialize Sui client: ${e.message}`);
  }
}

// Initialize the client when the module is loaded
initializeSuiClient().catch(console.error);

const stringToVectorU8 = (str: string): number[] => Array.from(new TextEncoder().encode(str));

function getCurrentDate(): number {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return parseInt(`${year}${month}${day}`);
}

// Helper function for API responses in test mode
function getMockResponse(operation: string): Promise<any> {
  if (!testMode) return Promise.reject(new Error("Not in test mode"));
  
  return Promise.resolve({
    digest: "mockTransactionDigest",
    effects: {
      status: { status: "success" },
      events: [
        {
          type: `${M2_RIDE_SYNC_PACKAGE_ID}::drife_ride_sync::${operation}_event`,
          sender: keypair?.getPublicKey().toSuiAddress(),
          parsedJson: {
            success: true,
            message: `Mock ${operation} completed successfully`,
          },
        },
      ],
    },
  });
}

// Role Management
export async function assignRole(userAddress: string, role: Role): Promise<SuiTransactionBlockResponse> {
  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Assigning role ${role} to address: ${userAddress}`);
  if (!client || !keypair) await initializeSuiClient();
  
  if (testMode) {
    console.log(`[${new Date().toISOString()}] [TEST MODE] Mocking assignRole response`);
    return getMockResponse("assign_role") as any;
  }
  
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${M2_RIDE_SYNC_PACKAGE_ID}::drife_ride_sync::assign_role`,
    arguments: [
      tx.object(M2_ROLE_MANAGER_ID),
      tx.pure.address(userAddress),
      tx.pure.vector('u8', stringToVectorU8(role)),
    ],
  });

  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Signing and executing transaction for role assignment...`);
  return client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair as any,
    options: { showEffects: true, showEvents: true },
  });
}

export async function revokeRole(userAddress: string, role: Role): Promise<SuiTransactionBlockResponse> {
  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Revoking role ${role} from address: ${userAddress}`);
  if (!client || !keypair) await initializeSuiClient();
  
  if (testMode) {
    console.log(`[${new Date().toISOString()}] [TEST MODE] Mocking revokeRole response`);
    return getMockResponse("revoke_role") as any;
  }
  
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${M2_RIDE_SYNC_PACKAGE_ID}::drife_ride_sync::revoke_role`,
    arguments: [
      tx.object(M2_ROLE_MANAGER_ID),
      tx.pure.address(userAddress),
      tx.pure.vector('u8', stringToVectorU8(role)),
    ],
  });

  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Signing and executing transaction for role revocation...`);
  return client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair as any,
    options: { showEffects: true, showEvents: true },
  });
}

// Ride Management
export async function requestRide(rideId: string, fare: number): Promise<SuiTransactionBlockResponse> {
  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Requesting ride with ID: ${rideId}, fare: ${fare}`);
  if (!client || !keypair) await initializeSuiClient();
  
  if (testMode) {
    console.log(`[${new Date().toISOString()}] [TEST MODE] Mocking requestRide response`);
    return getMockResponse("request_ride") as any;
  }
  
  const dateYyyymmdd = getCurrentDate();
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${M2_RIDE_SYNC_PACKAGE_ID}::drife_ride_sync::request_ride`,
    arguments: [
      tx.object(M2_RIDE_SYNC_STATE_ID),
      tx.object(M2_ROLE_MANAGER_ID),
      tx.pure.vector('u8', stringToVectorU8(rideId)),
      tx.pure.u64(fare),
      tx.pure.u32(dateYyyymmdd),
      tx.object(SUI_CLOCK_OBJECT_ID),
    ],
  });

  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Signing and executing transaction for ride request...`);
  return client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair as any,
    options: { showEffects: true, showEvents: true },
  });
}

export async function matchDriver(rideId: string, driverAddress: string): Promise<SuiTransactionBlockResponse> {
  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Matching driver ${driverAddress} to ride ID: ${rideId}`);
  if (!client || !keypair) await initializeSuiClient();
  
  if (testMode) {
    console.log(`[${new Date().toISOString()}] [TEST MODE] Mocking matchDriver response`);
    return getMockResponse("match_driver") as any;
  }
  
  const dateYyyymmdd = getCurrentDate();
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${M2_RIDE_SYNC_PACKAGE_ID}::drife_ride_sync::match_driver`,
    arguments: [
      tx.object(M2_RIDE_SYNC_STATE_ID),
      tx.object(M2_ROLE_MANAGER_ID),
      tx.pure.vector('u8', stringToVectorU8(rideId)),
      tx.pure.address(driverAddress),
      tx.pure.u32(dateYyyymmdd),
      tx.object(SUI_CLOCK_OBJECT_ID),
    ],
  });

  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Signing and executing transaction for driver matching...`);
  return client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair as any,
    options: { showEffects: true, showEvents: true },
  });
}

export async function completeRide(rideId: string): Promise<SuiTransactionBlockResponse> {
  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Completing ride with ID: ${rideId}`);
  if (!client || !keypair) await initializeSuiClient();
  
  if (testMode) {
    console.log(`[${new Date().toISOString()}] [TEST MODE] Mocking completeRide response`);
    return getMockResponse("complete_ride") as any;
  }
  
  const dateYyyymmdd = getCurrentDate();
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${M2_RIDE_SYNC_PACKAGE_ID}::drife_ride_sync::complete_ride`,
    arguments: [
      tx.object(M2_RIDE_SYNC_STATE_ID),
      tx.object(M2_ROLE_MANAGER_ID),
      tx.pure.vector('u8', stringToVectorU8(rideId)),
      tx.pure.u32(dateYyyymmdd),
      tx.object(SUI_CLOCK_OBJECT_ID),
    ],
  });

  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Signing and executing transaction for ride completion...`);
  return client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair as any,
    options: { showEffects: true, showEvents: true },
  });
}

export async function cancelRide(rideId: string): Promise<SuiTransactionBlockResponse> {
  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Canceling ride with ID: ${rideId}`);
  if (!client || !keypair) await initializeSuiClient();
  
  if (testMode) {
    console.log(`[${new Date().toISOString()}] [TEST MODE] Mocking cancelRide response`);
    return getMockResponse("cancel_ride") as any;
  }
  
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${M2_RIDE_SYNC_PACKAGE_ID}::drife_ride_sync::cancel_ride`,
    arguments: [
      tx.object(M2_RIDE_SYNC_STATE_ID),
      tx.object(M2_ROLE_MANAGER_ID),
      tx.pure.vector('u8', stringToVectorU8(rideId)),
      tx.object(SUI_CLOCK_OBJECT_ID),
    ],
  });

  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Signing and executing transaction for ride cancellation...`);
  return client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair as any,
    options: { showEffects: true, showEvents: true },
  });
}

export async function archiveRide(rideId: string): Promise<SuiTransactionBlockResponse> {
  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Archiving ride with ID: ${rideId}`);
  if (!client || !keypair) await initializeSuiClient();
  
  if (testMode) {
    console.log(`[${new Date().toISOString()}] [TEST MODE] Mocking archiveRide response`);
    return getMockResponse("archive_ride") as any;
  }
  
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${M2_RIDE_SYNC_PACKAGE_ID}::drife_ride_sync::archive_ride`,
    arguments: [
      tx.object(M2_RIDE_SYNC_STATE_ID),
      tx.object(M2_ROLE_MANAGER_ID),
      tx.pure.vector('u8', stringToVectorU8(rideId)),
    ],
  });

  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Signing and executing transaction for ride archiving...`);
  return client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair as any,
    options: { showEffects: true, showEvents: true },
  });
}

export async function pauseContract(): Promise<SuiTransactionBlockResponse> {
  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Pausing contract`);
  if (!client || !keypair) await initializeSuiClient();
  
  if (testMode) {
    console.log(`[${new Date().toISOString()}] [TEST MODE] Mocking pauseContract response`);
    return getMockResponse("pause_contract") as any;
  }
  
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${M2_RIDE_SYNC_PACKAGE_ID}::drife_ride_sync::pause`,
    arguments: [
      tx.object(M2_RIDE_SYNC_STATE_ID),
      tx.object(M2_ROLE_MANAGER_ID),
    ],
  });

  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Signing and executing transaction for pausing contract...`);
  return client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair as any,
    options: { showEffects: true, showEvents: true },
  });
}

export async function unpauseContract(): Promise<SuiTransactionBlockResponse> {
  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Unpausing contract`);
  if (!client || !keypair) await initializeSuiClient();
  
  if (testMode) {
    console.log(`[${new Date().toISOString()}] [TEST MODE] Mocking unpauseContract response`);
    return getMockResponse("unpause_contract") as any;
  }
  
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${M2_RIDE_SYNC_PACKAGE_ID}::drife_ride_sync::unpause`,
    arguments: [
      tx.object(M2_RIDE_SYNC_STATE_ID),
      tx.object(M2_ROLE_MANAGER_ID),
    ],
  });

  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Signing and executing transaction for unpausing contract...`);
  return client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair as any,
    options: { showEffects: true, showEvents: true },
  });
}

export async function emitFullRide(rideId: string): Promise<SuiTransactionBlockResponse> {
  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Emitting full ride info for ride ID: ${rideId}`);
  if (!client || !keypair) await initializeSuiClient();
  
  if (testMode) {
    console.log(`[${new Date().toISOString()}] [TEST MODE] Mocking emitFullRide response`);
    return getMockResponse("emit_full_ride") as any;
  }
  
  const tx = new Transaction();
  
  tx.moveCall({
    target: `${M2_RIDE_SYNC_PACKAGE_ID}::drife_ride_sync::emit_full_ride`,
    arguments: [
      tx.object(M2_RIDE_SYNC_STATE_ID),
      tx.pure.vector('u8', stringToVectorU8(rideId)),
    ],
  });

  console.log(`[${new Date().toISOString()}] [SUI_SERVICE] Signing and executing transaction for emitting ride info...`);
  return client.signAndExecuteTransaction({
    transaction: tx,
    signer: keypair as any,
    options: { showEffects: true, showEvents: true },
  });
} 