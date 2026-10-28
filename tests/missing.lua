local dir = assert(vim.env.CUBRID_TEST_DIR)
local notes = {}
vim.notify = function(message) table.insert(notes, message) end
local function wait(f, msg) assert(vim.wait(12000, f, 50), msg) end
vim.cmd('filetype plugin indent on')
local cubrid = require('cubrid')
cubrid.setup({server_path = '/missing/cubrid-language-server'})
vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/missing.csql'))
wait(function() return #notes > 0 end, 'missing server notice')
assert(notes[1]:find('not executable', 1, true), 'missing executable reported')
cubrid.setup({server_path = '/home/vimkim/gh/cubrid-language-tools/.venv/bin/cubrid-language-server'})
wait(function() return #vim.lsp.get_clients({name = 'cubrid'}) == 1 and vim.lsp.get_clients({name = 'cubrid'})[1].initialized end, 'retry with valid server')
local client = vim.lsp.get_clients({name = 'cubrid'})[1]
vim.api.nvim_buf_set_lines(0, 0, -1, false, {'SELect'})
wait(function() for _, d in ipairs(vim.diagnostic.get(0)) do if d.code == 'CUBRID-T1001' then return true end end end, 'missing runtime diagnostic')
local response
client:request('textDocument/completion', {textDocument = {uri = vim.uri_from_bufnr(0)}, position = {line = 0, character = 3}}, function(err, result) assert(not err, vim.inspect(err)); response = result end, 0)
wait(function() return response ~= nil end, 'keyword completion response')
local found = false
for _, item in ipairs(response.items or response) do if item.label:upper() == 'SELECT' then found = true end end
assert(found, 'keyword completion without runtime')
client:stop()
wait(function() return #vim.lsp.get_clients({name='cubrid'}) == 0 end, 'server shutdown')
print('missing server and runtime passed')
vim.cmd('qa!')
