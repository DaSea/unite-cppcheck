" Vim plugin to run Cppcheck on the current buffer.
" Last Change:  31 Dec 2015
" Maintainer:   DaSea
" License:      Public Domain

" TODO: 高亮,文件名与错误的高亮
" TODO: linux下路径的匹配

" save cpoptions and reset to avoid problems in the script
let s:save_cpo = &cpo
setlocal cpo&vim


" ensure that the options and path variables have been defined. if the
" user hasn't done so, set them up with defaults
if !exists('g:unite_cppcheck_options')
    let g:unite_cppcheck_options = '--enable=style'
endif

if !exists('g:unite_cppcheck_cmd')
    let g:unite_cppcheck_cmd = 'cppcheck'
endif

" add to the error format, so the quick fix window can be used
" let l:regexp = '\^[\(\<\h\w\{1,\}\>\.\{0,\}\):\(\d\{1,}\)]\s\{1,\}\(*\)'
let s:regexp = '\v\[(\h.+\.\h\w+):(\d+)\]:\s{1}(.*)'
" let s:regexp = '\v\[(\a:\\[\h\w|\\]? \h\w\.\h\w):(\d+)\]\s{1}(.*)'

let s:unite_source = {
      \ 'name': 'cppcheck',
      \ 'description': 'Check current buffer!',
      \ 'hooks': {},
      \ }

"inspired from 'unite-outline'
function! s:Source_Hooks_on_init(args, context)
    let a:context.source__cppcheck_source_bufnr = bufnr('%')
    let a:context.source__cppcheck_source_path = expand('%:p')
endfunction

function! s:get_SID()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction
let s:SID = s:get_SID()
delfunction s:get_SID

let s:unite_source.hooks.on_init = function(s:SID . 'Source_Hooks_on_init')

function! s:unite_source.gather_candidates(args, context)
    let l:candidates = []
    let ftype = &filetype
    if ('cpp' !=? ftype) && ('c' !=? ftype)
        echo "No supported file type!"
        return l:candidates
    endif

    if !executable(g:unite_cppcheck_cmd)
        echo 'Cppcheck cannot be found. Ensure the path to cppcheck is in your PATH environment variable.'
    else
        let cmd = fnameescape(g:unite_cppcheck_cmd) . ' ' . g:unite_cppcheck_options . ' ' . expand('%:p')
        let sysret = system(cmd)
        " let sysret = vimproc#system2(cmd)
        let s:tlines = split(sysret, '[\x0]') " 以^@ 进行分割的
        for s:tline in s:tlines
            let l:res = matchlist(s:tline, s:regexp)
            if !empty(l:res)
                call extend(l:candidates, [{
                    \ "word": '['.l:res[2].'] :'.l:res[3],
                    \ "source": "tasklist",
                    \ "kind": "jump_list",
                    \ "action__path": a:context.source__cppcheck_source_path,
                    \ "action__line": l:res[2],
                    \ "action__buf_nr": a:context.source__cppcheck_source_bufnr,
                    \ }])
            endif
        endfor
    endif
    return l:candidates
endfunction

function! unite#sources#cppcheck#define()
  return s:unite_source
endfunction

" restore the original cpoptions
let &cpo = s:save_cpo
unlet s:save_cpo

