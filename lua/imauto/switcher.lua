local native = require("imauto.native")

local M = {}

local state = {
  cfg = nil,
  bin = nil,
  last_global_lang = nil,
  previous_lang = nil,
}

function M.get_current_lang()
  if not state.bin then
    return nil
  end
  local out = vim.fn.system({ state.bin })
  if vim.v.shell_error ~= 0 then
    return state.cfg and state.cfg.default_im or nil
  end
  return (out:gsub("%s+", ""))
end

function M.set_lang(lang)
  if not state.bin or not lang or lang == "" then
    return
  end
  if vim.system then
    vim.system({ state.bin, lang }, { detach = true })
  else
    vim.fn.jobstart({ state.bin, lang }, { detach = true })
  end
end

function M.toggle()
  if not state.cfg then
    return
  end
  local cur = M.get_current_lang()
  if cur == state.cfg.default_im then
    if not state.previous_lang or state.previous_lang == state.cfg.default_im then
      vim.notify("[imauto] no previous IM recorded yet", vim.log.levels.INFO)
      return
    end
    M.set_lang(state.previous_lang)
  else
    state.previous_lang = cur
    M.set_lang(state.cfg.default_im)
  end
end

function M.attach(cfg)
  local bin, err = native.resolve(cfg.cmd)
  if not bin then
    vim.notify("[imauto] " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  state.cfg = cfg
  state.bin = bin
  state.last_global_lang = cfg.default_im
  state.previous_lang = nil

  local group = vim.api.nvim_create_augroup("Imauto", { clear = true })

  if #cfg.set_default_events > 0 then
    vim.api.nvim_create_autocmd(cfg.set_default_events, {
      group = group,
      pattern = "*",
      callback = function()
        state.previous_lang = M.get_current_lang() or state.previous_lang
        M.set_lang(cfg.default_im)
        state.last_global_lang = cfg.default_im
      end,
    })
  end

  if #cfg.set_previous_events > 0 then
    vim.api.nvim_create_autocmd(cfg.set_previous_events, {
      group = group,
      pattern = "*",
      callback = function()
        M.set_lang(state.previous_lang)
        state.last_global_lang = state.previous_lang
      end,
    })
  end

  if cfg.restore_focus_state then
    vim.api.nvim_create_autocmd("FocusLost", {
      group = group,
      pattern = "*",
      callback = function()
        state.last_global_lang = M.get_current_lang() or state.last_global_lang
      end,
    })

    vim.api.nvim_create_autocmd("FocusGained", {
      group = group,
      pattern = "*",
      callback = function()
        M.set_lang(state.last_global_lang)
      end,
    })
  end
end

return M
