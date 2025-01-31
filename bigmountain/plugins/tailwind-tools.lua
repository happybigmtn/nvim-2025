-- tailwind-tools.lua
return {
  "luckasRanarison/tailwind-tools.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    document_color = {
      enabled = true,
      inline = true,
    },
    conceal = {
      enabled = true,
      min_length = 3,
    },
  },
}
