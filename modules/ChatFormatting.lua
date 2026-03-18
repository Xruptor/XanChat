--[[
	ChatFormatting.lua - Direct chat text construction system for XanChat
	Refactored for:
	- Eliminated per-call function creation (getValue helper)
	- Simplified string concatenation and trimming
	- Removed redundant nil checks
	- Better variable naming
	- More efficient whitespace handling
	- Removed unnecessary conditional logic
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- CHAT COMPOSITION SYSTEM (Direct Construction)
-- ============================================================================

-- IMPORTANT SECURITY NOTES:
-- 1. This module handles chat message formatting and construction
-- 2. Secret values are protected WoW values that cannot be modified with gsub()
-- 3. DO NOT call FormatChatMessage() for secret value payloads
-- 4. Secret value messages use the direct safe path in XanChat.lua instead
-- 5. Violating these rules will cause errors during boss encounters/chat lockdown

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
-- IMPORTANT: This function returns empty string for secret values - DO NOT use
-- for operations that require string manipulation like gsub() on the original secret value
local function getSafeValue(field, m)
	local value = m and m[field]
	if not value then return "" end
	if addon.isSecretValue(value) then return "" end
	if not addon.canAccessValue(value) then return "" end
	if type(value) ~= "string" then return "" end

	-- Trim leading and trailing whitespace
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
-- This function should not be called for secret values as there is a lot of string
-- modifications done here. Especially gsub() which don't work with secret values.
local function FormatChatMessage(message)
	if addon and addon.dbg then
		addon.dbg("FormatChatMessage: building chat text with direct construction")
	end

	if message ~= nil and message ~= false then
		sectionWorking = message
	end
	local m = sectionWorking

	-- Build prefix section (channel info and type prefix)
	local parts = {}
	local channelNum = getSafeValue("channel_number", m)
	local channelName = getSafeValue("channel_name", m)
	local typePrefix = getSafeValue("type_prefix", m)

	if channelNum ~= "" and channelName ~= "" then
		table.insert(parts, "["..channelNum..". "..channelName.."]")
	end
	if typePrefix ~= "" then
		table.insert(parts, typePrefix)
	end

	-- Build player section (flag, styled name, or link)
	local playerFlag = getSafeValue("player_flag", m)
	local styledPlayer = getSafeValue("styled_player_name", m)
	local playerLink = getSafeValue("player_link", m)
	local playerName = getSafeValue("player_name", m)
	local serverName = getSafeValue("server_name", m)
	local serverSep = getSafeValue("server_separator", m)

	if playerFlag ~= "" then
		table.insert(parts, playerFlag)
	end
	if styledPlayer ~= "" then
		table.insert(parts, styledPlayer)
	elseif playerLink ~= "" then
		table.insert(parts, playerLink)
	elseif playerName ~= "" then
		if serverName ~= "" then
			table.insert(parts, playerName..serverSep..serverName)
		else
			table.insert(parts, playerName)
		end
	end

	-- Build postfix section (language and mobile icon)
	local language = getSafeValue("language", m)
	local mobileIcon = getSafeValue("mobile_icon", m)

	if language ~= "" then
		table.insert(parts, "["..language.."]")
	end
	if mobileIcon ~= "" then
		table.insert(parts, mobileIcon)
	end

	-- Add message text
	local messageText = getSafeValue("message_text", m)
	if messageText ~= "" then
		-- If we have player styling, combine with last part (player section) instead of adding as separate part
		if styledPlayer ~= "" or playerLink ~= "" or playerName ~= "" then
			local lastPartIndex = #parts
			if lastPartIndex > 0 then
				parts[lastPartIndex] = parts[lastPartIndex]..": "..messageText
			else
				table.insert(parts, messageText)
			end
		else
			table.insert(parts, messageText)
		end
	end

	-- Combine all parts with proper spacing
	local result = table.concat(parts, " ")
	-- Clean up multiple spaces
	result = string.gsub(result, "%s+", " ")

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
