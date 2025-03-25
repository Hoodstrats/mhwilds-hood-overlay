local utils = {}

---@param float number
---@return string
function utils.GetTheString(float)
	if not float then
		return "nil"
	end
	return string.format("%0.1f", float)
end

---@param total_seconds number
---@return string
function utils.GetTheTime(total_seconds)
	local minutes = math.floor(total_seconds / 60)
	local seconds = math.floor(total_seconds % 60)
	local formatted_time = string.format("%02d:%02d", minutes, seconds)
	return formatted_time
end

--- @param unsorted table
--- @return table
function utils.GetSortedTable(unsorted)
	local sorted_table = {}
	for k, v in pairs(unsorted) do
		table.insert(sorted_table, k)
	end
	table.sort(sorted_table) -- this makes it alphabetical
	return sorted_table
end

--- @param table table
--- @param func function
function utils.ForEach(table, func)
	for k, v in pairs(table) do
		func(k, v)
	end
end

--- @param collection table The collection to iterate over
--- @param action function The action to perform on each element (receives key and value)
--- @param sort boolean (optional) Whether to sort keys alphabetically before iterating
function utils.GhettoLoopThis(collection, action, sort)
	if not collection then return end

	if type(collection) == "table" then
		-- Sort keys if requested
		if sort then
			local sorted_keys = utils.GetSortedTable(collection)
			for _, k in ipairs(sorted_keys) do
				action(k, collection[k])
			end
			return
		end

		-- Handle array/ipairs iteration (for sorted tables)
		-- sorted tables are usually looped using ipairs instead of pairs
		if #collection > 0 then
			for i, item in ipairs(collection) do
				action(i, item)
			end
			-- Handle dictionary/pairs iteration
		else
			for key, value in pairs(collection) do
				action(key, value)
			end
		end
	end
end

return utils
