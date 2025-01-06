return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
  },
  config = function()
    -- Import required modules
    local lspconfig = require("lspconfig")
    local mason_lspconfig = require("mason-lspconfig")
    local cmp_nvim_lsp = require("cmp_nvim_lsp")
    local keymap = vim.keymap

    -- Performance settings
    vim.lsp.set_log_level("ERROR")
    vim.g.markdown_fenced_languages = {
      "ts=typescript",
    }
    vim.g.eslint_d_enable_lsp = false
    vim.diagnostic.config({
      virtual_text = {
        source = "always",
        spacing = 4,
        format = function(diagnostic)
          if diagnostic.source == "eslint" then
            return nil
          end
          return diagnostic.message
        end,
      },
      float = {
        source = "always",
      },
      update_in_insert = false,
      severity_sort = true,
    })

    -- Buffer management settings
    vim.o.hidden = true
    vim.o.updatetime = 300
    vim.o.timeoutlen = 500
    vim.lsp.start_client_timeout = 10000

    -- LSP attach autocmd
    -- LSP attach autocmd
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        local opts = { buffer = ev.buf, silent = true }

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

        opts.desc = "Go to definition"
        keymap.set("n", "gd", vim.lsp.buf.definition, opts)

        opts.desc = "Show hover information"
        keymap.set("n", "K", vim.lsp.buf.hover, opts)

        opts.desc = "Go to implementation"
        keymap.set("n", "gi", vim.lsp.buf.implementation, opts)

        opts.desc = "Show signature help"
        keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)

        opts.desc = "Show signature help"
        keymap.set("n", "gh", vim.lsp.buf.signature_help, opts)

        opts.desc = "Add workspace folder"
        keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)

        opts.desc = "Remove workspace folder"
        keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)

        opts.desc = "List workspace folders"
        keymap.set("n", "<leader>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, opts)

        opts.desc = "Go to type definition"
        keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)

        opts.desc = "Rename symbol"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

        opts.desc = "Code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

        opts.desc = "Show references"
        keymap.set("n", "gr", vim.lsp.buf.references, opts)

        opts.desc = "Format buffer"
        keymap.set("n", "<leader>f", function()
          vim.lsp.buf.format({ async = true })
        end, opts)
      end,
    })

    -- Capabilities configuration
    local capabilities = cmp_nvim_lsp.default_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    capabilities.textDocument.completion.completionItem.preselectSupport = true
    capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
    capabilities.textDocument.completion.completionItem.resolveSupport = {
      properties = {
        "documentation",
        "detail",
        "additionalTextEdits",
      },
    }

    -- Diagnostic signs
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    -- Workaround for cancellation errors
    for _, method in ipairs({ "textDocument/diagnostic", "workspace/diagnostic" }) do
      local default_handler = vim.lsp.handlers[method]
      vim.lsp.handlers[method] = function(err, result, ctx, config)
        if err and err.code == -32802 then
          return
        end
        return default_handler(err, result, ctx, config)
      end
    end

    -- Set up language servers with enhanced stability settings
    mason_lspconfig.setup_handlers({
      -- Enhanced Rust Analyzer configuration with automatic type hints
      ["rust_analyzer"] = function()
        lspconfig.rust_analyzer.setup({
          capabilities = capabilities,
          settings = {
            ["rust-analyzer"] = {
              -- Existing cargo settings remain unchanged
              cargo = {
                loadOutDirsFromCheck = true,
                runBuildScripts = true,
              },
              -- Add inlay hints configuration for automatic type information
              inlayHints = {
                enable = true,
                -- Show parameter names in function calls
                parameterHints = {
                  enable = true,
                  hideNamedArguments = false,
                },
                -- Show inferred types for variables
                typeHints = {
                  enable = true,
                  hideClosureInitialization = false,
                  hideNamedConstructor = false,
                },
                -- Show hints for implicit return types
                returnTypeHints = {
                  enable = true,
                },
                -- Show hints about variable binding modes
                bindingModeHints = {
                  enable = true,
                },
                -- Show hints for implicit numeric conversions
                expressionAdjustmentHints = {
                  enable = true,
                  mode = "prefix",
                },
                -- Configure how the hints look
                maxLength = 25, -- Truncate long hints
              },
              -- Enhanced hover settings for more detailed information
              hover = {
                enable = true,
                documentation = {
                  enable = true,
                  keywords = true,
                },
                actions = {
                  enable = true,
                  group = true,
                },
              },
              -- Your existing checkOnSave settings remain unchanged
              checkOnSave = {
                command = "clippy",
                extraArgs = { "--no-deps" },
              },
              -- Your existing procMacro settings remain unchanged
              procMacro = {
                enable = true,
                ignored = {
                  ["async-trait"] = { "async_trait" },
                  ["napi-derive"] = { "napi" },
                  ["async-recursion"] = { "async_recursion" },
                },
              },
              -- Your existing diagnostics settings remain unchanged
              diagnostics = {
                disabled = { "unresolved-proc-macro" },
                enableExperimental = false,
              },
              -- Enhanced completion settings with postfix completion filtering
              completion = {
                privateEditable = {
                  enable = true,
                },
                snippets = {
                  custom = {},
                },
                postfix = {
                  enable = true,
                  ignoredPrefixes = { "pu", "us" },
                },
                -- Add parameter completion settings
                callable = {
                  snippets = "fill_arguments",
                },
              },
              -- Your existing experimental settings remain unchanged
              experimental = {
                procAttrMacros = true,
              },
            },
          },
          flags = {
            debounce_text_changes = 200,
          },
        })
      end,

      ["eslint"] = function() end,

      ["svelte"] = function()
        lspconfig["svelte"].setup({
          capabilities = capabilities,
        })
      end,

      ["graphql"] = function()
        lspconfig["graphql"].setup({
          capabilities = capabilities,
        })
      end,

      ["emmet_ls"] = function()
        lspconfig["emmet_ls"].setup({
          capabilities = capabilities,
        })
      end,

      ["lua_ls"] = function()
        lspconfig["lua_ls"].setup({
          capabilities = capabilities,
        })
      end,

      -- Default handler
      function(server_name)
        lspconfig[server_name].setup({
          capabilities = capabilities,
          flags = {
            debounce_text_changes = 150,
            allow_incremental_sync = true,
          },
          settings = {
            ["*"] = {
              workspace = {
                maxPreload = 10000,
                preloadMaxFileSize = 1000000,
              },
            },
          },
        })
      end,
    })
  end,
}
