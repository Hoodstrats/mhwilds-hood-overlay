local sdk = sdk

local hook = {}

-- TODO: store the hunter calls etc in hook.CACHE
hook.CACHE = {}

--- @param typename string
--- @param method string
--- @param prefun function
--- @param postfun function
function hook.HookThis(typename, method, prefun, postfun)
	if typename == nil or method == nil then
		print("typename or method is nil")
		return
	end
	if hook.GetTheType(typename) == nil then
		print("type not found")
		return
	end
	if prefun == nil then
		prefun = function(args) end
	end
	if postfun == nil then
		postfun = function(retval)
			return retval
		end
	end
	sdk.hook(sdk.find_type_definition(typename):get_method(method), prefun, postfun)
end

--- @param typename string
--- @param native boolean
function hook.GetSingleton(typename, native)
	if hook.GetTheType(typename) == nil then
		print("type not found")
		return
	end
	if native then
		return sdk.get_native_singleton(typename)
	else
		return sdk.get_managed_singleton(typename)
	end
end

--- @param typename string
function hook.GetTheType(typename)
	local type = sdk.find_type_definition(typename)
	if type then
		return type
	end
end

--- Gets the screen res with error handling
--- @param scene_man any
--- @return number width, number height
function hook.GetRes(scene_man)
	if not scene_man then
		return 1920, 1080
	end

	local mngr_type = hook.GetTheType("via.SceneManager")
	if not mngr_type then
		return 1920, 1080
	end

	local scene_view = sdk.call_native_func(scene_man, mngr_type, "get_MainView")
	if not scene_view then
		return 1920, 1080
	end

	local view_type = hook.GetTheType("via.SceneView")
	if not view_type then
		return 1920, 1080
	end

	local get_size = view_type:get_method("get_Size")
	if not get_size then
		return 1920, 1080
	end

	local size = get_size:call(scene_view)
	if not size then
		return 1920, 1080
	end

	local size_type = get_size:get_return_type()
	if not size_type then
		return 1920, 1080
	end

	local width_field = size_type:get_field("w")
	local height_field = size_type:get_field("h")
	if not width_field or not height_field then
		return 1920, 1080
	end

	local width = width_field:get_data(size)
	local height = height_field:get_data(size)
	if not width or not height then
		return 1920, 1080
	end

	return width, height
end

return hook
