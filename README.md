# commentary.nvim
Neovim plugin to comment out/in a text written in lua. Support comment out a single line, a visual selection and a motion.

[![screenshot.gif](https://s9.gifyu.com/images/screenshot.gif)](https://gifyu.com/image/GiVm)

## Getting started

### Requirements
- Neovim 0.5+

#### Packer

```lua
use 'shoukoo/commentary.nvim'
```

#### Vim-Plug
```viml
Plug 'shoukoo/commentary.nvim'
```

### Setup

### Use the default mappings
The default keybindings are the same as in vim-commentary, meaning your can use the following keybindings
- `gcc` to comment out a single line, 
- `gc` to comment out a visual selection 
- `gc<motion>` to commentout with a motion i.e. `gc5j`

#### Disable the default mappings
If you don't like the default mappings, set `use_default_mappings` to false in init.lua/vimrc
```
require("commentary").setup({
  use_default_mappings = false 
})
```

#### Customise your mappings
You can also bind your own keys. Insert the following lines into your `init.lua` and replace `<your key>` with the valid keys.

```lua
vim.api.nvim_set_keymap("x", "<your key>", "<Plug>commentary", { silent = true })
vim.api.nvim_set_keymap("n", "<your key>", "<Plug>commentary", { silent = true })
vim.api.nvim_set_keymap("n", "<your key>", "<Plug>commentary_motion", { silent = true })
```

### Add additional languages
Currently, this plugin only supports a few languages, feel free to create a PR and add them in [here](lua/commentary/config.lua#L9). Otherwise, you can also pass them into the setup function like this:


```lua
require("commentary").setup({languages= 
  {
    go = {single_line_comment =  "//", multiline_comment = {"/*", "*/"}, prefer_multiline = true}
    typescript = {single_line_comment =  "//", multiline_comment = {"/**", "*/"}, prefer_mutiline = true}
  }
})
```

