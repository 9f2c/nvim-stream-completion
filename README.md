# Nvim Stream Completion

Real-time streaming text completion for Neovim using OpenAI-compatible APIs.

## Features

- 🚀 Real-time streaming completions
- 📝 Context-aware suggestions based on entire file content
- ⚡ Configurable debouncing and delays
- 🎨 Virtual text display with customizable highlighting
- 🔧 Extensive configuration options
- 📁 Filetype filtering support

## Installation

### Using lazy.nvim
```lua
{
  'your-username/nvim-stream-completion',
  config = function()
    require('stream-completion').setup({
      api_key = os.getenv("OPENAI_API_KEY"),
      -- other options...
    })
  end
}
```

### Using packer.nvim
```lua
use {
  'your-username/nvim-stream-completion',
  config = function()
    require('stream-completion').setup()
  end
}
```

## Configuration

```lua
require('stream-completion').setup({
  -- API Configuration
  api_key = os.getenv("OPENAI_API_KEY"), -- Your API key
  api_url = "http://127.0.0.1:1234/v1/chat/completions", -- API endpoint
  model = "gpt-3.5-turbo", -- Model name
  
  -- Completion settings
  max_tokens = 200, -- Maximum tokens in completion
  temperature = 0.1, -- Creativity level (0-1)
  delay_ms = 1000, -- Delay before making API request
  
  -- UI settings
  highlight_group = "Comment", -- Highlight group for virtual text
  virtual_text_prefix = " ◦ ", -- Prefix for virtual text
  show_border = true, -- Show border in floating windows
  
  -- Behavior
  auto_trigger = true, -- Enable auto-triggering
  min_chars = 3, -- Minimum characters before triggering
  debounce_ms = 500, -- Debounce time for text changes
  
  -- File types
  filetypes = {}, -- Whitelist of filetypes (empty = all)
  exclude_filetypes = { "TelescopePrompt", "neo-tree" }, -- Blacklist
})
```

## Usage

### Commands
- `:StreamCompletionToggle` - Toggle completion on/off
- `:StreamCompletionEnable` - Enable completion
- `:StreamCompletionDisable` - Disable completion
- `:StreamCompletionAccept` - Accept current completion
- `:StreamCompletionReject` - Reject current completion

### Default Keymaps
- `<C-g>` (Insert mode) - Accept completion
- `<C-x>` (Insert mode) - Reject completion
- `<leader>sc` (Normal mode) - Toggle completion

### Custom Keymaps
```lua
-- Disable default mappings
vim.g.stream_completion_no_default_mappings = 1

-- Set your own
vim.keymap.set('i', '<Tab>', '<cmd>StreamCompletionAccept<CR>')
vim.keymap.set('i', '<S-Tab>', '<cmd>StreamCompletionReject<CR>')
```

## Requirements
- Neovim 0.7+
- curl
- An OpenAI-compatible API endpoint

## License
MIT
