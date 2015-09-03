if !has("win32") || !has("gui") || !(exists("g:html_clipboard_exe") && filereadable(g:html_clipboard_exe))
    finish
endif

let s:old_fen = &foldenable
setlocal nofoldenable
let s:end=line('$')
" Font
if exists("g:html_font")
    let s:htmlfont = "'". g:html_font . "', monospace"
elseif (&guifont != '')
    let s:htmlfont = "'". &guifont . "', monospace"
else
    let s:htmlfont = "monospace"
endif

let s:whatterm = "gui"

" Find out the background and foreground color for use later
let s:fgc = synIDattr(hlID("Normal"), "fg#", s:whatterm)
let s:bgc = synIDattr(hlID("Normal"), "bg#", s:whatterm)
if s:fgc == ""
    let s:fgc = ( &background == "dark" ? "#ffffff" : "#000000" )
endif
if s:bgc == ""
    let s:bgc = ( &background == "dark" ? "#000000" : "#ffffff" )
endif

" Return CSS style describing given highlight id (can be empty)
function! s:CSS1(id)
    let a = ""
    if synIDattr(a:id, "inverse")
        " For inverse, we always must set both colors (and exchange them)
        let x = synIDattr(a:id, "bg#", s:whatterm)
        let a = a . "color: " . ( x != "" ? x : s:bgc ) . "; "
        let x = synIDattr(a:id, "fg#", s:whatterm)
        let a = a . "background-color: " . ( x != "" ? x : s:fgc ) . "; "
    else
        let x = synIDattr(a:id, "fg#", s:whatterm)
        if x != "" | let a = a . "color: " . x . "; " | endif
        let x = synIDattr(a:id, "bg#", s:whatterm)
        if x != ""
            let a = a . "background-color: " . x . "; "
            " stupid hack because almost every browser seems to have at least one font
            " which shows 1px gaps between lines which have background
            let a = a . "padding-bottom: 1px; "
        endif
    endif
    if synIDattr(a:id, "bold") | let a = a . "font-weight: bold; " | endif
    if synIDattr(a:id, "italic") | let a = a . "font-style: italic; " | endif
    if synIDattr(a:id, "underline") | let a = a . "text-decoration: underline; " | endif
    return a
endfun

let s:stylelist = {}

" save CSS to a list of rules to add to the output at the end of processing
function! s:BuildStyleWrapper(style_id, text)
    " get primary style info from cache or build it on the fly if not found
    let l:saved_style = get(s:stylelist,a:style_id)
    if type(l:saved_style) == type(0)
        unlet l:saved_style
        let l:saved_style = s:CSS1(a:style_id)
        if l:saved_style != ""
            let l:saved_style = 'style=" ' . l:saved_style . '"'
        endif
        let s:stylelist[a:style_id]= l:saved_style
    endif

    " Build the wrapper tags around the text. It turns out that caching these
    " gives pretty much zero performance gain and adds a lot of logic.
    if l:saved_style == ""
        return a:text
    else
        return "<span ". l:saved_style .">".a:text."</span>"
    endif
endfun

let s:LeadingSpace = '&nbsp;'
let s:HtmlSpace = '\' . s:LeadingSpace

" Return HTML valid characters enclosed in a span of class style_name with
" unprintable characters expanded and double spaces replaced as necessary.
"
" TODO: eliminate unneeded logic like done for BuildStyleWrapper
function! s:HtmlFormat(text, style_id)
    " Replace unprintable characters
    let unformatted = strtrans(a:text)

    let formatted = unformatted

    " Replace the reserved html characters
    let formatted = substitute(formatted, '&', '\&amp;',  'g')
    let formatted = substitute(formatted, '<', '\&lt;',   'g')
    let formatted = substitute(formatted, '>', '\&gt;',   'g')
    let formatted = substitute(formatted, '"', '\&quot;', 'g')

    " Replace double spaces, leading spaces, and trailing spaces if needed
    if ' ' != s:HtmlSpace
        let formatted = substitute(formatted, '  ', s:HtmlSpace . s:HtmlSpace, 'g')
        let formatted = substitute(formatted, '^ ', s:HtmlSpace, 'g')
        let formatted = substitute(formatted, ' \+$', s:HtmlSpace, 'g')
    endif

    " Enclose in the correct format
    return s:BuildStyleWrapper(a:style_id, formatted)
endfun

let &l:fileencoding="utf-8"
setlocal nobomb

let s:lines = []
let s:code_lines = []
if !exists("g:html_show_line_num")
    let g:html_show_line_num = 0
