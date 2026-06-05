return {
  {
    'nvim-java/nvim-java',
    -- event = 'VimEnter',
    config = function()
      require('java').setup {
        settings = {
          java = {
            completion = {
              imports = {
                enabled = true,
              },
            },
          },
        },
      }

      local inline = require 'custom.java-test-inline'
      local lsp_utils = require 'java-core.utils.lsp'
      local runner = require 'async.runner'

      local JavaTestApi = require 'java-test.api'
      local DapRunner = require 'java-dap.runner'
      local JUnitReport = require 'java-test.reports.junit'
      local ResultParserFactory = require 'java-test.results.result-parser-factory'
      local ReportViewer = require 'java-test.ui.floating-report-viewer'

      vim.api.nvim_create_user_command('JavaTestRunClass', function()
        print 'JavaTestRunClass called'
        local buf = vim.api.nvim_get_current_buf()
        print('buffer:', buf)
        inline.clear(buf)

        runner(function()
            print 'runner started'
            local test_api = JavaTestApi:new {
              client = lsp_utils.get_jdtls(),
              runner = DapRunner(),
            }
            local report = JUnitReport(ResultParserFactory(), ReportViewer())
            print 'hooking report'
            inline.hook(report, buf)
            print 'executing test'
            return test_api:execute_current_test_class(report, { noDebug = true })
          end)
          .catch(function(err) vim.notify('Test failed: ' .. err, vim.log.LEVEL_ERROR) end)
          .run()
      end, {})

      vim.api.nvim_create_user_command('JavaTestRunMethod', function()
        print 'JavaTestRunMethod called'
        local buf = vim.api.nvim_get_current_buf()
        inline.clear(buf)

        runner(function()
            local test_api = JavaTestApi:new {
              client = lsp_utils.get_jdtls(),
              runner = DapRunner(),
            }
            local report = JUnitReport(ResultParserFactory(), ReportViewer())
            inline.hook(report, buf)
            return test_api:execute_current_test_method(report, { noDebug = true })
          end)
          .catch(function(err) vim.notify('Test failed: ' .. err, vim.log.LEVEL_ERROR) end)
          .run()
      end, {})

      vim.lsp.enable 'jdtls'
      vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
        pattern = '*.class',
        callback = function()
          vim.bo.filetype = 'java'
          -- Force trigger nvim-java's setup for this buffer
          vim.cmd 'doautocmd FileType java'
        end,
      })
    end,
  },
}
