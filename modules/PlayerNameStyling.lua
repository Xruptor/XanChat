--[[
	HelperFunctions.lua - Helper functions for XanChat
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- PLAYER SECTION FORMATTING
-- ============================================================================

local function FormatPlayerSection(m)
	if not addon then return end

	if not (_G.XCHT_DB and _G.XCHT_DB.enablePlayerChatStyle) then
		return
	end
	if not m.player_name or m.player_name == "" then
		return
	end
	local nameToLookup = m.player_link or m.player_name
	if not nameToLookup then
		return
	end

	-- Access player list from addon object
	local baseName = string.match(nameToLookup, "([^%-]+)") or nameToLookup
	local playerInfo = addon.playerListByName and addon.playerListByName[baseName]
	if not playerInfo then
		return
	end

	-- Helper function to wrap text in WoW color format
	local function wrapInColor(text, r, g, b)
		if not text or text == "" then return "" end
		if not r or not g or not b then return text end
		local hexColor = _G.RGBAToHex and _G.RGBAToHex(r, g, b, 1) or ""
		return "|c" .. hexColor .. text .. "|r"
	end

	-- Build level text with difficulty coloring
	local coloredLevel = ""
	if playerInfo.level and playerInfo.level > 0 then
		local colorFunc = _G.GetQuestDifficultyColor or _G.GetDifficultyColor
		if colorFunc then
			local difficultyColor = colorFunc(playerInfo.level)
			if difficultyColor then
				coloredLevel = wrapInColor(tostring(playerInfo.level), difficultyColor.r, difficultyColor.g, difficultyColor.b)
			end
		end
	end

	-- Build player name with class coloring
	local coloredPlayerName = m.player_name
	if playerInfo.class then
		local classColorTable = _G.RAID_CLASS_COLORS or _G.CUSTOM_CLASS_COLORS
		if classColorTable then
			local classColor = classColorTable[playerInfo.class]
			if classColor then
				coloredPlayerName = wrapInColor(m.player_name, classColor.r, classColor.g, classColor.b)
			end
		end
	end

	-- Construct styled player name directly without templates
	if coloredLevel ~= "" then
		-- Format: [70:Xruptor]
		m.styled_player_name = "[" .. coloredLevel .. ":" .. coloredPlayerName .. "]"
	else
		-- Format: [Xruptor]
		m.styled_player_name = "[" .. coloredPlayerName .. "]"
	end

	-- Clear other player fields that are now part of styled_player_name
	m.player_name = ""
	m.server_name = ""
	m.server_separator = ""
end

-- ============================================================================
-- INSTANCE CHECKING
-- ============================================================================

local function isInAnyInstance()
	if not _G.IsInInstance then return false end
	return _G.select(1, _G.IsInInstance())
end

-- ============================================================================
-- NOTICE FILTER CHECKING
-- ============================================================================

local function checkNoticeFilter(...)
	if not addon then return false end

	if not _G.XCHT_DB or not _G.XCHT_DB.filterJoinLeave then
		return false
	end

	local event = ...
	if event ~= "CHAT_MSG_SYSTEM" then
		return false
	end

	local arg1 = _G.select(1, ...)
	if not arg1 or type(arg1) ~= "string" then
		return false
	end

	-- Filter join/leave messages
	if string.find(arg1, _G.ERR_PLAYER_DND, 1, true) then
		return true
	end

	if string.find(arg1, _G.ERR_PLAYER_AFK, 1, true) then
		return true
	end

	return false
end

-- ============================================================================
-- NOTICE FILTER SETUP
-- ============================================================================

local function setDisableChatEnterLeaveNotice()
	if not addon then return end

	if addon._noticeFilterRegistered then return end

	if _G.ChatFrame_AddMessageEventFilter then
		_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", addon.checkNoticeFilter)
		_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_JOIN", addon.checkNoticeFilter)
		_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_LEAVE", addon.checkNoticeFilter)
	end

	addon._noticeFilterRegistered = true
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.FormatPlayerSection = FormatPlayerSection
addon.isInAnyInstance = isInAnyInstance
addon.checkNoticeFilter = checkNoticeFilter
addon.setDisableChatEnterLeaveNotice = setDisableChatEnterLeaveNotice
