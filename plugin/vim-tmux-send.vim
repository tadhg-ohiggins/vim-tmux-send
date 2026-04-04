" Send keys/commands from vim to other tmux panes.

if exists("g:loaded_vim_tmux_send") || !exists("$TMUX")
    finish
endif
let g:loaded_vim_tmux_send = 1

command! -nargs=1 SendKeys :call vim_tmux_send#send_keys(<args>)
command! SendMakeCmd :call vim_tmux_send#send_make_cmd()
command! SendLine :call vim_tmux_send#send_line('+')
command! SendLineMinus :call vim_tmux_send#send_line('-')
command! -range=% SendVisual call vim_tmux_send#send_visual(<line1>, <line2>)


" Built 2026-04-03 with mdtangle from:
" /Users/tadhg/vcs/vimplugins/vim-tmux-send/vim-tmux-send.tangle.md