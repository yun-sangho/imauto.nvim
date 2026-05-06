local M = {}

local function plugin_root()
  local source = debug.getinfo(1, "S").source
  local path = source:sub(2):gsub("/lua/imauto/native%.lua$", "")
  return path
end

local function file_exists(path)
  local stat = vim.uv and vim.uv.fs_stat(path) or vim.loop.fs_stat(path)
  return stat ~= nil
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

function M.resolve(explicit_cmd)
  if explicit_cmd and explicit_cmd ~= "" then
    if vim.fn.executable(explicit_cmd) == 1 then
      return explicit_cmd
    end
    return nil, "configured cmd not executable: " .. explicit_cmd
  end

  local bundled = M.bundled_binary_path()
  if file_exists(bundled) then
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
