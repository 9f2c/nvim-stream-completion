" Prevent loading the plugin multiple times
if exists('g:loaded_stream_completion')
  finish
endif
let g:loaded_stream_completion = 1

" Load the Lua module
lua require('stream-completion').setup()

" Commands
command! StreamCompletionToggle lua require('stream-completion').toggle()
command! StreamCompletionEnable lua require('stream-completion').enable()
command! StreamCompletionDisable lua require('stream-completion').disable()
command! StreamCompletionAccept lua require('stream-completion').accept_completion()
command! StreamCompletionReject lua require('stream-completion').reject_completion()
command! StreamCompletionStatus lua require('stream-completion').status()
command! StreamCompletionCompleteNow lua require('stream-completion').complete_now()
command! StreamCompletionHealth lua vim.health.report_start('Stream Completion'); require('stream-completion.health').check()

" Default keymaps (can be overridden by user)
if !exists('g:stream_completion_no_default_mappings')
  inoremap <silent> <C-i> <cmd>StreamCompletionAccept<CR>
  inoremap <silent> <C-x> <cmd>StreamCompletionReject<CR>
  inoremap <silent> <C-Space> <cmd>StreamCompletionCompleteNow<CR>
  nnoremap <silent> <leader>sc <cmd>StreamCompletionToggle<CR>
  nnoremap <silent> <leader>ss <cmd>StreamCompletionStatus<CR>
endif
