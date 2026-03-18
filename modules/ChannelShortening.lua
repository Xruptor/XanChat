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
	{ addon.L.ChannelPatternGeneral or "(%[%d+%. ]*General[%s%-].-])", addon.L.ShortGeneral or "Gen" },
	{ addon.L.ChannelPatternTrade or "(%[%d+%. ]*Trade[%s%-].-])", addon.L.ShortTrade or "Trade" },
	{ addon.L.ChannelPatternWorldDefense or "(%[%d+%. ]*WorldDefense[%s%-].-])", addon.L.ShortWorldDefense or "WDef" },
	{ addon.L.ChannelPatternLocalDefense or "(%[%d+%. ]*LocalDefense[%s%-].-])", addon.L.ShortLocalDefense or "LDef" },
	{ addon.L.ChannelPatternLookingForGroup or "(%[%d+%. ]*LookingForGroup[%s%-].-])", addon.L.ShortLookingForGroup or "LFG" },
	{ addon.L.ChannelPatternGuildRecruitment or "(%[%d+%. ]*GuildRecruitment[%s%-].-])", addon.L.ShortGuildRecruitment or "Guild" },
	{ addon.L.ChannelPatternNewcomerChat or "(%[%d+%. ]*Newcomer Chat[%s%-].-])", addon.L.ShortNewComerChat or "New" },
}

local function applyShortChannelNamesToSections(m)
	if not addon then return end

	-- Early return if short names disabled or no channel name
	if not (_G.XCHT_DB and _G.XCHT_DB.shortNames) or not m.channel_name or m.channel_name == "" then
		if addon and addon.dbg then
			addon.dbg("applyShortChannelNamesToSections: shortNames disabled or channel_name empty")
		end
		return
	end

	local longName = m.channel_name
	local originalName = longName

	-- Helper function to strip whitespace
	local function stripWhitespace(s)
		return string.gsub(s, "%s+", "")
	end

	-- Helper function to check if pattern is a simple word match (not a regex pattern)
	local function isSimpleWordPattern(pattern)
		return not pattern:find("[%(%)%.%*%+%?%[%]%^%$]") and
		       not pattern:find("[%-%]")
	end

	-- Try each replacement pattern
	for _, replacement in ipairs(SHORT_CHANNEL_REPLACEMENTS) do
		local longPattern, shortName = unpack(replacement)
		if longPattern and shortName then
			-- Apply replacement directly using the locale pattern
			-- The locale pattern already handles the full channel name with/without zone suffix
			longName = string.gsub(longName, longPattern, shortName)
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
					longName = string.gsub(originalName, longPattern, shortName)
					if addon and addon.dbg then
						addon.dbg("applyShortChannelNamesToSections: matched via whitespace fallback for pattern: "..tostring(longPattern))
					end
					break
				end
			end
		end
	end

	-- Fallback 2: Extract channel name from brackets and compare against patterns
	if longName == originalName then
		local bracketMatch = originalName:match("%[([^%]]+)%]")
		if bracketMatch then
			local extractedName = bracketMatch:gsub("^%d+%.?%s*", ""):gsub("[%s%-].*", ""):lower()
			local bracketName = originalName:match("%[([^%]]+)%]")

			for _, replacement in ipairs(SHORT_CHANNEL_REPLACEMENTS) do
				local longPattern, shortName = unpack(replacement)
				if longPattern and shortName and isSimpleWordPattern(longPattern) then
					local patternName = longPattern:gsub("[%[%]]", ""):gsub("%^", ""):lower()
					if patternName ~= "" and extractedName:find(patternName, 1, true) then
						-- Replace the entire bracketed section with short name
						longName = string.gsub(originalName, bracketName, shortName)
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
					-- Found a partial match, replace it
					longName = string.gsub(originalName, longPattern, shortName)
					if addon and addon.dbg then
						addon.dbg("applyShortChannelNamesToSections: matched via partial word fallback for pattern: "..tostring(longPattern))
					end
					break
				end
			end
		end
	end

	m.channel_name = longName
	if addon and addon.dbg then
		addon.dbg("applyShortChannelNamesToSections: final channel_name="..addon.dbgSafeValue(longName))
	end
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.applyShortChannelNamesToSections = applyShortChannelNamesToSections
addon.SHORT_CHANNEL_REPLACEMENTS = SHORT_CHANNEL_REPLACEMENTS
