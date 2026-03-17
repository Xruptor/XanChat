--[[
	PlayerNameStyling.lua - Player name styling and formatting for XanChat
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- Color Helper
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

-- Helper function to wrap text in WoW color format
local function wrapInColor(text, r, g, b)
	if not text or text == "" then return "" end
	if not r or not g or not b then return text end

	-- Try RGBAToHex first, fallback to manual hex conversion
	local hexColor
	if RGBAToHex then
		hexColor = RGBAToHex(r, g, b, 1)
	else
		hexColor = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
	end

	if not hexColor or hexColor == "" then return text end
	return "|c"..hexColor..text.."|r"
end

local function addTimeRunningIcon(guid, stylizedName)
	if not stylizedName then return "" end
	if not guid then return stylizedName end
	if addon.isSecretValue(guid) then return stylizedName end
	if type(guid) ~= "string" then return stylizedName end
	if not _G.C_ChatInfo or not _G.C_ChatInfo.IsTimerunningPlayer then return stylizedName end
	if not _G.TimerunningUtil or not  _G.TimerunningUtil.AddSmallIcon then return stylizedName end

	stylizedName = _G.TimerunningUtil.AddSmallIcon(stylizedName)
	return stylizedName
end

-- ============================================================================
-- PLAYER SECTION FORMATTING
-- ============================================================================

local function StylePlayerSection(m)
	if not addon then return end
	local isSecret = addon.isSecretValue(m.player_name)

	-- During a boss encounter or a chat lockdown we don't want to process certain events as they will get broken because of their special formatting.
	---------------------------
	-- Skip styling for special events during secret value lockdowns to prevent issues
	-- Based on patterns from Prat and Chattynator that skip processing these event types
	local chatType = m.chat_type or ""
	if isSecret then
		local skipStyling = false
		-- Skip achievement events (they have special formatting and don't need styling)
		if chatType == "ACHIEVEMENT" or chatType == "GUILD_ACHIEVEMENT" then
			skipStyling = true
		-- Skip all Battle.net toast events (friend online/offline, broadcasts, etc.)
		elseif string.sub(chatType, 1, 15) == "BN_INLINE_TOAST" then
			skipStyling = true
		-- Skip Battle.net whisper events that might be system messages
		elseif chatType == "BN_WHISPER_PLAYER_OFFLINE" then
			skipStyling = true
		-- Skip system messages during secret lockdown (friend status, server messages, etc.)
		elseif chatType == "SYSTEM" then
			skipStyling = true
		-- Skip AFK/DND status messages
		elseif chatType == "AFK" or chatType == "DND" then
			skipStyling = true
		-- Skip addon messages and error messages
		elseif chatType == "ADDON" or chatType == "ERRORS" then
			skipStyling = true
		-- Skip channel notice messages
		elseif chatType == "CHANNEL_NOTICE" or chatType == "CHANNEL_NOTICE_USER" then
			skipStyling = true
		-- Skip trade skills and profession messages
		elseif chatType == "TRADESKILLS" then
			skipStyling = true
		-- Skip pet information messages
		elseif chatType == "PET_INFO" then
			skipStyling = true
		-- Skip combat info messages (XP, faction, honor, etc.)
		elseif chatType == "COMBAT_MISC_INFO" or chatType == "COMBAT_XP_GAIN" or
		       chatType == "COMBAT_FACTION_CHANGE" or chatType == "COMBAT_HONOR_GAIN" then
			skipStyling = true
		-- Skip ignored messages
		elseif chatType == "IGNORED" then
			skipStyling = true
		-- Skip ping messages
		elseif chatType == "PING" then
			skipStyling = true
		end

		if skipStyling then
			if addon and addon.dbg then
				addon.dbg("StylePlayerSection: skipping special event during secret lockdown: "..addon.dbgSafeValue(chatType))
			end
			return
		end
	end

	-- Check filter list to see if this event type should be styled, when an event is checked that means we want to process it.  When unchecked that means we don't
	-- want to apply any styling to those events.
	local shouldStyle = true
	if addon.searchFilterList and addon.isFilterListEnabled then
		shouldStyle = addon:searchFilterList(m.chat_type, m.message_text or "")
	end

	if not (_G.XCHT_DB and _G.XCHT_DB.enablePlayerChatStyle) or isSecret or not shouldStyle then
		-- Even if player chat style is disabled, we still need to generate player_link for clickable names
		if not m.player_name or (not isSecret and m.player_name == "") then
			return
		end

		-- Try to get class color for the player name
		local coloredPlayerName = m.player_name
		local playerClass = m.player_class

		--only do these checks if we don't have secret values, since we cannot do table lookups using secret value keys
		if not isSecret and (not playerClass or playerClass == "") and addon.getPlayerInfo then
			-- If class not available from ParseChatEvent, check player table using getPlayerInfo
			local playerInfo = addon.getPlayerInfo(m.player_guid, m.player_name_with_realm, m.player_name, m.server_name)
			if playerInfo and playerInfo.class then
				playerClass = playerInfo.class
			end
		elseif isSecret and (m.player_guid and not playerClass)  then
			local _, englishClassChk = _G.GetPlayerInfoByGUID(m.player_guid)
			playerClass = englishClassChk
		end

		-- Apply class color for non-secret, because you cannot do a table lookup using secret values
		if not isSecret and playerClass and playerClass ~= "" then
			local classColorTable = _G.RAID_CLASS_COLORS or _G.CUSTOM_CLASS_COLORS
			if classColorTable then
				local classColor = classColorTable[playerClass]
				if classColor then
					coloredPlayerName = wrapInColor(m.player_name, classColor.r, classColor.g, classColor.b)
					if addon and addon.dbg then
						addon.dbg("StylePlayerSection: class color applied for disabled style="..addon.dbgSafeValue(playerClass))
					end
				end
			end
		elseif isSecret and playerClass and C_ClassColor then
			--NOTE:  This is the only real way to colorize a player name that is a secret value.  Because we also pass secret value class to a blizzard function.
			local classColor = C_ClassColor.GetClassColor(playerClass)
			if classColor then
				coloredPlayerName = classColor:WrapTextInColorCode(coloredPlayerName)
				addon.dbg("StylePlayerSection: class color applied for (secret) coloredPlayerName="..addon.dbgSafeValue(coloredPlayerName))
			end

		end

		-- Generate clickable player link with class color
		if m.sender_name and string.sub(m.chat_type or "", 1, 7) ~= "MONSTER" and
		    string.sub(m.chat_type or "", 1, 18) ~= "RAID_BOSS_EMOTE" and
		    m.chat_type ~= "CHANNEL_NOTICE" and m.chat_type ~= "CHANNEL_NOTICE_USER" then

			local linkTarget = m.sender_name
			local displayText = coloredPlayerName

			-- Add timerunning icon if available, checks for secret values just in case
			displayText = addTimeRunningIcon(m.player_guid, displayText)

			local playerLink
			if m.chat_type == "BN_WHISPER" or m.chat_type == "BN_WHISPER_INFORM" or m.chat_type == "BN_CONVERSATION" then
				if m.arg13 then
					playerLink = string.format("|HBNplayer:%s:%s:%s:%s:%s|h[%s]|h", linkTarget, m.arg13, m.arg11 or 0, m.CHATGROUP or 0, m.chat_target or "", displayText)
				else
					playerLink = "[" .. displayText .. "]"
				end
			else
				playerLink = string.format("|Hplayer:%s:%s:%s:%s|h[%s]|h", linkTarget, m.arg11 or 0, m.CHATGROUP or 0, m.chat_target or "", displayText)
			end

			m.player_link = playerLink
			m.styled_player_name = displayText
			if addon and addon.dbg then
				addon.dbg("StylePlayerSection: class-colored player_link created="..addon.dbgSafeValue(playerLink).." styled_player_name="..addon.dbgSafeValue(displayText))
			end
		end
		return
	end

	if not m.player_name or (not addon.isSecretValue(m.player_name) and m.player_name == "") then
		return
	end

	-- Extract class color from Blizzard-formatted output text
	local extractedClassColor = nil
	if m.OUTPUT and type(m.OUTPUT) == "string" then
		-- Break early if player name is empty or nil to prevent empty brackets
		if not m.player_name or (not addon.isSecretValue(m.player_name) and m.player_name == "") then
			return
		end

		-- Look for class color in the formatted output around the player name
		-- Blizzard formats player names like |cffRRGGBB[PlayerName]|r or just |cffRRGGBBPlayerName|r
		local playerNamePattern = string.gsub(m.player_name, "([%-%^%$%(%)%%%[%]%.%*%+%?])", "%%%1")
		-- Try different patterns to find the color code
		local patterns = {
			"|cff(%x%x%x%x%x%x)%["..playerNamePattern.."%]|r",  -- |cffRRGGBB[Name]|r
			"|cff(%x%x%x%x%x%x)"..playerNamePattern.."|r",       -- |cffRRGGBBName|r (before brackets)
			"|cff(%x%x%x%x%x%x)%|"..playerNamePattern.."|h",    -- |cffRRGGBB|Name|h (player link)
		}

		for _, pattern in ipairs(patterns) do
			local colorMatch = string.match(m.OUTPUT, pattern)
			if colorMatch then
				local hexColor = colorMatch
				extractedClassColor = {
					r = tonumber(string.sub(hexColor, 1, 2), 16) / 255,
					g = tonumber(string.sub(hexColor, 3, 4), 16) / 255,
					b = tonumber(string.sub(hexColor, 5, 6), 16) / 255
				}
				if addon and addon.dbg then
					addon.dbg("StylePlayerSection: Extracted class color from Blizzard output: R="..string.format("%.2f", extractedClassColor.r).." G="..string.format("%.2f", extractedClassColor.g).." B="..string.format("%.2f", extractedClassColor.b))
				end
				break
			end
		end
	end

	-- Always look up player info for level, even if we have extracted color
	local playerInfo = nil
	local fallbackPlayerName = m.player_name_with_realm

	-- Use getPlayerInfo to lookup player in table
	if addon.getPlayerInfo then
		playerInfo = addon.getPlayerInfo(m.player_guid, fallbackPlayerName, m.player_name, m.server_name)

		if addon and addon.dbg then
			addon.dbg("-->player list lookup: guid="..addon.dbgSafeValue(m.player_guid).." name="..addon.dbgSafeValue(m.player_name).." fallback="..addon.dbgSafeValue(fallbackPlayerName).." found="..tostring(playerInfo and "yes" or "no"))
			if playerInfo then
				addon.dbg("-->playerInfo: level="..addon.dbgSafeValue(playerInfo.level or "nil").." class="..addon.dbgSafeValue(playerInfo.class or "nil"))
			end
		end
	end

	-- Simple debug summary
	if addon and addon.dbg then
		addon.dbg("-->StylePlayerSection: name="..addon.dbgSafeValue(m.player_name).." player_class="..addon.dbgSafeValue(m.player_class or "nil").." extractedColor="..tostring(extractedClassColor and "yes" or "no"))
	end

	-- Continue only if we have player info for level or class info for name styling
	if not playerInfo and not extractedClassColor and not (m.player_class and m.player_class ~= "") then
		return
	end

	-- Build level text with difficulty coloring
	local coloredLevel = ""
	-- Check for level with more flexible condition, handle string conversion
	if playerInfo then
		local level = tonumber(playerInfo.level) or 0
		if addon and addon.dbg then
			addon.dbg("-->level calculation: playerInfo.level="..addon.dbgSafeValue(playerInfo.level).." tonumber="..tostring(level).." >0="..tostring(level and level > 0))
		end
		if level and level > 0 then
			local colorFunc = _G.GetQuestDifficultyColor or _G.GetDifficultyColor
			if colorFunc then
				local difficultyColor = colorFunc(level)
				if addon and addon.dbg then
					addon.dbg("-->level difficulty color: R="..string.format("%.2f", difficultyColor.r).." G="..string.format("%.2f", difficultyColor.g).." B="..string.format("%.2f", difficultyColor.b))
				end
				if difficultyColor then
					coloredLevel = wrapInColor(tostring(level), difficultyColor.r, difficultyColor.g, difficultyColor.b)
					if addon and addon.dbg then
						addon.dbg("-->coloredLevel result: "..tostring(coloredLevel))
					end
				end
			end
		end
	end

	-- Build player name with class coloring
	local coloredPlayerName = m.player_name
	-- First try to use extracted class color from Blizzard output
	if extractedClassColor then
		coloredPlayerName = wrapInColor(m.player_name, extractedClassColor.r, extractedClassColor.g, extractedClassColor.b)
	-- Try to use class from GUID lookup (for secret messages)
	elseif m.player_class and m.player_class ~= "" then
		local classColorTable = _G.RAID_CLASS_COLORS or _G.CUSTOM_CLASS_COLORS
		if classColorTable then
			local classColor = classColorTable[m.player_class]
			if classColor then
				coloredPlayerName = wrapInColor(m.player_name, classColor.r, classColor.g, classColor.b)
				if addon and addon.dbg then
					addon.dbg("-->class color: using GUID class="..addon.dbgSafeValue(m.player_class))
				end
			else
				if addon and addon.dbg then
					addon.dbg("-->class color: GUID class "..addon.dbgSafeValue(m.player_class).." NOT found in color table")
				end
			end
		end
	-- Fallback to player list lookup for class color
	elseif playerInfo and playerInfo.class then
		local classColorTable = _G.RAID_CLASS_COLORS or _G.CUSTOM_CLASS_COLORS
		if classColorTable then
			local classColor = classColorTable[playerInfo.class]
			if classColor then
				coloredPlayerName = wrapInColor(m.player_name, classColor.r, classColor.g, classColor.b)
				if addon and addon.dbg then
					addon.dbg("-->class color: using player list class="..addon.dbgSafeValue(playerInfo.class))
				end
			else
				if addon and addon.dbg then
					addon.dbg("-->class color: class "..addon.dbgSafeValue(playerInfo.class).." NOT found in color table")
				end
			end
		end
	end

	-- Construct styled player name as a clickable link
	-- Generate the clickable player link with level and class color
	if m.sender_name and string.sub(m.chat_type or "", 1, 7) ~= "MONSTER" and
	    string.sub(m.chat_type or "", 1, 18) ~= "RAID_BOSS_EMOTE" and
	    m.chat_type ~= "CHANNEL_NOTICE" and m.chat_type ~= "CHANNEL_NOTICE_USER" then

		local linkTarget = m.sender_name
		local displayText = coloredPlayerName

		-- Add level prefix if available
		if coloredLevel ~= "" then
			displayText = coloredLevel..":"..coloredPlayerName
		end

		-- Add timerunning icon if available, checks for secret values just in case
		displayText = addTimeRunningIcon(m.player_guid, displayText)

		local playerLink
		if m.chat_type == "BN_WHISPER" or m.chat_type == "BN_WHISPER_INFORM" or m.chat_type == "BN_CONVERSATION" then
			if m.arg13 then
				playerLink = string.format("|HBNplayer:%s:%s:%s:%s:%s|h[%s]|h", linkTarget, m.arg13, m.arg11 or 0, m.CHATGROUP or 0, m.chat_target or "", displayText)
			else
				playerLink = "[" .. displayText .. "]"
			end
		else
			playerLink = string.format("|Hplayer:%s:%s:%s:%s|h[%s]|h", linkTarget, m.arg11 or 0, m.CHATGROUP or 0, m.chat_target or "", displayText)
		end

		m.player_link = playerLink
		m.styled_player_name = playerLink
		if addon and addon.dbg then
			addon.dbg("-->clickable player_link created: "..addon.dbgSafeValue(playerLink))
			if coloredLevel ~= "" then
				addon.dbg("-->stylized_player_name applied: ["..addon.dbgSafeValue(coloredLevel)..":"..addon.dbgSafeValue(m.player_name).."]")
			else
				addon.dbg("-->stylized_player_name applied: ["..addon.dbgSafeValue(m.player_name).."] (no level)")
			end
		end
	else
		-- Fallback: non-clickable styled player name for non-player messages
		if coloredLevel ~= "" then
			-- Format: [70:Xruptor]
			m.styled_player_name = "["..coloredLevel..":"..coloredPlayerName.."]"
			if addon and addon.dbg then
				addon.dbg("-->stylized_player_name applied: ["..addon.dbgSafeValue(coloredLevel)..":"..addon.dbgSafeValue(m.player_name).."]")
				addon.dbg("-->Final styled name result: "..addon.dbgSafeValue(m.styled_player_name))
			end
		else
			-- Format: [Xruptor]
			m.styled_player_name = "["..coloredPlayerName.."]"
			if addon and addon.dbg then
				addon.dbg("-->stylized_player_name applied: ["..addon.dbgSafeValue(m.player_name).."] (no level)")
				addon.dbg("-->Final styled name result: "..addon.dbgSafeValue(m.styled_player_name))
			end
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
	if not addon then return false end

	if not _G.XCHT_DB or not _G.XCHT_DB.disableChatEnterLeaveNotice then
		return false
	end

	if event == "CHAT_MSG_CHANNEL_NOTICE" or event == "CHAT_MSG_CHANNEL_JOIN" or event == "CHAT_MSG_CHANNEL_LEAVE" then
		return true
	end

	if event == "CHAT_MSG_SYSTEM" and type(message) == "string" then
		if string.find(message, "|Hplayer:", 1, true) and (string.find(message, "has joined", 1, true) or string.find(message, "has left", 1, true)) then
			return true
		end
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
