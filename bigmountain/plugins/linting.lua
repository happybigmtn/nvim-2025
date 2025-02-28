return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    -- Configure pylint with better error handling
    lint.linters.pylint.args = {
      "--output-format=text",
      "--score=no",
      "--msg-template='{line}:{column}:{category}:{msg} ({symbol})'",
      "-d",
      "C0303", -- Trailing whitespace
      "-d",
      "C0304", -- Final newline missing
      "--max-line-length=120",
    }

    -- Add parser configuration
    lint.linters.pylint.parser = require("lint.parser").from_pattern(
      "([^:]+):(%d+):(%d+):(%w+):(.+) %(([^)]+)%)",
      { "file", "lnum", "col", "severity", "message", "code" },
      {
        ["convention"] = vim.diagnostic.severity.HINT,
        ["refactor"] = vim.diagnostic.severity.HINT,
        ["warning"] = vim.diagnostic.severity.WARN,
        ["error"] = vim.diagnostic.severity.ERROR,
        ["fatal"] = vim.diagnostic.severity.ERROR,
      }
    )

    lint.linters_by_ft = {
      python = { "pylint" },
    }

    -- Create autocommand group for linting
    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    -- Set up autocommand for running lint on file write
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    -- Set up keymap for manual linting
    vim.keymap.set("n", "<leader>l", function()
      lint.try_lint()
    end, { desc = "Trigger linting for current file" })
  end,
}
