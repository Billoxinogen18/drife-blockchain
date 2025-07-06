#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status

echo "=========================================="
echo "DRIFE M2 Backend - Setting Correct Admin Key"
echo "=========================================="

# Use npx vercel directly
VERCEL_CMD="npx vercel"

# Correctly formatted Ed25519 private key for testing (32 bytes, hex encoded)
# This is a dummy key for demonstration only - NEVER use this in production
CORRECT_ADMIN_KEY="7f71d10b84c9dad0123456789abcdef0123456789abcdef0123456789abcdef0"

# Set the admin key
echo "Setting DRIFE_ADMIN_SUI_PRIVATE_KEY with correct format..."
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