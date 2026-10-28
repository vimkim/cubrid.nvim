local base = assert(vim.env.CUBRID_TEST_DIR)
vim.cmd('filetype plugin indent on')
vim.cmd('edit ' .. vim.fn.fnameescape(base .. '/ownership.csql'))
vim.bo.filetype = 'cubrid'
vim.bo.omnifunc = 'CustomComplete'
require('cubrid').setup({ server_path = assert(vim.env.CUBRID_TEST_SERVER) })
local function wait(fn) assert(vim.wait(12000, fn, 50), 'completion lifecycle timeout') end
local buf = vim.api.nvim_get_current_buf()
wait(function() return vim.bo[buf].omnifunc:find('cubrid.completion', 1, true) ~= nil end)
vim.bo[buf].filetype = 'text'
wait(function() return vim.bo[buf].omnifunc == 'CustomComplete' end)
vim.bo[buf].filetype = 'cubrid'
wait(function() return vim.bo[buf].omnifunc:find('cubrid.completion', 1, true) ~= nil end)
vim.bo[buf].omnifunc = 'ChangedLater'
vim.bo[buf].filetype = 'text'
wait(function() return vim.bo[buf].omnifunc == 'ChangedLater' end)
print('PASS omnifunc ownership')
vim.cmd('qa!')
