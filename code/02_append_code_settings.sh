#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && pwd)"

SOURCE_FILE="$REPO_ROOT/settings.json"
TARGET_FILE="$HOME/.config/Code/User/settings.json"
DRY_RUN=false

usage() {
	cat <<EOF
Usage: $(basename "$0") [options]

Set VS Code settings from this repo's settings file.

Options:
  -s, --source FILE    Source settings file (default: $SOURCE_FILE)
  -t, --target FILE    Target settings file (default: $TARGET_FILE)
  -n, --dry-run        Show actions without writing files
  -h, --help           Show this help

Examples:
  $(basename "$0")
  $(basename "$0") --target /tmp/settings.json
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		-s|--source)
			SOURCE_FILE="$2"
			shift 2
			;;
		-t|--target)
			TARGET_FILE="$2"
			shift 2
			;;
		-n|--dry-run)
			DRY_RUN=true
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "Unknown option: $1" >&2
			usage
			exit 2
			;;
	esac
done

if [[ ! -f "$SOURCE_FILE" ]]; then
	echo "Source settings file not found: $SOURCE_FILE" >&2
	exit 1
fi

if command -v jq >/dev/null 2>&1; then
	if ! jq -e . "$SOURCE_FILE" >/dev/null 2>&1; then
		echo "Source file is not valid JSON: $SOURCE_FILE" >&2
		exit 1
	fi
fi

TARGET_DIR="$(dirname "$TARGET_FILE")"
BACKUP_FILE="${TARGET_FILE}.bak.$(date +%Y%m%d%H%M%S)"

echo "Source : $SOURCE_FILE"
echo "Target : $TARGET_FILE"

if [[ "$DRY_RUN" == true ]]; then
	echo "Dry-run mode: no files will be changed."
	if [[ -f "$TARGET_FILE" ]]; then
		echo "Would backup existing target to: $BACKUP_FILE"
	else
		echo "Target does not exist yet; no backup needed."
	fi
	echo "Would copy source settings to target."
	exit 0
fi

mkdir -p "$TARGET_DIR"

if [[ -f "$TARGET_FILE" ]]; then
	cp -a "$TARGET_FILE" "$BACKUP_FILE"
	echo "Backup created: $BACKUP_FILE"
fi

cp -a "$SOURCE_FILE" "$TARGET_FILE"
echo "VS Code settings updated successfully."

