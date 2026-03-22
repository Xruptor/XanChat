--[[
	DebugSystem.lua - Debug logging and value inspection for XanChat
	Improvements:
	- Simplified safeToString with inline check
	- Consolidated type handling in safeValue
	- Reduced nested conditionals
	- Better early returns throughout
	- Improved safeLength and safeSub with guards
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- DEBUG SYSTEM
-- ============================================================================

local DEBUG_PREFIX = "XanChatDebug"
local MAX_DEPTH = 5
local MAX_TABLE_ITEMS = 10

-- Basic debug output to chat
local function dbg(msg)
	if not msg or not (addon.debugChat or (_G.XCHT_DB and _G.XCHT_DB.debugChat)) or not (_G.DEFAULT_CHAT_FRAME and _G.DEFAULT_CHAT_FRAME.AddMessage) then
		return
	end

	pcall(_G.DEFAULT_CHAT_FRAME.AddMessage, _G.DEFAULT_CHAT_FRAME, DEBUG_PREFIX..": "..msg)
end

-- Safely convert value to string for debugging
local function safeToString(v)
	local ok, res = pcall(tostring, v)
	return ok and res or ""
end

-- Recursively convert value to safe string representation
local function safeValue(v, depth)
	depth = depth or 0
	if depth > MAX_DEPTH then
		return "<max-depth-reached>"
	end

	local t = type(v)

	-- Handle strings (check for secret values)
	if t == "string" then
		if addon.isSecretValue and addon.isSecretValue(v) then
			return "<secret-string> ¦¦¦ "..safeToString(v)
		end
		if addon.canAccessValue and not addon.canAccessValue(v) then
			return "<inaccessible-string>"
		end
		return v
	end

	-- Handle simple types
	if t == "number" or t == "boolean" then
		return tostring(v)
	end
	if v == nil then
		return "nil"
	end

	-- Handle frames (game objects)
	if t == "table" and v.GetObjectType then
		local name = v:GetName()
		return name and "<Frame:"..name..">" or "<Frame:anonymous>"
	end

	-- Handle tables with metatables (protected objects)
	if t == "table" then
		local mt = getmetatable(v)
		if mt and mt.__index then
			return "<table-with-metatable>"
		end
		if v.pcall or (type(v[1]) == "function" and #v > 0) then
			return "<table-function>"
		end
	end

	-- Handle regular tables
	if t == "table" then
		local result = "{"
		local count = 0
		for k, val in pairs(v) do
			count = count + 1
			if count > MAX_TABLE_ITEMS then
				result = result.." ...<truncated>"
				break
			end
			result = result.."["..safeValue(k, depth + 1).."]="..safeValue(val, depth + 1)..", "
		end
		return result.."}"
	end

	-- Handle functions and userdata
	if t == "function" then return "<function>" end
	if t == "userdata" then return "<userdata>" end

	return "<"..t..">"
end

-- Get safe length of string (returns 0 for secret values)
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

-- Get safe substring (handles secret values)
local function safeSub(v, startPos, length)
	if addon.isSecretValue and addon.isSecretValue(v) then
		return "<secret-string> ¦¦¦ "..safeToString(v)
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

-- Convert boolean to safe string representation
local function safeBool(v)
	if v == true then return "true" end
	if v == false then return "false" end
	return safeValue(v)
end

-- Multi-argument debug print with safe value conversion
local function debugPrint(...)
	if not (addon.debugChat or (_G.XCHT_DB and _G.XCHT_DB.debugChat)) then return end

	local out = {}
	for i = 1, select("#", ...) do
		out[i] = safeValue(select(i, ...))
	end

	local ok, line = pcall(table.concat, out, " ")
	dbg(ok and line or "<error: failed to concatenate values>")
end

-- ============================================================================
-- CHAT LOCKDOWN AND ENCOUNTER DEBUG FUNCTIONS
-- ============================================================================

local _chatLockdownLast = nil

-- Debug-only: Chat lockdown state probe
function addon:CheckChatLockdownState()
	if not self.dbg or not (_G.C_ChatInfo and _G.C_ChatInfo.InChatMessagingLockdown) then return end

	local isLocked = _G.C_ChatInfo.InChatMessagingLockdown()
	if _chatLockdownLast == isLocked then return end

	_chatLockdownLast = isLocked
	self.dbg("ChatLockdown: state=" .. (self.dbgSafeBool and self.dbgSafeBool(isLocked) or tostring(isLocked)))
	if self.DebugChatHandlerState then
		self:DebugChatHandlerState("chat-lockdown-change")
	end
end

function addon:OnEncounterStart()
	if not self.dbg then return end
	self.dbg("OnEncounterStart: encounter started (debug only, no hook changes)")
	if self.DebugChatHandlerState then
		self:DebugChatHandlerState("encounter-start")
	end
end

function addon:OnEncounterEnd()
	if not self.dbg then return end
	self.dbg("OnEncounterEnd: encounter ended (debug only, no hook changes)")
	if self.DebugChatHandlerState then
		self:DebugChatHandlerState("encounter-end")
	end
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
