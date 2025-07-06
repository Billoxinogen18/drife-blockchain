# Deploying to Vercel

This document provides step-by-step instructions for deploying the DRIFE M2 Backend to Vercel.

## Prerequisites

- A Vercel account (sign up at [vercel.com](https://vercel.com))
- Git repository with your project code
- Access to the SUI contract IDs and admin private key

## Deployment Steps

### 1. Connect to GitHub

1. Log in to your Vercel account
2. Click "Add New..." and select "Project"
3. Import your GitHub repository containing the DRIFE M2 backend code
4. Select the repository from the list

### 2. Configure Project

1. Configure your project with the following settings:
   - **Framework Preset**: Next.js
   - **Root Directory**: `./` (or the path to your `drife_m2_backend` folder if in a subdirectory)
   - **Build Command**: `npm run build`
   - **Output Directory**: `.next`

### 3. Set Environment Variables

Add the following environment variables:

- `M2_RIDE_SYNC_PACKAGE_ID`: Your deployed package ID (e.g., `0x123...abc`)
- `M2_RIDE_SYNC_STATE_ID`: Your state object ID (e.g., `0x456...def`)
- `M2_ROLE_MANAGER_ID`: Your role manager object ID (e.g., `0x789...ghi`)
- `DRIFE_ADMIN_SUI_PRIVATE_KEY`: Your admin private key (mark as encrypted)

### 4. Deploy

Click "Deploy" to start the deployment process.

## Testing with the Deployed API

Once your backend is deployed to Vercel, you'll get a production URL like:
```
https://drife-m2-backend.vercel.app
```

Update your test script to use this URL instead of localhost:

```bash
# In test.sh, change:
API_BASE_URL="http://localhost:3000/api"

# To:
API_BASE_URL="https://drife-m2-backend.vercel.app/api"
```

Then run the test script against your production deployment:

```bash
./test.sh
```

## Continuous Deployment

Vercel automatically sets up continuous deployment from your GitHub repository. Any changes pushed to your main branch will trigger a new deployment.

## Troubleshooting

If you encounter any issues:

1. Check the Vercel deployment logs
2. Verify environment variables are set correctly
3. Ensure your SUI network configuration (testnet) is correct
4. Confirm your admin private key has the necessary permissions 