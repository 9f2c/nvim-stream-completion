local M = {}

M.defaults = {
  -- API Configuration
  api_key = os.getenv("OPENAI_API_KEY") or "your_api_key_here",
  api_url = "http://127.0.0.1:1234/v1/chat/completions",
  model = "whatever",
  
  -- Completion settings
  max_tokens = 100,
  temperature = 0.3,
  delay_ms = 1000, -- Delay before making API request
  
  -- UI settings
  highlight_group = "Comment",
  virtual_text_prefix = " ◦ ",
  show_border = true,
  
  -- Behavior
  auto_trigger = true,
  min_chars = 1, -- Minimum characters before triggering
  debounce_ms = 500, -- Debounce time for text changes
  
  -- File types to enable (empty means all)
  filetypes = {},
  -- File types to exclude
  exclude_filetypes = { "TelescopePrompt", "neo-tree", "lazy" },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  
  -- Validate API key
  if M.options.api_key == "your_api_key_here" then
    vim.notify("Stream Completion: Please set your API key", vim.log.levels.WARN)
  end
end

return M
