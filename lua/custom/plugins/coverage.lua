return {
  {
    'mr-u0b0dy/crazy-coverage.nvim',
    keys = {
      { '<leader>cc', '<cmd>JavaCoverage<cr>', desc = 'Toggle JaCoCo coverage' },
      { '<leader>cS', '<cmd>JaCoCoSummary<cr>', desc = 'JaCoCo coverage summary' },
      { '<leader>cD', '<cmd>JacocoDebug<cr>', desc = 'Debug coverage paths' },
      { '<leader>cd', '<cmd>JavaCoverage disable<cr>', desc = 'Disable coverage signs' },
      { '<leader>ce', '<cmd>JavaCoverage enable<cr>', desc = 'Re-enable coverage signs' },
      { ']cu', '<cmd>CoverageNextUncovered<cr>', desc = 'Next uncovered line' },
      { '[cu', '<cmd>CoveragePrevUncovered<cr>', desc = 'Prev uncovered line' },
    },
    cmd = { 'CoverageToggle', 'CoverageSummary', 'CoverageLoad', 'CoverageNextUncovered', 'CoveragePrevUncovered', 'JavaCoverage', 'JaCoCoSummary', 'JacocoDebug' },
    config = function()
      vim.api.nvim_set_hl(0, 'JacocoGreen', { fg = '#50fa7b', bold = true })
      vim.api.nvim_set_hl(0, 'JacocoYellow', { fg = '#f1fa8c', bold = true })
      vim.api.nvim_set_hl(0, 'JacocoRed', { fg = '#ff5555', bold = true })
      vim.api.nvim_set_hl(0, 'JacocoNA', { fg = '#6272a4' })
      vim.api.nvim_set_hl(0, 'JacocoHeader', { fg = '#8be9fd', bold = true })
      vim.api.nvim_set_hl(0, 'JacocoSep', { fg = '#44475a' })
      vim.api.nvim_set_hl(0, 'JacocoDrill', { fg = '#bd93f9' })

      local jacoco_parser = require('custom.jacoco_parser')
      require('crazy-coverage.parser').register_parser('jacoco', jacoco_parser)

      local orig_detect = require('crazy-coverage.utils').detect_format
      require('crazy-coverage.utils').detect_format = function(file_path)
        local name = file_path:match("([^/\\]+)$")
        if name and (name == "jacoco.xml" or name == "jacoco-it.xml" or name:match("^jacoco")) then
          return "jacoco"
        end
        return orig_detect(file_path)
      end

      require('crazy-coverage').setup {
        coverage_dirs = {
          'target/site/jacoco', 'target/site/jacoco-it',
          'bib-backend/target/site/jacoco', 'bib-backend/target/site/jacoco-it',
          'build/reports/jacoco', 'coverage',
        },
        coverage_patterns = {
          java = { 'jacoco.xml', 'jacoco-it.xml', '*.lcov', '*.info', 'coverage.xml' },
          c = { '*.lcov', '*.info', 'coverage.json', 'coverage.xml', '*.profdata' },
          cpp = { '*.lcov', '*.info', 'coverage.json', 'coverage.xml', '*.profdata' },
          rust = { '*.lcov', '*.info', 'coverage.json', 'coverage.xml' },
          go = { 'coverage.out', '*.lcov', '*.info', 'coverage.json', 'coverage.xml' },
        },
        project_markers = { '.git', 'pom.xml', 'build.gradle', 'CMakeLists.txt', 'Makefile', 'go.mod', 'Cargo.toml' },
        hit_count = { show_by_default = true, display = 'eol' },
        show_coverage_in_sign_column = true,
        auto_adapt_colors = true,
      }

      local function find_jacoco_xml()
        local project_root = vim.fn.getcwd()
        local dirs = { 'target/site/jacoco', 'target/site/jacoco-it', 'bib-backend/target/site/jacoco', 'bib-backend/target/site/jacoco-it' }
        for _, dir in ipairs(dirs) do
          for _, name in ipairs({ 'jacoco.xml', 'jacoco-it.xml' }) do
            local path = vim.fs.normalize(project_root .. '/' .. dir .. '/' .. name)
            if vim.fn.filereadable(path) == 1 then return path end
          end
        end
        return nil
      end

      -- JavaCoverage command with enable/disable/toggle
      vim.api.nvim_create_user_command('JavaCoverage', function(opts)
        local args = opts.fargs
        local cc = require('crazy-coverage')

        if args and #args > 0 then
          local subcmd = args[1]:lower()
          if subcmd == 'disable' or subcmd == 'off' then
            cc.disable()
            vim.notify('Coverage disabled', vim.log.levels.INFO)
            return
          elseif subcmd == 'enable' or subcmd == 'on' then
            local found = find_jacoco_xml()
            if found then
              cc.load_coverage(found)
              vim.notify('Coverage enabled', vim.log.levels.INFO)
            else
              vim.notify('No jacoco.xml found. Run :JavaCoverage first to generate.', vim.log.levels.WARN)
            end
            return
          elseif subcmd == 'toggle' then
            cc.toggle()
            return
          end
        end

        -- Default: load/generate coverage
        local found = find_jacoco_xml()
        if not found then
          local project_root = vim.fn.getcwd()
          vim.notify('Generating JaCoCo report...', vim.log.levels.INFO)
          vim.fn.jobstart({ 'mvn', 'jacoco:report', '-q' }, {
            cwd = project_root,
            on_exit = function(_, code)
              local report_path = find_jacoco_xml()
              if code == 0 and report_path then
                vim.schedule(function() cc.load_coverage(report_path) end)
              else
                vim.schedule(function() vim.notify('Failed to generate JaCoCo report (exit ' .. code .. ')', vim.log.levels.ERROR) end)
              end
            end,
          })
          return
        end

        local data = require('custom.jacoco_parser').parse(found, vim.fn.getcwd())
        if data then
          local norm_fn = require('crazy-coverage.utils').normalize_path
          local matched = 0
          for key in pairs(data) do
            local nk = norm_fn(key)
            for _, b in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_loaded(b) then
                local bn = vim.api.nvim_buf_get_name(b)
                if bn ~= '' and nk == norm_fn(bn) then matched = matched + 1; break end
              end
            end
          end
          vim.notify('Coverage: ' .. matched .. '/' .. vim.tbl_count(data) .. ' files rendered', vim.log.levels.INFO)
        end
        require('crazy-coverage').load_coverage(found)
      end, { desc = 'JaCoCo coverage: load/toggle/enable/disable', nargs = '*', complete = function() return { 'enable', 'disable', 'toggle' } end })

      -- Debug command
      vim.api.nvim_create_user_command('JacocoDebug', function()
        local found = find_jacoco_xml()
        if not found then vim.notify('No jacoco.xml found', vim.log.levels.WARN); return end
        local data = require('custom.jacoco_parser').parse(found, vim.fn.getcwd())
        if not data then vim.notify('Failed to parse', vim.log.levels.ERROR); return end
        local norm_fn = require('crazy-coverage.utils').normalize_path
        local keys = vim.tbl_keys(data)
        local bufs = {}
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(b) then
            local name = vim.api.nvim_buf_get_name(b)
            if name ~= '' then table.insert(bufs, { raw = name, norm = norm_fn(name) or name }) end
          end
        end
        local dl = { '=== Coverage Debug ===', '', 'File: ' .. found, 'Keys: ' .. #keys, 'Buffers: ' .. #bufs, '', 'First 5 coverage paths:' }
        for i = 1, math.min(5, #keys) do dl[#dl+1] = '  ' .. (norm_fn(keys[i]) or keys[i]) end
        dl[#dl+1] = ''; dl[#dl+1] = 'Buffer paths:'
        for _, b in ipairs(bufs) do dl[#dl+1] = '  ' .. b.norm end
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, dl)
        vim.api.nvim_buf_set_option(buf, 'modifiable', false)
        vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
        vim.api.nvim_open_win(buf, true, { relative = 'editor', width = 120, height = math.min(#dl+2, 30), col = 5, row = 5, style = 'minimal', border = 'rounded', title = ' JaCoCo Debug ', title_pos = 'center' })
        vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<cr>', { noremap = true, silent = true })
        vim.api.nvim_buf_set_keymap(buf, 'n', '<esc>', '<cmd>close<cr>', { noremap = true, silent = true })
      end, { desc = 'Debug JaCoCo path matching' })

      -- JaCoCo summary tree
      local jacoco_view = { buf = nil, win = nil }

      local function pct(missed, covered)
        local total = missed + covered
        if total == 0 then return -1 end
        return math.floor(covered / total * 100 + 0.5)
      end

      local function pct_str(pct_val)
        if pct_val < 0 then return ' n/a' end
        return string.format('%3d%%', pct_val)
      end

      local function hl_for_pct(pct_val)
        if pct_val < 0 then return 'JacocoNA' end
        if pct_val >= 80 then return 'JacocoGreen' end
        if pct_val >= 50 then return 'JacocoYellow' end
        return 'JacocoRed'
      end

      local function fmt_num(n)
        if n >= 1000 then
          local s = tostring(n); local r = ''; local c = 0
          for i = #s, 1, -1 do
            if c > 0 and c % 3 == 0 then r = ',' .. r end
            r = s:sub(i,i) .. r; c = c + 1
          end
          return r
        end
        return tostring(n)
      end

      local function render_row(name, c, is_dir)
        local display = is_dir and (name .. '/') or name
        if #display > 44 then display = '...' .. display:sub(-41) end
        local ip = pct(c.instr_missed, c.instr_covered)
        local bp = pct(c.branch_missed, c.branch_covered)
        local ci_total = c.cxty_missed + c.cxty_covered
        local ln_total = c.line_missed + c.line_covered
        local mt_total = c.method_missed + c.method_covered
        local cl_total = c.class_missed + c.class_covered
        local line = string.format(' %-44s │%7s │%5s │%7s │%5s │%7s │%7s │%7s │%7s │%7s │%7s │%7s │%7s',
          display,
          fmt_num(c.instr_missed), pct_str(ip),
          fmt_num(c.branch_missed), pct_str(bp),
          fmt_num(c.cxty_missed), fmt_num(ci_total),
          fmt_num(c.line_missed), fmt_num(ln_total),
          fmt_num(c.method_missed), fmt_num(mt_total),
          fmt_num(c.class_missed), fmt_num(cl_total))
        return line, ip
      end

      local HEADER = ' %-44s │%7s │%5s │%7s │%5s │%7s │%7s │%7s │%7s │%7s │%7s │%7s │%7s'
      local HEADER_TEXT = string.format(HEADER, 'Element', 'Missed', 'Cov%', 'Missed', 'Cov%', 'Missed', 'Cxty', 'Missed', 'Lines', 'Missed', 'Methods', 'Missed', 'Classes')
      local SUBHEADER = string.format(' %-44s │ Instr  │      │ Bran  │      │  Cxty │  Cxty │ Lines │ Lines │  Mthd │  Mthd │ Class │ Class', '')

      local show_packages, show_classes, show_methods

      local function clear_keymaps(buf)
        for _, key in ipairs({ '<cr>', '<bs>', '<c-h>', 'H', 'q', '<esc>' }) do
          pcall(vim.api.nvim_buf_del_keymap, buf, 'n', key)
        end
      end

      local function show_view(lines, highlights, title, keymap_fn)
        if jacoco_view.buf and vim.api.nvim_buf_is_valid(jacoco_view.buf) then
          vim.api.nvim_buf_set_option(jacoco_view.buf, 'modifiable', true)
          vim.api.nvim_buf_set_lines(jacoco_view.buf, 0, -1, false, lines)
          vim.api.nvim_buf_set_option(jacoco_view.buf, 'modifiable', false)
          vim.api.nvim_buf_clear_namespace(jacoco_view.buf, -1, 0, -1)
          for _, hl in ipairs(highlights) do
            vim.api.nvim_buf_add_highlight(jacoco_view.buf, -1, hl.group, hl.row, hl.col_start, hl.col_end)
          end
          clear_keymaps(jacoco_view.buf)
          keymap_fn(jacoco_view.buf)
          vim.api.nvim_win_set_cursor(jacoco_view.win, { math.min(3, #lines), 0 })
          return
        end

        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(buf, 'modifiable', false)
        vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
        vim.api.nvim_buf_set_option(buf, 'filetype', 'jacocosummary')
        for _, hl in ipairs(highlights) do
          vim.api.nvim_buf_add_highlight(buf, -1, hl.group, hl.row, hl.col_start, hl.col_end)
        end

        local width = math.min(vim.o.columns - 2, 140)
        local height = math.min(#lines + 2, vim.o.lines - 4)
        local col = math.floor((vim.o.columns - width) / 2)
        local row = math.floor((vim.o.lines - height) / 2)

        local win = vim.api.nvim_open_win(buf, true, {
          relative = 'editor', width = width, height = height,
          col = col, row = row, style = 'minimal', border = 'rounded',
          title = ' ' .. title .. ' ', title_pos = 'center',
        })
        vim.api.nvim_win_set_option(win, 'number', false)
        vim.api.nvim_win_set_option(win, 'relativenumber', false)
        vim.api.nvim_win_set_option(win, 'cursorline', true)
        vim.api.nvim_win_set_option(win, 'wrap', false)

        jacoco_view.buf = buf
        jacoco_view.win = win
        keymap_fn(buf)
      end

      show_packages = function(tree)
        local lines, highlights = {}, {}
        local t = tree.total
        local row_str, total_ip = render_row('TOTAL', t, false)
        table.insert(lines, HEADER_TEXT)
        table.insert(lines, SUBHEADER)
        local sep = string.rep('─', #row_str)
        table.insert(lines, sep)
        table.insert(highlights, { row = #lines, group = hl_for_pct(total_ip), col_start = 0, col_end = -1 })
        lines[#lines] = ' ' .. row_str
        local total_row = #lines
        table.insert(lines, sep)

        local data_start = #lines + 1
        for _, pkg in ipairs(tree.packages) do
          local line_text, ip = render_row(pkg.name == '' and '(default)' or pkg.name, pkg, true)
          table.insert(lines, line_text)
          table.insert(highlights, { row = #lines - 1, group = hl_for_pct(ip), col_start = 0, col_end = -1 })
        end

        local function keymaps(buf)
          vim.api.nvim_buf_set_keymap(buf, 'n', '<cr>', '', {
            noremap = true, silent = true,
            callback = function()
              local row = vim.api.nvim_win_get_cursor(jacoco_view.win)[1]
              local idx = row - data_start + 1
              if idx < 1 or idx > #tree.packages then return end
              show_classes(tree.packages[idx], tree)
            end,
          })
          vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<cr>', { noremap = true, silent = true })
          vim.api.nvim_buf_set_keymap(buf, 'n', '<esc>', '<cmd>close<cr>', { noremap = true, silent = true })
        end

        show_view(lines, highlights, 'JaCoCo: Packages ─ Enter=drill, q/Esc=close', keymaps)
      end

      show_classes = function(pkg, tree)
        local lines, highlights = {}, {}
        table.insert(lines, HEADER_TEXT)
        table.insert(lines, SUBHEADER)

        local data_start = #lines + 1
        for _, cls in ipairs(pkg.children) do
          local display = cls.name
          local prefix = pkg.name:gsub("/", ".") .. "."
          if display:sub(1, #prefix) == prefix then display = display:sub(#prefix + 1) end
          local line_text, ip = render_row(display, cls, false)
          table.insert(lines, line_text)
          table.insert(highlights, { row = #lines - 1, group = hl_for_pct(ip), col_start = 0, col_end = -1 })
        end

        local function keymaps(buf)
          vim.api.nvim_buf_set_keymap(buf, 'n', '<cr>', '', {
            noremap = true, silent = true,
            callback = function()
              local row = vim.api.nvim_win_get_cursor(jacoco_view.win)[1]
              local idx = row - data_start + 1
              if idx < 1 or idx > #pkg.children then return end
              local cls = pkg.children[idx]
              if cls.file_path then
                local fp = cls.file_path:gsub("/", "\\")
                if vim.fn.filereadable(fp) == 1 or vim.fn.filereadable(cls.file_path) == 1 then
                  vim.cmd('close')
                  vim.cmd('edit ' .. vim.fn.fnameescape(cls.file_path))
                  local found = find_jacoco_xml()
                  if found then require('crazy-coverage').load_coverage(found) end
                  return
                end
              end
              if #cls.children > 0 then show_methods(cls, pkg, tree) end
            end,
          })
          vim.api.nvim_buf_set_keymap(buf, 'n', '<bs>', '', { noremap = true, silent = true, callback = function() show_packages(tree) end })
          vim.api.nvim_buf_set_keymap(buf, 'n', '<c-h>', '', { noremap = true, silent = true, callback = function() show_packages(tree) end })
          vim.api.nvim_buf_set_keymap(buf, 'n', 'H', '', { noremap = true, silent = true, callback = function() show_packages(tree) end })
          vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<cr>', { noremap = true, silent = true })
          vim.api.nvim_buf_set_keymap(buf, 'n', '<esc>', '<cmd>close<cr>', { noremap = true, silent = true })
        end

        show_view(lines, highlights, 'JaCoCo: ' .. pkg.name .. ' ─ Enter=open, H/BS=back', keymaps)
      end

      show_methods = function(cls, pkg, tree)
        local lines, highlights = {}, {}
        table.insert(lines, HEADER_TEXT)
        table.insert(lines, SUBHEADER)

        local data_start = #lines + 1
        for _, method in ipairs(cls.children) do
          local display = method.display
          if #display > 44 then display = '...' .. display:sub(-41) end
          local line_text, ip = render_row(display, method, false)
          table.insert(lines, line_text)
          table.insert(highlights, { row = #lines - 1, group = hl_for_pct(ip), col_start = 0, col_end = -1 })
        end

        local function keymaps(buf)
          vim.api.nvim_buf_set_keymap(buf, 'n', '<bs>', '', { noremap = true, silent = true, callback = function() show_classes(pkg, tree) end })
          vim.api.nvim_buf_set_keymap(buf, 'n', '<c-h>', '', { noremap = true, silent = true, callback = function() show_classes(pkg, tree) end })
          vim.api.nvim_buf_set_keymap(buf, 'n', 'H', '', { noremap = true, silent = true, callback = function() show_classes(pkg, tree) end })
          vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<cr>', { noremap = true, silent = true })
          vim.api.nvim_buf_set_keymap(buf, 'n', '<esc>', '<cmd>close<cr>', { noremap = true, silent = true })
        end

        show_view(lines, highlights, 'JaCoCo: ' .. cls.name .. ' ─ H/BS=back', keymaps)
      end

      vim.api.nvim_create_user_command('JaCoCoSummary', function()
        local found = find_jacoco_xml()
        if not found then
          vim.notify('No jacoco.xml found. Run :JavaCoverage first.', vim.log.levels.WARN)
          return
        end
        local tree = jacoco_parser.tree(found)
        if not tree or not tree.packages or #tree.packages == 0 then
          vim.notify('No coverage data found in ' .. found, vim.log.levels.WARN)
          return
        end
        jacoco_view.stack = {}
        show_packages(tree)
      end, { desc = 'Show JaCoCo coverage summary per class' })
    end,
  },
}