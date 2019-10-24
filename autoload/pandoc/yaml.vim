" Parsing of YAML metadata blocks

function! pandoc#yaml#Init() abort
    let b:pandoc_yaml_data = {}
    try
	call extend(b:pandoc_yaml_data, pandoc#yaml#Parse())
    catch
    endtry
endfunction

" extract yaml header text from the current text, as a list of lines
" TODO: multiple YAML metadata blocks can exist, and at any position in
" the file, but this doesn't handle that yet.
function! pandoc#yaml#Extract() abort
    let l:tmp_lines = []
    let l:cline_n = 1
    while l:cline_n < 100 " arbitrary, but no sense in having huge yaml headers either
	let l:cline = getline(l:cline_n)
	let l:is_delim = l:cline =~# '^[-.]\{3}'
	if l:cline_n == 1 && !l:is_delim " assume no header, end early
	    return []
	elseif l:cline_n > 1 && l:is_delim " yield data as soon as we find a delimiter
	    return l:tmp_lines
	else
	    if l:cline_n > 1
		call add(l:tmp_lines, l:cline)
	    endif
	endif
	let l:cline_n += 1
    endwhile
    return [] " just in case
endfunction

function! pandoc#yaml#Parse(...) abort
    if a:0 == 0 " if no arguments, extract from the current buffer
	let l:block = pandoc#yaml#Extract()
    else
	let l:block = a:1
    endif
    if l:block == []
	return -1
    endif
    let yaml_dict = {}
    " assume a flat structure
    for line in l:block
	let key = ''
	let val = ''
	try
	    let [key, val] = matchlist(line,
			\ '\s*\([[:graph:]]\+\)\s*:\s*\(.*\)')[1:2]
	    let key = substitute(key, '[ -]', '_', 'g')
	    " trim "s at the beggining and end of values
	    let val = substitute(val, '\(^"\|"$\)', '', 'g')
	    let yaml_dict[key] = val
        catch
	endtry
    endfor
    return yaml_dict
endfunction
