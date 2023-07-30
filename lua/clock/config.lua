local M = {}

local api = vim.api

---@class ClockFloatConfig
---@field border string
---@field col_offset integer
---@field padding integer[] left, right, top, bottom paddings, respectively
---@field position string
---@field row_offset integer
---@field zindex integer

---@class ClockConfig
---@field auto_start boolean
---@field font table<string, string[]>
---@field hl_group fun(c: string, time: string, position: integer): string
---@field hl_group_pixel nil | fun(c: string, time: string, position: integer, pixel_row: integer, pixel_col: integer): string
---@field separator string
---@field time_format string
---@field update_time integer
---@field float ClockFloatConfig

---@type ClockConfig
local default = {
  auto_start = true,
  font = {
    ["0"] = {
      "██████",
      "██  ██",
      "██  ██",
      "██  ██",
      "██████",
    },
    ["1"] = {
      "████  ",
      "  ██  ",
      "  ██  ",
      "  ██  ",
      "██████",
    },
    ["2"] = {
      "██████",
      "    ██",
      "██████",
      "██    ",
      "██████",
    },
    ["3"] = {
      "██████",
      "    ██",
      "██████",
      "    ██",
      "██████",
    },
    ["4"] = {
      "██  ██",
      "██  ██",
      "██████",
      "    ██",
      "    ██",
    },
    ["5"] = {
      "██████",
      "██    ",
      "██████",
      "    ██",
      "██████",
    },
    ["6"] = {
      "██████",
      "██    ",
      "██████",
      "██  ██",
      "██████",
    },
    ["7"] = {
      "██████",
      "    ██",
      "    ██",
      "    ██",
      "    ██",
    },
    ["8"] = {
      "██████",
      "██  ██",
      "██████",
      "██  ██",
      "██████",
    },
    ["9"] = {
      "██████",
      "██  ██",
      "██████",
      "    ██",
      "██████",
    },
    [":"] = {
      "  ",
      "██",
      "  ",
      "██",
      "  ",
    },
  },
  hl_group = function()
    return "NormalText"
  end,
  hl_group_pixel = nil,
  separator = "  ",
  time_format = "%X",
  update_time = 500,
  float = {
    border = "single",
    col_offset = 1,
    padding = { 1, 1, 0, 0 },
    position = "top",
    row_offset = 2,
    zindex = 40,
  },
}

---@type ClockConfig
local config = default

local char_set = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":" }

---@return boolean
local function validate_time_format()
  local time = os.date(config.time_format)
  if type(time) ~= "string" then
    return false
  end

  for i = 1, time:len(), 1 do
    local c = time:sub(i, i)
    local found = false

    for _, v in pairs(char_set) do
      if c == v then
        found = true
        break
      end
    end

    if not found then
      api.nvim_err_writeln("formatted time should only contain digits or colons")
      return false
    end
  end

  return true
end

---@return boolean
local function validate_font()
  local font = config.font
  local rows = {}

  ---@param l integer[]
  ---@return boolean
  local function all_same(l)
    table.sort(l)
    return l[1] == l[#l]
  end

  for _, c in pairs(char_set) do
    if not font[c] then
      api.nvim_err_writeln(string.format("config.font[\"%s\"] should be accessible", c))
      return false
    end

    local cols = {}

    for _, line in pairs(font[c]) do
      cols[#cols + 1] = api.nvim_strwidth(line)
    end

    if not all_same(cols) then
      api.nvim_err_writeln(
        string.format("lengths of each row of config.font[\"%s\"] should be the same", c)
      )
      return false
    end

    rows[#rows + 1] = #font[c]
  end

  if not all_same(rows) then
    api.nvim_err_writeln("row numbers of each character of config.font should be the same")
    return false
  end

  return true
end

---@param user_config? ClockConfig
---@return boolean
M.set = function(user_config)
  user_config = user_config or {}
  config = vim.tbl_deep_extend("force", default, user_config)

  if config.float.position ~= "top" and config.float.position ~= "bottom" then
    api.nvim_err_writeln("config.ui.position should be either \"top\" or \"bottom\"")
    return false
  end

  if not validate_time_format() then
    return false
  end

  if not validate_font() then
    return false
  end

  return true
end

---@return ClockConfig
M.get = function()
  return config
end

return M
