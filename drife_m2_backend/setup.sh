#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status

echo "=========================================="
echo "DRIFE M2 Ride Sync Backend Setup"
echo "=========================================="

# Install dependencies
echo "Installing dependencies..."
npm install

# Create .env.local file if it doesn't exist
if [ ! -f .env.local ]; then
    echo "Creating .env.local file..."
    cat > .env.local << EOL
# SUI Network Configuration
# Replace these values with the actual deployed contract addresses
M2_RIDE_SYNC_PACKAGE_ID=0x__YOUR_PACKAGE_ID_HERE__
M2_RIDE_SYNC_STATE_ID=0x__YOUR_STATE_ID_HERE__
M2_ROLE_MANAGER_ID=0x__YOUR_ROLE_MANAGER_ID_HERE__

# Admin Private Key (NEVER commit the actual key to version control)
DRIFE_ADMIN_SUI_PRIVATE_KEY=YOUR_ADMIN_PRIVATE_KEY_HERE

# API Port (optional, default is 3000)
PORT=3000
EOL
    echo ".env.local file created. Please update it with your actual values."
else
    echo ".env.local file already exists."
fi

# Build the project
echo "Building the project..."
npm run build

echo "=========================================="
echo "Setup complete!"
echo "To start the development server: npm run dev"
echo "To start the production server: npm run start"
echo "==========================================" 