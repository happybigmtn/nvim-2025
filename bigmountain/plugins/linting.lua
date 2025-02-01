return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    -- Configure pylint to ignore trailing whitespace messages
    lint.linters.pylint.args = {
      "-d",
      "C0303", -- Trailing whitespace
      "-d",
      "C0304", -- Final newline missing
      "--max-line-length=120",
    }

    lint.linters_by_ft = {
      -- Remove typescript/javascript entries
      python = { "pylint" },
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    vim.keymap.set("n", "<leader>l", function()
      lint.try_lint()
    end, { desc = "Trigger linting for current file" })
  end,
}
