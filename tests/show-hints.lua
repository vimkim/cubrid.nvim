local dir = assert(vim.env.CUBRID_TEST_DIR)
local server = assert(vim.env.CUBRID_TEST_SERVER)
local function wait(predicate, message) assert(vim.wait(12000, predicate, 20), message) end
local function diagnostic(code)
  for _, item in ipairs(vim.diagnostic.get(0)) do if item.code == code then return item end end
end
vim.cmd('filetype plugin indent on')
require('cubrid').setup({ server_path = server,
  parser_worker = '/home/vimkim/gh/cubrid-language-tools/native/parser-worker/build/parser-worker',
  runtime_prefix = '/home/vimkim/.cub/install/develop/debug' })
vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/show-hints.csql'))
wait(function() return #vim.lsp.get_clients({ name = 'cubrid', bufnr = 0 }) == 1 end, 'native client attached')
local client = vim.lsp.get_clients({ name = 'cubrid', bufnr = 0 })[1]
local function complete(text, character, label, expected)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { text })
  local result
  client:request('textDocument/completion', { textDocument = { uri = vim.uri_from_bufnr(0) },
    position = { line = 0, character = character } }, function(err, response)
    assert(not err, vim.inspect(err)); result = response
  end, vim.api.nvim_get_current_buf())
  wait(function() return result ~= nil end, 'real completion response')
  local selected
  for _, item in ipairs(result.items or result) do if item.label == label then selected = item end end
  assert(selected and selected.textEdit, label .. ' has a real completion edit')
  vim.lsp.util.apply_text_edits({ selected.textEdit }, vim.api.nvim_get_current_buf(), client.offset_encoding)
  assert(vim.api.nvim_get_current_line() == expected, label .. ' replaces the whole token')
end
complete('SHOW TABwrong', 8, 'TABLES', 'SHOW TABLES')
complete("SELECT '😀'; SELECT /*+ USE_NLwrong */ 1;", 30, 'USE_NL', "SELECT '😀'; SELECT /*+ USE_NL */ 1;")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "SELECT '😀', /*+ BOGUS */ 1;" })
wait(function() return diagnostic('CUBRID-A1001') and diagnostic('CUBRID-U1002') end, 'authoring warning retains unsupported diagnostic')
local warning = diagnostic('CUBRID-A1001')
assert(warning.severity == vim.diagnostic.severity.WARN, 'authoring diagnostic is a warning')
assert(warning.user_data.lsp.data.category == 'authoring', 'authoring category preserved')
assert(vim.deep_equal(warning.user_data.lsp.range, { start = { line = 0, character = 17 }, ['end'] = { line = 0, character = 22 } }), 'authoring span uses original UTF-16 offsets')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "SELECT '😀', /*+ ORDERED */ 1;" })
wait(function() return not diagnostic('CUBRID-A1001') and diagnostic('CUBRID-U1002') end, 'correction clears authoring warning and retains unsupported coverage')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'SELECT 1;' })
wait(function() return #vim.diagnostic.get(0) == 0 end, 'clean supported statement clears diagnostics')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'SELECT /*+ BOGUS */ 1;' })
wait(function() return diagnostic('CUBRID-A1001') ~= nil end, 'warning restored before close')
local buf = vim.api.nvim_get_current_buf()
vim.cmd('bwipeout!')
wait(function() return not client.attached_buffers[buf] end, 'closing document detaches')
for _, item in ipairs(vim.diagnostic.get()) do assert(item.bufnr ~= buf, 'closing document clears warning') end
vim.lsp.enable('cubrid', false)
wait(function() return #vim.lsp.get_clients({ name = 'cubrid' }) == 0 end, 'server stops')
print('PASS SHOW/hint edits, exact authoring warning, correction and close clearing')
vim.cmd('qa!')
