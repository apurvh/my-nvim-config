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
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>",  { desc = "Quit" })

-- Minimal autocmds: highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank({ timeout = 120 }) end,
  desc = "Briefly highlight yanked text",
})

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
      { "<leader>sf", function() require("telescope.builtin").find_files() end, desc = "Search files" },
      { "<leader>sg", function() require("telescope.builtin").live_grep() end,  desc = "Grep in project" },
      { "<leader>sd", function() require("telescope.builtin").diagnostics() end, desc = "Search diagnostics" },
      { "<leader>sw", function() require("telescope.builtin").grep_string() end, desc = "Search word under cursor" },
      { "<leader><leader>", function()
        require("telescope.builtin").buffers({
          sort_mru = true,
          sort_lastused = true,
          ignore_current_buffer = true,
        })
      end,
        mode = "n",
        desc = "Buffers (MRU)"
      },
      { "<leader>sr", function() require("telescope.builtin").resume() end, desc = "Resume last Telescope" },
      { "<leader>sa", function() require("telescope.builtin").find_files({ hidden = true, no_ignore = true }) end, desc = "Find all files (hidden+ignored)" },
      { "<leader>st", function() require("telescope.builtin").treesitter() end, desc = "Buffer symbols (Treesitter)" },
      { "<leader>sj", function() require("telescope.builtin").jumplist() end, desc = "Jumplist" },
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
    build = "make",   -- or: build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release"
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
      auto_install = true,  -- install a parser automatically when you open a new filetype
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
        python = { "ruff_format" },

        -- Prettier family (daemon first, CLI fallback)
        json   = { "prettierd", "prettier" },
        jsonc  = { "prettierd", "prettier" },
        yaml   = { "prettierd", "prettier" },
        javascript         = { "prettierd", "prettier" },
        javascriptreact    = { "prettierd", "prettier" },
        typescript         = { "prettierd", "prettier" },
        typescriptreact    = { "prettierd", "prettier" },
        css                = { "prettierd", "prettier" },
        html               = { "prettierd", "prettier" },
        markdown           = { "prettierd", "prettier" },
        ["markdown.mdx"]   = { "prettierd", "prettier" }, -- if your ft is this; harmless if absent
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
  }

}, {
    change_detection = { notify = false },
  })
