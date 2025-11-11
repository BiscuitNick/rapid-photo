#!/bin/bash

# Test script for Lightsail API endpoints
# Tests both public and authenticated endpoints

LIGHTSAIL_URL="https://rapid-photo-dev-backend.51qxcte01q11c.us-east-1.cs.amazonlightsail.com"

echo "========================================="
echo "Testing Lightsail API Endpoints"
echo "Base URL: $LIGHTSAIL_URL"
echo "========================================="

echo ""
echo "1. Testing Health Check (Public)..."
curl -s -w "HTTP Status: %{http_code}\n" "$LIGHTSAIL_URL/actuator/health" | jq .

echo ""
echo "2. Testing Info Endpoint (Public)..."
curl -s -w "HTTP Status: %{http_code}\n" "$LIGHTSAIL_URL/actuator/info"

echo ""
echo "3. Testing Batch Status (Requires Authentication)..."
curl -s -w "HTTP Status: %{http_code}\n" "$LIGHTSAIL_URL/api/v1/uploads/batch/status"

echo ""
echo "4. Testing Get Photos (Requires Authentication)..."
curl -s -w "HTTP Status: %{http_code}\n" "$LIGHTSAIL_URL/api/v1/photos?page=0&size=20"

echo ""
echo "========================================="
echo "Test Summary:"
echo "- Public endpoints (health, info): Should return 200"
echo "- Authenticated endpoints: Should return 401 without JWT token"
echo "- To test with authentication, use the mobile/web app"
echo "========================================="
