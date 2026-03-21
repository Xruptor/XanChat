--[[
	ChannelShortening.lua - Channel name shortening and channel extraction for XanChat
	Refactored for:
	- Fixed global string.gsub usage (now uses string.gsub)
	- Simplified pattern matching logic
	- Removed redundant nil checks
	- Better early returns
	- Centralized channel extraction and parsing
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- CHANNEL NAME SHORTENING
-- ============================================================================

local SHORT_CHANNEL_REPLACEMENTS = {
	-- Simple word replacements (for fallback matching)
	{ addon.L.ChannelGeneral or "General", addon.L.ShortGeneral or "Gen" },
	{ addon.L.ChannelTradeServices or "Trade - Services", addon.L.ShortTradeServices or "Trade-S" },
	{ addon.L.ChannelTrade or "Trade", addon.L.ShortTrade or "Trade" },
	{ addon.L.ChannelWorldDefense or "WorldDefense", addon.L.ShortWorldDefense or "WDef" },
	{ addon.L.ChannelLocalDefense or "LocalDefense", addon.L.ShortLocalDefense or "LDef" },
	{ addon.L.ChannelLookingForGroup or "LookingForGroup", addon.L.ShortLookingForGroup or "LFG" },
	{ addon.L.ChannelGuildRecruitment or "GuildRecruitment", addon.L.ShortGuildRecruitment or "Guild" },
	{ addon.L.ChannelNewComerChat or "NewComers", addon.L.ShortNewComerChat or "New" },
	-- Case-insensitive patterns
	{ addon.L.ChannelNameGeneral or "[Gg]eneral", addon.L.ShortGeneral or "Gen" },
	{ addon.L.ChannelNameTrade or "[Tt]rade", addon.L.ShortTrade or "Trade" },
	{ addon.L.ChannelNameWorldDefense or "[Ww]orld[Dd]efense", addon.L.ShortWorldDefense or "WDef" },
	{ addon.L.ChannelNameLocalDefense or "[Ll]ocal[Dd]efense", addon.L.ShortLocalDefense or "LDef" },
	{ addon.L.ChannelNameLookingForGroup or "[Ll]ooking[Ff]or[Gg]roup", addon.L.ShortLookingForGroup or "LFG" },
	{ addon.L.ChannelNameGuildRecruitment or "[Gg]uild[Rr]ecruitment", addon.L.ShortGuildRecruitment or "Guild" },
	{ addon.L.ChannelNameNewcomerChat or "[Nn]ewcomer", addon.L.ShortNewComerChat or "New" },
	-- Blizzard hyperlink format with actual channel number: |Hchannel:1|h[1. General - Zone]|h
	{ "|Hchannel:%d+|h%[%d+%. ]*General.-|h", addon.L.ShortGeneral or "Gen" },
	{ "|Hchannel:%d+|h%[%d+%. ]*Trade.-|h", addon.L.ShortTrade or "Trade" },
	{ "|Hchannel:%d+|h%[%d+%. ]*WorldDefense.-|h", addon.L.ShortWorldDefense or "WDef" },
	{ "|Hchannel:%d+|h%[%d+%. ]*LocalDefense.-|h", addon.L.ShortLocalDefense or "LDef" },
	{ "|Hchannel:%d+|h%[%d+%. ]*LookingForGroup.-|h", addon.L.ShortLookingForGroup or "LFG" },
	{ "|Hchannel:%d+|h%[%d+%. ]*GuildRecruitment.-|h", addon.L.ShortGuildRecruitment or "Guild" },
	{ "|Hchannel:%d+|h%[%d+%. ]*Newcomer Chat.-|h", addon.L.ShortNewComerChat or "New" },
}

-- ============================================================================
-- CHANNEL INFORMATION EXTRACTION
-- ============================================================================

-- Helper function to extract channel number from string
-- Tries multiple patterns to find the channel number in various formats
local function extractChannelNumberFromString(str)
	if not str or type(str) ~= "string" then return nil end

	-- Try various patterns for channel number:
	-- 1. |Hchannel:1|h or |Hchannel:CHANNEL:1|h
	-- 2. [1. prefix in bracketed text like [1. General]
	-- 3. Just [1] bracketed number
	return str:match("|Hchannel:(%d+)|h") or
	       str:match("|Hchannel:CHANNEL:(%d+)|h") or
	       str:match("|Hchannel:channel:(%d+)|h") or
	       str:match("^%[(%d+)%..*%]") or
	       str:match("%[(%d+)%s")
end

-- Helper function to extract channel name from bracketed content
-- Works with formats like: |Hchannel:1|h[1. General - Zone]|h
local function extractChannelNameFromString(str, channelNum)
	if not str or type(str) ~= "string" or not channelNum then return "" end

	-- Try to extract from hyperlink bracketed content: |Hchannel:1|h[1. General - Zone]|h
	-- The pattern needs to match the bracket content but stop at the first ] after the channel name
	-- We handle zone-specific names like "General - Ragefire Chasm" by capturing the base name
	local bracketMatch = str:match("|Hchannel:"..channelNum.."|h%[([^%]]*)%]")
	if bracketMatch then
		-- Remove leading number and any zone suffix, keep the channel name
		-- For zone-specific names like "General - Ragefire Chasm", extract just "General"
		-- Pattern: remove optional zone suffix like " - Zone" or " - Zone Name"
		local name = bracketMatch:gsub("^"..channelNum.."[%. ]*", ""):gsub("%s*%-.*$", "")
		if name and name ~= "" then
			return name:gsub("^%s+", ""):gsub("%s+$", "")
		end
	end

	-- Fallback: try to find the channel name anywhere in the string
	-- Use simple locale-aware patterns from addon.L to extract channel names
	-- Locale patterns are lowercase strings like "general", "trade", etc.

	-- Define locale channel patterns with fallbacks
	local localePatterns = {
		{ addon.L.ChannelPatternShortGeneral or "general", "General" },
		{ addon.L.ChannelPatternShortTrade or "trade", "Trade" },
		{ addon.L.ChannelPatternShortWorldDefense or "worlddefense", "WorldDefense" },
		{ addon.L.ChannelPatternShortLocalDefense or "localdefense", "LocalDefense" },
		{ addon.L.ChannelPatternShortLookingForGroup or "lookingforgroup", "LookingForGroup" },
		{ addon.L.ChannelPatternShortGuildRecruitment or "guildrecruitment", "GuildRecruitment" },
		{ addon.L.ChannelPatternShortNewcomerChat or "newcomer", "Newcomer" },
	}

	-- For handling names with suffixes like "General - Zone", strip whitespace/special chars for matching
	local lowerStr = str:lower():gsub("[%s%-]", "")

	for _, patternPair in ipairs(localePatterns) do
		local searchPattern, properName = unpack(patternPair)
		if searchPattern and properName and searchPattern ~= "" then
			-- searchPattern is already lowercase from locale, just need to strip spaces/hyphens
			local cleanedPattern = searchPattern:gsub("[%s%-]", "")
			-- Require minimum 4 chars for search pattern to avoid false matches
			if cleanedPattern ~= "" and #cleanedPattern >= 4 and lowerStr:find(cleanedPattern, 1, true) then
				return properName
			end
		end
	end

	return ""
end

-- ============================================================================
-- UNIFIED CHANNEL EXTRACTION
-- ============================================================================

-- Unified function to extract channel info from multiple sources
-- Populates m.channel_number and m.channel_name if found
-- Uses SafeType() to handle secret values gracefully
-- Returns true if extraction was attempted, false otherwise
local function extractChannelInfoFromSources(m, sources)
	if not m or not m.channel_number then return false end

	local extractedNum = m.channel_number
	local extractedName = m.channel_name or ""

	-- Try each source in order until we find channel info
	for _, source in ipairs(sources) do
		-- Skip if source is empty or nil
		if not source or source == "" then
			-- continue to next source
		else
			-- Use SafeType() to check type without errors on secret values
			local sourceType = addon.SafeType and addon.SafeType(source) or type(source)

			-- If channel number already found, only extract name
			if extractedNum and extractedNum ~= "" then
				if sourceType == "string" then
					-- Try to extract channel name from this source
					local nameFromSource = extractChannelNameFromString(source, extractedNum)
					if nameFromSource and nameFromSource ~= "" then
						extractedName = nameFromSource
						break
					end
				end
			else
				-- Try to extract channel number from this source
				if sourceType == "number" then
					extractedNum = tostring(source)
				elseif sourceType == "string" then
					local numFromSource = extractChannelNumberFromString(source)
					if numFromSource and numFromSource ~= "" then
						extractedNum = numFromSource
						-- Also try to extract name from the same source
						local nameFromSource = extractChannelNameFromString(source, extractedNum)
						if nameFromSource and nameFromSource ~= "" then
							extractedName = nameFromSource
						end
						break
					end
				end
			end
		end
	end

	-- Update m with extracted values
	if extractedNum and extractedNum ~= "" and (not m.channel_number or m.channel_number == "") then
		m.channel_number = extractedNum
	end
	if extractedName and extractedName ~= "" and (not m.channel_name or m.channel_name == "") then
		m.channel_name = extractedName
	end

	return extractedNum and extractedNum ~= "" or extractedName and extractedName ~= ""
end

-- ============================================================================
-- DEFERRED CHANNEL EXTRACTION (from OUTPUT)
-- ============================================================================

-- Unified function to handle deferred channel extraction from OUTPUT
-- Called when channel info wasn't available in args but might be in OUTPUT
local function extractChannelFromOutputIfDeferred(m)
	if not m or not m.deferredChannelExtraction then return false end
	local sourceType = addon.SafeType and addon.SafeType(m.OUTPUT) or type(m.OUTPUT)

	if m.deferredChannelExtraction and sourceType == "string" and m.OUTPUT ~= "" then
		local numFromOutput = extractChannelNumberFromString(m.OUTPUT)
		if numFromOutput then
			m.channel_number = numFromOutput
			if not m.channel_name or m.channel_name == "" then
				m.channel_name = extractChannelNameFromString(m.OUTPUT, numFromOutput)
			end
			m.deferredChannelExtraction = false
			addon.dbg("ChatFrame_MessageEventHandler: extracted channel number from OUTPUT="..tostring(numFromOutput))
			return true
		end
	end

	return false
end

-- ============================================================================
-- LEGACY CHANNEL INFO EXTRACTION (extractChannelInfo)
-- ============================================================================

-- Extract channel information into section
local function extractChannelInfo(s, arg7, arg8, arg9, arg10, chatGroup)
	if not s then return end

	-- Clear channel extraction flag first
	s.deferredChannelExtraction = nil

	-- Special handling for BN_CONVERSATION channels
	if chatGroup == "BN_CONVERSATION" then
		local bnChannelNum = tonumber(arg8) or 0
		s.channel_number = tostring((_G.MAX_WOW_CHAT_CHANNELS or 20) + bnChannelNum)
		if _G.CHAT_BN_CONVERSATION_SEND then
			s.channel_name = string.match(_G.CHAT_BN_CONVERSATION_SEND or "", "%d%.%s+(.+)")
		end
		return
	end

	-- For channel events, build list of sources to try in order
	-- Priority: arg8 (primary), then arg7, arg9, arg10
	local sources = {}
	if arg8 then table.insert(sources, arg8) end
	if arg7 then table.insert(sources, arg7) end
	if arg9 then table.insert(sources, arg9) end
	if arg10 then table.insert(sources, arg10) end

	-- Use unified function to extract from all sources
	local found = extractChannelInfoFromSources(s, sources)

	-- If still no channel number and this is a CHANNEL event, mark for deferred extraction
	-- This handles channel notice events where OUTPUT contains the info but args don't
	if not found and chatGroup == "CHANNEL" then
		s.channel_number = ""
		s.channel_name = ""
		s.deferredChannelExtraction = true
	elseif not found then
		s.channel_number = ""
		s.channel_name = ""
	end
end

-- ============================================================================
-- CHANNEL NAME SHORTENING FUNCTIONS
-- ============================================================================

local function applyShortChannelNamesToSections(m)
	if not addon then return end

	-- Early return if short names disabled
	if not (_G.XCHT_DB and _G.XCHT_DB.shortNames) then
		if addon and addon.dbg then
			addon.dbg("applyShortChannelNamesToSections: shortNames disabled")
		end
		return
	end

	-- Always use OUTPUT for shortening since it contains the full hyperlink format
	-- channel_name alone doesn't have the hyperlink structure needed for replacement
	local longName = m.OUTPUT

	if not longName or longName == "" then
		if addon and addon.dbg then
			addon.dbg("applyShortChannelNamesToSections: no OUTPUT to process")
		end
		return
	end

	if addon and addon.dbg then
		addon.dbg("applyShortChannelNamesToSections: PROCESSING OUTPUT="..tostring(string.sub(longName, 1, 150)))
	end

	-- Get channel number if not already set
	-- Use the addon's centralized extraction function
	if (not m.channel_number or m.channel_number == "") and type(longName) == "string" then
		m.channel_number = extractChannelNumberFromString(longName)
	end

	-- Also extract the short channel name to update m.channel_name for FormatChatMessage
	if m.channel_number and type(longName) == "string" then
		m.channel_name = extractChannelNameFromString(longName, m.channel_number)
	end

	local channelNum = m.channel_number

	if addon and addon.dbg then
		addon.dbg("applyShortChannelNamesToSections: extracted channelNum="..tostring(channelNum).." channel_name="..tostring(string.sub(m.channel_name or "", 1, 30)))
	end

	-- Try to find and replace the channel bracket with shortened version
	if channelNum then
		-- Match the channel bracket (format: [1. General - Ragefire Chasm] or [1. General])
		-- The OUTPUT may or may not have a hyperlink prefix, so we try both patterns
		local bracketContent = longName:match("|Hchannel:%d+|h%["..channelNum.."%. [^%]]+%]|h") or
		                          longName:match("%["..channelNum.."%. [^%]]+%]")

		if addon and addon.dbg then
			addon.dbg("applyShortChannelNamesToSections: bracketContent="..tostring(bracketContent))
		end

		if bracketContent then
			-- Extract just the channel name (remove number prefix and zone suffix)
			-- e.g., "1. General - Orgrimmar" -> "General"
			local baseName = bracketContent:gsub("^%d+%.?%s*", ""):gsub("%s*%-.*$", "")
			local baseNameLower = baseName:lower()

			-- Look up the short name for this channel
			local shortName = nil
			for _, replacement in ipairs(SHORT_CHANNEL_REPLACEMENTS) do
				local longPattern, replacementName = unpack(replacement)
				if longPattern and replacementName then
					local patternClean = longPattern:gsub("[%[%]]", ""):gsub("%^", ""):gsub("%-", ""):lower()
					if patternClean ~= "" and baseNameLower:find(patternClean, 1, true) then
						shortName = replacementName
						break
					end
				end
			end

			-- If we found a short name, replace the channel bracket
			if shortName then
				-- Build the shortened format: [1] GN
				local shortenedBracket = "["..channelNum.."] "..shortName.."]"
				-- Replace the original bracket with the shortened one
				-- Need to escape special regex chars in the bracket content
				local escapedBracket = bracketContent:gsub("[%(%)%.%*%+%?%[%]%^%$%-]", "%%%0")
				local originalPattern = "%["..escapedBracket.."%]"
				longName = string.gsub(longName, originalPattern, shortenedBracket, 1)
				if addon and addon.dbg then
					addon.dbg("applyShortChannelNamesToSections: replaced '"..baseName.."' with '"..shortName.."'")
				end
			end
		end
	end

	-- Write back to OUTPUT
	m.OUTPUT = longName

	-- Update m.channel_name with the short name for FormatChatMessage use
	-- Look up the short name from SHORT_CHANNEL_REPLACEMENTS based on the extracted full name
	if m.channel_name and m.channel_name ~= "" then
		local fullName = m.channel_name:lower():gsub("[%s%-]", "")
		if addon and addon.dbg then
			addon.dbg("applyShortChannelNamesToSections: Looking up short name for fullName="..tostring(fullName))
		end
		for _, replacement in ipairs(SHORT_CHANNEL_REPLACEMENTS) do
			local longPattern, shortName = unpack(replacement)
			if longPattern and shortName then
				local patternMatched = false

				-- Check if pattern matches the full name
				if longPattern:find("%[") then
					-- Pattern contains [Gg] style - use it as a Lua pattern directly
					-- The pattern like "[Gg]eneral" should match "general"
					patternMatched = (fullName:match("^" .. longPattern .. "$") ~= nil)
				else
					-- Simple word pattern - case-insensitive comparison
					patternMatched = (longPattern:lower() == fullName)
				end

				if addon and addon.dbg then
					addon.dbg("applyShortChannelNamesToSections: Checking longPattern="..tostring(longPattern).." shortName="..tostring(shortName).." matched="..tostring(patternMatched))
				end

				if patternMatched then
					m.channel_name = shortName
					if addon and addon.dbg then
						addon.dbg("applyShortChannelNamesToSections: mapped '"..tostring(longPattern).."' to '"..shortName.."'")
					end
					break
				end
			end
		end
	end

	if addon and addon.dbg then
		addon.dbg("applyShortChannelNamesToSections: final channel_name="..addon.dbgSafeValue(m.channel_name))
	end
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.applyShortChannelNamesToSections = applyShortChannelNamesToSections
addon.SHORT_CHANNEL_REPLACEMENTS = SHORT_CHANNEL_REPLACEMENTS
addon.extractChannelNumberFromString = extractChannelNumberFromString
addon.extractChannelNameFromString = extractChannelNameFromString
addon.extractChannelInfoFromSources = extractChannelInfoFromSources
addon.extractChannelFromOutputIfDeferred = extractChannelFromOutputIfDeferred
addon.extractChannelInfo = extractChannelInfo
