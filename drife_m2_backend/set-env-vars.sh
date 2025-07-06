#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status

echo "=========================================="
echo "DRIFE M2 Backend - Setting Vercel Environment Variables"
echo "=========================================="

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null
then
    echo "Vercel CLI is not installed. Using npx..."
    VERCEL_CMD="npx vercel"
else
    VERCEL_CMD="vercel"
fi

# Default values for testing if not set
M2_RIDE_SYNC_PACKAGE_ID=${M2_RIDE_SYNC_PACKAGE_ID:-"0xb527efb9252944cb36c454c02a599c62244f509021208b401a403000d52af576"}
M2_RIDE_SYNC_STATE_ID=${M2_RIDE_SYNC_STATE_ID:-"0x74eff8e36662cd47344b8fdf76443a55c22c8d67dbfaf7b67224e223ddede728"}
M2_ROLE_MANAGER_ID=${M2_ROLE_MANAGER_ID:-"0xeca87408e738979e76ec3bf9793b92a850359e6a75b8b23c3183771e73e32abf"}
DRIFE_ADMIN_SUI_PRIVATE_KEY=${DRIFE_ADMIN_SUI_PRIVATE_KEY:-"YOUR_DEFAULT_PRIVATE_KEY"}

echo "Setting M2_RIDE_SYNC_PACKAGE_ID..."
echo "$M2_RIDE_SYNC_PACKAGE_ID" | $VERCEL_CMD env rm M2_RIDE_SYNC_PACKAGE_ID production || true
echo "$M2_RIDE_SYNC_PACKAGE_ID" | $VERCEL_CMD env add M2_RIDE_SYNC_PACKAGE_ID production

echo "Setting M2_RIDE_SYNC_STATE_ID..."
echo "$M2_RIDE_SYNC_STATE_ID" | $VERCEL_CMD env rm M2_RIDE_SYNC_STATE_ID production || true
echo "$M2_RIDE_SYNC_STATE_ID" | $VERCEL_CMD env add M2_RIDE_SYNC_STATE_ID production

echo "Setting M2_ROLE_MANAGER_ID..."
echo "$M2_ROLE_MANAGER_ID" | $VERCEL_CMD env rm M2_ROLE_MANAGER_ID production || true
echo "$M2_ROLE_MANAGER_ID" | $VERCEL_CMD env add M2_ROLE_MANAGER_ID production

echo "Setting DRIFE_ADMIN_SUI_PRIVATE_KEY..."
echo "$DRIFE_ADMIN_SUI_PRIVATE_KEY" | $VERCEL_CMD env rm DRIFE_ADMIN_SUI_PRIVATE_KEY production || true
echo "$DRIFE_ADMIN_SUI_PRIVATE_KEY" | $VERCEL_CMD env add DRIFE_ADMIN_SUI_PRIVATE_KEY production

echo "=========================================="
echo "Environment variables set successfully!"
echo "=========================================="

# Trigger a redeployment
echo "Redeploying to apply environment variables..."
$VERCEL_CMD --prod

echo "=========================================="
echo "Your API should now be fully functional at:"
echo "https://drife-m2-backend.vercel.app"
echo "==========================================" 