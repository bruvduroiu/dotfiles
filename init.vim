set number
set relativenumber
set autoindent

" coc.nvim Setup
set cmdheight=2
set updatetime=1000

" don't use arrowkeys
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

" really, just don't
inoremap <Up>    <NOP>
inoremap <Down>  <NOP>
inoremap <Left>  <NOP>
inoremap <Right> <NOP>

call plug#begin("~/.vim/plugged")
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

Plug 'airblade/vim-gitgutter'     " Show git diff of lines edited
Plug 'tpope/vim-fugitive'         " :Gblame
Plug 'tpope/vim-rhubarb'          " :GBrowse
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'edkolev/tmuxline.vim'       " vim-airline compatible tmux bar

Plug 'tpope/vim-endwise'          " Autocomplete end after a do
Plug 'mileszs/ack.vim'            " Use ack in Vim

Plug 'pangloss/vim-javascript'    " JavaScript support
Plug 'leafgarland/typescript-vim' " TypeScript syntax
Plug 'peitalin/vim-jsx-typescript'
Plug 'maxmellon/vim-jsx-pretty'   " JS and JSX syntax
Plug 'jparise/vim-graphql'        " GraphQL syntax
Plug 'styled-components/vim-styled-components'

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
Plug 'junegunn/fzf.vim'

Plug 'Yggdroot/indentLine'        " Indentation Lines

Plug 'APZelos/blamer.nvim'        " Git Blame

Plug 'dracula/vim'

Plug 'voldikss/vim-floaterm'      " Floaterm

Plug 'ryanoasis/vim-devicons'     " Keep this last always
call plug#end()
autocmd BufEnter *.{js,jsx,ts,tsx,py} :syntax sync fromstart
autocmd BufLeave *.{js,jsx,ts,tsx,py} :syntax sync clear 

if (has("termguicolors"))
 set termguicolors
endif
syntax enable
colorscheme dracula

" NERDTree on ctrl+n
let NERDTreeShowHidden=1
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" NERDTree config
let g:NERDTreeWinPos = 1  " open on right
let g:NERDTreeWinSize = 45
let g:NERDTreeShowHidden = 1
let g:NERDTreeMinimalUI = 1
let g:NERDTreeDirArrows = 1
let g:NERDTreeIgnore = []
let g:NERDTreeStatusline = ''
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Integrated Terminal
" open new split panes to right and below
set splitright
set splitbelow
" turn terminal to normal mode with escape
" tnoremap <Esc> <C-\><C-n>
" start terminal in insert mode
au BufEnter * if &buftype == 'terminal' | :startinsert | endif
" open terminal on ctrl+n
"function! OpenTerminal()
"  split term://fish
"  resize 10
"endfunction
"nnoremap <c-b> :call OpenTerminal()<CR>
nnoremap <c-b> :FloatermToggle<CR>
let g:floaterm_wintype = 'split'

" FZF Mapping
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit'
  \}
let $FZF_DEFAULT_COMMAND = 'ag -g ""'

" COC namp
"" Remap keys for applying codeAction to the current line.
nmap <leader>ac  <Plug>(coc-codeaction)

"" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

"" Rename
nmap <leader>rn <Plug>(coc-rename)

"" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gD :vsplit<CR><Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gY :vsplit<CR><Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gI :vsplit<CR><Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

nnoremap <silent> <space>d :<C-u>CocList diagnostics<cr>
nnoremap <silent> <space>s :<C-u>CocList -I symbols<cr>

inoremap <silent><expr> <TAB>
	\ pumvisible() ? "\<C-n>" :
	\ <SID>check_back_space() ? "\<TAB>" :
	\ coc#refresh() 
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

inoremap <silent><expr> <c-space> coc#refresh()
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

function! ShowDocIfNoDiagnostic(timer_id)
  if (coc#float#has_float() == 0 && CocHasProvider('hover') == 1)
    silent call CocActionAsync('doHover')
  endif
endfunction

function! s:show_hover_doc()
  call timer_start(200, 'ShowDocIfNoDiagnostic')
endfunction

autocmd CursorHoldI * :call <SID>show_hover_doc()
autocmd CursorHold * :call <SID>show_hover_doc()

" Diagnostics color
hi! CocErrorSign guifg=#d1666a
hi! CocInfoSign guibg=#353b45
hi! CocWarningSign guifg=#d1cd66

" make FZF respect gitignore if `ag` is installed
" you will obviously need to install `ag` for this to work
if (executable('ag'))
    let $FZF_DEFAULT_COMMAND = 'ag --hidden --ignore .git -g ""'
endif

nnoremap <C-P> :Files<CR>

" VimWiki settings
set nocompatible
filetype plugin on
syntax on


 " VimWiki let
let g:vimwiki_list = [{'path': '~/Nextcloud/vimwiki/', 'ext': '.md'}]

" COC let
let g:coc_global_extensions = [ 'coc-tsserver' ]

" ESLint & Prettier
if isdirectory('./node_modules') && isdirectory('./node_modules/prettier')
  let g:coc_global_extensions += ['coc-prettier']
endif

if isdirectory('./node_modules') && isdirectory('./node_modules/eslint')
  let g:coc_global_extensions += ['coc-eslint']
endif

let g:typescript_indent_disable = 1

" YAML config
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType ts setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType js setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType tf setlocal ts=2 sts=2 sw=2 expandtab
let g:indentLine_char = '⦙'

" Increase win size
nnoremap <silent> <Leader>= :exe "resize " . (winheight(0) * 3/2)<CR>
nnoremap <silent> <Leader>- :exe "resize " . (winheight(0) * 2/3)<CR>
