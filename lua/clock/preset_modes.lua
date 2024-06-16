local M = {}

local api = vim.api

---@param hl_groups table<string>
---@param level integer
---@param map fun(position: integer, pixel_col: integer): integer
function M.gradient(hl_groups, level, map)
  local r, g, b, colors = {}, {}, {}, {}

  for _, group_name in pairs(hl_groups) do
    local fg = api.nvim_get_hl(0, { name = group_name }).fg --[[@as integer]]
    r[#r + 1] = bit.rshift(fg, 16)
    g[#g + 1] = bit.band(bit.rshift(fg, 8), 255)
    b[#b + 1] = bit.band(fg, 255)
  end

  for i = 1, #hl_groups - 1, 1 do
    for j = 1, level, 1 do
      local R, G, B
      R = math.floor(r[i] * (level + 1 - j) / level + r[i + 1] * (j - 1) / level + 0.5)
      G = math.floor(g[i] * (level + 1 - j) / level + g[i + 1] * (j - 1) / level + 0.5)
      B = math.floor(b[i] * (level + 1 - j) / level + b[i + 1] * (j - 1) / level + 0.5)
      colors[#colors + 1] = string.format("#%X%X%X", R, G, B)
    end
  end

  for i = 1, (#hl_groups - 1) * level, 1 do
    api.nvim_set_hl(0, "Clock" .. tostring(i), { fg = colors[i], bg = "bg" })
  end

  return {
    hl_group_pixel = function(_, position, _, pixel_col)
      return "Clock" .. tostring(map(position, pixel_col))
    end,
    hl_group_separator = "Normal",
  }
end

return M
