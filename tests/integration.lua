local base = assert(vim.env.CUBRID_TEST_DIR)
local server = (vim.env.CUBRID_TEST_SERVER or '/home/vimkim/gh/cubrid-language-tools/.venv/bin/cubrid-language-server')
local worker = '/home/vimkim/gh/cubrid-language-tools/native/parser-worker/build/parser-worker'
local runtime = '/home/vimkim/.cub/install/develop/debug'
assert(vim.fn.executable(server) == 1 and vim.fn.executable(worker) == 1 and vim.fn.isdirectory(runtime) == 1, 'native prerequisites required')
local notifications = {}
vim.lsp.set_log_level('trace')
vim.notify = function(message, level) table.insert(notifications, { message = message, level = level }) end
local function check(value, message) assert(value, message) end
local function wait(fn, message) check(vim.wait(12000, fn, 50), message) end
local function write(path, content) local f = assert(io.open(path, 'wb')); f:write(content); f:close() end
local function read(path) local f = assert(io.open(path, 'rb')); local s = f:read('*a'); f:close(); return s end
local function children()
  return read('/proc/' .. vim.fn.getpid() .. '/task/' .. vim.fn.getpid() .. '/children')
end
local function clients() return vim.lsp.get_clients({ name = 'cubrid' }) end
local function request(client, method, params)
  local done, error_value, result = false
  client:request(method, params, function(err, res) error_value, result, done = err, res, true end, 0)
  wait(function() return done end, method .. ' response')
  check(not error_value, vim.inspect(error_value))
  return result
end
local function reload()
  local done, err, result = false
  require('cubrid').reload_schema(function(e, r) err, result, done = e, r, true end)
  wait(function() return done end, 'reload response')
  check(not err, vim.inspect(err))
  return result
end
local function diag(code)
  for _, d in ipairs(vim.diagnostic.get(0)) do if d.code == code then return d end end
end
vim.cmd('filetype plugin indent on')
vim.cmd('syntax on')
local snapshot = base .. '/schema.json'
write(snapshot, '{"schemaVersion":1,"user":"DBA","relations":[{"owner":"DBA","name":"CUSTOMERS","kind":"CLASS","columns":["ID"]}]}')
local opts = { server_path = server, parser_worker = worker, runtime_prefix = runtime, schema_snapshot = snapshot }
require('cubrid').setup({ server_path = server, parser_worker = worker, runtime_prefix = runtime })
local file = base .. '/unicode.CSQL'
write(file, "SELECT '가😀';\r\nCREATE SERIAL s START WITH ;\r\nCREATE PROCEDURE p;\r\n")
vim.cmd('edit ' .. vim.fn.fnameescape(file))
check(vim.bo.filetype == 'cubrid', 'filetype')
require('cubrid').setup(opts)
check(not pcall(require('cubrid').setup, { parser_worker = worker }), 'invalid update rejected')
wait(function() return #clients() == 1 and clients()[1].initialized end, 'one client initialized')
local client = clients()[1]
local initial_children = children()
check(initial_children:match('%d'), 'owned server process exists')
print('nvim pid=' .. vim.fn.getpid() .. ' direct children=' .. initial_children)
print('root_dir=' .. vim.inspect(client.config.root_dir) .. ' root_uri=' .. vim.inspect(client.workspace_folders))
wait(function() return diag('CUBRID-S1001') and diag('CUBRID-U1002') end, 'native syntax and unsupported diagnostics')
print('native diagnostics=' .. vim.inspect(vim.diagnostic.get(0)))
check(diag('CUBRID-S1001').user_data.lsp.range.start.character == 13, 'UTF-16 syntax start')
check(diag('CUBRID-U1002').user_data.lsp.range.start.line == 1, 'unsupported range')
check(vim.bo.fileformat == 'dos', 'CRLF detected')
check(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == "SELECT '가😀';", 'buffer LF normalized')
check(vim.fn.synIDattr(vim.fn.synID(1, 1, 1), 'name') == 'cubridKeyword', 'lexical keyword')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "SELECT '가😀'; SELect" })
wait(function() return client.attached_buffers[vim.api.nvim_get_current_buf()] end, 'buffer attached')
vim.wait(500)
local complete = request(client, 'textDocument/completion', { textDocument = { uri = vim.uri_from_bufnr(0) }, position = { line = 0, character = 16 } })
local items = complete.items or complete
local item
for _, value in ipairs(items) do if value.label:upper() == 'SELECT' then item = value; break end end
check(item and item.textEdit, 'whole token completion')
print('completion edit=' .. vim.inspect(item.textEdit))
vim.lsp.util.apply_text_edits({ item.textEdit }, vim.api.nvim_get_current_buf(), client.offset_encoding)
check(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == "SELECT '가😀'; SELECT", 'suffix replaced by native edit API')
vim.cmd('write')
local bytes = read(file)
check(bytes:find('\r\n', 1, true) and not bytes:gsub('\r\n', ''):find('\n', 1, true), 'CRLF preserved on disk')
local r = reload()
print('reload available=' .. vim.inspect(r))
check(r[1].schemaAvailable and not r[1].stale, 'schema loaded')
write(snapshot, '{ invalid')
r = reload()
print('reload stale=' .. vim.inspect(r))
check(r[1].schemaAvailable and r[1].stale, 'failed reload stale')
write(snapshot, '{"schemaVersion":1,"user":"DBA","relations":[]}')
r = reload()
check(r[1].schemaAvailable and not r[1].stale, 'reload recovers')
opts.schema_snapshot = vim.NIL
require('cubrid').setup(opts)
r = reload()
check(not r[1].schemaAvailable and not r[1].stale, 'schema disabled')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'SELECT ,;' })
wait(function() return diag('CUBRID-S1001') end, 'native settings retained after schema update')
local one = vim.api.nvim_get_current_buf()
vim.fn.mkdir(base .. '/nested', 'p')
write(base .. '/nested/second.csql', 'SELECT 1;\n')
vim.cmd('edit ' .. vim.fn.fnameescape(base .. '/nested/second.csql'))
local two = vim.api.nvim_get_current_buf()
wait(function() return client.attached_buffers[two] end, 'second attached')
check(#clients() == 1 and client.attached_buffers[one], 'one session for roots')
vim.bo[two].filetype = 'sql'
wait(function() return not client.attached_buffers[two] end, 'filetype change detaches')
vim.bo[two].filetype = 'cubrid'
wait(function() return client.attached_buffers[two] end, 'filetype change reattaches')
require('cubrid').setup(opts)
check(#clients() == 1, 'idempotent setup')
local old = client.id
require('cubrid').restart()
wait(function() return #clients() == 1 and clients()[1].id ~= old and clients()[1].initialized end, 'restart')
client = clients()[1]
wait(function() return client.attached_buffers[one] and client.attached_buffers[two] end, 'reattach after restart')
vim.cmd('bwipeout!')
wait(function() return not client.attached_buffers[two] end, 'close detaches')
for _, d in ipairs(vim.diagnostic.get()) do check(d.bufnr ~= two, 'close clears diagnostics') end
client:stop()
wait(function() return #clients() == 0 and children():match('^%s*$') end, 'owned server stops')
print('direct children after shutdown=' .. vim.inspect(children()))
print('integration passed')
vim.cmd('qa!')
