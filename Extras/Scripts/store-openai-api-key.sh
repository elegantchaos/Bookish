#!/bin/zsh

set -euo pipefail

readonly account="openai-api-key"
readonly server="api.openai.com"

api_key=""
trap 'unset api_key' EXIT

read -r -s "?OpenAI API key: " api_key
print

if [[ -z "$api_key" ]]; then
    print -u2 "No API key supplied; nothing was stored."
    exit 1
fi

security add-internet-password \
    -U \
    -a "$account" \
    -s "$server" \
    -w "$api_key" \
    >/dev/null

print "Stored the OpenAI API key in Keychain."
