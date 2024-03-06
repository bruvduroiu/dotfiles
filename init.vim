set number
set relativenumber
set nofoldenable
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

Plug 'Yggdroot/indentLine'        " Indentation Lines

Plug 'APZelos/blamer.nvim'        " Git Blame

Plug 'kaicataldo/material.vim'

" Telescope installation
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.4' }
Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }

Plug 'christoomey/vim-tmux-navigator' " What it says

Plug 'godlygeek/tabular'          " Vim Markdown
Plug 'preservim/vim-markdown'

Plug 'editorconfig/editorconfig-vim' " Keep editors consistent

Plug 'fatih/vim-go'

" Plug 'huggingface/llm.nvim'
" Plug 'bruvduroiu/llm.nvim'

Plug 'github/copilot.vim'

Plug 'jpalardy/vim-slime', { 'for': 'python' }
Plug 'hanschen/vim-ipython-cell', { 'for': 'python' }

Plug 'folke/noice.nvim'
Plug 'MunifTanjim/nui.nvim'
Plug 'rcarriga/nvim-notify'

Plug 'CoderCookE/vim-chatgpt'

Plug 'jellydn/hurl.nvim'

Plug 'ryanoasis/vim-devicons'     " Keep this last always

call plug#end()
autocmd BufEnter *.{js,jsx,ts,tsx,py} :syntax sync fromstart
autocmd BufLeave *.{js,jsx,ts,tsx,py} :syntax sync clear 

set termguicolors
syntax enable

let g:material_terminal_italics = 1
let g:material_theme_style = "default"
let g:airline_theme = 'material'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
colorscheme material

" NERDTree on ctrl+n
let NERDTreeShowHidden=1
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
let g:airline#extensions#tabline#enabled = 1
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" NERDTree config
let g:NERDTreeWinPos = "right"
let g:NERDTreeWinSize = 45
let g:NERDTreeShowHidden = 1
let g:NERDTreeMinimalUI = 1
let g:NERDTreeDirArrows = 1
let g:NERDTreeIgnore = []
let g:NERDTreeStatusline = ''
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
y
" FZF Mapping
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit'
  \}
let $FZF_DEFAULT_COMMAND = 'ag -g ""'

" Telescope Bindings
nnoremap <C-P> <cmd>Telescope find_files<cr>
nnoremap <C-f> <cmd>Telescope live_grep<cr>
nnoremap <leader>fs <cmd>Telescope grep_string<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

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

" ===== Old one ====
"inoremap <silent><expr> <TAB>
"	\ pumvisible() ? "\<C-n>" :
"	\ <SID>check_back_space() ? "\<TAB>" :
"	\ coc#refresh() 
"inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
"inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
"function! s:check_back_space() abort
"  let col = col('.') - 1
"  return !col || getline('.')[col - 1]  =~# '\s'
"endfunction
" Use tab for trigger completion with characters ahead and navigate
" NOTE: There's always complete item selected by default, you may want to enable
" no select by `"suggest.noselect": true` in your configuration file
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
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

" VimWiki settings
set nocompatible
filetype plugin on
syntax on

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
" autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
" autocmd FileType ts setlocal ts=2 sts=2 sw=2 expandtab
" autocmd FileType js setlocal ts=2 sts=2 sw=2 expandtab
" autocmd FileType tf setlocal ts=2 sts=2 sw=2 expandtab
" autocmd FileType go setlocal ts=4 sts=4 sw=4 expandtab
" autocmd FileType html setlocal ts=4 sts=4 sw=4 expandtab
" autocmd FileType md setlocal ts=4 sts=4 sw=4 expandtab
" autocmd FileType css setlocal ts=4 sts=4 sw=4 expandtab
autocmd FileType json set filetype=jsonc
let g:indentLine_char = '⦙'

" Increase win size
nnoremap <silent> <Leader>= :exe "resize " . (winheight(0) * 3/2)<CR>
nnoremap <silent> <Leader>- :exe "resize " . (winheight(0) * 2/3)<CR>

" Python 3 support
let g:python3_host_prog = '/Users/bogdanbuduroiu/.pyenv/versions/3.9.16/bin/python'

" VIM-GPT Support
let g:chat_gpt_max_tokens=2000
let g:chat_gpt_model='gpt-4'
let g:chat_gpt_session_mode=1
let g:chat_gpt_temperature=0.7
let g:chat_gpt_lang = 'English'

" Noice
lua require("noice").setup()
lua require("notify").setup({ top_down = false })

" Markdown
let g:markdown_fenced_languages = ['html', 'js=javascript', 'ruby', 'python', 'ts=typescript', 'golang']

" Copilot
let g:copilot_filetypes = {'python': v:true, 'typescript': v:true, 'yaml': v:true, 'docker': v:true}
let b:copilot_enabled = v:true
imap <silent><script><expr> <S-Tab> copilot#Accept("\<CR>")
nnoremap <silent> <M-]> <Plug>(copilot-next)
nnoremap <silent> <M-[> <Plug>(copilot-prev)
nnoremap <silent> <M-\> <Plug>(copilot-dismiss)
let g:copilot_no_tab_map = v:true


" lua << EOF
" require('llm').setup({
"   api_token = nil, -- cf Install paragraph
"   model = "stabilityai/stable-code-3b", -- can be a model ID or an http(s) endpoint
"   -- parameters that are added to the request body
"   query_params = {
"     max_new_tokens = 48,
"     temperature = 0.2,
"     top_p = 0.95,
"     stop_token = "<|endoftext|>",
"   },
"   -- set this if the model supports fill in the middle
"   fim = {
"     enabled = true,
"     prefix = "<fim_prefix>",
"     middle = "<fim_middle>",
"     suffix = "<fim_suffix>",
"   },
"   debounce_ms = 150,
"   accept_keymap = "<Tab>",
"   dismiss_keymap = "<S-Tab>",
"   max_context_after = 8192,
"   max_context_before = 8192,
"   tls_skip_verify_insecure = false,
"   -- llm-ls integration
"   lsp = {
"     enabled = false,
"     bin_path = vim.api.nvim_call_function("stdpath", { "data" }) .. "/llm_nvim/bin/llm-ls",
"   },
"   tokenizer_path = nil, -- when setting model as a URL, set this var
"   context_window = 16384, -- max number of tokens for the context window
" })
" EOF

lua << EOF
require('telescope').setup{
  defaults = {
    theme = "dropdown"
  }
}
EOF
