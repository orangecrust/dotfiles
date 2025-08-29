-- Keymap Variables
local remap = vim.keymap.set

-- Remap ESC
remap('i', 'kj', '<esc>')
remap('i', 'KJ', '<esc>')

-- Visual block
remap('n', '<leader>v', '<C-v>')

-- Clipboard
remap('v', '<A-y>', '"+y')
remap('n', '<A-y>', '"+yy')
remap('n', '<A-p>', '"+p')

-- Move line wraps
remap('n', 'j', 'gj')
remap('n', 'k', 'gk')

-- Format pasted line
remap('n', 'p', 'p==')

-- Line jump up/down
remap('n', '<C-k>', '5k')
remap('n', '<C-j>', '5j')
remap('v', '<C-k>', '5k')
remap('v', '<C-j>', '5j')

-- Vertical split
remap('n', '<leader>+', '<Cmd>vsplit<CR>')
-- Horizontal split
remap('n', '<leader>-', '<Cmd>split<CR>')
-- Move in splits with hjkl
remap('n', '<A-h>', '<Cmd>wincmd h<CR>')
remap('n', '<A-j>', '<Cmd>wincmd j<CR>')
remap('n', '<A-k>', '<Cmd>wincmd k<CR>')
remap('n', '<A-l>', '<Cmd>wincmd l<CR>')
remap('t', '<A-h>', '<Cmd>wincmd h<CR>')
remap('t', '<A-j>', '<Cmd>wincmd j<CR>')
remap('t', '<A-k>', '<Cmd>wincmd k<CR>')
remap('t', '<A-l>', '<Cmd>wincmd l<CR>')
-- Resize splits
remap('n', '<S-Left>', '<Cmd>vertical resize -2<CR>')
remap('n', '<S-Right>', '<Cmd>vertical resize +2<CR>')
remap('n', '<S-Up>', '<Cmd>resize -2<CR>')
remap('n', '<S-Down>', '<Cmd>resize +2<CR>')

-- Indent/Unindent selected text with Tab and Shift+Tab
remap('v', '>', '>gv')
remap('v', '<', '<gv')

-- Remove search HL
remap('n', '<leader>h', '<Cmd>nohlsearch<CR>')

-- cd to current file
remap('n', '<leader>c', '<Cmd>cd %:p:h<CR>')
-- cd to init
remap('n', '<leader>e', '<Cmd>e ' .. vim.env.MYVIMRC .. '<CR>')
-- save and source
remap('n', '<leader>w', '<Cmd>w | so %<CR>')
-- copy filepath to clipboard
remap('n', '<leader>y', '<Cmd>let @*=substitute(expand("%:p"), "/", "\", "g")<CR>')

-- find in current selection
remap('v', '<leader>/', '<esc>/\\%V')
-- find and replace in current selection
remap('v', '<leader>//', ':s/')

-- Enter terminal
remap('n', '<C-q><C-w>', '<c-w>v<Cmd>sl100m<CR><Cmd>terminal<CR>i')
remap('n', '<C-q>', '<c-w>v<Cmd>sl100m<CR><Cmd>terminal<CR>i')
remap('n', '<C-q><C-s>', '<c-w>s<c-w>j<Cmd>sl100m<CR><Cmd>terminal<CR>i')
-- Terminal ESC
remap('t', '<leader>kj', '<c-\\><c-n>')
-- Exit terminal
remap('t', '<C-q>', '<c-\\><c-n><Cmd>sl 100m<CR><Cmd>q<CR>')

-- buffers
remap('n', '<A-,>', '<Cmd>bNext<CR>')
remap('n', '<A-.>', '<Cmd>bnext<CR>')
remap('n', '<A-m>', '<Cmd>bd<CR>')
remap('n', '<A-M>', '<Cmd>bd!<CR>')
remap('n', '<A-n>', '<Cmd>enew<CR>')
remap('n', '<A-/>', '<Cmd>:1,.-bd|.+,$bd<CR><CR>')
-- tabs
remap('n', '<leader>,', '<Cmd>tabNext<CR>')
remap('n', '<leader>.', '<Cmd>tabnext<CR>')
remap('n', '<leader>m', '<Cmd>bd<CR>')
remap('n', '<leader>n', '<Cmd>tabe<CR>')
remap('n', '<leader>/', '<Cmd>:1,.-bd|.+,$bd<CR><CR>')

