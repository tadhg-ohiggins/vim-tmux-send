# Vim tmux send
<!-- !ep{tanglefile: vim_tmux_send.vim; }! -->

## Overview

Forked from [vim-tmux-send](https://github.com/slarwise/vim-tmux-send).

Sends lines and visual selections to a different tmux pane. Does some stuff before that which I think might be helpful.

## Functions

These are all in `autoload`.

### `send_keys`

This is the core function; I added a direction parameter to it in cases where I want to send to the previous, rather than next, pane.

I added support for including environment variables, but ended up not using it much. I’ll get around to moving that functionality into its own function, and adding the ability to evaluate VimScript, at some point.

```vim
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
```

### `send_line`

This is the simplest invocation:

```vim
function! vim_tmux_send#send_line(direction = '+')
    let current_line = getline('.')
    let current_line = shellescape(current_line)
    let keys = current_line . ' ENTER'
    call vim_tmux_send#send_keys(keys, a:direction)
endfunction
```

### `send_visual`

The original didn’t have this, so I added it.

```vim
function! vim_tmux_send#send_visual(rng1, rng2)
    let lines = getline(a:rng1, a:rng2)
    for line in lines
        let current_line = shellescape(line)
        let keys = current_line . ' ENTER'
        call vim_tmux_send#send_keys(keys)
    endfor
endfunction
```

### `send_selection`

This is for operator-pending mode, as in:

```vim {.notangle}
nnoremap <LEADER>s :set operatorfunc=SendSelection<CR>g@
```

I basically don’t use it.

```vim
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
```

### `send_make_cmd`

This is a nice idea, but I switched to this and to using `tmake` instead of using `makeprg`, so never use this either.

```vim
function! vim_tmux_send#send_make_cmd()
    let make_list = split(&makeprg)
    let make_cmd = map(make_list, 'expand(v:val)')
    let make_cmd = join(make_cmd, ' SPACE ')
    let keys = make_cmd . ' ENTER'
    call vim_tmux_send#send_keys(keys)
endfunction
```

### `transform_keys`

There are a few transformations I might want to apply to the text, such as adding contents of environment variables. These go here.

```vim
function! vim_tmux_send#transform_keys(keys)
    let keys_to_send = a:keys
    let keys_to_send = vim_tmux_send#resolve_env_vars(keys_to_send)
    let keys_to_send = vim_tmux_send#resolve_filepath(keys_to_send)
    let keys_to_send = vim_tmux_send#resolve_filedir(keys_to_send)
    return keys_to_send
endfunction
```

#### Resolve environment variables

```vim
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
```

#### Resolve filepath

This inserts the filepath of the current file:

```vim
function! vim_tmux_send#resolve_filepath(keys)
    let keys_to_send = a:keys
    let filepath_magic_string = "%%%vim_tmux_send_filepath%%%"
    while stridx(keys_to_send, filepath_magic_string) != -1
        echom "stridx!!!!!" . stridx(keys_to_send, filepath_magic_string)
        let keys_to_send = substitute(keys_to_send, filepath_magic_string, expand("%:p"), "")
    endwhile
    return keys_to_send
endfunction
```

#### Resolve parent path

This inserts the path of the current file’s directory:

```vim
function! vim_tmux_send#resolve_filedir(keys)
    let keys_to_send = a:keys
    let filepath_magic_string = "%%%vim_tmux_send_filedir%%%"
    while stridx(keys_to_send, filepath_magic_string) != -1
        let keys_to_send = substitute(keys_to_send, filepath_magic_string, expand("%:p:h"), "")
    endwhile
    return keys_to_send
endfunction
```

## Plugin file

This creates commands and goes in `plugin`:

```vim {filename=../plugin/vim-tmux-send.vim}
" Send keys/commands from vim to other tmux panes.

if exists("g:loaded_vim_tmux_send") || !exists("$TMUX")
    finish
endif
let g:loaded_vim_tmux_send = 1

command! -nargs=1 SendKeys :call vim_tmux_send#send_keys(<args>)
command! SendMakeCmd :call vim_tmux_send#send_make_cmd()
command! SendLine :call vim_tmux_send#send_line('+')
command! SendLineMinus :call vim_tmux_send#send_line('-')
```

## UltiSnips file

```ultisnips {filename=../ultisnips/all.snippets}
snippet :vtsfp "vim_tmux_send_filepath" i
%%%vim_tmux_send_filepath%%%
endsnippet

snippet :vtsfd "vim_tmux_send_filedir" i
%%%vim_tmux_send_filedir%%%
endsnippet
```

<!--

## tmake

tmake:

mdtangle /Users/tadhg/vcs/vimplugins/vim-tmux-send/autoload/vim-tmux-send.tangle.md


-->


## EPMetadata

:Identifier: [AU0MJ7]  
:Tags: [project.vim-tmux-send, literate programming, Markdown, coding, VimScript]  
:Title: [Vim tmux send]  
:Format: [Markdown]  
:Originalformat: [Markdown]  
:Created: [2022-09-18]  
:Modified: [2025-01-22]  
:Related: []  

