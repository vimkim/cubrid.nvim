local cubrid = require('cubrid')
cubrid.setup()
local notice
vim.notify = function(message) notice = message end
vim.cmd('CubridDoctor')
assert(notice and notice:find('Native probe: CUBRID-S1001', 1, true), notice)
assert(notice:find('LSP log:', 1, true), notice)
vim.cmd('checkhealth cubrid')
local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
assert(text:find('Native diagnostic probe passed', 1, true), text)
assert(text:find('LSP log:', 1, true), text)
print('doctor command and health passed')
vim.cmd('qa!')
