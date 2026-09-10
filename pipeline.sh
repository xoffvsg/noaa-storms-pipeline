#!/usr/bin/env bash
#
# pipeline.sh — Download a year of NOAA Storm Events, convert to GeoParquet.
#
# Usage:   ./pipeline.sh [YEAR]
# Example: ./pipeline.sh 2024
#
# Requires: bash, curl, gunzip, ogr2ogr (GDAL >= 3.5)
#
##################### This is a starter scaffold. Read the comments. Replace the [TODO] markers
##################### with the actual logic. Do not change the structure unless you have a reason.

set -euo pipefail

# -----------------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------------

DATA_DIR="./data"
BASE_URL="https://www.ncei.noaa.gov/pub/data/swdi/stormevents/csvfiles"

# Year to pull. Override by passing as the first argument.
YEAR="${1:-2024}"

# NOAA file naming pattern. The "c{CREATED_DATE}" portion changes when NOAA
# republishes a year. Look at https://www.ncei.noaa.gov/pub/data/swdi/stormevents/csvfiles
# and update CREATED_DATE for the year you want.
CREATED_DATE="20260728"

BASE_URL="https://www.ncei.noaa.gov/pub/data/swdi/stormevents/csvfiles"
FILE_NAME="StormEvents_details-ftp_v1.0_d${YEAR}_c${CREATED_DATE}.csv.gz"
URL="${BASE_URL}/${FILE_NAME}"

RAW_DIR="data/raw"
PROCESSED_DIR="data/processed"
RAW_GZ="${RAW_DIR}/${FILE_NAME}"
RAW_CSV="${RAW_DIR}/${FILE_NAME%.gz}" # the % trucates .gz from FILE_NAME
OUT_PARQUET="${PROCESSED_DIR}/storms_${YEAR}.parquet"

# -----------------------------------------------------------------------------
# Step 1: Set up directories
# -----------------------------------------------------------------------------

echo "[1/4] Setting up directories"

mkdir -p "$RAW_DIR"
mkdir -p "$PROCESSED_DIR"

# -----------------------------------------------------------------------------
# Step 2: Download the raw file
# -----------------------------------------------------------------------------

echo "[2/4] Downloading ${FILE_NAME}"

# Skip the download if the file already exists.

if [ -f "$RAW_GZ" ]; then
    echo "⏭️  Already downloaded: $FILE_NAME"
else
    echo "⬇️  Downloading $FILE_NAME ..."
    curl -L --progress-bar --fail --ssl-no-revoke -o "$RAW_GZ" "$BASE_URL/$FILE_NAME"

    # Guard against failed downloads (HTML error pages are small)
    FILE_SIZE=$(wc -c < "$RAW_GZ" | tr -d ' ')
    if [ "$FILE_SIZE" -lt 10000 ]; then
        echo "❌ ERROR: $FILE_NAME is only $FILE_SIZE bytes — download likely failed."
        echo "   Check that the filename is current at:"
        echo "   $BASE_URL/"
        rm "$RAW_GZ"
        exit 1
    fi
    echo "✅ Downloaded ($FILE_SIZE bytes compressed)"
fi

# -----------------------------------------------------------------------------
# Step 3: Decompress
# -----------------------------------------------------------------------------

echo "[3/4] Decompressing"

# Skip this step if RAW_CSV already exists.

if [ -f "$RAW_CSV" ]; then
    echo "⏭️  Already decompressed: $RAW_CSV"
else
    echo "📦 Decompressing..."
    # gunzip deletes the .gz by default; -k keeps the original
    gunzip -k "$RAW_GZ"
    # The decompressed file keeps the original long name; rename for clarity
    mv "$RAW_DIR/StormEvents_details-ftp_v1.0_d${YEAR}_c${CREATED_DATE}.csv" \
        "$RAW_CSV"
    echo "✅ Decompressed to $RAW_CSV"
fi

# -----------------------------------------------------------------------------
# Step 4: Convert CSV to GeoParquet
# -----------------------------------------------------------------------------

echo "[4/4] Converting to GeoParquet"

rm -f "$OUT_PARQUET"
ogr2ogr \
    -f "Parquet" \
    "$OUT_PARQUET" \
    "$RAW_CSV" \
    -oo AUTODETECT_TYPE=YES \
    -oo X_POSSIBLE_NAMES=BEGIN_LON \
    -oo Y_POSSIBLE_NAMES=BEGIN_LAT \
    -a_srs EPSG:4326

PARQUET_SIZE=$(wc -c < "$RAW_CSV" | tr -d ' ')
echo "✅ Created $OUT_PARQUET ($PARQUET_SIZE bytes)"
echo "Done. Output: ${OUT_PARQUET}"

