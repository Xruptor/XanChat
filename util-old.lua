local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]


--- A lightweight, standalone SecureHook implementation for XanChat.
--- This function safely wraps an existing function (the "original").
--- The provided 'handler' function will be called in its place.
---
--- The handler receives the original function as its first argument, so it can
--- choose when or if to call it.
---
--- CRITICALLY, if the game is in a restricted state (like combat), this hook
--- will automatically and safely call the original function, bypassing the
--- handler entirely to prevent taint errors.
---
--- Usage:
---   addon:SecureHook(TargetObject, "MethodName", YourHandlerFunction)
---   addon:SecureHook("GlobalFunctionName", YourHandlerFunction)
---
function addon:SecureHook(target, method, handler)
	-- Handle different argument styles, e.g., SecureHook("Func", handler) vs SecureHook(Frame, "OnClick", handler)
	if type(target) == "string" then
		handler = method
		method = target
		target = _G
    end

			-- --- Validate Inputs ---
	if not target or type(target) ~= "table" then
		print(ADDON_NAME .. ": SecureHook failed. Target must be a table or frame.")
		return
    end

	if type(method) ~= "string" or not target[method] then
		print(ADDON_NAME .. ": SecureHook failed. Method '"..tostring(method).."' does not exist on the target.")
		return
	end

	-- If handler is a string, resolve it to a method on our addon object
	if type(handler) ~= "function" then
		handler = self[handler]
    end

 	if type(handler) ~= "function" then
		print(ADDON_NAME .. ": SecureHook failed. Handler must be a function or a method name on the addon.")
		return
 	end

 	local original = target[method]

	-- Create the new function that will replace the original
	local new_func = function(...)
		-- The core safety check. If we are in combat or a chat lockdown,
		-- we immediately call the original function with its arguments and do nothing else.
		-- This is the "secure" part of the hook that prevents taint.
		if InCombatLockdown() or (addon.IsChatLockdown and addon:IsChatLockdown()) then
			return original(...)
		end

    		-- If we are not in a restricted state, call our custom handler function.
		-- We pass the original function as the first argument so the handler can
		-- use it. This allows the handler to act as a pre-hook, post-hook, or
		-- a complete replacement.
		return handler(original, ...)

    end

	-- Replace the original function on the target with our new, safe wrapper function.
	target[method] = new_func

end

--- Helper function to check for Blizzard's chat lockdown.
--- This is used by our SecureHook to determine if it should bypass the handler.
function addon:IsChatLockdown()
	local api = _G.C_ChatInfo
	if api and api.InChatMessagingLockdown then
		-- Use a protected call (pcall) in case the API itself errors.
		local ok, locked = pcall(api.InChatMessagingLockdown)
		if ok then
			return not not locked
		end
    end
    return false
end