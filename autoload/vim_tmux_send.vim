function! vim_tmux_send#send_keys(keys, direction = '+')
    let openenvvar = "〈〈"
    let closeenvvar = "〉〉"
    let keys_to_send = a:keys
    while stridx(keys_to_send, openenvvar) != -1 && stridx(keys_to_send, closeenvvar) != -1
        let start = stridx(keys_to_send, openenvvar) + strlen(openenvvar)
        let end = stridx(keys_to_send, closeenvvar) -1
        let curenv = environ()
        let envvarname = keys_to_send[start:end]
        if has_key(environ(), envvarname)
            let envvar = environ()[envvarname]
        else
            let envvar = "Env var not found: " . envvarname
        endif
        let keys_to_send = substitute(keys_to_send, openenvvar . envvarname . closeenvvar, envvar, "")
    endwhile
    let pane_count = str2nr(trim(system('tmux list-panes | wc -l')))
    if pane_count > 1
        let clear_line_cmd = 'tmux send-keys -t+ C-u'
        call system(clear_line_cmd)
        " let cmd = 'tmux send-keys -t' . a:direction .' ' . a:keys
        let cmd = 'tmux send-keys -t' . a:direction .' ' . keys_to_send
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

function! vim_tmux_send#send_visual(rng1, rng2)
    let lines = getline(a:rng1, a:rng2)
    for line in lines
        let current_line = shellescape(line)
        let keys = current_line . ' ENTER'
        call vim_tmux_send#send_keys(keys)
    endfor
    " exe 'normal "ay'
    " execute "normal! '[V']" . '"ay'
    " let keys = @a
    " let keys = shellescape(keys)
    " call vim_tmux_send#send_keys(keys)
endfunction
