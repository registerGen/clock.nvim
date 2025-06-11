# clock.nvim

A simple, minimalist clock in neovim.

![Screenshot](https://github.com/registerGen/clock.nvim/assets/62944333/660f942a-cdd8-4232-9f1b-2844f4abe6d2)

The configuration can be found in the [gallery](https://github.com/registerGen/clock.nvim/wiki/Gallery).

## Installation & Setup

Install it as a typical neovim plugin and call the `setup()` function.

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
    position = "bottom", -- or "top"
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
  -- This function has higher priority than hl_group.
  hl_group_pixel = nil,
  separator = "  ", -- separator of two characters
  separator_hl = "NormalText",
  time_format = "%H:%M:%S",
  update_time = 500, -- update the clock text once per <update_time> (in ms)
}
```

## Commands

```vim
" These do what you think they do.
:ClockStart
:ClockStop
:ClockToggle
```
