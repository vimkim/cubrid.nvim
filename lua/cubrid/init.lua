local M = {}
local completion = require('cubrid.completion')
local environment = require('cubrid.environment')
local connections = require('cubrid.connections')
local session = { warned = {} }
local keys = {
  server_path = true, file_extensions = true, auto_start = true, parser_worker = true, runtime_prefix = true,
  worker_manifest = true, worker_timeout = true, profile = true, script_mode = true,
  config_path = true, schema_snapshot = true, schema_exporter = true, csql_path = true,
  schema_timeout = true, schema_prompt = true,
}

local function absolute(value, name)
  if type(value) ~= 'string' or value == '' or not (value:sub(1, 1) == '/' or value:match('^%a:[/\\]') or value:match('^\\\\')) then
    error(name .. ' must be an absolute path', 3)
  end
  return value
end

local function parse(options)
  if type(options) ~= 'table' then error('cubrid setup expects a table', 3) end
  if options.sql ~= nil then error('sql is no longer supported; use file_extensions: {".sql", ".csql"} for both or {".csql"} for .csql only', 3) end
  for key in pairs(options) do
    if not keys[key] then error('unknown cubrid option: ' .. tostring(key), 3) end
  end
  if options.auto_start ~= nil and type(options.auto_start) ~= 'boolean' then error('auto_start must be a boolean', 3) end
  local extensions = options.file_extensions
  if extensions == nil then extensions = { '.sql', '.csql' } end
  if type(extensions) ~= 'table' or not vim.islist(extensions) then error('file_extensions must be a dense list of .sql and .csql', 3) end
  local selected = {}
  for _, suffix in ipairs(extensions) do
    if suffix ~= '.sql' and suffix ~= '.csql' then error('file_extensions supports only .sql and .csql', 3) end
    if selected[suffix] then error('file_extensions contains a duplicate: ' .. suffix, 3) end
    selected[suffix] = true
  end
  local result = { server = options.server_path ~= nil and absolute(options.server_path, 'server_path') or 'cubrid-language-server', file_extensions = selected, auto_start = options.auto_start ~= false, settings = vim.empty_dict() }
  result.schema_exporter = options.schema_exporter ~= nil and absolute(options.schema_exporter, 'schema_exporter') or 'cubrid-schema'
  result.csql_path = options.csql_path ~= nil and absolute(options.csql_path, 'csql_path') or 'csql'
  result.schema_timeout = options.schema_timeout == nil and 5 or options.schema_timeout
  if type(result.schema_timeout) ~= 'number' or result.schema_timeout ~= result.schema_timeout or result.schema_timeout <= 0 or result.schema_timeout > 300 then error('schema_timeout must be positive and at most 300', 3) end
  if options.schema_prompt ~= nil and type(options.schema_prompt) ~= 'boolean' then error('schema_prompt must be a boolean', 3) end
  result.schema_prompt = options.schema_prompt == true
  local values = result.settings
  if options.parser_worker ~= nil or options.runtime_prefix ~= nil then
    values.parserWorker = absolute(options.parser_worker, 'parser_worker')
    values.runtimePrefix = absolute(options.runtime_prefix, 'runtime_prefix')
    if options.worker_manifest ~= nil then values.workerManifest = absolute(options.worker_manifest, 'worker_manifest') end
    if options.worker_timeout ~= nil then
      if type(options.worker_timeout) ~= 'number' or options.worker_timeout ~= options.worker_timeout or options.worker_timeout <= 0 or options.worker_timeout > 300 then error('worker_timeout must be positive and at most 300', 3) end
      values.workerTimeout = options.worker_timeout
    end
  elseif options.worker_manifest ~= nil or options.worker_timeout ~= nil then
    error('worker_manifest and worker_timeout require the native pair', 3)
  end
  if options.profile ~= nil then
    if type(options.profile) ~= 'string' or options.profile == '' then error('profile must be a nonempty string', 3) end
    values.profile = options.profile
  end
  if options.script_mode ~= nil then
    if options.script_mode ~= 'sql' and options.script_mode ~= 'csql' then error('script_mode must be sql or csql', 3) end
    values.scriptMode = options.script_mode
  end
  if options.config_path ~= nil then values.configPath = absolute(options.config_path, 'config_path') end
  if options.schema_snapshot ~= nil then
    values.schemaSnapshot = options.schema_snapshot == vim.NIL and vim.NIL or absolute(options.schema_snapshot, 'schema_snapshot')
  end
  return result
