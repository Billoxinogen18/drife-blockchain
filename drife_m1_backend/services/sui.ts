import { SuiClient } from '@mysten/sui/client';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import { Secp256k1Keypair } from '@mysten/sui/keypairs/secp256k1';
import { Transaction } from '@mysten/sui/transactions';
import type { SuiTransactionBlockResponse } from '@mysten/sui/client';


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
    
    try {
    
      keypair = Ed25519Keypair.fromSecretKey(privateKey);
      console.log(`[${new Date().toISOString()}] Using Ed25519 keypair`);
    } catch (ed25519Error) {
      console.log(`[${new Date().toISOString()}] Ed25519 failed, trying Secp256k1...`);
      try {
       
        keypair = Secp256k1Keypair.fromSecretKey(privateKey);
        console.log(`[${new Date().toISOString()}] Using Secp256k1 keypair`);
      } catch (secp256k1Error) {
       
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
