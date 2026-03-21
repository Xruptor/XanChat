--[[
	PlayerNameStyling.lua - Player name styling and formatting for XanChat
	Refactored for:
	- Consolidated duplicate player link generation code
	- Simplified color extraction logic
	- Improved early returns and nil handling
	- Better function organization
	- Reduced code duplication
	- Fixed redundant secret value checks
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
	if not text or text == "" then return "" end
	if not r or not g or not b then return text end

	local hexColor = RGBAToHex(r, g, b, 1)
	if not hexColor or hexColor == "" then return text end
	return "|c"..hexColor..text.."|r"
end

-- ============================================================================
-- TIMERUNNING ICON HANDLING
-- ============================================================================

local function addTimeRunningIcon(guid, stylizedName, isSecret)
	-- Skip timerunning icons during secret value lockdowns (boss encounters)
	-- but return the colored stylizedName since WrapTextInColorCode handles secret values
	if not stylizedName then
		return ""
	end
	if not guid or isSecret then
		-- Return colored stylizedName as-is (WrapTextInColorCode handles secret values)
		return stylizedName
	end
	if type(guid) ~= "string" then return stylizedName end

	-- Check for timerunning availability
	if not _G.C_ChatInfo or not _G.C_ChatInfo.IsTimerunningPlayer then
		return stylizedName
	end
	if not _G.TimerunningUtil or not _G.TimerunningUtil.AddSmallIcon then
		return stylizedName
	end
	if not _G.C_ChatInfo.IsTimerunningPlayer(guid) then
		return stylizedName
	end

	return _G.TimerunningUtil.AddSmallIcon(stylizedName)
end

-- ============================================================================
-- EVENT TYPE FILTERING
-- ============================================================================

-- IMPORTANT: During secret value lockdowns (boss encounters, combat),
-- certain events must be skipped to prevent errors. These events contain
-- special formatting that cannot be safely processed when values are secret.

-- Events to skip styling for during secret value lockdowns
-- Obviously many of these have CHAT_MSG_ stripped from the front  like CHAT_MSG_SYSTEM
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
	-- Always skip for events in SKIP_STYLING_EVENTS (emotes, system messages, etc.)
	-- These have special formatting that breaks with player links prepended
	if SKIP_STYLING_EVENTS and SKIP_STYLING_EVENTS[chatType] then
		return true
	end

	return false
end

-- ============================================================================
-- PLAYER LINK GENERATION
-- ============================================================================

local function createPlayerLink(m, linkTarget, displayText)
	-- Skip for emotes, monster emotes, and channel notices
	-- EMOTE and TEXT_EMOTE events have embedded player names in the message text
	-- and should not have additional player links prepended
	local chatType = m.chat_type or ""
	if string.sub(chatType, 1, 7) == "MONSTER" or
	   string.sub(chatType, 1, 18) == "RAID_BOSS_EMOTE" or
	   chatType == "EMOTE" or
	   chatType == "TEXT_EMOTE" or
	   chatType == "CHANNEL_NOTICE" or
	   chatType == "CHANNEL_NOTICE_USER" then
		return nil
	end

	-- Skip if linkTarget or displayText is nil (e.g., during secret value lockdowns)
	if not linkTarget or not displayText then
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

	-- During a boss encounter or a chat lockdown we don't want to process certain events
	-- as they will get broken because of their special formatting.
	-- Skip styling for special events during secret value lockdowns
	if shouldSkipStyling(chatType) then
		if addon and addon.dbg then
			addon.dbg("StylePlayerSection: skipping special event during secret lockdown: "..addon.dbgSafeValue(chatType))
		end
		return
	end

	-- Check filter list for styling eligibility (filter returns true = allow styling)
	local shouldStyle = false  -- default: no styling
	if addon.searchFilterList and addon.isFilterListEnabled and addon:searchFilterList(fullEvent, m.message_text or "") then
		shouldStyle = true  -- filter matched, allow styling
	end

	-- Debug: Check why we're entering disabled styling path
	if addon and addon.dbg then
		addon.dbg("StylePlayerSection: enablePlayerChatStyle="..tostring(_G.XCHT_DB and _G.XCHT_DB.enablePlayerChatStyle).." isSecret="..tostring(isSecret).." shouldStyle="..tostring(shouldStyle))
	end

	if not (_G.XCHT_DB and _G.XCHT_DB.enablePlayerChatStyle) or isSecret or not shouldStyle then
		-- Still need to generate player_link for clickable names
		if not m.player_name or (not isSecret and m.player_name == "") then
			return
		end

		-- Get class color for player name
		local coloredPlayerName = m.player_name
		local playerClass = m.player_class

		if not isSecret and (not playerClass or playerClass == "") and addon.getPlayerInfo then
			local playerInfo = addon.getPlayerInfo(m.player_guid, m.player_name_with_realm, m.player_name, m.server_name)
			if playerInfo and playerInfo.class then
				playerClass = playerInfo.class
			end
		elseif isSecret and (m.player_guid and not playerClass) then
			local _, englishClassChk = _G.GetPlayerInfoByGUID(m.player_guid)
			playerClass = englishClassChk
		end

		-- Apply class color
		if not isSecret and playerClass and playerClass ~= "" then
			local classColorTable = _G.RAID_CLASS_COLORS or _G.CUSTOM_CLASS_COLORS
			local classColor = classColorTable and classColorTable[playerClass]
			if classColor then
				coloredPlayerName = wrapInColor(m.player_name, classColor.r, classColor.g, classColor.b)
				if addon and addon.dbg then
					addon.dbg("StylePlayerSection: class color applied for disabled style="..addon.dbgSafeValue(playerClass))
				end
			end
		elseif isSecret and playerClass and C_ClassColor then
			local classColor = C_ClassColor.GetClassColor(playerClass)
			if classColor then
				coloredPlayerName = classColor:WrapTextInColorCode(coloredPlayerName)
				if addon and addon.dbg then
					addon.dbg("StylePlayerSection: class color applied for (secret) coloredPlayerName="..addon.dbgSafeValue(coloredPlayerName))
				end
			end
		end

		-- Create clickable player link
		local displayText = addTimeRunningIcon(m.player_guid, coloredPlayerName, isSecret)
		local playerLink = createPlayerLink(m, m.sender_name, displayText)
		if playerLink then
			m.player_link = playerLink
			m.styled_player_name = displayText
			if addon and addon.dbg then
				addon.dbg("StylePlayerSection: class-colored player_link created="..addon.dbgSafeValue(playerLink).." styled_player_name="..addon.dbgSafeValue(displayText))
			end
		end
		return
	end

	-- Return early if no player name
	if not m.player_name or (not addon.isSecretValue(m.player_name) and m.player_name == "") then
		return
	end

	-- Extract class color from Blizzard output
	local extractedClassColor
	if m.OUTPUT and type(m.OUTPUT) == "string" then
		local playerNamePattern = string.gsub(m.player_name, "([%-%^%$%(%)%%%[%]%.%*%+%?])", "%%%1")

		for _, pattern in ipairs({
			"|cff(%x%x%x%x%x)%["..playerNamePattern.."%]|r",
			"|cff(%x%x%x%x%x)"..playerNamePattern.."|r",
			"|cff(%x%x%x%x%x)%|"..playerNamePattern.."|h",
		}) do
			local colorMatch = string.match(m.OUTPUT, pattern)
			if colorMatch then
				extractedClassColor = {
					r = tonumber(string.sub(colorMatch, 1, 2), 16) / 255,
					g = tonumber(string.sub(colorMatch, 3, 4), 16) / 255,
					b = tonumber(string.sub(colorMatch, 5, 6), 16) / 255
				}
				if addon and addon.dbg then
					addon.dbg("StylePlayerSection: Extracted class color from Blizzard output")
				end
				break
			end
		end
	end

	-- Get player info for level
	local playerInfo
	if addon.getPlayerInfo then
		playerInfo = addon.getPlayerInfo(m.player_guid, m.player_name_with_realm, m.player_name, m.server_name)
		if addon and addon.dbg then
			addon.dbg("-->player list lookup: guid="..addon.dbgSafeValue(m.player_guid).." found="..tostring(playerInfo and "yes" or "no"))
		end
	end

	if addon and addon.dbg then
		addon.dbg("-->StylePlayerSection: name="..addon.dbgSafeValue(m.player_name).." extractedColor="..tostring(extractedClassColor and "yes" or "no"))
	end

	-- Return early if no styling data available
	if not playerInfo and not extractedClassColor and not (m.player_class and m.player_class ~= "") then
		return
	end

	-- Build level text with difficulty coloring
	local coloredLevel = ""
	if playerInfo then
		local level = tonumber(playerInfo.level) or 0
		if level > 0 then
			local colorFunc = _G.GetQuestDifficultyColor or _G.GetDifficultyColor
			if colorFunc then
				local difficultyColor = colorFunc(level)
				if difficultyColor then
					coloredLevel = wrapInColor(tostring(level), difficultyColor.r, difficultyColor.g, difficultyColor.b)
				end
			end
		end
	end

	-- Build colored player name
	local coloredPlayerName = m.player_name

	if extractedClassColor then
		coloredPlayerName = wrapInColor(m.player_name, extractedClassColor.r, extractedClassColor.g, extractedClassColor.b)
	elseif m.player_class and m.player_class ~= "" then
		local classColorTable = _G.RAID_CLASS_COLORS or _G.CUSTOM_CLASS_COLORS
		local classColor = classColorTable and classColorTable[m.player_class]
		if classColor then
			coloredPlayerName = wrapInColor(m.player_name, classColor.r, classColor.g, classColor.b)
		end
	elseif playerInfo and playerInfo.class then
		local classColorTable = _G.RAID_CLASS_COLORS or _G.CUSTOM_CLASS_COLORS
		local classColor = classColorTable and classColorTable[playerInfo.class]
		if classColor then
			coloredPlayerName = wrapInColor(m.player_name, classColor.r, classColor.g, classColor.b)
		end
	end

	-- Build display text and create player link
	local displayText = coloredPlayerName
	if coloredLevel ~= "" then
		displayText = coloredLevel..":"..coloredPlayerName
	end
	displayText = addTimeRunningIcon(m.player_guid, displayText, false)

	local playerLink = createPlayerLink(m, m.sender_name, displayText)
	if playerLink then
		m.player_link = playerLink
		m.styled_player_name = playerLink
		if addon and addon.dbg then
			addon.dbg("-->clickable player_link created: "..addon.dbgSafeValue(playerLink))
		end
	else
		-- Fallback: non-clickable styled player name
		m.styled_player_name = coloredLevel ~= "" and "["..displayText.."]" or "["..coloredPlayerName.."]"
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

	if event == "CHAT_MSG_SYSTEM" and type(message) == "string" then
		-- Skip secret values as string.find is not allowed on them
		if not (addon.isSecretValue and addon.isSecretValue(message)) then
			if string.find(message, "|Hplayer:", 1, true) and (string.find(message, "has joined", 1, true) or string.find(message, "has left", 1, true)) then
				return true
			end
		end
	end

	return false
end

local function setDisableChatEnterLeaveNotice()
	if not addon or addon._noticeFilterRegistered then
		return
	end

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
