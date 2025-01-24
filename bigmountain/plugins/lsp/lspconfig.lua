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
    local lspconfig = require("lspconfig")
    local mason_lspconfig = require("mason-lspconfig")
    local cmp_nvim_lsp = require("cmp_nvim_lsp")
    local keymap = vim.keymap

    vim.lsp.set_log_level("ERROR")
    vim.g.markdown_fenced_languages = { "ts=typescript" }
    vim.g.eslint_d_enable_lsp = false

    vim.diagnostic.config({
      virtual_text = {
        source = "always",
        spacing = 4,
        prefix = "●",
        format = function(diagnostic)
          local severity_labels = {
            [vim.diagnostic.severity.ERROR] = "Error",
            [vim.diagnostic.severity.WARN] = "Warning",
            [vim.diagnostic.severity.INFO] = "Info",
            [vim.diagnostic.severity.HINT] = "Hint",
          }
          local label = severity_labels[diagnostic.severity]
          return string.format("%s: %s", label, diagnostic.message)
        end,
      },
      float = {
        source = "always",
        border = "rounded",
        header = "",
        prefix = "",
        format = function(diagnostic)
          local message = diagnostic.message
          local source = diagnostic.source
          local code = diagnostic.code or (diagnostic.user_data and diagnostic.user_data.lsp.code)

          local lines = {
            message,
            "",
            string.format("Source: %s", source or "unknown"),
          }

          if code then
            table.insert(lines, string.format("Code: %s", code))
          end

          local severity = ({
            [1] = "Error",
            [2] = "Warning",
            [3] = "Information",
            [4] = "Hint",
          })[diagnostic.severity]

          if severity then
            table.insert(lines, string.format("Severity: %s", severity))
          end

          return table.concat(lines, "\n")
        end,
      },
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
    })

    vim.o.hidden = true
    vim.o.updatetime = 300
    vim.o.timeoutlen = 500
    vim.lsp.start_client_timeout = 10000

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
        keymap.set("n", "gh", vim.lsp.buf.signature_help, opts)

        opts.desc = "Show line diagnostics"
        keymap.set("n", "gl", vim.diagnostic.open_float, opts)

        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

        keymap.set("n", "<C-w>l", "<C-w>l", { desc = "Focus right window" })
        keymap.set("n", "<C-w>h", "<C-w>h", { desc = "Focus left window" })

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
        keymap.set({ "n", "v" }, "<leader>ca", function()
          -- Get current diagnostics
          local diagnostics = vim.lsp.diagnostic.get_line_diagnostics()

          -- Define the context with diagnostics
          local context = {
            diagnostics = diagnostics,
            triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
          }

          -- For normal mode, we'll use a simpler approach that's more reliable
          if vim.fn.mode() == "n" then
            vim.lsp.buf.code_action({
              context = context,
            })
          else
            -- For visual mode, we need to handle the range
            local start_pos = vim.fn.getpos("'<")
            local end_pos = vim.fn.getpos("'>")

            -- Create the range object properly
            local range = {
              ["start"] = {
                line = start_pos[2] - 1,
                character = start_pos[3] - 1,
              },
              ["end"] = {
                line = end_pos[2] - 1,
                character = end_pos[3],
              },
            }

            vim.lsp.buf.code_action({
              range = range,
              context = context,
            })
          end
        end, opts)

        opts.desc = "Show references"
        keymap.set("n", "gr", vim.lsp.buf.references, opts)

        opts.desc = "Format buffer"
        keymap.set("n", "<leader>f", function()
          vim.lsp.buf.format({ async = true })
        end, opts)
      end,
    })

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

    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    for _, method in ipairs({ "textDocument/diagnostic", "workspace/diagnostic" }) do
      local default_handler = vim.lsp.handlers[method]
      vim.lsp.handlers[method] = function(err, result, ctx, cfg)
        if err and err.code == -32802 then
          return
        end
        return default_handler(err, result, ctx, cfg)
      end
    end

    mason_lspconfig.setup_handlers({
      ["rust_analyzer"] = function()
        lspconfig.rust_analyzer.setup({
          capabilities = capabilities,
          settings = {
            ["rust-analyzer"] = {
              cargo = {
                loadOutDirsFromCheck = true,
                runBuildScripts = true,
              },
              inlayHints = {
                enable = true,
                parameterHints = {
                  enable = true,
                  hideNamedArguments = false,
                },
                typeHints = {
                  enable = true,
                  hideClosureInitialization = false,
                  hideNamedConstructor = false,
                },
                returnTypeHints = { enable = true },
                bindingModeHints = { enable = true },
                expressionAdjustmentHints = {
                  enable = true,
                  mode = "prefix",
                },
                maxLength = 25,
              },
              hover = {
                enable = true,
                documentation = { enable = true, keywords = true },
                actions = { enable = true, group = true },
              },
              checkOnSave = {
                command = "clippy",
                extraArgs = { "--no-deps" },
                allFeatures = true,
              },
              procMacro = {
                enable = true,
                ignored = {
                  ["async-trait"] = { "async_trait" },
                  ["napi-derive"] = { "napi" },
                  ["async-recursion"] = { "async_recursion" },
                },
              },
              assist = {
                importGranularity = "module",
                importPrefix = "self",
                allowMergingIntoGlobImports = true,
              },
              diagnostics = {
                disabled = { "unresolved-proc-macro" },
                enableExperimental = true,
                experimental = { enable = true },
              },
              completion = {
                privateEditable = { enable = true },
                snippets = { custom = {} },
                postfix = {
                  enable = true,
                  ignoredPrefixes = { "pu", "us" },
                },
                callable = { snippets = "fill_arguments" },
                autoimport = { enable = true },
                autoself = { enable = true },
              },
              lens = {
                enable = true,
                debug = { enable = true },
                implementations = { enable = true },
                run = { enable = true },
                methodReferences = true,
                references = true,
              },
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
          flags = {
            debounce_text_changes = 150,
          },
        })
      end,

      ["graphql"] = function()
        lspconfig["graphql"].setup({
          capabilities = capabilities,
          flags = {
            debounce_text_changes = 150,
          },
          filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
        })
      end,

      ["emmet_ls"] = function()
        lspconfig["emmet_ls"].setup({
          capabilities = capabilities,
          flags = {
            debounce_text_changes = 150,
          },
          filetypes = {
            "html",
            "typescriptreact",
            "javascriptreact",
            "css",
            "sass",
            "scss",
            "less",
            "svelte",
          },
        })
      end,

      ["lua_ls"] = function()
        lspconfig["lua_ls"].setup({
          capabilities = capabilities,
          flags = {
            debounce_text_changes = 150,
          },
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" },
              },
              completion = {
                callSnippet = "Replace",
              },
              workspace = {
                checkThirdParty = false,
              },
              telemetry = {
                enable = false,
              },
            },
          },
        })
      end,

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
