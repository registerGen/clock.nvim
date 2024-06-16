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

  api.nvim_create_user_command("ClockChangeMode", function(arg)
    local mode = arg.fargs[1]

    if not config.get().modes[mode] then
      api.nvim_err_writeln(string.format("mode %s does not exist", mode))
      return
    end

    local argc, argv = config.get().modes[mode].argc, { [0] = os.date("*t") }

    if #arg.fargs ~= 1 + argc then
      api.nvim_err_writeln(string.format("mode %s expects %d argument(s)", mode, argc))
      return
    end

    for i = 2, 1 + argc, 1 do
      argv[i - 1] = arg.fargs[i]
    end

    clock:change_mode({ mode, argv = argv })
  end, {
    nargs = "+",
  })

  if config.get().auto_start then
    clock:start()
  end
end

return M
