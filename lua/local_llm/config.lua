local M = {}

M.defaults = {
	endpoint = "http://127.0.0.1:8080/v1/chat/completions",
	model = "local",
	api_key = nil,

	-- "word" (1 word strictly) or "prose" (up to max_words)
	completion_mode = "prose",
	max_words = 5, -- Maximum number of words per candidate

	debounce_ms = 150,
	max_context_chars = 1200,
	max_tokens = 64,
	temperature = 0.2,
	timeout_ms = 5000,

	enabled_filetypes = { "text", "markdown", "tex", "plaintex", "rst", "org" },
	disabled_filetypes = {},
	allow_hyphenated = true,
	cache_size = 256,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	opts = opts or {}
	M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)
	return M.options
end

return M
