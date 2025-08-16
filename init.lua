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

-- ── Plugin manager: lazy.nvim (no plugins yet) ────────────────────────────────
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
  -- no plugins yet — keeping it truly minimal
}, {
  change_detection = { notify = false },
})
