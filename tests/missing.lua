local dir = assert(vim.env.CUBRID_TEST_DIR)
local notes = {}
vim.notify = function(message, level) table.insert(notes, message); notes.level = level end
local function wait(f, msg) assert(vim.wait(12000, f, 50), msg) end
vim.cmd('filetype plugin indent on')
local cubrid = require('cubrid')
cubrid.setup({server_path = '/missing/cubrid-language-server'})
vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/missing.sql'))
wait(function() return #notes > 0 end, 'missing server notice')
assert(notes[1]:find('Install', 1, true) and notes[1]:find('https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.en.md', 1, true), 'missing server asks for installation with GitHub guide')
assert(notes.level == vim.log.levels.WARN, 'missing server uses warning severity')
assert(notes[1]:find('/missing/cubrid-language-server', 1, true) and notes[1]:find('server_path', 1, true) and notes[1]:find(':CubridRestart', 1, true), 'actionable missing executable reported')
local original = vim.env.CUBRID_TEST_SERVER or '/home/vimkim/gh/cubrid-language-tools/.venv/bin/cubrid-language-server'
local copy = dir .. '/no-metadata-server'
vim.fn.writefile(vim.fn.readfile(original, 'b'), copy, 'b')
vim.fn.setfperm(copy, 'rwxr-xr-x')
cubrid.setup({server_path = copy})
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
local count = #notes
local unavailable = dir .. '/non-executable-server'
vim.fn.writefile({ '#!/bin/sh', 'exit 0' }, unavailable)
cubrid.setup({server_path = unavailable})
wait(function() return #notes > count and #vim.lsp.get_clients({name='cubrid'}) == 0 end, 'present to missing server stops old session and warns')
assert(notes[#notes]:find(unavailable, 1, true) and notes.level == vim.log.levels.WARN, 'non-executable replacement uses WARN')
vim.fn.writefile(vim.fn.readfile(original, 'b'), unavailable, 'b')
vim.fn.setfperm(unavailable, 'rwxr-xr-x')
vim.cmd('CubridRestart')
wait(function() local c=vim.lsp.get_clients({name='cubrid'}); return #c == 1 and c[1].initialized end, 'restart repairs the same server path')
vim.lsp.enable('cubrid', false)
wait(function() return #vim.lsp.get_clients({name='cubrid'}) == 0 end, 'server shutdown')
print('missing server and runtime passed')
vim.cmd('qa!')
