#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status

echo "=========================================="
echo "DRIFE M2 Ride Sync Backend API Tests - PRODUCTION"
echo "Updated Contract IDs and Test Mode: FALSE"
echo "=========================================="

# Define variables
API_BASE_URL="https://drife-m2-backend.vercel.app/api"
TEST_RIDE_ID="test_ride_$(date +%s)"
TEST_USER_ADDRESS="0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
TEST_DRIVER_ADDRESS="0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"
TEST_FARE=1000

echo "Testing Configuration:"
echo "API Base URL: $API_BASE_URL"
echo "Test Ride ID: $TEST_RIDE_ID"
echo "Test User Address: $TEST_USER_ADDRESS"
echo "Test Driver Address: $TEST_DRIVER_ADDRESS"
echo "Test Fare: $TEST_FARE"
echo ""

# Function to make API calls and display results
call_api() {
    local endpoint=$1
    local data=$2
    local description=$3
    
    echo -e "\n===========================================" 
    echo "Testing: $description"
    echo "==========================================="
    echo "Endpoint: $endpoint"
    echo "Request Payload: $data"
    echo ""
    
    echo "Making API call..."
    response=$(curl -s -w "\nHTTP_STATUS:%{http_code}\nTIME_TOTAL:%{time_total}" \
        -X POST "$API_BASE_URL/$endpoint" \
        -H "Content-Type: application/json" \
        -d "$data")
        
    # Extract HTTP status and response body
    http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
    time_total=$(echo "$response" | grep "TIME_TOTAL:" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/HTTP_STATUS:/,$d')
    
    echo "HTTP Status: $http_status"
    echo "Response Time: ${time_total}s"
    echo "Response Body: $response_body"
    
    # Check if response indicates success
    if [ "$http_status" = "200" ]; then
        if echo "$response_body" | grep -q "error"; then
            echo "❌ TEST FAILED - Error in response body"
        else
            echo "✅ TEST PASSED - Success"
        fi
    else
        echo "❌ TEST FAILED - HTTP Status: $http_status"
    fi
    
    echo "===========================================" 
}

echo "Starting comprehensive API tests..."
echo ""

# Test 1: Health Check (Home page)
echo "===========================================" 
echo "Testing: Home Page / Health Check"
echo "==========================================="
echo "Endpoint: https://drife-m2-backend.vercel.app/"
echo ""

home_response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" https://drife-m2-backend.vercel.app/)
home_status=$(echo "$home_response" | grep "HTTP_STATUS:" | cut -d: -f2)
home_body=$(echo "$home_response" | sed '/HTTP_STATUS:/,$d')

echo "HTTP Status: $home_status"
if [ "$home_status" = "200" ]; then
    echo "✅ HOME PAGE ACCESSIBLE"
else
    echo "❌ HOME PAGE INACCESSIBLE - HTTP Status: $home_status"
fi
echo "===========================================" 

# Test 2: Assign Admin Role to Test User
call_api "assign-role" \
    "{\"userAddress\":\"$TEST_USER_ADDRESS\",\"role\":\"Admin\"}" \
    "Assign Admin Role to Test User"

# Test 3: Assign Rider Role to Test User  
call_api "assign-role" \
    "{\"userAddress\":\"$TEST_USER_ADDRESS\",\"role\":\"Rider\"}" \
    "Assign Rider Role to Test User"

# Test 4: Assign Driver Role to Test Driver
call_api "assign-role" \
    "{\"userAddress\":\"$TEST_DRIVER_ADDRESS\",\"role\":\"Driver\"}" \
    "Assign Driver Role to Test Driver"

# Test 5: Contract Control - Check Pause Function
call_api "contract-control" \
    "{\"action\":\"pause\"}" \
    "Pause Contract"

# Test 6: Contract Control - Check Unpause Function
call_api "contract-control" \
    "{\"action\":\"unpause\"}" \
    "Unpause Contract"

# Test 7: Request New Ride
call_api "request-ride" \
    "{\"rideId\":\"$TEST_RIDE_ID\",\"fare\":$TEST_FARE}" \
    "Request New Ride"

# Test 8: Match Driver to Ride
call_api "match-driver" \
    "{\"rideId\":\"$TEST_RIDE_ID\",\"driverAddress\":\"$TEST_DRIVER_ADDRESS\"}" \
    "Match Driver to Ride"

# Test 9: Complete Ride
call_api "complete-ride" \
    "{\"rideId\":\"$TEST_RIDE_ID\"}" \
    "Complete Ride"

# Test 10: Emit Ride Information for Indexers
call_api "emit-ride-info" \
    "{\"rideId\":\"$TEST_RIDE_ID\"}" \
    "Emit Full Ride Information for Indexers"

# Test 11: Archive Completed Ride
call_api "archive-ride" \
    "{\"rideId\":\"$TEST_RIDE_ID\"}" \
    "Archive Completed Ride"

# Test 12: Cancel Ride Test (with new ride)
TEST_CANCEL_RIDE_ID="cancel_test_$(date +%s)"
call_api "request-ride" \
    "{\"rideId\":\"$TEST_CANCEL_RIDE_ID\",\"fare\":$TEST_FARE}" \
    "Request Ride for Cancellation Test"

call_api "cancel-ride" \
    "{\"rideId\":\"$TEST_CANCEL_RIDE_ID\"}" \
    "Cancel Ride"

# Test 13: Revoke Role Test
call_api "revoke-role" \
    "{\"userAddress\":\"$TEST_DRIVER_ADDRESS\",\"role\":\"Driver\"}" \
    "Revoke Driver Role from Test Driver"

echo ""
echo "=========================================="
echo "API TESTING COMPLETE!"
echo "=========================================="
echo ""
echo "Summary of tests performed:"
echo "1. ✓ Home page accessibility"
echo "2. ✓ Role management (assign/revoke)"
echo "3. ✓ Contract control (pause/unpause)"
echo "4. ✓ Ride lifecycle (request → match → complete → archive)"
echo "5. ✓ Ride cancellation flow"
echo "6. ✓ Ride information emission for indexers"
echo ""
echo "Please review the test results above."
echo "All tests should show '✅ TEST PASSED' if the APIs are working correctly."
echo ""
echo "If you see any '❌ TEST FAILED' results, check:"
echo "1. Vercel environment variables are set correctly"
echo "2. Contract IDs match the deployed contract"
echo "3. Private key has proper permissions on the contract"
echo "4. testMode is set to false in services/sui.ts"
echo "=========================================="