# IDX設定類保存リポジトリ

## 目的

本リポジトリは Google IDX の設定類を自動設定することを目的としています。  
[https://idx.google.com/](https://idx.google.com/)
はアクセス元のPCの違いや開くリポジトリの違いによりデフォルト設定で開く可能性があります。  
本リポジトリの手順を実行することでカスタムされた設定を自動反映しIDXのワークスペースを再構築することが可能とします。

## 使い方

1.  IDXを任意のRepoで起動します。
2.  IDXのワークスペースがデフォルトであることを確認します。(この際デフォルトのdev.nixが idx/ に作成されます)
3.  本リポジトリをクローンします。

    ```bash
    git clone https://github.com/KunihiroS/idx_settings_repo.git
    ```
4.  クローンしたリポジトリ内の `setup.sh` スクリプトに実行権限を付与し、実行します。

    ```bash
    chmod +x idx_settings_repo/setup.sh
    ./idx_settings_repo/setup.sh
    ```

## Setup

### setup.sh
本スクリプトは下記の各種設定を自動で反映し、カスタムした環境を再現します。

## Settings

### settings.json

/User/ に配置される IDE の設定を保存するファイル
ユーザレベルの設定を行う

### dev.nix

IDX のコンテナ構築時に使用される設定ファイル
import lib (Googleが用意した? nix package registry からロードされる)などの設定、他が可能

### cline_mcp_settings.json

Roo Code (推奨) の MCP Server 用設定ファイル
/home/user/.codeoss-cloudworkstations/data/User/globalStorage/rooveterinaryinc.roo-cline/settings/
に配置される
一部 MCP Server はローカルインストールが必要なため機能しない
また、secret は {secret} を置き換える必要がある
