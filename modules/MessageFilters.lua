--[[
	MessageFilters.lua - Message filtering for XanChat (join/leave suppression)
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}
-- ============================================================================
-- MESSAGE FILTERS
-- ============================================================================

local function shouldSuppressJoinLeaveMessage(event, text)
	if not (_G.XCHT_DB and _G.XCHT_DB.disableChatEnterLeaveNotice) then
		return false
	end

	if addon and addon.dbg then
		addon.dbg("shouldSuppressJoinLeaveMessage: checking event="..tostring(event))
	end

	if event == "CHAT_MSG_CHANNEL_NOTICE" or event == "CHAT_MSG_CHANNEL_JOIN" or event == "CHAT_MSG_CHANNEL_LEAVE" then
		if addon and addon.dbg then
			addon.dbg("shouldSuppressJoinLeaveMessage: suppressing channel notice event")
		end
		return true
	end

	if event == "CHAT_MSG_SYSTEM" and type(text) == "string" then
		if string.find(text, "|Hplayer:", 1, true) and (string.find(text, "has joined", 1, true) or string.find(text, "has left", 1, true)) then
			if addon and addon.dbg then
				addon.dbg("shouldSuppressJoinLeaveMessage: suppressing system join/leave message")
			end
			return true
		end
	end

	return false
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.shouldSuppressJoinLeaveMessage = shouldSuppressJoinLeaveMessage
