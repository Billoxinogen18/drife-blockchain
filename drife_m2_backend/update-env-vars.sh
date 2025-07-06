#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status

echo "=========================================="
echo "DRIFE M2 Backend - Setting Vercel Environment Variables"
echo "=========================================="

# Use npx vercel directly
VERCEL_CMD="npx vercel"

# Default values for testing if not set
M2_RIDE_SYNC_PACKAGE_ID=${M2_RIDE_SYNC_PACKAGE_ID:-"0xb527efb9252944cb36c454c02a599c62244f509021208b401a403000d52af576"}
M2_RIDE_SYNC_STATE_ID=${M2_RIDE_SYNC_STATE_ID:-"0x74eff8e36662cd47344b8fdf76443a55c22c8d67dbfaf7b67224e223ddede728"}
M2_ROLE_MANAGER_ID=${M2_ROLE_MANAGER_ID:-"0xeca87408e738979e76ec3bf9793b92a850359e6a75b8b23c3183771e73e32abf"}
DRIFE_ADMIN_SUI_PRIVATE_KEY=${DRIFE_ADMIN_SUI_PRIVATE_KEY:-"YOUR_DEFAULT_PRIVATE_KEY"}

# Function to set an environment variable
set_env_var() {
  local name=$1
  local value=$2
  
  echo "Setting $name..."
  # First try to remove if exists (ignore errors)
  $VERCEL_CMD env rm $name production --yes || true
  # Then add the new value
  $VERCEL_CMD env add $name production <<< "$value"
}

# Set all environment variables
set_env_var "M2_RIDE_SYNC_PACKAGE_ID" "$M2_RIDE_SYNC_PACKAGE_ID"
set_env_var "M2_RIDE_SYNC_STATE_ID" "$M2_RIDE_SYNC_STATE_ID"
set_env_var "M2_ROLE_MANAGER_ID" "$M2_ROLE_MANAGER_ID"
set_env_var "DRIFE_ADMIN_SUI_PRIVATE_KEY" "$DRIFE_ADMIN_SUI_PRIVATE_KEY"

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