elseif g:html_show_line_num
    let s:number_lines = []
    if !exists('s:LINENR_ID')
        let s:LINENR_ID  = hlID('LineNr')     | lockvar s:LINENR_ID
    endif
endif

let s:tag_close = '>'
let s:HtmlEndline = '<br' . s:tag_close

" call extend(s:lines, ["<table>"])

" Now loop over all lines in the original text to convert to html.
" Use html_start_line and html_end_line if they are set.
if exists("g:html_start_line")
    let s:lnum = html_start_line
    if s:lnum < 1 || s:lnum > line("$")
        let s:lnum = 1
    endif
else
    let s:lnum = 1
endif
if exists("g:html_end_line")
    let s:end = html_end_line
    if s:end < s:lnum || s:end > line("$")
        let s:end = line("$")
    endif
else
    let s:end = line("$")
endif
if g:html_show_line_num
    let s:margin = strlen(s:end) + 1
else
    let s:margin = 0
endif


call add(s:lines, "<table style=\" width: 100%; color: " . s:fgc . "; background-color: " . s:bgc . "; font-family: ". s:htmlfont ."; \">")
call add(s:lines, "<tr>")
call add(s:code_lines, "<td>")

if g:html_show_line_num
    call add(s:number_lines, "<td>")
endif
let s:start_line = s:lnum

while s:lnum <= s:end

    let s:new = "<p style=\" display: inline-block; width: 100%; margin: 0px; font-family: ". s:htmlfont .";\">"
    if g:html_show_line_num
        call add(s:number_lines, "<p style=\" display: inline-block; text-align: right; margin: 0px; font-family: ". s:htmlfont .";\">")
        let s:numcol = repeat(' ', s:margin - 1 - strlen(s:lnum)) . (s:lnum - s:start_line + 1) . ' '
    endif

    "
    " A line that is not folded, or doing dynamic folding.
    "
    let s:line = getline(s:lnum)
    let s:len = strlen(s:line)
    " if s:len == 0
    "     call add(s:code_lines, s:LeadingSpace)
    " endif

    " Loop over each character in the line
    let s:col = 1
    while s:col <= s:len
        let s:startcol = s:col " The start column for processing text
        let s:id = synID(s:lnum, s:col, 1)
        let s:col = s:col + 1
        " Speed loop (it's small - that's the trick)
        " Go along till we find a change in synID
        while s:col <= s:len && s:id == synID(s:lnum, s:col, 1) | let s:col = s:col + 1 | endwhile

        " Expand tabs if needed
        let s:expandedtab = strpart(s:line, s:startcol - 1, s:col - s:startcol)
        let s:offset = 0
        let s:idx = stridx(s:expandedtab, "\t")
        while s:idx >= 0
            if has("multi_byte_encoding")
                if s:startcol + s:idx == 1
                    let s:i = &tabstop
                else
                    if s:idx == 0
                        let s:prevc = matchstr(s:line, '.\%' . (s:startcol + s:idx + s:offset) . 'c')
                    else
                        let s:prevc = matchstr(s:expandedtab, '.\%' . (s:idx + 1) . 'c')
                    endif
                    let s:vcol = virtcol([s:lnum, s:startcol + s:idx + s:offset - len(s:prevc)])
                    let s:i = $tabstop - (s:vcol % $tabstop)
                endif
                let s:offset -= s:i - 1
            else
                let s:i = $tabstop - ((s:idx + s:startcol - 1) % $tabstop)
            endif
            let s:expandedtab = substitute(s:expandedtab, '\t', repeat(' ', s:i), '')
            let s:idx = stridx(s:expandedtab, "\t")
        endwhile

        " get the highlight group name to use
        let s:id = synIDtrans(s:id)

        " Output the text with the same synID, with class set to the highlight ID
        " name, unless it has been concealed completely.
        if strlen(s:expandedtab) > 0
            let s:new = s:new . s:HtmlFormat(s:expandedtab,  s:id)
        endif
    endwhile
    let s:new = s:new . "</p>"
    if g:html_show_line_num
        " echo s:HtmlFormat(s:numcol,  s:LINENR_ID) . 'n'
        call add(s:number_lines, s:HtmlFormat(s:numcol,  s:LINENR_ID) . "</p>")
    endif
    call extend(s:code_lines, split(s:new, '\n', 1))
    let s:lnum = s:lnum + 1
endwhile

call add(s:code_lines, "</td>")
if g:html_show_line_num
    call add(s:number_lines, "</td>")
    call extend(s:lines, s:number_lines)
endif
call extend(s:lines, s:code_lines)
call add(s:lines, "</tr></table>")

let @+ = join(s:lines, "")
call system(g:html_clipboard_exe)
let &l:foldenable = s:old_fen
