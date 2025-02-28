vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt

opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

-- -- Python-specific settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    -- Ensure auto-indentation for Python is enabled
    vim.bo.autoindent = true
    vim.bo.smartindent = false
    vim.bo.cindent = false

    -- Set Python-specific indentation
    vim.bo.expandtab = true -- Use spaces instead of tabs
    vim.bo.tabstop = 4 -- A tab is 4 spaces
    vim.bo.shiftwidth = 4 -- Number of spaces for each step of indent
    vim.bo.softtabstop = 4 -- Backspace removes up to 4 spaces
  end,
})

opt.wrap = false

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

opt.cursorline = true

-- turn on termguicolors for tokyonight colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- turn off swapfile
opt.swapfile = false

-- Folding
vim.opt.foldmethod = "manual"
vim.opt.foldenable = true
vim.opt.foldlevel = 99

-- File type associations
vim.filetype.add({
  extension = {
    heex = "heex",
    exs = "elixir",
  },
})
