" vim: set fdm=marker et ts=4 sw=4 sts=4:

" Init(): sets up defaults, creates the Pandoc command, requires python support {{{1
function! pandoc#command#Init()
    " set up defaults {{{2
    " use message buffers? {{{3
    if !exists("g:pandoc#command#use_message_buffers")
        let g:pandoc#command#use_message_buffers = 1
    endif

    " LaTeX engine to use to produce PDFs with pandoc (xelatex, pdflatex, lualatex) {{{3
    if !exists("g:pandoc#command#latex_engine")
        let g:pandoc#command#latex_engine = "xelatex"
    endif
    if exists('b:pandoc_yaml_data')
        if has_key(b:pandoc_yaml_data, 'latex_engine')
            let b:pandoc_command_latex_engine = b:pandoc_yaml_data['latex_engine']
        endif
    endif
    " custom function defining command to open the created files {{{3
    if !exists("g:pandoc#command#custom_open")
        let g:pandoc#command#custom_open = ""
    endif
    " file where to save command templates {{{3
    if !exists("g:pandoc#command#templates_file")
        let g:pandoc#command#templates_file = split(&runtimepath, ",")[0] . "/vim-pandoc-templates"
    endif
    " auto-execute pandoc on writes {{{3
    if !exists("g:pandoc#command#autoexec_on_writes")
        let g:pandoc#command#autoexec_on_writes = 0
    endif
    " command to execute on writes {{{2
    if !exists("g:pandoc#command#autoexec_command")
        let g:pandoc#command#autoexec = ''
    endif
    " path to pandoc executable
    if !exists("g:pandoc#command#path")
        let g:pandoc#command#path = 'pandoc'
    endif
    " custom command to execute instead of pandoc
    if !exists("g:pandoc#compiler#command")
        let g:pandoc#compiler#command = g:pandoc#command#path
    endif
    " custom command arguments
    if !exists("g:pandoc#compiler#arguments")
        let g:pandoc#compiler#arguments = ''
    endif

    " create :Pandoc {{{2
    if has("python3") || has("python3/dyn")
       " let's make sure it gets loaded
        py3 import vim
        command! -buffer -bang -nargs=? -complete=customlist,pandoc#command#PandocComplete
                    \ Pandoc call pandoc#command#Pandoc("<args>", "<bang>")
    else
        " simple version for systems without python
        command! -buffer -nargs=? Pandoc call pandoc#command#PandocNative("<args>")
    endif "}}}2
    " create :PandocTemplate {{{2
    command! -buffer -nargs=1 -complete=custom,pandoc#command#PandocTemplateComplete
                    \ PandocTemplate call pandoc#command#PandocTemplate("<args>")

    " set up auto-execution
    au! BufWritePost <buffer> call pandoc#command#AutoPandoc()
endfunction

" :Pandoc command {{{1

" Pandoc(args, bang): the Pandoc command itself, requires python support {{{2
" args: arguments to pass pandoc
" bang: should we open the created file afterwards?
function! pandoc#command#Pandoc(args, bang)
    if has("python3") || has("python3/dyn")
        py3 from vim_pandoc.command import pandoc
        let templatized_args = substitute(a:args, '#\(\S\+\)',
                    \'\=pandoc#command#GetTemplate(submatch(1))', 'g')
        py3 pandoc(vim.eval('templatized_args'), vim.eval('a:bang') != '')
    endif
endfunction

function! pandoc#command#PandocNative(args)
    let l:cmd = g:pandoc#compiler#command.' '.g:pandoc#compiler#arguments.' '.a:args.' '.fnameescape(expand('%'))
    if has('job')
        call job_start(l:cmd)
    else
        call system(l:cmd)
    endif
endfunction

" PandocComplete(a, c, pos): the Pandoc command argument completion func, requires python support {{{2
function! pandoc#command#PandocComplete(a, c, pos)
    if has("python3") || has("python3/dyn")
        py3 from vim_pandoc.helpparser import PandocInfo
        py3 pandoc_info = PandocInfo()
        let cmd_args = split(a:c, " ", 1)[1:]
        if len(cmd_args) == 1 && (cmd_args[0] == '' || eval(py3eval('vim.eval("cmd_args[0]").startswith(vim.eval("a:a:))')))
            return py3eval('list(filter(lambda i: i.startswith(vim.eval("a:a")), sorted(pandoc_info.output_formats + ["pdf"])))')
        endif
        if len(cmd_args) >= 2
            let long_opts = py3eval('["--" + i for i in filter(lambda i: i.startswith(vim.eval("a:a[2:]")), [v for v in pandoc_info.get_options_list() if len(v) > 1])]')
            let short_opts = py3eval('["-" + i for i in filter(lambda i: i.startswith(vim.eval("a:a[1:]")), [v for v in pandoc_info.get_options_list() if len(v) == 1])]')
            return filter(uniq(extend(sort(short_opts), sort(long_opts))), 'v:val != "-:"')
        endif
    endif
