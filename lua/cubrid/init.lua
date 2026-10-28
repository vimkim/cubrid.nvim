local M = {}
local completion = require('cubrid.completion')
local session = { phase = 'idle', buffers = {} }
local keys = {
  server_path = true, sql = true, parser_worker = true, runtime_prefix = true,
  worker_manifest = true, worker_timeout = true, profile = true, script_mode = true,
  config_path = true, schema_snapshot = true,
}

local function absolute(value, name)
  if type(value) ~= 'string' or value == '' or not (value:sub(1, 1) == '/' or value:match('^%a:[/\\]') or value:match('^\\\\')) then
    error(name .. ' must be an absolute path', 3)
  end
  return value
end

local function parse(options)
  if type(options) ~= 'table' then error('cubrid setup expects a table', 3) end
  for key in pairs(options) do
    if not keys[key] then error('unknown cubrid option: ' .. tostring(key), 3) end
  end
  local result = { server = options.server_path ~= nil and absolute(options.server_path, 'server_path') or 'cubrid-language-server', sql = options.sql or false, settings = vim.empty_dict() }
  if options.sql ~= nil and type(options.sql) ~= 'boolean' then error('sql must be a boolean', 3) end
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

local function eligible(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == 'cubrid'
end

local function update(client)
  client:notify('workspace/didChangeConfiguration', { settings = { cubrid = session.config.settings } })
end

local start
local function attach_all(client)
  for buf in pairs(session.buffers) do
    if eligible(buf) then completion.prepare(buf); vim.lsp.buf_attach_client(buf, client.id) else session.buffers[buf] = nil end
  end
end

start = function()
  if session.phase ~= 'idle' or not next(session.buffers) then return end
  local config = session.config
  if vim.fn.executable(config.server) ~= 1 then
    session.phase = 'failed'
    notice('language server is not executable: ' .. config.server, vim.log.levels.ERROR)
    return
  end
  session.phase = 'starting'
  local first = next(session.buffers)
  completion.prepare(first)
  local id = vim.lsp.start({
    name = 'cubrid', cmd = { config.server }, root_dir = vim.uv.cwd(), exit_timeout = 2000,
    init_options = { cubrid = config.settings },
    on_attach = function(client, buf) completion.attach(buf, client) end,
    on_init = function(client)
      if session.phase ~= 'starting' then return end
      session.phase = 'running'
      update(client)
      attach_all(client)
    end,
    on_exit = function(code, _, client_id)
      vim.schedule(function()
        if session.client ~= client_id then return end
        for buf in pairs(session.buffers) do completion.detach(buf) end
        session.client = nil
        if session.phase == 'disposed' then
          return
        elseif session.phase == 'stopping' then
          session.phase = 'idle'
          start()
        else
          session.phase = 'failed'
          notice('language server exited with code ' .. code .. '; use :CubridRestart to retry', vim.log.levels.ERROR)
        end
      end)
    end,
  }, { bufnr = first, reuse_client = function() return false end })
  if id then session.client = id else session.phase = 'failed'; notice('could not start language server', vim.log.levels.ERROR) end
end

local function attach(buf)
  if not session.config or not eligible(buf) then return end
  session.buffers[buf] = true
  if session.phase == 'idle' then start()
  elseif session.phase == 'running' or session.phase == 'starting' then
    local client = vim.lsp.get_client_by_id(session.client)
    if client then completion.prepare(buf); vim.lsp.buf_attach_client(buf, client.id) end
  end
end

function M.restart()
  if session.phase == 'stopping' then return end
  local client = session.client and vim.lsp.get_client_by_id(session.client)
  if client then
    session.phase = 'stopping'
    for buf in pairs(session.buffers) do completion.detach(buf, client.id) end
    client:stop()
  else
    session.phase = 'idle'
    start()
  end
end

function M.reload_schema(callback)
  local client = session.client and vim.lsp.get_client_by_id(session.client)
  if not client or session.phase ~= 'running' then
    notice('language server is not running', vim.log.levels.ERROR)
    return
  end
  client:request('workspace/executeCommand', { command = 'cubrid.reloadSchema', arguments = {} }, function(err, result)
    if err then notice('schema reload failed: ' .. vim.inspect(err), vim.log.levels.ERROR)
    else notice('schema reload: ' .. vim.inspect(result)) end
    if callback then callback(err, result) end
  end)
end

function M.setup(options)
  local config = parse(options == nil and {} or options)
  local previous = session.config
  session.config = config
  if not session.registered then
    session.registered = true
    vim.filetype.add({ pattern = {
      ['.*%.[cC][sS][qQ][lL]'] = 'cubrid',
      ['.*%.[sS][qQ][lL]'] = function() if session.config.sql then return 'cubrid' end end,
    } })
    local group = vim.api.nvim_create_augroup('cubrid', { clear = true })
    vim.api.nvim_create_autocmd('FileType', { group = group, callback = function(args)
      if eligible(args.buf) then
        attach(args.buf)
      elseif session.buffers[args.buf] then
        session.buffers[args.buf] = nil
        local client = session.client and vim.lsp.get_client_by_id(session.client)
        if client then completion.detach(args.buf, client.id); vim.lsp.buf_detach_client(args.buf, client.id) end
      end
    end })
    vim.api.nvim_create_autocmd({ 'BufUnload', 'BufWipeout' }, { group = group, callback = function(args) completion.detach(args.buf); session.buffers[args.buf] = nil end })
    vim.api.nvim_create_autocmd('LspDetach', { group = group, callback = function(args) completion.detach(args.buf, args.data.client_id) end })
    vim.api.nvim_create_autocmd('VimLeavePre', { group = group, callback = function()
      session.phase = 'disposed'
      local client = session.client and vim.lsp.get_client_by_id(session.client)
      if client then client:stop() end
    end })
    vim.api.nvim_create_user_command('CubridReloadSchema', function() M.reload_schema() end, {})
    vim.api.nvim_create_user_command('CubridRestart', function() M.restart() end, {})
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do if eligible(buf) and vim.api.nvim_buf_is_loaded(buf) then session.buffers[buf] = true end end
  if previous and previous.server ~= config.server then M.restart()
  elseif session.phase == 'running' then update(vim.lsp.get_client_by_id(session.client))
  elseif session.phase == 'idle' then start() end
end

return M
