-- Leader first, then basic options
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Essentials: predictable editing, UI, and performance
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
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
}, {
  change_detection = { notify = false },
})
