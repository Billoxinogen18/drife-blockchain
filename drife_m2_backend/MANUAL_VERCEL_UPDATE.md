# Manual Vercel Environment Variables Update Guide

## Current Contract Information (Updated)

Based on the redeployed contracts, use these values:

```
M2_RIDE_SYNC_PACKAGE_ID=0xc1e28ae1e7ed67a5d9f32e53d4fec24a2eb48a0d9a58450ba605c0a4b2febf23
M2_RIDE_SYNC_STATE_ID=0xb7d367a4498c25a6044a1e6e4dab8a4a2b6cb443b2660a0cea0b94d06cb5a837
M2_ROLE_MANAGER_ID=0x3d220fd5f521a3b6e062b4a76399501c0386e64e73332d79b0575af138664433
DRIFE_ADMIN_SUI_PRIVATE_KEY=sEzcljv7WndhH9y5bN+cH6anFXNwhJl4EmkmB6sBJkQ=
```

## Step 1: Access Vercel Dashboard

1. Go to [https://vercel.com/dashboard](https://vercel.com/dashboard)
2. Sign in to your account
3. Find and click on your `drife-m2-backend` project

## Step 2: Delete Existing Environment Variables

1. Click on **Settings** tab
2. Click on **Environment Variables** in the left sidebar
3. **DELETE** all existing environment variables:
   - `M2_RIDE_SYNC_PACKAGE_ID`
   - `M2_RIDE_SYNC_STATE_ID` 
   - `M2_ROLE_MANAGER_ID`
   - `DRIFE_ADMIN_SUI_PRIVATE_KEY`

## Step 3: Add New Environment Variables

For each variable, click **Add New** and enter:

### Variable 1:
- **Name**: `M2_RIDE_SYNC_PACKAGE_ID`
- **Value**: `0xc1e28ae1e7ed67a5d9f32e53d4fec24a2eb48a0d9a58450ba605c0a4b2febf23`
- **Environment**: Production ✓

### Variable 2:
- **Name**: `M2_RIDE_SYNC_STATE_ID`
- **Value**: `0xb7d367a4498c25a6044a1e6e4dab8a4a2b6cb443b2660a0cea0b94d06cb5a837`
- **Environment**: Production ✓

### Variable 3:
- **Name**: `M2_ROLE_MANAGER_ID`
- **Value**: `0x3d220fd5f521a3b6e062b4a76399501c0386e64e73332d79b0575af138664433`
- **Environment**: Production ✓

### Variable 4:
- **Name**: `DRIFE_ADMIN_SUI_PRIVATE_KEY`
- **Value**: `sEzcljv7WndhH9y5bN+cH6anFXNwhJl4EmkmB6sBJkQ=`
- **Environment**: Production ✓
- **✅ Mark as "Sensitive"** (click the eye icon to encrypt it)

## Step 4: Redeploy

1. After adding all variables, go to the **Deployments** tab
2. Click on the latest deployment
3. Click **Redeploy** → **Use existing Build Cache** → **Redeploy**

## Step 5: Verify Deployment

1. Wait for deployment to complete (usually 1-2 minutes)
2. Visit your production URL: https://drife-m2-backend.vercel.app
3. You should see the DRIFE M2 backend home page

## Step 6: Test APIs

Run the comprehensive test script:
```bash
./test-apis-production.sh
```

Or manually test key endpoints:

### Test 1: Home Page
```bash
curl https://drife-m2-backend.vercel.app/
```

### Test 2: Assign Role
```bash
curl -X POST https://drife-m2-backend.vercel.app/api/assign-role \
  -H "Content-Type: application/json" \
  -d '{"userAddress":"0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef","role":"Rider"}'
```

### Test 3: Request Ride
```bash
curl -X POST https://drife-m2-backend.vercel.app/api/request-ride \
  -H "Content-Type: application/json" \
  -d '{"rideId":"test123","fare":1000}'
```

## Expected Results

✅ **Success**: APIs should return status 200 with transaction digests  
❌ **Failure**: If you see errors, check:

1. All environment variables are set correctly
2. Private key is marked as sensitive/encrypted
3. Contract IDs match exactly
4. `testMode = false` in `services/sui.ts`

## Configuration Changes Made

1. ✅ Updated contract IDs in `services/sui.ts`
2. ✅ Set `testMode = false` for production use  
3. ✅ Updated local `.env.local` with new values
4. ✅ Private key updated to: `sEzcljv7WndhH9y5bN+cH6anFXNwhJl4EmkmB6sBJkQ=`

## API Endpoints Available

All endpoints are now configured for production use:

- POST `/api/assign-role` - Assign roles to users
- POST `/api/revoke-role` - Revoke roles from users  
- POST `/api/request-ride` - Request a new ride
- POST `/api/match-driver` - Match driver to ride
- POST `/api/complete-ride` - Mark ride as completed
- POST `/api/cancel-ride` - Cancel a ride
- POST `/api/archive-ride` - Archive completed/cancelled rides
- POST `/api/contract-control` - Pause/unpause contract
- POST `/api/emit-ride-info` - Emit ride info for indexers

## Troubleshooting

If APIs still fail after following these steps:

1. Check Vercel function logs in the dashboard
2. Verify the wallet address has admin permissions on the contract
3. Ensure the SUI network is accessible
4. Check that contract functions match the expected signatures

---

**Note**: This configuration uses the latest redeployed contract with `testMode = false` and the provided private key `sEzcljv7WndhH9y5bN+cH6anFXNwhJl4EmkmB6sBJkQ=`.