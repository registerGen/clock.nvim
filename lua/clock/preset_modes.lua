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

  local hash = 0

  for i = 1, #hl_groups - 1, 1 do
    for j = 1, level, 1 do
      local R, G, B
      R = math.floor(r[i] * (level + 1 - j) / level + r[i + 1] * (j - 1) / level + 0.5)
      G = math.floor(g[i] * (level + 1 - j) / level + g[i + 1] * (j - 1) / level + 0.5)
      B = math.floor(b[i] * (level + 1 - j) / level + b[i + 1] * (j - 1) / level + 0.5)
      colors[#colors + 1] = string.format("#%X%X%X", R, G, B)
      hash = (((hash * 256 + R) * 256 + G) * 256 + B) % 998244353
    end
  end

  local prefix = "Clock_" .. tostring(hash) .. "_"

  for i = 1, (#hl_groups - 1) * level, 1 do
    api.nvim_set_hl(0, prefix .. tostring(i), { fg = colors[i], bg = "bg" })
  end

  return {
    hl_group_pixel = function(_, position, _, pixel_col)
      return prefix .. tostring(map(position, pixel_col))
    end,
    hl_group_separator = "Normal",
  }
end

---@param format fun(h: integer, m: integer, s: integer): string
function M.countup(format)
  return {
    time_format = function(argv)
      local t2 = os.date("*t") --[[@as osdate]]
      local t1 = argv[0] --[[@as osdate]]

      if t2.sec < t1.sec then
        t2.sec = t2.sec + 60
        t2.min = t2.min - 1
      end

      if t2.min < t1.min then
        t2.min = t2.min + 60
        t2.hour = t2.hour - 1
      end

      return format(t2.hour - t1.hour, t2.min - t1.min, t2.sec - t1.sec)
    end,
  }
end

return M
