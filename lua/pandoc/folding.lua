-- Pandoc and markdown folds for Neovim. Same rules as autoload/pandoc/folding9.vim.
-- A plain line is skipped. Marker lines use the Vim patterns.

local M = {}

local cached_buf = -1
local cached_tick = -2
local cached_n = -1
local cached_sig = ''
local cached_levels = {}

local heading_pat = [=[^#\{1,6}[^.]]=]
local hashes_pat = [[^#\{1,6}]]
local title_pat = [[^[^-=].\+$]]
local h1_pat = [[^=\+$]]
local h2_pat = [[^-\+$]]
local opener_pat = [[^\s*\zs\%(`\{3,}\|\~\{3,}\)]]
local delim_pat = [[^\%(---\|\.\.\.\)$]]
local blank_pat = [[^\s*$]]
local fold_begin_pat = [[\c^<!--.*fold-begin -->]]
local fold_end_pat = [[\c^<!--.*fold-end -->]]

local function flag(name, default)
  local value = vim.g[name]
  if value == nil then
    return default
  end
  return value ~= 0
end

local function heading(mode, stack, level)
  if mode == 'stacked' then
    return '>1'
  end
  if mode == 'relative' then
    while #stack > 0 and stack[#stack] >= level do
      table.remove(stack)
    end
    stack[#stack + 1] = level
    return '>' .. #stack
  end
  return '>' .. level
end

local function marker(line, mark_head)
  if vim.fn.match(line, mark_head .. [[{\{3}]]) >= 0 then
    local level = vim.fn.matchstr(line, [[\({\{3}\)\@<=\d]])
    if level ~= '' then
      return '>' .. level
    end
    return 'a1'
  end
  if vim.fn.match(line, mark_head .. [[}\{3}]]) >= 0 then
    local level = vim.fn.matchstr(line, [[\(}\{3}\)\@<=\d]])
    if level ~= '' then
      return '<' .. level
    end
    return 's1'
  end
  return nil
end

local function scan(lines)
  local fold_yaml = flag('pandoc#folding#fold_yaml', false)
  local yaml_level = tostring(vim.g['pandoc#folding#foldlevel_yaml'] or 1)
  local fold_fence = flag('pandoc#folding#fold_fenced_codeblocks', false)
  local fold_markers = flag('pandoc#folding#fold_vim_markers', true)
  local markers_in_comments = flag('pandoc#folding#vim_markers_in_comments_only', true)
  local mode = vim.g['pandoc#folding#mode'] or 'syntax'
  local classes = vim.g['pandoc#folding#fold_div_classes']
  if classes == nil then
    classes = { 'notes' }
  end
  local div_re = nil
  if #classes > 0 then
    div_re = vim.regex('\\c<div class=.\\%(' .. table.concat(classes, '\\|') .. '\\)')
  end
  local mark_head = markers_in_comments and '<!--.*' or ''

  local out = {}
  local stack = {}
  local in_front = false
  local in_yaml = false
  local fence_char = ''
  local close_re = nil
  local n = #lines

  for i = 1, n do
    local line = lines[i]
    local prev = i == 1 and '' or lines[i - 1]
    out[i] = '='
    if in_front then
      if vim.fn.match(line, delim_pat) >= 0 then
        if fold_yaml then
          out[i] = '<' .. yaml_level
        end
        in_front = false
      end
    elseif i == 1 and line == '---' then
      in_front = true
      if fold_yaml then
        out[i] = '>' .. yaml_level
      end
    else
      local claimed = false
      if div_re ~= nil and div_re:match_str(line) ~= nil then
        out[i] = 'a1'
        claimed = true
      elseif line:lower():find('</div endfold>', 1, true) then
        out[i] = 's1'
        claimed = true
      elseif fold_markers then
        local mark = marker(line, mark_head)
        if mark ~= nil then
          out[i] = mark
          claimed = true
        end
      end

      if fence_char ~= '' then
        if close_re ~= nil and close_re:match_str(line) ~= nil then
          if fold_fence and not claimed then
            out[i] = 's1'
          end
          fence_char = ''
          close_re = nil
        elseif not claimed and vim.fn.match(line, fold_begin_pat) >= 0 then
          out[i] = 'a1'
        elseif not claimed and vim.fn.match(line, fold_end_pat) >= 0 then
          out[i] = 's1'
        end
      elseif vim.fn.match(line, delim_pat) >= 0 and (vim.fn.match(prev, blank_pat) >= 0 or in_yaml) then
        in_yaml = not in_yaml
      elseif in_yaml or claimed then
        -- A heading inside a YAML document stays at the surrounding level.
      else
        local next_line = i < n and lines[i + 1] or ''
        local first = line:sub(1, 1)
        local n0 = next_line:sub(1, 1)
        local plain = first ~= '#' and first ~= '`' and first ~= '~' and first ~= ' ' and first ~= '\t' and first ~= '<'
          and line:find('<', 1, true) == nil and line:find('{', 1, true) == nil and line:find('}', 1, true) == nil
          and n0 ~= '=' and n0 ~= '-'
        if not plain then
          local opener = vim.fn.matchstr(line, opener_pat)
          if opener ~= '' then
            fence_char = opener:sub(1, 1)
            close_re = vim.regex('^\\s*' .. fence_char .. '\\{' .. #opener .. ',}\\s*$')
            if fold_fence then
              out[i] = 'a1'
            end
          elseif vim.fn.match(line, heading_pat) >= 0 then
            local level = #vim.fn.matchstr(line, hashes_pat)
            out[i] = heading(mode, stack, level)
          elseif vim.fn.match(line, title_pat) >= 0 and vim.fn.match(next_line, h1_pat) >= 0 then
            out[i] = heading(mode, stack, 1)
          elseif vim.fn.match(line, title_pat) >= 0 and vim.fn.match(next_line, h2_pat) >= 0 then
            out[i] = heading(mode, stack, 2)
          elseif vim.fn.match(line, fold_begin_pat) >= 0 then
            out[i] = 'a1'
          elseif vim.fn.match(line, fold_end_pat) >= 0 then
            out[i] = 's1'
          end
        end
      end
    end
  end
  return out
end

local function signature()
  local classes = vim.g['pandoc#folding#fold_div_classes']
  if classes == nil then
    classes = { 'notes' }
  end
  return table.concat({
    vim.g['pandoc#folding#mode'] or 'syntax',
    tostring(vim.g['pandoc#folding#fold_yaml'] or 0),
    tostring(vim.g['pandoc#folding#foldlevel_yaml'] or 1),
    tostring(vim.g['pandoc#folding#fold_fenced_codeblocks'] or 0),
    tostring(vim.g['pandoc#folding#fold_vim_markers'] == nil and 1 or vim.g['pandoc#folding#fold_vim_markers']),
    tostring(vim.g['pandoc#folding#vim_markers_in_comments_only'] == nil and 1 or vim.g['pandoc#folding#vim_markers_in_comments_only']),
    table.concat(vim.tbl_map(tostring, classes), ','),
  }, ':')
end

local function ensure()
  local buf = vim.fn.bufnr('%')
  local tick = vim.b.changedtick
  local n = vim.fn.line('$')
  local sig = signature()
  if cached_buf == buf and cached_tick == tick and cached_n == n and cached_sig == sig then
    return
  end
  cached_levels = scan(vim.fn.getline(1, '$'))
  cached_buf = buf
  cached_tick = tick
  cached_n = n
  cached_sig = sig
end

function M.expr()
  ensure()
  return cached_levels[vim.v.lnum] or '='
end

return M
