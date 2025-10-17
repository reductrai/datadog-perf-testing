#!/bin/bash

# Import Datadog dashboard via API
# Usage: ./import-dashboard.sh

set -e

# Check for Datadog API key
if [ -z "$DD_API_KEY" ]; then
    echo "Error: DD_API_KEY environment variable not set"
    echo "Usage: export DD_API_KEY=your_api_key && ./import-dashboard.sh"
    exit 1
fi

if [ -z "$DD_APP_KEY" ]; then
    echo "Error: DD_APP_KEY environment variable not set"
    echo "Usage: export DD_APP_KEY=your_app_key && ./import-dashboard.sh"
    exit 1
fi

# Datadog API endpoint
DD_SITE="${DD_SITE:-datadoghq.com}"
API_URL="https://api.${DD_SITE}/api/v1/dashboard"

echo "Creating dashboard via Datadog API..."

# Create dashboard using the JSON file
RESPONSE=$(curl -X POST "${API_URL}" \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  -d @datadog-iss-dashboard.json)

# Parse response
DASHBOARD_ID=$(echo "$RESPONSE" | jq -r '.id // empty')

if [ -n "$DASHBOARD_ID" ]; then
    echo "✅ Dashboard created successfully!"
    echo "Dashboard ID: $DASHBOARD_ID"
    echo "URL: https://app.${DD_SITE}/dashboard/${DASHBOARD_ID}"
else
    echo "❌ Failed to create dashboard"
    echo "Response: $RESPONSE"
    exit 1
fi
