local dir = assert(vim.env.CUBRID_TEST_DIR)
local server = assert(vim.env.CUBRID_TEST_SERVER)
local function wait(predicate, message) assert(vim.wait(12000, predicate, 20), message) end
vim.cmd('filetype plugin indent on')
require('cubrid').setup({ server_path = server, auto_start = false })
vim.lsp.config('cubrid', {
  root_dir = function(buf, on_dir) on_dir(vim.fs.dirname(vim.api.nvim_buf_get_name(buf))) end,
})
vim.lsp.enable('cubrid')
local buffers = {}
for _, name in ipairs({ 'root-a', 'root-b' }) do
  vim.fn.mkdir(dir .. '/' .. name, 'p')
  vim.cmd('edit ' .. vim.fn.fnameescape(dir .. '/' .. name .. '/file.csql'))
  buffers[#buffers + 1] = vim.api.nvim_get_current_buf()
end
wait(function() return #vim.lsp.get_clients({ name = 'cubrid' }) == 2 end, 'custom roots intentionally create two clients')
local before = {}
for _, buf in ipairs(buffers) do
  local attached = vim.lsp.get_clients({ name = 'cubrid', bufnr = buf })
  assert(#attached == 1, 'each custom-root document has one client')
  assert(attached[1].config.root_dir == vim.fs.dirname(vim.api.nvim_buf_get_name(buf)), 'native root override reaches client')
  before[attached[1].id] = true
end
require('cubrid').restart()
wait(function()
  local current = vim.lsp.get_clients({ name = 'cubrid' })
  if #current ~= 2 then return false end
  for _, client in ipairs(current) do if before[client.id] then return false end end
  return true
end, 'restart replaces both native root clients')
vim.lsp.enable('cubrid', false)
wait(function() return #vim.lsp.get_clients({ name = 'cubrid' }) == 0 end, 'native disable cleans up both roots')
print('PASS custom native roots and restart')
vim.cmd('qa!')
