return {
  "barrett-ruth/live-server.nvim",
  build = "npm install -g live-server",
  config = function()
    require("live-server").setup({
      -- arguments passed to live-server upon startup
      args = {
        -- browser to use (default uses your system default)
        -- browser = "firefox",
        -- ignore these files/folders
        ignore = "node_modules,.git",
        -- start server in your project folder
        root = ".",
      },
    })

    -- Add a keymap to start the server
    vim.keymap.set("n", "<leader>ls", ":LiveServerStart<CR>", { desc = "Start live server" })
    vim.keymap.set("n", "<leader>lx", ":LiveServerStop<CR>", { desc = "Stop live server" })
  end,
}
