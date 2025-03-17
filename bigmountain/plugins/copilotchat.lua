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
            insert = "<C-f>",
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

        -- Direct shortcut to open CopilotChat window
        vim.keymap.set("n", "<leader>ao", function()
          -- Get chat module
          local chat_ok, chat = pcall(require, "CopilotChat")
          if not chat_ok then
            vim.notify("Could not load CopilotChat module", vim.log.levels.ERROR)
            return
          end

          -- Open CopilotChat window
          local ok, err = pcall(function()
            -- Try multiple possible functions to open the chat
            if chat.toggle then
              chat.toggle()
            elseif chat.open then
              chat.open()
            else
              -- Last resort - use vim command
              vim.cmd("CopilotChat")
            end
          end)

          if not ok then
            vim.notify("Failed to open CopilotChat: " .. tostring(err), vim.log.levels.ERROR)
            -- Fallback to using command directly
            pcall(vim.cmd, "CopilotChat")
          end
        end, { desc = "Open CopilotChat window" })

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
