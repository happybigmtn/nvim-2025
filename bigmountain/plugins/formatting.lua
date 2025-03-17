return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require("conform")

    conform.setup({
      formatters = {
        black = {
          prepend_args = { "--fast", "--line-length=120" },
        },
        isort = {
          prepend_args = { "--profile", "black" },
        },
        -- Configure prettier to recognize Solidity files
        prettier = {
          -- These are the default arguments, but we're explicitly setting them
          -- to demonstrate how to add the solidity plugin config
          args = {
            "--stdin-filepath",
            "$FILENAME",
            "--plugin=prettier-plugin-solidity",
          },
          -- Add solidity to the list of file types prettier handles
          env = {
            PRETTIER_PLUGIN_RESOLVERS = "node_modules",
          },
        },
      },
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        svelte = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        liquid = { "prettier" },
        lua = { "stylua" },
        python = { "isort", "black" },
        -- Use prettier for Solidity!
        solidity = { "prettier" },
      },
      format_on_save = {
        -- Continue to exclude solidity from automatic LSP formatting
        -- but let prettier handle it explicitly
        lsp_fallback = true,
        timeout_ms = 5000,
      },
    })

    -- Manual formatting (keep this as-is)
    vim.keymap.set({ "n", "v" }, "<leader>mp", function()
      conform.format({
        lsp_fallback = true,
        async = true,
        timeout_ms = 5000,
      })
    end, { desc = "Format file or range (in visual mode)" })

    -- Ensure the Solidity LSP doesn't try to format
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "solidity",
      callback = function()
        -- Register a specific buffer-local command for Solidity formatting
        vim.api.nvim_buf_create_user_command(0, "FormatSolidity", function()
          conform.format({
            bufnr = 0,
            formatters = { "prettier" },
            async = true,
            timeout_ms = 5000,
          })
        end, { desc = "Format Solidity file with Prettier" })
      end,
    })
  end,
}
