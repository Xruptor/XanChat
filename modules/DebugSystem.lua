--[[
	DebugSystem.lua - Debug logging and value inspection for XanChat
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- Debug functions will be added to addon when this module loads
-- The addon object is expected to be available in addon

-- ============================================================================
-- DEBUG SYSTEM
-- ============================================================================

local DEBUG_PREFIX = "XanChatDebug"

local function dbg(msg)
	if not msg then return end

	-- Get addon reference
	if not addon then return end

	if not (addon.debugChat or (_G.XCHT_DB and _G.XCHT_DB.debugChat)) then return end
	if _G.DEFAULT_CHAT_FRAME and _G.DEFAULT_CHAT_FRAME.AddMessage then
		pcall(_G.DEFAULT_CHAT_FRAME.AddMessage, _G.DEFAULT_CHAT_FRAME, DEBUG_PREFIX..": "..msg)
	end
end

--apparently you can do tostring() on secret values and they will print out in chat, but you cannot copy it to a copyframe, a placeholder would have to be used
local doSafeToString = function(v)
	local fn = tostring
	if type(fn) == "function" then
		local ok, res = pcall(fn, v)
		if ok and res then
			return ok, res
		end
	end
	return false
end

local function safeValue(v, depth)
	depth = depth or 0
	if depth > 5 then
		return "<max-depth-reached>"
	end

	local t = type(v)
	if t == "string" then
		if addon.isSecretValue(v) then
			local boolChk, safeToString = doSafeToString(v)
			return "<secret-string>"..(boolChk and "-> "..safeToString)
		end
		if not addon.canAccessValue(v) then
			return "<inaccessible-string>"
		end
		return v
	end
	if t == "number" or t == "boolean" then
		return tostring(v)
	end
	if v == nil then
		return "nil"
	end
	if t == "table" then
		if v.GetObjectType then
			local name = v:GetName()
			if name then
				return "<Frame:"..name..">"
			end
			return "<Frame:anonymous>"
		end

		local mt = getmetatable(v)
		if mt and mt.__index then
			return "<table-with-metatable>"
		end

		if v.pcall or (type(v[1]) == "function" and #v > 0) then
			return "<table-function>"
		end

		local result = "{"
		local count = 0
		for k, val in pairs(v) do
			count = count + 1
			if count > 10 then
				result = result.." ...<truncated>"
				break
			end
			local keyStr = safeValue(k, depth + 1)
			local valStr = safeValue(val, depth + 1)
			result = result.."["..keyStr.."]="..valStr..", "
		end
		result = result.."}"
		return result
	end
	if t == "function" then
		return "<function>"
	end
	if t == "userdata" then
		return "<userdata>"
	end
	return "<"..t..">"
end

local function safeLength(v)
	if addon.isSecretValue and addon.isSecretValue(v) then
		return 0
	end
	if addon.canAccessValue and not addon.canAccessValue(v) then
		return 0
	end
	if type(v) ~= "string" then
		return 0
	end
	return #v
end

local function safeSub(v, startPos, length)
	if addon.isSecretValue and addon.isSecretValue(v) then
		local boolChk, safeToString = doSafeToString(v)
		return "<secret-string>"..(boolChk and "-> "..safeToString)
	end
	if addon.canAccessValue and not addon.canAccessValue(v) then
		return "<inaccessible-string>"
	end
	if type(v) ~= "string" then
		return "<non-string>"
	end
	if length then
		return string.sub(v, startPos or 1, (startPos or 1) + length - 1)
	end
	return string.sub(v, startPos or 1)
end

local function safeBool(v)
	if v == true then return "true" end
	if v == false then return "false" end
	return safeValue(v)
end

local function debugPrint(...)
	if not (addon.debugChat or (_G.XCHT_DB and _G.XCHT_DB.debugChat)) then return end
	local out = {}
	for i = 1, select("#", ...) do
		out[#out + 1] = safeValue(select(i, ...))
	end
	local ok, line = pcall(table.concat, out, " ")
	if not ok then
		line = "<error: failed to concatenate values>"
	end
	dbg(line)
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.dbg = dbg
addon.dbgValue = safeValue
addon.dbgSafeValue = safeValue
addon.dbgSafeLength = safeLength
addon.dbgSafeSub = safeSub
addon.dbgSafeBool = safeBool
addon.DebugPrint = debugPrint
addon.DebugValue = safeValue
