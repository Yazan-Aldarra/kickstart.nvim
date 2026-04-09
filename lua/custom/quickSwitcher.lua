local opts = { noremap = true, silent = true }

local function find(file_regex, opts)
  return function() require('nvim-quick-switcher').find(file_regex, opts) end
end

-- local function inline_ts_switch(file_type, scheme)
--   return function() require('nvim-quick-switcher').inline_ts_switch(file_type, scheme) end
-- end

local function find_by_fn(fn, opts)
  return function() require('nvim-quick-switcher').find_by_fn(fn, opts) end
end

-- Styles
vim.keymap.set('n', '<leader>ai', find('.+css|.+scss|.+sass', { regex = true, prefix = 'full' }), opts)

-- Types
vim.keymap.set('n', '<leader>arm', find('.+model.ts|.+models.ts|.+types.ts', { regex = true }), opts)

-- Util
vim.keymap.set('n', '<leader>al', find('*util.*', { prefix = 'short' }), opts)

-- Tests
vim.keymap.set('n', '<leader>at', find('.+test|.+spec', { regex = true, prefix = 'full' }), opts)

-- Project Specific Keymaps
-- * Maps keys based on project using an auto command. Ideal for reusing keymaps based on context.
-- * Example: In Angular, `oo` switches to .component.html. In Svelte, `oo` switches to *page.svelte
vim.api.nvim_create_autocmd({ 'UIEnter' }, {
  callback = function(event)
    local is_angular = next(vim.fs.find({ 'angular.json', 'nx.json' }, { upward = true }))
    local is_svelte = next(vim.fs.find({ 'svelte.config.js', 'svelte.config.ts' }, { upward = true }))

    -- Angular
    if is_angular then
      print 'Angular'
      vim.keymap.set('n', '<leader>ao', find '.component.html', opts)
      vim.keymap.set('n', '<leader>au', find '.component.ts', opts)
      vim.keymap.set('n', '<leader>ap', find '.module.ts', opts)
      vim.keymap.set('n', '<leader>ay', find '.service.ts', opts)
    end

    -- SvelteKit
    if is_svelte then
      print 'Svelte'
      vim.keymap.set('n', '<leader>ao', find('*page.svelte', { maxdepth = 1, ignore_prefix = true }), opts)
      vim.keymap.set('n', '<leader>au', find('.*page.server(.+js|.+ts)|.*page(.+js|.+ts)', { maxdepth = 1, regex = true, ignore_prefix = true }), opts)
      vim.keymap.set('n', '<leader>ap', find('*layout.svelte', { maxdepth = 1, ignore_prefix = true }), opts)

      -- -- Inline TS
      -- vim.keymap.set('n', '<leader>aj', inline_ts_switch('svelte', '(script_element (end_tag) @capture)'), opts)
      -- vim.keymap.set('n', '<leader>ak', inline_ts_switch('svelte', '(style_element (start_tag) @capture)'), opts)
    end
  end,
})

-- Redux-like
vim.keymap.set('n', '<leader>are', find '*effects.ts', opts)
vim.keymap.set('n', '<leader>ara', find '*actions.ts', opts)
vim.keymap.set('n', '<leader>arw', find '*store.ts', opts)
vim.keymap.set('n', '<leader>arf', find '*facade.ts', opts)
vim.keymap.set('n', '<leader>ars', find('.+query.ts|.+selectors.ts|.+selector.ts', { regex = true }), opts)
vim.keymap.set('n', '<leader>arr', find('.+reducer.ts|.+repository.ts', { regex = true }), opts)

-- Java J-Unit (Advanced Example)
local find_test_fn = function(p)
  local path = p.path
  local file_name = p.prefix
  local result = path:gsub('src', 'test') .. '/' .. file_name .. '*'
  return result
end

local find_src_fn = function(p)
  local path = p.path
  local file_name = p.prefix
  local result = path:gsub('test', 'src') .. '/' .. file_name .. '*'
  return result
end

vim.keymap.set('n', '<leader>ajj', find_by_fn(find_test_fn), opts)
vim.keymap.set('n', '<leader>ajk', find_by_fn(find_src_fn), opts)
