local base = assert(vim.env.CUBRID_TEST_DIR)
vim.cmd('filetype plugin indent on')
vim.opt.completeopt = { 'menuone', 'noselect' }
require('cubrid').setup({ server_path = assert(vim.env.CUBRID_PLUGIN_ROOT) .. '/tests/delay-server.py' })
vim.cmd('edit ' .. vim.fn.fnameescape(base .. '/choices.csql'))
assert(vim.wait(12000, function()
  local clients = vim.lsp.get_clients({ name = 'cubrid', bufnr = 0 })
  return #clients == 1 and clients[1].initialized
end, 50))
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'SELect; -- keep' })
vim.api.nvim_win_set_cursor(0, { 1, 3 })
vim.defer_fn(function() vim.api.nvim_input('i<C-X><C-O>') end, 100)
vim.defer_fn(function()
  local menu = vim.fn.complete_info({ 'pum_visible', 'items' })
  if menu.pum_visible ~= 1 or #menu.items ~= 2 or menu.items[1].abbr ~= 'same'
    or menu.items[2].abbr ~= 'same' or menu.items[2].word ~= 'SZZ' then
    io.stderr:write('FAIL duplicate menu: ' .. vim.inspect(menu) .. '\n'); vim.cmd('cquit 8')
  end
  vim.api.nvim_input('<C-N><C-N><C-Y><Esc>')
end, 2200)
vim.defer_fn(function()
  if vim.api.nvim_get_current_line() ~= 'SZZ; -- keep' then
    io.stderr:write('FAIL different start: ' .. vim.api.nvim_get_current_line() .. '\n'); vim.cmd('cquit 8')
  end
  print('PASS duplicate labels and different edit starts')
  vim.cmd('qa!')
end, 2700)
