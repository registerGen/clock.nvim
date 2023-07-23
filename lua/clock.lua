local M = {}

local api = vim.api
local config = require("clock.config")

---@param user_config? ClockConfig
M.setup = function(user_config)
  config.set(user_config)

  local clock = require("clock.main")
  api.nvim_create_user_command("ClockStart", function()
    clock.start()
  end, {})
  api.nvim_create_user_command("ClockStop", function()
    clock.stop()
  end, {})
  api.nvim_create_user_command("ClockToggle", function()
    clock.toggle()
  end, {})

  if config.get().auto_start then
    clock.start()
  end
end

return M
