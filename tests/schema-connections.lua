local cubrid = require('cubrid')
local server = assert(vim.env.CUBRID_TEST_SERVER)
assert(not pcall(cubrid.setup, { schema_timeout = 0 }), 'zero timeout is rejected')
assert(not pcall(cubrid.setup, { schema_exporter = 'relative' }), 'exporter path must be absolute')
cubrid.setup({ server_path = server, schema_prompt = false })
for _, name in ipairs({ 'CubridConnect', 'CubridRefreshSchema', 'CubridDisconnect', 'CubridSchemaStatus' }) do
  assert(vim.fn.exists(':' .. name) == 2, name .. ' command exists')
  assert(not pcall(vim.cmd, name .. ' secret'), name .. ' rejects arguments')
end
assert(type(cubrid.connect) == 'function' and type(cubrid.refresh_schema) == 'function')
assert(type(cubrid.disconnect) == 'function' and type(cubrid.schema_status) == 'function')
print('schema connection interface passed')
vim.cmd('qa!')
