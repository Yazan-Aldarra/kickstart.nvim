local harpoon = require 'harpoon'

-- REQUIRED
harpoon:setup()
-- REQUIRED

vim.keymap.set('n', '<leader>ma', function() harpoon:list():add() end, { desc = '[A]dd current buffer to Harpoon list' })
vim.keymap.set('n', '<leader>mo', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = '[O]pen Harpoon quick menu' })

vim.keymap.set('n', '<leader>1', function() harpoon:list():select(1) end, { desc = 'Go to buffer [1] in Harpoon list' })
vim.keymap.set('n', '<leader>2', function() harpoon:list():select(2) end, { desc = 'Go to buffer [2] in Harpoon list' })
vim.keymap.set('n', '<leader>3', function() harpoon:list():select(3) end, { desc = 'Go to buffer [3] in Harpoon list' })
vim.keymap.set('n', '<leader>4', function() harpoon:list():select(4) end, { desc = 'Go to buffer [4] in Harpoon list' })

-- Toggle previous & lnext buffers stored within Harpoon list
vim.keymap.set('n', '<leader>mp', function() harpoon:list():prev() end, { desc = 'Go to [P]revious buffer in Harpoon list' })
vim.keymap.set('n', '<leader>mn', function() harpoon:list():next() end, { desc = 'Go to [N]ext buffer in Harpoon list' })

-- basic telescope configuration
local conf = require('telescope.config').values
local function toggle_telescope(harpoon_files)
  local file_paths = {}
  for _, item in ipairs(harpoon_files.items) do
    table.insert(file_paths, item.value)
  end

  require('telescope.pickers')
    .new({}, {
      prompt_title = 'Harpoon',
      finder = require('telescope.finders').new_table {
        results = file_paths,
      },
      previewer = conf.file_previewer {},
      sorter = conf.generic_sorter {},
    })
    :find()
end

vim.keymap.set('n', '<leader>mt', function() toggle_telescope(harpoon:list()) end, { desc = 'Open harpoon window' })
