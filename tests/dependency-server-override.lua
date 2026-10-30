local dir = assert(vim.env.CUBRID_TEST_DIR)
local server = assert(vim.env.CUBRID_TEST_SERVER)
local notes = {}
vim.notify = function(message, level) notes[#notes + 1] = { message = message, level = level } end
local function wait(predicate, message) assert(vim.wait(12000, predicate, 20), message) end
local function clients() return vim.lsp.get_clients({ name = 'cubrid' }) end
vim.cmd('filetype plugin indent on')
local cubrid = require('cubrid')
cubrid.setup({ auto_start = false, server_path = server })
local selected = dir .. '/server'
vim.fn.writefile({ '#!/bin/sh', 'exit 0' }, selected)
vim.lsp.config('cubrid', { cmd = { selected } })
vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/override.csql'))
vim.wait(100)
assert(#notes == 0 and #clients() == 0, 'native override stays silent until enabled')
vim.lsp.enable('cubrid')
wait(function() return #notes > 0 end, 'native command warning')
assert(notes[1].level == vim.log.levels.WARN and notes[1].message:find(selected, 1, true)
  and notes[1].message:find('https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.en.md', 1, true),
  'native argv executable gets WARN and GitHub installation guide')
assert(#clients() == 0, 'non-executable native argv does not start a client')
vim.fn.delete(selected)
vim.uv.fs_symlink(server, selected)
vim.cmd('CubridRestart')
wait(function() return #clients() == 1 and clients()[1].initialized end, 'repairing native command and restarting recovers')
assert(clients()[1].config.cmd[1] == selected, 'recovery preserves native argv override')
local count = #notes
vim.lsp.config('cubrid', { cmd = { dir .. '/missing-replacement' } })
vim.cmd('CubridRestart')
wait(function() return #notes > count and #clients() == 0 end, 'present to missing native command warns after restart')
assert(notes[#notes].level == vim.log.levels.WARN and notes[#notes].message:find('/missing-replacement', 1, true),
  'missing native command replacement uses WARN')
vim.lsp.enable('cubrid', false)
vim.fn.writefile({ vim.json.encode(notes) }, dir .. '/dependency-notices.json')
print('PASS native argv dependency warnings and recovery')
vim.cmd('qa!')
