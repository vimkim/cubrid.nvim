local M = {}
local sessions, prompted, tokens, generations = {}, {}, {}, {}
local epoch, selection_sequence = 0, 0
local api
local limit = 16 * 1024 * 1024

function M.configure(value) api = value end

local function alive(client, session)
  return sessions[client.id] == session and vim.lsp.get_client_by_id(client.id) == client and not client:is_stopped()
end

local function erase(session)
  session.request = nil
  if session.job then pcall(session.job.kill, session.job, 15); session.job = nil end
  if session.dir then vim.fn.delete(session.dir, 'rf'); session.dir = nil end
end

local function discard(id)
  local session = sessions[id]
  sessions[id] = nil
  prompted[id] = nil
  tokens[id] = nil
  generations[id] = nil
  if session then erase(session) end
end

function M.cleanup_all()
  epoch = epoch + 1
  for id, session in pairs(sessions) do sessions[id] = nil; erase(session) end
end

function M.prepare_setup()
  local active = {}
  for id in pairs(sessions) do active[id] = true end
  M.cleanup_all()
  return active
end

local function sweep()
  for _, registry in ipairs({ sessions, prompted, tokens, generations }) do
    for id in pairs(registry) do
      local client = vim.lsp.get_client_by_id(id)
      if not client or client:is_stopped() then discard(id) end
    end
  end
end

local timer = vim.uv.new_timer()
timer:start(500, 500, vim.schedule_wrap(sweep))

local function choose(callback)
  selection_sequence = selection_sequence + 1
  local selection = selection_sequence
  local current_epoch = epoch
  local buf = vim.api.nvim_get_current_buf()
  local attached = vim.lsp.get_clients({ name = 'cubrid', bufnr = 0 })
  if #attached == 0 then api.notice('no CUBRID client is attached to this buffer', vim.log.levels.ERROR); return end
  if #attached == 1 then callback(attached[1]); return end
  vim.ui.select(attached, { prompt = 'Select CUBRID client', format_item = function(c)
    return ('client %d (%s)'):format(c.id, c.config.root_dir or 'no root')
  end }, function(client)
    if epoch == current_epoch and selection == selection_sequence and client and not client:is_stopped()
      and client.attached_buffers[buf] then callback(client) end
  end)
end

local function reload(client, callback)
  local sent = client:request('workspace/executeCommand', { command = 'cubrid.reloadSchema', arguments = {} }, function(err, result)
    callback(not err and type(result) == 'table' and vim.islist(result) and result or nil)
  end)
  if not sent then callback(nil) end
end

local function cleared(result)
  if not result or #result == 0 then return false end
  for _, document in ipairs(result) do
    if type(document) ~= 'table' or type(document.profile) ~= 'string' or type(document.scriptMode) ~= 'string'
      or document.schemaAvailable ~= false or document.stale ~= false then return false end
  end
  return true
end

local function loaded(result)
  if not result or #result == 0 then return false end
  for _, document in ipairs(result) do
    if type(document) ~= 'table' or document.schemaAvailable ~= true or document.stale ~= false then return false end
  end
  return true
end

local function fail(session, message)
  session.phase = session.path and 'stale' or 'failed'
  session.error = message
  api.notice(message, vim.log.levels.ERROR)
end

local function valid_snapshot(snapshot)
  return type(snapshot) == 'table' and snapshot.schemaVersion == 1
    and type(snapshot.user) == 'string' and snapshot.user ~= ''
    and type(snapshot.database) == 'string' and snapshot.database ~= ''
    and type(snapshot.source) == 'table' and type(snapshot.source.endpoint) == 'string' and snapshot.source.endpoint ~= ''
    and type(snapshot.relations) == 'table' and vim.islist(snapshot.relations)
end

local function publish(session, contents)
  if not session.dir then
    local dir = vim.fn.tempname()
    if not vim.uv.fs_mkdir(dir, 448) then return nil end
    session.dir = dir
  end
  session.serial = (session.serial or 0) + 1
  local target = session.dir .. '/schema-' .. session.serial .. '.json'
  local temporary = target .. '.tmp'
  local fd = vim.uv.fs_open(temporary, 'wx', 384)
  if not fd then return nil end
  local written = vim.uv.fs_write(fd, contents, 0)
  vim.uv.fs_close(fd)
  if written ~= #contents or not vim.uv.fs_rename(temporary, target) then
    vim.uv.fs_unlink(temporary)
    return nil
  end
  return target
end

local function acquire(client, session)
  if not alive(client, session) or session.job then return end
  session.phase = 'loading'
  session.error = nil
  local config = api.config()
  local stdout, out_size, total, exceeded = {}, 0, 0, false
  local function consume(is_stdout, err, data)
    if err then exceeded = true end
    if not data then return end
    total = total + #data
    if total > limit then
      exceeded = true
      if session.job then pcall(session.job.kill, session.job, 15) end
      return
    end
    if is_stdout then out_size = out_size + #data; stdout[#stdout + 1] = data end
  end
  local ok, job = pcall(vim.system, { config.schema_exporter, 'export', '--csql', config.csql_path,
    '--timeout', tostring(config.schema_timeout), '--request-stdin' }, {
      stdin = true,
      stdout = function(err, data) consume(true, err, data) end,
      stderr = function(err, data) consume(false, err, data) end,
    }, function(result)
      vim.schedule(function()
        if not alive(client, session) then return end
        session.job = nil
        if exceeded or result.code ~= 0 or out_size == 0 then fail(session, 'schema export failed'); return end
        local contents = table.concat(stdout)
        local parsed, snapshot = pcall(vim.json.decode, contents)
        if not parsed or not valid_snapshot(snapshot) then fail(session, 'schema export returned invalid data'); return end
        local path = publish(session, contents)
        if not path then fail(session, 'cannot publish schema snapshot'); return end
        api.update(client, path)
        reload(client, function(states)
          if not alive(client, session) then return end
          if not loaded(states) then
            vim.uv.fs_unlink(path)
            api.update(client, session.path or vim.NIL)
            reload(client, function() end)
            fail(session, 'schema reload failed')
            return
          end
          if session.path then vim.uv.fs_unlink(session.path) end
          session.path = path
          session.phase = 'ready'
          session.label = { user = snapshot.user, endpoint = snapshot.source.endpoint }
        end)
      end)
    end)
  if not ok then fail(session, 'cannot start schema exporter'); return end
  session.job = job
  local request = vim.json.encode({ requestVersion = 1, command = session.request.command, password = session.request.password or vim.NIL })
  if #request > 65536 then
    pcall(job.kill, job, 15)
    fail(session, 'schema request is too large')
    return
  end
  job:write(request)
  job:write(nil)
