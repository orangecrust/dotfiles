--===========================================================================
-- KEYBINDS
--===========================================================================
local remap = vim.keymap.set
-----------------------------------------
-- Plugins
-----------------------------------------
-- Oil
remap('n', '-', '<Cmd>Oil<CR>')

-- mini.git
remap('n', '<leader>gb', '<CMD>vert Git blame --date=human -- %<CR><Cmd>sl10m<CR><c-w>H')
remap('n', '<leader>gs', '<CMD>vert split<CR>sl 100m<CMD>lua MiniGit.show_at_cursor()<CR>')

-- mini.completion
-- local keycode = vim.keycode or function(x)
--     return vim.api.nvim_replace_termcodes(x, true, true, true)
--   end
-- local keys = {
--     ['cr']        = keycode('<CR>'),
--     ['ctrl-y']    = keycode('<C-y>'),
--     ['ctrl-y_cr'] = keycode('<C-y><CR>'),
-- }
-- _G.cr_action = function()
--     if vim.fn.pumvisible() ~= 0 then
--       -- If popup is visible, confirm selected item or add new line otherwise
--       local item_selected = vim.fn.complete_info()['selected'] ~= -1
--       return item_selected and keys['ctrl-y'] or keys['ctrl-y_cr']
--     else
--       -- If popup is not visible, use plain `<CR>`. You might want to customize
--       -- according to other plugins. For example, to use 'mini.pairs', replace
--       -- next line with `return require('mini.pairs').cr()`
--       return keys['cr']
--     end
-- end
-- remap('i', '<CR>', 'v:lua._G.cr_action()', { expr = true })


-- mini.pick
remap('n', '<leader>f', '<Cmd>lua MiniPick.builtin.files()<CR>')
remap('n', '<leader>b', '<Cmd>lua MiniPick.builtin.buffers()<CR>')
remap('n', '<leader>g', '<Cmd>lua MiniPick.builtin.grep_live()<CR>')
-- notes: 
--  tab = preview
--  c-x/a = mark/all
--  a-cr = choose marked items
-- extras: 
remap('n', '<leader>c', '<Cmd>lua MiniExtra.pickers.history()<CR>')
remap('n', '<leader>d', '<Cmd>lua MiniExtra.pickers.diagnostic()<CR>')
remap('n', '<leader>x', '<Cmd>lua MiniExtra.pickers.explorer()<CR>')
remap('n', '<leader>k', '<Cmd>lua MiniExtra.pickers.keymaps()<CR>')
remap('n', '<leader>m', '<Cmd>lua MiniExtra.pickers.marks()<CR>')
-- notes: quickfix, location-list, jumplist, changelist
--  tab = preview
--  c-x/a = mark/all
--  a-cr = choose marked items

-- LSP
remap('n', '<CA-a>', vim.lsp.buf.code_action)
remap('n', '<CA-l>', vim.lsp.buf.format)
remap('n', '<CA-d>', vim.lsp.buf.declaration)
remap('n', '<CA-s>', vim.lsp.buf.document_symbol)
remap('n', '<CA-i>', vim.lsp.buf.implementation)
remap('n', '<CA-r>', vim.lsp.buf.references)
remap('n', '<A-d>', vim.diagnostic.open_float)
remap('n', '<S-F6>', vim.lsp.buf.rename)
-- notes:
--  <s-k>: open help
--  gd: goto defintion

-- Outline
remap('n', '<leader>o', "<Cmd>Outline<CR>")

--===========================================================================
-- PLUGIN MANAGER: LAZY
--===========================================================================
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim' -- Lazy bootstrap starts here
---@diagnostic disable-next-line: undefined-field
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)                                -- Ends here, this should be left alone.


