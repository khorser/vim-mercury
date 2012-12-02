" Commands for Mercury compiler (http://www.mercury.csse.unimelb.edu.au)
" Native Mercury installer for Windows: http://code.google.com/p/winmercury
" Last Change: $HGLastChangedDate: 2012-12-02 13:27 +0400 $
" URL: http://www.vim.org/scripts/script.php?script_id=2920
" Maintainer:  Sergey Khorev <sergey.khorev@gmail.com>

" EXPORTED COMMANDS:
" :Mmc arg1...	
"     - invoke compiler (mmc), use current file when no arguments passed
" :Mmake arg1...
"     - invoke mmake (mmake.bat on Windows)
" :Mmerr 
"     - show last output from :Mmc or :Mmake
" :Mmod name [interface_imports [implementation_imports]]
"     - insert module template, *imports are comma-separated lists of modules
" :Mmain name [interface_imports [implementation_imports]]
"     - insert module template with the `main' predicate
"
" CUSTOMISATION:
" g:mercury_home or b:mercury_home - Mercury installation directory

let s:save_cpo = &cpo
set cpo&vim

if exists("loaded_mercury_commands")
  finish
endif
let loaded_mercury_commands = 1

if v:version < 700
  finish
endif 

command! -nargs=* Mmc call mercury_commands#CallMmc(<q-args>)
command! -nargs=* Mmake call mercury_commands#CallMmake(mercury_commands#PasteArgs(<f-args>))
command! Mmerr echo mercury_commands#GetLastOutput()
command! -nargs=+ Mmod call mercury_commands#Module(0, <f-args>)
command! -nargs=+ Mmain call mercury_commands#Module(1, <f-args>)

let &cpo = s:save_cpo

finish

List of files for Vimball:

doc/mercury.txt
ftdetect/mercury.vim
ftplugin/mercury.vim
autoload/mercury_commands.vim
plugin/mercury_commands.vim
syntax/mercury.vim
" vim: set ts=8 sw=2 sts=2:
