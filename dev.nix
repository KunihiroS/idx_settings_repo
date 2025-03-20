{ pkgs, ... }: {
  channel = "stable-24.05";
  
  packages = [
    pkgs.python311
    pkgs.pipx
    pkgs.nodejs_latest
    
    # 統合版uvxコマンド（環境同期機能付き）
    (pkgs.writeShellScriptBin "uvx" ''
      #!/usr/bin/env bash
      
      # 共有パッケージディレクトリの設定と作成
      PERSISTENT_PKG_DIR="$HOME/.uvx/packages"
      mkdir -p "$PERSISTENT_PKG_DIR"
      
      # ユーザー環境へのPATHを追加
      export PATH="$HOME/.local/bin:$PATH"
      
      # 一時パッケージディレクトリ（セッション内共有用）
      TEMP_PKG_DIR="/tmp/uvx-packages-$$"
      mkdir -p "$TEMP_PKG_DIR"
      
      # リソース管理の統合
      cleanup() {
        rm -rf "$TEMP_PKG_DIR" "$TEMP_CLONE_DIR" "$TEMP_PIP_DIR" "$TEMP_SCRIPT" 2>/dev/null || true
      }
      trap cleanup EXIT
      
      # ヘルプコマンドの処理
      if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "uvx: Python development tool wrapper for IDX environment"
        echo ""
        echo "Usage: uvx [command/option]"
        echo ""
        echo "Commands:"
        echo "  python [args]       Execute Python with environment configuration"
        echo "  pip install [pkgs]  Install packages to session directory"
        echo "  pip install --user [pkgs]  Install packages to user environment"
        echo "  pip [command]       Run other pip commands"
        echo ""
        echo "Options:"
        echo "  --help, -h          Show this help message"
        echo "  --version, -V       Show version information"
        echo "  --from GIT_URL PACKAGE_NAME  Install and run package from Git repository"
        echo ""
        echo "Examples:"
        echo "  uvx python script.py"
        echo "  uvx pip install numpy pandas"
        echo "  uvx --from git+https://github.com/user/repo.git#subdirectory=package package_name"
        exit 0
      fi
      
      # バージョン情報
      if [ "$1" = "--version" ] || [ "$1" = "-V" ]; then
        echo "uvx wrapper version 1.5.0"
        echo "Using Python: $(${pkgs.python311}/bin/python --version 2>&1)"
        echo "Using pipx: $(${pkgs.pipx}/bin/pipx --version 2>&1)"
        exit 0
      fi
      
      # コマンドがない場合はヘルプを表示
      if [ $# -eq 0 ]; then
        echo "Error: No command specified. Use --help for usage information."
        exit 1
      fi
      
      # --fromオプションの検出と処理
      if [ "$1" = "--from" ]; then
        shift
        if [ $# -lt 2 ]; then
          echo "Error: --from requires a git URL and a package name"
          echo "Usage: uvx --from GIT_URL PACKAGE_NAME [ARGS...]"
          exit 1
        fi
        
        GIT_URL="$1"
        shift
        PACKAGE_NAME="$1"
        shift
        EXTRA_ARGS="$@"  # 残りの引数を保存
        
        echo "Installing and running package from Git repository..."
        
        # 一時ディレクトリを作成
        TEMP_CLONE_DIR=$(mktemp -d /tmp/uvx-git-XXXXXX)
        
        # URLからサブディレクトリとエッグ名を抽出
        # フラグメント部分を抽出 (#以降の部分)
        URL_FRAGMENT=$(echo "$GIT_URL" | grep -o '#.*' || echo "")
        SUBDIRECTORY=$(echo "$URL_FRAGMENT" | grep -o "subdirectory=[^&]*" | cut -d= -f2 || echo "")
        
        # git+https:// => https:// に変換
        REPO_URL=$(echo "$GIT_URL" | cut -d'#' -f1 | sed 's/^git+//')
        
        # GitHubからクローン
        echo "Cloning repository from $REPO_URL..."
        git clone --depth 1 "$REPO_URL" "$TEMP_CLONE_DIR" || {
          echo "Error: Failed to clone repository"
          exit 1
        }
        
        # サブディレクトリがある場合の移動
        if [ -n "$SUBDIRECTORY" ]; then
          if [ ! -d "$TEMP_CLONE_DIR/$SUBDIRECTORY" ]; then
            echo "Error: Subdirectory $SUBDIRECTORY not found in repository"
            exit 1
          fi
          cd "$TEMP_CLONE_DIR/$SUBDIRECTORY"
        else
          cd "$TEMP_CLONE_DIR"
        fi
        
        # Pythonのユーザーサイトパッケージへのパスを構築
        USER_SITE_PACKAGES=$(${pkgs.python311}/bin/python -m site --user-site)
        
        # PYTHONPATHの設定（優先順位: 一時 > 永続的 > ユーザーサイト > システム）
        export PYTHONPATH="$TEMP_PKG_DIR:$PERSISTENT_PKG_DIR:$USER_SITE_PACKAGES:$PYTHONPATH"
        export PYTHONUSERBASE="$HOME/.local"
        
        # パッケージのインストールと実行
        echo "Installing package..."
        ${pkgs.pipx}/bin/pipx run pip install --target="$TEMP_PKG_DIR" -e . || {
          echo "Error: Failed to install package"
          exit 1
        }
        
        # パッケージの実行
        echo "Running $PACKAGE_NAME..."
        if command -v "$PACKAGE_NAME" >/dev/null 2>&1; then
          # 直接実行可能な場合
          $PACKAGE_NAME $EXTRA_ARGS
        else
          # Pythonモジュールとして実行
          ${pkgs.python311}/bin/python -m $PACKAGE_NAME $EXTRA_ARGS
        fi
        
        exit $?
      fi
      
      command="$1"
      shift
      
      case "$command" in
        python)
          # Pythonのユーザーサイトパッケージへのパスを構築
          USER_SITE_PACKAGES=$(${pkgs.python311}/bin/python -m site --user-site)
          
          # PYTHONPATHの設定（優先順位: 一時 > 永続的 > ユーザーサイト > システム）
          export PYTHONPATH="$TEMP_PKG_DIR:$PERSISTENT_PKG_DIR:$USER_SITE_PACKAGES:$PYTHONPATH"
          
          # --user インストールが確実に機能するようPYTHONUSERBASEを設定
          export PYTHONUSERBASE="$HOME/.local"
          
          # Pythonコマンドの処理
          if [ $# -eq 0 ]; then
            # 引数なしの場合は対話モード
            ${pkgs.python311}/bin/python
          elif [ "$1" = "-c" ]; then
            # -c オプションの場合、Bashのヒストリ展開を回避するために処理を変更
            if [ $# -lt 2 ]; then
              echo "Error: No Python code provided after -c"
              exit 1
            fi
            # 引数をエスケープするためにファイルに書き出し
            TEMP_SCRIPT=$(mktemp /tmp/uvscript_XXXXXX.py)
            echo "$2" > "$TEMP_SCRIPT"
            ${pkgs.python311}/bin/python "$TEMP_SCRIPT"
            exit_code=$?
            rm -f "$TEMP_SCRIPT"
            exit $exit_code
          else
            # その他の引数はそのまま渡す
            ${pkgs.python311}/bin/python "$@"
          fi
          ;;
        
        pip)
          # 基本フラグの初期化
          HAS_USER_FLAG=0
          IS_INSTALL_CMD=0
          
          # 最初の引数がinstallかチェック
          if [ $# -gt 0 ] && [ "$1" = "install" ]; then
            IS_INSTALL_CMD=1
            shift
            
            # 残りの引数を処理
            REGULAR_PKGS=""
            USER_PKGS=""
            
            # 引数の分類
            while [ $# -gt 0 ]; do
              if [ "$1" = "--user" ]; then
                HAS_USER_FLAG=1
              elif [ $HAS_USER_FLAG -eq 1 ]; then
                # --user フラグ後の引数はユーザーパッケージとして扱う
                if [ -z "$USER_PKGS" ]; then
                  USER_PKGS="$1"
                else
                  USER_PKGS="$USER_PKGS $1"
                fi
              else
                # それ以外は通常のパッケージ/オプションとして扱う
                if [ -z "$REGULAR_PKGS" ]; then
                  REGULAR_PKGS="$1"
                else
                  REGULAR_PKGS="$REGULAR_PKGS $1"
                fi
              fi
              shift
            done
            
            # インストールコマンドの処理
            if [ $HAS_USER_FLAG -eq 1 ] && [ -n "$USER_PKGS" ]; then
              # --userフラグ付きのインストール => 永続的パッケージディレクトリを使用
              # 一時的なpipインストール環境を作成
              TEMP_PIP_DIR=$(mktemp -d /tmp/pip-installer.XXXXXX)
              
              # pipをダウンロードして直接実行
              curl -sSL https://bootstrap.pypa.io/get-pip.py -o "$TEMP_PIP_DIR/get-pip.py" || {
                echo "Error: Failed to download pip. Check your network connection."
                rm -rf "$TEMP_PIP_DIR"
                exit 1
              }
              
              # テンポラリディレクトリにpipをインストール
              ${pkgs.python311}/bin/python "$TEMP_PIP_DIR/get-pip.py" \
                --no-warn-script-location \
                --target="$TEMP_PIP_DIR" >/dev/null || {
                echo "Error: Failed to install pip."
                rm -rf "$TEMP_PIP_DIR"
                exit 1
              }
              
              echo "Installing to user environment: $USER_PKGS"
              
              # --target オプションで永続的ディレクトリにインストール
              USER_SITE_PKG_DIR="$HOME/.local/lib/python3.11/site-packages"
              USER_BIN_DIR="$HOME/.local/bin"
              mkdir -p "$USER_SITE_PKG_DIR" "$USER_BIN_DIR" 2>/dev/null
              
              PYTHONPATH="$TEMP_PIP_DIR" \
              ${pkgs.python311}/bin/python -m pip install \
                --target="$USER_SITE_PKG_DIR" \
                --no-warn-script-location \
                $USER_PKGS
              
              INSTALL_STATUS=$?
              # インストール成功時のガイダンス表示
              if [ $INSTALL_STATUS -eq 0 ]; then
                # パッケージ名の先頭部分を抽出
                FIRST_PKG=$(echo "$USER_PKGS" | cut -d' ' -f1)
                
                echo ""
                echo "Packages successfully installed to user environment."
                echo "To use, run the uvx python command as follows:"
                echo "  uvx python -c 'import ''${FIRST_PKG}; print(''${FIRST_PKG}.__version__)'"
                echo ""
              else
                echo "Error: Package installation failed."
                exit 1
              fi
            else
              # 通常のインストール => 一時パッケージディレクトリにインストール
              echo "Installing to session package directory..."
              
              # 修正: 引数を正しく渡す
              ${pkgs.pipx}/bin/pipx run pip install --target="$TEMP_PKG_DIR" $REGULAR_PKGS
              
              INSTALL_STATUS=$?
              
              if [ $INSTALL_STATUS -eq 0 ]; then
                # インストールしたパッケージを永続的ディレクトリにもコピー
                echo "Copying packages to persistent directory..."
                cp -r "$TEMP_PKG_DIR"/* "$PERSISTENT_PKG_DIR"/ 2>/dev/null || true
                
                echo ""
                echo "Packages installed successfully."
                echo "They are automatically available in this session with the uvx python command."
                echo ""
              else
                echo "Error: Package installation failed."
                exit 1
              fi
            fi
          else
            # install以外のコマンド
            ${pkgs.pipx}/bin/pipx run pip "$@"
          fi
          ;;
        
        *)
          echo "Error: Unknown command '$command'"
          echo "Use 'uvx --help' for usage information."
          exit 1
          ;;
      esac
    '')
    
    # 使用ガイド（最終版）
    (pkgs.writeShellScriptBin "show-uv-guide" ''
      #!/usr/bin/env bash
      
      cat << EOF
# Python Development Guide for IDX Environment

## About the Environment

This project runs in the Google IDX environment. Due to the separation between IDX build processes and user sessions,
standard virtual environment (venv) creation and sharing may not function as expected.

## Using the UVX Command

This project provides the \`uvx\` command that works independently of virtual environments:

\`\`\`bash
# Running Python scripts
uvx python script.py

# Direct Python code execution
uvx python -c 'print("Hello, World!")'

# Session package installation
uvx pip install numpy pandas matplotlib

# Permanent package installation to user environment
uvx pip install --user numpy pandas matplotlib

# List installed packages
uvx pip list

# Install and run a package directly from a Git repository
uvx --from git+https://github.com/username/repo.git#subdirectory=package package_name
\`\`\`

This command operates consistently regardless of virtual environment status.
Particularly, packages installed with the \`--user\` flag are automatically accessible
when using the \`uvx python\` command.

## Technical Details

The \`uvx\` command overcomes IDX environment constraints using the following technologies:

1. Session package directory (\`/tmp/uvx-packages\`)
2. Persistent package directory (\`~/.uvx/packages\`)
3. User site packages (\`~/.local/lib/python3.11/site-packages\`)

By coordinating these appropriately, development work can proceed efficiently while avoiding IDX constraints.

For detailed help information, use the \`uvx --help\` command.
EOF
    '')
  ];
  
  idx = {
    extensions = [
      "RooVeterinaryInc.roo-cline"
      "saoudrizwan.claude-dev"
    ];
    
    previews = {
      enable = true;
      previews = {};
    };
    
    workspace = {
      onCreate = {
        setup-action = ''
          echo "IDX environment has been configured. Use the 'show-uv-guide' command to check Python environment usage instructions."
        '';
      };
    };
  };
}