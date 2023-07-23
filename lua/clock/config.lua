local M = {}

local api = vim.api
local fn = vim.fn

---@class Config
---@field autostart boolean
---@field border string
---@field font table<string, string[]>
---@field separator string
---@field time_format string
---@field update_time integer

---@type Config
local default = {
  autostart = true,
  border = "rounded",
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
  time_format = "%X",
  update_time = 500,
}

---@type Config
local config = default

---@return nil
local function validate_font()
  local font = config.font
  local char_set = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":" }
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
    end

    local cols = {}

    for _, line in pairs(font[c]) do
      cols[#cols + 1] = fn.strdisplaywidth(line)
    end

    if not all_same(cols) then
      api.nvim_err_writeln(
        string.format("lengths of each row of config.font[\"%s\"] should be the same", c)
      )
    end

    rows[#rows + 1] = #font[c]
  end

  if not all_same(rows) then
    api.nvim_err_writeln("rows of each character of config.font should be the same")
  end
end

---@param user_config? Config
M.set = function(user_config)
  user_config = user_config or {}
  config = vim.tbl_deep_extend("force", default, user_config)
  validate_font()
end

---@return Config
M.get = function()
  return config
end

return M
