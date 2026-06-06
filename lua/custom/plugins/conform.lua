return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_fallback = true }
        end,
        mode = '',
        desc = 'Format buffer',
      },
    },
    opts = {
      formatters_by_ft = {
        java = { 'google-java-format' },
        lua = { 'stylua' },
      },
      format_on_save = {
        timeout_ms = 3000,
        lsp_fallback = true,
      },
    },
    config = function(_, opts)
      local conform = require 'conform'
      conform.setup(opts)

      conform.formatters['google-java-format'] = {
        command = vim.fn.stdpath 'data' .. '/mason/bin/google-java-format.cmd',
        args = { '--aosp', '-' },
      }
    end,
  },
}