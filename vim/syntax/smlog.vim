" Vim syntax file
" Language:     SMlog
" Maintainer:   Andrew J. Bennieston <a.j.bennieston@gmail.com>
" URL:          
" Last Change:  2012 June 20
" Version:      0.1.0
" Remark:       Basic syntax highlighting for SMlog

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

" Lines should begin with a process ID
syntax match smlogProcID /^\[\d\+\]/ nextgroup=smlogTimestamp skipwhite display
highlight link smlogProcID Operator

" Then a timestamp
syntax match smlogTimestamp /\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\.\d\+/ contained display
highlight link smlogTimestamp Type

" Highlight any quoted strings
syntax region smlogString start=/"/ end=/"/ display oneline
syntax region smlogSingleString start=/'/ end=/'/ display oneline
highlight link smlogString String
highlight link smlogSingleString String

" Highlighting for the common 'pread SUCCESS' message
syntax match smlogpreadSUCCESS /pread SUCCESS/ display
highlight link smlogpreadSUCCESS Comment

" Highlighting for lock lines
syntax match smlogLock /lock: .\+$/ display
highlight link smlogLock Comment

let b:current_syntax = "smlog"
