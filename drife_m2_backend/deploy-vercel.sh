#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status

echo "=========================================="
echo "DRIFE M2 Ride Sync Backend - Vercel Deployment"
echo "=========================================="

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null
then
    echo "Vercel CLI is not installed. Attempting to install..."
    npm install -g vercel || {
        echo "Failed to install Vercel CLI globally. Trying locally..."
        npm install vercel --no-save
        VERCEL_CMD="npx vercel"
    }
else
    VERCEL_CMD="vercel"
fi

# Login to Vercel if not already logged in
echo "Checking Vercel authentication..."
$VERCEL_CMD whoami &> /dev/null || {
    echo "Not logged in to Vercel. Please follow the login steps..."
    $VERCEL_CMD login
}

# Deploy to Vercel production
echo "Deploying to Vercel production..."
$VERCEL_CMD --prod

echo "=========================================="
echo "Deployment complete! Your API is now live."
echo "==========================================="

echo "NOTE: After deployment, you need to set the following environment variables in the Vercel dashboard:"
echo "- M2_RIDE_SYNC_PACKAGE_ID"
echo "- M2_RIDE_SYNC_STATE_ID"
echo "- M2_ROLE_MANAGER_ID"
echo "- DRIFE_ADMIN_SUI_PRIVATE_KEY"
echo ""
echo "To set these variables:"
echo "1. Go to the Vercel Dashboard"
echo "2. Select your project 'drife-m2-backend'"
echo "3. Go to Settings > Environment Variables"
echo "4. Add each variable with its corresponding value"
echo "5. Make sure to mark DRIFE_ADMIN_SUI_PRIVATE_KEY as 'Encrypt'"
echo ""
echo "After setting these variables, redeploy your project with:"
echo "$VERCEL_CMD --prod" 