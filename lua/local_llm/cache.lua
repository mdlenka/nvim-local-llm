local M = {}

function M.new(max_size)
	local self = setmetatable({}, { __index = M })
	self.entries = {}
	self.order = {}
	self.max_size = max_size or 256
	return self
end

function M:key(model, context, prefix)
	return (model or "") .. "\0" .. (context or "") .. "\0" .. (prefix or "")
end

function M:get(key)
	local e = self.entries[key]
	if not e then
		return nil
	end
	for i, k in ipairs(self.order) do
		if k == key then
			table.remove(self.order, i)
			break
		end
	end
	table.insert(self.order, key)
	return e
end

function M:set(key, value)
	if self.entries[key] then
		for i, k in ipairs(self.order) do
			if k == key then
				table.remove(self.order, i)
				break
			end
		end
	end
	self.entries[key] = value
	table.insert(self.order, key)
	while #self.order > self.max_size do
		local old = table.remove(self.order, 1)
		self.entries[old] = nil
	end
end

function M:size()
	return #self.order
end

return M
