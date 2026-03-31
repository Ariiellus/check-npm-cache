# check-npm-cache

This script will check your npm cache and find if any of the affected packages was pulled in your machine. 

Requires jq, use `brew install jq` to install. 

Use `chmod +x check-npm-cache.sh` before usage to make it executable. 

Run with `bash check-npm-cache.sh`

Only tested on MacOS.

Based on: https://gist.github.com/phxgg/737198b6e945aba7046e9f9328576271


Attacks covered:

- 31/03/2026 - [Axios supply chain attack](https://x.com/feross/status/2038807290422370479)
- 24/11/2025 - [ENS npm package supply chain attack](https://enslabs.notion.site/ENS-update-on-npm-packages-supply-chain-attack-2b57a8b1f0ed8084b807ea445ce5c970
)