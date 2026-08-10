local M = {}
local WORD_AT_END = vim.regex and vim.regex("\\k\\+$") or nil

function M.get_prefix_from_line(line, col)
	if not line or col <= 0 then
		return nil
	end
	local before = line:sub(1, col)
	if before == "" then
		return nil
	end
	if not WORD_AT_END then
		return nil
	end
	local s, e = WORD_AT_END:match_str(before)
	if not s then
		return nil
	end
	return {
		prefix = before:sub(s + 1, e),
		start_col = s,
		end_col = e,
	}
end

function M.get_prefix_from_ctx(ctx)
	if not ctx or not ctx.cursor then
		return nil
	end
	local line = ctx.line or ""
	local col = ctx.cursor[2] or 0

	local info = M.get_prefix_from_line(line, col)
	if not info then
		return nil
	end
	info.line = ctx.cursor[1]
	return info
end

function M.get_context(bufnr, cursor, mode, max_chars)
	if not cursor or not cursor[1] then
		return ""
	end
	local row = cursor[1]
	if row < 1 then
		row = 1
	end
	max_chars = max_chars or 1200

	if mode == "word" then
		-- Full single line context up to current cursor position
		local lines = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)
		local line = lines[1] or ""
		return line:sub(1, cursor[2] or 0)
	else
		-- Prose mode: scan backwards up to the paragraph boundary (empty line)
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row, false)

		local para_start = #lines
		while para_start > 1 do
			local prev_line = lines[para_start - 1]
			if prev_line:match("^%s*$") then
				break
			end
			para_start = para_start - 1
		end

		local parts = {}
		for i = para_start, #lines do
			local line = lines[i] or ""
			if i == #lines then
				line = line:sub(1, cursor[2] or 0)
			end
			table.insert(parts, line)
		end

		local text = table.concat(parts, "\n")
		if #text > max_chars then
			text = text:sub(#text - max_chars + 1)
		end
		return text
	end
end

return M
