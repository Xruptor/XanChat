--[[
	InstanceWarning.lua - Instance warning system for XanChat
	Refactored for:
	- Simplified instance type checking
	- Improved warning state tracking
	- Better cleanup on shutdown
	- Consolidated redundant nil checks
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- INSTANCE WARNING SYSTEM
-- ============================================================================

-- Instance warning tracking
local _lastInstanceName = nil
local _instanceWarningShown = {}

-- Instance types that trigger chat lockdowns (raids, dungeons, etc.)
local LOCKDOWN_INSTANCE_TYPES = {
	raid = true,
	party = true,
}

-- Check if current instance triggers lockdowns
local function isLockdownInstance()
	if not _G.IsInInstance then return false end

	local inInstance, instanceType = _G.IsInInstance()
	if not inInstance then return false end

	return LOCKDOWN_INSTANCE_TYPES[instanceType] or false
end

-- Get current instance name for tracking
local function getCurrentInstanceName()
	if not _G.GetInstanceInfo then return nil end
	return select(1, _G.GetInstanceInfo())
end

-- Show instance warning message in chat
local function showInstanceWarning()
	if not addon or not addon.L or not addon.L.ChatFeaturesDisabledInstance then
		return
	end

	-- First display (immediate)
	if _G.DEFAULT_CHAT_FRAME and _G.DEFAULT_CHAT_FRAME.AddMessage then
		_G.DEFAULT_CHAT_FRAME:AddMessage("|cFFFA8072" .. addon.L.ChatFeaturesDisabledInstance .. "|r")
	end

	-- Second display after 2 seconds using timer
	_G.C_Timer.After(2, function()
		if _G.DEFAULT_CHAT_FRAME and _G.DEFAULT_CHAT_FRAME.AddMessage then
			_G.DEFAULT_CHAT_FRAME:AddMessage("|cFFFA8072" .. addon.L.ChatFeaturesDisabledInstance .. "|r")
		end
	end)

	if addon.dbg then
		addon.dbg("InstanceWarning: showing warning for instance (with 2-second repeat)")
	end
end

-- Check for instance entry and show warning if needed
local function checkInstanceEntry()
	local currentInstance = getCurrentInstanceName()

	if currentInstance and currentInstance ~= _lastInstanceName then
		if isLockdownInstance() then
			-- Only show warning if we haven't shown it for this instance yet
			if not _instanceWarningShown[currentInstance] then
				showInstanceWarning()
				_instanceWarningShown[currentInstance] = true
			end
		end
	end

	_lastInstanceName = currentInstance
end

-- Zone change event handler
local function onZoneChanged()
	if addon.dbg then
		addon.dbg("InstanceWarning: OnZoneChanged - checking for instance entry")
	end
	checkInstanceEntry()
end

-- Player entering world event handler
local function onPlayerEnteringWorld()
	if addon.dbg then
		addon.dbg("InstanceWarning: OnPlayerEnteringWorld - checking for instance")
	end
	checkInstanceEntry()
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function addon.InitInstanceWarning()
	if not addon or not addon.dbg then
		return false
	end

	addon.dbg("InstanceWarning: initializing instance warning system")

	-- Register event handlers
	if addon.RegisterEvent then
		addon:RegisterEvent("ZONE_CHANGED_NEW_AREA", onZoneChanged)
		addon:RegisterEvent("PLAYER_ENTERING_WORLD", onPlayerEnteringWorld)
	end

	-- Initial check for existing instance
	checkInstanceEntry()
	return true
end

function addon.ShutdownInstanceWarning()
	if addon.dbg then
		addon.dbg("InstanceWarning: shutting down instance warning system")
	end

	-- Unregister event handlers
	if addon.UnregisterEvent then
		addon:UnregisterEvent("ZONE_CHANGED_NEW_AREA", onZoneChanged)
		addon:UnregisterEvent("PLAYER_ENTERING_WORLD", onPlayerEnteringWorld)
	end

	-- Clear tracking data
	_lastInstanceName = nil
	wipe(_instanceWarningShown)
end

function addon.ForceInstanceWarning()
	showInstanceWarning()
end
