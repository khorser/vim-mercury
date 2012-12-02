" Vim filetype plugin
" Language:    Mercury
" Last Change: $HGLastChangedDate: 2012-12-02 13:27 +0400 $
" Maintainer:  Sergey Khorev <sergey.khorev@gmail.com>
" Based on work of Ralph Becket <rafe@cs.mu.oz.au>
" vim: ts=2 sw=2 et

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" I find it handy to run `mtags' over the Mercury library .m files
" and move the resulting tags file to `$HOME/mercury/tags.library'.
setlocal tags+=$HOME/mercury/tags.library,$HOME/mercury/tags.compiler

" Handy if you use `:make'.
if has('win32')
  if exists('b:mercury_home')
    let s:mercury_home = b:mercury_home
  elseif exists('g:mercury_home')
    let s:mercury_home = g:mercury_home
  else
    " @ MERCURY_HOME @ will be substituted with a real path during installation
    let s:mercury_home = "@MERCURY_HOME@"
    if s:mercury_home[0] == "@"
      echoerr "Mercury home is not set"
    endif
  endif
  let &l:makeprg = s:mercury_home . '/bin/mmake.bat'
  unlet s:mercury_home
else
  setlocal makeprg=mmake
endif
setlocal errorformat&

" Reload any .err buffers silently
autocmd! FileChangedShell *.err vi!

" Formatting options
setlocal formatoptions=trcq
setlocal wrapmargin=0 textwidth=0
setlocal fileformat=unix
