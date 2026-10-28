local dir = assert(vim.env.CUBRID_TEST_DIR) .. '/projects'
local function wait(f, message) assert(vim.wait(12000, f, 50), message) end
local function write(path, data) local file = assert(io.open(path, 'wb')); file:write(data); file:close() end
vim.fn.mkdir(dir .. '/nested', 'p')
write(dir .. '/one.json', '{"schemaVersion":1,"user":"DBA","relations":[{"owner":"DBA","name":"PARENT_TABLE","kind":"CLASS","columns":[]}]}')
write(dir .. '/nested/two.json', '{"schemaVersion":1,"user":"DBA","relations":[{"owner":"DBA","name":"CHILD_TABLE","kind":"CLASS","columns":[]}]}')
write(dir .. '/.cubrid-language.json', '{"schemaSnapshot":"one.json"}')
write(dir .. '/nested/.cubrid-language.json', '{"schemaSnapshot":"two.json"}')
write(dir .. '/one.csql', 'SELECT * FROM PARENT\n')
write(dir .. '/nested/two.csql', 'SELECT * FROM CHILD\n')
vim.notify = function() end
vim.cmd('cd ' .. vim.fn.fnameescape(dir .. '/nested'))
vim.cmd('filetype plugin indent on')
local cubrid = require('cubrid')
cubrid.setup({ server_path = (vim.env.CUBRID_TEST_SERVER or '/home/vimkim/gh/cubrid-language-tools/.venv/bin/cubrid-language-server') })
vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/one.csql'))
local first = vim.api.nvim_get_current_buf()
wait(function() local c = vim.lsp.get_clients({name='cubrid'}); return #c == 1 and c[1].initialized end, 'first client')
local client = vim.lsp.get_clients({name='cubrid'})[1]
vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/nested/two.csql'))
local second = vim.api.nvim_get_current_buf()
wait(function() return client.attached_buffers[second] end, 'second document')
local function completion(buf, character)
  local result
  client:request('textDocument/completion', { textDocument = { uri = vim.uri_from_bufnr(buf) }, position = {line=0,character=character} }, function(err, value) assert(not err, vim.inspect(err)); result = value end, buf)
  wait(function() return result ~= nil end, 'completion')
  local labels = {}
  for _, item in ipairs(result.items or result) do labels[item.label] = true end
  return labels
end
assert(completion(first, 20).PARENT_TABLE, 'parent snapshot')
assert(completion(second, 19).CHILD_TABLE, 'nested snapshot')
assert(#vim.lsp.get_clients({name='cubrid'}) == 1, 'one client across roots')
local result
cubrid.reload_schema(function(err, value) assert(not err, vim.inspect(err)); result = value end)
wait(function() return result ~= nil end, 'reload')
assert(#result == 2 and result[1].schemaAvailable and result[2].schemaAvailable, 'reload reports both documents')
print('per-document reload=' .. vim.inspect(result))
vim.cmd('enew')
vim.bo.filetype = 'cubrid'
local untitled = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(untitled, 0, -1, false, { 'SELECT * FROM PARENT' })
wait(function() return client.attached_buffers[untitled] end, 'untitled attached')
print('untitled uri=' .. vim.uri_from_bufnr(untitled))
print('untitled labels=' .. vim.inspect(completion(untitled, 20)))
local untitled_result
cubrid.reload_schema(function(err, value) assert(not err, vim.inspect(err)); untitled_result = value end)
wait(function() return untitled_result ~= nil end, 'untitled reload')
print('untitled reload=' .. vim.inspect(untitled_result))
assert(completion(untitled, 20).PARENT_TABLE, 'untitled discovers metadata from initialize root parent')
print('untitled root=' .. client.config.root_dir)
client:stop()
wait(function() return #vim.lsp.get_clients({name='cubrid'}) == 0 end, 'server stopped')
print('project metadata passed')
vim.cmd('qa!')
