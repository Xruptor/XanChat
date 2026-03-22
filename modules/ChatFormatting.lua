--[[
	ChatFormatting.lua - Direct chat text construction system for XanChat
	Improvements:
	- Simplified getSafeValue with early returns
	- Consolidated string concatenation with table.concat
	- Improved resetSectionBuffer with direct wipe
	- More efficient FormatChatMessage flow
	- Removed redundant nil checks
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- IMPORTANT SECURITY NOTES:
-- 1. This module handles chat message formatting and construction
-- 2. Secret values are protected WoW values that cannot be modified with gsub()
-- 3. DO NOT call FormatChatMessage() for secret value payloads
-- 4. Secret value messages use the direct safe path in XanChat.lua instead

if addon and addon.dbg then
	addon.dbg("chat_composition_system_init")
end

-- All possible data keys that can be populated from a chat event
local CHAT_DATA_KEYS = {
	"prefix_text", "type_prefix", "channel_link", "channel_number", "channel_name", "zone_name",
	"player_flag", "timerunner", "player_link", "player_guid", "player_name", "player_name_with_realm", "player_class", "non_player_name", "server_name", "server_separator",
	"type_postfix", "language", "mobile_icon", "message_text", "postfix_text", "styled_player_name", "PRE", "POST"
}

-- Buffers for composition
local sectionOriginal = {}
local sectionWorking = { ORG = sectionOriginal }

-- Helper to safely trim strings and handle secret values
local function getSafeValue(field, m)
	local value = m and m[field]
	if not value then return "" end
	if addon.isSecretValue(value) then return "" end
	if not addon.canAccessValue(value) then return "" end
	if type(value) ~= "string" then return "" end

	return string.match(value, "^%s*(.-)%s*$") or ""
end

-- Reset section buffer to empty state
local function resetSectionBuffer(buffer)
	if addon and addon.dbg then
		addon.dbg("resetSectionBuffer: clearing buffer")
	end
	wipe(buffer)
	for i = 1, #CHAT_DATA_KEYS do
		buffer[CHAT_DATA_KEYS[i]] = ""
	end
end

-- Prepare working sections by copying from original
local function prepareWorkingSections()
	if addon and addon.dbg then
		addon.dbg("prepareWorkingSections: copying sectionOriginal to sectionWorking")
	end
	for k, v in pairs(sectionOriginal) do
		sectionWorking[k] = v
	end
	return sectionWorking
end

-- Do not call this for secret values (string modifications like gsub don't work with secret values)
local function FormatChatMessage(message)
	if addon and addon.dbg then
		addon.dbg("FormatChatMessage: building chat text with direct construction")
	end

	if message ~= nil and message ~= false then
		sectionWorking = message
	end
	local m = sectionWorking

	-- Build all parts with table for efficiency
	local parts = {}
	local channelNum = getSafeValue("channel_number", m)
	local channelName = getSafeValue("channel_name", m)
	local typePrefix = getSafeValue("type_prefix", m)

	-- Channel prefix
	if channelNum ~= "" and channelName ~= "" then
		local useShortNames = _G.XCHT_DB and _G.XCHT_DB.shortNames
		parts[#parts + 1] = "|Hchannel:"..channelNum.."|h["..channelNum..(useShortNames and "] ["..channelName or ". "..channelName).."]|h"
	end
	if typePrefix ~= "" then
		parts[#parts + 1] = typePrefix
	end

	-- Player section
	local playerFlag = getSafeValue("player_flag", m)
	local styledPlayer = getSafeValue("styled_player_name", m)
	local playerLink = getSafeValue("player_link", m)
	local playerName = getSafeValue("player_name", m)
	local serverName = getSafeValue("server_name", m)
	local serverSep = getSafeValue("server_separator", m)

	if playerFlag ~= "" then
		parts[#parts + 1] = playerFlag
	end
	if styledPlayer ~= "" then
		parts[#parts + 1] = styledPlayer
	elseif playerLink ~= "" then
		parts[#parts + 1] = playerLink
	elseif playerName ~= "" then
		if serverName ~= "" then
			parts[#parts + 1] = playerName..serverSep..serverName
		else
			parts[#parts + 1] = playerName
		end
	end

	-- Postfix section
	local language = getSafeValue("language", m)
	local mobileIcon = getSafeValue("mobile_icon", m)
	local messageText = getSafeValue("message_text", m)

	if language ~= "" then
		parts[#parts + 1] = "["..language.."]"
	end
	if mobileIcon ~= "" then
		parts[#parts + 1] = mobileIcon
	end

	-- Add message text with colon separator if we have player info
	if messageText ~= "" then
		if styledPlayer ~= "" or playerLink ~= "" or playerName ~= "" then
			local lastIdx = #parts
			if lastIdx > 0 then
				parts[lastIdx] = parts[lastIdx]..": "..messageText
			else
				parts[#parts + 1] = messageText
			end
		else
			parts[#parts + 1] = messageText
		end
	end

	-- Combine all parts with proper spacing
	local result = string.gsub(table.concat(parts, " "), "%s+", " ")

	if addon and addon.isSafeString and addon.isSafeString(result) then
		if addon and addon.dbg then
			addon.dbg("FormatChatMessage: result length="..tostring(addon.dbgSafeLength and addon.dbgSafeLength(result) or 0))
		end
	end
	return result
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.FormatChatMessage = FormatChatMessage
addon.CHAT_DATA_KEYS = CHAT_DATA_KEYS
addon.resetSectionBuffer = resetSectionBuffer
addon.prepareWorkingSections = prepareWorkingSections
addon.sectionOriginal = sectionOriginal
addon.sectionWorking = sectionWorking
