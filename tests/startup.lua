local dir = assert(vim.env.CUBRID_TEST_DIR)
local server = (vim.env.CUBRID_TEST_SERVER or '/home/vimkim/gh/cubrid-language-tools/.venv/bin/cubrid-language-server')
local worker = '/home/vimkim/gh/cubrid-language-tools/native/parser-worker/build/parser-worker'
local runtime = '/home/vimkim/.cub/install/develop/debug'
local snapshot = dir .. '/startup.json'
local f = assert(io.open(snapshot, 'w'))
f:write('{"schemaVersion":1,"user":"DBA","relations":[]}')
f:close()
vim.notify = function() end
vim.cmd('filetype plugin indent on')
local cubrid = require('cubrid')
cubrid.setup({server_path=server})
vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/startup.csql'))
cubrid.restart()
cubrid.setup({server_path=server, parser_worker=worker, runtime_prefix=runtime, schema_snapshot=snapshot})
local function clients() return vim.lsp.get_clients({name='cubrid'}) end
assert(vim.wait(12000, function() return #clients() == 1 and clients()[1].initialized end, 50), 'restart while starting')
local result
cubrid.reload_schema(function(err, value) assert(not err, vim.inspect(err)); result = value end)
assert(vim.wait(12000, function() return result ~= nil end, 50), 'reload after restart')
assert(#result == 1 and result[1].schemaAvailable, 'latest setup applied after startup')
vim.api.nvim_buf_set_lines(0, 0, -1, false, {'SELECT ,;'})
assert(vim.wait(12000, function() for _, d in ipairs(vim.diagnostic.get(0)) do if d.code == 'CUBRID-S1001' then return true end end end, 50), 'native pair applied after startup')
clients()[1]:stop()
assert(vim.wait(12000, function() return #clients() == 0 end, 50), 'server stopped')
print('restart and configuration during startup passed')
vim.cmd('qa!')
