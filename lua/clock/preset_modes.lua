local M = {}

local api = vim.api

function M.rainbow()
  local r, g, b, colors = {}, {}, {}, {}

  for _, group_name in pairs({ "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Red" }) do
    local fg = api.nvim_get_hl(0, { name = group_name }).fg
    r[#r + 1] = bit.rshift(fg, 16)
    g[#g + 1] = bit.band(bit.rshift(fg, 8), 255)
    b[#b + 1] = bit.band(fg, 255)
  end

  for i = 1, 6, 1 do
    for j = 1, 9, 1 do
      local R, G, B
      R = math.floor(r[i] * (10 - j) / 9 + r[i + 1] * (j - 1) / 9 + 0.5)
      G = math.floor(g[i] * (10 - j) / 9 + g[i + 1] * (j - 1) / 9 + 0.5)
      B = math.floor(b[i] * (10 - j) / 9 + b[i + 1] * (j - 1) / 9 + 0.5)
      colors[#colors + 1] = string.format("#%X%X%X", R, G, B)
    end
  end

  for i = 1, 54, 1 do
    api.nvim_set_hl(0, "Clock" .. tostring(i), { fg = colors[i], bg = "bg" })
  end

  -- stylua: ignore start
  local hl_map = {
    [11] = 1,  [12] = 2,  [13] = 3,  [14] = 4,  [15] = 5,  [16] = 6,
    [21] = 9,  [22] = 10, [23] = 11, [24] = 12, [25] = 13, [26] = 14,
    [31] = 17, [32] = 18,
    [41] = 21, [42] = 22, [43] = 23, [44] = 24, [45] = 25, [46] = 26,
    [51] = 29, [52] = 30, [53] = 31, [54] = 32, [55] = 33, [56] = 34,
    [61] = 37, [62] = 38,
    [71] = 41, [72] = 42, [73] = 43, [74] = 44, [75] = 45, [76] = 46,
    [81] = 49, [82] = 50, [83] = 51, [84] = 52, [85] = 53, [86] = 54,
  }
  -- stylua: ignore end

  return {
    hl_group_pixel = function(_, _, position, _, pixel_col)
      return "Clock" .. tostring(hl_map[position * 10 + pixel_col])
    end,
    hl_group_separator = "Normal",
  }
end

return M