endfunction

function! pandoc#command#AutoPandoc()
    if g:pandoc#command#autoexec_on_writes == 1
        let command = ''
        if exists('g:pandoc#command#autoexec_command')
            let command = g:pandoc#command#autoexec_command
        endif
        if exists('b:pandoc_command_autoexec_command')
            let command = b:pandoc_command_autoexec_command
        endif
        exe command
    endif
endfunction

" PandocAsyncCallback(should_open, returncode): Callback to execute after pandoc finished {{{2
" should_open: should we open the cretaed file?
" returncode: the returncode value pandoc gave
function! pandoc#command#PandocAsyncCallback(should_open, returncode)
    py3 from vim_pandoc.command import pandoc
    py3 pandoc.on_done(vim.eval('a:should_open') == '1', vim.eval('a:returncode'))
endfunction

" PandocJobHandler(id, data, event): Callback for neovim {{{2
function! pandoc#command#JobHandler(id, data, event) dict
    if a:event == 'stdout'
        call writefile(a:data, 'pandoc.out', 'ab')
    elseif a:event == 'stderr'
        call writefile(a:data, 'pandoc.out', 'ab')
    else
        py3 from vim_pandoc.command import pandoc
        py3 pandoc.on_done(vim.eval('self.should_open') == '1', vim.eval('a:data'))
    endif
endfunction

" Command template functions {{{1

function! pandoc#command#PandocTemplate(args) "{{{2
    let cmd_args = split(a:args, " ", 1)
    if cmd_args[0] == "get"
        if len(cmd_args) >= 2
            echo pandoc#command#GetTemplate(join(cmd_args[1:], " "))
        else
            echohl ErrorMsg
            echom "pandoc:command:'PandocTemplate get' needs an argument"
            echohl None
        endif
    elseif cmd_args[0] == "save"
        if len(cmd_args) == 2 && cmd_args[1] != ""
            call pandoc#command#SaveTemplate(cmd_args[1])
        elseif len(cmd_args) > 2
            call pandoc#command#SaveTemplate(cmd_args[1], join(cmd_args[2:], " "))
        else
            echohl ErrorMsg
            echom "pandoc:command:missing or invalid arguments for 'PandocTemplate save'"
            echohl None
        endif
    endif
endfunction

function! pandoc#command#PandocTemplateComplete(a, c, pos) "{{{2
    let cmd_args = split(a:c, " ", 1)[1:]
    if len(cmd_args) == 1
        return "save\nget"
    elseif len(cmd_args) > 1
        if cmd_args[0] == "get"
            return join(pandoc#command#GetTemplateNames(), "\n")
        endif
    endif
    return ""
endfunction

function! s:LastCommandAsTemplate() "{{{2
    let hist_item_idx = histnr("cmd")
    while 1
        let hist_item = histget("cmd", hist_item_idx)
        if match(hist_item, '^Pandoc!\? ') == 0
            break
        endif
        let hist_item_idx = hist_item_idx - 1
    endwhile
    return join(split(hist_item, " ")[1:], " ")
endfunction

function! s:LoadTemplates() "{{{2
    let templates_list = []
    if filereadable(g:pandoc#command#templates_file) == 1
        call extend(templates_list, readfile(g:pandoc#command#templates_file))
    endif
    let templates = {}
    if len(templates_list) > 0
        for temp in templates_list
            let data = split(temp, "|")
            let templates[data[0]] = data[1]
        endfor
    endif
    return templates
endfunction

function! pandoc#command#GetTemplateNames() "{{{2
    return keys(s:LoadTemplates())
endfunction

function! pandoc#command#SaveTemplate(template_name, ...) "{{{2
    if a:0 > 0
        let template = a:1
    else
        let template = s:LastCommandAsTemplate()
    endif
    let templates = s:LoadTemplates()
    let new_template = {a:template_name : template}
    echom string(new_template)
    call extend(templates, new_template)
    let new_templates_list = []
    for key in keys(templates)
        call add(new_templates_list, key . "|" . templates[key])
    endfor
    call writefile(new_templates_list, g:pandoc#command#templates_file)
endfunction

function! pandoc#command#GetTemplate(template_name) "{{{2
    let templates = s:LoadTemplates()
    return templates[a:template_name]
endfunction
