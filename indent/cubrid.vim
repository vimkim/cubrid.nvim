if exists('b:did_indent') | finish | endif
let b:did_indent = 1
setlocal indentexpr=GetCubridIndent()
setlocal indentkeys=o,O,0),0=END,0=end
let b:undo_indent = 'setlocal indentexpr< indentkeys<'
function! GetCubridIndent() abort
  let l:previous = prevnonblank(v:lnum - 1)
  if !l:previous | return 0 | endif
  let l:amount = indent(l:previous)
  let l:prior = getline(l:previous)
  if l:prior =~? '^\s*\%(begin\|case\)\>' || l:prior =~ '(\s*$'
    let l:amount += shiftwidth()
  endif
  if getline(v:lnum) =~? '^\s*\%(end\>\|)\)'
    let l:amount -= shiftwidth()
  endif
  return max([0, l:amount])
endfunction
