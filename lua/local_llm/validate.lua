local M = {}

function M.validate_candidate(word, prefix, opts)
  if type(word) ~= "string" then return nil end

  -- 1. Strip surrounding quotes (sometimes LLMs wrap output)
  word = word:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")

  -- 2. Extract ONLY the valid word characters.
  -- This automatically strips hidden Unicode spaces, markdown, and punctuation!
  local pattern = opts.allow_hyphenated and "[%w][%w%-]*[%w]" or "[%w]+"
  local matched = word:match(pattern) or word:match("[%w]")
  if not matched then return nil end
  word = matched

  -- 3. Reject newlines / multi-line output (should be gone, but just in case)
  if word:match("[\r\n]") then return nil end

  -- 4. Reject internal whitespace
  if word:match("%s") then return nil end

  local pl = prefix:lower()
  local wl = word:lower()

  -- 5. The candidate must START WITH the prefix (case-insensitive).
  if #wl < #pl then return nil end
  if wl:sub(1, #pl) ~= pl then return nil end

  -- 6. Reject the prefix itself (no useful completion)
  if wl == pl then return nil end

  -- 7. Reject obvious prefix duplication like "scatscat"
  if #wl == 2 * #pl and wl == pl .. pl then return nil end

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
