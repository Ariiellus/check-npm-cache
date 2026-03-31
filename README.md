# check-npm-cache

This script checks for known indicators of compromise from the axios supply chain incident.

It supports two different scopes:

- npm cache mode: checks the current user's npm cache on the machine
- path mode: recursively scans project files under a directory such as `~/Documents`
- deep path mode: recursively scans project files and nested `node_modules` manifests

What it currently looks for:

- `axios@1.14.1`
- `plain-crypto-js@4.2.1`

Requirements:

- `bash`
- `jq`
- `npm` for cache mode
- `rg` for path mode

Install dependencies:

- macOS: `brew install jq ripgrep`
- Debian/Ubuntu: `sudo apt-get install jq ripgrep`
- Fedora/RHEL: `sudo dnf install jq ripgrep`
- Arch: `sudo pacman -S jq ripgrep`

Usage:

```bash
chmod +x latest.sh
```

Check the user-level npm cache:

```bash
bash latest.sh
```

Or explicitly:

```bash
bash latest.sh --cache
```

Recursively scan a directory tree:

```bash
bash latest.sh --path ~/Documents
```

Recursively scan a directory tree including installed packages in `node_modules`:

```bash
bash latest.sh --deep-path ~/Documents
```

That path mode scans these files under the given directory:

- `package-lock.json`
- `npm-shrinkwrap.json`
- `package.json`
- `pnpm-lock.yaml`
- `yarn.lock`

Deep path mode scans the same files plus:

- `node_modules/**/package.json`

Notes:

- Cache mode does not scan only the current folder. It queries the npm cache for the current user with `npm cache ls`.
- Path mode is the right option if the goal is to cover all subfolders under a route like `~/Documents`.
- Deep path mode is the right option if the goal is to also catch IOC versions that only exist inside installed dependencies under nested `node_modules` directories.
- `package.json` matches are strongest when the dependency is pinned exactly. Lockfile matches are generally more reliable for installed versions.
- Deep path mode is slower and noisier because it walks installed package trees.
- As of March 31, 2026, the npm registry shows `axios` rolled back so the `latest` dist-tag points to `1.14.0`.
- `plain-crypto-js` has since been replaced by an npm security holding package, but `plain-crypto-js@4.2.1` remains an indicator of prior exposure.

Sources:

- https://x.com/feross/status/2038807290422370479
- https://registry.npmjs.org/axios
- https://registry.npmjs.org/plain-crypto-js
