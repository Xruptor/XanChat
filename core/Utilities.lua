--[[
	Utilities.lua - Utility functions for XanChat
	Improvements:
	- Consolidated secret value checks
	- Improved ApplyDefaults efficiency
	- Simplified SafeType with inline check
	- Better function organization
	- Removed redundant isNotSafeStr logic
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

local function SafeType(v)
	local ok, result = pcall(_G.type, v)
	return ok and result or nil
end

-- issecretvalue fails by raising an error on secret values
local function isSecretValue(v)
	local fn = _G.issecretvalue
	if type(fn) ~= "function" then
		return false
	end

	local ok, res = pcall(fn, v)
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
	if not target or not defaults then return end

	for key, value in pairs(defaults) do
		if target[key] == nil then
			target[key] = value
		end
	end
end

-- Check if a value is a safe, accessible string
local function isSafeString(v)
	return not isSecretValue(v) and canAccessValue(v) and SafeType(v) == "string"
end

-- Return safe string representation for display
local function safestr(v)
	if isSecretValue(v) then
		return "<secret-string>"
	end
	if not canAccessValue(v) then
		return "<inaccessible-string>"
	end
	if SafeType(v) ~= "string" then
		return ""
	end
	return v
end

-- Return boolean indicating if value requires safe string handling
local function safestr_bool(v)
	return isSecretValue(v) or not canAccessValue(v) or SafeType(v) ~= "string"
end

-- ============================================================================
-- CHAT FRAME ROUTING
-- ============================================================================

-- Check if a chat frame is valid and should receive messages
local function isChatFrameValid(frame)
	if not frame then return false end
	if type(frame) ~= "table" then return false end
	if not frame.GetObjectType then return false end
	if frame:GetObjectType() ~= "Frame" then return false end

	-- Check if frame is registered in CHAT_FRAMES
	local frameName = frame:GetName()
	if not frameName then return false end

	if _G.CHAT_FRAMES then
		for _, name in ipairs(_G.CHAT_FRAMES) do
			if name == frameName then
				return true
			end
		end
	end

	return false
end

-- Check if a frame is visible (shown and not hidden)
local function isFrameVisible(frame)
	if not frame then return false end

	-- Check IsShown safely
	local isShown = true
	if frame.IsShown then
		local ok = pcall(function()
			isShown = frame:IsShown()
		end)
		if not ok then
			isShown = true
		end
	end

	return isShown
end

-- Check if a frame is the active tab in its dock
-- When frames are docked together, only the active tab receives messages
local function isActiveDockTab(frame)
	if not frame then return false end

	-- If the frame isn't docked, it's always "active" for receiving messages
	local isDocked = false
	if frame.IsDocked then
		local ok = pcall(function()
			isDocked = frame:IsDocked()
		end)
		if not ok then
			isDocked = false
		end
	end

	if not isDocked then
		return true
	end

	-- Frame is docked - check if it's the selected frame in the dock
	-- Use FCFDock_GetSelectedFrame if available (modern API)
	if _G.FCFDock_GetSelectedFrame then
		-- Get the dock for this frame
		local dock = frame:GetDock()
		if dock then
			local selectedFrame = _G.FCFDock_GetSelectedFrame(dock)
			return selectedFrame == frame
		end
	end

	-- Fallback: check if the frame has a dock reference and compare
	if frame.dock then
		local dock = frame.dock
		if dock.GetSelectedFrame then
			local selectedFrame = dock:GetSelectedFrame()
			return selectedFrame == frame
		end
	end

	-- If we can't determine, assume active (conservative approach)
	return true
end

-- Get all chat frames that should receive a message for a given event/channel
-- Returns a table of frame objects that are valid, visible, and configured for the event
-- @param event string: The chat event (e.g., "CHAT_MSG_CHANNEL", "CHAT_MSG_GUILD")
-- @param channelNumber string|number|nil: Optional channel number for channel events
-- @return table: Array of chat frames that should receive the message
local function getTargetChatFrames(event, channelNumber)
	local targetFrames = {}

	if not _G.CHAT_FRAMES then
		return targetFrames
	end

	for i = 1, #_G.CHAT_FRAMES do
		local frameName = _G.CHAT_FRAMES[i]
		local frame = _G[frameName]

		if not frame then
			-- Try direct lookup
			frame = _G["ChatFrame" .. i]
		end

		-- Check if frame is valid
		if not isChatFrameValid(frame) then
			-- skip this frame
		elseif not isFrameVisible(frame) then
			-- skip this frame
		elseif not isActiveDockTab(frame) then
			-- skip this frame (docked but not the active tab)
		else
			local shouldAdd = true

			-- For channel events, check if the specific channel is enabled
			if channelNumber and channelNumber ~= "" and channelNumber ~= "0" then
				local channelNum = tostring(channelNumber)
				local hasChannel = false

				-- Check frame's channel list
				if frame.channelList then
					for _, chan in ipairs(frame.channelList) do
						if tostring(chan) == channelNum then
							hasChannel = true
							break
						end
					end
				end

				-- Alternative check using Blizzard API
				if not hasChannel and _G.FCF_IsChatFrameEnabledForChannel then
					local ok, result = pcall(_G.FCF_IsChatFrameEnabledForChannel, frame, tonumber(channelNum))
					if ok and result then
						hasChannel = true
					end
				end

				if not hasChannel then
					shouldAdd = false
				end
			end

			-- Add frame to target list
			if shouldAdd then
				table.insert(targetFrames, frame)
			end
		end
	end

	return targetFrames
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
addon.SafeType = SafeType
addon.isChatFrameValid = isChatFrameValid
addon.isFrameVisible = isFrameVisible
addon.isActiveDockTab = isActiveDockTab
addon.getTargetChatFrames = getTargetChatFrames
