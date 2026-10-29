local dir = assert(vim.env.CUBRID_TEST_DIR)
local root = assert(vim.env.CUBRID_PLUGIN_ROOT)
local server = assert(vim.env.CUBRID_TEST_SERVER)
local worker = '/home/vimkim/gh/cubrid-language-tools/native/parser-worker/build/parser-worker'
local runtime = '/home/vimkim/.cub/install/develop/debug'
vim.env.CUBRID_WIRE_LOG = dir .. '/native-settings-wire.jsonl'
vim.env.CUBRID_INIT_GATE = dir .. '/initialize-release'
local function wait(predicate, message) assert(vim.wait(12000, predicate, 20), message) end
local function messages(method)
  local found = {}
  if vim.fn.filereadable(vim.env.CUBRID_WIRE_LOG) == 0 then return found end
  for _, line in ipairs(vim.fn.readfile(vim.env.CUBRID_WIRE_LOG)) do
    local message = vim.json.decode(line)
    if message.method == method then found[#found + 1] = message.params end
  end
  return found
end
vim.cmd('filetype plugin indent on')
local cubrid = require('cubrid')
cubrid.setup({ auto_start = false, server_path = server, parser_worker = worker, runtime_prefix = runtime,
  schema_snapshot = vim.NIL, worker_timeout = 5, script_mode = 'csql' })
vim.lsp.config('cubrid', {
  cmd = { vim.fn.exepath('python3'), root .. '/tests/record-server.py' },
  capabilities = { experimental = { nativeWire = true } },
  settings = { cubrid = { scriptMode = 'sql' } },
})
vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/wire.csql'))
vim.lsp.enable('cubrid')
wait(function() return #messages('initialize') == 1 end, 'server receives initialize before releasing it')
local initial = messages('initialize')[1]
assert(initial.capabilities.experimental.nativeWire, 'capability override is on the wire')
assert(vim.deep_equal(initial.initializationOptions, { cubrid = {
  parserWorker = worker, runtimePrefix = runtime, schemaSnapshot = vim.NIL, workerTimeout = 5, scriptMode = 'sql',
} }), 'initialize contains complete trusted settings plus native overrides')
cubrid.setup({ auto_start = false, server_path = server, parser_worker = worker, runtime_prefix = runtime })
vim.fn.writefile({ '' }, vim.env.CUBRID_INIT_GATE)
wait(function() return #messages('workspace/didChangeConfiguration') > 0 end, 'initialization sends the newest settings')
local expected = { cubrid = { parserWorker = worker, runtimePrefix = runtime, scriptMode = 'sql' } }
assert(vim.deep_equal(messages('workspace/didChangeConfiguration')[1].settings, expected),
  'startup replacement drops removed schema and timeout and retains native overrides')
local client = vim.lsp.get_clients({ name = 'cubrid' })[1]
assert(client and client.initialized, 'real server initializes')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'SELECT ,;' })
wait(function()
  for _, d in ipairs(vim.diagnostic.get(0)) do if d.code == 'CUBRID-S1001' then return true end end
end, 'settings on the wire enable actual native diagnostics')
cubrid.setup({ auto_start = false, server_path = server })
wait(function() return #messages('workspace/didChangeConfiguration') >= 2 end, 'running setup replacement is sent')
local changes = messages('workspace/didChangeConfiguration')
assert(vim.deep_equal(changes[#changes].settings, { cubrid = { scriptMode = 'sql' } }), 'removed native pair is absent on the wire')
wait(function()
  for _, d in ipairs(vim.diagnostic.get(0)) do if d.code == 'CUBRID-T1001' then return true end end
end, 'server observes removal of the native runtime')
vim.lsp.enable('cubrid', false)
wait(function() return #vim.lsp.get_clients({ name = 'cubrid' }) == 0 end, 'native disable stops recording server')
print('PASS complete initialization and startup/running settings replacements')
vim.cmd('qa!')
