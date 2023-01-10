let s:projectInfo = {}

function! s:isBelow(root, file_path)
    if stridx(a:file_path, a:root) == 0
        return 1
    else
        return 0
    endif
endfunction

function! project#ProjectRoot(file_path)
    if empty(a:file_path) || s:isBelow(g:cwd,a:file_path)
        return g:cwd
    else
        return a:file_path
    endif
endfunction

function! project#RelativeToRoot(file_path)
    let l:projectRoot = project#ProjectRoot(a:file_path)
    if s:isBelow(l:projectRoot, a:file_path)
        return strpart(a:file_path, strlen(l:projectRoot)+1)
    else
        return a:file_path
    endif
endfunction

function! project#IsBelowRoot(file_path)
    return s:isBelow(project#ProjectRoot(a:file_path), a:file_path )
endfunction


" This was taken out of vim-projectionist by T. Pope
function! s:rootHasFile(root, file) abort
  let file = matchstr(a:file, '[^!].*')
  if file =~# '\*'
    let found = !empty(glob(a:root . '/' . file))
  elseif file =~# '/$'
    let found = isdirectory(a:root . '/' . file)
  else
    let found = filereadable(a:root . '/' . file)
  endif
  return a:file =~# '^!' ? !found : found
endfunction

" This was taken out of vim-projectionist by T. Pope
function! s:evaluateMarker(root, marker)
    for test in split(a:marker, '|')
        if empty(filter(split(test, '&'), '!s:rootHasFile(a:root, v:val)'))
            return 1
        endif
    endfor
    return 0
endfunction

function! project#ProjectType(proj_root)
    for [type, info] in items(s:projectInfo)
        let l:isTypeFunction = get(info, 'isTypeFunction', '')
        if l:isTypeFunction != '' && call(l:isTypeFunction, [a:project_root])
            return type
        else
            let l:marker = get(info, 'marker', '')
            if l:marker != '' && s:evaluateMarker(a:proj_root, l:marker)
                return type
            endif
        endif
    endfor
    return 'default'
endfunction


function! project#AddProjectInfo(type, info)
    let s:projectInfo[a:type] = a:info
endfunction

function! project#ProjectInfo(proj_root, proj_type)
    let l:info = get(s:projectInfo, a:proj_type, {})
    if empty(l:info)
        let l:info = get(s:projectInfo, 'default', {})
    endif
    return copy(l:info)
endfunction

function! project#ProjectFilesCommand(proj_root, proj_type)
    return get(project#ProjectInfo(a:proj_root, a:proj_type),'fileCommand', 'find . -type f')
endfunction

function! project#ProjectCTagsExtraArgs(proj_root, proj_type)
    return get(project#ProjectInfo(a:proj_root, a:proj_type),'ctagsArgs', [])
endfunction

function! project#CreateFindFromExtensions(extensions)
    let l:parts = []
    for ext in a:extensions 
        call add(l:parts,'-name "*.'.ext.'"')
    endfor
    
    return 'find . '.join(l:parts, ' -o ')
endfunction

function! project#CreateAgGFromExtensions(extensions)
    let l:parts = []
    for ext in a:extensions 
        call add(l:parts,'(.*\.'.ext.'$)')
    endfor
    
    return "-G '".join(l:parts, '|')."'"
endfunction

function! project#CreateGrepFromExtensions(extensions)
    let l:parts = []
    for ext in a:extensions 
        call add(l:parts,'--include "*.'.ext.'"')
    endfor
    
    return join(l:parts, ' ')
endfunction

function! project#CreateSearchInFileCommand(proj_root, proj_type, symbol)
    let l:project_info = project#ProjectInfo(a:proj_root, a:proj_type) 
    let l:extensions = get(l:project_info, 'fileExtentions', []) 
    if !empty(l:extensions)
        if executable('ag')
            return "ag --vimgrep ".project#CreateAgGFromExtensions(l:extensions)." ".a:symbol
        else
            return 'grep -H -n -r '.project#CreateGrepFromExtensions(l:extensions).' '.a:symbol
        endif
        exe ':cgetexpr system(l:searchString) | botright copen'
    endif
    return ''
endfunction



