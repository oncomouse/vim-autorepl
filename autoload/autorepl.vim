" Define some REPL commands:
let g:autorepl_commands = get(g:, 'autorepl_commands', {})
" Turn off line numbers in terminal (this is a problem in Neovim):
let g:autorepl_no_line_numbers = get(g:, 'autorepl_no_line_numbers', 1)
" Track jobs:
let s:autorepl_jobs = {}
" Track buffers:
let s:autorepl_buffers = {}
" Default configuration is interactive and autoload:
let s:autorepl_defaults = {'interactive': 1, 'auto': 1}
" Command to start the REPL in interactive mode or headless mode:
function! s:start_repl(command, ...) abort
  " Is the REPL interactive:
  let interactive = get(a:, 001, s:autorepl_defaults.interactive)
  " Is the REPL going to retain focus:
  let focus = get(a:, 002, 0)
  " Make sure command is a string:
  let command = type(a:command) == v:t_list ? join(a:command, ' ') : a:command
  if interactive
    " Open the terminal command:
    call execute(':terminal '.(has('nvim') ? '' : '++curwin ++kill=term ').expand(command))
    " Turn off line numbers in term buffer, if we want to:
    if g:autorepl_no_line_numbers
      setlocal nonumber
      setlocal norelativenumber
    endif
    call execute(':file autorepl-' . expand('%:t'))
    let output = has('nvim') ? &channel : buffer_number()
    bp
    " Hook original buffer up to slime:
    call s:connect_to_slime(output)
    call s:connect_to_conjure(1)
    if focus
      bp
    endif
    " Return the identifier we need for job tracking:
    return output
  endif
  " If not interactive, start the job:
  call s:connect_to_conjure(1)
  return has('nvim') ? jobstart(a:command) : job_getchannel(job_start(a:command))
endfunction
function! s:is_job_running(id) abort
  if has('nvim')
    try
      call jobpid(a:id)
      return 1
    catch
      return 0
    endtry
  else
    return job_status(term_getjob(a:id)) ==# 'run'
  endif
endfunction
function! s:connect_to_slime(val) abort
  " If slime is using neovim or vimterminal as a target:
  if get(g:, 'slime_target', '') =~# 'vim'
    let b:slime_config = eval("{'".(has('nvim') ? 'jobid' : 'bufnr')."': ".a:val.'}')
  endif
endfunction
function! s:connect_to_conjure(...) abort
  let first = get(a:, 000, 0)
  if !has_key(g:, 'conjure#filetype_client')
    return
  endif
  if has_key(g:conjure#filetype_client, &filetype)
    " Wait for the REPL to boot:
    if first
      sleep 150m
    endif
    ConjureConnect
  endif
endfunction
function! s:track_buffer(ft) abort
  if !has_key(s:autorepl_buffers, a:ft)
    let s:autorepl_buffers[a:ft] = []
  endif
  call add(s:autorepl_buffers[a:ft], bufnr(''))
endfunction
" Command to start a REPL if none is running and connect the buffer if a REPL
" is running:
function! s:load_repl(ft, auto) abort
  " Don't load if we don't have a repl defined:
  if !(has_key(g:autorepl_commands, a:ft))
    if a:auto == 0
      echohl ErrorMsg | echo 'No REPL configured for '.&filetype | echohl None
    endif
    return
  endif
  if get(s:autorepl_jobs, a:ft, -1) < 0
    let job = extend(s:autorepl_defaults, (type(g:autorepl_commands[a:ft]) == v:t_dict ?
          \ g:autorepl_commands[a:ft] : {'command': g:autorepl_commands[a:ft]}))
    " Do we have to start a job (did the user call for a REPL or is the job
    " autostart-able?):
    if a:auto == 0 || job.auto
      let s:autorepl_jobs[a:ft] = s:start_repl(job.command, job.interactive, !a:auto)
      call s:track_buffer(a:ft)
    endif
  else
    " Anything to do when a REPL is already running. Here we hook into
    " vim-slime:
    if !s:is_job_running(s:autorepl_jobs[a:ft])
      " Recover if the REPL has crashed or been quit:
      let s:autorepl_jobs[a:ft] = -1
      let buffers_to_update = s:autorepl_buffers[a:ft]
      call s:load_repl(a:ft, a:auto)
      " Reconnect each tracked buffer:
      if get(g:, 'slime_target', '') =~# 'vim'
        for bufn in buffers_to_update
          if buffer_exists(bufn)
            execute('buffer '.bufn)
            call s:connect_to_slime(s:autorepl_jobs[a:ft])
            call s:connect_to_conjure()
            bp
          endif
        endfor
      endif
    else
      call s:connect_to_slime(s:autorepl_jobs[a:ft])
      call s:connect_to_conjure()
      call s:track_buffer(a:ft)
    endif
  endif
endfunction
" Autostart a REPL:
function! autorepl#start(ft) abort
  call s:load_repl(a:ft, 1)
endfunction
" Manually start a REPL:
function! autorepl#open_repl() abort
  call s:load_repl(&filetype, 0)
endfunction
function! autorepl#attach_repl() abort
  if get(s:autorepl_jobs, &filetype, -1) >= 0
    call s:connect_to_slime(s:autorepl_jobs[&filetype])
    call s:connect_to_conjure()
    call s:track_buffer(&filetype)
  else
    echohl ErrorMsg | echo 'No running REPL found for '.&filetype | echohl None
  endif
endfunction
