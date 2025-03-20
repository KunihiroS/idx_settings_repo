#!/bin/bash

# スクリプトの実行ディレクトリを取得
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# settings.json のコピー (シンボリックリンクでも可)
# 既存のファイルがある場合はバックアップ
if [ -f /User/settings.json ]; then
  mv /User/settings.json /User/settings.json.bak
fi
cp "$SCRIPT_DIR/settings.json" /User/

# dev.nix のコピー (シンボリックリンクでも可)
# 既存のファイルがある場合はバックアップ
if [ -f .idx/dev.nix ]; then
  mv .idx/dev.nix .idx/dev.nix.bak
fi
cp "$SCRIPT_DIR/dev.nix" .idx/

# cline_mcp_settings.json のコピー (シンボリックリンクでも可)
# 既存のファイルがある場合はバックアップ
TARGET_DIR="/home/user/.codeoss-cloudworkstations/data/User/globalStorage/rooveterinaryinc.roo-cline/settings/"
if [ -f "$TARGET_DIR/cline_mcp_settings.json" ]; then
  mv "$TARGET_DIR/cline_mcp_settings.json" "$TARGET_DIR/cline_mcp_settings.json.bak"
fi
mkdir -p "$TARGET_DIR"  # ディレクトリが存在しない場合に作成
cp "$SCRIPT_DIR/cline_mcp_settings.json" "$TARGET_DIR/"

echo "IDX settings setup completed."
