local config     = require("local_llm.config")
local source_mod = require("local_llm.source")

local M = {}

function M.setup(opts)
  return config.setup(opts)
end

function M.new(opts)
  local merged = vim.tbl_deep_extend(
    "force",
    vim.deepcopy(config.options or config.defaults),
    opts or {}
  )
  return source_mod.new(merged)
end

return M
