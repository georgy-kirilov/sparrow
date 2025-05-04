#!/usr/bin/env bash
set -euo pipefail

API_TOKEN="${CF_API_TOKEN}"
ZONE_ID="${CF_ZONE_ID}"
RECORD_NAME="${FULL_DOMAIN}"
RECORD_TYPE="A"
RECORD_CONTENT="${DROPLET_IP}"
TTL=300
PROXIED=false

record_id=$(curl -s \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=${RECORD_TYPE}&name=${RECORD_NAME}" \
  | jq -r '.result[0].id // empty')

payload=$(jq -nc \
  --arg type "$RECORD_TYPE" \
  --arg name "$RECORD_NAME" \
  --arg content "$RECORD_CONTENT" \
  --argjson ttl $TTL \
  --argjson proxied $PROXIED \
  '{type: $type, name: $name, content: $content, ttl: $ttl, proxied: $proxied}')

if [[ -n "$record_id" ]]; then
  curl -s -X PUT \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H "Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${record_id}" \
    --data "$payload"
else
  curl -s -X POST \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H "Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
    --data "$payload"
fi
