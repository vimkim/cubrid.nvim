local dir = assert(vim.env.CUBRID_TEST_DIR)
local plugin = assert(vim.env.CUBRID_PLUGIN_ROOT)
local function wait(fn, message) assert(vim.wait(10000, fn, 20), message) end
vim.notify = function() end
vim.cmd('filetype plugin indent on')
local cubrid = require('cubrid')
cubrid.setup({ server_path = assert(vim.env.CUBRID_TEST_SERVER),
  schema_exporter = assert(vim.env.CUBRID_TEST_EXPORTER), csql_path = plugin .. '/tests/schema-csql-fixture.py' })
vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/exit.csql'))
wait(function() return #vim.lsp.get_clients({ name = 'cubrid', bufnr = 0 }) == 1 end, 'client attaches')
vim.defer_fn(function() vim.api.nvim_input('csql -udba slow -C\r') end, 40)
vim.defer_fn(function() vim.api.nvim_input('\r') end, 120)
cubrid.connect()
wait(function() return vim.uv.fs_stat(dir .. '/slow-pid') end, 'CSQL child starts')
local f = assert(io.open(dir .. '/schema-flow-result', 'w')); f:write('passed'); f:close()
vim.cmd('qa!')
