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

# Updated values with redeployed contract IDs
M2_RIDE_SYNC_PACKAGE_ID=${M2_RIDE_SYNC_PACKAGE_ID:-"0xc1e28ae1e7ed67a5d9f32e53d4fec24a2eb48a0d9a58450ba605c0a4b2febf23"}
M2_RIDE_SYNC_STATE_ID=${M2_RIDE_SYNC_STATE_ID:-"0xb7d367a4498c25a6044a1e6e4dab8a4a2b6cb443b2660a0cea0b94d06cb5a837"}
M2_ROLE_MANAGER_ID=${M2_ROLE_MANAGER_ID:-"0x3d220fd5f521a3b6e062b4a76399501c0386e64e73332d79b0575af138664433"}
DRIFE_ADMIN_SUI_PRIVATE_KEY=${DRIFE_ADMIN_SUI_PRIVATE_KEY:-"sEzcljv7WndhH9y5bN+cH6anFXNwhJl4EmkmB6sBJkQ="}

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

# Delete all existing environment variables first
echo "Removing existing environment variables..."
$VERCEL_CMD env rm M2_RIDE_SYNC_PACKAGE_ID production --yes || true
$VERCEL_CMD env rm M2_RIDE_SYNC_STATE_ID production --yes || true
$VERCEL_CMD env rm M2_ROLE_MANAGER_ID production --yes || true
$VERCEL_CMD env rm DRIFE_ADMIN_SUI_PRIVATE_KEY production --yes || true

echo "Setting new environment variables..."
# Set all environment variables with updated values
set_env_var "M2_RIDE_SYNC_PACKAGE_ID" "$M2_RIDE_SYNC_PACKAGE_ID"
set_env_var "M2_RIDE_SYNC_STATE_ID" "$M2_RIDE_SYNC_STATE_ID"
set_env_var "M2_ROLE_MANAGER_ID" "$M2_ROLE_MANAGER_ID"
set_env_var "DRIFE_ADMIN_SUI_PRIVATE_KEY" "$DRIFE_ADMIN_SUI_PRIVATE_KEY"

echo "=========================================="
echo "Environment variables updated successfully!"
echo "=========================================="

# Trigger a redeployment
echo "Redeploying to apply environment variables..."
$VERCEL_CMD --prod

echo "=========================================="
echo "Your API should now be fully functional at:"
echo "https://drife-m2-backend.vercel.app"
echo "==========================================" 