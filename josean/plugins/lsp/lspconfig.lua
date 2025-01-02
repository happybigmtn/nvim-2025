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

    -- Optimize LSP performance settings
    vim.lsp.set_log_level("ERROR") -- Reduce logging overhead
    -- Explicitly disable eslint LSP
    vim.g.markdown_fenced_languages = {
      "ts=typescript",
    }
    vim.g.eslint_d_enable_lsp = false
    -- Single merged diagnostic config
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

    -- Improve buffer management and response times
    vim.o.hidden = true -- Allow switching buffers with unsaved changes
    vim.o.updatetime = 300 -- Faster update time for better responsiveness
    vim.o.timeoutlen = 500 -- Shorter timeout for mapped sequences

    -- Set a longer timeout for LSP client startup
    vim.lsp.start_client_timeout = 10000 -- 10 seconds

    -- Set up key LSP commands when a language server attaches to a buffer
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        -- Options for all keymaps
        local opts = { buffer = ev.buf, silent = true }

        -- Essential LSP navigation and information commands
        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

        opts.desc = "Go to definition"
        keymap.set("n", "gd", vim.lsp.buf.definition, opts)

        opts.desc = "Show LSP hover information"
        keymap.set("n", "K", vim.lsp.buf.hover, opts)

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", vim.lsp.buf.implementation, opts)

        opts.desc = "Show signature help"
        keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)

        -- Workspace management
        opts.desc = "Add workspace folder"
        keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)

        opts.desc = "Remove workspace folder"
        keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)

        opts.desc = "List workspace folders"
        keymap.set("n", "<leader>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, opts)

        -- Code navigation and refactoring
        opts.desc = "Show LSP references"
        keymap.set("n", "gr", vim.lsp.buf.references, opts)

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gD", vim.lsp.buf.type_definition, opts)

        opts.desc = "Rename symbol under cursor"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

        opts.desc = "Show code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

        -- Document formatting
        opts.desc = "Format buffer"
        keymap.set("n", "<leader>f", function()
          vim.lsp.buf.format({ async = true })
        end, opts)

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
      end,
    })

    -- Enhanced capabilities configuration for better completion experience
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

    -- Configure diagnostic signs for better visibility
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    -- Set up language servers with enhanced stability settings
    mason_lspconfig.setup_handlers({
      -- Disable eslint LSP
      ["eslint"] = function()
        -- Do nothing to prevent eslint LSP from starting
      end,

      -- Default handler for all language servers
      function(server_name)
        lspconfig[server_name].setup({
          capabilities = capabilities,
          flags = {
            debounce_text_changes = 150, -- Debounce rapid text changes
            allow_incremental_sync = true, -- Enable incremental document sync
          },
          settings = {
            -- Add default settings for improved stability
            ["*"] = {
              workspace = {
                maxPreload = 10000, -- Limit preloading to prevent memory issues
                preloadMaxFileSize = 1000000, -- Skip preloading large files
              },
            },
          },
        })
      end,

      -- Special configuration for svelte
      ["svelte"] = function()
        lspconfig["svelte"].setup({
          capabilities = capabilities,
          flags = {
            debounce_text_changes = 150,
          },
          on_attach = function(client, bufnr)
            vim.api.nvim_create_autocmd("BufWritePost", {
              pattern = { "*.js", "*.ts" },
              callback = function(ctx)
                client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
              end,
            })
          end,
        })
      end,

      -- GraphQL configuration with extended file type support
      ["graphql"] = function()
        lspconfig["graphql"].setup({
          capabilities = capabilities,
          flags = {
            debounce_text_changes = 150,
          },
          filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
        })
      end,

      -- Emmet language server configuration
      ["emmet_ls"] = function()
        lspconfig["emmet_ls"].setup({
          capabilities = capabilities,
          flags = {
            debounce_text_changes = 150,
          },
          filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
        })
      end,

      -- Lua language server with Neovim-specific settings
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
                checkThirdParty = false, -- Improve startup time
              },
              telemetry = {
                enable = false,
              },
            },
          },
        })
      end,
    })
  end,
}
