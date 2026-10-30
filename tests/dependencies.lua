local dir = assert(vim.env.CUBRID_TEST_DIR)
local original = assert(vim.env.CUBRID_TEST_SERVER)
local mode = assert(vim.env.CUBRID_DEPENDENCY_CASE)
local notes = {}
vim.notify = function(message, level) notes[#notes + 1] = { message = message, level = level } end
local function wait(predicate, message) assert(vim.wait(12000, predicate, 20), message) end
local function client()
  local found = vim.lsp.get_clients({ name = 'cubrid' })
  return #found == 1 and found[1].initialized and found[1] or nil
end
local function warning(index, detail)
  wait(function() return #notes >= index end, 'dependency warning: ' .. detail)
  local note = notes[index]
  assert(note.level == vim.log.levels.WARN, 'dependency notice uses WARN: ' .. vim.inspect(note))
  for _, text in ipairs({ detail, 'Install', 'https://github.com/vimkim/cubrid-language-tools',
    'https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.en.md', ':CubridRestart' }) do
    assert(note.message:find(text, 1, true), 'warning includes ' .. text .. ': ' .. note.message)
  end
  return note.message
end
local function complete()
  local response
  client():request('textDocument/completion', { textDocument = { uri = vim.uri_from_bufnr(0) },
    position = { line = 0, character = 3 } }, function(err, result)
    assert(not err, vim.inspect(err)); response = result
  end, 0)
  wait(function() return response ~= nil end, 'completion with missing native prerequisites')
  for _, item in ipairs(response.items or response) do if item.label:upper() == 'SELECT' then return end end
  error('keyword completion remains available')
end
vim.cmd('filetype plugin indent on')
local cubrid = require('cubrid')
-- A real server entry point in a fresh prefix has no source installation metadata.
local server = dir .. '/server/bin/cubrid-language-server'
vim.fn.mkdir(vim.fs.dirname(server), 'p')
vim.fn.writefile(vim.fn.readfile(original, 'b'), server, 'b')
vim.fn.setfperm(server, 'rwxr-xr-x')
local options = { auto_start = false, server_path = server }
if mode == 'configured' then
  options.parser_worker = dir .. '/native/parser-worker'
  options.runtime_prefix = dir .. '/runtime'
  options.worker_manifest = dir .. '/native/manifest.json'
  vim.fn.mkdir(dir .. '/native', 'p')
end
cubrid.setup(options)
vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/dependency.sql'))
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'SELect' })
vim.wait(100)
assert(#notes == 0 and not client(), 'auto_start=false leaves dependencies silent before activation')
vim.lsp.enable('cubrid')
wait(function() return client() end, 'real language server starts despite missing native prerequisites')
local message = warning(1, mode == 'configured' and options.parser_worker or 'direct_url.json')
assert(message:find('Strict syntax diagnostics are unavailable', 1, true)
  and message:find('keyword completion', 1, true), 'native warning states diagnostics and completion availability')
complete()
wait(function()
  for _, diagnostic in ipairs(vim.diagnostic.get(0)) do if diagnostic.code == 'CUBRID-T1001' then return true end end
end, 'server retains native availability diagnostics')
cubrid.setup(options)
vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/dependency-2.sql'))
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'SELect' })
vim.wait(400)
assert(#notes == 1, 'same settings and multiple buffers do not repeat the warning')
if mode == 'configured' then
  -- Non-executable workers are the same unresolved prerequisite.
  vim.fn.writefile({ '#!/bin/sh', 'exit 0' }, options.parser_worker)
  cubrid.setup(options)
  vim.wait(100)
  assert(#notes == 1, 'non-executable worker does not duplicate unchanged warning')
  vim.fn.setfperm(options.parser_worker, 'rwxr-xr-x')
  cubrid.setup(options)
  warning(2, 'manifest')
  vim.fn.writefile({ '{}' }, options.worker_manifest)
  cubrid.setup(options)
  warning(3, options.runtime_prefix)
  vim.fn.mkdir(options.runtime_prefix, 'p')
  cubrid.setup(options)
  vim.wait(100)
  assert(#notes == 3, 'available prerequisite paths produce no warning')
  vim.fn.delete(options.parser_worker)
  cubrid.setup(options)
  warning(4, options.parser_worker)
  complete()
end
vim.lsp.enable('cubrid', false)
wait(function() return #vim.lsp.get_clients({ name = 'cubrid' }) == 0 end, 'owned server stops')
vim.fn.writefile({ vim.json.encode(notes) }, dir .. '/dependency-notices.json')
print('PASS dependency warnings ' .. mode)
vim.cmd('qa!')
