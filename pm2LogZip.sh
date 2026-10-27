
#!/usr/bin/env bash
set -Eeuo pipefail

LOG_DIR="/root/.pm2/logs"
ARCHIVE_DIR="/root/pm2-log-archives"

DAY="${1:-$(date -d yesterday +%F)}"

# Validate the date format and calendar date.
if ! [[ "$DAY" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] ||
   [[ "$(date -d "$DAY" +%F 2>/dev/null || true)" != "$DAY" ]]; then
    echo "Usage: $0 YYYY-MM-DD"
    exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
    echo "Installing zip..."
    apt-get update
    apt-get install -y zip
fi

mkdir -p "$ARCHIVE_DIR"

ARCHIVE="$ARCHIVE_DIR/pm2-logs-${DAY}.zip"

# Select only rotated logs bearing the requested date.
mapfile -d '' FILES < <(
    find "$LOG_DIR" -maxdepth 1 -type f \
        -name "*__${DAY}.log" -print0
)

if (( ${#FILES[@]} == 0 )); then
    echo "No rotated PM2 logs found for $DAY in $LOG_DIR"
    exit 1
fi

# Rebuild the archive on reruns so removed logs aren't left inside it.
rm -f "$ARCHIVE"
zip -q -9 -j "$ARCHIVE" "${FILES[@]}"

echo "Created: $ARCHIVE"
echo "Log files included: ${#FILES[@]}"
du -h "$ARCHIVE"
