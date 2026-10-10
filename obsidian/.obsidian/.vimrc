" remap esc
imap kj <Esc>
imap KJ <Esc>

" unmap space to use as leader
unmap <Space>

" search selection
vnoremap <Space>/ <esc>/\%V
vnoremap <a-/> :s/\%V

" force quit
nnoremap <Space>q :q!<CR>

" ctrl bkspace/del
inoremap <C-BS> <C-w>
imap <C-d> <C-[>ldwi

" ctrl+v workaround for visual block
nnoremap <Space>v <C-v>

" edit this file
nnoremap <Space>e :e ~/.ideavimrc<CR>
nnoremap <Space>w :w<CR>:so ~/.ideavimrc<CR>

" remove current highlighting
nnoremap <Space>h :noh<CR>

" don't jump with *
"nmap <silent> * "syiw<Esc>: let @/ = @s<CR>: let &hls=0<cr>: let &hls=1<cr>

" navigate tabs
nnoremap <a-.> :action NextTab<CR>
nnoremap <a-,> :action PreviousTab<CR>

" move between splits
nnoremap <a-h> <c-w>h
nnoremap <a-l> <c-w>l
nnoremap <a-k> <c-w>k
nnoremap <a-j> <c-w>j

"" equalize splits
map <Space>= <c-w>v:q<CR><c-w>s:q<CR>
"map <a-=> <c-w>v:q<CR><c-w>s:q<CR>

exmap back obcommand app:go-back
nmap <C-o> :back<CR>
exmap forward obcommand app:go-forward
nmap <C-i> :forward<CR>
