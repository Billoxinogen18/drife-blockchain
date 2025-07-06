// Script to generate a valid SUI testnet private key
const { Ed25519Keypair } = require('@mysten/sui/keypairs/ed25519');

// Generate a new keypair
const keypair = new Ed25519Keypair();

// For Ed25519Keypair, get the private key directly
// Note: Different versions of @mysten/sui may have different APIs
// This uses the current API for getting the private key bytes
let privateKeyBytes;
try {
  // First try the direct property access which is available in some versions
  privateKeyBytes = keypair.keypair.secretKey.slice(0, 32);
} catch (error) {
  console.error('Could not access private key directly, trying alternative methods');
  
  try {
    // Alternative: Some versions expose a getSecretKey method
    privateKeyBytes = keypair.getSecretKey();
  } catch (error2) {
    console.error('Failed to extract private key. Please check @mysten/sui version compatibility.');
    process.exit(1);
  }
}

// Convert to base64 for environment variable format
const privateKeyBase64 = Buffer.from(privateKeyBytes).toString('base64');

// Get the public address
const publicAddress = keypair.getPublicKey().toSuiAddress();

console.log('===========================================');
console.log('SUI Testnet Keypair Generated Successfully');
console.log('===========================================');
console.log(`SUI Address: ${publicAddress}`);
console.log(`Private Key (base64): ${privateKeyBase64}`);
console.log('===========================================');
console.log('IMPORTANT: Save this private key and keep it secure!');
console.log('Use this key for the DRIFE_ADMIN_SUI_PRIVATE_KEY env variable');
console.log('==========================================='); 