local M = {}

M.defaults = {
  default_im = "com.apple.keylayout.ABC",
  -- Path or name of an alternative IM-switching binary. Leave nil to use the
  -- bundled `bin/imauto` (built from swift/imauto.swift on demand).
  cmd = nil,
  set_default_events = { "InsertLeave", "CmdlineLeave" },
  set_previous_events = { "InsertEnter" },
  restore_focus_state = true,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  return M.options
end

return M
