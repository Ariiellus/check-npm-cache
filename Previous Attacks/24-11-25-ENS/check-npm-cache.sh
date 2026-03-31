# Customized for the ENS npm package supply chain attack:

# https://enslabs.notion.site/ENS-update-on-npm-packages-supply-chain-attack-2b57a8b1f0ed8084b807ea445ce5c970

#!/usr/bin/env bash
set -euo pipefail

packages_json='[
  {"name":"backslash","version":"0.2.1"},
  {"name":"@ensdomains/address-encoder","version":"1.1.5"},
  {"name":"@ensdomains/blacklist","version":"1.0.1"},
  {"name":"@ensdomains/buffer","version":"0.1.2"},
  {"name":"@ensdomains/ccip-read-cf-worker","version":"0.0.4"},
  {"name":"@ensdomains/ccip-read-dns-gateway","version":"0.1.1"},
  {"name":"@ensdomains/ccip-read-router","version":"0.0.7"},
  {"name":"@ensdomains/ccip-read-worker-viem","version":"0.0.4"},
  {"name":"@ensdomains/content-hash","version":"3.0.1"},
  {"name":"@ensdomains/curvearithmetics","version":"1.0.1"},
  {"name":"@ensdomains/cypress-metamask","version":"1.2.1"},
  {"name":"@ensdomains/dnsprovejs","version":"0.5.3"},
  {"name":"@ensdomains/dnssec-oracle-anchors","version":"0.0.2"},
  {"name":"@ensdomains/dnssecoraclejs","version":"0.2.9"},
  {"name":"@ensdomains/durin","version":"0.1.2"},
  {"name":"@ensdomains/durin-middleware","version":"0.0.2"},
  {"name":"@ensdomains/ens-archived-contracts","version":"0.0.3"},
  {"name":"@ensdomains/ens-avatar","version":"1.0.4"},
  {"name":"@ensdomains/ens-contracts","version":"1.6.1"},
  {"name":"@ensdomains/ens-test-env","version":"1.0.2"},
  {"name":"@ensdomains/ens-validation","version":"0.1.1"},
  {"name":"@ensdomains/ensjs","version":"4.0.3"},
  {"name":"@ensdomains/ensjs-react","version":"0.0.5"},
  {"name":"@ensdomains/eth-ens-namehash","version":"2.0.16"},
  {"name":"@ensdomains/hackathon-registrar","version":"1.0.5"},
  {"name":"@ensdomains/hardhat-chai-matchers-viem","version":"0.1.15"},
  {"name":"@ensdomains/hardhat-toolbox-viem-extended","version":"0.0.6"},
  {"name":"@ensdomains/mock","version":"2.1.52"},
  {"name":"@ensdomains/name-wrapper","version":"1.0.1"},
  {"name":"@ensdomains/offchain-resolver-contracts","version":"0.2.2"},
  {"name":"@ensdomains/op-resolver-contracts","version":"0.0.2"},
  {"name":"@ensdomains/react-ens-address","version":"0.0.32"},
  {"name":"@ensdomains/renewal","version":"0.0.13"},
  {"name":"@ensdomains/renewal-widget","version":"0.1.10"},
  {"name":"@ensdomains/reverse-records","version":"1.0.1"},
  {"name":"@ensdomains/server-analytics","version":"0.0.2"},
  {"name":"@ensdomains/solsha1","version":"0.0.4"},
  {"name":"@ensdomains/subdomain-registrar","version":"0.2.4"},
  {"name":"@ensdomains/test-utils","version":"1.3.1"},
  {"name":"@ensdomains/thorin","version":"0.6.51"},
  {"name":"@ensdomains/ui","version":"3.4.6"},
  {"name":"@ensdomains/unicode-confusables","version":"0.1.1"},
  {"name":"@ensdomains/unruggable-gateways","version":"0.0.3"},
  {"name":"@ensdomains/vite-plugin-i18next-loader","version":"4.0.4"},
  {"name":"@ensdomains/web3modal","version":"1.10.2"}
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