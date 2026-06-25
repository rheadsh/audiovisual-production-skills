#!/usr/bin/env bash
# Convert a folder of source textures to Redshift .rstexbin
# Usage: ./process_textures.sh /path/to/textures
# Requires redshiftTextureProcessor on PATH (ships with Redshift).

set -euo pipefail

DIR="${1:-.}"

if ! command -v redshiftTextureProcessor >/dev/null 2>&1; then
    echo "redshiftTextureProcessor not found on PATH." >&2
    echo "Add the Redshift bin directory to PATH and retry." >&2
    exit 1
fi

echo "Processing textures in: $DIR"
find "$DIR" -type f \
    \( -iname "*.exr" -o -iname "*.png" -o -iname "*.tif" -o -iname "*.tiff" \
       -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.hdr" \) \
    -print -exec redshiftTextureProcessor {} \;

echo "Done. .rstexbin files written next to sources."
