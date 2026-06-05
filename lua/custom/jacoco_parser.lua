local M = {}

local function normalize_path(path)
  if not path or path == "" then return nil end
  local normalized = vim.fn.fnamemodify(path, ":p")
  if normalized == "" then return nil end
  normalized = normalized:gsub("\\", "/")
  normalized = normalized:gsub("/+", "/")
  if normalized:sub(-1) == "/" and normalized:len() > 1 then
    normalized = normalized:sub(1, -2)
  end
  return normalized
end

local function find_maven_root(start_dir, max_depth)
  local dir = start_dir
  for _ = 1, max_depth or 10 do
    if dir == "" or dir == "/" then break end
    local dir_norm = dir:gsub("\\", "/")
    if vim.fn.filereadable(dir_norm .. "/pom.xml") == 1
      or vim.fn.filereadable(dir_norm .. "/build.gradle") == 1 then
      return dir_norm
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then break end
    dir = parent
  end
  return nil
end

local function resolve_jacoco_path(package_name, sourcefile_name, project_root, coverage_dir)
  local relative = package_name and package_name ~= ""
      and (package_name .. "/" .. sourcefile_name)
      or sourcefile_name

  local module_root = find_maven_root(coverage_dir, 6) or project_root
  local candidates = {
    module_root .. "/src/main/java/" .. relative,
    module_root .. "/src/test/java/" .. relative,
    project_root .. "/src/main/java/" .. relative,
    project_root .. "/src/test/java/" .. relative,
  }

  for _, candidate in ipairs(candidates) do
    local norm = normalize_path(candidate)
    if norm and vim.fn.filereadable(norm) == 1 then
      return norm
    end
  end

  return normalize_path(module_root .. "/src/main/java/" .. relative)
end

function M.parse(file_path, project_root)
  if not file_path or file_path == "" then return nil end

  local lines = vim.fn.readfile(file_path)
  if not lines or #lines == 0 then return nil end

  local content = table.concat(lines, "\n")
  local coverage_dir = normalize_path(vim.fn.fnamemodify(file_path, ":p:h"))
  if not project_root then
    project_root = normalize_path(vim.fn.fnamemodify(file_path, ":p:h:h:h:h:h"))
  end
  project_root = project_root and project_root:gsub("\\", "/") or nil

  local coverage_data = {}

  for package_name, package_content in content:gmatch('<package%s+name="([^"]*)"[^>]*>(.-)</package>') do
    for sourcefile_attrs, sourcefile_content in package_content:gmatch('<sourcefile%s+([^>]+)>(.-)</sourcefile>') do
      local sourcefile_name = sourcefile_attrs:match('name="([^"]+)"')
      if not sourcefile_name then goto continue_sf end

      local resolved_path = resolve_jacoco_path(package_name, sourcefile_name, project_root, coverage_dir)
      if not resolved_path then goto continue_sf end

      if not coverage_data[resolved_path] then
        coverage_data[resolved_path] = { lines = {}, branches = {}, path = resolved_path }
      end

      local file_entry = coverage_data[resolved_path]

      for line_attrs in sourcefile_content:gmatch('<line%s+([^/]-)/?>') do
        local nr = tonumber(line_attrs:match('nr="(%d+)"'))
        local ci = tonumber(line_attrs:match('ci="(%d+)"')) or 0
        local mi = tonumber(line_attrs:match('mi="(%d+)"')) or 0
        local mb = tonumber(line_attrs:match('mb="(%d+)"')) or 0
        local cb = tonumber(line_attrs:match('cb="(%d+)"')) or 0

        if nr then
          local hits = ci > 0 and ci or 0
          table.insert(file_entry.lines, { line = nr, hits = hits })
          if (mb + cb) > 0 then
            for _ = 1, cb do
              table.insert(file_entry.branches, { line = nr, hit_count = 1 })
            end
            for _ = 1, mb do
              table.insert(file_entry.branches, { line = nr, hit_count = 0 })
            end
          end
        end
      end
      ::continue_sf::
    end
  end

  return coverage_data
end

local function parse_counters(text)
  local c = {
    instr_missed = 0, instr_covered = 0,
    branch_missed = 0, branch_covered = 0,
    cxty_missed = 0, cxty_covered = 0,
    line_missed = 0, line_covered = 0,
    method_missed = 0, method_covered = 0,
    class_missed = 0, class_covered = 0,
  }
  for ct, m, cv in text:gmatch('<counter%s+type="([^"]+)"%s+missed="(%d+)"%s+covered="(%d+)"%s*/>') do
    local mm, cc = tonumber(m), tonumber(cv)
    if ct == "INSTRUCTION" then c.instr_missed = mm c.instr_covered = cc
    elseif ct == "BRANCH" then c.branch_missed = mm c.branch_covered = cc
    elseif ct == "COMPLEXITY" then c.cxty_missed = mm c.cxty_covered = cc
    elseif ct == "LINE" then c.line_missed = mm c.line_covered = cc
    elseif ct == "METHOD" then c.method_missed = mm c.method_covered = cc
    elseif ct == "CLASS" then c.class_missed = mm c.class_covered = cc
    end
  end
  return c
end

function M.tree(file_path)
  if not file_path or file_path == "" then return nil end

  local lines = vim.fn.readfile(file_path)
  if not lines or #lines == 0 then return nil end

  local content = table.concat(lines, "\n")
  local project_root = normalize_path(vim.fn.fnamemodify(file_path, ":p:h:h:h:h:h"))
  local coverage_dir = normalize_path(vim.fn.fnamemodify(file_path, ":p:h"))

  local packages = {}

  for pkg_name, pkg_content in content:gmatch('<package%s+name="([^"]*)"[^>]*>(.-)</package>') do
    local pkg = {
      name = pkg_name,
      children = {},
    }
    local c = parse_counters(pkg_content)
    for k, v in pairs(c) do pkg[k] = v end

    if (pkg.line_covered + pkg.line_missed + pkg.instr_covered + pkg.instr_missed) == 0 then
      goto continue_pkg
    end

    for cls_name, cls_content in pkg_content:gmatch('<class%s+name="([^"]*)"[^>]*>(.-)</class>') do
      local sourcefile = cls_content:match('sourcefilename="([^"]*)"')
        or (cls_name:match("([^/]+)$") or cls_name) .. ".java"

      local display_name = cls_name:gsub("/", "."):gsub("%$", ".")

      local cls = {
        name = display_name,
        sourcefile = sourcefile,
        full_class_name = cls_name,
        package = pkg_name,
        file_path = resolve_jacoco_path(pkg_name, sourcefile, project_root, coverage_dir),
        children = {},
      }
      local cc = parse_counters(cls_content)
      for k, v in pairs(cc) do cls[k] = v end

      for m_name, m_desc, m_content in cls_content:gmatch('<method%s+name="([^"]*)"%s+desc="([^"]*)"[^>]*>(.-)</method>') do
        local method = {
          name = m_name,
          desc = m_desc,
          display = m_name .. m_desc:gsub("^%(", "("):gsub("/", "."),
          children = {},
        }
        local mc = parse_counters(m_content)
        for k, v in pairs(mc) do method[k] = v end
        table.insert(cls.children, method)
      end

      table.sort(cls.children, function(a, b) return a.name < b.name end)
      table.insert(pkg.children, cls)
    end

    table.sort(pkg.children, function(a, b) return a.name < b.name end)
    table.insert(packages, pkg)
    ::continue_pkg::
  end

  table.sort(packages, function(a, b) return a.name < b.name end)

  local top_level = parse_counters(content)

  return {
    packages = packages,
    total = top_level,
  }
end

return M