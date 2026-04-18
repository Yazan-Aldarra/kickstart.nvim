-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

---@module 'lazy'
---@type LazySpec
return {
  {
    'nvim-lua/plenary.nvim',
  },

  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
  },

  { 'joeveiga/ng.nvim' },

  -- wezterm types for type annotations and autocompletion in wezterm config
  {
    'DrKJeff16/wezterm-types',
    version = false, -- Get the latest version
  },
  -- color picker
  {
    'uga-rosa/ccc.nvim',
  },
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
  },
}
