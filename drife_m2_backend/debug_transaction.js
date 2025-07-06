const { SuiClient } = require('@mysten/sui/client');
const { Ed25519Keypair } = require('@mysten/sui/keypairs/ed25519');
const { Transaction } = require('@mysten/sui/transactions');

async function testTransaction() {
    console.log('🧪 Testing SUI transaction...');
    
    // Configuration
    const client = new SuiClient({ url: 'https://fullnode.testnet.sui.io:443' });
    const privateKey = 'sEzcljv7WndhH9y5bN+cH6anFXNwhJl4EmkmB6sBJkQ=';
    const privateKeyBytes = Buffer.from(privateKey, 'base64');
    const keypair = Ed25519Keypair.fromSecretKey(privateKeyBytes);
    
    const M2_RIDE_SYNC_PACKAGE_ID = '0xc1e28ae1e7ed67a5d9f32e53d4fec24a2eb48a0d9a58450ba605c0a4b2febf23';
    const M2_ROLE_MANAGER_ID = '0x3d220fd5f521a3b6e062b4a76399501c0386e64e73332d79b0575af138664433';
    
    // Get wallet address and balance
    const walletAddress = keypair.getPublicKey().toSuiAddress();
    console.log(`💰 Wallet address: ${walletAddress}`);
    
    try {
        const balance = await client.getBalance({ owner: walletAddress });
        console.log(`💰 SUI balance: ${balance.totalBalance} mist`);
        
        if (balance.totalBalance === '0') {
            console.log('❌ ERROR: Wallet has no SUI for gas fees!');
            console.log('💡 Solution: Add SUI to wallet address:', walletAddress);
            return;
        }
    } catch (error) {
        console.log('⚠️ Could not check balance:', error.message);
    }
    
    // Test the transaction
    console.log('\n📝 Creating transaction...');
    const tx = new Transaction();
    
    const stringToVectorU8 = (str) => Array.from(new TextEncoder().encode(str));
    
    tx.moveCall({
        target: `${M2_RIDE_SYNC_PACKAGE_ID}::drife_ride_sync::assign_role`,
        arguments: [
            tx.object(M2_ROLE_MANAGER_ID),
            tx.pure.address('0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'),
            tx.pure.vector('u8', stringToVectorU8('Rider')),
        ],
    });
    
    try {
        console.log('🔍 Preparing transaction...');
        const result = await client.signAndExecuteTransaction({
            transaction: tx,
            signer: keypair,
            options: { showEffects: true, showEvents: true },
        });
        
        console.log('✅ SUCCESS! Transaction digest:', result.digest);
        console.log('📊 Effects:', JSON.stringify(result.effects, null, 2));
        
    } catch (error) {
        console.log('❌ TRANSACTION FAILED:');
        console.log('Error message:', error.message);
        console.log('Error code:', error.code);
        console.log('Full error:', JSON.stringify(error, null, 2));
        
        // Check specific error types
        if (error.message.includes('Invalid params')) {
            console.log('\n🔍 DIAGNOSIS: Invalid params error');
            console.log('This usually means:');
            console.log('1. Function signature mismatch');
            console.log('2. Object types don\'t match');
            console.log('3. Package/module/function doesn\'t exist');
        }
        
        if (error.message.includes('Insufficient')) {
            console.log('\n🔍 DIAGNOSIS: Insufficient funds for gas');
            console.log('Add SUI to wallet:', walletAddress);
        }
        
        if (error.message.includes('abort')) {
            console.log('\n🔍 DIAGNOSIS: Smart contract abort');
            console.log('Check if wallet has proper permissions');
        }
    }
}

testTransaction().catch(console.error);