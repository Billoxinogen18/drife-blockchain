#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status

echo "=========================================="
echo "DRIFE M2 Ride Sync Backend API Tests"
echo "=========================================="

# Define variables
API_BASE_URL="https://drife-m2-backend.vercel.app/api"
TEST_RIDE_ID="test_ride_$(date +%s)"
TEST_USER_ADDRESS="0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
TEST_DRIVER_ADDRESS="0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"
TEST_FARE=1000

# Function to make API calls and display results
call_api() {
    local endpoint=$1
    local data=$2
    local description=$3
    
    echo -e "\n--- Testing: $description ---"
    echo "Endpoint: $endpoint"
    echo "Request Payload: $data"
    
    response=$(curl -s -X POST "$API_BASE_URL/$endpoint" \
        -H "Content-Type: application/json" \
        -d "$data")
        
    echo "Response: $response"
    
    # Check if response contains an error
    if echo "$response" | grep -q "error"; then
        echo "⛔ TEST FAILED"
    else
        echo "✅ TEST PASSED"
    fi
}

echo "Starting API tests..."

# Test 1: Assign Rider Role
call_api "assign-role" \
    "{\"userAddress\":\"$TEST_USER_ADDRESS\",\"role\":\"Rider\"}" \
    "Assign Rider Role to User"

# Test 2: Assign Driver Role
call_api "assign-role" \
    "{\"userAddress\":\"$TEST_DRIVER_ADDRESS\",\"role\":\"Driver\"}" \
    "Assign Driver Role to User"

# Test 3: Request Ride
call_api "request-ride" \
    "{\"rideId\":\"$TEST_RIDE_ID\",\"fare\":$TEST_FARE}" \
    "Request New Ride"

# Test 4: Match Driver to Ride
call_api "match-driver" \
    "{\"rideId\":\"$TEST_RIDE_ID\",\"driverAddress\":\"$TEST_DRIVER_ADDRESS\"}" \
    "Match Driver to Ride"

# Test 5: Complete Ride
call_api "complete-ride" \
    "{\"rideId\":\"$TEST_RIDE_ID\"}" \
    "Complete Ride"

# Test 6: Emit Ride Information
call_api "emit-ride-info" \
    "{\"rideId\":\"$TEST_RIDE_ID\"}" \
    "Emit Full Ride Information"

# Test 7: Archive Ride
call_api "archive-ride" \
    "{\"rideId\":\"$TEST_RIDE_ID\"}" \
    "Archive Ride"

echo -e "\n=========================================="
echo "All tests completed!"
echo "Please verify the test results above."
echo "===========================================" 