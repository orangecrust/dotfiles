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

-- LSP progress
-- vim.api.nvim_create_autocmd("LspProgress", {
--   callback = function(ev)
--     local value = ev.data.params.value or {}
--     local msg = value.message or "done"
--
--     -- truncate long messages
--     if #msg > 40 then
--       msg = msg:sub(1, 37) .. "..."
--     end
--
--     -- :h LspProgress
--     vim.api.nvim_echo({ { msg } }, false, {
--       id = "lsp",
--       kind = "progress",
--       title = value.title,
--       status = value.kind ~= "end" and "running" or "success",
--       percent = value.percentage,
--     })
--   end,
-- })
