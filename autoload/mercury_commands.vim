" Commands for Mercury compiler (http://www.mercury.csse.unimelb.edu.au)
" Native Mercury installer for Windows: http://code.google.com/p/winmercury
" Last Change: $HGLastChangedDate: 2012-12-02 15:24 +0400 $
" URL: http://www.vim.org/scripts/script.php?script_id=2920
" Maintainer:  Sergey Khorev <sergey.khorev@gmail.com>

let s:save_cpo = &cpo
set cpo&vim

if exists("loaded_mercury_commands_autoload")
  finish
endif
let loaded_mercury_commands_autoload = 1

function! mercury_commands#CallMmc(args)
  if a:args == ''
    let l:args = expand('%')
  else
    let l:args = a:args
  endif
  if l:args == ''
    echoerr 'No arguments passed to mmc and current buffer has no filename'
    return
  endif
  let l:Mmc = s:GetMmc()
  call s:InvokeMercury(1, l:Mmc, l:args)
  call s:OpenIfErrors(l:Mmc)
endfunction

function! mercury_commands#CallMmake(args)
  let l:Mmake = s:GetMmake()
  call s:InvokeMercury(0, l:Mmake, a:args)
  " no errors in *.err but there is some message
  call s:ConsolidateErrors()
  call s:OpenIfErrors(l:Mmake)
endfunction

function! s:InvokeMercury(qfoutput, util, args)
  " the only known for me way to be completely silent
  let s:LastOutput = system(a:util . ' ' . a:args)
  if &verbose > 0
    echo 'Invoked' a:util 'with output' s:LastOutput
  endif
  " put output to the quickfix error file
  if a:qfoutput
    exec 'silent redir! >' &ef '| silent echon s:LastOutput | redir END'
  endif
endfunction

" consolidate all .err files from s:LastOutput
function! s:ConsolidateErrors()
  call delete(&ef)
  let pat = '\<\f\+\.err\>'
  let tail = s:LastOutput
  let i = match(tail, pat)
  exec 'silent new' &ef
  while i >= 0
    let tail = strpart(tail, i)
    let e = stridx(tail, '.err')
    let file = strpart(tail, 0, e + 4)
    if filereadable(file) && getfsize(file) > 0
      normal G
      exec 'silent .-1r' file
    endif
    " next iteration
    let tail = strpart(tail, e + 4)
    let i = match(tail, pat)
  endwhile
  silent w
  silent bw
  if v:shell_error
    exec 'silent redir >>' &ef '| silent echon s:LastOutput | redir END'
  endif
endfunction

function! s:PrependMercuryHome(dir, file)
  if has('win32')
    let l:suffix = '.bat'
  else
    let l:suffix = ''
  endif

  let l:mercury_home = ''

  if exists('b:mercury_home')
    let l:mercury_home = b:mercury_home
  elseif exists('g:mercury_home')
    let l:mercury_home = g:mercury_home
  elseif has('win32')
    " @ MERCURY_HOME @ will be patched with the real path by the installer
    let l:mercury_home = "@MERCURY_HOME@"
    " cannot work without MERCURY_HOME on Windows
    if l:mercury_home[0] == "@"
      echoerr "Mercury home is not set"
    endif
  endif

  if l:mercury_home != ''
    return l:mercury_home . '/' . a:dir . '/' . a:file . l:suffix
  else
    return a:file . l:suffix
  endif
endfunction

function! s:GetMmc()
  return s:PrependMercuryHome('bin', 'mmc')
endfunction

function! s:GetMmake()
  return s:PrependMercuryHome('bin', 'mmake')
endfunction

" INTERNAL
  " on win32 cmd seems to substitute "NAME=VALUE" with "NAME VALUE"
  " or is that a zsh, anyway let's quote
if has('win32')
  let s:QuoteChar = '"'
else
  let s:QuoteChar = ''
endif

" just to not bother with passing it everywhere
let s:LastOutput = ''
" the max length of the message to show with echoerr
let s:MaxSensibleLength = 200

" load errors into quickfix and jump to the first one
function! s:OpenIfErrors(util)
  if !filereadable(&ef)
    " No error file but there is some output
    if v:shell_error
      echoerr 'Error invoking' a:util ':' s:LastOutput
    endif
    return
  endif
  
  if v:version >= 700
    let l:found = 0
    try
      cget
      let l:nr = 0
      for err in getqflist()
	let l:nr += 1 "keep current index
	" skip invalid lines and warnings
	if err.valid && err.lnum > 0 && filereadable(bufname(err.bufnr))
			\  && ((stridx(err.text, 'error') >= 0 
			\ || stridx(err.text, 'Error') >= 0))
	  let l:found = 1
	  exec 'cc' l:nr
	  break
	endif
      endfor
    catch /^Vim\%((\a\+)\)\=:E42/	" E42: No errors
    endtry
    " no sensible items in the quickfix list
    if v:shell_error && !l:found
      call s:ErrorMessage(a:util)
    endif
  else
    cf
  endif
endfunction

function! s:ErrorMessage(util)
  if strlen(s:LastOutput) > 0
    echoerr 'Error invoking' a:util ':' strpart(s:LastOutput, 0, s:MaxSensibleLength)
  endif
endfunction

function! mercury_commands#PasteArgs(...)
  let i = 1
  let args = ''
  while i <= a:0
    let args = args . ' ' . s:QuoteChar . a:{i} . s:QuoteChar
    let i += 1
  endwhile
  return args
endfunction

function! s:ModuleHeader(main, name, imports)
  insert  
%------------------------------------------------------------------------------%
.
  call append(line('.'), '% ' . a:name . '.m')
  normal j
  append
% vim: ft=mercury:ff=unix:ts=8:sw=4:sts=4:
%------------------------------------------------------------------------------%

.
  call append(line('.') , ':- module ' . a:name . '.')
  normal j
  append

:- interface.

.
  if a:imports != ''
    call append(line('.') , ':- import_module ' . a:imports . '.')
    normal j
    if !a:main
      append

.
    endif
  endif
  if a:main
    append
:- import_module io.

:- pred main(io.state::di, io.state::uo) is det.

.
  endif
endfunction

function! s:ModuleBody(main, imports)
  append
%------------------------------------------------------------------------------%

:- implementation.

.
  if a:imports != ''
    call append(line('.') , ':- import_module ' . a:imports . '.')
  else
    call append(line('.') , '%:- import_module .')
  endif
  normal j
  if a:main
    append

main(!IO) :- 
    io.write_string("Hello!\n", !IO).
.
  else
    append


.
  endif
endfunction

" insert spaces after commas in import list
function! s:BeautifyImports(imports)
  return substitute(a:imports, ',\(\w\)', ', \1','g')
endfunction

function! mercury_commands#Module(main, name, ...)
  if a:0 > 2
    echoerr 'Too many arguments'
    return
  endif

  if filereadable(a:name . '.m')
    echoerr 'File' a:name .'.m already exists'
    return
  endif

  if a:0 > 0
    let l:int_imports = s:BeautifyImports(a:1)
  else
    let l:int_imports = ''
  endif
  if a:0 > 1
    let l:imp_imports = s:BeautifyImports(a:2)
  else
    let l:imp_imports = ''
  endif
  exec 'new' a:name . '.m'
  set ft=mercury ff=unix ts=8 sw=4 sts=4
  call s:ModuleHeader(a:main, a:name, l:int_imports)
  call s:ModuleBody(a:main, l:imp_imports)
endfunction

function! mercury_commands#GetLastOutput()
  return s:LastOutput
endfunction

let &cpo = s:save_cpo
" vim: ts=8:sw=2:sts=2:
