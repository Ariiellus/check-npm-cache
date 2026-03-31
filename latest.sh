#!/usr/bin/env bash
set -euo pipefail

# Customized for npm supply chain incident checks:
#
# https://x.com/feross/status/2038807290422370479
#
# Axios incident note:
# - axios@1.14.1 was published on 2026-03-31 and reported as compromised.
# - npm registry metadata now shows axios "latest" rolled back to 1.14.0.
# - plain-crypto-js has since been replaced with an npm security holding package,
#   but seeing axios@1.14.1 or plain-crypto-js@4.2.1 locally is still an IOC.

packages_json='[
  {"name":"axios","version":"1.14.1"},
  {"name":"plain-crypto-js","version":"4.2.1"}
]'

usage() {
  cat <<'EOF'
Usage:
  bash latest.sh
  bash latest.sh --cache
  bash latest.sh --path /path/to/root
  bash latest.sh --deep-path /path/to/root

Modes:
  --cache        Check the current user's npm cache for known IOC package versions.
  --path <dir>   Recursively scan package manifests and lockfiles under a directory.
  --deep-path <dir>
                 Recursively scan manifests, lockfiles, and nested node_modules package manifests.

Notes:
  - Cache mode checks the user-level npm cache via `npm cache ls`.
  - Path mode scans `package-lock.json`, `npm-shrinkwrap.json`, `package.json`,
    `pnpm-lock.yaml`, and `yarn.lock` below the provided directory.
  - Deep path mode includes `node_modules/**/package.json`, which is slower and noisier,
    but can catch installed packages that are no longer referenced in lockfiles.
EOF
}

require_command() {
  local cmd="$1"
  local msg="$2"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: $msg"
    exit 1
  fi
}

scan_cache() {
  require_command jq "'jq' is required (to parse the JSON array-of-objects)."
  require_command npm "'npm' is required for cache mode."

  local names
  local npm_output
  local tmpfile

  names=$(printf '%s\n' "$packages_json" | jq -r '.[].name' | tr '\n' ' ')

  echo "Running 'npm cache ls' for given packages..."
  npm_output="$(npm cache ls $names 2>/dev/null || true)"

  echo
  echo "Packages found in npm cache:"

  tmpfile=$(mktemp)

  printf '%s\n' "$packages_json" | jq -r '.[] | "\(.name)\t\(.version)"' | \
  while IFS=$'\t' read -r name version; do
    if [ -n "$name" ] && printf '%s\n' "$npm_output" | grep -q "${name}-${version}"; then
      echo "• $name@$version"
      echo 1 >> "$tmpfile"
    fi
  done

  if ! grep -q 1 "$tmpfile" 2>/dev/null; then
    echo "(none)"
  fi

  rm -f "$tmpfile"
}

scan_json_file() {
  local file="$1"
  local tmpfile="$2"
  local name
  local version
  local found

  while IFS=$'\t' read -r name version; do
    found=$(jq -er \
      --arg name "$name" \
      --arg version "$version" \
      '
      if .packages? then
        (.packages["node_modules/" + $name].version? == $version)
        or (.packages[$name].version? == $version)
      else
        false
      end
      or (.dependencies[$name].version? == $version)
      or (.packages[$name].version? == $version)
      or (.dependencies[$name]? == $version)
      or (.devDependencies[$name]? == $version)
      or (.optionalDependencies[$name]? == $version)
      or (.peerDependencies[$name]? == $version)
      or any(
        .. | objects;
        (.version? == $version)
        and (
          (.name? == $name)
          or ((.resolved? // "") | contains("/" + $name + "/-/"))
          or ((.from? // "") | contains($name + "@"))
        )
      )
      ' "$file" 2>/dev/null || true)

    if [ "$found" = "true" ]; then
      printf '• %s -> %s@%s\n' "$file" "$name" "$version"
      echo 1 >> "$tmpfile"
    fi
  done < <(printf '%s\n' "$packages_json" | jq -r '.[] | "\(.name)\t\(.version)"')
}

scan_text_lockfile() {
  local file="$1"
  local tmpfile="$2"
  local name
  local version

  while IFS=$'\t' read -r name version; do
    if rg -q -e "${name}@[^[:space:]]*${version}" -e "${name}.*${version}" "$file"; then
      printf '• %s -> %s@%s\n' "$file" "$name" "$version"
      echo 1 >> "$tmpfile"
    fi
  done < <(printf '%s\n' "$packages_json" | jq -r '.[] | "\(.name)\t\(.version)"')
}

scan_path() {
  local scan_root="$1"
  local include_node_modules="${2:-false}"
  local tmpfile
  local file

  require_command jq "'jq' is required for JSON manifest scanning."
  require_command rg "'rg' is required for recursive path scanning."

  if [ ! -d "$scan_root" ]; then
    echo "Error: directory not found: $scan_root"
    exit 1
  fi

  echo "Scanning project files under: $scan_root"
  echo
  if [ "$include_node_modules" = "true" ]; then
    echo "IOC references found in manifests, lockfiles, and node_modules package manifests:"
  else
    echo "IOC references found in manifests and lockfiles:"
  fi

  tmpfile=$(mktemp)

  while IFS= read -r file; do
    case "$(basename "$file")" in
      package-lock.json|npm-shrinkwrap.json|package.json)
        scan_json_file "$file" "$tmpfile"
        ;;
      pnpm-lock.yaml|yarn.lock)
        scan_text_lockfile "$file" "$tmpfile"
        ;;
    esac
  done < <(
    if [ "$include_node_modules" = "true" ]; then
      rg --files "$scan_root" \
        -g 'package-lock.json' \
        -g 'npm-shrinkwrap.json' \
        -g 'package.json' \
        -g 'pnpm-lock.yaml' \
        -g 'yarn.lock' \
        -g '**/node_modules/**/package.json' \
        -g '!**/.git/**'
    else
      rg --files "$scan_root" \
        -g 'package-lock.json' \
        -g 'npm-shrinkwrap.json' \
        -g 'package.json' \
        -g 'pnpm-lock.yaml' \
        -g 'yarn.lock' \
        -g '!**/node_modules/**' \
        -g '!**/.git/**'
    fi
  )

  if ! grep -q 1 "$tmpfile" 2>/dev/null; then
    echo "(none)"
  fi

  rm -f "$tmpfile"
}

main() {
  case "${1-}" in
    ""|--cache)
      scan_cache
      ;;
    --path)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      scan_path "$2"
      ;;
    --deep-path)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      scan_path "$2" "true"
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Error: unknown argument: $1"
      echo
      usage
      exit 1
      ;;
  esac
}

main "$@"
