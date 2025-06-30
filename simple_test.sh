#!/bin/bash

echo "=== Testing Journal Labeler Service ==="
echo

# Wait for service to be ready
echo "Waiting for service to start..."
sleep 5

# Test health endpoint
echo "Testing /health endpoint..."
HEALTH_RESPONSE=$(curl -s -w "%{http_code}" http://localhost:8001/health)
HTTP_CODE="${HEALTH_RESPONSE: -3}"
RESPONSE_BODY="${HEALTH_RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Health check passed"
    echo "Response: $RESPONSE_BODY"
else
    echo "❌ Health check failed (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo

# Test categories endpoint
echo "Testing /categories endpoint..."
CATEGORIES_RESPONSE=$(curl -s -w "%{http_code}" http://localhost:8001/categories)
HTTP_CODE="${CATEGORIES_RESPONSE: -3}"
RESPONSE_BODY="${CATEGORIES_RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Categories endpoint passed"
    echo "Response: $RESPONSE_BODY" | head -c 200
    echo "..."
else
    echo "❌ Categories endpoint failed (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo

# Test analysis endpoint
echo "Testing /analyze endpoint..."
ANALYSIS_RESPONSE=$(curl -s -w "%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -d '{"title": "Great Day", "content": "Today was amazing! I accomplished so much and feel really happy and motivated."}' \
  http://localhost:8001/analyze)

HTTP_CODE="${ANALYSIS_RESPONSE: -3}"
RESPONSE_BODY="${ANALYSIS_RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Analysis endpoint passed"
    echo "Response: $RESPONSE_BODY" | head -c 300
    echo "..."
else
    echo "❌ Analysis endpoint failed (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo
echo "=== Test Complete ===" 