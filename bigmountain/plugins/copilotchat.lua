-- local IS_DEV = false
--
-- local prompts = {
--   -- Code related prompts
--   Explain = "Please explain how the following code works.",
--   Review = "Please review the following code and provide suggestions for improvement.",
--   Tests = "Please explain how the selected code works, then generate unit tests for it.",
--   Refactor = "Please refactor the following code to improve its clarity and readability.",
--   FixCode = "Please fix the following code to make it work as intended.",
--   FixError = "Please explain the error in the following text and provide a solution.",
--   BetterNamings = "Please provide better names for the following variables and functions.",
--   Documentation = "Please provide documentation for the following code.",
--   SwaggerApiDocs = "Please provide documentation for the following API using Swagger.",
--   SwaggerJsDocs = "Please write JSDoc for the following API using Swagger.",
--   -- Text related prompts
--   Summarize = "Please summarize the following text.",
--   Spelling = "Please correct any grammar and spelling errors in the following text.",
--   Wording = "Please improve the grammar and wording of the following text.",
--   Concise = "Please rewrite the following text to make it more concise.",
-- }
--
-- return {
--   {
--     "github/copilot.vim",
--     lazy = false,
--     -- Your existing Copilot configuration will be used from copilot.lua
--   },
--   {
--     "folke/which-key.nvim",
--     optional = true,
--     opts = {
--       spec = {
--         { "<leader>a", group = "ai" },
--       },
--     },
--   },
--   {
--     dir = IS_DEV and "~/Projects/research/CopilotChat.nvim" or nil,
--     "CopilotC-Nvim/CopilotChat.nvim",
--     version = "v3.3.0", -- Using a specific version to prevent breaking changes
--     dependencies = {
--       { "nvim-telescope/telescope.nvim" }, -- Use telescope for help actions
--       { "nvim-lua/plenary.nvim" }, -- Important for path handling functions
--       { "github/copilot.vim" }, -- Explicitly declare dependency on Copilot
--     },
--     opts = {
--       question_header = "## User ",
--       answer_header = "## Copilot ",
--       error_header = "## Error ",
--       prompts = prompts,
--       auto_follow_cursor = false, -- Don't follow the cursor after getting response
--       mappings = {
--         -- Use tab for completion
--         complete = {
--           detail = "Use @<Tab> or /<Tab> for options.",
--           insert = "<Tab>",
--         },
--         -- Close the chat
--         close = {
--           normal = "q",
--           insert = "<C-c>",
--         },
--         -- Reset the chat buffer
--         reset = {
--           normal = "<C-x>",
--           insert = "<C-x>",
--         },
--         -- Submit the prompt to Copilot
--         submit_prompt = {
--           normal = "<CR>",
--           insert = "<C-CR>",
--         },
--         -- Accept the diff
--         accept_diff = {
--           normal = "<C-y>",
--           insert = "<C-y>",
--         },
--         -- Show help
--         show_help = {
--           normal = "g?",
--         },
--       },
--     },
--     config = function(_, opts)
--       local chat = require("CopilotChat")
--
--       -- Make sure plenary is properly loaded before setting up CopilotChat
--       local has_plenary, plenary_path = pcall(require, "plenary.path")
--       if not has_plenary then
--         vim.notify("CopilotChat requires plenary.nvim", vim.log.levels.ERROR)
--         return
--       end
--
--       -- First, patch the CopilotChat.utils module to add our missing functions
--       local CopilotChatUtils = require("CopilotChat.utils")
--
--       -- Add the missing abspath function
--       CopilotChatUtils.abspath = function(path)
--         if not path then
--           return nil
--         end
--
--         if has_plenary then
--           return plenary_path:new(path):absolute()
--         end
--
--         -- Fallback to a simple path normalization if plenary is not available
--         return path
--       end
--
--       -- Override the filename_same function with a more robust version
--       if CopilotChatUtils.filename_same then
--         local original_filename_same = CopilotChatUtils.filename_same
--
--         CopilotChatUtils.filename_same = function(a, b)
--           -- Basic nil checks
--           if not a or not b then
--             return false
--           end
--
--           -- Convert to strings in case we got something unexpected
--           local path_a = tostring(a)
--           local path_b = tostring(b)
--
--           -- Get absolute paths
--           path_a = CopilotChatUtils.abspath(path_a)
--           path_b = CopilotChatUtils.abspath(path_b)
--
--           -- Simple string comparison of absolute paths
--           if path_a and path_b then
--             return path_a == path_b
--           end
--
--           -- If our approach fails, try the original function with error handling
--           local success, result = pcall(original_filename_same, a, b)
--           if success then
--             return result
--           end
--
--           -- Last resort: direct string comparison
--           return tostring(a) == tostring(b)
--         end
--       end
--
--       -- Now set up the chat
--       chat.setup(opts)
--
--       -- File patching autocmd for long-term fix
--       vim.api.nvim_create_autocmd("VimEnter", {
--         callback = function()
--           vim.defer_fn(function()
--             -- Path to the utils.lua file
--             local utils_path = vim.fn.stdpath("data") .. "/lazy/CopilotChat.nvim/lua/CopilotChat/utils.lua"
--
--             -- Check if the file exists
--             if vim.fn.filereadable(utils_path) == 1 then
--               -- Read the file content
--               local content = table.concat(vim.fn.readfile(utils_path), "\n")
--
--               -- Check if we need to patch the file (has filename_same but no abspath)
--               if content:find("function M.filename_same") and not content:find("function M.abspath") then
--                 -- Create a backup of the original file
--                 vim.fn.writefile(vim.fn.readfile(utils_path), utils_path .. ".backup")
--
--                 -- Add the abspath function before the filename_same function
--                 local patched_content = content:gsub(
--                   "function M.filename_same",
--                   [[function M.abspath(path)
--   if not path then return nil end
--   local has_plenary, Path = pcall(require, 'plenary.path')
--   if has_plenary then
--     return Path:new(path):absolute()
--   else
--     return path
--   end
-- end
--
-- function M.filename_same]]
--                 )
--
--                 -- Replace the problematic line in filename_same with a safer version
--                 patched_content = patched_content:gsub(
--                   "return vim.loop.fs_stat(a).ino == vim.loop.fs_stat(b).ino",
--                   [[local success, result = pcall(function()
--     local stat_a = vim.loop.fs_stat(M.abspath(a))
--     local stat_b = vim.loop.fs_stat(M.abspath(b))
--     if stat_a and stat_b and stat_a.ino and stat_b.ino then
--       return stat_a.ino == stat_b.ino
--     end
--     return M.abspath(a) == M.abspath(b)
--   end)
--   return success and result or M.abspath(a) == M.abspath(b)]]
--                 )
--
--                 -- Write the patched file
--                 vim.fn.writefile(vim.split(patched_content, "\n"), utils_path)
--
--                 -- Notify the user
--                 vim.notify(
--                   "Patched CopilotChat utils.lua to fix abspath issue. Restart Neovim for changes to take effect.",
--                   vim.log.levels.INFO
--                 )
--               end
--             end
--           end, 1000) -- Wait 1 second for plugins to load
--         end,
--         once = true,
--       })
--
--       -- Set up commands
--       local select = require("CopilotChat.select")
--
--       -- Visual selection chat
--       vim.api.nvim_create_user_command("CopilotChatVisual", function(args)
--         chat.ask(args.args, { selection = select.visual })
--       end, { nargs = "*", range = true })
--
--       -- Inline chat with Copilot
--       vim.api.nvim_create_user_command("CopilotChatInline", function(args)
--         chat.ask(args.args, {
--           selection = select.visual,
--           window = {
--             layout = "float",
--             relative = "cursor",
--             width = 1,
--             height = 0.4,
--             row = 1,
--           },
--         })
--       end, { nargs = "*", range = true })
--
--       -- Buffer chat
--       vim.api.nvim_create_user_command("CopilotChatBuffer", function(args)
--         chat.ask(args.args, { selection = select.buffer })
--       end, { nargs = "*", range = true })
--
--       -- Custom buffer settings for CopilotChat
--       vim.api.nvim_create_autocmd("BufEnter", {
--         pattern = "copilot-*",
--         callback = function()
--           vim.opt_local.relativenumber = true
--           vim.opt_local.number = true
--
--           -- Set filetype to markdown for proper syntax highlighting
--           local ft = vim.bo.filetype
--           if ft == "copilot-chat" then
--             vim.bo.filetype = "markdown"
--           end
--         end,
--       })
--     end,
--     event = "VeryLazy",
--     keys = {
--       -- Show prompts actions with telescope
--       {
--         "<leader>ap",
--         function()
--           local actions = require("CopilotChat.actions")
--           require("CopilotChat.integrations.telescope").pick(actions.prompt_actions())
--         end,
--         desc = "CopilotChat - Prompt actions",
--       },
--       {
--         "<leader>ap",
--         ":lua require('CopilotChat.integrations.telescope').pick(require('CopilotChat.actions').prompt_actions({selection = require('CopilotChat.select').visual}))<CR>",
--         mode = "x",
--         desc = "CopilotChat - Prompt actions",
--       },
--       -- Code related commands
--       { "<leader>ae", "<cmd>CopilotChatExplain<cr>", desc = "CopilotChat - Explain code" },
--       { "<leader>at", "<cmd>CopilotChatTests<cr>", desc = "CopilotChat - Generate tests" },
--       { "<leader>ar", "<cmd>CopilotChatReview<cr>", desc = "CopilotChat - Review code" },
--       { "<leader>aR", "<cmd>CopilotChatRefactor<cr>", desc = "CopilotChat - Refactor code" },
--       { "<leader>an", "<cmd>CopilotChatBetterNamings<cr>", desc = "CopilotChat - Better Naming" },
--       -- Chat with Copilot in visual mode
--       {
--         "<leader>av",
--         ":CopilotChatVisual",
--         mode = "x",
--         desc = "CopilotChat - Open in vertical split",
--       },
--       {
--         "<leader>ax",
--         ":CopilotChatInline<cr>",
--         mode = "x",
--         desc = "CopilotChat - Inline chat",
--       },
--       -- Custom input for CopilotChat
--       {
--         "<leader>ai",
--         function()
--           local input = vim.fn.input("Ask Copilot: ")
--           if input ~= "" then
--             vim.cmd("CopilotChat " .. input)
--           end
--         end,
--         desc = "CopilotChat - Ask input",
--       },
--       -- Generate commit message based on the git diff
--       {
--         "<leader>am",
--         "<cmd>CopilotChatCommit<cr>",
--         desc = "CopilotChat - Generate commit message for all changes",
--       },
--       -- Quick chat with Copilot
--       {
--         "<leader>aq",
--         function()
--           local input = vim.fn.input("Quick Chat: ")
--           if input ~= "" then
--             vim.cmd("CopilotChatBuffer " .. input)
--           end
--         end,
--         desc = "CopilotChat - Quick chat",
--       },
--       -- Debug
--       { "<leader>ad", "<cmd>CopilotChatDebugInfo<cr>", desc = "CopilotChat - Debug Info" },
--       -- Fix the issue with diagnostic
--       { "<leader>af", "<cmd>CopilotChatFixDiagnostic<cr>", desc = "CopilotChat - Fix Diagnostic" },
--       -- Clear buffer and chat history
--       { "<leader>al", "<cmd>CopilotChatReset<cr>", desc = "CopilotChat - Clear buffer and chat history" },
--       -- Toggle Copilot Chat Vsplit
--       { "<leader>ac", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat - Toggle" }, -- Changed from av to ac to avoid conflict
--       -- Copilot Chat Models
--       { "<leader>a?", "<cmd>CopilotChatModels<cr>", desc = "CopilotChat - Select Models" },
--       -- Copilot Chat Agents
--       { "<leader>aa", "<cmd>CopilotChatAgents<cr>", desc = "CopilotChat - Select Agents" },
--     },
--   },
-- }

return {
  -- Dependency: Base Copilot plugin for completions
  {
    "github/copilot.vim",
    lazy = false,
  },

  -- Main CopilotChat plugin
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary", -- Use the canary branch which has the latest fixes
    dependencies = {
      "nvim-lua/plenary.nvim",
      "github/copilot.vim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      -- ========================================
      -- SETUP AND CONFIGURATION
      -- ========================================

      -- Define standard prompts
      local prompts = {
        Explain = "Please explain how the following code works.",
        Review = "Please review the following code and provide suggestions for improvement.",
        Tests = "Please explain how the selected code works, then generate unit tests for it.",
        Refactor = "Please refactor the following code to improve its clarity and readability.",
        FixCode = "Please fix the following code to make it work as intended.",
        FixError = "Please explain the error in the following text and provide a solution.",
        BetterNamings = "Please provide better names for the following variables and functions.",
        Documentation = "Please provide documentation for the following code.",
      }

      -- Basic configuration settings
      local options = {
        debug = true, -- Enable debug mode for more information
        prompt = prompts,
        -- Make sure diff acceptance works properly
        mappings = {
          accept_diff = {
            normal = "<C-y>",
            insert = "<C-y>",
          },
          close = {
            normal = "q",
            insert = "<C-c>",
          },
          reset = {
            normal = "<C-l>",
            insert = "<C-l>",
          },
          submit_prompt = {
            normal = "<CR>",
            insert = "<C-CR>",
          },
          show_help = {
            normal = "g?",
          },
        },
      }

      -- ========================================
      -- MODULE HANDLING & ERROR CHECKING
      -- ========================================

      -- Use protected calls to ensure we gracefully handle errors
      local setup_copilot_chat = function()
        -- Attempt to require the module
        local chat_ok, chat = pcall(require, "CopilotChat")
        if not chat_ok then
          vim.notify("Failed to load CopilotChat module: " .. tostring(chat), vim.log.levels.ERROR)
          return false
        end

        -- Try to set up the chat with our configuration
        local setup_ok, setup_err = pcall(function()
          chat.setup(options)
        end)

        if not setup_ok then
          vim.notify("Failed to set up CopilotChat: " .. tostring(setup_err), vim.log.levels.ERROR)
          return false
        end

        return true
      end

      -- Run the setup with error checking
      local chat_setup_success = setup_copilot_chat()

      -- ========================================
      -- BUFFER SPECIFIC SETTINGS
      -- ========================================

      -- Custom DIRECT key mapping for the accept_diff functionality
      -- This bypasses the normal plugin key mapping system for more reliability
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "copilot-*", "markdown" },
        callback = function(ev)
          -- Direct key mapping in the buffer where it's needed
          vim.keymap.set({ "n", "i" }, "<C-y>", function()
            -- Get the required modules
            local actions_ok, actions

            -- Try different paths to reach the actions module
            for _, module_path in ipairs({
              "CopilotChat.actions",
              "copilotchat.actions",
              "copilot_chat.actions",
            }) do
              actions_ok, actions = pcall(require, module_path)
              if actions_ok and actions then
                break
              end
            end

            if not actions_ok or not actions then
              vim.notify("Could not find CopilotChat actions module. Tried multiple paths.", vim.log.levels.ERROR)
              return
            end

            -- Try to call the accept_diff function
            if not actions.accept_diff then
              vim.notify("accept_diff function not found in actions module", vim.log.levels.ERROR)

              -- Last resort: try to find any function that might be related to diff acceptance
              for func_name, func in pairs(actions) do
                if
                  type(func) == "function"
                  and (func_name:match("diff") or func_name:match("accept") or func_name:match("apply"))
                then
                  vim.notify("Found potential alternative: " .. func_name, vim.log.levels.INFO)
                  local ok, err = pcall(func)
                  if not ok then
                    vim.notify("Failed to call " .. func_name .. ": " .. tostring(err), vim.log.levels.ERROR)
                  end
                  return
                end
              end

              return
            end

            -- Call the accept_diff function with proper error handling
            local ok, err = pcall(actions.accept_diff)
            if not ok then
              vim.notify("Error in accept_diff: " .. tostring(err), vim.log.levels.ERROR)
            end
          end, { buffer = ev.buf, desc = "Accept Copilot Chat diff suggestion" })

          -- Make sure buffer settings are correct for diff handling
          vim.opt_local.modifiable = true
          vim.opt_local.readonly = false
        end,
      })

      -- ========================================
      -- VISUAL SELECTION HANDLERS
      -- ========================================

      local get_visual_selection = function()
        -- Save the current register content and selection mode
        local reg_save = vim.fn.getreg('"')
        local regtype_save = vim.fn.getregtype('"')

        -- Get the selection into the unnamed register
        vim.cmd('noau normal! "vy"')

        -- Get the selection from the unnamed register
        local selection = vim.fn.getreg('"')

        -- Restore the register
        vim.fn.setreg('"', reg_save, regtype_save)

        -- Return the selection
        return selection
      end

      -- Function to safely handle a prompt with visual selection
      local handle_visual_prompt = function(prompt_name)
        if not prompt_name or not prompts[prompt_name] then
          vim.notify("Unknown prompt: " .. tostring(prompt_name), vim.log.levels.ERROR)
          return
        end

        -- Get selection and chat module
        local selection = get_visual_selection()

        if selection == nil or selection == "" then
          vim.notify("No text selected", vim.log.levels.WARN)
          return
        end

        local chat_ok, chat = pcall(require, "CopilotChat")
        if not chat_ok then
          vim.notify("Could not load CopilotChat module", vim.log.levels.ERROR)
          return
        end

        -- Ensure we have the actual prompt text
        local prompt_text = prompts[prompt_name] .. "\n\n```\n" .. selection .. "\n```"

        -- Call ask with proper error handling
        local ask_ok, ask_err = pcall(function()
          chat.ask(prompt_text)
        end)

        if not ask_ok then
          vim.notify("Failed to ask Copilot: " .. tostring(ask_err), vim.log.levels.ERROR)
        end
      end

      -- ========================================
      -- DIAGNOSTICS COMMANDS
      -- ========================================

      -- Create a diagnostic command to help with troubleshooting
      vim.api.nvim_create_user_command("CopilotChatDiagnostics", function()
        vim.notify("Running CopilotChat diagnostics...", vim.log.levels.INFO)

        -- Check Neovim version
        vim.notify(
          "Neovim version: " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
          vim.log.levels.INFO
        )

        -- Check if plugin is installed
        local plugin_dir = vim.fn.stdpath("data") .. "/lazy/CopilotChat.nvim"
        local plugin_exists = vim.fn.isdirectory(plugin_dir) == 1
        vim.notify("Plugin directory exists: " .. tostring(plugin_exists), vim.log.levels.INFO)

        -- Check buffer settings
        vim.notify("Current buffer: " .. vim.api.nvim_buf_get_name(0), vim.log.levels.INFO)
        vim.notify("Buffer filetype: " .. vim.bo.filetype, vim.log.levels.INFO)
        vim.notify("Buffer modifiable: " .. tostring(vim.bo.modifiable), vim.log.levels.INFO)
        vim.notify("Buffer readonly: " .. tostring(vim.bo.readonly), vim.log.levels.INFO)

        -- Try to load modules
        for _, module_name in ipairs({
          "CopilotChat",
          "CopilotChat.actions",
          "copilotchat.actions",
          "copilot_chat.actions",
        }) do
          local ok, module = pcall(require, module_name)
          vim.notify("Module " .. module_name .. " loaded: " .. tostring(ok), vim.log.levels.INFO)

          if ok and module_name:match("actions") then
            -- Check for diff function
            vim.notify("accept_diff function exists: " .. tostring(module.accept_diff ~= nil), vim.log.levels.INFO)

            -- List available functions
            vim.notify("Available functions in " .. module_name .. ":", vim.log.levels.INFO)
            for func_name, _ in pairs(module) do
              if type(module[func_name]) == "function" then
                vim.notify("  - " .. func_name, vim.log.levels.INFO)
              end
            end
          end
        end
      end, {})

      -- Make it easier to trigger the diagnostics
      vim.keymap.set("n", "<leader>acd", "<cmd>CopilotChatDiagnostics<CR>", { desc = "Run CopilotChat diagnostics" })

      -- ========================================
      -- MAPPING SETUP FOR NORMAL & VISUAL MODE
      -- ========================================

      -- Set up key mappings for both normal and visual modes
      local setup_keymaps = function()
        local actions = {
          { key = "e", prompt = "Explain", desc = "Explain code" },
          { key = "t", prompt = "Tests", desc = "Generate tests" },
          { key = "r", prompt = "Review", desc = "Review code" },
          { key = "R", prompt = "Refactor", desc = "Refactor code" },
          { key = "f", prompt = "FixCode", desc = "Fix code" },
          { key = "F", prompt = "FixError", desc = "Fix error" },
          { key = "n", prompt = "BetterNamings", desc = "Suggest better names" },
          { key = "d", prompt = "Documentation", desc = "Generate documentation" },
        }

        -- Set up normal mode mappings with commands
        for _, action in ipairs(actions) do
          -- Normal mode - whole buffer
          vim.keymap.set("n", "<leader>a" .. action.key, function()
            -- Get chat module
            local chat_ok, chat = pcall(require, "CopilotChat")
            if not chat_ok then
              vim.notify("Could not load CopilotChat module", vim.log.levels.ERROR)
              return
            end

            -- Get buffer content
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            local text = table.concat(lines, "\n")

            -- Prepare prompt
            local prompt_text = prompts[action.prompt] .. "\n\n```\n" .. text .. "\n```"

            -- Ask Copilot
            local ask_ok, ask_err = pcall(function()
              chat.ask(prompt_text)
            end)

            if not ask_ok then
              vim.notify("Failed to ask Copilot: " .. tostring(ask_err), vim.log.levels.ERROR)
            end
          end, { desc = "CopilotChat - " .. action.desc })

          -- Visual mode - selected text
          vim.keymap.set("v", "<leader>a" .. action.key, function()
            handle_visual_prompt(action.prompt)
          end, { desc = "CopilotChat - " .. action.desc .. " (visual)" })
        end

        -- Add the inline chat shortcut for visual mode
        vim.keymap.set("v", "<leader>ax", function()
          -- Get selection
          local selection = get_visual_selection()

          if selection == nil or selection == "" then
            vim.notify("No text selected", vim.log.levels.WARN)
            return
          end

          -- Get chat module
          local chat_ok, chat = pcall(require, "CopilotChat")
          if not chat_ok then
            vim.notify("Could not load CopilotChat module", vim.log.levels.ERROR)
            return
          end

          -- Try to open inline chat
          local ask_ok, ask_err = pcall(function()
            chat.ask("", {
              selection = selection,
              window = {
                layout = "float",
                relative = "cursor",
                width = 1,
                height = 0.4,
                row = 1,
              },
            })
          end)

          if not ask_ok then
            vim.notify("Failed to open inline chat: " .. tostring(ask_err), vim.log.levels.ERROR)
          end
        end, { desc = "CopilotChat - Inline chat (visual)" })

        -- Custom prompt with input for both modes
        vim.keymap.set({ "n", "v" }, "<leader>ai", function()
          local input = vim.fn.input("Ask Copilot: ")
          if input == "" then
            return
          end

          -- Get chat module
          local chat_ok, chat = pcall(require, "CopilotChat")
          if not chat_ok then
            vim.notify("Could not load CopilotChat module", vim.log.levels.ERROR)
            return
          end

          -- In visual mode, get the selection
          local mode = vim.fn.mode()

          if mode == "v" or mode == "V" or mode == "\22" then
            local selection = get_visual_selection()

            if selection and selection ~= "" then
              local prompt_text = input .. "\n\n```\n" .. selection .. "\n```"

              -- Ask Copilot with the selection
              local ask_ok, ask_err = pcall(function()
                chat.ask(prompt_text)
              end)

              if not ask_ok then
                vim.notify("Failed to ask Copilot: " .. tostring(ask_err), vim.log.levels.ERROR)
              end
            end
          else
            -- In normal mode, just ask the question
            local ask_ok, ask_err = pcall(function()
              chat.ask(input)
            end)

            if not ask_ok then
              vim.notify("Failed to ask Copilot: " .. tostring(ask_err), vim.log.levels.ERROR)
            end
          end
        end, { desc = "CopilotChat - Ask with input" })
      end

      -- Set up all keymaps if the plugin is ready
      if chat_setup_success then
        setup_keymaps()
      end
    end,
  },
}
