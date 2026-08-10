local M = {}

function M.request(opts, cb)
	local body = vim.json.encode({
		model = opts.model,
		messages = opts.messages,
		temperature = opts.temperature,
		max_tokens = opts.max_tokens,
		stream = false,
	})

	local timeout_sec = math.max(1, math.ceil((opts.timeout_ms or 5000) / 1000))
	local args = {
		"curl",
		"-sS",
		"-X",
		"POST",
		opts.endpoint,
		"--max-time",
		tostring(timeout_sec),
		"-H",
		"Content-Type: application/json",
	}
	if opts.api_key and opts.api_key ~= "" then
		table.insert(args, "-H")
		table.insert(args, "Authorization: Bearer " .. opts.api_key)
	end
	table.insert(args, "-d")
	table.insert(args, body)

	local handle
	local cancelled = false

	handle = vim.system(args, { stdout = true, stderr = true }, function(completed)
		handle = nil
		if cancelled then
			return
		end

		-- Schedule callback execution back onto the Neovim main event loop
		vim.schedule(function()
			if cancelled then
				return
			end
			if completed.code ~= 0 then
				local err_msg = (completed.stderr and completed.stderr ~= "") and completed.stderr
					or ("curl exited with code " .. tostring(completed.code))
				cb(nil, err_msg)
				return
			end
			local out = completed.stdout or ""
			local ok, decoded = pcall(vim.json.decode, out)
			if not ok or type(decoded) ~= "table" then
				cb(nil, "invalid JSON response")
				return
			end
			cb(decoded, nil)
		end)
	end)

	return function()
		cancelled = true
		if handle then
			pcall(function()
				handle:kill(9)
			end)
			handle = nil
		end
	end
end

return M
