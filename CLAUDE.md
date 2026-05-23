# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository containing editor and shell configurations:
- **vim/.vimrc** - Vim editor configuration with plugins and keybindings
- **ideavim/.ideavimrc** - IdeaVim plugin configuration for JetBrains IDEs
- **starship/.config/starship.toml** - Starship shell prompt configuration

## Architecture & Key Relationships

### Vim Configuration Structure
The Vim configuration uses vim-plug for plugin management. Plugins are declared in `.vimrc` with `call plug#begin()` and `call plug#end()` blocks. Currently includes:
- `vim-log-highlighting` - Syntax highlighting for log files
- `vim-highlightedyank` - Visual feedback when yanking text
- `vim-commentary` - Comment/uncomment operator
- `nerdtree` - File tree explorer
- `rainbow_csv` - CSV file syntax highlighting

### IdeaVim Relationship
The `.ideavimrc` sources `.vimrc` at the top (line 7: `source ~/.vimrc`), so they share Vim settings. IdeaVim then adds IDE-specific action mappings that map Vim keybindings to JetBrains IDE actions.

**Key IDE action mappings:**
- Navigation: `]d`/`[d` for next/previous error, `gi` for go to implementation, `gr` for find usages
- Code actions: `<leader>ca` (show intentions), `<leader>cf` (reformat), `<leader>cr` (refactoring menu)
- Debugging: `<leader>t`/`<leader>T` (run), `<leader>d`/`<leader>D` (debug)

### Starship Configuration
Uses a custom Gruvbox Dark color palette with a multi-segment format. Each segment (os, directory, git, languages, time) has specific styling and positioning. The configuration detects multiple programming languages and shows their versions.

## Important Configuration Details

### Vim Leader Key
- Leader key is space (`let mapleader = " "`)
- No timeout on leader key sequences (`set notimeout`)
- Applies to both Vim and IdeaVim configurations

### Vim Settings
- Tabs: 2 spaces, expanded tabs, no shift rounding
- Searching: case-insensitive by default, smart case matching, inline search
- Navigation: 5 lines scroll offset, relative line numbers, match highlighting
- `.sdkmanrc` files are treated as Java properties files (line 12)

### NERDTree Configuration
- File tree not hijacked by netrw (`NERDTreeHijackNetrw=0`)
- Keybindings:
  - `<C-n>` - Open NERDTree
  - `<C-t>` - Toggle NERDTree
  - `<C-f>` - Find current file in tree
  - `<leader>n` - Focus NERDTree window

## Working With These Configurations

### Testing Configuration Changes
- Vim: Test changes by reloading with `:source ~/.vimrc`
- IdeaVim: Changes typically take effect after IDE restart or manual plugin refresh
- Starship: Test with `starship prompt` or check the prompt in a new shell session

### Adding New Vim Plugins
1. Add plugin line in vim-plug block: `Plug 'author/plugin-name'`
2. Run `:PlugInstall` in Vim
3. Configure keybindings or settings below the plug#end() block
4. Both Vim and IdeaVim will load the plugin (IdeaVim has its own plugin selection)

### Modifying IdeaVim Mappings
- Reference available actions at https://jb.gg/abva4t
- Most IDE actions are mapped in comments showing the action name
- Some mappings are conditional (e.g., commented breakpoint toggle on line 40)

## External Documentation References
- Vim documentation: `:help` in Vim
- IdeaVim plugins: https://jb.gg/ideavim-plugins
- IdeaVim actions: https://jb.gg/abva4t
- Starship config: https://starship.rs/config-schema.json
- Gruvbox theme: https://github.com/morhetz/gruvbox
