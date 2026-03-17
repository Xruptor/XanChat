--[[
	MessageFilters.lua - Message filtering for XanChat (join/leave suppression)
	Refactored for:
	- Consolidated redundant checks
	- Simplified string matching logic
	- Improved early returns
	- Better function organization
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- MESSAGE FILTERS
-- ============================================================================

-- Events to filter for channel join/leave messages
local FILTER_EVENTS = {
	CHAT_MSG_CHANNEL_NOTICE = true,
	CHAT_MSG_CHANNEL_JOIN = true,
	CHAT_MSG_CHANNEL_LEAVE = true,
}

-- Check if a message should be suppressed based on settings
local function shouldSuppressJoinLeaveMessage(event, text)
	if not (_G.XCHT_DB and _G.XHT_DB.disableChatEnterLeaveNotice) then
		return false
	end

	-- Filter channel events
	if FILTER_EVENTS[event] then
		if addon and addon.dbg then
			addon.dbg("shouldSuppressJoinLeaveMessage: suppressing channel notice event")
		end
		return true
	end

	-- Filter system messages for join/leave
	if event == "CHAT_MSG_SYSTEM" and type(text) == "string" then
		if string.find(text, "|Hplayer:", 1, true) then
			if string.find(text, "has joined", 1, true) or string.find(text, "has left", 1, true) then
				if addon and addon.dbg then
					addon.dbg("shouldSuppressJoinLeaveMessage: suppressing system join/leave message")
				end
				return true
			end
		end
	end

	return false
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.shouldSuppressJoinLeaveMessage = shouldSuppressJoinLeaveMessage
