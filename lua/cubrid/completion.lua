local M = {}
local slots = {}
local epoch = 0
local omnifunc = "v:lua.require'cubrid.completion'.omnifunc"

local function notice(message)
  vim.schedule(function() vim.notify('cubrid completion: ' .. message, vim.log.levels.ERROR) end)
end

local function invalidate(slot)
  local ctx = slot.context
  slot.context = nil
  if ctx and ctx.phase == 'menu' then
    vim.schedule(function()
      if not slot.context and slot.generation == ctx.generation and vim.api.nvim_get_current_buf() == ctx.buf
        and vim.api.nvim_get_current_win() == ctx.win and vim.fn.pumvisible() == 1 then
        local items = vim.fn.complete_info({ 'items' }).items
        if #items == 0 then return end
        for _, item in ipairs(items) do
          local index = type(item.user_data) == 'string'
            and item.user_data:match(('^cubrid:%d:%d:(%%d+)$'):format(slot.epoch, ctx.generation))
          if not index or not ctx.choices[tonumber(index)] then return end
        end
        vim.api.nvim_input('<C-E>')
      end
    end)
  end
  if ctx and ctx.request_id then
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if client then client:cancel_request(ctx.request_id) end
  end
end

function M.prepare(buf)
  if not slots[buf] then
    epoch = epoch + 1
    slots[buf] = { previous = vim.bo[buf].omnifunc, epoch = epoch, generation = 0 }
  end
end

function M.detach(buf, client_id)
  local slot = slots[buf]
  if not slot or (client_id and slot.client_id ~= client_id) then return end
  invalidate(slot)
  slots[buf] = nil
  if vim.api.nvim_buf_is_valid(buf) then
    if vim.bo[buf].omnifunc == omnifunc then vim.bo[buf].omnifunc = slot.previous end
    if slot.group then pcall(vim.api.nvim_del_augroup_by_id, slot.group) end
  end
end

