# clock.nvim

A simple, minimalist clock in neovim.

![Screenshot](https://github.com/registerGen/dotfiles/assets/62944333/cc2a10bf-8100-4f13-a557-d5f8003c8c04)

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
local default = {
  auto_start = true,
  font = {
    -- the "font" of the clock text
    -- see lua/clock/config.lua for details
  },
  separator = "  ", -- separator of two characters
  time_format = "%X",
  update_time = 500, -- update the clock text once per update_time
  float = {
    border = "single",
    col_offset = 1,
    padding = { 1, 1, 0, 0 }, -- left, right, top, bottom padding, respectively
    position = "top", -- or "bottom"
    row_offset = 1,
    zindex = 40,
  },
}
```

## Commands

```vim
" These do what you think they do.
:ClockStart
:ClockStop
:ClockToggle
```
