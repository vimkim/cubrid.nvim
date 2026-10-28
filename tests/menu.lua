local base = assert(vim.env.CUBRID_TEST_DIR)
vim.cmd('filetype plugin indent on')
vim.opt.completeopt = { 'menuone', 'noselect' }
require('cubrid').setup({ server_path = assert(vim.env.CUBRID_TEST_SERVER) })
vim.cmd('edit ' .. vim.fn.fnameescape(base .. '/menu.csql'))
assert(vim.wait(12000, function()
  local clients = vim.lsp.get_clients({ name = 'cubrid', bufnr = 0 })
  return #clients == 1 and clients[1].initialized
end, 50), 'CUBRID client did not attach')

local prefix = "SELECT '가😀'; "
vim.api.nvim_buf_set_lines(0, 0, -1, false, { prefix .. 'SELect' })
vim.api.nvim_win_set_cursor(0, { 1, #prefix + 3 })
vim.defer_fn(function() vim.api.nvim_input('i<C-X><C-O>') end, 100)
vim.defer_fn(function()
  local menu = vim.fn.complete_info({ 'pum_visible', 'selected', 'items' })
  if menu.pum_visible ~= 1 then error('completion menu was not visible') end
  local target
  for i, item in ipairs(menu.items) do
    if item.word == 'SELECT' then target = i - 1 end
  end
  assert(target, 'SELECT was not offered in the completion menu')
  local keys = ''
  while menu.selected ~= target do
    keys = keys .. '<C-N>'
    menu.selected = (menu.selected + 1) % #menu.items
  end
  vim.api.nvim_input(keys .. '<C-Y><Esc>')
end, 1500)
vim.defer_fn(function()
  local line = vim.api.nvim_get_current_line()
  if line ~= prefix .. 'SELECT' then
    io.stderr:write('FAIL menu completion: expected ' .. prefix .. 'SELECT; got ' .. line .. '\n')
    vim.cmd('cquit 4')
  end
  assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 1, #prefix + 5 }), 'cursor is not at end of SELECT')
  print('PASS menu completion replaces the full range')
  vim.cmd('qa!')
end, 2500)
