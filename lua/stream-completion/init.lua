local config = require('stream-completion.config')
local api = require('stream-completion.api')
local ui = require('stream-completion.ui')
local performance = require('stream-completion.performance')

local M = {}

-- State
local enabled = false
local timer = nil
local last_change_time = 0
local debounce_timer = nil

function M.setup(opts)
  config.setup(opts)
  
  -- Set up autocommands
  M.setup_autocmds()
  
  -- Enable by default if configured
  if config.options.auto_trigger then
    M.enable()
  end
end

function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup('StreamCompletion', { clear = true })
  
  -- Clear completions when leaving insert mode
  vim.api.nvim_create_autocmd('InsertLeave', {
    group = group,
    callback = function()
      ui.clear_completion()
      api.cancel_completion()
    end,
  })
  
  -- Handle text changes in insert mode
  vim.api.nvim_create_autocmd('TextChangedI', {
    group = group,
    callback = function()
      if enabled then
        M.on_text_changed()
      end
    end,
  })
  
  -- Clear completions when buffer changes
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function()
      ui.clear_completion()
      api.cancel_completion()
    end,
  })
end

-- Enhanced text change handler
function M.on_text_changed()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[bufnr].filetype
  
  -- Check if filetype is excluded
  if vim.tbl_contains(config.options.exclude_filetypes, filetype) then
    return
  end
  
  -- Check if filetype is allowed (if whitelist is specified)
  if #config.options.filetypes > 0 and not vim.tbl_contains(config.options.filetypes, filetype) then
    return
  end
  
  -- Get current context
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- Convert to 0-based
  
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  
  -- Use performance optimization for context
  local context = performance.get_relevant_context(lines, row + 1, 100)
  
  -- Check if we should trigger completion (performance optimization)
  if not performance.should_trigger_completion(bufnr, context) then
    return
  end
  
  -- Check minimum character requirement
  if #context < config.options.min_chars then
    return
  end
  
  -- Cancel any existing operations
  api.cancel_completion()
  ui.clear_completion()
  
  -- Clear existing timers
  if timer then
    vim.loop.timer_stop(timer)
  end
  if debounce_timer then
    vim.loop.timer_stop(debounce_timer)
  end
  
  last_change_time = vim.loop.now()
  
  -- Set up debounced completion request
  debounce_timer = vim.loop.new_timer()
  debounce_timer:start(config.options.debounce_ms, 0, vim.schedule_wrap(function()
    -- Check if text changed during debounce period
    local current_time = vim.loop.now()
    if current_time - last_change_time < config.options.debounce_ms then
      return
    end
    
    -- Set up delayed completion request
    timer = vim.loop.new_timer()
    timer:start(config.options.delay_ms, 0, vim.schedule_wrap(function()
      M.request_completion(context, row, col, bufnr)
    end))
  end))
end

function M.request_completion(text, row, col, bufnr)
  -- Verify we're still in the same buffer and position is still valid
  if vim.api.nvim_get_current_buf() ~= bufnr then
    return
  end
  
  api.get_completion(text, function(completion)
    vim.schedule(function()
      -- Double-check we're still in the right context
      if vim.api.nvim_get_current_buf() == bufnr then
        ui.show_completion(completion, row, col, bufnr)
      end
    end)
  end)
end

function M.enable()
  enabled = true
  vim.notify("Stream Completion enabled", vim.log.levels.INFO)
end

function M.disable()
  enabled = false
  ui.clear_completion()
  api.cancel_completion()
  vim.notify("Stream Completion disabled", vim.log.levels.INFO)
end

function M.toggle()
  if enabled then
    M.disable()
  else
    M.enable()
  end
end

function M.accept_completion()
  return ui.accept_completion()
end

function M.reject_completion()
  ui.clear_completion()
  api.cancel_completion()
end

function M.is_enabled()
  return enabled
end

-- Status function
function M.status()
  local status = {
    enabled = enabled,
    api_key_set = config.options.api_key ~= "your_api_key_here",
    current_completion = ui.get_current_completion() ~= "",
    excluded_ft = vim.tbl_contains(config.options.exclude_filetypes, vim.bo.filetype)
  }
  
  print("Stream Completion Status:")
  print("  Enabled: " .. (status.enabled and "✓" or "✗"))
  print("  API Key: " .. (status.api_key_set and "✓" or "✗"))
  print("  Active Completion: " .. (status.current_completion and "✓" or "✗"))
  print("  Current Filetype: " .. vim.bo.filetype)
  print("  Filetype Excluded: " .. (status.excluded_ft and "✓" or "✗"))
  
  return status
end

-- Manual completion trigger
function M.complete_now()
  if not enabled then
    vim.notify("Stream Completion is disabled", vim.log.levels.WARN)
    return
  end
  
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local context = performance.get_relevant_context(lines, row + 1, 100)
  
  M.request_completion(context, row, col, bufnr)
end

return M
