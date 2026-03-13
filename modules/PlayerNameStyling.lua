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
	return tonumber("0x" .. string.sub(hex, 3, 4), 10) / 255,
		tonumber("0x" .. string.sub(hex, 5, 6), 10) / 255,
		tonumber("0x" .. string.sub(hex, 7, 8), 10) / 255,
		tonumber("0x" .. string.sub(hex, 1, 2), 10) / 255
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
	return "|c" .. hexColor .. text .. "|r"
end

-- ============================================================================
-- PLAYER SECTION FORMATTING
-- ============================================================================

local function StylePlayerSection(m)
	if not addon then return end

	if not (_G.XCHT_DB and _G.XCHT_DB.enablePlayerChatStyle) then
		return
	end
	if not m.player_name or m.player_name == "" then
		return
	end

	-- Extract class color from Blizzard-formatted output text
	local extractedClassColor = nil
	if m.OUTPUT and type(m.OUTPUT) == "string" then
		-- Look for class color in the formatted output around the player name
		-- Blizzard formats player names like |cffRRGGBB[PlayerName]|r or just |cffRRGGBBPlayerName|r
		local playerNamePattern = string.gsub(m.player_name, "([%-%^%$%(%)%%%[%]%.%*%+%?])", "%%%1")
		-- Try different patterns to find the color code
		local patterns = {
			"|cff(%x%x%x%x%x%x)%[" .. playerNamePattern .. "%]|r",  -- |cffRRGGBB[Name]|r
			"|cff(%x%x%x%x%x%x)" .. playerNamePattern .. "|r",       -- |cffRRGGBBName|r (before brackets)
			"|cff(%x%x%x%x%x%x)%|" .. playerNamePattern .. "|h",    -- |cffRRGGBB|Name|h (player link)
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
					addon.dbg("StylePlayerSection: Extracted class color from Blizzard output: R=" .. string.format("%.2f", extractedClassColor.r) .. " G=" .. string.format("%.2f", extractedClassColor.g) .. " B=" .. string.format("%.2f", extractedClassColor.b))
				end
				break
			end
		end
	end

	-- Always look up player info for level, even if we have extracted color
	local playerInfo = nil
	local nameToLookup = m.player_name or m.player_link
	if nameToLookup then
		local cleanName = string.gsub(string.lower(nameToLookup), "[^%a%d]", "")
		playerInfo = addon.playerListByName and addon.playerListByName[cleanName]

		if not playerInfo then
			-- Fallback to original name if cleanName lookup fails
			playerInfo = addon.playerListByName and addon.playerListByName[nameToLookup]
		end

		if addon and addon.dbg then
			addon.dbg("-->player list lookup: name=" .. tostring(nameToLookup) .. " clean=" .. tostring(cleanName) .. " found=" .. tostring(playerInfo and "yes" or "no"))
			if playerInfo then
				addon.dbg("-->playerInfo: level=" .. tostring(playerInfo.level or "nil") .. " class=" .. tostring(playerInfo.class or "nil"))
			end
		end
	end

	-- Simple debug summary
	if addon and addon.dbg then
		addon.dbg("-->StylePlayerSection: name=" .. tostring(m.player_name) .. " player_class=" .. tostring(m.player_class or "nil") .. " extractedColor=" .. tostring(extractedClassColor and "yes" or "no"))
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
			addon.dbg("-->level calculation: playerInfo.level=" .. tostring(playerInfo.level) .. " tonumber=" .. tostring(level) .. " >0=" .. tostring(level and level > 0))
		end
		if level and level > 0 then
			local colorFunc = _G.GetQuestDifficultyColor or _G.GetDifficultyColor
			if colorFunc then
				local difficultyColor = colorFunc(level)
				if addon and addon.dbg then
					addon.dbg("-->level difficulty color: R=" .. string.format("%.2f", difficultyColor.r) .. " G=" .. string.format("%.2f", difficultyColor.g) .. " B=" .. string.format("%.2f", difficultyColor.b))
				end
				if difficultyColor then
					coloredLevel = wrapInColor(tostring(level), difficultyColor.r, difficultyColor.g, difficultyColor.b)
					if addon and addon.dbg then
						addon.dbg("-->coloredLevel result: " .. tostring(coloredLevel))
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
					addon.dbg("-->class color: using GUID class=" .. tostring(m.player_class))
				end
			else
				if addon and addon.dbg then
					addon.dbg("-->class color: GUID class " .. tostring(m.player_class) .. " NOT found in color table")
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
					addon.dbg("-->class color: using player list class=" .. tostring(playerInfo.class))
				end
			else
				if addon and addon.dbg then
					addon.dbg("-->class color: class " .. tostring(playerInfo.class) .. " NOT found in color table")
				end
			end
		end
	end

	-- Construct styled player name directly without templates
	if coloredLevel ~= "" then
		-- Format: [70:Xruptor]
		m.styled_player_name = "[" .. coloredLevel .. ":" .. coloredPlayerName .. "]"
		if addon and addon.dbg then
			addon.dbg("-->stylized_player_name applied: [" .. coloredLevel .. ":" .. m.player_name .. "]")
			addon.dbg("-->Final styled name result: " .. m.styled_player_name)
		end
	else
		-- Format: [Xruptor]
		m.styled_player_name = "[" .. coloredPlayerName .. "]"
		if addon and addon.dbg then
			addon.dbg("-->stylized_player_name applied: [" .. m.player_name .. "] (no level)")
			addon.dbg("-->Final styled name result: " .. m.styled_player_name)
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
