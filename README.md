# clock.nvim

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
