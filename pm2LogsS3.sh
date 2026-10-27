
#!/usr/bin/env bash
set -Eeuo pipefail

LOG_DIR="/root/.pm2/logs"
ARCHIVE_DIR="/root/pm2-log-archives"

# Set your bucket name here.
S3_BUCKET="abhijeetrana"

# Optional folder path inside the bucket.
S3_PREFIX="pm2-logs"

DAY="${1:-$(date -d yesterday +%F)}"

if ! [[ "$DAY" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] ||
   [[ "$(date -d "$DAY" +%F 2>/dev/null || true)" != "$DAY" ]]; then
    echo "Usage: $0 YYYY-MM-DD"
    exit 1
fi

if [[ "$S3_BUCKET" == "YOUR_BUCKET_NAME" ]]; then
    echo "Set S3_BUCKET in this script before running it."
    exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
    echo "AWS CLI is not installed. Install and configure it first."
    exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
    apt-get update
    apt-get install -y zip
fi

mkdir -p "$ARCHIVE_DIR"

ARCHIVE="$ARCHIVE_DIR/pm2-logs-${DAY}.zip"

mapfile -d '' FILES < <(
    find "$LOG_DIR" -maxdepth 1 -type f \
        -name "*__${DAY}.log" -print0
)

if (( ${#FILES[@]} == 0 )); then
    echo "No rotated PM2 logs found for $DAY in $LOG_DIR"
    exit 1
fi

rm -f "$ARCHIVE"
zip -q -9 -j "$ARCHIVE" "${FILES[@]}"

echo "Created: $ARCHIVE"
echo "Log files included: ${#FILES[@]}"

S3_PATH="s3://${S3_BUCKET}/${S3_PREFIX:+${S3_PREFIX%/}/}$(basename "$ARCHIVE")"

aws s3 cp "$ARCHIVE" "$S3_PATH" --only-show-errors

echo "Upload successful: $S3_PATH"
