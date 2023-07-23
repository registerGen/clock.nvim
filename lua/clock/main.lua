local M = {}

local api = vim.api
local fn = vim.fn
local uv = vim.loop
---@type Config
local config = require("clock.config").get()

---@return string | osdate
local function get_time()
  local format = config.time_format
  return os.date(format)
end

---@return integer
local function get_font_row()
  local font = config.font
  return #font["0"]
end

-- Build the lines of the clock buffer.
---@param time string | osdate
---@return string[]
local function build_lines(time)
  if type(time) == "string" then
    local lines = {}
    local font, sep = config.font, config.separator
    local row = get_font_row()
    local len = time:len()

    for _ = 1, row, 1 do
      lines[#lines + 1] = ""
    end

    for i = 1, len, 1 do
      local c = time:sub(i, i)
      for j = 1, row, 1 do
        lines[j] = lines[j] .. font[c][j]
        if i ~= len then
          lines[j] = lines[j] .. sep
        end
      end
    end

    return lines
  end

  return {}
end

---@return integer clock buffer id
local function init_buffer(lines)
  local bufid = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(bufid, 0, -1, false, lines)
  return bufid
end

---@return nil
local function update_buffer(bufid, lines)
  api.nvim_buf_set_lines(bufid, 0, -1, false, lines)
end

---@return nil
local function delete_buffer(bufid)
  api.nvim_buf_delete(bufid, { force = true })
end

---@return integer clock window id
local function init_window(bufid)
  local lines = api.nvim_buf_get_lines(bufid, 0, -1, false)
  local width, height = fn.strdisplaywidth(lines[1]), #lines
  local columns = api.nvim_get_option_value("columns", {})
  local border = config.border
  local winid = api.nvim_open_win(bufid, false, {
    relative = "editor",
    anchor = "NE",
    row = 0,
    col = columns,
    width = width,
    height = height,
    border = border,
    style = "minimal",
  })
  return winid
end

---@return nil
local function delete_window(winid)
  api.nvim_win_close(winid, true)
end

local clock_running = false
local clock_timer, clock_bufid, clock_winid

---@return nil
function M.start()
  if clock_running then
    return
  end

  local lines = build_lines(get_time())
  clock_bufid = init_buffer(lines)
  clock_winid = init_window(clock_bufid)

  clock_timer = uv.new_timer()
  if not clock_timer then
    return
  end

  clock_timer:start(config.update_time, config.update_time, function()
    vim.schedule(function()
      lines = build_lines(get_time())
      update_buffer(clock_bufid, lines)
    end)
  end)

  clock_running = true
end

---@return nil
function M.stop()
  if not clock_running then
    return
  end

  clock_timer:stop()
  clock_timer:close()

  delete_window(clock_winid)
  delete_buffer(clock_bufid)

  clock_running = false
end

---@return nil
function M.toggle()
  if clock_running then
    M.stop()
  else
    M.start()
  end
end

return M
