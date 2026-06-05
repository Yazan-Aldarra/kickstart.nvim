return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'rcasia/neotest-java',
    },
    keys = {
      { '<leader>tt', function() require('neotest').run.run() end, desc = 'Run nearest test' },
      { '<leader>tT', function() require('neotest').run.run(vim.fn.expand '%') end, desc = 'Run test file' },
      { '<leader>ta', function() require('neotest').run.run({ suite = true }) end, desc = 'Run all tests' },
      { '<leader>td', function() require('neotest').run.run { strategy = 'dap' } end, desc = 'Debug nearest test' },
      { '<leader>ts', function() require('neotest').summary.toggle() end, desc = 'Test summary' },
      { '<leader>to', function() require('neotest').output.open { enter = true } end, desc = 'Test output' },
      { '<leader>tO', function() require('neotest').output_panel.toggle() end, desc = 'Test output panel' },
      { '<leader>tS', function() require('neotest').run.stop() end, desc = 'Stop test' },
      { '[t', function() require('neotest').jump.prev { status = 'failed' } end, desc = 'Prev failed test' },
      { ']t', function() require('neotest').jump.next { status = 'failed' } end, desc = 'Next failed test' },
    },
    config = function()
      require('neotest').setup {
        adapters = {
          require('neotest-java') {
            ignore_wrapper = false,
          },
        },
        status = { virtual_text = true },
        signs = {
          passed = { text = '✓', highlight = 'DiagnosticOk' },
          failed = { text = '✗', highlight = 'DiagnosticError' },
          skipped = { text = '⊘', highlight = 'DiagnosticWarn' },
          running = { text = '⟳', highlight = 'DiagnosticInfo' },
          unknown = { text = '?', highlight = 'DiagnosticHint' },
        },
        consumers = {},
        icons = {
          passed = '✓',
          running = '⟳',
          failed = '✗',
          skipped = '⊘',
          unknown = '?',
          running_animated = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' },
        },
        highlights = {
          passed = 'DiagnosticOk',
          running = 'DiagnosticInfo',
          failed = 'DiagnosticError',
          skipped = 'DiagnosticWarn',
          unknown = 'DiagnosticHint',
        },
        floating = {
          border = 'rounded',
          max_height = 0.6,
          max_width = 0.6,
        },
        summary = {
          follow = true,
          open = 'botright vsplit | vertical resize 40',
        },
        output = {
          open_on_run = 'short',
        },
        quickfix = {
          open = function()
            vim.cmd 'copen'
          end,
        },
      }
    end,
  },
}