end

local function notice(message, level)
  vim.schedule(function() vim.notify('cubrid: ' .. message, level or vim.log.levels.INFO) end)
end

local function dependency_notice(resolved)
  if not resolved.error then session.dependency_error = nil; return end
  local identity = resolved.error_kind .. ':' .. resolved.server .. ':' .. resolved.error
  if session.dependency_error == identity then return end
  session.dependency_error = identity
  local guide = 'https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.en.md'
  if resolved.error_kind == 'server' then
    notice('Install cubrid-language-server using ' .. guide .. '. Missing or non-executable: ' .. resolved.server
      .. '. Add it to Neovim PATH or set trusted server_path (or vim.lsp.config cmd), then run :CubridRestart.', vim.log.levels.WARN)
  else
    notice('Strict syntax diagnostics are unavailable; keyword completion can continue.'
      .. ' Install parser-worker with its matching runtime and manifest using ' .. guide .. '. ' .. resolved.error
      .. ' Repair discovery or set trusted parser_worker and runtime_prefix (worker_manifest if needed), then run :CubridRestart.', vim.log.levels.WARN)
  end
end

local function eligible(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == 'cubrid'
end

local function warn_once(buf, identity, message)
  local warned = session.warned[buf] or {}
  session.warned[buf] = warned
  if warned[identity] then return end
  warned[identity] = true
  vim.notify('cubrid: ' .. message, vim.log.levels.WARN)
end

local function inspect_filetype(buf)
  vim.schedule(function()
    if not session.config or not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then return end
    local name = vim.api.nvim_buf_get_name(buf)
    local lower = name:lower()
    local suffix = lower:match('(%.[^./]+)$')
    local managed = session.config.file_extensions[suffix]
    local ft = vim.bo[buf].filetype
    if managed and ft ~= '' and ft ~= 'cubrid' then
      local advice = 'Exclude ' .. suffix .. ' from file_extensions or adjust the conflicting filetype configuration, then reopen the file.'
      warn_once(buf, 'filetype:' .. ft, 'filetype conflict for ' .. name .. ': expected cubrid, observed ' .. ft .. '. A filetype rule or manual setting may override detection. ' .. advice)
    end
  end)
end

local function inspect_clients(buf)
  vim.schedule(function()
    if not session.config or not eligible(buf) then return end
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
      if client.name ~= 'cubrid' then
        local name = vim.api.nvim_buf_get_name(buf)
        local advice = ' To disable automatic association, exclude its suffix from file_extensions and reopen the file.'
        warn_once(buf, 'client:' .. client.id, 'LSP client ' .. client.name .. ' (id ' .. client.id .. ') is attached to ' .. name .. ' and may overlap completion or diagnostics. Choose one server.' .. advice)
      end
    end
  end)
end

local function clients()
  return vim.lsp.get_clients({ name = 'cubrid', _uninitialized = true })
end

local default_cmd
local function resolve(config, server)
  local trusted = session.config or parse({})
  local command = config and config.cmd
  local selected = server or (type(command) == 'table' and command[1]) or trusted.server
  local settings = vim.tbl_deep_extend('force', vim.empty_dict(), trusted.settings,
    (config and config.init_options and config.init_options.cubrid) or {},
    (config and config.settings and config.settings.cubrid) or {})
  local resolved = environment.resolve({ server = selected, settings = settings })
  if command and command ~= default_cmd then resolved.server_source = 'vim.lsp.config' end
  if type(command) == 'table' then resolved.cmd = vim.deepcopy(command) end
  return resolved
end

local function update(client, snapshot)
  local previous = client.config._cubrid_active
  local config = vim.lsp.config.cubrid
  local resolved = resolve(config, previous and previous.server)
  if previous then resolved.server_source = previous.server_source end
  dependency_notice(resolved)
  client.config._cubrid_active = resolved
  client.settings = vim.deepcopy(config.settings or {})
  client.settings.cubrid = resolved.settings
  if snapshot ~= nil then client.settings.cubrid.schemaSnapshot = snapshot end
  client.config.settings = client.settings
  client.config.init_options = vim.deepcopy(config.init_options or {})
  client.config.init_options.cubrid = vim.deepcopy(resolved.settings)
  if client.initialized then
    client:notify('workspace/didChangeConfiguration', { settings = client.settings })
  end
end

function M.restart()
  connections.cleanup_all()
  if session.restarting then return end
  session.restarting = true
  session.failed = nil
  session.dependency_error = nil
  local owned = clients()
  vim.lsp.enable('cubrid', false)
  for _, client in ipairs(owned) do
    for buf in pairs(client.attached_buffers) do completion.detach(buf, client.id) end
    if not client.initialized then client:stop(2000) end
  end
  local function resume()
    if #clients() > 0 then vim.defer_fn(resume, 20); return end
    session.restarting = nil
    if vim.v.exiting == vim.NIL then vim.lsp.enable('cubrid') end
  end
  vim.schedule(resume)
end

function M.reload_schema(callback)
  local attached = vim.lsp.get_clients({ name = 'cubrid', bufnr = 0 })
  local client = attached[1] or vim.lsp.get_clients({ name = 'cubrid' })[1]
  if not client then
    notice('language server is not running', vim.log.levels.ERROR)
    return
  end
  client:request('workspace/executeCommand', { command = 'cubrid.reloadSchema', arguments = {} }, function(err, result)
    if err then notice('schema reload failed: ' .. vim.inspect(err), vim.log.levels.ERROR)
    else notice('schema reload: ' .. vim.inspect(result)) end
    if callback then callback(err, result) end
  end)
end

local function register()
  if session.registered then return end
  session.registered = true
  session.root = vim.uv.cwd()
  local group = vim.api.nvim_create_augroup('cubrid', { clear = true })
  vim.api.nvim_create_autocmd('FileType', { group = group, callback = function(args)
    inspect_filetype(args.buf)
    if eligible(args.buf) then completion.prepare(args.buf) else completion.detach(args.buf) end
  end })
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, { group = group, callback = function(args) inspect_filetype(args.buf) end })
  vim.api.nvim_create_autocmd('LspAttach', { group = group, callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == 'cubrid' then
      completion.attach(args.buf, client)
      connections.attached(client, args.buf)
    end
    inspect_clients(args.buf)
  end })
  vim.api.nvim_create_autocmd('BufWipeout', { group = group, callback = function(args) session.warned[args.buf] = nil end })
  vim.api.nvim_create_autocmd({ 'BufUnload', 'BufWipeout' }, { group = group, callback = function(args) completion.detach(args.buf) end })
  vim.api.nvim_create_autocmd('LspDetach', { group = group, callback = function(args) completion.detach(args.buf, args.data.client_id) end })
  vim.api.nvim_create_autocmd('VimLeavePre', { group = group, callback = connections.cleanup_all })
  vim.api.nvim_create_user_command('CubridConnect', function() M.connect() end, {})
  vim.api.nvim_create_user_command('CubridRefreshSchema', function() M.refresh_schema() end, {})
  vim.api.nvim_create_user_command('CubridDisconnect', function() M.disconnect() end, {})
  vim.api.nvim_create_user_command('CubridSchemaStatus', function() M.schema_status() end, {})
  vim.api.nvim_create_user_command('CubridReloadSchema', function() M.reload_schema() end, {})
  vim.api.nvim_create_user_command('CubridRestart', function() M.restart() end, {})
  vim.api.nvim_create_user_command('CubridDoctor', function() vim.notify(require('cubrid.doctor').format(M.doctor())) end, {})
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do if eligible(buf) then completion.prepare(buf) end end
end

