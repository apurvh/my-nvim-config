# Intro

apurv's nvim config

created it after testing things with kickstart for 6 months

# how to setup in a new machine

1. backup existing ~/.config/nvim: `mv ~/.config/nvim ~/.config/nvim.backup`
2. clone this config: `git clone ..`

# Keymaps

#### Basics

```
jj or jf - exit insert mode
<leader> w - save
<leader> q - quite
vim motions such as ci", d}, yw, yyp
```

#### Search with telescope

```
<leader> sf - search file names
<leader> sg - grep search
<leader> sd - search diagnostics
<leader> sw - search current word
<leader><leader> - search open buffers (ordered by recent)
<leader> sr - resume last search
<leader> sa - search all files
<leader> st - search buffer symbols from treesitter
<leader> sj - search jump list
```

#### LSP keymaps

```
<leader> ld - go to def
<leader> la - open code actions
format-on-save
```

#### Navigation

```
s - flash jump
`C-o` back / `C-i` forward
/ to to search, n to jump, . to repeat
```

===============================
