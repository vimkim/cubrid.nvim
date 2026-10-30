local dir = assert(vim.env.CUBRID_TEST_DIR)
local server = vim.env.CUBRID_TEST_SERVER or '/home/vimkim/gh/cubrid-language-tools/.venv/bin/cubrid-language-server'
local notes = {}
vim.notify = function(message, level) table.insert(notes, message); notes.level = level end
local old_path = vim.env.PATH
vim.env.PATH = dir .. '/empty-path'
vim.fn.mkdir(vim.env.PATH, 'p')
vim.cmd('filetype plugin indent on')
require('cubrid').setup()
vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/default-missing.sql'))
assert(vim.wait(3000, function() return #notes > 0 end), 'missing PATH notice')
assert(vim.bo.filetype == 'cubrid' and vim.bo.indentexpr ~= '', 'lexical support remains')
assert(notes.level == vim.log.levels.WARN, 'missing server uses warning severity')
assert(notes[1]:find('Install', 1, true) and notes[1]:find('https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.en.md', 1, true), 'missing server asks for installation with GitHub guide')
assert(notes[1]:find('cubrid-language-server', 1, true) and notes[1]:find('PATH', 1, true) and notes[1]:find('server_path', 1, true) and notes[1]:find(':CubridRestart', 1, true), 'actionable notice')
vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/default-missing-2.sql'))
vim.wait(200)
assert(#notes == 1, 'one notice for failed attempt')
vim.env.PATH = old_path
vim.fn.mkdir(dir .. '/server-bin', 'p')
vim.uv.fs_symlink(server, dir .. '/server-bin/cubrid-language-server')
vim.env.PATH = dir .. '/server-bin:' .. old_path
vim.cmd('CubridRestart')
assert(vim.wait(12000, function() local c=vim.lsp.get_clients({name='cubrid'}); return #c == 1 and c[1].initialized end, 50), 'restart after PATH repair')
vim.lsp.get_clients({name='cubrid'})[1]:stop()
print('missing default server and restart passed')
vim.cmd('qa!')
