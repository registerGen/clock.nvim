local M = {}

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

---@param user_config? Config
M.set = function(user_config)
  user_config = user_config or {}
  config = vim.tbl_deep_extend("force", default, user_config)
end

---@return Config
M.get = function()
  return config
end

return M
