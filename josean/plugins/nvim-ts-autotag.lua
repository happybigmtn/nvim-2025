return {
  "windwp/nvim-ts-autotag",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("nvim-ts-autotag").setup({
      opts = {
        enable_close = true, -- Enable auto-closing tags
        enable_rename = true, -- Enable auto-renaming paired tags
        enable_close_on_slash = true, -- Enable auto-closing when typing /
      },
      -- You can add filetype-specific configurations if needed
      per_filetype = {
        -- For example, if you want to disable any feature for a specific filetype:
        -- ["html"] = {
        --   enable_close = false
        -- }
      },
    })
  end,
}
