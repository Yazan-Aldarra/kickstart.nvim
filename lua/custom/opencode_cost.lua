local M = {}

local multipliers = {
  ['gemini-2.5-pro'] = 1,
  ['gpt-5-mini'] = 0,
  ['gpt-5.3-codex'] = 1,
  ['claude-opus-4.6'] = 'upgrade',
  ['claude-sonnet-4.6'] = 'upgrade',
  ['gpt-5.4'] = 'upgrade',
  ['claude-haiku-4.5'] = 0.33,
  ['gemini-3-flash-preview'] = 0.33,
  ['gemini-3.1-pro-preview'] = 1,
  ['gpt-4.1'] = 0,
  ['gpt-4o'] = 0,
  ['gpt-5.1'] = 1,
  ['gpt-5.2'] = 1,
  ['gpt-5.2-codex'] = 1,
  ['gpt-5.4-mini'] = 0.33,
  ['grok-code-fast-1'] = 0.25,
  ['raptor-mini-preview'] = 0,
}

local function normalize_mult(mult)
  if mult == 'upgrade' or mult == 'Upgrade' then return math.huge end
  return mult
end

function M.list()
  local lines = {}
  table.insert(lines, 'Opencode Models:')

  for model, mult in pairs(multipliers) do
    local value = normalize_mult(mult)

    local label
    if value == math.huge then
      label = 'Upgrade required'
    else
      label = tostring(value) .. '×'
    end

    local warning = (type(value) == 'number' and value >= 10) and ' ⚠️' or ''

    table.insert(lines, string.format('- %-20s → %s%s', model, label, warning))
  end

  table.insert(lines, '')
  table.insert(lines, 'Total known models: ' .. vim.tbl_count(multipliers))

  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
end

return M
