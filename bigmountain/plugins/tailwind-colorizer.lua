return {
  "roobert/tailwindcss-colorizer-cmp.nvim",
  -- Load the plugin when you open a file
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("tailwindcss-colorizer-cmp").setup({
      color_square_width = 2, -- Width of the color square in the completion menu
    })
  end,
}
