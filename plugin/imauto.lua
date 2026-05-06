if vim.g.loaded_imauto == 1 then
  return
end
vim.g.loaded_imauto = 1

if vim.fn.has("mac") == 0 and vim.fn.has("macunix") == 0 then
  return
end

vim.api.nvim_create_user_command("ImautoToggle", function()
  require("imauto").toggle()
end, { desc = "Toggle input method between default and previous" })

vim.api.nvim_create_user_command("ImautoGet", function()
  local lang = require("imauto").get()
  vim.notify("Current IM: " .. tostring(lang), vim.log.levels.INFO)
end, { desc = "Print the current input method" })

vim.api.nvim_create_user_command("ImautoSet", function(opts)
  require("imauto").set(opts.args)
end, { nargs = 1, desc = "Set input method to the given identifier" })
