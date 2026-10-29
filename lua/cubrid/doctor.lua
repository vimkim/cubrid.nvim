local M = {}

function M.run(resolved, session)
  local report = { ok = false, server = resolved.server, server_source = resolved.server_source,
    native = resolved.native, native_source = resolved.native_source, error = resolved.error,
    version = tostring(vim.version()), filetype = vim.bo.filetype,
    active = session.client and vim.lsp.get_client_by_id(session.client) and session.active or nil,
    diagnostics = vim.diagnostic.get(0), log = vim.lsp.log.get_filename() }
  local client = session.client and vim.lsp.get_client_by_id(session.client)
  if client then report.active_client = { id = client.id, name = client.name, initialized = client.initialized, phase = session.phase } end
  if report.active then report.active_differs = not vim.deep_equal(report.active, resolved) end
  if resolved.error then return report end
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, 'p')
  vim.fn.writefile({ '{}' }, root .. '/.cubrid-language.json')
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, root .. '/doctor.sql')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'SELECT ,;' })
  local settings = vim.deepcopy(resolved.settings)
  settings.schemaSnapshot = vim.NIL
  settings.configPath = nil
  settings.scriptMode = 'sql'
  settings.workerTimeout = math.min(settings.workerTimeout or 3, 3)
  local done, exited, seen = false, false, nil
  local started, id = pcall(vim.lsp.start, { name = 'cubrid-doctor', cmd = resolved.cmd or { resolved.server }, root_dir = root,
    exit_timeout = 500, get_language_id = function() return 'cubrid' end, init_options = { cubrid = settings },
    on_init = function(client) client:notify('workspace/didChangeConfiguration', { settings = { cubrid = settings } }) end,
    on_exit = function(code) exited = code; done = true end,
    handlers = { ['textDocument/publishDiagnostics'] = function(_, params)
      if params.uri ~= vim.uri_from_bufnr(buf) then return end
      for _, diagnostic in ipairs(params.diagnostics or {}) do
        if diagnostic.code == 'CUBRID-S1001' then seen = true
        elseif tostring(diagnostic.code or ''):match('^CUBRID%-') then seen = false; done = true; report.error = 'Probe diagnostic: ' .. tostring(diagnostic.code) .. ' ' .. (diagnostic.message or '') end
      end
      if seen and not report.error then done = true end
    end },
  }, { bufnr = buf, reuse_client = function() return false end })
  if not started or not id then report.error = 'Could not start language server: ' .. tostring(id or 'unknown error') .. '. Check the LSP log.'
  else
    vim.wait(10000, function() return done end, 20)
    if not done then report.error = 'Probe timed out. Check the LSP log.'
    elseif exited then report.error = 'Language server exited during probe with code ' .. tostring(exited) .. '. Check the LSP log.'
    elseif seen and not report.error then report.ok = true; report.probe = 'CUBRID-S1001' end
    local client = vim.lsp.get_client_by_id(id)
    if client then
      client:stop()
      if not vim.wait(1000, function() return not vim.lsp.get_client_by_id(id) end, 20) then
        client:stop(true)
        if not vim.wait(2000, function() return not vim.lsp.get_client_by_id(id) end, 20) then
          report.ok = false
          report.error = 'Doctor client did not exit. Check the LSP log.'
        end
      end
    end
  end
  if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
  vim.fn.delete(root, 'rf')
  return report
end
function M.format(report)
  local lines = { 'CUBRID doctor', 'Server (' .. report.server_source .. '): ' .. report.server,
    'Neovim: ' .. report.version, 'Filetype: ' .. (report.filetype ~= '' and report.filetype or '(none)'),
    'LSP log: ' .. report.log }
  if report.native then
    table.insert(lines, 'Native source: ' .. report.native_source)
    for _, key in ipairs({ 'parserWorker', 'runtimePrefix', 'workerManifest' }) do
      if report.native[key] then table.insert(lines, key .. ': ' .. report.native[key]) end
    end
  end
  table.insert(lines, report.active and ('Active CUBRID client ' .. report.active_client.id .. ' (' .. report.active_client.phase .. '): ' .. report.active.server) or 'Active CUBRID client: none')
  if report.active_differs then table.insert(lines, 'Active session differs from discovery. Run :CubridRestart.') end
  table.insert(lines, 'Current diagnostics: ' .. #report.diagnostics)
  for _, diagnostic in ipairs(report.diagnostics) do table.insert(lines, tostring(diagnostic.code or '') .. ' ' .. diagnostic.message) end
  table.insert(lines, report.ok and 'Native probe: CUBRID-S1001' or 'Doctor failed: ' .. (report.error or 'probe failed'))
  return table.concat(lines, '\n')
end
return M
