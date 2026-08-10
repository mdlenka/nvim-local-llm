local M = {}

M.defaults = {
  -- Default to llama.cpp's default port
  endpoint = "http://127.0.0.1:8080/v1/chat/completions",
  model = "local",
  api_key = nil,
  debounce_ms        = 150,
  max_context_chars  = 1200,
  max_tokens         = 32,
  temperature        = 0.1,
  timeout_ms         = 5000,
  enabled_filetypes  = { "text", "markdown", "tex", "plaintex", "rst", "org" },
  disabled_filetypes = {},
  allow_hyphenated   = true,
  cache_size         = 256,
  british_english    = true,
}

-- FIX: Initialize with defaults immediately so the plugin works even if setup() isn't called
M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  opts = opts or {}
  vim.validate({
    endpoint         = { opts.endpoint,         "string",  true },
    model            = { opts.model,            "string",  true },
    debounce_ms      = { opts.debounce_ms,      "number",  true },
    max_context_chars= { opts.max_context_chars,"number",  true },
    max_tokens       = { opts.max_tokens,       "number",  true },
    temperature      = { opts.temperature,      "number",  true },
    enabled_filetypes= { opts.enabled_filetypes,"table",   true },
    cache_size       = { opts.cache_size,       "number",  true },
  })
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)
  return M.options
end

return M
