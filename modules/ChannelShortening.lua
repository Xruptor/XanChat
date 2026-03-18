--[[
	ChannelShortening.lua - Channel name shortening for XanChat
	Refactored for:
	- Fixed global string.gsub usage (now uses string.gsub)
	- Simplified pattern matching logic
	- Removed redundant nil checks
	- Better early returns
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- CHANNEL NAME SHORTENING
-- ============================================================================

local SHORT_CHANNEL_REPLACEMENTS = {
	{ addon.L.ChannelGeneral or "General", addon.L.ShortGeneral or "Gen" },
	{ addon.L.ChannelTradeServices or "Trade - Services", addon.L.ShortTradeServices or "Trade-S" },
	{ addon.L.ChannelTrade or "Trade", addon.L.ShortTrade or "Trade" },
	{ addon.L.ChannelWorldDefense or "WorldDefense", addon.L.ShortWorldDefense or "WDef" },
	{ addon.L.ChannelLocalDefense or "LocalDefense", addon.L.ShortLocalDefense or "LDef" },
	{ addon.L.ChannelLookingForGroup or "LookingForGroup", addon.L.ShortLookingForGroup or "LFG" },
	{ addon.L.ChannelGuildRecruitment or "GuildRecruitment", addon.L.ShortGuildRecruitment or "Guild" },
	{ addon.L.ChannelNewComerChat or "NewComers", addon.L.ShortNewComerChat or "New" },
	-- Use universal locale pattern variables - these are localized per language
	-- ChannelName patterns: simple case-insensitive word matching
	{ addon.L.ChannelNameGeneral or "[Gg]eneral", addon.L.ShortGeneral or "Gen" },
	{ addon.L.ChannelNameTrade or "[Tt]rade", addon.L.ShortTrade or "Trade" },
	{ addon.L.ChannelNameWorldDefense or "[Ww]orld[Dd]efense", addon.L.ShortWorldDefense or "WDef" },
	{ addon.L.ChannelNameLocalDefense or "[Ll]ocal[Dd]efense", addon.L.ShortLocalDefense or "LDef" },
	{ addon.L.ChannelNameLookingForGroup or "[Ll]ooking[Ff]or[Gg]roup", addon.L.ShortLookingForGroup or "LFG" },
	{ addon.L.ChannelNameGuildRecruitment or "[Gg]uild[Rr]ecruitment", addon.L.ShortGuildRecruitment or "Guild" },
	{ addon.L.ChannelNameNewcomerChat or "[Nn]ewcomer", addon.L.ShortNewComerChat or "New" },
	-- ChannelPattern patterns: full bracketed channel name match with prefix/suffix tolerance
	-- These patterns match the full hyperlink format: |Hchannel:CHANNEL:1|h[1. General - Zone]|h
	-- Uses .- (non-greedy) to match everything up to the next |h
	{ addon.L.ChannelPatternGeneral or "|Hchannel:CHANNEL:%d+|h%[1%. ]*General.-|h", addon.L.ShortGeneral or "Gen" },
	{ addon.L.ChannelPatternTrade or "|Hchannel:CHANNEL:%d+|h%[%d+%. ]*Trade.-|h", addon.L.ShortTrade or "Trade" },
	{ addon.L.ChannelPatternWorldDefense or "|Hchannel:CHANNEL:%d+|h%[%d+%. ]*WorldDefense.-|h", addon.L.ShortWorldDefense or "WDef" },
	{ addon.L.ChannelPatternLocalDefense or "|Hchannel:CHANNEL:%d+|h%[%d+%. ]*LocalDefense.-|h", addon.L.ShortLocalDefense or "LDef" },
	{ addon.L.ChannelPatternLookingForGroup or "|Hchannel:CHANNEL:%d+|h%[%d+%. ]*LookingForGroup.-|h", addon.L.ShortLookingForGroup or "LFG" },
	{ addon.L.ChannelPatternGuildRecruitment or "|Hchannel:CHANNEL:%d+|h%[%d+%. ]*GuildRecruitment.-|h", addon.L.ShortGuildRecruitment or "Guild" },
	{ addon.L.ChannelPatternNewcomerChat or "|Hchannel:CHANNEL:%d+|h%[%d+%. ]*Newcomer Chat.-|h", addon.L.ShortNewComerChat or "New" },
}

local function applyShortChannelNamesToSections(m)
	if not addon then return end

	-- Early return if short names disabled
	if not (_G.XCHT_DB and _G.XCHT_DB.shortNames) then
		if addon and addon.dbg then
			addon.dbg("applyShortChannelNamesToSections: shortNames disabled")
		end
		return
	end

	-- Check if we have a channel_name field, otherwise apply shortening to OUTPUT
	local useOutput = not m.channel_name or m.channel_name == ""
	local longName = useOutput and m.OUTPUT or m.channel_name
	local originalName = longName

	if not longName or longName == "" then
		if addon and addon.dbg then
			addon.dbg("applyShortChannelNamesToSections: no channel name or OUTPUT to process")
		end
		return
	end

	-- Debug: log initial state
	if addon and addon.dbg then
		addon.dbg("applyShortChannelNamesToSections: m.channel_number="..tostring(m.channel_number).." m.channel_name="..tostring(m.channel_name).." m.OUTPUT="..tostring(string.sub(m.OUTPUT or "", 1, 50)))
		addon.dbg("applyShortChannelNamesToSections: useOutput="..tostring(useOutput).." longName="..tostring(string.sub(longName or "", 1, 50)))
	end

	-- Helper function to strip whitespace
	local function stripWhitespace(s)
		return string.gsub(s, "%s+", "")
	end

	-- Helper function to check if pattern is a simple word match (not a regex pattern)
	local function isSimpleWordPattern(pattern)
		return not pattern:find("[%(%)%.%*%+%?%[%]%^%$]") and
		       not pattern:find("[%-%]")
	end

	-- Get channel number and name if not already set
	-- Use the addon's centralized extraction function
	if (not m.channel_number or m.channel_number == "") and type(longName) == "string" then
		m.channel_number = addon.extractChannelNumberFromString(longName)
	end
	if (not m.channel_name or m.channel_name == "") and m.channel_number and type(longName) == "string" then
		m.channel_name = addon.extractChannelNameFromString(longName, m.channel_number)
	end

	local channelNum = m.channel_number
	local useClickable = useOutput and channelNum

	if addon and addon.dbg then
		addon.dbg("applyShortChannelNamesToSections: extracted channelNum="..tostring(channelNum).." useClickable="..tostring(useClickable).." channel_name="..tostring(string.sub(m.channel_name or "", 1, 30)))
	end

	-- Helper function to apply replacement with clickable channel number if needed
	local function applyReplacement(textToModify, longPattern, shortName)
		if useClickable and channelNum then
			return string.gsub(textToModify, longPattern, "|Hchannel:"..channelNum.."|h["..channelNum.."] "..shortName.."|h")
		else
			return string.gsub(textToModify, longPattern, shortName)
		end
	end

	-- Try each replacement pattern
	for _, replacement in ipairs(SHORT_CHANNEL_REPLACEMENTS) do
		local longPattern, shortName = unpack(replacement)
		if longPattern and shortName then
			local beforeReplace = longName
			longName = applyReplacement(longName, longPattern, shortName)
			if addon and addon.dbg and beforeReplace ~= longName then
				addon.dbg("applyShortChannelNamesToSections: replaced via main pattern: "..tostring(longPattern))
				break
			end
		end
	end

	-- Fallback 1: If no change occurred, try stripping all whitespace and matching
	if longName == originalName then
		local strippedName = stripWhitespace(originalName):lower()

		for _, replacement in ipairs(SHORT_CHANNEL_REPLACEMENTS) do
			local longPattern, shortName = unpack(replacement)
			if longPattern and shortName and isSimpleWordPattern(longPattern) then
				local strippedPattern = stripWhitespace(longPattern):gsub("[^%w]+", ""):lower()
				if strippedPattern ~= "" and strippedName:find(strippedPattern, 1, true) then
					-- For simple word patterns, we need to handle the hyperlink format
					-- Try to find and replace the full hyperlink
					if useClickable and channelNum then
						-- Try to replace the full hyperlink pattern with shortened format
						local hyperlinkPattern = "|Hchannel:CHANNEL:"..channelNum.."|h%[%d+%. ]*"..longPattern.."[%s%-][^]%]*|h"
						local replaced = string.gsub(originalName, hyperlinkPattern, "|Hchannel:"..channelNum.."|h["..channelNum.."] "..shortName.."|h")
						if replaced ~= originalName then
							longName = replaced
							if addon and addon.dbg then
								addon.dbg("applyShortChannelNamesToSections: matched via whitespace fallback with hyperlink for pattern: "..tostring(longPattern))
							end
							break
						end
					end
				end
			end
		end
	end

	-- Fallback 2: Extract channel name from brackets and compare against patterns
	if longName == originalName then
		-- Try to extract bracket content from hyperlink format
		local fullHyperlinkMatch = originalName:match("|Hchannel:CHANNEL:(%d+)|h%[([^%]]+)%]")
		local hyperlinkNum, bracketContent = fullHyperlinkMatch, fullHyperlinkMatch

		if not hyperlinkNum and channelNum then
			-- Try format |Hchannel:1|h[1. General]|h
			fullHyperlinkMatch = originalName:match("|Hchannel:"..channelNum.."|h%[([^%]]+)%]")
			bracketContent = fullHyperlinkMatch
		end

		if not bracketContent then
			-- Try simple bracket format
			bracketContent = originalName:match("%[([^%]]+)%]")
		end

		if bracketContent then
			local extractedName = bracketContent:gsub("^%d+%.?%s*", ""):gsub("[%s%-].*", ""):lower()

			if addon and addon.dbg then
				addon.dbg("applyShortChannelNamesToSections: bracket extraction - extractedName="..tostring(extractedName).." bracketContent="..tostring(string.sub(bracketContent or "", 1, 30)))
			end

			for _, replacement in ipairs(SHORT_CHANNEL_REPLACEMENTS) do
				local longPattern, shortName = unpack(replacement)
				if longPattern and shortName and isSimpleWordPattern(longPattern) then
					local patternName = longPattern:gsub("[%[%]]", ""):gsub("%^", ""):lower()
					if patternName ~= "" and extractedName:find(patternName, 1, true) then
						-- Replace the entire hyperlink with clickable version
						if useClickable and channelNum then
							-- Handle both |Hchannel:CHANNEL:1|h and |Hchannel:1|h formats
							local patternToMatch = originalName:match("|Hchannel:CHANNEL:%d+|h") and
							                "|Hchannel:CHANNEL:"..channelNum.."|h%["..bracketContent:gsub("[%(%)%.%*%+%?%[%]%^%$%-]", "%%%1").."%]|h" or
							                "|Hchannel:"..channelNum.."|h%["..bracketContent:gsub("[%(%)%.%*%+%?%[%]%^%$%-]", "%%%1").."%]|h"
							longName = string.gsub(originalName, patternToMatch, "|Hchannel:"..channelNum.."|h["..channelNum.."] "..shortName.."|h")
						else
							-- Simple bracket replacement (non-clickable)
							longName = string.gsub(originalName, "%["..bracketContent:gsub("[%(%)%.%*%+%?%[%]%^%$%-]", "%%%1").."%]", shortName)
						end
						if addon and addon.dbg then
							addon.dbg("applyShortChannelNamesToSections: matched via bracket extraction for pattern: "..tostring(longPattern))
						end
						break
					end
				end
			end
		end
	end

	-- Fallback 3: Check for partial word matches in the full string
	if longName == originalName then
		local lowerName = originalName:lower()

		for _, replacement in ipairs(SHORT_CHANNEL_REPLACEMENTS) do
			local longPattern, shortName = unpack(replacement)
			if longPattern and shortName and isSimpleWordPattern(longPattern) then
				-- Extract the base word from the pattern (remove [Gg] style brackets)
				local baseWord = longPattern:match("[%[%](.+)[%]]") or longPattern
				baseWord = baseWord:gsub("[^%w]+", ""):lower()

				if baseWord ~= "" and #baseWord > 3 and lowerName:find(baseWord, 1, true) then
					-- Found a partial match, replace the full hyperlink
					if useClickable and channelNum then
						-- Try to find the hyperlink with this channel name
						local hyperlinkPattern = "|Hchannel:CHANNEL:"..channelNum.."|h%[%d+%. ]*"..baseWord..".*%]|h"
						local replaced = string.gsub(originalName, hyperlinkPattern, "|Hchannel:"..channelNum.."|h["..channelNum.."] "..shortName.."|h")
						if replaced ~= originalName then
							longName = replaced
							if addon and addon.dbg then
								addon.dbg("applyShortChannelNamesToSections: matched via partial word fallback for pattern: "..tostring(longPattern))
							end
							break
						end
					else
						-- Simple word replacement
						longName = applyReplacement(originalName, longPattern, shortName)
						if addon and addon.dbg then
							addon.dbg("applyShortChannelNamesToSections: matched via partial word fallback for pattern: "..tostring(longPattern))
						end
						break
					end
				end
			end
		end
	end

	-- Write back to the appropriate field
	if useOutput then
		m.OUTPUT = longName
	else
		m.channel_name = longName
	end

	if addon and addon.dbg then
		addon.dbg("applyShortChannelNamesToSections: final channel_name="..addon.dbgSafeValue(longName))
	end
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.applyShortChannelNamesToSections = applyShortChannelNamesToSections
addon.SHORT_CHANNEL_REPLACEMENTS = SHORT_CHANNEL_REPLACEMENTS