default_cmd = function(dispatchers, config)
  local resolved = resolve(config)
  dependency_notice(resolved)
  config._cubrid_active = resolved
  return vim.lsp.rpc.start({ resolved.server }, dispatchers, { cwd = config.cmd_cwd, env = config.cmd_env, detached = config.detached })
end

function M.lsp_config()
  register()
  local available = not session.failed and vim.fn.executable(resolve().server) == 1
  -- Inspect the merged native configuration after Neovim finishes loading it.
  vim.schedule(function()
    if not vim.lsp.is_enabled('cubrid') then return end
    local config = vim.lsp.config.cubrid
    local resolved = resolve(config)
    if config.cmd == default_cmd or type(config.cmd) == 'table' or resolved.error_kind ~= 'server' then
      dependency_notice(resolved)
    end
  end)
  return {
    cmd = default_cmd,
    filetypes = { 'cubrid' },
    exit_timeout = 2000,
    settings = { cubrid = vim.empty_dict() },
    root_dir = available and session.root or function(buf, on_dir)
      if session.failed or session.restarting then return end
      local config = vim.lsp.config.cubrid
      local resolved = resolve(config)
      if (config.cmd == default_cmd or type(config.cmd) == 'table') and resolved.error_kind == 'server' then
        session.failed = true
        dependency_notice(resolved)
        return
      end
      completion.prepare(buf)
      on_dir(session.root)
    end,
    before_init = function(params, config)
      local resolved = config._cubrid_active or resolve(config)
      if resolved.error_kind ~= 'server' then dependency_notice(resolved) end
      config._cubrid_active = resolved
      config.settings.cubrid = vim.deepcopy(resolved.settings)
      config.init_options = vim.deepcopy(config.init_options or {})
      config.init_options.cubrid = vim.deepcopy(resolved.settings)
      params.initializationOptions = config.init_options
    end,
    on_exit = function(code)
      if session.restarting or not vim.lsp.is_enabled('cubrid') or vim.v.exiting ~= vim.NIL then return end
      session.failed = true
      vim.lsp.config('cubrid', {})
      notice('language server exited with code ' .. code .. '; use :CubridRestart to retry', vim.log.levels.ERROR)
    end,
  }
