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
<leader> ld - go to definition
<leader> la - code actions
K           - diagnostics + LSP hover (toggle)
format-on-save (via Conform/LSP)
```

#### Navigation

```
s - flash jump
`C-o` back / `C-i` forward
/ to to search, n to jump, . to repeat
zz - center the current line in the window
<leader> - - open yazi
<leader> a - show code structure
<leader> j - search and jump to symbols
<leader> k - search and jump to jumplist
```

#### Copy and paste

```
<leader> by - copy all text in current buffer
<leader> bp - replace current buffer with clipboard
p] p[ - paste in the current indent level
```

#### Info

```
K - preview diagnostics and LSP info
```

#### Testing (neotest)

```
<leader> tn - run nearest test
<leader> tj - run file
<leader> tl - run last
<leader> ts - toggle summary
<leader> to - toggle output panel
<leader> td - debug nearest (sets a breakpoint at cursor first)
<leader> tx - stop tests
```

#### Debugging (DAP)

```
<leader> b  - toggle breakpoint

Debug flow:
- Press <leader> td at the test line to start a debug session; a breakpoint is set at the cursor so execution pauses immediately.
- DAP UI auto-opens on start and closes on stop.
- Use the DAP UI buttons to Continue / Step Over / Step Into / Step Out / Stop (no extra n/i/o/c mappings).
```

#### Others

```
<leader> o - Fold: toggle recursively at cursor
<leader> / - comment/uncomment
```
