local M = {}

M.defaults = {
  default_im = "com.apple.keylayout.ABC",
  set_default_events = { "InsertLeave", "CmdlineLeave" },
  set_previous_events = { "InsertEnter" },
  restore_focus_state = true,
}

function M.setup(opts)
  if opts and opts.cmd ~= nil then
    vim.notify(
      "[imauto] the `cmd` option has been removed; the bundled binary is always used",
      vim.log.levels.WARN
    )
    opts.cmd = nil
  end
  return vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
