local root = assert(vim.env.CUBRID_TEST_DIR)
local plugin = assert(vim.env.CUBRID_PLUGIN_ROOT)
local server = assert(vim.env.CUBRID_TEST_SERVER)
local real = vim.env.CUBRID_SCHEMA_FAKE ~= '1'
local exporter = real and assert(vim.env.CUBRID_TEST_EXPORTER) or plugin .. '/tests/schema-exporter-fixture.py'
local csql = real and plugin .. '/tests/schema-csql-fixture.py' or nil
local function wait(fn, message) assert(vim.wait(10000, fn, 20), message) end
local function write(path, text) local f = assert(io.open(path, 'w')); f:write(text); f:close() end
local function read(path) local f = assert(io.open(path)); local s = f:read('*a'); f:close(); return s end
local notifications = {}
vim.notify = function(value) notifications[#notifications + 1] = value end
vim.fn.histdel('input')
local offline = root .. '/offline.json'
write(offline, '{"schemaVersion":1,"user":"DBA","relations":[{"owner":"DBA","name":"OFFLINE_TABLE","kind":"CLASS","columns":["ID"]}]}')
vim.cmd('filetype plugin indent on')
local cubrid = require('cubrid')
cubrid.setup({ server_path = server, schema_exporter = exporter, csql_path = csql, schema_snapshot = offline, script_mode = 'csql' })
vim.cmd('edit ' .. vim.fn.fnameescape(root .. '/one.csql'))
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'SELECT * FROM ' })
local buf = vim.api.nvim_get_current_buf()
wait(function() return #vim.lsp.get_clients({ name = 'cubrid', bufnr = buf }) == 1 end, 'client attaches')
local client = vim.lsp.get_clients({ name = 'cubrid', bufnr = buf })[1]
local function labels(character)
  local done, value = false
  client:request('textDocument/completion', { textDocument = { uri = vim.uri_from_bufnr(buf) }, position = { line = 0, character = character or 14 } }, function(err, result)
    assert(not err, vim.inspect(err)); value = result; done = true
  end, buf)
  wait(function() return done end, 'completion')
  local result = {}
  for _, item in ipairs(value.items or value) do result[item.label] = true end
  return result
end
wait(function() return labels().OFFLINE_TABLE end, 'offline completion')
local function status()
  local before = #notifications
  cubrid.schema_status()
  wait(function() return #notifications > before end, 'status')
  return notifications[#notifications]
end
local function connect(command, password)
  vim.defer_fn(function() vim.api.nvim_input(command .. '\r') end, 40)
  vim.defer_fn(function() vim.api.nvim_input((password or '') .. '\r') end, 120)
  cubrid.connect()
end
connect('csql -udba -pInlineSecret demodb -C', 'SeparateSecret')
wait(function() return status():find('ready', 1, true) end, 'connect ready')
assert(labels().FIRST_TABLE and not labels().OFFLINE_TABLE, 'live schema overrides offline completion')
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'SELECT FIRST_TABLE. FROM FIRST_TABLE' })
vim.wait(150)
assert(labels(19).ID, 'live schema supplies column completion')
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'SELECT * FROM ' })
vim.wait(150)
if csql then
  local launch = vim.json.decode(read(root .. '/csql-launch.json'))
  assert(vim.list_contains(launch.argv, 'demodb') and vim.list_contains(launch.argv, 'SeparateSecret'), 'exporter parses command and password for CSQL')
else
  local request = vim.json.decode(vim.split(read(root .. '/requests.jsonl'), '\n')[1])
  assert(request.command == 'csql -udba -pInlineSecret demodb -C' and request.password == 'SeparateSecret', 'original request reaches exporter')
