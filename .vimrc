autocmd!
set shiftwidth=2
set softtabstop=2
set tabstop=2
set shiftround
set expandtab
set autoindent
set showmatch
set showmode
set showcmd
set number


set formatoptions-=t
set textwidth=78

set background=dark

set comments-=s1:/*,mb:*,ex:*/
set comments+=s:/*,mb:**,ex:*/
set comments+=fb:*

set mouse=

" Fix for putty not liking UTF-8
let &termencoding = &encoding
set encoding=utf-8
" End fix

filetype on
filetype plugin on
filetype indent on

map <F5> :set hls!<bar>set hls?<CR>
set hls!
" `XTerm', `RXVT', `Gnome Terminal', and `Konsole' all claim to be "xterm";
" `KVT' claims to be "xterm-color":
"if &term =~ 'xterm'
  " `Gnome Terminal' fortunately sets $COLORTERM; it needs <BkSpc> and <Del>
  " fixing, and it has a bug which causes spurious "c"s to appear, which can be
  " fixed by unsetting t_RV:
"  if $COLORTERM == 'gnome-terminal'
"    execute 'set t_kb=' . nr2char(8)
    " [Char 8 is <Ctrl>+H.]
"    fixdel
"    set t_RV=

    " `XTerm', `Konsole', and `KVT' all also need <BkSpc> and <Del> fixing;
    " there's no easy way of distinguishing these terminals from other things
    " that claim to be "xterm", but `RXVT' sets $COLORTERM to "rxvt" and these
    " don't:
"    elseif $COLORTERM == ''
"      execute 'set t_kb=' . nr2char(8)
"      fixdel
"  endif
"endif

if has('syntax') && (&t_Co > 2)
  syntax on
end
set paste
set ruler
