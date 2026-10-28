# CUBRID for Neovim

[한국어](README.md) | English

This plugin provides lexical highlighting and indentation for `.csql` files. It uses a separately installed CUBRID language server for completion and diagnostics. It does not execute SQL or connect to a database. Neovim 0.12.5 has been tested.

## Install locally

Extract the archive into Neovim's package directory. Replace the paths with your installation paths.

```sh
mkdir -p ~/.local/share/nvim/site/pack/local/start/cubrid.nvim
tar -xzf cubrid.nvim-alpha.tar.gz -C ~/.local/share/nvim/site/pack/local/start/cubrid.nvim
```

Start Neovim and run `:helptags ALL` to index the help. Configure the plugin in trusted user Lua.

```lua
require('cubrid').setup({
  server_path = '/absolute/path/to/cubrid-language-server',
  parser_worker = '/absolute/path/to/parser-worker',
  runtime_prefix = '/absolute/path/to/cubrid/runtime',
})
```

Without `server_path`, the plugin finds `cubrid-language-server` on Neovim's `PATH`. Set `parser_worker` and `runtime_prefix` together. Without them, diagnostics report the missing runtime and keyword completion remains available. Install the server and native runtime separately.

Set `sql = true` and reopen a file to opt in to `.sql`. The default leaves generic SQL filetypes alone. Completion uses Neovim's LSP support. For example, use `CTRL-X CTRL-O` in insert mode.

## Schema and commands

Omit `schema_snapshot` to inherit project metadata for each file. An absolute path selects a snapshot for every file. `vim.NIL` disables schema metadata. `:CubridReloadSchema` reloads snapshots and reports each document's availability and stale state. `:CubridRestart` restarts the server. Each `setup` call replaces the previous options, so include every option you want to retain.

One server handles files in multiple directories and discovers project metadata per file. Untitled buffers can inherit metadata from the server's starting directory. See `:help cubrid` for options and limits.
