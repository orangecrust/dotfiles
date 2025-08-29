-- Highlight yanked text for 150ms
vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
        vim.highlight.on_yank()
    end
})

-- Autoread external changes to files
vim.api.nvim_create_autocmd(
    { 'FocusGained', 'BufEnter' },
    { command = 'checktime' }
)
