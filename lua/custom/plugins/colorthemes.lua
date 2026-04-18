return {
  --[ colorthemes
  { 'catppuccin/nvim', name = 'catppuccin', priority = 1000 },

  -- {
  --   'navarasu/onedark.nvim',
  --   version = 'v0.1.0', -- Pin to legacy version
  --   priority = 1000,
  --   config = function()
  --     require('onedark').setup {
  --       style = 'warmer', -- Choose from 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer'
  --     }
  --   end,
  -- },

  -- {
  --   'Kopihue/one-dark-pro-max',
  --   name = 'one-dark-pro-max',
  --   config = function() vim.cmd 'colorscheme one-dark-pro-max' end,
  -- },

  -- https://github.com/olimorris/onedarkpro.nvim
  {
    'olimorris/onedarkpro.nvim',
    priority = 1000, -- Ensure it loads first
    config = function()
      require('onedarkpro').setup {
        styles = {
          comments = 'italic',
          keywords = 'italic',
          functions = 'italic',
          conditionals = 'italic',
        },
        options = {
          cursorline = true, -- Use cursorline highlighting?
          transparency = true, -- Use a transparent background?
        },
        colors = {
          cursorline = '#110d0e', -- This is optional. The default cursorline color is based on the background
        },
        highlights = {
          ['@lsp.type.annotation.java'] = { fg = '#f2ca81', italic = true }, -- @Configuration, @Bean
          ['@lsp.type.modifier.java'] = { fg = '#c678dd' }, -- public, private, final
        },
      }
    end,
  },
  --]
}
