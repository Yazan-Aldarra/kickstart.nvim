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
      format_on_save = function(bufnr)
        local exclude_filetypes = { java = true }
        if exclude_filetypes[vim.bo[bufnr].filetype] then
          return nil
        end
        return {
          timeout_ms = 3000,
          lsp_fallback = true,
        }
      end,
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