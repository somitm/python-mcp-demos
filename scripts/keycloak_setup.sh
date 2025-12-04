#!/bin/bash
set -e

BASE_URL="https://mcproutes.niceground-98809e7b.eastus2.azurecontainerapps.io"

echo "Getting admin token..."
ACCESS_TOKEN=$(curl -s -X POST "$BASE_URL/auth/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=pythonmcp" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ "$ACCESS_TOKEN" == "null" ] || [ -z "$ACCESS_TOKEN" ]; then
  echo "Failed to get token"
  exit 1
fi
echo "Token obtained!"

SCOPE_ID="fa8082ab-86f9-4ac9-961f-15b2f1a32482"

echo "Adding mcp-server as default scope..."
curl -s -X PUT "$BASE_URL/auth/admin/realms/mcp/default-default-client-scopes/$SCOPE_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
echo "Done!"

echo "Getting Trusted Hosts policy ID..."
TRUSTED_HOSTS_ID=$(curl -s "$BASE_URL/auth/admin/realms/mcp/components?type=org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy" \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq -r '.[] | select(.name=="Trusted Hosts") | .id')

echo "Trusted Hosts ID: $TRUSTED_HOSTS_ID"

echo "Updating Trusted Hosts policy..."
curl -s -X PUT "$BASE_URL/auth/admin/realms/mcp/components/$TRUSTED_HOSTS_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "id":"'"$TRUSTED_HOSTS_ID"'",
    "name":"Trusted Hosts",
    "providerId":"trusted-hosts",
    "providerType":"org.keycloak.services.clientregistration.policy.ClientRegistrationPolicy",
    "parentId":"mcp",
    "config":{
      "host-sending-registration-request-must-match":["false"],
      "client-uris-must-match":["false"],
      "trusted-hosts":["*"]
    }
  }'
echo "Done!"

echo ""
echo "=== Testing DCR ==="
curl -s -X POST "$BASE_URL/auth/realms/mcp/clients-registrations/openid-connect" \
  -H "Content-Type: application/json" \
  -d '{"client_name":"test-mcp-client","redirect_uris":["http://localhost:8080/callback"]}' | jq '.'
EOF