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
  local src = M.swift_source_path()

  local bin_m = mtime_sec(bundled)
  local src_m = mtime_sec(src)

  -- Reuse the existing binary only when it's at least as new as the source.
  -- After `git pull`, an updated swift file gets a fresh mtime while the
  -- gitignored binary keeps its old one, so this triggers a rebuild only
  -- when needed.
  if bin_m and (not src_m or bin_m >= src_m) then
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
