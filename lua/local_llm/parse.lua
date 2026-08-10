local M = {}

local function extract_words(t)
	local res = {}
	for _, v in ipairs(t) do
		if type(v) == "string" then
			table.insert(res, v)
		elseif type(v) == "table" then
			table.insert(res, table.concat(v, " "))
		end
	end
	return res
end

local function try_decode(s)
	local ok, decoded = pcall(vim.json.decode, s)
	if not ok or type(decoded) ~= "table" then
		return nil
	end

	if type(decoded.completions) == "table" then
		return extract_words(decoded.completions)
	end
	if type(decoded.words) == "table" then
		return extract_words(decoded.words)
	end
	if type(decoded.candidates) == "table" then
		return extract_words(decoded.candidates)
	end
	if decoded[1] ~= nil then
		return extract_words(decoded)
	end
	return nil
end

function M.parse_words(resp)
	if type(resp) ~= "table" then
		return {}
	end

	local content
	if resp.choices and resp.choices[1] and resp.choices[1].message then
		content = resp.choices[1].message.content
		if type(content) ~= "string" or content == "" then
			content = resp.choices[1].message.reasoning_content
		end
	elseif type(resp.content) == "string" then
		content = resp.content
	elseif type(resp.text) == "string" then
		content = resp.text
	end

	if type(content) ~= "string" or content == "" then
		return {}
	end

	local direct = try_decode(content)
	if direct then
		return direct
	end

	local fenced = content:match("```json%s*(.-)%s*```") or content:match("```%s*(.-)%s*```")
	if fenced then
		local f = try_decode(fenced)
		if f then
			return f
		end
	end

	local obj = content:match("{.*}")
	if obj then
		local o = try_decode(obj)
		if o then
			return o
		end
	end

	local arr = content:match("%[.*%]")
	if arr then
		local a = try_decode(arr)
		if a then
			return a
		end
	end

	local words = {}
	for w in content:gmatch("[%w][%w%-]+") do
		table.insert(words, w)
	end
	return words
end

return M
