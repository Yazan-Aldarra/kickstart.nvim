local M = {}
local jacoco_parser = require('custom.jacoco_parser')

local ns = vim.api.nvim_create_namespace('jacoco_coverage')

local state = {
  coverage_data = nil,
  coverage_file = nil,
  project_root = nil,
  is_enabled = false,
  buf_data = {},
}

local function normalize_path(path)
  if not path or path == "" then return nil end
  local p = vim.fn.fnamemodify(path, ":p")
  if p == "" then return nil end
  p = p:gsub("\\", "/")
  p = p:gsub("/+", "/")
  if p:sub(-1) == "/" and p:len() > 1 then p = p:sub(1, -2) end
  return p
end

local function find_buffer_by_path(path)
  local norm = normalize_path(path)
  if not norm then return nil end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local bn = normalize_path(vim.api.nvim_buf_get_name(buf))
      if bn and bn == norm then return buf end
    end
  end
  return nil
end

local function setup_highlights()
  vim.api.nvim_set_hl(0, 'JacocoCovSign',      { fg = '#50fa7b', bold = true })
  vim.api.nvim_set_hl(0, 'JacocoUncovSign',    { fg = '#ff5555', bold = true })
  vim.api.nvim_set_hl(0, 'JacocoPartialSign',   { fg = '#f1fa8c', bold = true })
  vim.api.nvim_set_hl(0, 'JacocoHitCount',     { fg = '#8be9fd' })
end

local function compute_line_state(line_info, branches)
  local hits = line_info.hits or 0
  local branch_total, branch_taken = 0, 0

  if branches then
    for _, br in ipairs(branches) do
      branch_total = branch_total + 1
      if (br.hit_count or 0) > 0 then branch_taken = branch_taken + 1 end
    end
  end

  if branch_total > 0 then
    if branch_taken == 0 then
      return 'uncovered', hits, branch_taken, branch_total
    elseif branch_taken < branch_total then
      return 'partial', hits, branch_taken, branch_total
    else
      return 'covered', hits, branch_taken, branch_total
    end
  end

  if hits > 0 then
    return 'covered', hits, 0, 0
  end
  return 'uncovered', hits, 0, 0
end

local sign_hl_map = {
  covered  = 'JacocoCovSign',
  uncovered = 'JacocoUncovSign',
  partial  = 'JacocoPartialSign',
}