-- --===========================================================================
-- -- LAZY PLUGINS START
-- --===========================================================================
require("lazy").setup({
--     --===============================================================================================
--     -- PLUGIN: MINI.NVIM
--     --===============================================================================================
    { 'echasnovski/mini.nvim', version = false },
--     --===============================================================================================
--     -- PLUGIN: OIL
--     --===============================================================================================
    {
        'stevearc/oil.nvim',
        opts = {
            view_options = { show_hidden = true }
        }
    },

--     --===============================================================================================
--     -- PLUGIN: TRESITTER
--     --===============================================================================================
    {
        'nvim-treesitter/nvim-treesitter',
        build = ":TSUpdate",
        config = function()
            -- ENABLES THIS IF USING WINDOWS:
            require('nvim-treesitter.install').compilers = { 'zig' }
            require('nvim-treesitter.configs').setup {
                ensure_installed = { 'c', 'lua', 'vim', 'python', 'vimdoc', 'markdown'},
                -- Install parsers synchronously (only applied to `ensure_installed`)
                sync_install = true,
                -- Automatically install missing parsers when entering buffer
                auto_install = true,
                highlight = {
                    enable = true,
                },
            }
        end
    },
--     --===============================================================================================
--     -- PLUGIN: LSP
--     --===============================================================================================
    {
        'neovim/nvim-lspconfig',
        config = function()
            local lspconfig = require('lspconfig')
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            local custom_attach = function()
                print('Lsp Attached.')
            end
            --===============================================================================================
            -- LSP: LUA-LANG-SERVER (LUA)
            --===============================================================================================
            lspconfig.lua_ls.setup ({
                on_attach = custom_attach,
                capabilities = capabilities,
                settings = {
                    Lua = {
                        runtime = { version = 'LuaJIT', },
                        diagnostics = { enable = true, },
                        workspace = {
                            checkThirdParty = false,
                            library = {
                              vim.env.VIMRUNTIME,
                            },
                        },
                        telemetry = { enable = false },
                    },
                },
            })
            --===============================================================================================
            -- LSP: BASEDPYRIGHT (PYTHON)
            --===============================================================================================
            lspconfig.basedpyright.setup({
                capabilities = capabilities,
                settings = {
                    basedpyright = {
                        -- typeCheckingMode = 'off',
                        -- autoSearchPaths = true,
                        -- diagnosticMode = 'openFilesOnly',
                        -- useLibraryCodeForTypes = false,
                        openFilesOnly = true,
                        disableOrganizeImports = true,
                        reportMissingTypeStubs = false,
                    },
                    python = {
                        analysis = {
                            typeCheckingMode = 'basic',
                            reportMissingTypeStubs = false,
                            useLibraryCodeForTypes = true,
                            -- ignore = { '*' },
                        },
                        typeCheckingMode = "off",
                    }
                },
            })
            --===============================================================================================
            -- LSP: RUFF (PYTHON)
            --===============================================================================================
            lspconfig.ruff.setup({
                trace = 'messages',
                    init_options = {
                        settings = {
                            logLevel = 'debug',
                        }
                    }
            })
        end
    },
    --===============================================================================================
    -- CODE SYMBOL OUTLINE
    --===============================================================================================
    { "hedyhli/outline.nvim", dependencies={ "epheien/outline-treesitter-provider.nvim" } },

    --===============================================================================================
    -- COLOR SCHEMES
    --===============================================================================================
    { "ntk148v/habamax.nvim", dependencies={ "rktjmp/lush.nvim" } },
    { "EdenEast/nightfox.nvim" },
    { "bluz71/vim-moonfly-colors" },
    { "p00f/alabaster.nvim" },

-- --===========================================================================
-- -- PLUGINS END
-- --===========================================================================
})

--===============================================================================================
-- Color Scheme
--===============================================================================================
-- vim.cmd("colo retrobox")
-- require('mini.hues').setup({ background = '#0f2728', foreground = '#d0d0d0', saturation = 'medium', n_hues=5, accent="bg"})
require('mini.hues').setup({ background = '#11262d', foreground = '#d0d0d0', saturation = 'medium', n_hues=5, accent="bg"})

--===========================================================================
-- CONFIG: OUTLINE
--===========================================================================
require('outline').setup({ providers = { priority = { 'lsp', 'treesitter' } } })

--===========================================================================
-- CONFIG: LSP
--===========================================================================
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics,
    {
      virtual_text = false,
      signs = true,
      update_in_insert = false,
      underline = true,
    }
)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup('lsp_attach_disable_ruff_hover', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client == nil then
      return
    end
    -- if client.name == 'ruff' then
    --   -- Disable hover in favor of Pyright
    --   client.server_capabilities.hoverProvider = false
    -- end
  end,
  desc = 'LSP: Disable hover capability from Ruff',
})

--===========================================================================
-- CONFIG: MINI.COMPLETION
--===========================================================================
require('mini.completion').setup({delay = { completion = 500 } })

