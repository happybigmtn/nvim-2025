return {
  "pmizio/typescript-tools.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  opts = {
    settings = {
      -- Enable auto updating of diagnostics
      publish_diagnostic_on = "change",
      -- Explicitly tell the server to watch files for changes
      watch_file = true,
      -- Set a shorter debounce time for faster updates
      file_change_timeout = 500,
    },
  },
}
