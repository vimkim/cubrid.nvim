vim.cmd('filetype plugin indent on')
local cubrid = require('cubrid')
cubrid.setup()
local report = cubrid.doctor()
assert(report.ok, vim.inspect(report))
assert(report.native and report.native.parserWorker, 'installed native worker discovered')
assert(report.probe == 'CUBRID-S1001', vim.inspect(report))
assert(#vim.lsp.get_clients({name = 'cubrid-doctor'}) == 0, 'doctor cleans up client')
local file = vim.fn.tempname() .. '.sql'
vim.cmd('edit ' .. vim.fn.fnameescape(file))
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'SELECT ,;' })
assert(vim.wait(15000, function()
  for _, d in ipairs(vim.diagnostic.get(0)) do if d.code == 'CUBRID-S1001' then return true end end
end, 50), 'default editor session reports native syntax diagnostic')
local function has_code(code)
  return vim.wait(12000, function()
    for _, d in ipairs(vim.diagnostic.get(0)) do if d.code == code then return true end end
  end, 50)
end
cubrid.setup({ parser_worker = '/missing/worker', runtime_prefix = '/missing/runtime' })
assert(has_code('CUBRID-T1001'), 'changed explicit native pair reports failure')
cubrid.setup()
assert(has_code('CUBRID-S1001'), 'removing explicit pair restores discovery')
local original_path = vim.env.PATH
local alternate = vim.fn.tempname()
vim.fn.mkdir(alternate, 'p')
vim.fn.writefile({ '#!/bin/sh', 'exit 1' }, alternate .. '/cubrid-language-server')
vim.fn.setfperm(alternate .. '/cubrid-language-server', 'rwxr-xr-x')
vim.env.PATH = alternate .. ':' .. original_path
cubrid.setup({ script_mode = 'sql' })
local changed = cubrid.doctor()
assert(changed.active and changed.active.server == report.server and changed.active.native.parserWorker == report.native.parserWorker, vim.inspect(changed))
assert(changed.active_differs, 'fresh PATH candidate differs from active session')
vim.env.PATH = original_path
cubrid.setup()
local before = vim.lsp.get_clients({ name = 'cubrid' })[1].id
cubrid.restart()
assert(vim.wait(15000, function() local c = vim.lsp.get_clients({ name = 'cubrid' }); return #c == 1 and c[1].id ~= before and c[1].initialized end, 50), 'restart starts a new session')
cubrid.setup({ server_path = report.server, parser_worker = report.native.parserWorker, runtime_prefix = report.native.runtimePrefix, worker_manifest = report.native.workerManifest })
local explicit = cubrid.doctor()
assert(explicit.ok and explicit.native_source == 'setup', vim.inspect(explicit))
print('discovery and doctor passed')
vim.cmd('qa!')
