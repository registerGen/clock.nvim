# clock.nvim

![lint](https://github.com/registerGen/clock.nvim/workflows/lint/badge.svg)
![code size](https://img.shields.io/github/languages/code-size/registerGen/clock.nvim)
![lines of code](https://tokei.rs/b1/github/registerGen/clock.nvim?type=Lua&category=code)

A simple, minimalist clock in neovim.

![Screenshot](https://github.com/registerGen/clock.nvim/assets/62944333/26326fa9-bd27-4f30-a6d1-8c943b136fea)

(You can see the configuration [here](https://github.com/registerGen/dotfiles/blob/master/nvim/lua/plugincfg/clock.lua).)

## Installation & Setup

Install it as a normal neovim plugin and call the `setup()` function.

```lua
require("clock").setup()
-- or
require("clock").setup({
  -- your configuration here
})
```

## Configuration

The default configuration and the documentation are shown below.

```lua
{
  auto_start = true,
  float = {
    border = "single",
    col_offset = 1,
    padding = { 1, 1, 0, 0 }, -- left, right, top, bottom padding, respectively
    position = "top", -- or "bottom"
    row_offset = 2,
    zindex = 40,
  },
  font = {
    -- the "font" of the clock text
    -- see lua/clock/config.lua for details
  },
  -- fun(c: string, time: string, position: integer): string
  -- <c> is the character to be highlighted
  -- <time> is the time represented in a string
  -- <position> is the position of <c> in <time>
  hl_group = function(c, time, position)
    return "NormalText"
  end,
  -- nil | fun(c: string, time: string, position: integer, pixel_row: integer, pixel_col: integer): string
  -- This function has higher priority.
  hl_group_pixel = nil,
  separator = "  ", -- separator of two characters
  time_format = "%X",
  update_time = 500, -- update the clock text once per update_time
}
```

## Commands

```vim
" These do what you think they do.
:ClockStart
:ClockStop
:ClockToggle
```
