local root = assert(vim.env.CUBRID_TEST_DIR)
local function wait(fn, message) assert(vim.wait(10000, fn, 20), message) end
local function write(path, text) local f = assert(io.open(path, 'w')); f:write(text); f:close() end
vim.notify = function() end
vim.cmd('filetype plugin indent on')
local cubrid = require('cubrid')
cubrid.setup({ server_path = assert(vim.env.CUBRID_TEST_SERVER), schema_exporter = assert(vim.env.CUBRID_TEST_EXPORTER), csql_path = vim.env.CUBRID_PLUGIN_ROOT .. '/tests/schema-csql-fixture.py' })
vim.cmd('edit ' .. vim.fn.fnameescape(root .. '/test.csql'))
wait(function() return #vim.lsp.get_clients({ name = 'cubrid', bufnr = 0 }) == 1 end, 'client attaches')
local duplicate = 'csql -udba -pInlineSecret demodb -C'
vim.fn.histadd('input', 'prior first')
vim.fn.histadd('input', duplicate)
vim.fn.histadd('input', 'prior last')
vim.fn.histadd('cmd', 'prior ex')
local function history(kind)
  local entries = {}
  for i = 1, vim.fn.histnr(kind) do entries[i] = vim.fn.histget(kind, i) end
  return entries
end
local before, ex = history('input'), history('cmd')
local function run(command, ending, password, password_end)
  vim.defer_fn(function() vim.api.nvim_input(command) end, 100)
  vim.defer_fn(function() vim.api.nvim_input(ending) end, 200)
  if password then vim.defer_fn(function() vim.api.nvim_input(password) end, 300)
    vim.defer_fn(function() vim.api.nvim_input(password_end) end, 400) end
  cubrid.connect()
  assert(vim.deep_equal(history('input'), before), 'input history changed')
  assert(vim.deep_equal(history('cmd'), ex), 'Ex history changed')
end
run(duplicate, '<CR>', 'PasswordSentinel', '<CR>')
wait(function() return vim.uv.fs_stat(root .. '/csql-launch.json') end, 'exporter started')
run('csql -udba -pNewSecret demodb -C', '<Esc>')
run('csql -udba -pNewSecret demodb -C', '<C-C>')
run('', '<CR>')
run('csql -udba demodb -C', '<CR>', 'CancelSecret', '<Esc>')
run('csql -udba demodb -C', '<CR>', 'CancelSecret', '<C-C>')
write(root .. '/visible-result', 'passed')
vim.cmd('qa!')
