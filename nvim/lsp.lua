-- SEE: https://neovim.io/doc/user/lsp.html

--===============================================================================================
-- Keymaps
--===============================================================================================
local remap = vim.keymap.set
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

--===============================================================================================
-- Config
--===============================================================================================
vim.api.nvim_create_augroup('lsp_attach_disable_ruff_hover', { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
  group = 'lsp_attach_disable_ruff_hover',
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client == nil then
      return
    end
    if client.name == 'ruff' then
      -- Disable hover in favor of Pyright
      client.server_capabilities.hoverProvider = false
    end
  end,
  desc = 'LSP: Disable hover capability from Ruff',
})

vim.api.nvim_create_augroup('lsp_diagnostics', { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
  group = 'lsp_diagnostics',
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client:supports_method('textDocument/publishDiagnostic') then
        vim.diagnostic.config({
            update_in_insert = false,
            virtual_text = false,
            signs = true,
            underline = true,
            severity_sort = true
        })
    end
  end,
})

--===============================================================================================
-- LSP Setup
--===============================================================================================
local capabilities = vim.lsp.protocol.make_client_capabilities()
vim.lsp.config("*", {
    capabilities = capabilities,
})
--===============================================================================================
-- LSP: LUA-LANG-SERVER (LUA)
--===============================================================================================
vim.lsp.config('lua_ls', {
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
vim.lsp.enable('lua_ls')

--===============================================================================================
-- LSP: ty (PYTHON)
--===============================================================================================
vim.lsp.config('ty', {
    settings = {
        ty = {
            diagnosticMode = "openFilesOnly",
        }
    }
})
-- vim.lsp.enable('ty')

--===============================================================================================
-- LSP: BASEDPYRIGHT (PYTHON)
--===============================================================================================
vim.lsp.config('basedpyright', {
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
            },
        }
    },
})
vim.lsp.enable('basedpyright')

--===============================================================================================
-- LSP: RUFF (PYTHON)
--===============================================================================================
vim.lsp.config('ruff', {
    trace = 'messages',
        init_options = {
            settings = {
                logLevel = 'debug',
            }
        }
})
vim.lsp.enable("ruff")

--===============================================================================================
-- Commands
--===============================================================================================
vim.api.nvim_create_user_command("LspStart", function()
  vim.cmd.e()
end, { desc = "Starts LSP clients in the current buffer" })

vim.api.nvim_create_user_command("LspStop", function(opts)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if opts.args == "" or opts.args == client.name then
      client:stop(true)
      vim.notify(client.name .. ": stopped")
    end
  end
end, {
  desc = "Stop all LSP clients or a specific client attached to the current buffer.",
  nargs = "?",
  complete = function(_, _, _)
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    local client_names = {}
    for _, client in ipairs(clients) do
      table.insert(client_names, client.name)
    end
    return client_names
  end,
})

vim.api.nvim_create_user_command("LspRestart", function()
  local detach_clients = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    client:stop(true)
    if vim.tbl_count(client.attached_buffers) > 0 then
      detach_clients[client.name] = { client, vim.lsp.get_buffers_by_client_id(client.id) }
    end
  end
  local timer = vim.uv.new_timer()
  if not timer then
    return vim.notify("Servers are stopped but havent been restarted")
  end
  timer:start(
    100,
    50,
    vim.schedule_wrap(function()
      for name, client in pairs(detach_clients) do
        local client_id = vim.lsp.start(client[1].config, { attach = false })
        if client_id then
          for _, buf in ipairs(client[2]) do
            vim.lsp.buf_attach_client(buf, client_id)
          end
          vim.notify(name .. ": restarted")
        end
        detach_clients[name] = nil
      end
      if next(detach_clients) == nil and not timer:is_closing() then
        timer:close()
      end
    end)
  )
end, {
  desc = "Restart all the language client(s) attached to the current buffer",
})

vim.api.nvim_create_user_command("LspLog", function()
  vim.cmd.vsplit(vim.lsp.log.get_filename())
end, {
  desc = "Get all the lsp logs",
})

vim.api.nvim_create_user_command("LspInfo", function()
  vim.cmd("silent checkhealth vim.lsp")
end, {
  desc = "Get all the information about all LSP attached",
})
