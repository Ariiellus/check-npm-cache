# check-npm-cache

This script checks the npm cache for known indicators of compromise from the axios supply chain incident.

It does not scan only the current folder. It queries the npm cache for the current user with `npm cache ls`, so it will report whether those package versions were cached anywhere on the machine for that npm account.

Requirements:

- `bash`
- `npm`
- `jq`

Install `jq`:

- macOS: `brew install jq`
- Debian/Ubuntu: `sudo apt-get install jq`
- Fedora/RHEL: `sudo dnf install jq`
- Arch: `sudo pacman -S jq`

Usage:

```bash
chmod +x latest.sh
bash latest.sh
```

Current indicators checked:

- `axios@1.14.1`
- `plain-crypto-js@4.2.1`

Notes:

- The npm registry state changed after the incident. As of March 31, 2026, `axios` was rolled back so the `latest` dist-tag points to `1.14.0`.
- `plain-crypto-js` has since been replaced by an npm security holding package, but `plain-crypto-js@4.2.1` in cache is still an indicator of prior exposure.

Sources:

- https://x.com/feross/status/2038807290422370479
- https://registry.npmjs.org/axios
- https://registry.npmjs.org/plain-crypto-js


Attacks covered:

- 31/03/2026 - [Axios supply chain attack](https://x.com/feross/status/2038807290422370479)
- 24/11/2025 - [ENS npm package supply chain attack](https://enslabs.notion.site/ENS-update-on-npm-packages-supply-chain-attack-2b57a8b1f0ed8084b807ea445ce5c970
)
