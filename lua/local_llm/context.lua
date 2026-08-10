local M = {}
local WORD_AT_END = vim.regex and vim.regex("\\k\\+$") or nil

function M.get_prefix_from_line(line, col)
  if not line or col <= 0 then return nil end
  local before = line:sub(1, col)
  if before == "" then return nil end
  if not WORD_AT_END then return nil end
  local s, e = WORD_AT_END:match_str(before)
  if not s then return nil end
  return {
    prefix    = before:sub(s + 1, e),
    start_col = s,
    end_col   = e,
  }
end

function M.get_prefix_from_ctx(ctx)
  -- FIX: blink.cmp provides the full line in ctx.line, and 0-based byte col in ctx.cursor[2]
  local line = ctx.line or ""
  local col = ctx.cursor[2]
  
  local info = M.get_prefix_from_line(line, col)
  if not info then return nil end
  info.line = ctx.cursor[1]
  return info
end

function M.get_context(bufnr, cursor, max_chars)
  local row = cursor[1]
  if row < 1 then row = 1 end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row, false)
  return M.get_context_from_lines(lines, row, cursor[2], max_chars)
end

function M.get_context_from_lines(lines, row, col, max_chars)
  local parts = {}
  local total = 0
  local r = row
  while r >= 1 and total < max_chars do
    local line = lines[r] or ""
    if r == row then
      line = line:sub(1, col)
    end
    table.insert(parts, 1, line)
    total = total + #line + 1
    r = r - 1
  end
  local text = table.concat(parts, "\n")
  if #text > max_chars then
    text = text:sub(#text - max_chars + 1)
  end
  return text
end

return M
