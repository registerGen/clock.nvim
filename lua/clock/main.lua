local api = vim.api
local uv = vim.uv
local ag = api.nvim_create_augroup("clock.nvim", { clear = true })
local ns = api.nvim_create_namespace("clock.nvim")

local config = require("clock.config").get() ---@type ClockConfig

---@param c string
---@return integer, integer # the row and column of font[c]
local function get_font_size(c)
  local font = config.font
  return #font[c], api.nvim_strwidth(font[c][1])
end

---@class Extmark
---@field line integer
---@field start_col integer
---@field end_col integer
---@field hl_group string

-- Build the lines and extmarks of the clock buffer.
---@param time string time represented in string
---@param mode string current mode
---@param mode_argv table current mode arguments
---@return string[], Extmark[] # lines and extmarks
local function build_lines_and_extmarks(time, mode, mode_argv)
  local LEFT, RIGHT, TOP, BOTTOM = 1, 2, 3, 4

  local lines = {} ---@type string[]
  local extmarks = {} ---@type Extmark[]
  local font, sep, pad = config.font, config.separator, config.modes[mode].float.padding
  local get_hl_group, get_hl_group_by_pixel =
    config.modes[mode].hl_group, config.modes[mode].hl_group_pixel
  local row, _ = get_font_size("0")
  local len = time:len()

  -- left padding
  for _ = 1, pad[TOP] + row + pad[BOTTOM], 1 do
    lines[#lines + 1] = (" "):rep(pad[LEFT])
  end

  for i = 1, len, 1 do
    local c = time:sub(i, i)
    local _, col = get_font_size(c)
    local hl_group = get_hl_group(time, i, mode_argv)

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
      local font_line = font[c][j - pad[TOP]]

      start_col = lines[j]:len()
      lines[j] = lines[j] .. font_line
      end_col = lines[j]:len()

      if not get_hl_group_by_pixel then
        extmarks[#extmarks + 1] = {
          line = j - 1,
          start_col = start_col,
          end_col = end_col,
          hl_group = hl_group,
        }
      else
        local positions = assert(vim.str_utf_pos(font_line))
        positions[#positions + 1] = font_line:len() + 1

        for k = 1, col, 1 do
          extmarks[#extmarks + 1] = {
            line = j - 1,
            start_col = positions[k] + start_col - 1,
            end_col = positions[k + 1] + start_col - 1,
            hl_group = get_hl_group_by_pixel(time, i, j - pad[TOP], k, mode_argv),
          }
        end
      end

      -- the separator
      if i ~= len then
        start_col = lines[j]:len()
        lines[j] = lines[j] .. sep
        end_col = lines[j]:len()

        extmarks[#extmarks + 1] = {
          line = j - 1,
          start_col = start_col,
          end_col = end_col,
          hl_group = config.modes[mode].hl_group_separator,
        }
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

-- Initialize clock buffer.
---@param lines string[] clock buffer content
---@param extmarks Extmark[] clock buffer extmarks
---@return integer # clock buffer id
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
  api.nvim_buf_clear_namespace(bufid, ns, 0, -1)

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
---@param mode string current mode
---@return integer # clock window id
local function init_window(bufid, mode)
  local float = config.modes[mode].float
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
  if not api.nvim_win_is_valid(winid) then
    return
  end

  api.nvim_win_close(winid, true)
end

-- Re-open clock window.
---@param bufid integer clock buffer id
---@param winid integer old clock window id
---@param mode string current mode
---@return integer # new clock window id
local function update_window(bufid, winid, mode)
  if not api.nvim_win_is_valid(winid) then
    return -1
  end

  delete_window(winid)
  return init_window(bufid, mode)
end

-- A clock.
---@class Clock
---
---@field running boolean
---@field timer uv_timer_t
---@field mode { [1]: string, argv: table }
---@field bufid integer
---@field winid integer
---
---@field init fun(self: Clock): Clock
---@field get_time fun(self: Clock): string
---@field start fun(self: Clock): nil
---@field stop fun(self: Clock): nil
---@field change_mode fun(self: Clock, mode: { [1]: string, argv: table }): nil
---@field toggle fun(self: Clock): nil
Clock = {}

function Clock:init()
  self.__index = self
  return setmetatable({
    running = false,
    timer = assert(uv.new_timer()),
    mode = { "default", argv = { [0] = os.date("*t") } },
    bufid = -1,
    winid = -1,
  }, self)
end

function Clock:get_time()
  local time_format = config.modes[self.mode[1]].time_format
  return time_format(self.mode.argv)
end

function Clock:start()
  if self.running then
    return
  end

  local lines, extmarks = build_lines_and_extmarks(self:get_time(), self.mode[1], self.mode.argv)
  self.bufid = init_buffer(lines, extmarks)
  self.winid = init_window(self.bufid, self.mode[1])

  self.timer:start(config.update_time, config.update_time, function()
    vim.schedule(function()
      lines, extmarks = build_lines_and_extmarks(self:get_time(), self.mode[1], self.mode.argv)
      update_buffer(self.bufid, lines, extmarks)
    end)
  end)

  api.nvim_create_autocmd("WinResized", {
    group = ag,
    callback = function()
      self.winid = update_window(self.bufid, self.winid, self.mode[1])
    end,
  })

  self.running = true
end

function Clock:stop()
  if not self.running then
    return
  end

  self.timer:stop()

  delete_window(self.winid)
  delete_buffer(self.bufid)

  self.running = false
end

function Clock:change_mode(mode)
  if not self.running then
    return
  end

  self.timer:stop()

  self.mode = mode

  local lines, extmarks = build_lines_and_extmarks(self:get_time(), self.mode[1], self.mode.argv)
  update_buffer(self.bufid, lines, extmarks)
  self.winid = update_window(self.bufid, self.winid, self.mode[1])

  self.timer:start(config.update_time, config.update_time, function()
    vim.schedule(function()
      lines, extmarks = build_lines_and_extmarks(self:get_time(), self.mode[1], self.mode.argv)
      update_buffer(self.bufid, lines, extmarks)
    end)
  end)
end

function Clock:toggle()
  if self.running then
    self:stop()
  else
    self:start()
  end
end

return Clock
