--[[
	PlayerNameStyling.lua - Player name styling and formatting for XanChat
	Improvements:
	- Extracted class color lookup into helper function
	- Simplified color extraction logic
	- Consolidated player info retrieval
	- Better early returns throughout
	- Reduced code duplication in level coloring
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- COLOR UTILITIES
-- ============================================================================

local function RGBAToHex(r, g, b, a)
	r = math.min(math.max(tonumber(r) or 1, 0), 1)
	g = math.min(math.max(tonumber(g) or 1, 0), 1)
	b = math.min(math.max(tonumber(b) or 1, 0), 1)
	a = math.min(math.max(tonumber(a) or 1, 0), 1)
	return string.format("%02X%02X%02X%02X", a * 255, r * 255, g * 255, b * 255)
end

local function HexToRGBA(hex)
	if type(hex) ~= "string" or #hex < 8 then
		return 1, 1, 1, 1
	end
	return tonumber("0x"..string.sub(hex, 3, 4), 10) / 255,
		tonumber("0x"..string.sub(hex, 5, 6), 10) / 255,
		tonumber("0x"..string.sub(hex, 7, 8), 10) / 255,
		tonumber("0x"..string.sub(hex, 1, 2), 10) / 255
end

local function wrapInColor(text, r, g, b)
	if not text or text == "" or not r or not g or not b then return text end

	local hexColor = RGBAToHex(r, g, b, 1)
	return hexColor ~= "" and "|c"..hexColor..text.."|r" or text
end

-- ============================================================================
-- TIMERUNNING ICON HANDLING
-- ============================================================================

local function addTimeRunningIcon(guid, stylizedName, isSecret)
	if not stylizedName then
		return ""
	end
	if not guid or isSecret or type(guid) ~= "string" then
		return stylizedName
	end

	if not (_G.C_ChatInfo and _G.C_ChatInfo.IsTimerunningPlayer) or
	   not (_G.TimerunningUtil and _G.TimerunningUtil.AddSmallIcon) or
	   not _G.C_ChatInfo.IsTimerunningPlayer(guid) then
		return stylizedName
	end

	return _G.TimerunningUtil.AddSmallIcon(stylizedName)
end

-- ============================================================================
-- EVENT TYPE FILTERING
-- ============================================================================

local SKIP_STYLING_EVENTS = {
	BN_INLINE_TOAST_ALERT = true,
	BN_INLINE_TOAST_BROADCAST = true,
	BN_INLINE_TOAST_BROADCAST_INFORM = true,
	BN_INLINE_TOAST_CONVERSATION = true,
	BN_WHISPER_PLAYER_OFFLINE = true,
	SYSTEM = true,
	AFK = true,
	DND = true,
	ADDON = true,
	ERRORS = true,
	CHANNEL_NOTICE = true,
	CHANNEL_NOTICE_USER = true,
	TRADESKILLS = true,
	PET_INFO = true,
	COMBAT_MISC_INFO = true,
	COMBAT_XP_GAIN = true,
	COMBAT_FACTION_CHANGE = true,
	COMBAT_HONOR_GAIN = true,
	IGNORED = true,
	PING = true,
	EMOTE = true,
	TEXT_EMOTE = true
}

local function shouldSkipStyling(chatType)
	return SKIP_STYLING_EVENTS and SKIP_STYLING_EVENTS[chatType]
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Get class color for a player class
local function getClassColor(playerClass)
	if not playerClass or playerClass == "" then return nil end

	local classColorTable = _G.RAID_CLASS_COLORS or _G.CUSTOM_CLASS_COLORS
	return classColorTable and classColorTable[playerClass]
end

-- Get colored level text
local function getColoredLevel(playerInfo)
	if not playerInfo or not playerInfo.level then return "" end

	local level = tonumber(playerInfo.level) or 0
	if level <= 0 then return "" end

	local colorFunc = _G.GetQuestDifficultyColor or _G.GetDifficultyColor
	if not colorFunc then return "" end

	local difficultyColor = colorFunc(level)
	if not difficultyColor then return "" end

	return wrapInColor(tostring(level), difficultyColor.r, difficultyColor.g, difficultyColor.b)
end

-- ============================================================================
-- PLAYER LINK GENERATION
-- ============================================================================

local function createPlayerLink(m, linkTarget, displayText)
	if not linkTarget or not displayText then return nil end

	local chatType = m.chat_type or ""

	-- Skip for emotes, monster emotes, and channel notices
	if string.sub(chatType, 1, 7) == "MONSTER" or
	   string.sub(chatType, 1, 18) == "RAID_BOSS_EMOTE" or
	   chatType == "EMOTE" or chatType == "TEXT_EMOTE" or
	   chatType == "CHANNEL_NOTICE" or chatType == "CHANNEL_NOTICE_USER" then
		return nil
	end

	-- Handle achievement events
	if chatType == "ACHIEVEMENT" or chatType == "GUILD_ACHIEVEMENT" then
		return string.format("|Hplayer:%s|h[%s]|h", linkTarget, displayText)
	end

	-- Handle community channels
	if chatType == "COMMUNITIES_CHANNEL" then
		local isBattleNetCommunity = m.arg13 ~= nil and m.arg13 ~= 0
		local messageInfo = _G.C_Club and _G.C_Club.GetInfoFromLastCommunityChatLine and _G.C_Club.GetInfoFromLastCommunityChatLine()

		if messageInfo then
			local clubId, streamId = messageInfo.clubId, messageInfo.streamId
			if isBattleNetCommunity then
				return string.format("|HBNplayerCommunity:%s:%s:%s:%s:%s:%s|h[%s]|h",
					linkTarget, m.arg13, clubId, streamId, messageInfo.messageId.epoch, messageInfo.messageId.position, displayText)
			else
				return string.format("|HBNplayerCommunity:%s:%s:%s:%s:%s|h[%s]|h",
					linkTarget, clubId, streamId, messageInfo.messageId.epoch, messageInfo.messageId.position, displayText)
			end
		end
		return "[" .. displayText .. "]"
	end

	-- Handle Battle.net whisper events
	if chatType == "BN_WHISPER" or chatType == "BN_WHISPER_INFORM" or chatType == "BN_CONVERSATION" then
		if m.arg13 then
			return string.format("|HBNplayer:%s:%s:%s:%s:%s|h[%s]|h", linkTarget, m.arg13, m.arg11 or 0, m.CHATGROUP or 0, m.chat_target or "", displayText)
		end
		return "[" .. displayText .. "]"
	end

	-- Handle regular player links
	return string.format("|Hplayer:%s:%s:%s:%s|h[%s]|h", linkTarget, m.arg11 or 0, m.CHATGROUP or 0, m.chat_target or "", displayText)
end

-- ============================================================================
-- PLAYER SECTION FORMATTING
-- ============================================================================

local function StylePlayerSection(m)
	if not addon then return end

	local isSecret = addon.isSecretValue(m.player_name)
	local chatType = m.chat_type or ""
	local fullEvent = m.EVENT or ""

	if shouldSkipStyling(chatType) then
		if addon and addon.dbg then
			addon.dbg("StylePlayerSection: skipping special event: "..addon.dbgSafeValue(chatType))
		end
		return
	end

	-- Check filter list for styling eligibility
	local shouldStyle = addon.searchFilterList and addon.isFilterListEnabled and addon:searchFilterList(fullEvent, m.message_text or "")

	if addon and addon.dbg then
		addon.dbg("StylePlayerSection: enablePlayerChatStyle="..tostring(_G.XCHT_DB and _G.XCHT_DB.enablePlayerChatStyle).." isSecret="..tostring(isSecret).." shouldStyle="..tostring(shouldStyle))
	end

	-- Early exit if no player name
	if not m.player_name or (not isSecret and m.player_name == "") then
		return
	end

	-- Get class color
	local coloredPlayerName = m.player_name
	local playerClass = m.player_class

	if not isSecret and (not playerClass or playerClass == "") and addon.getPlayerInfo then
		local playerInfo = addon.getPlayerInfo(m.player_guid, m.player_name_with_realm, m.player_name, m.server_name)
		if playerInfo and playerInfo.class then
			playerClass = playerInfo.class
		end
	elseif isSecret and m.player_guid and not playerClass then
		playerClass = select(2, _G.GetPlayerInfoByGUID(m.player_guid))
	end

	-- Apply class color (non-secret path)
	if not isSecret and playerClass and playerClass ~= "" then
		local classColor = getClassColor(playerClass)
		if classColor then
			coloredPlayerName = wrapInColor(m.player_name, classColor.r, classColor.g, classColor.b)
		end
	elseif isSecret and playerClass and _G.C_ClassColor then
		local classColor = _G.C_ClassColor.GetClassColor(playerClass)
		if classColor then
			coloredPlayerName = classColor:WrapTextInColorCode(coloredPlayerName)
		end
	end

	-- Get player level
	local coloredLevel = ""
	if addon.getPlayerInfo then
		local playerInfo = addon.getPlayerInfo(m.player_guid, m.player_name_with_realm, m.player_name, m.server_name)
		coloredLevel = getColoredLevel(playerInfo)
	end

	-- Build display text
	local displayText = coloredPlayerName
	if coloredLevel ~= "" then
		displayText = coloredLevel..":"..coloredPlayerName
	end
	displayText = addTimeRunningIcon(m.player_guid, displayText, isSecret)

	-- Create player link
	-- IMPORTANT: Ambiguate cannot be called on secret values during lockdown
	local linkTarget = m.sender_name
	if linkTarget and not isSecret and _G.Ambiguate then
		linkTarget = _G.Ambiguate(linkTarget, "none")
	end

	local playerLink = createPlayerLink(m, linkTarget, displayText)

	if not (_G.XCHT_DB and _G.XCHT_DB.enablePlayerChatStyle) or isSecret or not shouldStyle then
		-- Basic styling path - just create clickable link with class color
		if playerLink then
			m.player_link = playerLink
			m.styled_player_name = displayText
		end
		return
	end

	-- Full styling path - extract color from Blizzard output and apply
	local extractedColorFromOutput = false
	if m.OUTPUT and type(m.OUTPUT) == "string" then
		local playerNamePattern = string.gsub(m.player_name, "([%-%^%$%(%)%%%[%]%.%*%+%?])", "%%%1")

		for _, pattern in ipairs({
			"|cff(%x%x%x%x%x%x)%["..playerNamePattern.."%]|r",
			"|cff(%x%x%x%x%x%x)"..playerNamePattern.."|r",
			"|cff(%x%x%x%x%x%x)%|"..playerNamePattern.."|h",
		}) do
			local colorMatch = string.match(m.OUTPUT, pattern)
			if colorMatch then
				coloredPlayerName = wrapInColor(m.player_name,
					tonumber(string.sub(colorMatch, 1, 2), 16) / 255,
					tonumber(string.sub(colorMatch, 3, 4), 16) / 255,
					tonumber(string.sub(colorMatch, 5, 6), 16) / 255)
				displayText = coloredLevel ~= "" and coloredLevel..":"..coloredPlayerName or coloredPlayerName
				displayText = addTimeRunningIcon(m.player_guid, displayText, false)
				extractedColorFromOutput = true
				if addon and addon.dbg then
					addon.dbg("StylePlayerSection: Extracted class color from Blizzard output")
				end
				break
			end
		end
	end

	-- Try getting class from player info if not found
	if not extractedColorFromOutput then
		local playerInfo = addon.getPlayerInfo and addon.getPlayerInfo(m.player_guid, m.player_name_with_realm, m.player_name, m.server_name)
		if playerInfo and playerInfo.class then
			local classColor = getClassColor(playerInfo.class)
			if classColor then
				coloredPlayerName = wrapInColor(m.player_name, classColor.r, classColor.g, classColor.b)
				displayText = (coloredLevel ~= "" and coloredLevel..":"..coloredPlayerName) or coloredPlayerName
				displayText = addTimeRunningIcon(m.player_guid, displayText, false)
			end
		end
		if addon and addon.dbg then
			addon.dbg("-->player list lookup: guid="..addon.dbgSafeValue(m.player_guid).." found="..tostring(playerInfo and "yes" or "no"))
		end
	end

	-- Create final player link
	playerLink = createPlayerLink(m, linkTarget, displayText)
	if playerLink then
		m.player_link = playerLink
		m.styled_player_name = playerLink
		if addon and addon.dbg then
			addon.dbg("-->clickable player_link created: "..addon.dbgSafeValue(playerLink))
		end
	else
		m.styled_player_name = "["..displayText.."]"
		if addon and addon.dbg then
			addon.dbg("-->stylized_player_name (non-clickable): "..addon.dbgSafeValue(m.styled_player_name))
		end
	end

	-- Clear other player fields that are now part of styled_player_name
	m.player_name = ""
	m.server_name = ""
	m.server_separator = ""
end

-- ============================================================================
-- NOTICE FILTER CHECKING
-- ============================================================================

local function checkNoticeFilter(_, event, message)
	if not addon or not _G.XCHT_DB or not _G.XCHT_DB.disableChatEnterLeaveNotice then
		return false
	end

	if event == "CHAT_MSG_CHANNEL_NOTICE" or event == "CHAT_MSG_CHANNEL_JOIN" or event == "CHAT_MSG_CHANNEL_LEAVE" then
		return true
	end

	if event == "CHAT_MSG_SYSTEM" and type(message) == "string" and not (addon.isSecretValue and addon.isSecretValue(message)) then
		if string.find(message, "|Hplayer:", 1, true) and (string.find(message, "has joined", 1, true) or string.find(message, "has left", 1, true)) then
			return true
		end
	end

	return false
end

local function setDisableChatEnterLeaveNotice()
	if not addon or addon._noticeFilterRegistered then return end

	if _G.ChatFrame_AddMessageEventFilter then
		_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", addon.checkNoticeFilter)
		_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_JOIN", addon.checkNoticeFilter)
		_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_LEAVE", addon.checkNoticeFilter)
		_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", addon.checkNoticeFilter)
	end

	addon._noticeFilterRegistered = true
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.StylePlayerSection = StylePlayerSection
addon.checkNoticeFilter = checkNoticeFilter
addon.setDisableChatEnterLeaveNotice = setDisableChatEnterLeaveNotice
addon.RGBAToHex = RGBAToHex
addon.HexToRGBA = HexToRGBA
addon.wrapInColor = wrapInColor
addon.SKIP_STYLING_EVENTS = SKIP_STYLING_EVENTS
