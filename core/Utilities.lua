--[[
	Utilities.lua
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}


local function isInAnyInstance()
	if not _G.IsInInstance then return false end
	return _G.select(1, _G.IsInInstance())
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

local function safestr_bool(v)
	if isSecretValue(v) then return true end
	if not canAccessValue(v) then return true end
	if type(v) ~= "string" then return true end
	return false
end


addon.isInAnyInstance = isInAnyInstance
addon.ApplyDefaults = ApplyDefaults
addon.isSecretValue = isSecretValue
addon.canAccessValue = canAccessValue
addon.isSafeString = isSafeString
addon.safestr = safestr
addon.safestr_bool = safestr_bool
