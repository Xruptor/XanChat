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

local isSecretValue = function(v)
	local fn = _G.issecretvalue
	if type(fn) == "function" then
		local ok, res = pcall(fn, v)
		if ok then return not not res end
		return true
	end
	return false
end

local canAccessValue = function(v)
	local fn = _G.canaccessvalue
	if type(fn) == "function" then
		local ok, res = pcall(fn, v)
		if ok then return not not res end
		return false
	end
	return true
end

local function dbgValue(v)
	local t = type(v)
	if t == "string" then
		if isSecretValue(v) then
			return "<secret-string>"
		end
		if not canAccessValue(v) then
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
-- UTILITY FUNCTIONS
-- ============================================================================

local function ApplyDefaults(target, defaults)
	if not target or not defaults then return end
	for key, value in pairs(defaults) do
		if target[key] == nil then
			target[key] = value
		end
	end
end

-- Secret Value Protection Functions
local function isSafeString(v)
	if isSecretValue(v) then return false end
	if not canAccessValue(v) then return false end
	if type(v) ~= "string" then return false end
	return true
end

local function safestr(v)
	if isSecretValue(v) then return "<secret-string>" end
	if not canAccessValue(v) then return "<inaccessible-string>" end
	if type(v) ~= "string" then return "" end
	return v
end

-- Color Helper
local function RGBAToHex(r, g, b, a)
	r = math.min(math.max(tonumber(r) or 1, 0), 1)
	g = math.min(math.max(tonumber(g) or 1, 0), 1)
	b = math.min(math.max(tonumber(b) or 1, 0), 1)
	a = math.min(math.max(tonumber(a) or 1, 0), 1)
	return string.format("%02X%02X%02X%02X", a * 255, r * 255, g * 255, b * 255)
end

local function HexToRGBA(hex)
	if type(hex) ~= "string" or #hex < 8 then
		return 1, 1, 1, 1
	end
	return tonumber("0x" .. string.sub(hex, 3, 4), 10) / 255,
		tonumber("0x" .. string.sub(hex, 5, 6), 10) / 255,
		tonumber("0x" .. string.sub(hex, 7, 8), 10) / 255,
		tonumber("0x" .. string.sub(hex, 1, 2), 10) / 255
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.dbg = dbg
addon.dbgValue = dbgValue
addon.ApplyDefaults = ApplyDefaults
addon.isSecretValue = isSecretValue
addon.canAccessValue = canAccessValue
addon.isSafeString = isSafeString
addon.safestr = safestr
addon.RGBAToHex = RGBAToHex
addon.HexToRGBA = HexToRGBA
