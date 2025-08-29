-- Env Variables
vim.env.HOME = vim.env.USERPROFILE  -- make sure HOME is USERPROFILE

-- Global Settings
-- vim.g.mapleader = '\\'
vim.g.mapleader = ' '
vim.g.markdown_fenced_languages = {'javascript', 'js=javascript', 'json=javascript'}
vim.g.python_highlight_all = true

-- Terminal and Title Settings
vim.opt.title = false
vim.opt.shell = 'pwsh.exe -NoLogo'
vim.opt.shellcmdflag = '-c'
vim.opt.shellxquote = ''

-- Indentation and Formatting Settings
vim.opt.autoindent = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.smarttab = true
vim.opt.tabstop = 4
vim.opt.formatoptions = 'jql'
vim.opt.linebreak = true

-- Fold Settings
vim.opt.foldmethod = 'indent'
vim.opt.foldlevel = 20
vim.opt.foldenable = false

-- Display Settings
vim.opt.cmdheight = 0
vim.opt.showmode = false
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.mouse = 'a'
vim.opt.splitright = true
vim.opt.showcmd = true
vim.opt.timeoutlen = 500
vim.opt.wildmenu = true
vim.opt.updatetime = 50
vim.opt.scrolloff = 5
vim.opt.signcolumn = 'yes'
vim.opt.breakindent = true
vim.opt.breakindentopt = 'shift:4'
vim.opt.wrap = true

-- List and Match Settings
vim.opt.list = true
vim.opt.listchars = { tab = '  ', leadmultispace = '│   ' }
vim.opt.showmatch = false

-- GUI and Encoding Settings
vim.opt.termguicolors = true
vim.o.winborder = 'single'
-- vim.opt.clipboard = 'unnamedplus'
vim.opt.encoding = 'utf-8'

-- Search and Case Settings
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.incsearch = true
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.hidden = true

-- Line Number Settings
vim.opt.number = true

-- Quickfix Settings
vim.cmd('packadd cfilter')

-- Backup Settings
vim.opt.backupdir = vim.env.USERPROFILE .. '/appdata/local/temp//'
vim.opt.directory = vim.env.USERPROFILE .. '/appdata/local/temp//'
vim.opt.undodir = vim.env.USERPROFILE .. '/appdata/local/temp//'

-- Completion
vim.opt.completeopt = 'menuone,noinsert,noselect,preview,fuzzy'
-- vim.opt.completeopt = 'menuone,noselect,fuzzy'

-- Misc Settings
vim.opt.updatetime = 750
vim.opt.autoread = true