--===========================================================================
-- CONFIG: MINI.SNIPPETS (#TODO: add snippets)
--===========================================================================
local gen_loader = require('mini.snippets').gen_loader
require('mini.snippets').setup({
  snippets = {
    -- Load custom file with global snippets first 
    gen_loader.from_file(vim.env.USERPROFILE .. '/appdata/local/nvim/snippets/global.json'),

    -- Load snippets based on current language by reading files from
    -- "snippets/" subdirectories from 'runtimepath' directories.
    gen_loader.from_lang(),
  },
})

--===========================================================================
-- CONFIG: MINI.GIT
--===========================================================================
require('mini.git').setup({command={split="horizontal"}})

-- statusline minigit_summary_string
local format_summary = function(data)
    -- Utilize buffer-local table summary
    local summary = vim.b[data.buf].minigit_summary
    vim.b[data.buf].minigit_summary_string = (
        ( summary.head_name or '' ) .. ' ' .. ( summary.in_progress or '' )
    )
end
local minigitupdated_au_opts = { pattern = 'MiniGitUpdated', callback = format_summary }
vim.api.nvim_create_autocmd('User', minigitupdated_au_opts)

-- git blame
local align_blame = function(au_data)
    if au_data.data.git_subcommand ~= 'blame' then return end

    -- Align blame output with source
    local win_src = au_data.data.win_source
    vim.wo.wrap = false
    vim.fn.winrestview({ topline = vim.fn.line('w0', win_src) })
    vim.api.nvim_win_set_cursor(0, { vim.fn.line('.', win_src), 0 })

    -- Bind both windows so that they scroll together
    vim.wo[win_src].scrollbind, vim.wo.scrollbind = true, true
end
local minigitcmdsplit_au_opts = { pattern = 'MiniGitCommandSplit', callback = align_blame }
vim.api.nvim_create_autocmd('User', minigitcmdsplit_au_opts)

--===========================================================================
-- CONFIG: MINI.DIFF
--===========================================================================
require('mini.diff').setup()

--===========================================================================
-- CONFIG: MINI.STATUSLINE
--===========================================================================
local sl = require('mini.statusline')
sl.setup({
    content={
        active=function ()
            local mode, mode_hl = sl.section_mode({ trunc_width = 1000 })
            local git = sl.section_git({ trunc_width = 40, icon = ""})
            local diff = sl.section_diff({ trunc_width = 75, icon="║"})
            local lsp = sl.section_lsp({ trunc_width = 75, icon="║"})
            -- local fname = (MiniStatusline.section_filename({ trunc_width = 100})):match("([^\\]+)$")
            local fname = vim.fn.expand('%'):match("([^\\]+)$")
            local location = sl.section_location({ trunc_width = 1000 })
            local search = sl.section_searchcount({ trunc_width = 75 })
            local diagnostics = sl.section_diagnostics({
                trunc_width = 75,
                icon="",
                signs =   { ERROR = '(X)', WARN = '(!)', INFO = '(@)', HINT = '(*)' }
            })
            return sl.combine_groups({
                { hl = mode_hl,                  strings = { mode } },
                { hl = 'MiniStatuslineDevinfo',  strings = { git, diff, lsp } },
                '%<', -- Mark general truncate point
                -- { hl = 'MiniStatuslineFilename', strings = { fname } },
                { hl =  'MiniStatuslineFilename', strings = { diagnostics } },
                '%=', -- End left alignment
                { hl = 'MiniStatuslineFilename', strings = { search, location } },
                -- { hl = mode_hl,                  strings = { diagnostics } },
                { hl = mode_hl, strings = { fname } },
            })
            end,
        inactive=nil
    },
    use_icons=true,
    set_vim_settings=false
})

--===========================================================================
-- CONFIG: MINI.TABLINE
--===========================================================================
require('mini.tabline').setup({
  config = {
    -- Whether to show file icons (requires 'mini.icons')
    show_icons = true,

    -- Function which formats the tab label
    -- By default surrounds with space and possibly prepends with icon
    -- format = nil,

    -- Whether to set Vim's settings for tabline (make it always shown and
    -- allow hidden buffers)
    set_vim_settings = false,

    -- Where to show tabpage section in case of multiple vim tabpages.
    -- One of 'left', 'right', 'none'.
    tabpage_section = 'left',
  }
})

--===========================================================================
-- CONFIG: MINI.JUMP2D
--===========================================================================
require('mini.jump2d').setup()

--===========================================================================
-- CONFIG: MINI.PAIRS
--===========================================================================
require('mini.pairs').setup()

--===========================================================================
-- CONFIG: MINI.PICK
--===========================================================================
local pick = require('mini.pick')
local win_config = function()
    local height = math.floor(0.618 * vim.o.lines)
    local width = math.floor(0.618 * vim.o.columns)
    return {
      anchor = 'NW', height = height, width = width,
      row = math.floor(0.5 * (vim.o.lines - height)),
      col = math.floor(0.5 * (vim.o.columns - width)),
    }
end
pick.setup({
    window = { config = win_config, border = 'single' },
    mappings = { choose = '<C-y>', choose_marked = '<C-m>' },
})

--===========================================================================
-- CONFIG: MINI.EXTRA
--===========================================================================
require('mini.extra').setup()

--===========================================================================
-- CONFIG: MINI.ICONS
--===========================================================================
-- require('mini.icons').setup({
--     style = 'ascii',
-- })
