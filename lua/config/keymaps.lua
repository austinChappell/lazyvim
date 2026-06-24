-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "<C-g>u", function()
  local uuid = vim.fn.system("uuidgen"):gsub("\n", ""):lower()
  vim.api.nvim_put({ uuid }, "c", true, true)
end, { desc = "Insert UUID" })
