local M = {}

function M.validate_candidate(word, prefix, opts)
	if type(word) ~= "string" then
		return nil
	end

	-- Strip quotes
	word = word:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")

	local pattern
	if opts.completion_mode == "prose" then
		-- Allow letters, numbers, spaces, and basic sentence punctuation
		pattern = "[%w%p%s]+"
	else
		pattern = opts.allow_hyphenated and "[%w][%w%-]*[%w]" or "[%w]+"
	end

	local matched = word:match(pattern)
	if not matched then
		return nil
	end
	word = matched

	-- Trim leading/trailing whitespace
	word = word:match("^%s*(.-)%s*$")
	if not word or word == "" then
		return nil
	end

	-- Strictly reject newlines and markdown in all modes
	if word:match("[\r\n]") then
		return nil
	end
	if word:match("[%*`_#%[%]!]") then
		return nil
	end

	-- Enforce max_words limit in prose mode
	if opts.completion_mode == "prose" and opts.max_words then
		-- Count words by counting sequences of non-whitespace characters
		local _, count = word:gsub("%S+", "")
		if count > opts.max_words then
			return nil
		end
	end

	local pl = prefix:lower()
	local wl = word:lower()

	-- If there is a prefix, the candidate MUST START WITH it
	if pl and pl ~= "" then
		if #wl < #pl then
			return nil
		end
		if wl:sub(1, #pl) ~= pl then
			return nil
		end
		if wl == pl then
			return nil
		end
	end

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
		if #out >= 5 then
			break
		end
	end
	return out
end

return M
