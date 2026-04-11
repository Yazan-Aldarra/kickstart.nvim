-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

---@module 'lazy'
---@type LazySpec
return {

  {
    'sudo-tee/opencode.nvim',
    config = function() require('opencode').setup {} end,
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          anti_conceal = { enabled = false },
          file_types = { 'markdown', 'opencode_output' },
        },
        ft = { 'markdown', 'Avante', 'copilot-chat', 'opencode_output' },
      },
      -- Optional, for file mentions and commands completion, pick only one
      'saghen/blink.cmp',
      -- 'hrsh7th/nvim-cmp',

      -- Optional, for file mentions picker, pick only one
      -- 'folke/snacks.nvim',
      'nvim-telescope/telescope.nvim',
      -- 'ibhagwan/fzf-lua',
      -- 'nvim_mini/mini.nvim',
    },
  },

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
    end,
  },

  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
  },

  {
    'NeogitOrg/neogit',
    lazy = true,
    dependencies = {
      'nvim-lua/plenary.nvim', -- required

      -- Only one of these is needed.
      'sindrets/diffview.nvim', -- optional
      'esmuellert/codediff.nvim', -- optional

      -- For a custom log pager
      'm00qek/baleia.nvim', -- optional

      -- Only one of these is needed.
      'nvim-telescope/telescope.nvim', -- optional
      'ibhagwan/fzf-lua', -- optional
      'nvim-mini/mini.pick', -- optional
      'folke/snacks.nvim', -- optional
    },
    cmd = 'Neogit',
    keys = {
      { '<leader>gg', '<cmd>Neogit<cr>', desc = 'Show Neogit UI' },
    },
  },

  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    opts = {
      messages = {
        enabled = false,
      },
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      'MunifTanjim/nui.nvim',
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      --   dasds ad
      'rcarriga/nvim-notify',
    },
  },

  --[ colorthemes
  { 'catppuccin/nvim', name = 'catppuccin', priority = 1000 },

  {
    'olimorris/onedarkpro.nvim',
    priority = 1000, -- Ensure it loads first
    config = function()
      require('onedarkpro').setup {
        styles = {
          types = 'NONE',
          methods = 'NONE',
          numbers = 'NONE',
          strings = 'NONE',
          comments = 'italic',
          keywords = 'italic',
          constants = 'NONE',
          functions = 'italic',
          operators = 'NONE',
          variables = 'NONE',
          parameters = 'NONE',
          conditionals = 'italic',
          virtual_text = 'NONE',
        },
        options = {
          cursorline = true, -- Use cursorline highlighting?
        },
        colors = {
          cursorline = '#110d0e', -- This is optional. The default cursorline color is based on the background
        },
      }
    end,
  },
  --]

  {
    'github/copilot.vim',
    lazy = false, -- Load immediately so it's ready when you start coding
    config = function()
      -- Optional: Map Tab to accept suggestions more comfortably
      vim.keymap.set('i', '<Tab>', 'copilot#Accept()', { expr = true, replace_keycodes = false })
      vim.keymap.set('i', '<C-]>', '<Plug>(copilot-dismiss)') -- Use Ctrl+] to dismiss a suggestion
    end,
  },

  {
    'nvim-lua/plenary.nvim',
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'nvim-lua/plenary.nvim', branch = 'master' },
    },
    build = 'make tiktoken',
    opts = {
      -- See Configuration section for options
    },
  },

  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
  },

  { 'joeveiga/ng.nvim' },
}
