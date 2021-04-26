##../ntangle_test
@*=
vim.api.nvim_command("edit test.lua.t")
vim.api.nvim_command("normal G")
require"ntangle".transpose()
vim.api.nvim_command("bw!")
