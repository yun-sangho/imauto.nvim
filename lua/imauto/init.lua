local config = require("imauto.config")
local switcher = require("imauto.switcher")

local M = {}

M.setup = function(opts)
  local cfg = config.setup(opts)
  switcher.attach(cfg)
end

M.toggle = switcher.toggle
M.set = switcher.set_lang
M.get = switcher.get_current_lang

return M
