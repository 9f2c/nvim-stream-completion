local M = {}

function M.check()
  vim.health.report_start('Stream Completion Health Check')
  
  -- Check Neovim version
  if vim.fn.has('nvim-0.7') == 1 then
    vim.health.report_ok('Neovim version >= 0.7')
  else
    vim.health.report_error('Neovim version < 0.7', 'Please upgrade to Neovim 0.7 or later')
  end
  
  -- Check curl
  if vim.fn.executable('curl') == 1 then
    vim.health.report_ok('curl is available')
  else
    vim.health.report_error('curl not found', 'Please install curl')
  end
  
  -- Check API key
  local config = require('stream-completion.config')
  if config.options.api_key and config.options.api_key ~= 'your_api_key_here' then
    vim.health.report_ok('API key is configured')
  else
    vim.health.report_warn('API key not configured', 'Set OPENAI_API_KEY environment variable')
  end
  
  -- Test API connection
  vim.health.report_info('Testing API connection...')
  local test_result = M.test_api_connection()
  if test_result then
    vim.health.report_ok('API connection successful')
  else
    vim.health.report_error('API connection failed', 'Check your API key and endpoint')
  end
end

function M.test_api_connection()
  -- Simple test to verify API is reachable
  local config = require('stream-completion.config')
  
  local handle = io.popen(string.format(
    'curl -s -o /dev/null -w "%%{http_code}" -H "Authorization: Bearer %s" "%s" 2>/dev/null',
    config.options.api_key,
    config.options.api_url
  ))
  
  if not handle then
    return false
  end
  
  local result = handle:read("*a")
  handle:close()
  
  -- Check if we got any HTTP response
  return result and result:match("^%d%d%d$") and result ~= "000"
end

return M
