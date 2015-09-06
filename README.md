# code2Html
convert code to html in vim to keep original format when paste in OneNote or Word etc. Need vim built with +python support.

Installation
============
* Pathogen
    * `git clone https://github.com/chyxwzn/code2Html.git`

Usage
=====
## Default
* convert to html without line number
    * `map <silent><leader>y :CodeToHtml<CR>`
* convert to html with line number
    * `map <silent><leader>ny :NCodeToHtml<CR>`
