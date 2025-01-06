return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-buffer", -- source for text in buffer
    "hrsh7th/cmp-path", -- source for file system paths
    {
      "L3MON4D3/LuaSnip",
      -- follow latest release.
      version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
      -- install jsregexp (optional!).
      build = "make install_jsregexp",
    },
    "saadparwaiz1/cmp_luasnip", -- for autocompletion
    "rafamadriz/friendly-snippets", -- useful snippets
    "onsails/lspkind.nvim", -- vs-code like pictograms
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local lspkind = require("lspkind")

    -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
    require("luasnip.loaders.from_vscode").lazy_load()

    cmp.setup({
      completion = {
        completeopt = "menu,menuone,preview,noselect",
        keyword_length = 3, -- This ensures completion only triggers after 3 characters
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
      -- sources for autocompletion with custom filter for Rust files
      sources = cmp.config.sources({
        {
          name = "nvim_lsp",
          entry_filter = function(entry, context)
            -- First check for Rust-specific completions we want to prevent
            if vim.bo.filetype == "rust" then
              local line_to_cursor = context.cursor_before_line
              -- Check for both "us" and "pu" at the end of the line
              if line_to_cursor:match("us$") or line_to_cursor:match("pu$") then
                return false
              end
            end

            -- Get the string being typed
            local line = context.cursor_before_line
            local current_word = line:match("%S+$") or ""

            -- Only show completions for words with 4 or more characters
            if #current_word < 4 then
              return false
            end

            return true
          end,
        },
        { name = "luasnip" },
        { name = "buffer" },
        { name = "path" },
      }), -- configure lspkind for vs-code like pictograms in completion menu
      formatting = {
        format = function(entry, item)
          -- First, apply the lspkind formatting you already have
          local formatted_item = lspkind.cmp_format({
            maxwidth = 50,
            ellipsis_char = "...",
          })(entry, item)

          -- Then apply the Tailwind colors if it's an LSP suggestion
          if entry.source.name == "nvim_lsp" then
            formatted_item = require("tailwindcss-colorizer-cmp").formatter(entry, formatted_item)
          end

          return formatted_item
        end,
      },
    })
  end,
}
