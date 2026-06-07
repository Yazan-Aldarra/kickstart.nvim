return {
  {
    -- repo: https://github.com/stevearc/oil.nvim
    'stevearc/oil.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      CustomOilBar = function()
        local path = vim.fn.expand '%'
        path = path:gsub('oil://', '')

        return '  ' .. vim.fn.fnamemodify(path, ':.')
      end

      require('oil').setup {
        columns = { 'icon' },
        win_options = {
          winbar = '%{v:lua.CustomOilBar()}',
        },
        view_options = {
          show_hidden = true,
          is_always_hidden = function(name, _)
            local folder_skip = { 'dev-tools.locks', 'dune.lock', '_build' }
            return vim.tbl_contains(folder_skip, name)
          end,
        },
      }

      -- Open parent directory in current window
      vim.keymap.set('n', '<leader>-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })

      -- Fuzzy find directory and open in Oil
      local function pick_directory()
        local find_cmd
        if vim.fn.executable 'fd' == 1 then
          find_cmd = { 'fd', '--type', 'd', '--hidden', '--follow', '--exclude', '.git' }
        elseif vim.fn.executable 'fdfind' == 1 then
          find_cmd = { 'fdfind', '--type', 'd', '--hidden', '--follow', '--exclude', '.git' }
        else
          find_cmd = { 'find', '.', '-type', 'd', '-not', '-path', '*/.git/*' }
        end

        require('telescope.builtin').find_files {
          find_command = find_cmd,
          prompt_title = 'Open Directory in Oil',
          attach_mappings = function(prompt_bufnr, map)
            require('telescope.actions').select_default:replace(function()
              local entry = require('telescope.actions.state').get_selected_entry()
              require('telescope.actions').close(prompt_bufnr)
              if entry and entry.path then
                vim.cmd('Oil ' .. entry.path)
              end
            end)
            return true
          end,
        }
      end

      vim.keymap.set('n', '<leader>sD', pick_directory, { desc = '[S]earch [D]irectory (Oil)' })
    end,
  },
}
