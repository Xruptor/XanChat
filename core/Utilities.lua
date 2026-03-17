--[[
	Utilities.lua - Utility functions for XanChat
	Refactored for:
	- Simplified isSecretValue with clearer logic
	- Consolidated redundant nil checks
	- Improved ApplyDefaults with early exit
	- Fixed isNotSafeStr logic (was inverted behavior)
	- Better function organization and clarity
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- INSTANCE DETECTION
-- ============================================================================

local function isInAnyInstance()
	return _G.IsInInstance and select(1, _G.IsInInstance()) or false
end

-- ============================================================================
-- SECRET VALUE PROTECTION
-- ============================================================================

-- issecretvalue fails by raising an error on secret values
-- This is the safe way to test for secret values without causing errors
local function isSecretValue(v)
	local fn = _G.issecretvalue
	if type(fn) ~= "function" then
		return false
	end

	local ok, res = pcall(fn, v)
	-- If pcall fails, the value is secret
	return not (ok and not res)
end

local function canAccessValue(v)
	local fn = _G.canaccessvalue
	if type(fn) ~= "function" then
		return true
	end

	local ok, res = pcall(fn, v)
	return ok and res
end

-- Apply default values to a target table if keys are missing
local function ApplyDefaults(target, defaults)
	if not target or not defaults then
		return
	end

	for key, value in pairs(defaults) do
		if target[key] == nil then
			target[key] = value
		end
	end
end

-- Check if a value is a safe, accessible string
-- Removed redundant isNotSafeStr (logic was inverted and confusing)
local function isSafeString(v)
	return not isSecretValue(v) and canAccessValue(v) and type(v) == "string"
end

-- Return safe string representation for display
local function safestr(v)
	if isSecretValue(v) then
		return "<secret-string>"
	end
	if not canAccessValue(v) then
		return "<inaccessible-string>"
	end
	if type(v) ~= "string" then
		return ""
	end
	return v
end

-- Return boolean indicating if value requires safe string handling
local function safestr_bool(v)
	return isSecretValue(v) or not canAccessValue(v) or type(v) ~= "string"
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.isInAnyInstance = isInAnyInstance
addon.ApplyDefaults = ApplyDefaults
addon.isSecretValue = isSecretValue
addon.canAccessValue = canAccessValue
addon.isSafeString = isSafeString
addon.safestr = safestr
addon.safestr_bool = safestr_bool
