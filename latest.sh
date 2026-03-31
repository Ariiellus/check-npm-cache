# Customized for npm supply chain incident checks:

# https://x.com/feross/status/2038807290422370479

# Axios incident note:
# - axios@1.14.1 was published on 2026-03-31 and reported as compromised.
# - npm registry metadata now shows axios "latest" rolled back to 1.14.0.
# - plain-crypto-js has since been replaced with an npm security holding package,
#   but seeing axios@1.14.1 or plain-crypto-js@4.2.1 in local cache is still an IOC.

#!/usr/bin/env bash
set -euo pipefail

packages_json='[
  {"name":"axios","version":"1.14.1"},
  {"name":"plain-crypto-js","version":"4.2.1"}
]'

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: 'jq' is required (to parse the JSON array-of-objects)."
  exit 1
fi

names=$(printf '%s\n' "$packages_json" | jq -r '.[].name' | tr '\n' ' ')

echo "Running 'npm cache ls' for given packages..."
npm_output="$(npm cache ls $names 2>/dev/null || true)"

echo
echo "Packages found in npm cache:"
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

# loop through package/version
printf '%s\n' "$packages_json" | jq -r '.[] | "\(.name)\t\(.version)"' | \
while IFS=$'\t' read -r name version; do
  if [ -n "$name" ] && printf '%s\n' "$npm_output" | grep -q "${name}-${version}"; then
    echo "• $name@$version"
    echo 1 >> "$tmpfile"
  fi
done

if ! grep -q 1 "$tmpfile"; then
  echo "(none)"
fi
