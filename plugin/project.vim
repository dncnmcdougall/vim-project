if exists('g:project_loaded')
  finish
endif
let g:project_loaded = 1
let g:cwd = getcwd()

let g:project_type = project#ProjectType(g:cwd)

call project#AddProjectInfo('default', {
            \   'marker': '',
            \   'isTypeFunction': '',
            \   'fileCommand': 'find . -type f',
            \   'ctagsArgs': [],
            \   'fileExtentions': []
            \})
