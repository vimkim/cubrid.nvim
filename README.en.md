# CUBRID for Neovim

[한국어](README.md) | English

[cubrid.nvim](https://github.com/vimkim/cubrid.nvim) provides lexical highlighting and indentation for `.sql` and `.csql` files. It uses a separately installed CUBRID language server for completion and diagnostics. It never executes your SQL. An optional schema exporter connects to CUBRID and runs fixed catalog queries. Neovim 0.12.5 has been tested.

## Language support and upgrades

The shared server owns completion, syntax diagnostics, and conservative `CUBRID-A` authoring warnings. SHOW and optimizer-hint suggestions cover more syntax than the native checker accepts. Correcting an authoring warning can leave an unsupported-coverage diagnostic.

Current core coverage is `bounded-query-dml-schema-engineer-ordered-v4` for `cubrid-11.5.0.2704-cc94778` on Linux x86-64. It admits one argument-free `/*+ ORDERED */` immediately after a top-level literal `SELECT`. `FROM`, joins, and other hints remain unsupported in that form. Native SHOW coverage is only `SHOW TRACE`. See the [qualified coverage reference](https://github.com/vimkim/cubrid-language-tools/blob/main/docs/coverage.en.md) for exact limits. SQL formatting and semantic or style linting remain future work.

For a v4 upgrade, install the matching core and native worker with its manifest and qualified runtime. Follow the [shared engine installation guide](https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.en.md). Updating this plugin or running `just sync` does not rebuild the worker. A v3 worker does not supply v4 coverage. The Python wheel contains no native assets, and `--version` still reports `0.1.0.dev0`, which identifies neither the source commit nor coverage revision.

[Acceptance evidence](docs/acceptance.md#current-status-and-evidence-scope) distinguishes the earlier Neovim, Blink, and isolated LazyVim checks from current core coverage. Those editor checks used earlier engines. They are not a new v4 or personal-profile acceptance run.

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

For a wheel or index installation, or if the local native build is gone, set both `parser_worker` and `runtime_prefix` to absolute paths in trusted Lua setup. You can also set an absolute `server_path`. On activation, missing server or native prerequisites produce a warning with the GitHub installation guide and retry steps. If discovery fails, strict syntax diagnostics are unavailable while keyword completion remains available. Unchanged failures do not repeat across buffers or settings updates. After repair, run `:CubridRestart` to retry. Run `:CubridDoctor` or `:checkhealth cubrid` to inspect the installation and a private native diagnostic probe.

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

## Use native LSP configuration

`setup()` enables the shipped `lsp/cubrid.lua` configuration. Neovim owns activation and server processes. Calling `vim.lsp.enable('cubrid')` again reuses the same default client. Neither nvim-lspconfig nor Blink is required.

To let native configuration control activation, use this trusted user configuration before opening files:

```lua
require('cubrid').setup({ auto_start = false })
vim.lsp.config('cubrid', {
  cmd = { '/absolute/path/to/cubrid-language-server' },
  settings = { cubrid = { schemaSnapshot = vim.NIL } },
})
vim.lsp.enable('cubrid')
```

`auto_start = false` skips automatic enable. It does not disable an externally enabled configuration or stop an existing client. Use `vim.lsp.enable('cubrid', false)` to disable it. `:CubridRestart` explicitly enables the configuration again after stopping its clients.

Without `setup()`, `vim.lsp.enable('cubrid')` also works for buffers already marked `cubrid`. Add your own filetype rule or use `:setfiletype cubrid`. Automatic extension selection belongs to `setup()`.

Native `cmd`, `capabilities`, `on_attach`, and `settings` overrides work whether configured before or after `setup()`. Set them before enabling or opening a CUBRID buffer. Changes to native configuration affect new clients; run `:CubridRestart` to apply them to a running client. Native configuration uses Neovim's merge order, with `vim.lsp.config('cubrid', ...)` above runtime configuration and `vim.lsp.config('*', ...)`. Later native calls merge into earlier calls. A server-specific `settings.cubrid` value overrides the corresponding trusted setup option. Omitted setup options are removed on each `setup()` call; native overrides remain. Both initialization options and subsequent settings notifications contain the complete effective CUBRID settings.

The plugin uses `before_init` to prepare those settings and `on_exit` to report failure. If you replace either callback, chain the existing callback. `on_attach` is free for your mappings; manual completion uses separate attachment events.

The default root is the working directory at the first setup or native configuration load. Changing directories keeps one client. An explicit `root_dir` or root callback can create clients for separate roots. With multiple clients, `:CubridReloadSchema` uses the current buffer's client, and `:CubridRestart` restarts all enabled CUBRID clients.

## Use LazyVim and Blink

Add a local plugin specification under `lua/plugins/cubrid.lua`. Replace the checkout path. This uses LazyVim's existing LSP configuration and completion integration:

```lua
return {
  {
    dir = '/absolute/path/to/cubrid.nvim',
    lazy = false,
    opts = { auto_start = false },
  },
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        cubrid = { mason = false },
      },
    },
  },
}
```

LazyVim configures and enables `cubrid`. `mason = false` keeps installation external. Do not add a second manual `vim.lsp.start()` call. Put native overrides under `servers.cubrid`. Blink uses its ordinary `lsp` source; no CUBRID-specific completion source is needed. Outside LazyVim, Blink users can pass `require('blink.cmp').get_lsp_capabilities()` as the native `capabilities` option. The manual `CTRL-X CTRL-O` menu remains available.

A shared server with SHOW/hint authoring support supplies SHOW commands, optimizer hints, and `CUBRID-A` authoring warnings. The plugin forwards these results. An unsupported-coverage warning can remain after an authoring warning is corrected. An empty diagnostic list does not establish complete native SQL coverage.

Neovim 0.12.5 on Linux is the tested platform. The plugin suite does not verify earlier versions or full LazyVim distribution startup. The separate isolated LazyVim check covers the configuration recorded in the acceptance report. See [acceptance evidence](docs/acceptance.md) for the installed artifact checks and independent completion verification.

## Connect for schema completion

Install a shared language-tools version that includes `cubrid-schema`, and make it and CSQL available on Neovim's `PATH`. Open a CUBRID buffer and run `:CubridConnect`. Enter a command such as `csql -udba demodb@localhost -C`, then enter the password. Both prompts hide their input. An empty command or Escape cancels the selection. An empty password uses an inline password if supplied, or no password. The command and password do not enter input history or Ex history.

The exporter accepts supported CSQL connection options and runs its own fixed catalog queries. It does not run SQL from the buffer. The exporter request is sent on standard input. CSQL receives its password as a transient process argument. Use an appropriate local host and account for your environment.

`:CubridRefreshSchema` fetches metadata again. If refresh fails, completion keeps the last successful schema and `:CubridSchemaStatus` reports `stale`. A failed switch clears the previous schema. `:CubridDisconnect` restores the configured offline snapshot. `:CubridReloadSchema` only reloads an existing snapshot and does not fetch from the database.

A live connection overrides snapshot selection for every buffer attached to that LSP client until disconnect. Configure separate native roots for independent connections. If a buffer has several CUBRID clients, the command asks you to select one. To prompt once when an eligible client first attaches without configured metadata, set `schema_prompt = true`. The default is `false`.

Trusted setup can set `schema_exporter` and `csql_path` to absolute executable paths. Their defaults are `cubrid-schema` and `csql` on `PATH`. `schema_timeout` defaults to 5 seconds and accepts positive values up to 300. The plugin writes private temporary snapshots and removes them when the session ends. Project files cannot select executables or credentials.

## Schema and commands

Omit `schema_snapshot` to inherit project metadata for each file. An absolute path selects a snapshot for every file. `vim.NIL` disables schema metadata. `:CubridReloadSchema` reloads snapshots and reports each document's availability and stale state. `:CubridRestart` restarts the server. Each `setup` call replaces the previous options, so include every option you want to retain.

By default, one server handles files in multiple directories and discovers project metadata per file. On Neovim 0.12.5, an unnamed buffer uses `file://`; the current server searches for its project metadata from the parent of the default initialize root. See `:help cubrid` for options and limits.
