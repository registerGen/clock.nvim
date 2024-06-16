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
---@field float ClockFloatConfig
---@field hl_group string | fun(c: string, time: string, position: integer, argv: table): string
---@field hl_group_pixel nil | fun(c: string, time: string, position: integer, pixel_row: integer, pixel_col: integer, argv: table): string
---@field hl_group_separator: string
---@field time_format fun(): string

---@class ClockConfig
---@field auto_start boolean
---@field font table<string, string[]>
---@field separator string
---@field modes ClockModeConfig[]
---@field update_time integer

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
  separator = "  ",
  modes = {
    default = {
      float = {
        border = "single",
        col_offset = 1,
        padding = { 1, 1, 0, 0 },
        position = "bottom",
        row_offset = 2,
        zindex = 40,
      },
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

  for k, v in pairs(config.modes) do
    if type(v.hl_group) == "string" then
      local hl_group = v.hl_group
      v.hl_group = function()
        return hl_group
      end
    end

    -- hl_group_pixel should override the default even if it is nil.
    local hl_group_pixel = v.hl_group_pixel
    config.modes[k] = vim.tbl_deep_extend("force", default, v)
    config.modes[k].hl_group_pixel = hl_group_pixel
  end

  for _, v in pairs(config.modes) do
    if v.float.position ~= "top" and v.float.position ~= "bottom" then
      api.nvim_err_writeln("config.modes[mode].float.position should be either \"top\" or \"bottom\"")
      return false
    end
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
