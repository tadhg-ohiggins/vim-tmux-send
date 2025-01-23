" Send keys/commands from vim to other tmux panes.

if exists("g:loaded_vim_tmux_send") || !exists("$TMUX")
    finish
endif
let g:loaded_vim_tmux_send = 1

command! -nargs=1 SendKeys :call vim_tmux_send#send_keys(<args>)
command! SendMakeCmd :call vim_tmux_send#send_make_cmd()
command! SendLine :call vim_tmux_send#send_line('+')
command! SendLineMinus :call vim_tmux_send#send_line('-')


" Built with mdtangle from:
" /Users/tadhg/vcs/vimplugins/vim-tmux-send/autoload/vim-tmux-send.tangle.md