local M = {}

local api = vim.api
local config = require("clock.config")

---@param user_config? ClockConfig
---@return nil
M.setup = function(user_config)
  if not config.set(user_config) then
    return
  end

  local clock = require("clock.main"):init()
  api.nvim_create_user_command("ClockStart", function()
    clock:start()
  end, {})
  api.nvim_create_user_command("ClockStop", function()
    clock:stop()
  end, {})
  api.nvim_create_user_command("ClockToggle", function()
    clock:toggle()
  end, {})

  api.nvim_create_user_command("ClockChangeMode", function(argv)
    local mode = argv.args

    if not config.get().modes[mode] then
      api.nvim_err_writeln(string.format("mode %s does not exist", mode))
      return
    end

    clock:change_mode(mode)
  end, {
    nargs = 1,
  })

  if config.get().auto_start then
    clock:start()
  end
end

return M
