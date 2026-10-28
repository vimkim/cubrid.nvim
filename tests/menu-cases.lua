local base = assert(vim.env.CUBRID_TEST_DIR)
local snapshot = base .. '/menu-schema.json'
vim.fn.writefile({ '{"schemaVersion":1,"user":"DBA","relations":[{"owner":"DBA","name":"CUSTOMERS","kind":"CLASS","columns":["ID"]},{"owner":"DBA","name":"CUSTOM_ORDERS","kind":"CLASS","columns":["ITEM_ID"]}]}' }, snapshot)
vim.cmd('filetype plugin indent on')
vim.opt.completeopt = { 'menuone', 'noselect' }
require('cubrid').setup({ server_path = assert(vim.env.CUBRID_TEST_SERVER), schema_snapshot = snapshot })
local path = base .. '/menu-cases.csql'
vim.fn.writefile({ '' }, path)
vim.cmd('edit ' .. vim.fn.fnameescape(path))
assert(vim.wait(12000, function()
  local clients = vim.lsp.get_clients({ name = 'cubrid', bufnr = 0 })
  return #clients == 1 and clients[1].initialized
end, 50), 'CUBRID client did not attach')

local cases = {
  { name = 'no suffix', line = 'SEL; -- keep', cursor = 3, word = 'SELECT', expected = 'SELECT; -- keep' },
  { name = 'qualified second choice', line = 'SELECT * FROM DBA.CUSTOMERS; -- keep', cursor = 21, word = 'CUSTOMERS', expected = 'SELECT * FROM DBA.CUSTOMERS; -- keep', cycle = true },
  { name = 'quoted replacement', line = 'SELECT * FROM "CUSTOMERS"; -- keep', cursor = 18, word = '"CUSTOM_ORDERS"', expected = 'SELECT * FROM "CUSTOM_ORDERS"; -- keep', cycle = true, undo = true },
  { name = 'cancel', line = "SELECT '가😀'; SELect; -- keep", cursor = #"SELECT '가😀'; SEL", cancel = true },
  { name = 'undo', line = "SELECT '가😀'; SELect; -- keep", cursor = #"SELECT '가😀'; SEL", word = 'SELECT', expected = "SELECT '가😀'; SELECT; -- keep", undo = true, crlf = true },
}

local function fail(message)
  io.stderr:write('FAIL menu cases: ' .. message .. '\n')
  vim.cmd('cquit 5')
end
local function later(ms, fn)
  vim.defer_fn(function()
    local ok, err = xpcall(fn, debug.traceback)
    if not ok then fail(err) end
  end, ms)
end
local function poll(fn, continuation, attempts)
  if fn() then continuation(); return end
  assert(attempts > 0, 'completion menu did not appear')
  later(50, function() poll(fn, continuation, attempts - 1) end)
end
local index = 0
local function run()
  index = index + 1
  local case = cases[index]
  if not case then print('PASS menu cases'); vim.cmd('qa!'); return end
  local file = assert(io.open(path, 'wb'))
  file:write(case.line .. (case.crlf and '\r\n' or '\n'))
  file:close()
  vim.cmd('edit!')
  vim.api.nvim_win_set_cursor(0, { 1, case.cursor })
  vim.api.nvim_input('i<C-X><C-O>')
  poll(function() return vim.fn.complete_info({ 'pum_visible' }).pum_visible == 1 end, function()
    local menu = vim.fn.complete_info({ 'items', 'selected' })
    if case.cancel then vim.api.nvim_input('<C-E><Esc>')
    else
      local target
      for i, item in ipairs(menu.items) do if item.word == case.word then target = i - 1 end end
      assert(target, case.name .. ': missing ' .. case.word .. ' in ' .. vim.inspect(menu.items))
      local keys = ''
      if case.cycle then keys = '<C-N><C-N><C-P>'; menu.selected = 0 end
      while menu.selected ~= target do keys = keys .. '<C-N>'; menu.selected = (menu.selected + 1) % #menu.items end
      vim.api.nvim_input(keys .. '<C-Y><Esc>')
    end
    later(150, function()
      local expected = case.expected or case.line
      assert(vim.api.nvim_get_current_line() == expected, case.name .. ': got ' .. vim.api.nvim_get_current_line())
      if case.word then
        local expected_col = #expected - #(expected:match('; %-%- keep$') or '') - 1
        assert(vim.api.nvim_win_get_cursor(0)[2] == expected_col, case.name .. ': wrong cursor')
      end
      if case.crlf then
        vim.cmd('write')
        local saved = assert(io.open(path, 'rb'))
        local bytes = saved:read('*a'); saved:close()
        assert(bytes == expected .. '\r\n', 'CRLF save: ' .. vim.inspect(bytes))
      end
      if case.undo then
        vim.cmd('undo')
        assert(vim.api.nvim_get_current_line() == case.line, 'one undo must restore original line')
      end
      print('PASS ' .. case.name)
      later(100, run)
    end)
  end, 200)
end
later(100, run)
