local M = {}

-- Cache for file content hashing
local content_cache = {}
local cache_size_limit = 100

function M.get_content_hash(content)
  -- Simple hash function for content
  local hash = 0
  for i = 1, #content do
    hash = (hash * 31 + string.byte(content, i)) % 2147483647
  end
  return hash
end

function M.should_trigger_completion(bufnr, content)
  local hash = M.get_content_hash(content)
  local cached_hash = content_cache[bufnr]
  
  if cached_hash == hash then
    return false -- Content hasn't changed meaningfully
  end
  
  -- Update cache
  content_cache[bufnr] = hash
  
  -- Limit cache size
  local cache_keys = vim.tbl_keys(content_cache)
  if #cache_keys > cache_size_limit then
    -- Remove oldest entries (simple FIFO)
    for i = 1, #cache_keys - cache_size_limit do
      content_cache[cache_keys[i]] = nil
    end
  end
  
  return true
end

function M.clear_cache(bufnr)
  if bufnr then
    content_cache[bufnr] = nil
  else
    content_cache = {}
  end
end

function M.get_relevant_context(lines, cursor_row, max_lines)
  max_lines = max_lines or 50
  
  local start_line = math.max(1, cursor_row - math.floor(max_lines / 2))
  local end_line = math.min(#lines, start_line + max_lines - 1)
  
  local context_lines = {}
  for i = start_line, end_line do
    table.insert(context_lines, lines[i])
  end
  
  return table.concat(context_lines, "\n")
end

return M
