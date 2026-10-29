# CUBRID for Neovim

[한국어](README.md) | English

[cubrid.nvim](https://github.com/vimkim/cubrid.nvim) provides lexical highlighting and indentation for `.sql` and `.csql` files. It uses a separately installed CUBRID language server for completion and diagnostics. It does not execute SQL or connect to a database. Neovim 0.12.5 has been tested.

## Install with LazyVim or lazy.nvim

Install Python 3.10 or later and the shared language server with its optional `lsp` dependencies. Follow the [shared engine installation guide](https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.en.md). The server is installed separately from this plugin. A qualified native parser worker and matching runtime are also separate and are needed for strict syntax diagnostics, not keyword completion.

Add this spec to a file such as `~/.config/nvim/lua/plugins/cubrid.lua` in LazyVim, or add the spec to your lazy.nvim configuration. `lazy = false` registers the `.sql` and `.csql` filetypes at startup.

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

The plugin finds `cubrid-language-server` on Neovim's `PATH`. For a local source installation made with `just sync`, it reads the installed package metadata and looks for `native/parser-worker/build/parser-worker` under the recorded source directory. It reads `runtimePrefix` from the adjacent `manifest.json`. `just sync` does not build the native worker. See the [shared engine installation guide](https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.en.md).

For a wheel or index installation, or if the local native build is gone, set both `parser_worker` and `runtime_prefix` to absolute paths in trusted Lua setup. You can also set an absolute `server_path`. If discovery fails, keyword completion remains available and the server reports the missing runtime. Run `:CubridDoctor` or `:checkhealth cubrid` to inspect the installation and a private native diagnostic probe.

If the server is not on `PATH`, set its absolute `server_path` in `opts`. For example:

```lua
opts = {
  server_path = '/absolute/path/to/cubrid-language-server',
  parser_worker = '/absolute/path/to/parser-worker',
  runtime_prefix = '/absolute/path/to/cubrid/runtime',
}
```

Both `.sql` and `.csql` use the `cubrid` filetype by default. To use only `.csql`, set `opts` in the plugin spec as follows. Reopen existing buffers after changing the setting.

```lua
opts = { file_extensions = { '.csql' } }
```

Use `{ '.sql' }` for SQL only, or `{}` to disable both automatic associations. The list replaces the defaults. Enter lowercase suffixes; filename matching is case-insensitive. The old `sql` option is rejected. Replace it with `file_extensions`.

The plugin warns when it observes another filetype or LSP client. Resolve the filetype rule or choose one server. To disable an automatic association, remove its suffix from `file_extensions` and reopen the file. If the server is missing, install it or set a trusted `server_path`, then run `:CubridRestart`.

This is an alpha release. The server reports unsupported syntax coverage and native runtime failures as diagnostics. An empty diagnostic list does not certify all SQL. Highlighting and indentation are lexical.

In insert mode, use `CTRL-X CTRL-O`, select a candidate with `CTRL-N`, and accept it with `CTRL-Y`. The plugin owns the buffer-local `omnifunc` while its CUBRID client is attached. It restores the previous value on detach unless you changed it. CTRL-Y applies the full supported single-line edit, including text after the cursor. Space or Escape can discard the menu while leaving a native preview suffix in the buffer. Multiline and other unsupported completion items are reported without opening a partial menu.

## Install locally

Extract the archive into Neovim's package directory. Replace the paths with your installation paths.

```sh
mkdir -p ~/.local/share/nvim/site/pack/local/start/cubrid.nvim
tar -xzf cubrid.nvim-alpha.tar.gz -C ~/.local/share/nvim/site/pack/local/start/cubrid.nvim
```

Start Neovim and run `:helptags ALL` to index the help. Configure the plugin in trusted user Lua as described above.

You can also use a local installation with lazy.nvim. Replace the path with your installation path.

```lua
{
  dir = '/absolute/path/to/cubrid.nvim',
  lazy = false,
  config = function() require('cubrid').setup({ file_extensions = { '.sql', '.csql' } }) end,
}
```

## Schema and commands

Omit `schema_snapshot` to inherit project metadata for each file. An absolute path selects a snapshot for every file. `vim.NIL` disables schema metadata. `:CubridReloadSchema` reloads snapshots and reports each document's availability and stale state. `:CubridRestart` restarts the server. Each `setup` call replaces the previous options, so include every option you want to retain.

One server handles files in multiple directories and discovers project metadata per file. On Neovim 0.12.5, an unnamed buffer uses `file://`; the current server searches for its project metadata from the parent of the server's starting directory. See `:help cubrid` for options and limits.