end
assert(vim.fn.histget('input', -1) == '', 'command and password absent from input history')
vim.defer_fn(function() vim.api.nvim_input('csql -udba second -C\r') end, 40)
vim.defer_fn(function() vim.api.nvim_input('\27') end, 120)
cubrid.connect()
assert(status():find('ready', 1, true) and labels().FIRST_TABLE, 'cancelled password keeps previous connection')
local text = status()
assert(not text:find('Secret', 1, true) and not text:find('-p', 1, true), 'status does not disclose request')
local snapshot = client.settings.cubrid.schemaSnapshot
assert(vim.uv.fs_stat(snapshot).mode % 512 == 384, 'snapshot mode 0600')
assert(vim.uv.fs_stat(vim.fs.dirname(snapshot)).mode % 512 == 448, 'directory mode 0700')
assert(client.settings.cubrid.scriptMode == 'csql', 'complete settings are retained')
write(root .. '/refresh', '1')
cubrid.refresh_schema()
wait(function() return status():find('ready', 1, true) and labels().REFRESH_TABLE end, 'refresh completion')
assert(not labels().FIRST_TABLE, 'refresh replaces old schema')
write(root .. '/fail', '1')
cubrid.refresh_schema()
wait(function() return status():find('stale', 1, true) end, 'refresh failure reports stale')
assert(labels().REFRESH_TABLE, 'failed refresh retains last good schema')
vim.uv.fs_unlink(root .. '/fail')
connect('csql -udba slow -C')
wait(function() return vim.uv.fs_stat(root .. '/slow-pid') end, 'slow exporter starts')
local slow_pid = tonumber(read(root .. '/slow-pid'))
connect('csql -udba fail -C')
wait(function() return not vim.uv.kill(slow_pid, 0) end, 'superseded exporter exits')
wait(function() return status():find('failed', 1, true) end, 'switch failure')
assert(not labels().REFRESH_TABLE and not labels().OFFLINE_TABLE, 'failed switch clears previous names')
vim.wait(3500)
assert(not labels().FIRST_TABLE and not labels().REFRESH_TABLE, 'obsolete export cannot restore old names')
cubrid.disconnect()
wait(function() return status():find('offline', 1, true) and labels().OFFLINE_TABLE end, 'offline restored')
assert(vim.uv.fs_stat(snapshot) == nil, 'owned snapshot removed')
assert(not vim.inspect(notifications):find('Secret', 1, true), 'notifications redact request')
local native_exit = false
vim.lsp.config('cubrid', { on_exit = function() native_exit = true end, root_dir = function(b, on_dir) on_dir(vim.fs.dirname(vim.api.nvim_buf_get_name(b))) end,
  settings = { cubrid = { scriptMode = 'sql' } } })
