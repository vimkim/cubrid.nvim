local base = assert(vim.env.CUBRID_TEST_DIR)
local snapshot = base .. '/unsupported-schema.json'
vim.fn.writefile({ '{"schemaVersion":1,"user":"DBA","relations":[{"owner":"DBA","name":"CUSTOMERS","kind":"CLASS","columns":[]}]}' }, snapshot)
local notices = {}
vim.notify = function(message) notices[#notices + 1] = message end
vim.cmd('filetype plugin indent on')
vim.opt.completeopt = { 'menuone', 'noselect' }
require('cubrid').setup({ server_path = assert(vim.env.CUBRID_TEST_SERVER), schema_snapshot = snapshot })
vim.cmd('edit ' .. vim.fn.fnameescape(base .. '/unsupported.csql'))
assert(vim.wait(12000, function()
  local clients = vim.lsp.get_clients({ name = 'cubrid', bufnr = 0 })
  return #clients == 1 and clients[1].initialized
end, 50))
local line = 'SELECT * FROM "CUS'
vim.api.nvim_buf_set_lines(0, 0, -1, false, { line })
vim.api.nvim_win_set_cursor(0, { 1, #line - 1 })
vim.defer_fn(function() vim.api.nvim_input('i<C-X><C-O>') end, 100)
vim.defer_fn(function()
  local reported = false
  for _, message in ipairs(notices) do
    if message:find('unsupported multiline completion item', 1, true) then reported = true end
  end
  if not reported or vim.fn.pumvisible() ~= 0 or vim.api.nvim_get_current_line() ~= line then
    io.stderr:write('FAIL unsupported completion: ' .. vim.inspect(notices) .. '\n')
    vim.cmd('cquit 7')
  end
  print('PASS unsupported multiline edit is reported')
  vim.cmd('qa!')
end, 1800)
