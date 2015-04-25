nnoremap <buffer> <C-i> :<C-u>CppInclude<CR>

if exists(':CppInclude')
  finish
endif

command -nargs=0 -bar CppInclude call <SID>cppInclude()

let s:configFile = expand('<sfile>:p:r') . '.cfg'

let s:inclusionMap = {} " lazily initialised
function s:getInclusionMap()
  if empty(s:inclusionMap)
    let v = ''
    for line in readfile(s:configFile)
      if line !=# ''
        if line =~# '^\s'
          for w in split(line, '\s\+', 0)
            let s:inclusionMap[w] = v
          endfor
        else
          let v = line
        endif
      endif
    endfor
  endif
  return s:inclusionMap
endfunction

function s:cppInclude()
  let w = expand('<cword>')
  let h = s:getInclusionMap()
  if w !=# ''
    if has_key(h, w)
      let s = get(h, w)
      let pInclude = '#include '
      if s[:len(pInclude) - 1] ==# pInclude
        call s:addIncludeDirective(s[len(pInclude):])
      endif
    else
      echohl Error | echomsg "Don't know how to handle '" . w . "'" | echohl None
    endif
  endif
endfunction

function s:addIncludeDirective(s)
  let lines = getline(1, 100)
  let lastIncludeLine = 0
  let i = 0
  for line in lines
    let i += 1
    let re = '^\s*#include\s\+\(\S\+\)\s*$'
    if line =~# re
      let lastIncludeLine = i
      let s1 = substitute(line, re, '\1', '')
      if a:s ==# s1
        echohl WarningMsg | echomsg 'Header ' . a:s . ' is already included on line ' . i | echohl None
        return
      endif
    endif
  endfor
  call append(lastIncludeLine, '#include ' . a:s)
  redraw | echohl MoreMsg | echomsg 'OK, included ' . a:s | echohl None
endfunction
