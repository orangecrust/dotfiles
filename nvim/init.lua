-- Color Scheme
vim.cmd("colo default")

-- Define configs directory
local config_dir = vim.fn.stdpath("config")

-- Autocmds
vim.cmd("source " .. vim.fs.joinpath(config_dir, "autocmds.lua"))

-- Options
vim.cmd("source " .. vim.fs.joinpath(config_dir, "opts.lua"))

-- Basic Keymap
vim.cmd("source " .. vim.fs.joinpath(config_dir, "keymap.lua"))

-- Plugins
vim.cmd("source " .. vim.fs.joinpath(config_dir, "plugins.lua"))

