" Vim syntax file
" Language:     xensource.log
" Maintainer:   Andrew J. Bennieston <a.j.bennieston@gmail.com>
" URL:          
" Last Change:  2012 June 20
" Version:      0.1.0
" Remark:       Basic syntax highlighting for xensource.log

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

"Lines should begin with a date
syntax match xensourceDate /^\(Jan\|Feb\|Mar\|Apr\|May\|Jun\|Jul\|Aug\|Sep\|Oct\|Nov\|Dec\) \d\d \d\d:\d\d:\d\d/ nextgroup=xensourceHost skipwhite display
highlight link xensourceDate Type

" Host field
syntax match xensourceHost /\S\+/ contained nextgroup=xensourceProcess skipwhite display
highlight link xensourceHost Comment

" Process field
syntax match xensourceProcess /\S\+:/ contained display
highlight link xensourceProcess Operator

" Square-bracketed regions
syntax region xensourceBracketed start=/\[/ end=/\]/ display
highlight link xensourceBracketed String

let b:current_syntax = "xensource"
