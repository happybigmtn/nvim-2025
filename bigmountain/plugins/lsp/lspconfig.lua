-- Complete LSP configuration including all language servers and updated Tailwind support
return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
    {
      "pmizio/typescript-tools.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      opts = {},
    },
  },
  config = function()
    -- Import required modules
    local lspconfig = require("lspconfig")
    local mason_lspconfig = require("mason-lspconfig")
    local cmp_nvim_lsp = require("cmp_nvim_lsp")
    local util = require("lspconfig.util")
    local keymap = vim.keymap

    -- Basic LSP configurations
    vim.lsp.set_log_level("INFO")
    vim.g.markdown_fenced_languages = { "ts=typescript" }
    vim.g.eslint_d_enable_lsp = false

    -- Configure diagnostics display
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
      },
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
    })

    -- Set up LSP signs
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    -- Set up capabilities
    local capabilities = cmp_nvim_lsp.default_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    capabilities.textDocument.colorProvider = { dynamicRegistration = false }
    capabilities.textDocument.completion.completionItem.preselectSupport = true
    capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
    capabilities.textDocument.completion.completionItem.resolveSupport = {
      properties = {
        "documentation",
        "detail",
        "additionalTextEdits",
      },
    }

    -- Set up TypeScript tools
    require("typescript-tools").setup({
      capabilities = capabilities,
      settings = {
        tsserver_file_preferences = {
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      },
    })

    -- Configure Mason LSP handlers
    mason_lspconfig.setup_handlers({
      -- Default handler
      function(server_name)
        lspconfig[server_name].setup({
          capabilities = capabilities,
          flags = {
            debounce_text_changes = 150,
            allow_incremental_sync = true,
          },
        })
      end,

      -- Find the Solidity LSP handler section and update it like this
      ["solidity"] = function()
        -- Disable older solc-based server to prevent conflicts
        vim.cmd([[
    if exists('g:lspconfig_solc_setup')
      LspStop solc
      unlet g:lspconfig_solc_setup
    endif
  ]])

        -- Configure only the Nomicfoundation server
        lspconfig.solidity_ls.setup({
          capabilities = capabilities,
          cmd = { vim.fn.stdpath("data") .. "/mason/bin/nomicfoundation-solidity-language-server", "--stdio" },
          filetypes = { "solidity" },
          root_dir = util.root_pattern(
            "hardhat.config.js",
            "hardhat.config.ts",
            "foundry.toml",
            "remappings.txt",
            "truffle-config.js",
            "truffle.js",
            "package.json",
            ".git"
          ),
          single_file_support = true,
          settings = {
            -- Less aggressive settings to avoid parser errors
            solidity = {
              includePath = "",
              remapping = {},
              -- Set formatter to none to avoid LSP formatting
              formatter = "none",
              -- Other settings remain the same
              inlayHints = {
                enable = true,
                parameterNames = true,
                functionLikeReturnTypes = true,
                variableTypes = true,
              },
              -- Compiler validation settings
              compileUsingRemoteVersion = "0.8.19",
              defaultCompiler = "remote",
              compilerOptimization = 0,
              evmVersion = "paris",
            },
          },
          init_options = {
            hostInfo = "neovim",
            maxCompilationJobs = 1,
          },
          flags = {
            debounce_text_changes = 500, -- Increase debounce time
          },
          on_init = function(client)
            -- Explicitly disable document formatting to prevent interference with prettier
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false

            -- Notify the user
            vim.notify("Solidity LSP: Formatting provided by Prettier instead of Language Server", vim.log.levels.INFO)
          end,
        })
      end,
      -- Tailwind CSS configuration (updated for v4)
      ["tailwindcss"] = function()
        local project_root = vim.fn.getcwd()

        lspconfig.tailwindcss.setup({
          capabilities = capabilities,
          cmd = { vim.fn.stdpath("data") .. "/mason/bin/tailwindcss-language-server" },
          root_dir = function(fname)
            -- Log the current file and project root for debugging
            vim.notify("Tailwind LSP: Checking file: " .. fname)
            vim.notify("Tailwind LSP: Project root: " .. project_root)

            -- Try to detect root based on common project files
            local root = util.root_pattern(
              "package.json",
              "postcss.config.js",
              "postcss.config.ts",
              "tailwind.config.js",
              "tailwind.config.ts",
              "tsconfig.json",
              "jsconfig.json",
              "node_modules",
              ".git"
            )(fname)

            -- If no root found, fallback to the current working directory
            if not root then
              vim.notify(
                "Tailwind LSP: No root detected. Falling back to current working directory.",
                vim.log.levels.WARN
              )
              return project_root
            end

            vim.notify("Tailwind LSP: Root detected as: " .. root)
            return root
          end,
          settings = {
            tailwindCSS = {
              experimental = {
                classRegex = {
                  "className\\s*=\\s*[\"'{']([^\"'`}]*)[\"'}]",
                  "className\\s*=\\s*{`([^`]*)`}",
                  "tw`([^`]*)`",
                  "tw\\s*=\\s*[\"'{']([^\"'`}]*)[\"'}]",
                },
              },
              validate = true,
            },
          },
          filetypes = {
            "html",
            "css",
            "php",
            "blade",
            "twig",
            "vue",
            "heex",
            "astro",
            "eruby",
            "templ",
            "svelte",
            "elixir",
            "eelixir",
            "htmldjango",
            "javascript",
            "typescript",
            "javascriptreact",
            "typescriptreact",
            "rust",
          },
        })
      end,
      --
      -- Rust Analyzer configuration
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
          flags = { debounce_text_changes = 200 },
        })
      end,

      -- Svelte configuration
      ["svelte"] = function()
        lspconfig.svelte.setup({
          capabilities = capabilities,
          flags = { debounce_text_changes = 150 },
        })
      end,

      -- GraphQL configuration
      ["graphql"] = function()
        lspconfig.graphql.setup({
          capabilities = capabilities,
          flags = { debounce_text_changes = 150 },
          filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
        })
      end,

      -- Emmet configuration
      ["emmet_ls"] = function()
        lspconfig.emmet_ls.setup({
          capabilities = capabilities,
          flags = { debounce_text_changes = 150 },
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

      -- Lua configuration
      ["lua_ls"] = function()
        lspconfig.lua_ls.setup({
          capabilities = capabilities,
          flags = { debounce_text_changes = 150 },
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              completion = { callSnippet = "Replace" },
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        })
      end,
    })

    -- Set up keymaps when LSP attaches
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        local opts = { buffer = ev.buf, noremap = true, silent = true }

        keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        keymap.set("n", "K", vim.lsp.buf.hover, opts)
        keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)
        keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
        keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
        keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
        keymap.set("n", "<leader>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, opts)
        keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
        keymap.set("n", "gr", vim.lsp.buf.references, opts)
        keymap.set("n", "<leader>f", function()
          vim.lsp.buf.format({ async = true })
        end, opts)

        -- Diagnostic navigation
        keymap.set("n", "gl", vim.diagnostic.open_float, opts)
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
      end,
    })
  end,
}
