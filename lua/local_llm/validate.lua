local M = {}

function M.validate_candidate(word, prefix, opts)
	if type(word) ~= "string" then
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

	local pl = prefix:lower()
	local wl = word:lower()

	-- If there is a prefix, ensure the final output starts with it
	if pl and pl ~= "" then
		if wl:sub(1, #pl) ~= pl then
			-- LLM returned a suffix or next word instead of the full text.
			-- We will reconstruct it by prepending the prefix.
			if pl:sub(-1):match("[%w]") and wl:sub(1, 1):match("[%w]") then
				-- e.g., prefix="s", word="ystem" -> "system"
				word = prefix .. word
			else
				-- e.g., prefix="This", word="sentence" -> "This sentence"
				word = prefix .. " " .. word
			end
			wl = word:lower()
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
