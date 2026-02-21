--[[
	This is a standalone implementation of the secure hooking mechanism inspired by AceHook-3.0,
	as used by addons like Prat. It is designed to provide taint-free post-hooks that can be
	deactivated on demand.
]]

local XanChat = select(2, ...) or XanChat
if not XanChat then
	return
end
local Util = XanChat.Util or {}
XanChat.Util = Util

-- Internal tables to track hooks
-- The registry maps objects/functions to their hook identifiers (uid).
-- Actives and handlers use the uid to store state and the handler function.
local registry = setmetatable({}, { __index = function(tbl, key)
	tbl[key] = {}
	return tbl[key]
end })
local handlers = {}
local actives = {}

-- Lua APIs
local type, error, format = type, error, string.format
local hooksecurefunc, _G = hooksecurefunc, _G

-- This function creates the wrapper that gets passed to hooksecurefunc or frame:HookScript().
-- It allows for "unhooking" by checking the 'actives' table before running the real handler.
-- The hook itself is never removed (as hooksecurefunc provides no way to do so), but it becomes inactive.
local function createSecureHookHandler(handler)
	local uid
	uid = function(...)
		if actives[uid] then
			return handler(...)
		end
	end
	return uid
end

--- Securely hooks a function or method.
-- The handler is called AFTER the original function, with the same arguments.
-- This uses the native hooksecurefunc() and is taint-safe.
-- @param object (optional) The table/object containing the method. If nil, a global function is hooked.
-- @param method (string) The name of the function or method to hook.
-- @param handler (function) The function to run after the original.
function Util:SecureHook(object, method, handler)
	local usage = "Usage: XanChat.Util:SecureHook([object], method, handler)"
	if type(object) == "string" then
		-- Shift arguments if object is omitted for global hooks
		handler, method, object = method, object, nil
	end

	-- Parameter validation
	if object and type(object) ~= "table" and type(object) ~= "userdata" then
		error(format("%s: 'object' - expecting nil, table, or userdata, but got %s", usage, type(object)), 2)
	end
	if type(method) ~= "string" then
		error(format("%s: 'method' - expecting string, but got %s", usage, type(method)), 2)
	end
	if type(handler) ~= "function" then
		error(format("%s: 'handler' - expecting function, but got %s", usage, type(handler)), 2)
	end

	-- Prevent re-hooking the same function with this system
	local hookMap = object and registry[object] or registry
	if hookMap[method] then
		error(format("Hook for '%s' already exists.", method), 2)
	end

	local uid = createSecureHookHandler(handler)

	if object then
		hooksecurefunc(object, method, uid)
		registry[object][method] = uid
	else
		hooksecurefunc(method, uid)
		registry[method] = uid
	end

	actives[uid] = true
	handlers[uid] = handler
end

--- Securely hooks a frame script.
-- The handler is called AFTER the original script, with the same arguments.
-- This uses frame:HookScript() and is taint-safe.
-- @param frame (Frame) The frame object to hook the script on.
-- @param script (string) The name of the script to hook (e.g., "OnShow", "OnEvent").
-- @param handler (function) The function to run after the original script.
function Util:SecureHookScript(frame, script, handler)
	local usage = "Usage: XanChat.Util:SecureHookScript(frame, script, handler)"

	-- Parameter validation
	if type(frame) ~= "table" or type(frame.HookScript) ~= "function" then
		error(format("%s: 'frame' - expecting a frame object, but got %s", usage, type(frame)), 2)
	end
	if type(script) ~= "string" then
		error(format("%s: 'script' - expecting string, but got %s", usage, type(script)), 2)
	end
	if type(handler) ~= "function" then
		error(format("%s: 'handler' - expecting function, but got %s", usage, type(handler)), 2)
	end

	-- Prevent re-hooking
	if registry[frame] and registry[frame][script] then
		error(format("Hook for script '%s' on frame '%s' already exists.", script, frame:GetName() or 'unknown'), 2)
	end

	local uid = createSecureHookHandler(handler)

	frame:HookScript(script, uid)

	registry[frame][script] = uid
	actives[uid] = true
	handlers[uid] = handler
end

--- Deactivates a hook created with SecureHook or SecureHookScript.
function Util:Unhook(object, method)
	if type(object) == "string" then
		method, object = object, nil
	end

	local hookMap = object and registry[object] or registry
	local uid = hookMap and hookMap[method]

	if not uid or not actives[uid] then
		return false -- Not hooked or already unhooked
	end

	actives[uid] = nil
	handlers[uid] = nil

	if object then
		registry[object][method] = nil
	else
		registry[method] = nil
	end

	return true
end