function M.render_file(buf, file_entry)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
  if not file_entry or type(file_entry) ~= 'table' then return end
  if (not file_entry.lines or #file_entry.lines == 0) and
     (not file_entry.branches or #file_entry.branches == 0) then return end

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local branch_map = {}
  for _, br in ipairs(file_entry.branches or {}) do
    local arr = branch_map[br.line]
    if not arr then arr = {} branch_map[br.line] = arr end
    table.insert(arr, br)
  end

  for _, line_info in ipairs(file_entry.lines or {}) do
    local line_num = line_info.line
    local branches = branch_map[line_num]
    local cov_state, hits, branch_taken, branch_total = compute_line_state(line_info, branches)

    local sign_hl = sign_hl_map[cov_state]

    local virt_text = {}
    if hits > 0 then
      table.insert(virt_text, { tostring(hits) .. 'x', sign_hl })
    end
    if branch_total > 0 then
      local bt = branch_taken .. '/' .. branch_total
      if #virt_text > 0 then
        table.insert(virt_text, { ' ' .. bt, sign_hl })
      else
        table.insert(virt_text, { bt, sign_hl })
      end
    end

    local opts = {
      priority = 200,
      strict = false,
      sign_text = '▌',
      sign_hl_group = sign_hl,
    }
    if #virt_text > 0 then
      opts.virt_text = virt_text
      opts.virt_text_pos = 'eol'
    end

    pcall(vim.api.nvim_buf_set_extmark, buf, ns, line_num - 1, 0, opts)
  end
end

function M.render_all()
  if not state.coverage_data then return 0 end
  local rendered = 0
  for file_path, file_entry in pairs(state.coverage_data) do
    local buf = find_buffer_by_path(file_path)
    if buf then
      M.render_file(buf, file_entry)
      rendered = rendered + 1
    end
  end
  return rendered
end

function M.load(file_path, project_root)
  if not file_path or file_path == "" then
    vim.notify('No JaCoCo file path provided', vim.log.levels.ERROR)
    return false
  end
  if vim.fn.filereadable(file_path) ~= 1 then
    vim.notify('JaCoCo file not found: ' .. file_path, vim.log.levels.ERROR)
    return false
  end

  if not project_root then
    project_root = vim.fn.getcwd()
  end

  M.clear_all()
  state.coverage_data = jacoco_parser.parse(file_path, project_root)
  if not state.coverage_data then
    vim.notify('Failed to parse JaCoCo file: ' .. file_path, vim.log.levels.ERROR)
    return false
  end

  state.coverage_file = file_path
  state.project_root = project_root
  state.is_enabled = true

  local total = 0
  for _ in pairs(state.coverage_data) do total = total + 1 end
  local rendered = M.render_all()
  vim.notify(string.format('JaCoCo: %d/%d files rendered', rendered, total), vim.log.levels.INFO)
  return true
end

function M.clear_buffer(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
end

function M.clear_all()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      M.clear_buffer(buf)
    end
  end
end

function M.disable()
  M.clear_all()
  state.is_enabled = false
  vim.notify('JaCoCo coverage disabled', vim.log.levels.INFO)
end

function M.enable()
  if state.coverage_data then
    state.is_enabled = true
    local rendered = M.render_all()
    local total = 0
    for _ in pairs(state.coverage_data) do total = total + 1 end
    vim.notify(string.format('JaCoCo: %d/%d files rendered', rendered, total), vim.log.levels.INFO)
  else
    vim.notify('No JaCoCo data loaded. Run :JavaCoverage first.', vim.log.levels.WARN)
  end
end

function M.toggle()
  if state.is_enabled then
    M.disable()
  else
    M.enable()
  end
end

function M.is_enabled()
  return state.is_enabled
end

function M.get_coverage_for_buffer(buf)
  if not state.coverage_data then return nil end
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then return nil end
  local buf_path = normalize_path(vim.api.nvim_buf_get_name(buf))
  if not buf_path then return nil end

  for file_path, file_entry in pairs(state.coverage_data) do
    local norm = normalize_path(file_path)
    if norm and norm == buf_path then return file_entry end
  end
  return nil
end

function M.next_uncovered()
  if not state.is_enabled or not state.coverage_data then
    vim.notify('No JaCoCo data loaded. Run :JavaCoverage first.', vim.log.levels.WARN)
    return false
  end

  local file_entry = M.get_coverage_for_buffer()
  if not file_entry or not file_entry.lines or #file_entry.lines == 0 then
    vim.notify('No coverage data for current file', vim.log.levels.WARN)
    return false
  end

  local branch_map = {}
  for _, br in ipairs(file_entry.branches or {}) do
    local arr = branch_map[br.line]
    if not arr then arr = {} branch_map[br.line] = arr end
    table.insert(arr, br)
  end

  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local uncovered = {}

  for _, line_info in ipairs(file_entry.lines) do
    local branches = branch_map[line_info.line]
    local cov_state = compute_line_state(line_info, branches)
    if cov_state == 'uncovered' or cov_state == 'partial' then
      table.insert(uncovered, line_info.line)
    end
  end

  table.sort(uncovered)

  for _, line in ipairs(uncovered) do
    if line > current_line then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
      vim.cmd('normal! zz')
      return true
    end
  end

  if #uncovered > 0 then
    vim.api.nvim_win_set_cursor(0, { uncovered[1], 0 })
    vim.cmd('normal! zz')
    return true
  end

  vim.notify('No uncovered lines in current file', vim.log.levels.INFO)
  return false
end

function M.prev_uncovered()
  if not state.is_enabled or not state.coverage_data then
    vim.notify('No JaCoCo data loaded. Run :JavaCoverage first.', vim.log.levels.WARN)
    return false
  end

  local file_entry = M.get_coverage_for_buffer()
  if not file_entry or not file_entry.lines or #file_entry.lines == 0 then
    vim.notify('No coverage data for current file', vim.log.levels.WARN)
    return false
  end

  local branch_map = {}
  for _, br in ipairs(file_entry.branches or {}) do
    local arr = branch_map[br.line]
    if not arr then arr = {} branch_map[br.line] = arr end
    table.insert(arr, br)
  end

  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local uncovered = {}

  for _, line_info in ipairs(file_entry.lines) do
    local branches = branch_map[line_info.line]
    local cov_state = compute_line_state(line_info, branches)
    if cov_state == 'uncovered' or cov_state == 'partial' then
      table.insert(uncovered, line_info.line)
    end
  end

  table.sort(uncovered)

  for i = #uncovered, 1, -1 do
    if uncovered[i] < current_line then
      vim.api.nvim_win_set_cursor(0, { uncovered[i], 0 })
      vim.cmd('normal! zz')
      return true
    end
  end

  if #uncovered > 0 then
    vim.api.nvim_win_set_cursor(0, { uncovered[#uncovered], 0 })
    vim.cmd('normal! zz')
    return true
  end

  vim.notify('No uncovered lines in current file', vim.log.levels.INFO)
  return false
end

function M.count_matches()
  if not state.coverage_data then return 0, 0 end
  local total, matched = 0, 0
  for file_path in pairs(state.coverage_data) do
    total = total + 1
    if find_buffer_by_path(file_path) then matched = matched + 1 end
  end
  return matched, total
end

setup_highlights()
vim.api.nvim_create_augroup('JacocoCoverageHighlights', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
  group = 'JacocoCoverageHighlights',
  pattern = '*',
  callback = setup_highlights,
})

vim.api.nvim_create_augroup('JacocoAutoRender', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
  group = 'JacocoAutoRender',
  callback = function(args)
    if not state.is_enabled or not state.coverage_data then return end
    local buf = args.buf
    if not buf or not vim.api.nvim_buf_is_loaded(buf) then return end
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then return end
    local buf_path = normalize_path(name)
    if not buf_path then return end
    for file_path, file_entry in pairs(state.coverage_data) do
      if normalize_path(file_path) == buf_path then
        M.render_file(buf, file_entry)
        break
      end
    end
  end,
})

M.normalize_path = normalize_path

return M