local M = {}

function M.validate_candidate(word, prefix, opts)
	if type(word) ~= "string" then
		print("[Validate] Rejected: not a string")
		return nil
	end

	-- Strip quotes
	word = word:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")

	local pattern
	if opts.completion_mode == "prose" then
		pattern = "[%w%p%s]+"
	else
		pattern = opts.allow_hyphenated and "[%w][%w%-]*[%w]" or "[%w]+"
	end

	local matched = word:match(pattern)
	if not matched then
		print("[Validate] Rejected: pattern failed for '" .. word .. "'")
		return nil
	end
	word = matched

	-- Trim leading/trailing whitespace
	word = word:match("^%s*(.-)%s*$")
	if not word or word == "" then
		print("[Validate] Rejected: empty after trim")
		return nil
	end

	-- Strictly reject newlines and markdown in all modes
	if word:match("[\r\n]") then
		print("[Validate] Rejected: contains newline")
		return nil
	end
	if word:match("[%*`_#%[%]!]") then
		print("[Validate] Rejected: contains markdown")
		return nil
	end

	-- Enforce max_words limit in prose mode
	if opts.completion_mode == "prose" and opts.max_words then
		local _, count = word:gsub("%S+", "")
		if count > opts.max_words then
			print("[Validate] Rejected: too many words (" .. count .. " > " .. opts.max_words .. ")")
			return nil
		end
	end

	local pl = prefix:lower()
	local wl = word:lower()

	-- If there is a prefix, the candidate MUST START WITH it
	if pl and pl ~= "" then
		if #wl < #pl then
			print("[Validate] Rejected: candidate shorter than prefix. Word: '" .. wl .. "', Prefix: '" .. pl .. "'")
			return nil
		end
		if wl:sub(1, #pl) ~= pl then
			print("[Validate] Rejected: does not start with prefix. Word: '" .. wl .. "', Prefix: '" .. pl .. "'")
			return nil
		end
		if wl == pl then
			print("[Validate] Rejected: identical to prefix")
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
	end
	return out
end

return M
