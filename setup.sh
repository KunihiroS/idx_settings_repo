#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Copy settings.json (symbolic link is also acceptable)
# Backup existing file if present
if [ -f /User/settings.json ]; then
  mv /User/settings.json /User/settings.json.bak
fi
cp "$SCRIPT_DIR/settings.json" /User/

# Copy dev.nix (symbolic link is also acceptable)
# Backup existing file if present
if [ -f .idx/dev.nix ]; then
  mv .idx/dev.nix .idx/dev.nix.bak
fi
cp "$SCRIPT_DIR/dev.nix" .idx/

# Copy cline_mcp_settings.json (symbolic link is also acceptable)
# Backup existing file if present
TARGET_DIR="/home/user/.codeoss-cloudworkstations/data/User/globalStorage/rooveterinaryinc.roo-cline/settings/"
if [ -f "$TARGET_DIR/cline_mcp_settings.json" ]; then
  mv "$TARGET_DIR/cline_mcp_settings.json" "$TARGET_DIR/cline_mcp_settings.json.bak"
fi
mkdir -p "$TARGET_DIR"  # Create directory if it doesn't exist
cp "$SCRIPT_DIR/cline_mcp_settings.json" "$TARGET_DIR/"

echo "IDX settings setup completed."
