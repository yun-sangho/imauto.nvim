local native = require("imauto.native")

local M = {}

local state = {
  cfg = nil,
  bin = nil,
  last_global_lang = nil,
  previous_lang = nil,
}

local function strip(s)
  return (s:gsub("%s+", ""))
end

function M.get_current_lang()
  if not state.bin then
    return nil
  end
  local out = vim.fn.system({ state.bin })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return strip(out)
end

local function spawn_async(args, cb)
  if vim.system then
    vim.system(args, { text = true }, function(obj)
      if obj.code == 0 then
        cb(strip(obj.stdout or ""))
      else
        cb(nil)
      end
    end)
  else
    local stdout_chunks = {}
    vim.fn.jobstart(args, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        stdout_chunks = data or {}
      end,
      on_exit = function(_, code)
        if code == 0 and stdout_chunks[1] then
          cb(strip(stdout_chunks[1]))
        else
          cb(nil)
        end
      end,
    })
  end
end

function M.read_current_lang_async(cb)
  if not state.bin then
    cb(nil)
    return
  end
  spawn_async({ state.bin }, cb)
end

-- Single-process read-then-set: prints the prior IM, then selects new_id.
-- Halves fork+exec cost on InsertLeave/CmdlineLeave.
function M.swap_async(new_id, cb)
  if not state.bin or not new_id or new_id == "" then
    cb(nil)
    return
  end
  spawn_async({ state.bin, "--swap", new_id }, cb)
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
  if not cur then
    vim.notify("[imauto] failed to read current input source", vim.log.levels.WARN)
    return
  end
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
  local bin, err = native.resolve()
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
        M.swap_async(cfg.default_im, function(prev)
          if prev and prev ~= "" then
            state.previous_lang = prev
          end
        end)
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
        M.read_current_lang_async(function(cur)
          if cur and cur ~= "" then
            state.last_global_lang = cur
          end
        end)
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
