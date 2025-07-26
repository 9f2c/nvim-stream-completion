local config = require('stream-completion.config')

local M = {}

-- State
local completion_ns = vim.api.nvim_create_namespace('stream_completion')
local current_completion = ""
local completion_row = 0
local completion_col = 0
local completion_bufnr = 0

function M.clear_completion()
  if completion_bufnr and vim.api.nvim_buf_is_valid(completion_bufnr) then
    vim.api.nvim_buf_clear_namespace(completion_bufnr, completion_ns, 0, -1)
  end
  current_completion = ""
end

function M.show_completion(text, row, col, bufnr)
  if not text or text == "" then
    M.clear_completion()
    return
  end
  
  -- Clear previous completion
  M.clear_completion()
  
  -- Store current completion info
  current_completion = text
  completion_row = row
  completion_col = col
  completion_bufnr = bufnr
  
  -- Split completion into lines
  local lines = vim.split(text, "\n")
  
  -- Show virtual text for each line
  for i, line in ipairs(lines) do
    local display_row = row + i - 1
    local display_col = i == 1 and col or 0
    local prefix = i == 1 and config.options.virtual_text_prefix or "  "
    
    if line and line ~= "" then
      vim.api.nvim_buf_set_extmark(bufnr, completion_ns, display_row, display_col, {
        virt_text = { { prefix .. line, config.options.highlight_group } },
        virt_text_pos = "eol",
        ephemeral = false,
      })
    end
  end
end

function M.accept_completion()
  if current_completion == "" then
    return false
  end
  
  -- Get current cursor position (not stored position)
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- Convert to 0-based indexing
  
  -- Clear the virtual text first
  M.clear_completion()
  
  -- Get current line
  local lines = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)
  if #lines == 0 then
    return false
  end
  
  local current_line = lines[1]
  
  -- Insert completion at current cursor position
  local before_cursor = current_line:sub(1, col)
  local after_cursor = current_line:sub(col + 1)
  local new_text = before_cursor .. current_completion .. after_cursor
  
  -- Split by newlines and set lines
  local new_lines = vim.split(new_text, "\n")
  vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, new_lines)
  
  -- Move cursor to end of inserted completion
  local completion_lines = vim.split(current_completion, "\n")
  local final_row = row + #completion_lines - 1
  local final_col
  
  if #completion_lines == 1 then
    -- Single line completion
    final_col = col + #current_completion
  else
    -- Multi-line completion
    final_col = #completion_lines[#completion_lines]
  end
  
  vim.api.nvim_win_set_cursor(0, { final_row + 1, final_col })
  
  return true
end

function M.get_current_completion()
  return current_completion
end

function M.show_completion_popup(text, row, col, bufnr)
  if not config.options.show_border then
    return M.show_completion(text, row, col, bufnr)
  end
  
  local lines = vim.split(text, "\n")
  if #lines == 0 then return end
  
  -- Calculate popup dimensions
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.min(width + 4, vim.o.columns - 10)
  
  local height = math.min(#lines + 2, vim.o.lines - 10)
  
  -- Create popup buffer
  local popup_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(popup_bufnr, 0, -1, false, lines)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(popup_bufnr, 'modifiable', false)
  vim.api.nvim_buf_set_option(popup_bufnr, 'filetype', 'streamcompletion')
  
  -- Calculate position
  local win_config = {
    relative = 'cursor',
    width = width,
    height = height,
    row = 1,
    col = 0,
    style = 'minimal',
    border = 'rounded',
    title = ' Completion ',
    title_pos = 'center',
  }
  
  -- Create window
  local win_id = vim.api.nvim_open_win(popup_bufnr, false, win_config)
  
  -- Set window options
  vim.api.nvim_win_set_option(win_id, 'winhl', 'Normal:StreamCompletionPopup,FloatBorder:StreamCompletionBorder')
  
  -- Store for cleanup
  M.popup_win = win_id
  M.popup_buf = popup_bufnr
  
  return win_id
end

function M.close_popup()
  if M.popup_win and vim.api.nvim_win_is_valid(M.popup_win) then
    vim.api.nvim_win_close(M.popup_win, true)
  end
  if M.popup_buf and vim.api.nvim_buf_is_valid(M.popup_buf) then
    vim.api.nvim_buf_delete(M.popup_buf, { force = true })
  end
  M.popup_win = nil
  M.popup_buf = nil
end

return M
