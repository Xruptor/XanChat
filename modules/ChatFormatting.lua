--[[
	ChatFormatting.lua - Direct chat text construction system for XanChat
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- CHAT COMPOSITION SYSTEM (Direct Construction)
-- ============================================================================

if addon and addon.dbg then
	addon.dbg("chat_composition_system_init")
end

-- All possible data keys that can be populated from a chat event.
local CHAT_DATA_KEYS = {
    "prefix_text", "type_prefix", "channel_link", "channel_number", "channel_name", "zone_name",
    "player_flag", "timerunner", "player_link", "player_name", "non_player_name", "server_name", "server_separator",
    "type_postfix", "language", "mobile_icon", "message_text", "postfix_text", "styled_player_name", "PRE", "POST"
}

-- Buffers for composition. 'sectionOriginal' and 'sectionWorking' are used to maintain compatibility
-- with other parts of the addon that expect these names.
local sectionOriginal = {}
local sectionWorking = { ORG = sectionOriginal }

local function resetSectionBuffer(buffer)
	if addon and addon.dbg then
		addon.dbg("resetSectionBuffer: clearing buffer")
	end
	for k in pairs(buffer) do
		buffer[k] = nil
	end
	for i = 1, #CHAT_DATA_KEYS do
		buffer[CHAT_DATA_KEYS[i]] = ""
	end
end

local function prepareWorkingSections()
	if addon and addon.dbg then
		addon.dbg("prepareWorkingSections: copying sectionOriginal to sectionWorking")
	end
	-- Copy all fields from sectionOriginal to sectionWorking
	for k, v in pairs(sectionOriginal) do
		sectionWorking[k] = v
	end
	return sectionWorking
end

local function FormatChatMessage(message)
	if addon and addon.dbg then
		addon.dbg("FormatChatMessage: building chat text with direct construction")
	end
	local m = message or sectionWorking

	-- Helper function to safely get and trim values
	local function getValue(field)
		local value = m[field] or ""
		if type(value) ~= "string" then return "" end
		return value:gsub("^%s+", ""):gsub("%s+$", "")
	end

	-- Build prefix section (channel info and type prefix)
	local prefixSection = ""
	if getValue("channel_number") ~= "" and getValue("channel_name") ~= "" then
		prefixSection = "[" .. getValue("channel_number") .. ". " .. getValue("channel_name") .. "] "
	end
	if getValue("type_prefix") ~= "" then
		prefixSection = prefixSection .. getValue("type_prefix") .. " "
	end

	-- Build player section (flag, styled name, or link)
	local playerSection = ""
	if getValue("player_flag") ~= "" then
		playerSection = getValue("player_flag")
	end

	-- Use styled player name if available, otherwise use original link/name
	if getValue("styled_player_name") ~= "" then
		playerSection = playerSection .. getValue("styled_player_name")
	elseif getValue("player_link") ~= "" then
		playerSection = playerSection .. getValue("player_link")
	elseif getValue("player_name") ~= "" then
		-- Add server name if present
		if getValue("server_name") ~= "" then
			playerSection = playerSection .. getValue("player_name") .. getValue("server_separator") .. getValue("server_name")
		else
			playerSection = playerSection .. getValue("player_name")
		end
	end
	playerSection = playerSection .. " "

	-- Build postfix section (language and mobile icon)
	local postfixSection = ""
	if getValue("language") ~= "" then
		postfixSection = "[" .. getValue("language") .. "] "
	end
	if getValue("mobile_icon") ~= "" then
		postfixSection = postfixSection .. getValue("mobile_icon") .. " "
	end

	-- Combine all sections with message
	local result = prefixSection .. playerSection .. postfixSection .. ": " .. getValue("message_text")

	-- Clean up extra whitespace
	result = result:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s%s+", " ")

	if addon and addon.isSafeString and addon.isSafeString(result) then
		if addon and addon.dbg then
			addon.dbg("FormatChatMessage: result length=" .. #result)
		end
	end
	return result
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

-- Make section buffers and functions accessible to addon object
-- These are used in the main XanChat.lua file

addon.FormatChatMessage = FormatChatMessage
addon.CHAT_DATA_KEYS = CHAT_DATA_KEYS
addon.resetSectionBuffer = resetSectionBuffer
addon.prepareWorkingSections = prepareWorkingSections
addon.sectionOriginal = sectionOriginal
addon.sectionWorking = sectionWorking

