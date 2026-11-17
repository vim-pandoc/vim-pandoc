vim9script
# One pass over the buffer for pandoc#folding#FoldExpr().
# The legacy expression calls synID() on candidate lines. Each call can walk
# the syntax state. This scan applies the same fold markers from the text
# and keeps the result until the buffer or the folding options change.

var cached_buf = -1
var cached_tick = -2
var cached_n = -1
var cached_sig = ''
var cached_levels: list<string> = []

def Heading(mode: string, stack: list<number>, level: number): string
    if mode ==# 'stacked'
        return '>1'
    endif
    if mode ==# 'relative'
        while len(stack) > 0 && stack[-1] >= level
            remove(stack, -1)
        endwhile
        add(stack, level)
        return '>' .. string(len(stack))
    endif
    return '>' .. string(level)
enddef

def Scan(lines: list<string>): list<string>
    var fold_yaml: bool = get(g:, 'pandoc#folding#fold_yaml', 0) != 0
    var yaml_level: string = string(get(g:, 'pandoc#folding#foldlevel_yaml', 1))
    var fold_fence: bool = get(g:, 'pandoc#folding#fold_fenced_codeblocks', 0) != 0
    var fold_markers: bool = get(g:, 'pandoc#folding#fold_vim_markers', 1) != 0
    var markers_in_comments: bool = get(g:, 'pandoc#folding#vim_markers_in_comments_only', 1) != 0
    var mode: string = get(g:, 'pandoc#folding#mode', 'syntax')
    var classes = get(g:, 'pandoc#folding#fold_div_classes', ['notes'])
    var div_pat = ''
    if len(classes) > 0
        # The legacy check joined class names with a literal "|", so
        # <div class="notes"> never matched. \%(\) is the documented form.
        div_pat = '<div class=.\%(' .. join(classes, '\|') .. '\)'
    endif
    var mark_head = markers_in_comments ? '<!--.*' : ''
    var out = repeat(['='], len(lines))
    var stack: list<number> = []
    var in_front = false
    var in_yaml = false
    var fence_char = ''
    var fence_end = ''
    var n = len(lines)
    var i = 0
    while i < n
        var line = lines[i]
        var prev = i == 0 ? '' : lines[i - 1]
        if in_front
            if line =~# '^\%(---\|\.\.\.\)$'
                if fold_yaml
                    out[i] = '<' .. yaml_level
                endif
                in_front = false
            endif
            i += 1
            continue
        endif
        # Only a leading --- opens front matter. Track it even when the fold
        # is off, so the closing rule is not a setext heading.
        if i == 0 && line ==# '---'
            in_front = true
            if fold_yaml
                out[0] = '>' .. yaml_level
            endif
            i += 1
            continue
        endif

        var claimed = false
        if div_pat != '' && line =~? div_pat
            out[i] = 'a1'
            claimed = true
        elseif line =~? '</div endfold>'
            out[i] = 's1'
            claimed = true
        elseif fold_markers && line =~# mark_head .. '{\{3}'
            var open_level = matchstr(line, '\({\{3}\)\@<=\d')
            out[i] = open_level != '' ? '>' .. open_level : 'a1'
            claimed = true
        elseif fold_markers && line =~# mark_head .. '}\{3}'
            var close_level = matchstr(line, '\(}\{3}\)\@<=\d')
            out[i] = close_level != '' ? '<' .. close_level : 's1'
            claimed = true
        endif

        if fence_char != ''
            if line =~# fence_end
                if fold_fence && !claimed
                    out[i] = 's1'
                endif
                fence_char = ''
                fence_end = ''
            elseif !claimed && line =~? '^<!--.*fold-begin -->'
                out[i] = 'a1'
            elseif !claimed && line =~? '^<!--.*fold-end -->'
                out[i] = 's1'
            endif
            i += 1
            continue
        endif

        if line =~# '^\%(---\|\.\.\.\)$' && (prev =~# '^\s*$' || in_yaml)
            in_yaml = !in_yaml
            i += 1
            continue
        endif
        if in_yaml || claimed
            i += 1
            continue
        endif

        var c = line == '' ? '' : line[0]
        var next = i + 1 < n ? lines[i + 1] : ''
        var n0 = next == '' ? '' : next[0]
        if c != '#' && c != '`' && c != '~' && c != ' ' && c != "\t" && c != '<'
                && stridx(line, '<') < 0 && stridx(line, '{') < 0 && stridx(line, '}') < 0
                && n0 != '=' && n0 != '-'
            i += 1
            continue
        endif

        var opener = matchstr(line, '^\s*\zs\%(`\{3,}\|\~\{3,}\)')
        if opener != ''
            fence_char = opener[0]
            fence_end = '^\s*' .. fence_char .. '\{' .. string(len(opener)) .. ',}\s*$'
            if fold_fence
                out[i] = 'a1'
            endif
            i += 1
            continue
        endif
        if line =~# '^#\{1,6}[^.]'
            out[i] = Heading(mode, stack, len(matchstr(line, '^#\{1,6}')))
        elseif line =~# '^[^-=].\+$' && next =~# '^=\+$'
            out[i] = Heading(mode, stack, 1)
        elseif line =~# '^[^-=].\+$' && next =~# '^-\+$'
            out[i] = Heading(mode, stack, 2)
        elseif line =~? '^<!--.*fold-begin -->'
            out[i] = 'a1'
        elseif line =~? '^<!--.*fold-end -->'
            out[i] = 's1'
        endif
        i += 1
    endwhile
    return out
enddef

def Signature(): string
    var classes = get(g:, 'pandoc#folding#fold_div_classes', ['notes'])
    return get(g:, 'pandoc#folding#mode', 'syntax')
        .. ':' .. string(get(g:, 'pandoc#folding#fold_yaml', 0))
        .. ':' .. string(get(g:, 'pandoc#folding#foldlevel_yaml', 1))
        .. ':' .. string(get(g:, 'pandoc#folding#fold_fenced_codeblocks', 0))
        .. ':' .. string(get(g:, 'pandoc#folding#fold_vim_markers', 1))
        .. ':' .. string(get(g:, 'pandoc#folding#vim_markers_in_comments_only', 1))
        .. ':' .. string(classes)
enddef

def Ensure()
    var buf = bufnr('%')
    var tick = b:changedtick
    var n = line('$')
    var sig = Signature()
    if cached_buf == buf && cached_tick == tick && cached_n == n && cached_sig == sig
        return
    endif
    cached_levels = Scan(getline(1, '$'))
    cached_buf = buf
    cached_tick = tick
    cached_n = n
    cached_sig = sig
enddef

export def Expr(): string
    Ensure()
    var i = v:lnum - 1
    return i >= 0 && i < len(cached_levels) ? cached_levels[i] : '='
enddef
