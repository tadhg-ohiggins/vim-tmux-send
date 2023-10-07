function! vim_tmux_send#send_keys(keys, direction = '+')
    let pane_count = str2nr(trim(system('tmux list-panes | wc -l')))
    if pane_count > 1
        let clear_line_cmd = 'tmux send-keys -t+ C-u'
        call system(clear_line_cmd)
        let cmd = 'tmux send-keys -t' . a:direction .' ' . a:keys
        call system(cmd)
    else
        echohl WarningMsg | echo 'No other tmux pane exists' | echohl None
    endif
endfunction

function! vim_tmux_send#send_make_cmd()
    let make_list = split(&makeprg)
    let make_cmd = map(make_list, 'expand(v:val)')
    let make_cmd = join(make_cmd, ' SPACE ')
    let keys = make_cmd . ' ENTER'
    call vim_tmux_send#send_keys(keys)
endfunction

function! vim_tmux_send#send_line(direction = '+')
    let current_line = getline('.')
    let current_line = shellescape(current_line)
    let keys = current_line . ' ENTER'
    call vim_tmux_send#send_keys(keys, a:direction)
endfunction

function! vim_tmux_send#send_selection(type)
    let current_a_register = @a
    if a:type ==# 'line'
        execute "normal! '[V']" . '"ay'
        let keys = @a
        let keys = shellescape(keys)
        call vim_tmux_send#send_keys(keys)
    elseif a:type ==# 'char'
        execute "normal! `[v`]" . '"ay'
        let keys = @a
        let keys = shellescape(keys) . ' ENTER'
        call vim_tmux_send#send_keys(keys)
    endif
    let @a = current_a_register
endfunction

function! vim_tmux_send#send_visual()
    exe 'normal "ay'
    let keys = @a
    let keys = shellescape(keys)
    call vim_tmux_send#send_keys(keys)
endfunction