end

local function next_generation(id)
  generations[id] = (generations[id] or 0) + 1
  return generations[id]
end

function M.restore_after_setup(client)
  local session = { generation = next_generation(client.id), phase = 'clearing' }
  sessions[client.id] = session
  api.update(client, vim.NIL)
  reload(client, function(states)
    if not alive(client, session) then return end
    if not cleared(states) then fail(session, 'schema clear failed'); return end
    sessions[client.id] = nil
    api.update(client)
    reload(client, function(result)
      if not result then api.notice('offline schema reload failed', vim.log.levels.ERROR) end
    end)
  end)
end

local function clear_then_acquire(client, session)
  session.phase = 'clearing'
  session.error = nil
  api.update(client, vim.NIL)
  reload(client, function(states)
    if not alive(client, session) then return end
    if not cleared(states) then fail(session, 'schema clear failed'); return end
    acquire(client, session)
  end)
end

local function connect(client, command, password)
  local old = sessions[client.id]
  local generation = next_generation(client.id)
  if old then erase(old) end
  local session = { generation = generation, phase = 'clearing', request = { command = command, password = password } }
  sessions[client.id] = session
  clear_then_acquire(client, session)
end

local function secret(prompt_text)
  local aborted = false
  local autocmd = vim.api.nvim_create_autocmd('CmdlineLeave', { callback = function()
    if vim.v.event.cmdtype == '-' then aborted = vim.v.event.abort end
  end })
  local ok, value = pcall(vim.fn.inputsecret, prompt_text)
  vim.api.nvim_del_autocmd(autocmd)
  if not ok or aborted then return nil end
  return value
end

local function prompt(client)
  tokens[client.id] = (tokens[client.id] or 0) + 1
  local token, current_epoch = tokens[client.id], epoch
  local function current()
    return epoch == current_epoch and tokens[client.id] == token
      and vim.lsp.get_client_by_id(client.id) == client and not client:is_stopped()
  end
  local command = secret('CSQL command (hidden, for example csql -udba demodb -C; empty cancels): ')
  if not command or command == '' or not current() then return end
  local password = secret('Password (empty uses the command password or no password): ')
  if password == nil or not current() then return end
  connect(client, command, password ~= '' and password or nil)
end

function M.connect()
  choose(function(client) prompt(client) end)
end

function M.refresh()
  choose(function(client)
    local session = sessions[client.id]
    if not session or not session.request then api.notice('no live schema connection', vim.log.levels.ERROR); return end
    if session.phase == 'clearing' or session.phase == 'loading' then return end
    if session.error == 'schema clear failed' then clear_then_acquire(client, session) else acquire(client, session) end
  end)
end

function M.disconnect()
  choose(function(client)
    tokens[client.id] = (tokens[client.id] or 0) + 1
    local old = sessions[client.id]
    if not old then api.notice('no live schema connection'); return end
    local session = { generation = next_generation(client.id), phase = 'clearing' }
    erase(old)
    sessions[client.id] = session
    api.update(client, vim.NIL)
    reload(client, function(states)
      if not alive(client, session) then return end
      if not cleared(states) then fail(session, 'schema clear failed'); return end
      sessions[client.id] = nil
      api.update(client)
      reload(client, function(result)
        if not result then api.notice('offline schema reload failed', vim.log.levels.ERROR) end
      end)
    end)
  end)
end

function M.status()
  choose(function(client)
    local session = sessions[client.id]
    local status = { client = client.id, root = client.config.root_dir, phase = session and session.phase or 'offline' }
    if session then
      status.error = session.error
      if session.label then status.user = session.label.user; status.endpoint = session.label.endpoint end
    end
    api.notice(vim.inspect(status))
  end)
end

function M.attached(client, buf)
  if not api.config().schema_prompt or prompted[client.id] then return end
  prompted[client.id] = true
  local current_epoch = epoch
  if client.settings.cubrid and client.settings.cubrid.schemaSnapshot ~= nil then return end
  reload(client, function(result)
    if epoch ~= current_epoch or not result or client:is_stopped() or sessions[client.id] or not vim.api.nvim_buf_is_valid(buf) then return end
    local uri = vim.uri_from_bufnr(buf)
    for _, state in ipairs(result) do
      if state.uri == uri then
        if state.schemaAvailable == false and state.schemaConfigured == false
          and type(state.profile) == 'string' then vim.schedule(function()
          if epoch == current_epoch and not client:is_stopped() and client.attached_buffers[buf]
            and vim.api.nvim_get_current_buf() == buf and not sessions[client.id] then prompt(client) end
        end) end
        return
      end
    end
  end)
end

return M
