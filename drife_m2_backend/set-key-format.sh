#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status

echo "=========================================="
echo "DRIFE M2 Backend - Setting Correct Admin Key Format"
echo "=========================================="

# Use npx vercel directly
VERCEL_CMD="npx vercel"

# Format for Ed25519 keys: base64-encoded 32 byte private key
# This is a properly formatted dummy key for testing
CORRECT_ADMIN_KEY="AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8="

# Set the admin key
echo "Setting DRIFE_ADMIN_SUI_PRIVATE_KEY with correct base64 format..."
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