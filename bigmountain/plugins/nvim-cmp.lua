return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-buffer", -- source for text in buffer
    "hrsh7th/cmp-path", -- source for file system paths
    {
      "L3MON4D3/LuaSnip",
      version = "v2.*",
      build = "make install_jsregexp",
    },
    "saadparwaiz1/cmp_luasnip", -- for autocompletion
    "rafamadriz/friendly-snippets", -- useful snippets
    "onsails/lspkind.nvim", -- vs-code like pictograms
    "roobert/tailwindcss-colorizer-cmp.nvim", -- tailwind colorizer
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local lspkind = require("lspkind")
    -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
    require("luasnip.loaders.from_vscode").lazy_load()

    cmp.setup({
      matching = {
        disallow_fuzzy_matching = true,
        disallow_partial_matching = true,
        disallow_prefix_unmatching = true,
      },
      completion = {
        completeopt = "menu,menuone,preview,noselect",
        keyword_length = 1, -- minimum number of characters for completion
      },
      snippet = { -- configure how nvim-cmp interacts with snippet engine
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
        ["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
        ["<C-e>"] = cmp.mapping.abort(), -- close completion window
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
      }),
      sources = cmp.config.sources({
        {
          name = "nvim_lsp",
          entry_filter = function(entry, ctx)
            local client = vim.lsp.get_client_by_id(entry.source.client_id)
            -- Always show Tailwind suggestions
            if client and client.name == "tailwindcss" then
              return true
            end
            return #ctx.cursor_before_line >= 3
          end,
        },
        { name = "luasnip", keyword_length = 3 }, -- snippets
        { name = "buffer", keyword_length = 3 }, -- text within current buffer
        { name = "path", keyword_length = 3 }, -- file system paths
      }),
      formatting = {
        format = function(entry, item)
          -- Tailwind CSS colorizer
          if entry.source.name == "nvim_lsp" then
            local client = entry.source.client_id and vim.lsp.get_client_by_id(entry.source.client_id)
            if client and client.name == "tailwindcss" then
              return require("tailwindcss-colorizer-cmp").formatter(entry, item)
            end
          end
          -- Regular formatting for non-Tailwind items
          return lspkind.cmp_format({
            maxwidth = 50,
            ellipsis_char = "...",
            menu = {
              nvim_lsp = "[LSP]",
              luasnip = "[SNIP]",
              buffer = "[BUF]",
              path = "[PATH]",
            },
          })(entry, item)
        end,
      },
      experimental = {
        ghost_text = false, -- disable ghost text
      },
    })

    -- Add this after the main cmp.setup
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "haskell" },
      callback = function()
        local cmp = require("cmp")
        -- Configure Tab to trigger completion for Haskell files
        local mappings = {
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { "i", "s" }),
        }
        cmp.setup.buffer({ mapping = mappings })
      end,
    })

    -- Tailwind specific completion settings
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "html", "javascriptreact", "typescriptreact", "svelte" },
      callback = function()
        cmp.setup.buffer({
          sources = cmp.config.sources({
            { name = "nvim_lsp", priority = 1000 },
            { name = "luasnip", priority = 750 },
            { name = "buffer", priority = 500 },
            { name = "path", priority = 250 },
          }),
        })
      end,
    })
  end,
}
