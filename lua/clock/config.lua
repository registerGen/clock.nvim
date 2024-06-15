local M = {}

local api = vim.api

---@class ClockFloatConfig
---@field border string
---@field col_offset integer
---@field padding integer[] left, right, top, bottom paddings, respectively
---@field position string
---@field row_offset integer
---@field zindex integer

---@class ClockModeConfig
---@field argc integer
---@field hl_group string | fun(c: string, time: string, position: integer, argv: table): string
---@field hl_group_pixel nil | fun(c: string, time: string, position: integer, pixel_row: integer, pixel_col: integer, argv: table): string
---@field hl_group_separator: string
---@field time_format fun(): string

---@class ClockConfig
---@field auto_start boolean
---@field float ClockFloatConfig
---@field font table<string, string[]>
---@field separator string
---@field modes ClockModeConfig[]
---@field update_time integer

---@type ClockConfig
local default = {
  auto_start = true,
  float = {
    border = "single",
    col_offset = 1,
    padding = { 1, 1, 0, 0 },
    position = "bottom",
    row_offset = 2,
    zindex = 40,
  },
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
  separator = "  ",
  modes = {
    default = {
      hl_group = function()
        return "NormalText"
      end,
      hl_group_pixel = nil,
      hl_group_separator = "NormalText",
      time_format = function()
        return os.date("%X")
      end,
    },
  },
  update_time = 500,
}

---@type ClockConfig
local config = default

local char_set = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":" }

---@return boolean
local function validate_time_formats()
  for _, v in pairs(config.modes) do
    local time = os.date(v.time_format())
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
  config = vim.tbl_deep_extend("force", default, user_config or {})

  local default = config.modes.default

  for k, _ in pairs(config.modes) do
    local mode = config.modes[k]

    if type(mode.hl_group) == "string" then
      local hl_group = mode.hl_group
      mode.hl_group = function()
        return hl_group
      end
    end

    mode.hl_group = mode.hl_group or default.hl_group
    -- hl_group_pixel should be ignored.
    mode.hl_group_separator = mode.hl_group_separator or default.hl_group_separator
    mode.time_format = mode.time_format or default.time_format
  end

  if config.float.position ~= "top" and config.float.position ~= "bottom" then
    api.nvim_err_writeln("config.ui.position should be either \"top\" or \"bottom\"")
    return false
  end

  if not validate_time_formats() then
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
