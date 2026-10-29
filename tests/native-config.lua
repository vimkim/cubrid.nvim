local dir = assert(vim.env.CUBRID_TEST_DIR)
local server = assert(vim.env.CUBRID_TEST_SERVER)
local mode = assert(vim.env.CUBRID_NATIVE_CASE)
local function wait(predicate, message) assert(vim.wait(12000, predicate, 20), message) end
local function clients() return vim.lsp.get_clients({ name = 'cubrid' }) end
vim.cmd('filetype plugin indent on')
if mode == 'native' then
  assert(#vim.api.nvim_get_runtime_file('lsp/cubrid.lua', false) == 1, 'plugin supplies the standard cubrid LSP configuration')
end
local attached = {}
vim.lsp.config('cubrid', {
  cmd = { server },
  capabilities = { experimental = { cubridNativeConfig = true } },
  on_attach = function(client, buf) attached[buf] = client.id end,
  settings = { cubrid = { schemaSnapshot = vim.NIL, scriptMode = 'sql' } },
})
if mode == 'setup' then
  require('cubrid').setup({ server_path = server })
elseif mode == 'optout' then
  require('cubrid').setup({ auto_start = false })
  assert(not pcall(require('cubrid').setup, { auto_start = 'false' }), 'invalid activation option is rejected')
end
vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/' .. mode .. '.csql'))
vim.bo.filetype = 'cubrid'
local first = vim.api.nvim_get_current_buf()
if mode == 'optout' then
  vim.wait(300)
  assert(#clients() == 0, 'setup opt-out leaves activation to the native manager')
end
vim.lsp.enable('cubrid')
wait(function() return #clients() == 1 and attached[first] == clients()[1].id end,
  'native cubrid configuration attaches exactly one real client with the user callback')
local client = clients()[1]
assert(client.config.cmd[1] == server, 'native command overrides setup command')
assert(client.capabilities.experimental.cubridNativeConfig, 'native capabilities reach the real client')
assert(client.settings.cubrid.scriptMode == 'sql' and client.settings.cubrid.schemaSnapshot == vim.NIL,
  'native settings reach the real client')
assert(vim.bo.omnifunc:find('cubrid.completion', 1, true), 'manual completion survives user on_attach')
vim.fn.mkdir(dir .. '/second-root', 'p')
vim.cmd('cd ' .. vim.fn.fnameescape(dir .. '/second-root'))
vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/second-root/second.csql'))
vim.bo.filetype = 'cubrid'
local second = vim.api.nvim_get_current_buf()
vim.lsp.enable('cubrid')
wait(function() return attached[second] == client.id end, 'stable root shares client after cwd changes')
assert(#clients() == 1 and client.attached_buffers[first], 'setup and explicit enable share one actual client')
local result
client:request('workspace/executeCommand', { command = 'cubrid.reloadSchema', arguments = {} }, function(err, value)
  assert(not err, vim.inspect(err)); result = value
end)
wait(function() return result ~= nil end, 'configured server responds to real LSP requests')
assert(#result == 2 and not result[1].schemaAvailable and not result[2].schemaAvailable, 'settings disable schema for both documents')
assert(#vim.lsp.get_clients({ name = 'cubrid', _uninitialized = true }) == 1,
  'one client remains after both documents and a real server response, including clients still starting')
vim.lsp.enable('cubrid', false)
wait(function() return #clients() == 0 end, 'native disable stops the owned client')
print('PASS native configuration ' .. mode)
vim.cmd('qa!')
