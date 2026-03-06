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
		pcall(_G.DEFAULT_CHAT_FRAME.AddMessage, _G.DEFAULT_CHAT_FRAME, DEBUG_PREFIX .. ": " .. msg)
	end
end

local function dbgValue(v)
	local t = type(v)
	if t == "string" then
		if addon.isSecretValue(v) then
			return "<secret-string>"
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
	return "<" .. t .. ">"
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.dbg = dbg
addon.dbgValue = dbgValue
