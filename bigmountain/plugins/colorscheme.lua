return {
  "folke/tokyonight.nvim",
  priority = 1000,
  config = function()
    local transparent = false -- set to true if you would like to enable transparency

    local bg = "#011628"
    local bg_dark = "#011423"
    local bg_highlight = "#143652"
    local bg_search = "#0A64AC"
    local bg_visual = "#275378"
    local fg = "#CBE0F0"
    local fg_dark = "#B4D0E9"
    local fg_gutter = "#627E97"
    local border = "#547998"
    local comment_fg = "#7AA2F7" -- Bright blue for comments

    require("tokyonight").setup({
      style = "night",
      transparent = transparent,
      styles = {
        sidebars = transparent and "transparent" or "dark",
        floats = transparent and "transparent" or "dark",
        comments = { italic = true }, -- Make comments italic
      },
      on_colors = function(colors)
        colors.bg = bg
        colors.bg_dark = transparent and colors.none or bg_dark
        colors.bg_float = transparent and colors.none or bg_dark
        colors.bg_highlight = bg_highlight
        colors.bg_popup = bg_dark
        colors.bg_search = bg_search
        colors.bg_sidebar = transparent and colors.none or bg_dark
        colors.bg_statusline = transparent and colors.none or bg_dark
        colors.bg_visual = bg_visual
        colors.border = border
        colors.fg = fg
        colors.fg_dark = fg_dark
        colors.fg_float = fg
        colors.fg_gutter = fg_gutter
        colors.fg_sidebar = fg_dark
        colors.comment = comment_fg -- Set comment color
      end,
      on_highlights = function(hl, c)
        -- Enhance comment visibility
        hl.Comment = {
          fg = comment_fg,
          italic = true,
        }
        -- Also enhance TSComment for treesitter
        hl.TSComment = {
          fg = comment_fg,
          italic = true,
          bold = true,
        }
        -- Make doc comments stand out even more
        hl.DocComment = {
          fg = "#89B4FA", -- Even brighter blue for doc comments
          italic = true,
          bold = true,
        }
      end,
    })

    vim.cmd("colorscheme tokyonight")
  end,
}
