local M = {}

local function read_json(path, limit)
  local stat = vim.uv.fs_stat(path)
  if not stat or stat.type ~= 'file' or stat.size > limit then return nil end
  local fd = vim.uv.fs_open(path, 'r', 438)
  if not fd then return nil end
  local data = vim.uv.fs_read(fd, stat.size, 0)
  vim.uv.fs_close(fd)
  local ok, value = pcall(vim.json.decode, data or '')
  if ok and type(value) == 'table' then return value end
end

function M.resolve(config)
  local selected = vim.fn.exepath(config.server)
  local result = { server = selected ~= '' and (vim.uv.fs_realpath(selected) or selected) or config.server,
    server_source = config.server == 'cubrid-language-server' and 'PATH' or 'setup', settings = vim.deepcopy(config.settings) }
  if vim.fn.executable(result.server) ~= 1 then
    result.error = 'Language server is not executable. Install cubrid-language-server on PATH or set server_path.'
    return result
  end
  if result.settings.parserWorker then
    result.native = { parserWorker = result.settings.parserWorker, runtimePrefix = result.settings.runtimePrefix, workerManifest = result.settings.workerManifest }
    result.native_source = 'setup'
    return result
  end
  local prefix = vim.fn.fnamemodify(result.server, ':h:h')
  local paths, count = {}, 0
  local function entries(path)
    local ok, iterator = pcall(vim.fs.dir, path)
    if not ok then return function() end end
    return function()
      local name, kind = iterator()
      if name then count = count + 1 end
      if count > 2048 then return nil end
      return name, kind
    end
  end
  for python, kind in entries(prefix .. '/lib') do
    if kind == 'directory' and python:match('^python') then
      local site = prefix .. '/lib/' .. python .. '/site-packages'
      for dist, dist_kind in entries(site) do
        if dist_kind == 'directory' and dist:match('^cubrid_language_tools%-.*%.dist%-info$') then
          local path = site .. '/' .. dist .. '/direct_url.json'
          if vim.uv.fs_stat(path) then table.insert(paths, path) end
        end
      end
    end
  end
  if count > 2048 then result.error = 'Installation metadata scan exceeded its limit.'; return result end
  if #paths ~= 1 then
    result.error = 'Expected one installed cubrid-language-tools direct_url.json, found ' .. #paths .. '. Run just sync from the source checkout.'
    return result
  end
  local metadata = read_json(paths[1], 65536)
  local url = metadata and metadata.url
  if not metadata or (type(metadata.dir_info) ~= 'table' or vim.islist(metadata.dir_info)) or type(url) ~= 'string' or not url:match('^file:///') or url:gsub('%%(%x%x)', ''):find('%%') or url:find('[?#]') then
    result.error = 'Invalid local source URL in ' .. paths[1] .. '. Run just sync from the source checkout.'
    return result
  end
  local ok, source = pcall(vim.uri_to_fname, url)
  if not ok or source:sub(1, 1) ~= '/' or source:find('%z') or not vim.uv.fs_stat(source) or vim.uv.fs_stat(source).type ~= 'directory' then
    result.error = 'Installed source directory is missing or invalid: ' .. url .. '. Run just sync from the source checkout.'
    return result
  end
  local worker = source .. '/native/parser-worker/build/parser-worker'
  local manifest = source .. '/native/parser-worker/build/manifest.json'
  local info = read_json(manifest, 4 * 1024 * 1024)
  local runtime = info and info.runtimePrefix
  if vim.fn.executable(worker) ~= 1 then
    result.error = 'Native worker is missing or not executable: ' .. worker .. '. Build the native worker.'
    return result
  end
  if not info then
    result.error = 'Native manifest is missing or invalid: ' .. manifest .. '. Build the native worker.'
    return result
  end
  if type(runtime) ~= 'string' or runtime:sub(1, 1) ~= '/' or not vim.uv.fs_stat(runtime) or vim.uv.fs_stat(runtime).type ~= 'directory' then
    result.error = 'Native runtime is missing or invalid: ' .. tostring(runtime) .. '. Rebuild the worker with a valid runtime.'
    return result
  end
  result.native = { parserWorker = worker, workerManifest = manifest, runtimePrefix = runtime }
  result.native_source = paths[1]
  for key, value in pairs(result.native) do result.settings[key] = value end
  return result
end
return M
