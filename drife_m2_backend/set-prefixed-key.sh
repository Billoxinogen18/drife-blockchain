#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status

echo "=========================================="
echo "DRIFE M2 Backend - Setting Proper SUI Private Key Format"
echo "=========================================="

# Use npx vercel directly
VERCEL_CMD="npx vercel"

# For Ed25519 keypairs, the SUI SDK expects a 32-byte private key with specific encoding:
# For testing purposes only, using the prefixed format for Ed25519
# This is a properly formatted Ed25519 testing key - DO NOT USE IN PRODUCTION
CORRECT_ADMIN_KEY="AeYaGbPZdTHQCkVV8EADTSr3bp2hkp3YQJdXdrcQDrvJ"

# Set the admin key
echo "Setting DRIFE_ADMIN_SUI_PRIVATE_KEY with correct SUI SDK format..."
$VERCEL_CMD env rm DRIFE_ADMIN_SUI_PRIVATE_KEY production --yes || true
echo "$CORRECT_ADMIN_KEY" | $VERCEL_CMD env add DRIFE_ADMIN_SUI_PRIVATE_KEY production

echo "=========================================="
echo "Admin key updated successfully!"
echo "=========================================="

# Trigger a redeployment
echo "Redeploying to apply new admin key..."
$VERCEL_CMD --prod

echo "=========================================="
echo "Your API should now be functional at:"
echo "https://drife-m2-backend.vercel.app"
echo "==========================================" 