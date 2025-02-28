return {
  "github/copilot.vim",
  lazy = false,
  config = function()
    -- First, we'll disable Copilot's default mappings to ensure our custom ones work correctly
    vim.g.copilot_no_tab_map = true
    vim.g.copilot_assume_mapped = true
    vim.g.copilot_tab_fallback = ""

    local keymap = vim.keymap

    -- Tab accepts the next word, giving you precise control over how much of the suggestion to take
    -- This is particularly useful when you want to carefully review and accept suggestions piece by piece
    keymap.set("i", "jf", "<Plug>(copilot-accept-word)", {
      desc = "Copilot accept next word",
    })

    -- Ctrl-Tab accepts the current line, letting you take more of the suggestion at once
    -- This strikes a balance between word-by-word and full acceptance
    keymap.set("i", "js", "<Plug>(copilot-accept-line)", {
      desc = "Copilot accept current line",
    })

    -- Ctrl-D accepts the entire suggestion, perfect for when you're confident in Copilot's recommendation
    -- This is useful for common patterns or boilerplate code you've verified is correct
    keymap.set("i", "jd", 'copilot#Accept("<CR>")', {
      expr = true,
      replace_keycodes = false,
      desc = "Copilot accept full suggestion",
    })

    -- Ctrl-S moves to the previous suggestion, letting you review alternative options
    -- This is helpful when the first suggestion isn't quite what you want
    keymap.set("i", "<C-d>", "<Plug>(copilot-previous)", {
      desc = "Copilot previous suggestion",
    })

    -- Ctrl-F moves to the next suggestion, continuing your exploration of alternatives
    -- Use this in combination with Ctrl-S to find the perfect suggestion
    keymap.set("i", "<C-f>", "<Plug>(copilot-next)", {
      desc = "Copilot next suggestion",
    })

    -- Ctrl-E dismisses the current suggestion when none of the options are what you want
    -- This lets you quickly clear unwanted suggestions and continue typing your own code
    keymap.set("i", "jl", "<Plug>(copilot-dismiss)", {
      desc = "Copilot dismiss suggestion",
    })

    -- Enable Copilot for all filetypes to ensure consistent behavior across your editing
    vim.g.copilot_filetypes = {
      ["*"] = true,
    }
  end,
}
