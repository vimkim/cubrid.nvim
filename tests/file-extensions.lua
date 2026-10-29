local dir = assert(vim.env.CUBRID_TEST_DIR)
local cubrid = require('cubrid')
vim.notify = function() end
vim.cmd('filetype plugin indent on')
local serial = 0
local function open(suffix, expected)
  serial = serial + 1
  vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/extension' .. serial .. suffix))
  assert(vim.bo.filetype == expected, suffix .. ': expected ' .. expected .. ', got ' .. vim.bo.filetype)
end
local function setup(extensions)
  cubrid.setup({server_path='/missing/cubrid-language-server', file_extensions=extensions})
end
cubrid.setup({server_path='/missing/cubrid-language-server'})
open('.SQL', 'cubrid'); open('.CSql', 'cubrid')
setup({'.csql'})
open('.sql', 'sql'); open('.CSQL', 'cubrid')
local old = vim.api.nvim_get_current_buf()
setup({'.sql'})
assert(vim.bo[old].filetype == 'cubrid', 'setup does not retag existing buffers')
open('.SQL', 'cubrid'); open('.csql', '')
setup({})
open('.sql', 'sql'); open('.csql', '')
setup({'.csql'})
for _, invalid in ipairs({ 'sql', {'.sql', '.sql'}, {'.SQL'}, {[1]='.sql', [3]='.csql'}, {foo='.sql'}, {true} }) do
  assert(not pcall(setup, invalid), 'invalid list accepted: ' .. vim.inspect(invalid))
  open('.sql', 'sql'); open('.csql', 'cubrid')
end
for _, options in ipairs({{sql=false}, {sql=true, file_extensions={'.sql'}}}) do
  local ok, err = pcall(cubrid.setup, options)
  assert(not ok and err:find('file_extensions', 1, true) and err:find('.sql', 1, true) and err:find('.csql', 1, true), 'legacy option must give migration advice')
  open('.sql', 'sql'); open('.csql', 'cubrid')
end
cubrid.setup({server_path='/missing/cubrid-language-server'})
open('.sql', 'cubrid'); open('.csql', 'cubrid')
print('file extension selection passed')
vim.cmd('qa!')
