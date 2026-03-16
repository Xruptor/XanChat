--[[
	InstanceWarning.lua - Instance warning system for XanChat
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

-- Check if current instance is one where chat lockdowns would occur (raids, dungeons, etc.)
local function isLockdownInstance()
	if not _G.IsInInstance then return false end

	local inInstance, instanceType = _G.IsInInstance()
	if not inInstance then return false end

	-- Show warning in raids and dungeons (where chat lockdowns occur)
	return instanceType == "raid" or instanceType == "party"
end

-- Get current instance name for tracking
local function getCurrentInstanceName()
	if not _G.GetInstanceInfo then return nil end
	local name = _G.select(1, _G.GetInstanceInfo())
	return name
end

-- Show instance warning message
local function showInstanceWarning()
	if not addon.L.ChatFeaturesDisabledInstance then return end

	-- Light red color (scarlet/salmon) - |cFFFA8072 (hex for salmon)
	if _G.DEFAULT_CHAT_FRAME and _G.DEFAULT_CHAT_FRAME.AddMessage then
		_G.DEFAULT_CHAT_FRAME:AddMessage("|cFFFA8072" .. addon.L.ChatFeaturesDisabledInstance .. "|r")
	end

	if addon.dbg then
		addon.dbg("InstanceWarning: showing warning for instance")
	end
end

-- Check for instance entry and show warning if needed
local function checkInstanceEntry()
	local currentInstance = getCurrentInstanceName()

	-- If we're in a new instance that supports lockdowns
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

-- Zone change handler
local function onZoneChanged()
	if addon.dbg then
		addon.dbg("InstanceWarning: OnZoneChanged - checking for instance entry")
	end
	checkInstanceEntry()
end

-- Player entering world handler
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
		-- Addon not fully initialized, try again later
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
	_instanceWarningShown = {}
end

function addon.ForceInstanceWarning()
	showInstanceWarning()
end