end

function M.setup(options)
  local config = parse(options == nil and {} or options)
  local previous = session.config
  local active_connections = connections.prepare_setup()
  session.config = config
  register()
  if not session.filetypes then
    session.filetypes = true
    vim.filetype.add({ pattern = {
      ['.*%.[cC][sS][qQ][lL]'] = function() if session.config.file_extensions['.csql'] then return 'cubrid' end end,
      ['.*%.[sS][qQ][lL]'] = function() if session.config.file_extensions['.sql'] then return 'cubrid' end end,
    } })
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if eligible(buf) then completion.prepare(buf); inspect_clients(buf) end
  end
  if previous and previous.server ~= config.server and vim.lsp.is_enabled('cubrid') then
    M.restart()
  else
    for _, client in ipairs(clients()) do
      if active_connections[client.id] then connections.restore_after_setup(client) else update(client) end
    end
    if config.auto_start and not session.restarting then vim.lsp.enable('cubrid') end
  end
end

connections.configure({
  config = function() return session.config or parse({}) end,
  update = update,
  notice = notice,
})
M.connect = connections.connect
M.refresh_schema = connections.refresh
M.disconnect = connections.disconnect
M.schema_status = connections.status

function M.doctor()
  local attached = vim.lsp.get_clients({ name = 'cubrid', bufnr = 0, _uninitialized = true })
  local client = attached[1] or clients()[1]
  return require('cubrid.doctor').run(resolve(vim.lsp.config.cubrid), {
    client = client and client.id,
    active = client and client.config._cubrid_active,
    phase = client and (client.initialized and 'running' or 'starting') or 'idle',
  })
end

return M
