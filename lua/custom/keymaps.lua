-- Angular ('joeveiga/ng.nvim')
-- local opts = { noremap = true, silent = true }
-- local ng = require 'ng'
-- vim.keymap.set('n', '<leader>at', ng.goto_template_for_component, opts)
-- vim.keymap.set('n', '<leader>ac', ng.goto_component_with_template_file, opts)
-- vim.keymap.set('n', '<leader>aT', ng.get_template_tcb, opts)

-- Noice ('folke/noice.nvim')
vim.keymap.set('n', '<leader>nd', function() require('noice').cmd 'dismiss' end, { desc = 'Dismiss all Noice messages' })

require 'custom.harpoon'

vim.keymap.set('n', '<leader>sF', function()
  require('telescope.builtin').find_files {
    hidden = true,
    no_ignore = true,
    -- no_ignore_parent = true
  }
end, { desc = '[S]earch [<s-F>]iles (including hidden and ignored)' })

-- vim remaps
vim.keymap.set('n', '<c-d>', '<c-d>zz', { desc = 'Centers after half page scroll' })
vim.keymap.set('n', '<c-u>', '<c-u>zz', { desc = 'Centers after half page scroll' })

vim.api.nvim_create_user_command('PrevHunkPreview', function()
  vim.cmd.normal '[q'
  vim.cmd.normal '<leader>hi'
end, {})

vim.api.nvim_create_user_command('NextHunkPreview', function()
  vim.cmd.normal ']q'
  vim.cmd.normal '<leader>hi'
end, {})
