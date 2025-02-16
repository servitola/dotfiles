local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.termguicolors = true
opt.showmode = false
opt.signcolumn = "yes"
opt.cursorline = true
opt.colorcolumn = "120"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.splitbelow = true
opt.splitright = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- Indentation
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.wrap = false

-- Files
opt.backup = false
opt.swapfile = false
opt.undofile = true
opt.fileencoding = "utf-8"

-- Completion
opt.completeopt = "menu,menuone,noselect"
opt.pumheight = 10

-- Performance
opt.updatetime = 250
opt.timeoutlen = 300

-- Misc
opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.conceallevel = 0
