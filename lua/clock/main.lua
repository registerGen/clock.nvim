local M = {}

local api = vim.api
local uv = vim.loop
local ag = api.nvim_create_augroup("clock.nvim", { clear = true })
local ns = api.nvim_create_namespace("clock.nvim")

local config = require("clock.config").get() ---@type ClockConfig

---@return string | osdate
local function get_time()
  local format = config.time_format
  return os.date(format)
end

---@param c string
---@return integer, integer the row and column of font[c]
local function get_font_size(c)
  local font = config.font
  return #font[c], api.nvim_strwidth(font[c][1])
end

-- Build the lines and extmarks of the clock buffer.
---@class Extmark
---@field line integer
---@field start_col integer
---@field end_col integer
---@field hl_group string
---
---@param time string | osdate time represented in string
---@return string[], Extmark[] lines and extmarks
local function build_lines_and_extmarks(time)
  if type(time) == "string" then
    local LEFT, RIGHT, TOP, BOTTOM = 1, 2, 3, 4

    local lines = {} ---@type string[]
    local extmarks = {} ---@type Extmark[]
    local font, sep, pad = config.font, config.separator, config.float.padding
    local get_hl_group = config.hl_group
    local row, _ = get_font_size("0")
    local len = time:len()

    -- left padding
    for _ = 1, pad[TOP] + row + pad[BOTTOM], 1 do
      lines[#lines + 1] = (" "):rep(pad[LEFT])
    end

    for i = 1, len, 1 do
      local c = time:sub(i, i)
      local _, col = get_font_size(c)
      local hl_group = get_hl_group(c, time, i)

      -- top padding
      for j = 1, pad[TOP], 1 do
        lines[j] = lines[j] .. (" "):rep(col)
        if i ~= len then
          lines[j] = lines[j] .. sep
        end
      end

      -- the character
      for j = pad[TOP] + 1, pad[TOP] + row, 1 do
        local start_col, end_col

        start_col = lines[j]:len()
        lines[j] = lines[j] .. font[c][j - pad[TOP]]
        end_col = lines[j]:len()

        extmarks[#extmarks + 1] = {
          line = j - 1,
          start_col = start_col,
          end_col = end_col,
          hl_group = hl_group,
        }

        if i ~= len then
          lines[j] = lines[j] .. sep
        end
      end

      -- bottom padding
      for j = pad[TOP] + row + 1, pad[TOP] + row + pad[BOTTOM], 1 do
        lines[j] = lines[j] .. (" "):rep(col)
        if i ~= len then
          lines[j] = lines[j] .. sep
        end
      end
    end

    -- right padding
    for i = 1, pad[TOP] + row + pad[BOTTOM], 1 do
      lines[i] = lines[i] .. (" "):rep(pad[RIGHT])
    end

    return lines, extmarks
  end

  return {}, {}
end

-- Initialize clock buffer.
---@param lines string[] clock buffer content
---@param extmarks Extmark[] clock buffer extmarks
---@return integer clock buffer id
local function init_buffer(lines, extmarks)
  local bufid = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(bufid, 0, -1, false, lines)

  for _, extmark in pairs(extmarks) do
    api.nvim_buf_add_highlight(
      bufid,
      ns,
      extmark.hl_group,
      extmark.line,
      extmark.start_col,
      extmark.end_col
    )
  end

  return bufid
end

-- Update clock buffer.
---@param bufid integer clock buffer id
---@param lines string[] new clock buffer content
---@param extmarks Extmark[] new clock buffer extmarks
---@return nil
local function update_buffer(bufid, lines, extmarks)
  api.nvim_buf_set_lines(bufid, 0, -1, false, lines)

  for _, extmark in pairs(extmarks) do
    api.nvim_buf_add_highlight(
      bufid,
      ns,
      extmark.hl_group,
      extmark.line,
      extmark.start_col,
      extmark.end_col
    )
  end
end

-- Delete clock buffer.
---@param bufid integer clock buffer id
---@return nil
local function delete_buffer(bufid)
  api.nvim_buf_clear_namespace(bufid, ns, 0, -1)
  api.nvim_buf_delete(bufid, { force = true })
end

-- Initialize clock window.
---@param bufid integer clock buffer id
---@return integer clock window id
local function init_window(bufid)
  local float = config.float
  local lines = api.nvim_buf_get_lines(bufid, 0, -1, false)
  local width, height = api.nvim_strwidth(lines[1]), #lines
  local rows, columns =
    api.nvim_get_option_value("lines", {}), api.nvim_get_option_value("columns", {})

  local winid = api.nvim_open_win(bufid, false, {
    relative = "editor",
    anchor = float.position == "top" and "NE" or "SE",
    row = float.position == "top" and float.row_offset or rows - float.row_offset,
    col = columns - float.col_offset,
    width = width,
    height = height,
    border = float.border,
    style = "minimal",
    zindex = float.zindex,
    focusable = false,
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

  local lines, extmarks = build_lines_and_extmarks(get_time())
  clock_bufid = init_buffer(lines, extmarks)
  clock_winid = init_window(clock_bufid)

  clock_timer = assert(uv.new_timer())
  clock_timer:start(config.update_time, config.update_time, function()
    vim.schedule(function()
      lines, extmarks = build_lines_and_extmarks(get_time())
      update_buffer(clock_bufid, lines, extmarks)
    end)
  end)

  api.nvim_create_autocmd("WinResized", {
    group = ag,
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
