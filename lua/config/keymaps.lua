-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "<C-g>u", function()
  local uuid = vim.fn.system("uuidgen"):gsub("\n", ""):lower()
  vim.api.nvim_put({ uuid }, "c", true, true)
end, { desc = "Insert UUID" })

-- Search for exact literal strings, completely bypassing regex
vim.keymap.set("n", "<leader>af", function()
  require("telescope.builtin").live_grep({
    additional_args = function()
      return { "--fixed-strings" }
    end,
  })
end, { desc = "Grep literal string (Exact Match)" })

-- Yank the current buffer's path, relative to the cwd
vim.keymap.set("n", "<leader>ap", function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg('"', path)
  vim.fn.setreg("+", path)
  vim.notify("Yanked path: " .. path)
end, { desc = "Yank relative path" })
