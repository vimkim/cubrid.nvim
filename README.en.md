# CUBRID for Neovim

[한국어](README.md) | English

[cubrid.nvim](https://github.com/vimkim/cubrid.nvim) provides lexical highlighting and indentation for `.csql` files. It uses a separately installed CUBRID language server for completion and diagnostics. It does not execute SQL or connect to a database. Neovim 0.12.5 has been tested.

## Install with LazyVim or lazy.nvim

Install Python 3.10 or later and the shared language server with its optional `lsp` dependencies. Follow the [shared engine installation guide](https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.en.md). The server is installed separately from this plugin. A qualified native parser worker and matching runtime are also separate and are needed for strict syntax diagnostics, not keyword completion.

Add this spec to a file such as `~/.config/nvim/lua/plugins/cubrid.lua` in LazyVim, or add the spec to your lazy.nvim configuration. `lazy = false` registers the `.csql` filetype at startup.

```lua
return {
  {
    'vimkim/cubrid.nvim',
    lazy = false,
    main = 'cubrid',
    opts = {},
  },
}
```

See the [LazyVim plugin configuration](https://www.lazyvim.org/configuration/plugins) and [lazy.nvim spec usage](https://lazy.folke.io/spec) for plugin configuration. No separate nvim-lspconfig configuration or Blink source is required.

By default, the plugin finds `cubrid-language-server` on Neovim's `PATH`. If it is not on `PATH`, set `server_path` to its absolute path in `opts`. For a server installed in a checkout's `.venv`, use the absolute path to `.venv/bin/cubrid-language-server`. For strict syntax diagnostics, set both `parser_worker` and `runtime_prefix` to the absolute paths of the qualified worker and matching runtime. For example:

```lua
opts = {
  server_path = '/absolute/path/to/cubrid-language-server',
  parser_worker = '/absolute/path/to/parser-worker',
  runtime_prefix = '/absolute/path/to/cubrid/runtime',
}
```

Without the native pair, diagnostics report the missing runtime and keyword completion remains available. The plugin and server do not bundle the runtime.

Set `sql = true` and reopen a file to opt in to `.sql`. The default leaves generic SQL filetypes alone. In insert mode, use `CTRL-X CTRL-O`, select a candidate with `CTRL-N`, and accept it with `CTRL-Y`. The plugin owns the buffer-local `omnifunc` while its CUBRID client is attached. It restores the previous value on detach unless you changed it. CTRL-Y applies the full supported single-line edit, including text after the cursor. Space or Escape can discard the menu while leaving a native preview suffix in the buffer. Multiline and other unsupported completion items are reported without opening a partial menu.

## Schema and commands

Omit `schema_snapshot` to inherit project metadata for each file. An absolute path selects a snapshot for every file. `vim.NIL` disables schema metadata. `:CubridReloadSchema` reloads snapshots and reports each document's availability and stale state. `:CubridRestart` restarts the server. Each `setup` call replaces the previous options, so include every option you want to retain.

One server handles files in multiple directories and discovers project metadata per file. On Neovim 0.12.5, an unnamed buffer uses `file://`; the current server searches for its project metadata from the parent of the server's starting directory. See `:help cubrid` for options and limits.
