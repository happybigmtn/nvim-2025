return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    -- import mason
    local mason = require("mason")

    -- enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    -- Don't move these requires up - they need mason to be setup first
    local mason_lspconfig = require("mason-lspconfig")
    local mason_tool_installer = require("mason-tool-installer")

    mason_lspconfig.setup({
      ensure_installed = {
        "html",
        "cssls",
        "tailwindcss",
        "svelte",
        "lua_ls",
        "graphql",
        "emmet_ls",
        "prismals",
        "pyright",
      },
      automatic_installation = true,
      handlers = {
        ["tailwindcss"] = function()
          require("lspconfig").tailwindcss.setup({
            settings = {
              tailwindCSS = {
                classAttributes = { "class", "className", "ngClass" },
                validate = true,
                hovers = true,
                suggestions = true,
                experimental = {
                  classRegex = {
                    "tw`([^`]*)",
                    "tw\\.[^`]+`([^`]*)`",
                    "tw\\(.*?\\).*?`([^`]*)`",
                    'tw="([^"]*)"',
                  },
                },
              },
            },
          })
        end,
      },
    })

    mason_tool_installer.setup({
      ensure_installed = {
        "prettier", -- prettier formatter
        "stylua", -- lua formatter
        "isort", -- python formatter
        "black", -- python formatter
        "pylint",
      },
    })
  end,
}
