-- Leader first, then basic options
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Essentials: predictable editing, UI, and performance
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 500
vim.opt.signcolumn = "yes"
vim.opt.clipboard = "unnamedplus"

-- Indentation defaults (we can adjust per-language later)
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

-- jj to exit insert mode
vim.keymap.set("i", "jj", "<Esc>", { desc = "Exit insert mode" })
vim.keymap.set("i", "jf", "<Esc>", { desc = "Exit insert mode" })

-- keep cursor centered when jumping/searching
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "J", "mzJ`z")

-- Clear search highlight with Esc in normal mode (does nothing else)
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Quality-of-life: save/quit bindings (optional, remove if you dislike)
vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })

-- Minimal autocmds: highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank({ timeout = 120 }) end,
  desc = "Briefly highlight yanked text",
})

-- Copy entire buffer → system clipboard
vim.keymap.set("n", "<leader>by", ":%y+<CR>", { desc = "Buffer → clipboard" })

-- Replace entire buffer from system clipboard (no yank pollution)
vim.keymap.set("n", "<leader>bp", function()
  local lines = vim.fn.getreg("+", 1, true)          -- list of lines from clipboard
  if type(lines) == "string" then lines = { lines } end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines) -- replace buffer in one undo step
end, { desc = "Clipboard → buffer (replace all)" })

-- Indent/outdent visual selections with Tab / Shift-Tab (great after you paste)
vim.keymap.set("x", "<Tab>", ">gv", { desc = "Indent selection and keep it selected" })
vim.keymap.set("x", "<S-Tab>", "<gv", { desc = "Outdent selection and keep it selected" })




-- inline diagnostics (end-of-line), no auto popups
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
})

-- Tree-sitter folds + default view = only top-level open
vim.opt.foldmethod     = "expr"
vim.opt.foldexpr       = "nvim_treesitter#foldexpr()"
vim.opt.foldenable     = true
vim.opt.foldlevelstart = 1   -- on file open: show only top-level
vim.opt.foldlevel      = 1   -- keep windows at level 1 unless you change it

vim.opt.foldcolumn     = "3" -- little gutter for folds
vim.opt.fillchars:append({ foldopen = "", foldclose = "", fold = " ", foldsep = " " })
vim.opt.foldtext = "v:lua.vim.treesitter.foldtext()"

vim.keymap.set("n", "<leader>o", "zA", { desc = "Fold: toggle recursively at cursor", silent = true })

do
  local hover_state = { win = nil }

  local function open_combined_float()
    local bufnr = vim.api.nvim_get_current_buf()
    local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1

    -- collect diagnostics for the line
    local lines = {}
    local diags = vim.diagnostic.get(bufnr, { lnum = lnum })
    if #diags > 0 then
      local sev = {
        [vim.diagnostic.severity.ERROR] = "Error",
        [vim.diagnostic.severity.WARN]  = "Warn",
        [vim.diagnostic.severity.INFO]  = "Info",
        [vim.diagnostic.severity.HINT]  = "Hint",
      }
      table.insert(lines, "## Diagnostics")
      for _, d in ipairs(diags) do
        local msg = (d.message or ""):gsub("\r?\n", " ")
        table.insert(lines, string.format("- **%s**: %s", sev[d.severity] or "Diag", msg))
      end
      table.insert(lines, "")
    end

    -- pick client & encoding (prevents position_encoding warning)
    local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients
    local client
    for _, c in ipairs(get_clients({ bufnr = bufnr })) do
      if c.supports_method and c:supports_method("textDocument/hover") then
        client = c; break
      end
      client = client or c
    end
    local encoding = (client and client.offset_encoding) or "utf-16"
    local params = vim.lsp.util.make_position_params(0, encoding)

    -- request hover and render
    vim.lsp.buf_request(bufnr, "textDocument/hover", params, function(err, result)
      local hover_lines
      if not err and result and result.contents then
        local md = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
        md = vim.split(table.concat(md, "\n"), "\n", { trimempty = true })
        if #md > 0 then hover_lines = md end
      end

      -- nothing to show? fall back to default hover
      if (not hover_lines) and vim.tbl_isempty(lines) then
        return vim.lsp.buf.hover()
      end

      if hover_lines then
        table.insert(lines, "## Hover")
        vim.list_extend(lines, hover_lines)
      end

      local fbuf, fwin = vim.lsp.util.open_floating_preview(
        lines, "markdown", { border = "rounded", focusable = true }
      )
      hover_state.win = fwin
      vim.api.nvim_set_current_win(fwin) -- focus so q/Esc work

      local function close_float()
        if hover_state.win and vim.api.nvim_win_is_valid(hover_state.win) then
          pcall(vim.api.nvim_win_close, hover_state.win, true)
        end
        hover_state.win = nil
      end

      for _, key in ipairs({ "q", "<Esc>" }) do
        vim.keymap.set("n", key, close_float, { buffer = fbuf, nowait = true, noremap = true, silent = true })
      end
    end)
  end

  -- K toggles combined diagnostics + hover
  vim.keymap.set("n", "K", function()
    if hover_state.win and vim.api.nvim_win_is_valid(hover_state.win) then
      pcall(vim.api.nvim_win_close, hover_state.win, true)
      hover_state.win = nil
    else
      open_combined_float()
    end
  end, { desc = "Diagnostics + LSP hover (toggle)" })
