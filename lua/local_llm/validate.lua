local M = {}

function M.validate_candidate(word, prefix, opts)
  if type(word) ~= "string" then return nil end
  word = word:match("^%s*(.-)%s*$")
  if not word or word == "" then return nil end
  word = word:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
  word = word:match("^%s*(.-)%s*$")
  if not word or word == "" then return nil end
  if word:match("[\r\n]") then return nil end
  if word:match("%s") then return nil end
  if word:match("[%*`_#%[%]!]") then return nil end
  if word:match("^[^%w]") then return nil end
  if word:match("[^%w]$")  then return nil end

  if opts.allow_hyphenated then
    if not word:match("^[%w]+(%-[%w]+)*$") then return nil end
  else
    if not word:match("^[%w]+$") then return nil end
  end

  local pl = prefix:lower()
  local wl = word:lower()
  if #word < #pl then return nil end
  if wl:sub(1, #pl) ~= pl then return nil end
  if wl == pl then return nil end
  if #word == 2 * #pl and wl == pl .. pl then return nil end

  return word
end

function M.filter_candidates(words, prefix, opts)
  opts = opts or {}
  local out = {}
  local seen = {}
  for _, w in ipairs(words or {}) do
    local v = M.validate_candidate(w, prefix, opts)
    if v and not seen[v:lower()] then
      seen[v:lower()] = true
      table.insert(out, v)
    end
    if #out >= 10 then break end
  end
  return out
end

return M
