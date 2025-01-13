return {
  "echasnovski/mini.move",
  version = false,
  config = function()
    require("mini.move").setup({
      mappings = {
        -- Move visual selection in Visual mode
        left = "<leader><leader>h",
        right = "<leader><leader>l",
        down = "<leader><leader>j",
        up = "<leader><leader>k",

        -- Move current line in Normal mode
        line_left = "<leader><leader>h",
        line_right = "<leader><leader>l",
        line_down = "<leader><leader>j",
        line_up = "<leader><leader>k",
      },

      options = {
        reindent_linewise = true,
      },
    })
  end,
}
