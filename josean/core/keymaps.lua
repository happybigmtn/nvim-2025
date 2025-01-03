vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab
keymap.set("n", "<leader>ti", ":TSToolsFileReferences<CR>", opts, { desc = "Find File References" })
keymap.set("n", "<leader>th", ":TSToolsRemoveUnused<CR>", opts, { desc = "Remove Unused" })
keymap.set("n", "<leader>tg", ":TSToolsGoToSourceDefinition<CR>", opts, { desc = "Go To Source" })
keymap.set("n", "<leader>tp", ":TSToolsAddMissingImports<CR>", opts, { desc = "Add Missing Imports" })
keymap.set("n", "<leader>ca", function()
  require("tiny-code-action").code_action()
end, { noremap = true, silent = true })

-- Select all text in buffer (similar to Cmd-A or Ctrl-A)
keymap.set("n", "<leader>sa", "ggVG", { desc = "Select all text in buffer" })

-- Delete to blackhole register mappings
-- In normal mode, delete current line to blackhole register
keymap.set("n", "<leader>dd", '"_dd', { desc = "Delete current line to blackhole register" })
-- In visual mode, delete selection to blackhole register
keymap.set("v", "<leader>d", '"_d', { desc = "Delete selection to blackhole register" })

-- Move lines up and down
-- To:
keymap.set("n", "<leader><leader>j", ":m .+1<CR>==", { desc = "Move line down" })
keymap.set("n", "<leader><leader>k", ":m .-2<CR>==", { desc = "Move line up" })
keymap.set("n", "<leader><leader>h", "xhP", { desc = "Move character left" })
keymap.set("n", "<leader><leader>l", "xp", { desc = "Move character right" })
keymap.set("v", "<leader><leader>j", ":m .+1<CR>==", { desc = "Move line down" })
keymap.set("v", "<leader><leader>k", ":m .-2<CR>==", { desc = "Move line up" })
keymap.set("v", "<leader><leader>h", "xhP", { desc = "Move character left" })
keymap.set("v", "<leader><leader>l", "xp", { desc = "Move character right" })

-- 'x' for original 's' behavior (delete character and enter insert)
keymap.set("n", "x", "s", { desc = "Delete char and insert" })

-- 'X' for original 'S' behavior (delete line and enter insert)
keymap.set("n", "X", "S", { desc = "Delete line and insert" })
