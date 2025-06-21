-- Neovim Configuration
-- This is a sample configuration for demonstration purposes

-- Basic settings
vim.o.number = true
vim.o.relativenumber = true
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.smartindent = true
vim.o.wrap = false
vim.o.swapfile = false
vim.o.backup = false
vim.o.undofile = true
vim.o.hlsearch = false
vim.o.incsearch = true
vim.o.termguicolors = true
vim.o.scrolloff = 8
vim.o.signcolumn = "yes"
vim.o.updatetime = 50

-- Leader key
vim.g.mapleader = " "

-- Basic keymaps
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Open file explorer" })
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })

-- Example of a simple autocmd
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    -- Remove trailing whitespace on save
    vim.cmd([[%s/\s\+$//e]])
  end,
})

-- Simple status line
vim.o.statusline = "%f %h%m%r%=%-14.(%l,%c%V%) %P"

print("Configz Neovim configuration loaded!")
