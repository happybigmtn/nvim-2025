return {
  "NvChad/nvim-colorizer.lua",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("colorizer").setup({
      -- Enable colorizer for all filetypes
      "*",
      -- Configure specifically for Tailwind CSS
      css = {
        rgb_fn = true, -- Enable parsing rgb() functions
        hsl_fn = true, -- Enable parsing hsl() functions
        css = true, -- Enable parsing CSS variables
        css_fn = true, -- Enable parsing CSS functions
      },
      html = {
        mode = "background", -- Show colors as background
        tailwind = true, -- Enable tailwind colors
      },
      javascript = {
        mode = "background", -- Show colors as background
        tailwind = true, -- Enable tailwind colors
      },
      typescript = {
        mode = "background",
        tailwind = true,
      },
      javascriptreact = {
        mode = "background",
        tailwind = true,
      },
      typescriptreact = {
        mode = "background",
        tailwind = true,
      },
    })
  end,
}
