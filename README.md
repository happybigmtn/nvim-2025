# nvim-2025

A full-featured Neovim configuration written in Lua. This guide will walk you through replicating this configuration on your computer, even if you're completely new to Neovim.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Install Neovim](#step-1-install-neovim)
- [Step 2: Set Up the Configuration Directory](#step-2-set-up-the-configuration-directory)
- [Step 3: Get the Configuration Files](#step-3-get-the-configuration-files)
- [Step 4: Install Lazy.nvim & Plugins](#step-4-install-lazynvim--plugins)
- [Step 5: Install External Dependencies](#step-5-install-external-dependencies)
- [Usage & Keybindings](#usage--keybindings)
- [Troubleshooting & Updates](#troubleshooting--updates)
- [Customization](#customization)
- [Credits & License](#credits--license)

## Prerequisites

Before you begin, make sure you have the following installed on your system:

- **Neovim 0.8 or higher**  
  Download the latest release from [Neovim Releases](https://github.com/neovim/neovim/releases)
- **Git**  
  Required for cloning the repository
- **Node.js & npm**  
  Optional, but required for some plugins such as Live Server

## Step 1: Install Neovim

### macOS

Install via [Homebrew](https://brew.sh/):

```bash
brew install neovim
```

### Ubuntu/Linux

Install using your package manager or follow the official instructions:

```bash
sudo apt install neovim
```

### Windows

Download the installer from the [Neovim Releases](https://github.com/neovim/neovim/releases) page.

After installation, verify by running:

```bash
nvim --version
```

## Step 2: Set Up the Configuration Directory

Neovim looks for configuration files in:

- macOS/Linux: `~/.config/nvim`
- Windows: `%APPDATA%\nvim`

Create the configuration directory (if it doesn't already exist) and navigate to it:

```bash
mkdir -p ~/.config/nvim
cd ~/.config/nvim
```

## Step 3: Get the Configuration Files

Clone this repository into your Neovim configuration directory:

```bash
git clone https://github.com/happybigmtn/nvim-2025.git .
```

Your directory structure should now look similar to this:

```
~/.config/nvim/
├── lua
│   ├── README.md         # (This file can be here as well)
│   └── bigmountain
│       ├── core
│       │   ├── init.lua
│       │   ├── keymaps.lua
│       │   └── options.lua
│       ├── plugins
│       │   ├── nvim-ts-autotag.lua
│       │   ├── init.lua
│       │   ├── vim-maximizer.lua
│       │   └── ... (other plugin files)
│       └── lazy.lua
```

**Note**: If you're new to Git, you can also download the repository as a ZIP file from GitHub and extract it into `~/.config/nvim`.

## Step 4: Install Lazy.nvim & Plugins

This configuration uses Lazy.nvim as its plugin manager. The setup in `lua/bigmountain/lazy.lua` automatically installs Lazy.nvim if it's missing.

Simply start Neovim:

```bash
nvim
```

On the first run, Lazy.nvim will be automatically cloned and the rest of the plugins will be installed. This might take a few minutes.

## Step 5: Install External Dependencies

Some plugins require external tools. For example:

### Live Server Plugin

The live-server.nvim plugin requires the live-server package. Install it globally using npm:

```bash
npm install -g live-server
```

If you run into issues with missing dependencies, check individual plugin documentation or review the configuration files under `lua/bigmountain/plugins/`.

## Usage & Keybindings

With the configuration loaded, here are a few examples of the keybindings and commands you can use:

### General Leader Key

The leader key is set to the space bar. Press `<Space>` followed by another key or key combination.

### File Explorer

- Toggle file explorer: `<leader>ee`
- Toggle file explorer on current file: `<leader>ef`

### Telescope (Fuzzy Finder)

- Find files: `<leader>ff`
- Live grep: `<leader>fs`
- Find recent files: `<leader>fr`

### Window Management

- Split window vertically: `<leader>sv`
- Split window horizontally: `<leader>sh`

### Other Useful Mappings

- Clear search highlights: `<leader>nn`
- Format current file: `<leader>mp`

For a full list of keybindings, refer to the file `lua/bigmountain/core/keymaps.lua`.

## Troubleshooting & Updates

### Plugin Issues

If you experience plugin errors or missing functionality, run the following inside Neovim:

```vim
:Lazy sync
```

This will update and synchronize your plugins.

### Configuration Changes

After editing configuration files, restart Neovim or source the configuration with:

```vim
:source $MYVIMRC
```

### Updating Plugins

Update plugins by running:

```vim
:Lazy update
```

## Customization

This configuration is highly modular and organized:

- Core settings and keymaps are located in `lua/bigmountain/core/`
- Plugin configurations reside in `lua/bigmountain/plugins/`
- Plugin management is handled by `lua/bigmountain/lazy.lua`

Feel free to adjust settings, add new plugins, or modify keybindings to suit your workflow.

## Credits & License

### Credits

This configuration builds on the work of Josean (josean.com) and many open-source projects. Special thanks to the developers of Lazy.nvim and all the plugin authors whose work is included here.
