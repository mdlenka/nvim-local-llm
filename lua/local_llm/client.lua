local M = {}

function M.request(opts, cb)
  local body = vim.json.encode({
    model       = opts.model,
    messages    = opts.messages,
    temperature = opts.temperature,
    max_tokens  = opts.max_tokens,
    stream      = false,
  })

  local args = {
    "curl", "-sS", "-X", "POST", opts.endpoint,
    "--max-time", tostring(math.floor((opts.timeout_ms or 5000) / 1000) + 1),
    "-H", "Content-Type: application/json",
  }
  if opts.api_key and opts.api_key ~= "" then
    table.insert(args, "-H")
    table.insert(args, "Authorization: Bearer " .. opts.api_key)
  end
  table.insert(args, "-d")
  table.insert(args, body)

  local handle
  local cancelled = false

  handle = vim.system(args, { stdout = true, stderr = true }, function(completed)
    handle = nil
    if cancelled then return end
    if completed.code ~= 0 then
      cb(nil, completed.stderr or ("curl exited with code " .. tostring(completed.code)))
      return
    end
    local out = completed.stdout or ""
    local ok, decoded = pcall(vim.json.decode, out)
    if not ok or type(decoded) ~= "table" then
      cb(nil, "invalid JSON response")
      return
    end
    cb(decoded, nil)
  end)

  return function()
    cancelled = true
    if handle then
      pcall(function() handle:kill(9) end)
      handle = nil
    end
  end
end

return M