cubrid.restart()
wait(function() return #vim.lsp.get_clients({ name = 'cubrid' }) == 1 and vim.lsp.get_clients({name='cubrid'})[1].id ~= client.id end, 'restart replaces client')
local buffers = {}
for _, name in ipairs({ 'a', 'b' }) do
  vim.fn.mkdir(root .. '/' .. name, 'p')
  vim.cmd('edit ' .. vim.fn.fnameescape(root .. '/' .. name .. '/file.csql'))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'SELECT * FROM ' })
  buffers[#buffers + 1] = vim.api.nvim_get_current_buf()
end
wait(function() return #vim.lsp.get_clients({ name = 'cubrid' }) == 3 end, 'separate root clients')
local a = vim.lsp.get_clients({ name = 'cubrid', bufnr = buffers[1] })[1]
local b = vim.lsp.get_clients({ name = 'cubrid', bufnr = buffers[2] })[1]
assert(a.id ~= b.id, 'roots have distinct clients')
assert(vim.lsp.buf_attach_client(buffers[2], a.id), 'attach second client to current buffer')
wait(function() return #vim.lsp.get_clients({ name = 'cubrid', bufnr = buffers[2] }) == 2 end, 'both clients attach')
local select = vim.ui.select
vim.ui.select = function(items, _, callback)
  for _, candidate in ipairs(items) do if candidate.id == a.id then callback(candidate); return end end
  error('expected client is absent from chooser')
end
assert(status():find('client = ' .. a.id, 1, true), 'chooser selects requested client')
vim.ui.select = select
vim.lsp.buf_detach_client(buffers[2], a.id)
wait(function() return #vim.lsp.get_clients({ name = 'cubrid', bufnr = buffers[2] }) == 1 end, 'extra client detaches')
connect('csql -udba second -C')
wait(function() return status():find('ready', 1, true) end, 'second client ready')
local live_file = b.settings.cubrid.schemaSnapshot
assert(b.settings.cubrid.scriptMode == 'sql', 'native override survives connection')
assert(a.settings.cubrid.schemaSnapshot == offline, 'connection leaves other client offline')
vim.api.nvim_set_current_buf(buffers[1])
assert(status():find('offline', 1, true), 'first client remains offline')
vim.api.nvim_set_current_buf(buffers[2])
cubrid.setup({ server_path = server, schema_exporter = exporter, csql_path = csql, schema_snapshot = offline, schema_prompt = true })
wait(function() return not vim.uv.fs_stat(live_file) and b.settings.cubrid.schemaSnapshot == offline end, 'setup removes live snapshot and restores offline settings')
assert(b.settings.cubrid.scriptMode == 'sql', 'setup restores native settings')
assert(status():find('offline', 1, true), 'setup replacement ends session')
client, buf = b, buffers[2]
connect('csql -udba second -C')
wait(function() return status():find('ready', 1, true) end, 'live connection before missing offline restore')
assert(labels().REFRESH_TABLE, 'live schema present before setup replacement')
local missing = root .. '/missing.json'
cubrid.setup({ server_path = server, schema_exporter = exporter, csql_path = csql, schema_snapshot = missing })
wait(function() return status():find('offline', 1, true) end, 'setup ends live selection')
vim.wait(500)
assert(not labels().REFRESH_TABLE, 'missing offline snapshot cannot retain live names after setup')
cubrid.setup({ server_path = server, schema_exporter = exporter, csql_path = csql, schema_snapshot = offline })
vim.uv.fs_unlink(root .. '/slow-pid')
connect('csql -udba slow -C')
wait(function() return vim.uv.fs_stat(root .. '/slow-pid') end, 'slow exporter starts for setup replacement')
local setup_pid = tonumber(read(root .. '/slow-pid'))
cubrid.setup({ server_path = server, schema_exporter = exporter, csql_path = csql, schema_snapshot = offline })
wait(function() return not vim.uv.kill(setup_pid, 0) end, 'setup replacement cancels exporter')
wait(function() return status():find('offline', 1, true) end, 'setup invalidates running selection')
vim.uv.fs_unlink(root .. '/slow-pid')
connect('csql -udba slow -C')
wait(function() return vim.uv.fs_stat(root .. '/slow-pid') end, 'slow exporter starts before client exit')
local exit_pid = tonumber(read(root .. '/slow-pid'))
native_exit = false
b:stop()
wait(function() return native_exit and not vim.uv.kill(exit_pid, 0) end, 'native on_exit replacement still cleans exporter')
vim.api.nvim_set_current_buf(buffers[1])
local launch_before = real and read(root .. '/csql-launch.json') or read(root .. '/requests.jsonl')
vim.defer_fn(function() vim.api.nvim_input('csql -udba second -C\r') end, 40)
vim.defer_fn(function() cubrid.setup({ server_path = server, schema_exporter = exporter, csql_path = csql, schema_snapshot = offline }) end, 80)
vim.defer_fn(function() vim.api.nvim_input('secret-after-setup\r') end, 120)
cubrid.connect()
vim.wait(300)
assert(status():find('offline', 1, true), 'obsolete prompt cannot connect after setup replacement')
assert((real and read(root .. '/csql-launch.json') or read(root .. '/requests.jsonl')) == launch_before, 'obsolete prompt starts no exporter')
vim.lsp.config('cubrid', { settings = { cubrid = { invalidSetting = true } } })
cubrid.setup({ server_path = server, schema_exporter = exporter, csql_path = csql, schema_snapshot = offline })
connect('csql -udba second -C')
wait(function() return status():find('schema clear failed', 1, true) end, 'server rejects clear settings')
assert((real and read(root .. '/csql-launch.json') or read(root .. '/requests.jsonl')) == launch_before, 'failed clear barrier starts no exporter')
cubrid.refresh_schema()
wait(function() return status():find('schema clear failed', 1, true) end, 'refresh retries the clear barrier')
assert((real and read(root .. '/csql-launch.json') or read(root .. '/requests.jsonl')) == launch_before, 'failed retry starts no exporter')
write(root .. '/schema-flow-result', 'passed')
vim.cmd('qa!')
