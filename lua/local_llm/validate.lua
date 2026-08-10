local M = {}

function M.validate_candidate(word, prefix, opts)
	opts = opts or {}
	if type(word) ~= "string" then
		return nil
	end

	-- Strip quotes
	word = word:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")

	local pattern
	if opts.completion_mode == "prose" then
		pattern = "[%w%p%s]+"
	else
		-- Match alphanumeric words, including single characters and hyphenated terms
		pattern = opts.allow_hyphenated and "[%w%-]+" or "[%w]+"
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

	-- Strictly reject newlines and markdown
	if word:match("[\r\n]") then
		return nil
	end
	if word:match("[%*`_#%[%]!]") then
		return nil
	end

	-- Enforce max_words limit
	if opts.completion_mode == "prose" and opts.max_words then
		local _, count = word:gsub("%S+", "")
		if count > opts.max_words then
			return nil
		end
	end

	prefix = prefix or ""
	local pl = prefix:lower()
	local wl = word:lower()

	-- If there is a prefix, ensure the final candidate starts with it
	if pl and pl ~= "" then
		if wl:sub(1, #pl) ~= pl then
			-- 1. Overlap check: Trim preceding context if the LLM repeated it (e.g. prefix="ele", word="Gas electron multipliers")
			local s = wl:find(pl, 1, true)
			if s and s > 1 then
				local candidate = word:sub(s)
				if candidate:lower():sub(1, #pl) == pl then
					word = candidate
					wl = word:lower()
				end
			end

			-- 2. Suffix check: Only prepend prefix if it's a hyphenated term or a single-word suffix
			if wl:sub(1, #pl) ~= pl then
				local last_prefix_char = prefix:sub(-1)
				local is_hyphenated = (last_prefix_char == "-")
				local is_single_word_suffix = (opts.completion_mode == "word")
					and not word:find("%s")
					and word:sub(1, 1):match("%l")

				if is_hyphenated or is_single_word_suffix then
					word = prefix .. word
					wl = word:lower()
				end
			end
		end

		-- Final Guard: Candidate MUST start with the prefix and NOT equal the prefix exactly
		if wl:sub(1, #pl) ~= pl or wl == pl then
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
