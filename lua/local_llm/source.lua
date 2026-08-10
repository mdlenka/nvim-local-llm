local context = require("local_llm.context")
local client = require("local_llm.client")
local validate = require("local_llm.validate")
local cache_mod = require("local_llm.cache")
local prompt = require("local_llm.prompt")
local parse = require("local_llm.parse")

local Source = {}
Source.__index = Source

local KIND_TEXT = 1

function Source.new(opts)
	local self = setmetatable({}, Source)
	self.opts = opts or {}
	self.cache = cache_mod.new(self.opts.cache_size or 256)
	return self
end

function Source:get_trigger_characters()
	return {}
end

function Source:enabled()
	local ft = vim.bo.filetype
	if vim.tbl_contains(self.opts.disabled_filetypes or {}, ft) then
		return false
	end
	if vim.tbl_contains(self.opts.enabled_filetypes or {}, ft) then
		return true
	end
	return false
end

local function build_items(words, prefix_info)
	local items = {}
	for i, word in ipairs(words) do
		table.insert(items, {
			label = word,
			kind = KIND_TEXT,
			detail = "local-llm",
			filterText = word,
			sortText = string.format("%03d", i),
			insertText = word,
			textEdit = {
				range = {
					start = { line = prefix_info.line - 1, character = prefix_info.start_col },
					["end"] = { line = prefix_info.line - 1, character = prefix_info.end_col },
				},
				newText = word,
			},
		})
	end
	return items
end

function Source:get_completions(ctx, callback)
	local cancelled = false
	local timer
	local client_cancel

	local prefix_info = context.get_prefix_from_ctx(ctx)

	if not prefix_info then
		if self.opts.completion_mode == "prose" then
			prefix_info = {
				prefix = "",
				start_col = ctx.cursor[2],
				end_col = ctx.cursor[2],
				line = ctx.cursor[1],
			}
		else
			callback({ items = {}, is_incomplete_forward = false })
			return function() end
		end
	end

	-- GUARANTEE: Ensure ctx_text and prefix are never nil
	local ctx_text = context.get_context(ctx.bufnr, ctx.cursor, self.opts.max_context_chars) or ""
	local prefix = prefix_info.prefix or ""

	local cache_key = self.cache:key(self.opts.model, ctx_text, prefix)
	local cached = self.cache:get(cache_key)

	if cached then
		callback({ items = build_items(cached, prefix_info), is_incomplete_forward = true })
		return function() end
	end

	local messages = {
		{ role = "system", content = prompt.get_system_prompt(self.opts.completion_mode) },
		{ role = "user", content = prompt.build_user_prompt(ctx_text, prefix) },
	}

	timer = vim.defer_fn(function()
		timer = nil
		if cancelled then
			return
		end

		client_cancel = client.request({
			endpoint = self.opts.endpoint,
			model = self.opts.model,
			api_key = self.opts.api_key,
			messages = messages,
			temperature = self.opts.temperature,
			max_tokens = self.opts.max_tokens,
			timeout_ms = self.opts.timeout_ms,
		}, function(resp, err)
			client_cancel = nil
			if cancelled then
				return
			end

			if err or not resp then
				callback({ items = {}, is_incomplete_forward = false })
				return
			end

			local words = parse.parse_words(resp)
			local valid = validate.filter_candidates(words, prefix, {
				allow_hyphenated = self.opts.allow_hyphenated,
				completion_mode = self.opts.completion_mode,
				max_words = self.opts.max_words,
			})

			self.cache:set(cache_key, valid)
			callback({ items = build_items(valid, prefix_info), is_incomplete_forward = true })
		end)
	end, self.opts.debounce_ms or 150)

	return function()
		cancelled = true
		if timer then
			timer:stop()
			timer = nil
		end
		if client_cancel then
			client_cancel()
			client_cancel = nil
		end
	end
end
return Source
