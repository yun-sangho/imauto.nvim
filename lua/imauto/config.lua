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

function M.setup(opts)
  return vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
