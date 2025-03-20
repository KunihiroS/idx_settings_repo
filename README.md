# IDX Settings Repository

## Purpose

This repository aims to automate the configuration of Google IDX settings.  
[https://idx.google.com/](https://idx.google.com/)
may open with default settings depending on the accessing PC or the repository being opened.  
By executing the steps in this repository, it is possible to automatically apply a part of custom settings and rebuild the IDX workspace.

This repo helps you to less copy and paste.

## How to Use

1.  Launch IDX with any repository.
2.  Confirm that the IDX workspace is in its default state (a default `dev.nix` will be created in `idx/` at this time).
3.  Clone this repository.

    ```bash
    git clone https://github.com/KunihiroS/idx_settings_repo.git
    ```
4.  Grant execute permission to the `setup.sh` script in the cloned repository and execute it.
    This script will deploy the IDX build configuration (`dev.nix`) and MCP server settings.
    It will create backups if files already exist.

    ```bash
    chmod +x idx_settings_repo/setup.sh
    ./idx_settings_repo/setup.sh
    ```
5.  Perform an IDX Rebuild to enable the features described in `dev.nix` and confirm the MCP Server settings.
6.  (Optional) If necessary, overwrite the IDE settings with `idx_settings_repo/settings.json`.
    However, overwriting `settings.json` directly requires careful consideration.

## Files for setup

### setup.sh
This script automatically applies the following settings to reproduce a customized environment.
The settings apply to `dev.nix` and the MCP Server.

## Settings

### dev.nix

Configuration file used when building the IDX container.
Allows settings such as importing libraries (loaded from the Nix package registry, possibly provided by Google).

### cline_mcp_settings.json

Configuration file for the Roo Code (recommended) MCP Server.
Located at `/home/user/.codeoss-cloudworkstations/data/User/globalStorage/rooveterinaryinc.roo-cline/settings/`.
Some MCP Servers may not function because they require local installation.
Also, secrets need to be replaced where `{secret}` is indicated.

### settings.json

File that stores IDE settings located in `/User/`.
Used for user-level settings.
It is optional and not included in the `setup.sh` script.

Note: In the IDX environment, the location of `settings.json` cannot be identified, and the PATH indicating `settings.json` cannot be directly referenced.
To rewrite it, open `settings.json` from the IDX settings UI and replace the contents with this file.
However, overwriting `settings.json` requires careful consideration.
