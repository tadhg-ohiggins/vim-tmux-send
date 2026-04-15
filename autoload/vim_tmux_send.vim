function! vim_tmux_send#send_keys(keys, direction = '+')
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
    " echom 1
    " echom keys_to_send
    let keys_to_send = vim_tmux_send#resolve_vimscript(keys_to_send)
    " echom 2
    " echom keys_to_send
    let keys_to_send = vim_tmux_send#resolve_env_vars(keys_to_send)
    " echom 3
    " echom keys_to_send
    let keys_to_send = vim_tmux_send#resolve_filepath(keys_to_send)
    " echom 4
    " echom keys_to_send
    let keys_to_send = vim_tmux_send#resolve_filedir(keys_to_send)
    " echom 5
    " echom keys_to_send
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


function! vim_tmux_send#starts_with(longer, shorter) abort
  return a:longer[0:len(a:shorter)-1] ==# a:shorter
endfunction

function! vim_tmux_send#del_prefix(text, prefix) abort
    if StartsWith(a:text, a:prefix)
        return a:text[strlen(a:prefix):]
    endif
    return a:text
endfunction

function! vim_tmux_send#del_suffix(text, suffix) abort
    if EndsWith(a:text, a:suffix)
        return a:text[:-(strlen(a:suffix)+1)]
    endif
    return a:text
endfunction

function! vim_tmux_send#resolve_vimscript(keys)
    let keys_to_send = a:keys
    let vimscript_magic_string = "'%%%vim_tmux_send_vimscript_line%%%"
    let magic_suffix = "' ENTER"
    let lines = split(keys_to_send, "\n")
    let newlines = []
    for line in lines
        " echom line
        " echom vimscript_magic_string
        " echom vim_tmux_send#starts_with(line, vimscript_magic_string)
        if vim_tmux_send#starts_with(line, vimscript_magic_string)
            let command = vim_tmux_send#del_suffix(vim_tmux_send#del_prefix(line, vimscript_magic_string), magic_suffix)
            exe command
            " let vsline = line
        else
            call add(newlines, line)
        endif
    endfor
    let output = join(newlines, "\n")
    " echom "output"
    " echom output
    return output
endfunction

function! vim_tmux_send#resolve_filepath(keys)
    let keys_to_send = a:keys
    let filepath_magic_string = "%%%vim_tmux_send_filepath%%%"
    while stridx(keys_to_send, filepath_magic_string) != -1
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


" Built 2026-04-15 with mdtangle from:
" /Users/tadhg/vcs/vimplugins/vim-tmux-send/vim-tmux-send.tangle.md