end



-- ── Plugin manager: lazy.nvim ───────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Telescope core
  {
    "nvim-telescope/telescope.nvim",
    version = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>sf", function() require("telescope.builtin").find_files() end,  desc = "Search files" },
      { "<leader>sg", function() require("telescope.builtin").live_grep() end,   desc = "Grep in project" },
      { "<leader>sd", function() require("telescope.builtin").diagnostics() end, desc = "Search diagnostics" },
      { "<leader>sw", function() require("telescope.builtin").grep_string() end, desc = "Search word under cursor" },
      {
        "<leader><leader>",
        function()
          require("telescope.builtin").buffers({
            sort_mru = true,
            sort_lastused = true,
            ignore_current_buffer = true,
          })
        end,
        mode = "n",
        desc = "Buffers (MRU)"
      },
      { "<leader>sr", function() require("telescope.builtin").resume() end,                                        desc = "Resume last Telescope" },
      { "<leader>sa", function() require("telescope.builtin").find_files({ hidden = true, no_ignore = true }) end, desc = "Find all files (hidden+ignored)" },
      { "<leader>st", function() require("telescope.builtin").treesitter() end,                                    desc = "Buffer symbols (Treesitter)" },
      { "<leader>sj", function() require("telescope.builtin").jumplist() end,                                      desc = "Jumplist" },
    },
    opts = {
      defaults = {
        sorting_strategy = "ascending",
        layout_config = { prompt_position = "top" },
      },
      pickers = {
        buffers = {
          sort_mru = true,
          sort_lastused = true,
          ignore_current_buffer = true,
        },
      },
    },
    config = function(_, opts)
      require("telescope").setup(opts)
      pcall(require("telescope").load_extension, "fzf") -- will load once built
    end,
  },

  -- Native FZF sorter (speed)
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make", -- or: build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release"
  },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    opts = {
      -- keep this tight; add more languages later as you need them
      ensure_installed = {
        "lua", "vim", "vimdoc", "query",
        "python",
        "bash", "json", "yaml", "toml",
        "markdown", "regex",
        "html", "css", "javascript", "typescript", "tsx",
      },
      auto_install = true, -- install a parser automatically when you open a new filetype
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      -- TS indent can be opinionated; disable for python to avoid surprises
      indent = { enable = true, disable = { "python" } },
    },
  },

  {
    "williamboman/mason.nvim",
    main = "mason",
    build = ":MasonUpdate",
    opts = {},
  },

  {
    "williamboman/mason-lspconfig.nvim",
    main = "mason-lspconfig",
    opts = {
      ensure_installed = { "lua_ls", "basedpyright", "ruff" },
    },
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      local has_tb, tb = pcall(require, "telescope.builtin")

      -- buffer-local maps for Python LSP buffers
      local function on_attach(_, bufnr)
        local map = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
        end
        -- defs via Telescope if present; fallback to raw LSP
        if has_tb then
          map("<leader>ld", tb.lsp_definitions, "Goto definition")
        else
          map("<leader>ld", vim.lsp.buf.definition, "Goto definition")
        end
        map("<leader>la", vim.lsp.buf.code_action, "Code actions")
      end

      -- Python type checker: basedpyright
      lspconfig.basedpyright.setup({
        on_attach = on_attach,
        settings = {
          basedpyright = {
            analysis = {
              diagnosticMode = "openFilesOnly",
              autoImportCompletions = true,
            },
          },
        },
      })

      -- Python lints/quick fixes: Ruff LSP
      lspconfig.ruff.setup({
        on_attach = function(client, bufnr)
          -- prefer basedpyright's hover if both attach
          client.server_capabilities.hoverProvider = false
          on_attach(client, bufnr)
        end,
        init_options = { settings = { logLevel = "error" } },
      })
    end,
  },

  {
    "stevearc/conform.nvim",
    opts = {
      notify_on_error = false,
      -- Pick explicit fast formatters where we know them; the rest will use LSP if available
      formatters_by_ft = {
        -- Python via Ruff
        python           = { "ruff_format" },

        -- Prettier family (daemon first, CLI fallback)
        json             = { "prettierd", "prettier" },
        jsonc            = { "prettierd", "prettier" },
        yaml             = { "prettierd", "prettier" },
        javascript       = { "prettierd", "prettier" },
        javascriptreact  = { "prettierd", "prettier" },
        typescript       = { "prettierd", "prettier" },
        typescriptreact  = { "prettierd", "prettier" },
        css              = { "prettierd", "prettier" },
        html             = { "prettierd", "prettier" },
        markdown         = { "prettierd", "prettier" },
        ["markdown.mdx"] = { "prettierd", "prettier" }, -- if your ft is this; harmless if absent
      },

      -- ✅ Enable for ALL filetypes
      -- Conform will try the ft-specific formatter first; if none, it will try LSP.
      -- If neither is available, nothing happens (no errors, no surprises).
      format_on_save = {
        timeout_ms = 1000,
        lsp_fallback = true,
      },
    },
    config = function(_, opts)
      -- Ensure Mason bin dir is on PATH so prettierd/ruff are found
      vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

      require("conform").setup(opts)
    end,
  },

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {}, -- default behavior is good; we can tweak later
    keys = {
      -- Jump anywhere by typing a few chars, then press the shown label
      { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash jump" },

      -- Treesitter-powered targets (functions, classes, params, blocks…)
      { "S",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },

      -- Operator-pending: run an operator at a remote location (e.g., `y r` then label)
      { "r",     mode = "o",               function() require("flash").remote() end,            desc = "Flash remote" },

      -- Treesitter search (great in operator/visual to select syntactic objects)
      { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Flash TS search" },

      -- Optional: use Flash inside `/` or `?` (toggle while typing the search)
      { "<C-s>", mode = "c",               function() require("flash").toggle() end,            desc = "Toggle Flash in search" },
    },
  },

  {
    "numToStr/Comment.nvim",
    -- only our <leader>/> mapping; do NOT add default gc/gb maps
    opts = { mappings = { basic = false, extra = false } },
    keys = {
      -- Normal mode: toggle comment on the current line
      {
        "<leader>/",
        function()
          require("Comment.api").toggle.linewise.current()
        end,
        desc = "Toggle comment (line)"
      },

      -- Visual mode: toggle comment on the selection
      {
        "<leader>/",
        function()
          local api = require("Comment.api")
          local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
          vim.api.nvim_feedkeys(esc, "nx", false)
          api.toggle.linewise(vim.fn.visualmode())
        end,
        mode = "x",
        desc = "Toggle comment (selection)"
      },
    },
  },

  -- Debug Adapter Protocol core
  {
    "mfussenegger/nvim-dap",
    keys = function()
      local dap = require("dap")
      local map = function(lhs, rhs, desc)
        return { lhs, rhs, desc = desc, mode = "n", silent = true }
      end
      return {
        map("<leader>xb", function() dap.toggle_breakpoint() end, "DAP: Toggle breakpoint"),
        map("<leader>xc", function() dap.continue() end, "DAP: Continue/Start"),
        map("<leader>xo", function() dap.step_over() end, "DAP: Step over"),
        map("<leader>xi", function() dap.step_into() end, "DAP: Step into"),
        map("<leader>xO", function() dap.step_out() end, "DAP: Step out"),
        map("<leader>xr", function() dap.repl.open() end, "DAP: REPL open"),
        map("<leader>xB", function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint Condition: "))
        end, "DAP: Conditional breakpoint"),
      }
    end,
    config = function()
      local uv  = vim.uv or vim.loop
      local sep = package.config:sub(1, 1)
      local dap = require("dap")

      -- Find project root by walking up for markers
      local function project_root()
        local buf = vim.api.nvim_buf_get_name(0)
        local dir = (buf ~= "" and vim.fn.fnamemodify(buf, ":p:h")) or uv.cwd()
        local markers = { "pyproject.toml", "setup.cfg", "setup.py", ".git" }
        while dir and dir ~= "/" do
          for _, m in ipairs(markers) do
            if uv.fs_stat(dir .. sep .. m) then return dir end
          end
          local parent = vim.fn.fnamemodify(dir, ":h")
          if parent == dir then break end
          dir = parent
        end
        return uv.cwd()
      end

      -- Dotted module from current buffer (for `python -m <module>`)
      local function current_module_name()
        local file = vim.api.nvim_buf_get_name(0)
        local root = project_root()
        if file:sub(1, #root) == root then file = file:sub(#root + 2) end
        local mod = file:gsub("%.py$", ""):gsub("[/\\]", ".")
        mod = mod:gsub("%.__init$", "")
        return mod
      end

      -- STRICT: use <root>/.venv only (no fallback)
      local function python_path()
        local root = project_root()
        local bin  = (uv.os_uname().sysname == "Windows_NT") and ("Scripts" .. sep .. "python.exe")
            or ("bin" .. sep .. "python")
        local p    = table.concat({ root, ".venv", bin }, sep)
        if uv.fs_stat(p) then return p end
        return nil
      end

      -- Lazy adapter: resolved only when a session starts
      dap.adapters.python = function(cb)
        local py = python_path()
        if not py then
          vim.schedule(function()
            vim.notify(
              "DAP: no <project>/.venv Python found.\nRun:\n  uv venv\n  uv add --dev debugpy && uv sync",
              vim.log.levels.ERROR
            )
          end)
          return
        end
        cb({ type = "executable", command = py, args = { "-m", "debugpy.adapter" } })
      end

      -- Only the "run as module" config (Option A)
      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Python: current file (module)",
          module = current_module_name, -- runs `python -m <module>`
          cwd = project_root,
          pythonPath = python_path,     -- pinned to <root>/.venv
          console = "integratedTerminal",
          justMyCode = false,
          -- Uncomment while debugging setup:
          -- stopOnEntry = true,
          env = { DEBUGPY_LOG_DIR = vim.fn.stdpath("state") .. "/debugpy-logs" },
        },
      }
    end,
  }
  ,

  -- DAP UI (nice sidebar + scopes, stacks, breakpoints)
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    opts = {},
    config = function(_, opts)
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup(opts)
      -- Auto open/close the UI when sessions start/stop
      dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
      -- dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
      -- dap.listeners.before.event_exited["dapui"]     = function() dapui.close() end
      -- Handy toggle
      vim.keymap.set("n", "<leader>xu", function() dapui.toggle() end, { desc = "DAP UI toggle" })
    end,
  },


}, {
  change_detection = { notify = false },
})