local function valid_client(ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  return client and not client:is_stopped() and client.attached_buffers[ctx.buf]
end

local function byteindex(line, encoding, index)
  if type(index) ~= 'number' or index < 0 or index % 1 ~= 0 then return end
  local ok, byte = pcall(vim.str_byteindex, line, encoding, index, true)
  if not ok then return end
  local valid, roundtrip = pcall(vim.str_utfindex, line, encoding, byte, true)
  if valid and roundtrip == index then return byte end
end

local function choices(ctx, result)
  if type(result) ~= 'table' or result.itemDefaults then return nil, 'unsupported completion response' end
  local items = result.items or result
  if type(items) ~= 'table' or not vim.islist(items) then return nil, 'unsupported completion list' end
  local parsed, first = {}, ctx.cursor
  for _, item in ipairs(items) do
    if type(item) ~= 'table' then return nil, 'unsupported completion item' end
    local edit = item.textEdit
    local range = type(edit) == 'table' and edit.range
    if type(item.label) ~= 'string' or (item.detail ~= nil and type(item.detail) ~= 'string')
      or type(range) ~= 'table' or type(range.start) ~= 'table'
      or type(range['end']) ~= 'table' or type(edit.newText) ~= 'string'
      or edit.newText:find('[\r\n]') or edit.insert or edit.replace
      or (item.insertTextFormat ~= nil and item.insertTextFormat ~= 1) or item.insertTextMode
      or item.additionalTextEdits or item.command or item.data or item.textEditText then
      return nil, 'unsupported completion item ' .. tostring(item.label)
    end
    if range.start.line ~= ctx.row or range['end'].line ~= ctx.row then
      return nil, 'unsupported multiline completion item ' .. item.label
    end
    local start = byteindex(ctx.line, ctx.encoding, range.start.character)
    local finish = byteindex(ctx.line, ctx.encoding, range['end'].character)
    if not start or not finish or start > ctx.cursor or finish < ctx.cursor or finish < start then
      return nil, 'invalid completion range for ' .. item.label
    end
    first = math.min(first, start)
    parsed[#parsed + 1] = { start = start, finish = finish, text = edit.newText, label = item.label, detail = item.detail }
  end
  return parsed, first
end

local function present(slot, ctx, err, result)
  if slot.context ~= ctx then return end
  ctx.request_id = nil
  if err then slot.context = nil; notice('request failed: ' .. vim.inspect(err)); return end
  if not valid_client(ctx) or vim.api.nvim_get_current_buf() ~= ctx.buf
    or vim.api.nvim_get_current_win() ~= ctx.win or vim.fn.mode():sub(1, 1) ~= 'i'
    or vim.api.nvim_buf_get_changedtick(ctx.buf) ~= ctx.tick
    or not vim.deep_equal(vim.api.nvim_win_get_cursor(ctx.win), { ctx.row + 1, ctx.cursor }) then
    slot.context = nil
    return
  end
  local items, start = choices(ctx, result)
  if not items then slot.context = nil; notice(start); return end
  if #items == 0 then slot.context = nil; return end
  ctx.phase, ctx.choices, ctx.start = 'menu', items, start
  local menu = {}
  for i, choice in ipairs(items) do
    choice.word = ctx.line:sub(start + 1, choice.start) .. choice.text
    menu[i] = { word = choice.word, abbr = choice.label, menu = choice.detail or '', dup = 1,
      user_data = ('cubrid:%d:%d:%d'):format(slot.epoch, ctx.generation, i) }
  end
  vim.fn.complete(start + 1, menu)
end

function M.omnifunc(findstart, _)
  if findstart ~= 1 then return {} end
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  local slot = slots[buf]
  if not slot or not slot.client_id then return -2 end
  invalidate(slot)
  local client = vim.lsp.get_client_by_id(slot.client_id)
  if not client or not client.attached_buffers[buf] then return -2 end
  slot.generation = slot.generation + 1
  local cursor = vim.api.nvim_win_get_cursor(win)
  local ctx = { buf = buf, win = win, client_id = client.id, generation = slot.generation,
    row = cursor[1] - 1, cursor = cursor[2], line = vim.api.nvim_get_current_line(),
    tick = vim.api.nvim_buf_get_changedtick(buf), encoding = client.offset_encoding, phase = 'pending' }
  slot.context = ctx
  local params = vim.lsp.util.make_position_params(win, ctx.encoding)
  params.context = { triggerKind = 1 }
  local sent, request_id = client:request('textDocument/completion', params, function(err, result)
    present(slot, ctx, err, result)
  end, buf)
  if not sent then slot.context = nil; notice('could not request completion') else ctx.request_id = request_id end
  return -2
end

local function done(buf)
  local slot = slots[buf]
  local ctx = slot and slot.context
  if not ctx or ctx.phase ~= 'menu' then return end
  local event = vim.v.event
  local item = vim.v.completed_item
  if event.complete_type ~= 'eval' then return end
  if event.reason ~= 'accept' then invalidate(slot); return end
  local id = type(item.user_data) == 'string' and item.user_data:match('^cubrid:(%d+:%d+:%d+)$')
  local selected
  for i, choice in ipairs(ctx.choices) do
    if id == ('%d:%d:%d'):format(slot.epoch, ctx.generation, i) then selected = choice; break end
  end
  slot.context = nil
  if not selected or not valid_client(ctx) or vim.api.nvim_get_current_buf() ~= buf
    or vim.api.nvim_get_current_win() ~= ctx.win then notice('stale completion was not applied'); return end
  local expected = ctx.line:sub(1, ctx.start) .. selected.word .. ctx.line:sub(ctx.cursor + 1)
  local col = ctx.start + #selected.word
  if vim.api.nvim_get_current_line() ~= expected
    or not vim.deep_equal(vim.api.nvim_win_get_cursor(ctx.win), { ctx.row + 1, col }) then
    notice('stale completion was not applied'); return
  end
  if selected.finish > ctx.cursor then
    local ok = pcall(vim.cmd, 'undojoin')
    if not ok then notice('could not join completion undo'); return end
    vim.api.nvim_buf_set_text(buf, ctx.row, col, ctx.row, col + selected.finish - ctx.cursor, { '' })
    vim.api.nvim_win_set_cursor(ctx.win, { ctx.row + 1, col })
  end
end

function M.attach(buf, client)
  M.prepare(buf)
  local slot = slots[buf]
  slot.client_id = client.id
  vim.bo[buf].omnifunc = omnifunc
  slot.group = vim.api.nvim_create_augroup('cubrid_completion_' .. buf, { clear = true })
  vim.api.nvim_create_autocmd('CompleteDone', { group = slot.group, buffer = buf, callback = function() done(buf) end })
  vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufLeave' }, { group = slot.group, buffer = buf, callback = function() invalidate(slot) end })
  vim.api.nvim_buf_attach(buf, false, { on_lines = function(_, _, _, first, last, new_last)
    if slots[buf] ~= slot then return true end
    local ctx = slot.context
    if ctx and ctx.phase == 'menu' and (first ~= ctx.row or last ~= ctx.row + 1 or new_last ~= ctx.row + 1) then
      invalidate(slot)
      notice('completion cancelled after the buffer changed')
    end
  end, on_detach = function() if slots[buf] == slot then M.detach(buf, client.id) end end })
end

return M
