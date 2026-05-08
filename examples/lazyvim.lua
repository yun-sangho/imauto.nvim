-- LazyVim spec for imauto.nvim
-- Place this file at: ~/.config/nvim/lua/plugins/imauto.lua

return {
  "yun-sangho/imauto.nvim",
  build = "make build",
  event = "VeryLazy",
  cond = function()
    return vim.fn.has("mac") == 1
  end,
  opts = {
    default_im = "com.apple.keylayout.ABC",
    set_default_events = { "InsertLeave", "CmdlineLeave" },
    set_previous_events = { "InsertEnter" },
    restore_focus_state = true,
  },
  keys = {
    { "<leader>ui", "<cmd>ImautoToggle<cr>", desc = "Toggle input method" },
  },
}
