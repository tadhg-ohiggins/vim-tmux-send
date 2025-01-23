function! vim_tmux_send#send_keys(keys, direction = '+')
    echom "WTF?"
    let keys_to_send = vim_tmux_send#transform_keys(a:keys)
    let pane_count = system('tmux list-panes | wc -l')->trim()->str2nr()
    if pane_count > 1
        let clear_line_cmd = 'tmux send-keys -t+ C-u'
        call system(clear_line_cmd)
        let cmd = 'tmux send-keys -t' . a:direction .' ' . keys_to_send
        call system(cmd)
    else
        echohl WarningMsg | echo 'No other tmux pane exists' | echohl None
    endif
endfunction

function! vim_tmux_send#send_line(direction = '+')
    let current_line = getline('.')
    let current_line = shellescape(current_line)
    let keys = current_line . ' ENTER'
    call vim_tmux_send#send_keys(keys, a:direction)
endfunction

function! vim_tmux_send#send_visual(rng1, rng2)
    let lines = getline(a:rng1, a:rng2)
    for line in lines
        let current_line = shellescape(line)
        let keys = current_line . ' ENTER'
        call vim_tmux_send#send_keys(keys)
    endfor
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

function! vim_tmux_send#send_make_cmd()
    let make_list = split(&makeprg)
    let make_cmd = map(make_list, 'expand(v:val)')
    let make_cmd = join(make_cmd, ' SPACE ')
    let keys = make_cmd . ' ENTER'
    call vim_tmux_send#send_keys(keys)
endfunction

function! vim_tmux_send#transform_keys(keys)
    let keys_to_send = a:keys
    let keys_to_send = vim_tmux_send#resolve_env_vars(keys_to_send)
    let keys_to_send = vim_tmux_send#resolve_filepath(keys_to_send)
    let keys_to_send = vim_tmux_send#resolve_filedir(keys_to_send)
    return keys_to_send
endfunction

function! vim_tmux_send#resolve_env_vars(keys)
    let keys_to_send = a:keys
    " LEFT ARC GREATER-THAN BRACKET and RIGHT ARC GREATER-THAN BRACKET 
    let openenvvar = "⦓"
    let closeenvvar = "⦔"
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
    return keys_to_send
endfunction

function! vim_tmux_send#resolve_filepath(keys)
    let keys_to_send = a:keys
    let filepath_magic_string = "%%%vim_tmux_send_filepath%%%"
    while stridx(keys_to_send, filepath_magic_string) != -1
        echom "stridx!!!!!" . stridx(keys_to_send, filepath_magic_string)
        let keys_to_send = substitute(keys_to_send, filepath_magic_string, expand("%:p"), "")
    endwhile
    return keys_to_send
endfunction

function! vim_tmux_send#resolve_filedir(keys)
    let keys_to_send = a:keys
    let filepath_magic_string = "%%%vim_tmux_send_filedir%%%"
    while stridx(keys_to_send, filepath_magic_string) != -1
        let keys_to_send = substitute(keys_to_send, filepath_magic_string, expand("%:p:h"), "")
    endwhile
    return keys_to_send
endfunction


" Built with mdtangle from:
" /Users/tadhg/vcs/vimplugins/vim-tmux-send/autoload/vim-tmux-send.tangle.md