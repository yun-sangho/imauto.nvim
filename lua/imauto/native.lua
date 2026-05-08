local M = {}

local function plugin_root()
  local source = debug.getinfo(1, "S").source
  local path = source:sub(2):gsub("/lua/imauto/native%.lua$", "")
  return path
end

local function fs_stat(path)
  return vim.uv and vim.uv.fs_stat(path) or vim.loop.fs_stat(path)
end

local function file_exists(path)
  return fs_stat(path) ~= nil
end

local function mtime_sec(path)
  local s = fs_stat(path)
  return s and s.mtime.sec or nil
end

function M.bundled_binary_path()
  return plugin_root() .. "/bin/imauto"
end

function M.swift_source_path()
  return plugin_root() .. "/swift/imauto.swift"
end

function M.build()
  local bin = M.bundled_binary_path()
  local src = M.swift_source_path()
  if not file_exists(src) then
    return nil, "swift source missing: " .. src
  end
  if vim.fn.executable("swiftc") == 0 then
    return nil, "swiftc not found; install Xcode Command Line Tools (`xcode-select --install`)"
  end
  vim.fn.mkdir(plugin_root() .. "/bin", "p")
  local out = vim.fn.system({ "swiftc", "-O", "-framework", "Carbon", "-o", bin, src })
  if vim.v.shell_error ~= 0 then
    return nil, "swiftc failed: " .. out
  end
  return bin
end

function M.resolve()
  local bundled = M.bundled_binary_path()
  local bin_m = mtime_sec(bundled)
  if bin_m then
    local src_m = mtime_sec(M.swift_source_path())
    if src_m and bin_m < src_m then
      vim.notify(
        "[imauto] bin/imauto is older than swift/imauto.swift. "
          .. "Run `:Lazy build imauto.nvim` (or `make build` in the plugin "
          .. "directory) to pick up source changes.",
        vim.log.levels.WARN
      )
    end
    return bundled
  end

  local built, err = M.build()
  if built then
    vim.notify("[imauto] built " .. built, vim.log.levels.INFO)
    return built
  end
  return nil, err
end

return M
