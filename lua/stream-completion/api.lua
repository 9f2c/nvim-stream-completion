local config = require('stream-completion.config')

local M = {}

-- Active completion state
local active_job = nil
local completion_buffer = ""

function M.cancel_completion()
  if active_job then
    vim.fn.jobstop(active_job)
    active_job = nil
  end
  completion_buffer = ""
end

function M.get_completion(text, callback)
  -- Cancel any existing completion
  M.cancel_completion()
  
  if not text or text == "" then
    return
  end
  
  local payload = {
    model = config.options.model,
    messages = {
      {
        role = "user",
        content = "Complete the following text naturally and concisely:\n\n" .. text
      }
    },
    stream = true,
    max_tokens = config.options.max_tokens,
    temperature = config.options.temperature
  }
  
  local curl_command = {
    "curl",
    "-s", "-N",
    "-H", "Authorization: Bearer " .. config.options.api_key,
    "-H", "Content-Type: application/json",
    "-d", vim.fn.json_encode(payload),
    config.options.api_url
  }
  
  completion_buffer = ""
  
  active_job = vim.fn.jobstart(curl_command, {
    on_stdout = function(_, data, _)
      if not data then return end
      
      for _, line in ipairs(data) do
        if line and line ~= "" then
          M.process_stream_line(line, callback)
        end
      end
    end,
    
    on_stderr = function(_, data, _)
      if data and #data > 0 and data[1] ~= "" then
        vim.notify("Stream Completion Error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
      end
    end,
    
    on_exit = function(_, code, _)
      active_job = nil
      if code ~= 0 then
        vim.notify("Stream Completion: Request failed with code " .. code, vim.log.levels.ERROR)
      end
    end
  })
end

function M.process_stream_line(line, callback)
  -- Handle Server-Sent Events format
  if line:match("^data: %[DONE%]") then
    return
  end
  
  local data_match = line:match("^data: (.+)")
  if not data_match then
    return
  end
  
  local success, json_data = pcall(vim.fn.json_decode, data_match)
  if not success then
    return
  end
  
  if json_data.choices and json_data.choices[1] and json_data.choices[1].delta then
    local content = json_data.choices[1].delta.content
    if content then
      completion_buffer = completion_buffer .. content
      -- Format the completion
      local formatted = M.format_completion(completion_buffer)
      callback(formatted)
    end
  end
end

function M.format_completion(text)
  -- Add newlines after punctuation if not followed by space
  text = text:gsub("([.!?])([^ \n])", "%1\n%2")
  
  -- Clean up extra whitespace
  text = text:gsub("%s+", " ")
  text = text:gsub("^%s+", "")
  
  return text
end

return M
