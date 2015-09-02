if exists('g:loaded_code2html_plugin')
    if !has("win32") || !has("gui")
        echoe "only support windows gui version"
    endif
    finish
endif
let g:loaded_code2html_plugin = 1

if !exists("g:html_clipboard_exe")
    let g:html_clipboard_exe = "htmlClipboard.exe"
endif
if !exists("g:html_show_line_num")
    let g:html_show_line_num = 0
endif

command -range=% -bar CodeToHtml call <SID>CopyHtmlClip(<line1>, <line2>)

function! <SID>CopyHtmlClip(start_line, end_line)
    if !filereadable(g:html_clipboard_exe)
        echoe g:html_clipboard_exe . " doesn't exist"
        return
    endif
    let g:html_start_line = a:start_line
    let g:html_end_line = a:end_line
    runtime syntax/code2html.vim
endfunction!

map <silent><leader>y :CodeToHtml<CR>
