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

	-- If there is a prefix, ensure the final output starts with it
	if pl and pl ~= "" then
		if wl:sub(1, #pl) ~= pl then
			-- LLM returned a suffix for the first word. Reconstruct it.
			local first_word, rest = word:match("^(%S+)(.*)$")
			if first_word then
				local last_char = pl:sub(-1)
				if (last_char:match("[%w]") or last_char == "-") and first_word:sub(1, 1):match("[%w]") then
					-- e.g., prefix="scat", word="tering tomography" -> "scattering tomography"
					-- e.g., prefix="high-", word="energy" -> "high-energy"
					word = prefix .. first_word .. (rest or "")
				else
					-- e.g., prefix="This", word="sentence continues" -> "This sentence continues"
					word = prefix .. " " .. first_word .. (rest or "")
				end
				wl = word:lower()
			else
				word = prefix .. word
				wl = word:lower()
			end
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
