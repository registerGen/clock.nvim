local M = {}

local api = vim.api
local fn = vim.fn
local uv = vim.loop
local augroup = api.nvim_create_augroup("clock.nvim", { clear = true })

local config = require("clock.config").get() ---@type ClockConfig

---@return string | osdate
local function get_time()
  local format = config.time_format
  return os.date(format)
end

---@param c string
---@return integer[] (row, col) of font[c]
local function get_font_size(c)
  local font = config.font
  return { #font[c], fn.strdisplaywidth(font[c][1]) }
end

-- Build the lines of the clock buffer.
---@param time string | osdate time represented in string
---@return string[]
local function build_lines(time)
  if type(time) == "string" then
    local LEFT, RIGHT, TOP, BOTTOM = 1, 2, 3, 4

    local lines = {}
    local font, sep, pad = config.font, config.separator, config.ui.padding
    local row = get_font_size("0")[1]
    local len = time:len()

    for _ = 1, pad[TOP] + row + pad[BOTTOM], 1 do
      lines[#lines + 1] = (" "):rep(pad[LEFT])
    end

    for i = 1, len, 1 do
      local c = time:sub(i, i)
      local col = get_font_size(c)[2]

      for j = 1, pad[TOP], 1 do
        lines[j] = lines[j] .. (" "):rep(col)
        if i ~= len then
          lines[j] = lines[j] .. sep
        end
      end

      for j = pad[TOP] + 1, pad[TOP] + row, 1 do
        lines[j] = lines[j] .. font[c][j - pad[TOP]]
        if i ~= len then
          lines[j] = lines[j] .. sep
        end
      end

      for j = pad[TOP] + row + 1, pad[TOP] + row + pad[BOTTOM], 1 do
        lines[j] = lines[j] .. (" "):rep(col)
        if i ~= len then
          lines[j] = lines[j] .. sep
        end
      end
    end

    for i = 1, pad[TOP] + row + pad[BOTTOM], 1 do
      lines[i] = lines[i] .. (" "):rep(pad[RIGHT])
    end

    return lines
  end

  return {}
end

-- Initialize clock buffer.
---@param lines string[] clock buffer content
---@return integer clock buffer id
local function init_buffer(lines)
  local bufid = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(bufid, 0, -1, false, lines)
  return bufid
end

-- Update clock buffer.
---@param bufid integer clock buffer id
---@param lines string[] new clock buffer content
---@return nil
local function update_buffer(bufid, lines)
  api.nvim_buf_set_lines(bufid, 0, -1, false, lines)
end

-- Delete clock buffer.
---@param bufid integer clock buffer id
---@return nil
local function delete_buffer(bufid)
  api.nvim_buf_delete(bufid, { force = true })
end

-- Initialize clock window.
---@param bufid integer clock buffer id
---@return integer clock window id
local function init_window(bufid)
  local ui = config.ui
  local lines = api.nvim_buf_get_lines(bufid, 0, -1, false)
  local width, height = fn.strdisplaywidth(lines[1]), #lines
  local rows, columns =
    api.nvim_get_option_value("lines", {}), api.nvim_get_option_value("columns", {})
  local winid = api.nvim_open_win(bufid, false, {
    relative = "editor",
    anchor = ui.position == "top" and "NE" or "SE",
    row = ui.position == "top" and ui.row_offset or rows - ui.row_offset,
    col = columns - ui.col_offset,
    width = width,
    height = height,
    border = ui.border,
    style = "minimal",
    zindex = ui.zindex,
  })
  return winid
end

-- Delete clock window.
---@param winid integer clock window id
---@return nil
local function delete_window(winid)
  api.nvim_win_close(winid, true)
end

-- Re-open clock window.
---@param bufid integer clock buffer id
---@param winid integer old clock window id
---@return integer new clock window id
local function update_window(bufid, winid)
  delete_window(winid)
  return init_window(bufid)
end

local clock_running = false ---@type boolean
local clock_timer ---@type uv_timer_t
local clock_bufid ---@type integer
local clock_winid ---@type integer

---@return nil
function M.start()
  if clock_running then
    return
  end

  local lines = build_lines(get_time())
  clock_bufid = init_buffer(lines)
  clock_winid = init_window(clock_bufid)

  clock_timer = assert(uv.new_timer())
  clock_timer:start(config.update_time, config.update_time, function()
    vim.schedule(function()
      lines = build_lines(get_time())
      update_buffer(clock_bufid, lines)
    end)
  end)

  api.nvim_create_autocmd("WinResized", {
    group = augroup,
    callback = function()
      clock_winid = update_window(clock_bufid, clock_winid)
    end,
  })

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
