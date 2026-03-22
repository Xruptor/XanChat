--[[
	ChannelShortening.lua - Channel name shortening and channel extraction for XanChat
	Improvements:
	- Removed duplicate comment header
	- Consolidated channel name extraction logic
	- Simplified lookupShortChannelName with early exit
	- Improved applyShortChannelNamesToSections flow
	- Better channel number extraction
	- Reduced redundant gsub calls
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- CHANNEL NAME SHORTENING
-- ============================================================================

local SHORT_CHANNEL_REPLACEMENTS = {
	-- Simple word replacements
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
	-- Blizzard hyperlink format patterns
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
local function extractChannelNumberFromString(str)
	if not str or type(str) ~= "string" then return nil end

	return str:match("|Hchannel:(%d+)|h") or
	       str:match("|Hchannel:CHANNEL:(%d+)|h") or
	       str:match("|Hchannel:channel:(%d+)|h") or
	       str:match("^%[(%d+)%..*%]") or
	       str:match("%[(%d+)%s")
end

-- Helper function to extract channel name from bracketed content
local function extractChannelNameFromString(str, channelNum)
	if not str or type(str) ~= "string" or not channelNum then return "" end

	-- Try to extract from hyperlink bracketed content
	local bracketMatch = str:match("|Hchannel:"..channelNum.."|h%[([^%]]*)%]")
	if bracketMatch then
		local name = bracketMatch:gsub("^"..channelNum.."[%. ]*", ""):gsub("%s*%-.*$", "")
		if name and name ~= "" then
			return name:gsub("^%s+", ""):gsub("%s+$", "")
		end
	end

	-- Fallback: locale-aware patterns
	local localePatterns = {
		{ addon.L.ChannelPatternShortGeneral or "general", "General" },
		{ addon.L.ChannelPatternShortTrade or "trade", "Trade" },
		{ addon.L.ChannelPatternShortWorldDefense or "worlddefense", "WorldDefense" },
		{ addon.L.ChannelPatternShortLocalDefense or "localdefense", "LocalDefense" },
		{ addon.L.ChannelPatternShortLookingForGroup or "lookingforgroup", "LookingForGroup" },
		{ addon.L.ChannelPatternShortGuildRecruitment or "guildrecruitment", "GuildRecruitment" },
		{ addon.L.ChannelPatternShortNewcomerChat or "newcomer", "Newcomer" },
	}

	local lowerStr = str:lower():gsub("[%s%-]", "")

	for _, patternPair in ipairs(localePatterns) do
		local searchPattern, properName = unpack(patternPair)
		local cleanedPattern = searchPattern:gsub("[%s%-]", "")
		if cleanedPattern ~= "" and #cleanedPattern >= 4 and lowerStr:find(cleanedPattern, 1, true) then
			return properName
		end
	end

	return ""
end

-- ============================================================================
-- UNIFIED CHANNEL EXTRACTION
-- ============================================================================

-- Unified function to extract channel info from multiple sources
local function extractChannelInfoFromSources(m, sources)
	if not m then return false end

	local extractedNum = m.channel_number or ""
	local extractedName = m.channel_name or ""

	for _, source in ipairs(sources) do
		if not source or source == "" then
			-- continue
		else
			local sourceType = addon.SafeType and addon.SafeType(source) or type(source)

			if extractedNum and extractedNum ~= "" then
				if sourceType == "string" then
					local nameFromSource = extractChannelNameFromString(source, extractedNum)
					if nameFromSource and nameFromSource ~= "" then
						extractedName = nameFromSource
						break
					end
				end
			else
				if sourceType == "number" then
					extractedNum = tostring(source)
				elseif sourceType == "string" then
					local numFromSource = extractChannelNumberFromString(source)
					if numFromSource and numFromSource ~= "" then
						extractedNum = numFromSource
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

	if extractedNum and extractedNum ~= "" and (not m.channel_number or m.channel_number == "") then
		m.channel_number = extractedNum
	end
	if extractedName and extractedName ~= "" and (not m.channel_name or m.channel_name == "") then
		m.channel_name = extractedName
	end

	return extractedNum and extractedNum ~= "" or extractedName and extractedName ~= ""
end

-- Unified function to handle deferred channel extraction from OUTPUT
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
			addon.dbg("extracted channel number from OUTPUT="..tostring(numFromOutput))
			return true
		end
	end

	return false
end

-- ============================================================================
-- LEGACY CHANNEL INFO EXTRACTION
-- ============================================================================

-- Extract channel information into section
local function extractChannelInfo(s, arg7, arg8, arg9, arg10, chatGroup)
	if not s then return end

	s.deferredChannelExtraction = nil

	if chatGroup == "BN_CONVERSATION" then
		local bnChannelNum = tonumber(arg8) or 0
		s.channel_number = tostring((_G.MAX_WOW_CHAT_CHANNELS or 20) + bnChannelNum)
		if _G.CHAT_BN_CONVERSATION_SEND then
			s.channel_name = string.match(_G.CHAT_BN_CONVERSATION_SEND or "", "%d%.%s+(.+)")
		end
		return
	end

	local sources = {}
	if arg8 then table.insert(sources, arg8) end
	if arg7 then table.insert(sources, arg7) end
	if arg9 then table.insert(sources, arg9) end
	if arg10 then table.insert(sources, arg10) end

	local found = extractChannelInfoFromSources(s, sources)

	if chatGroup == "CHANNEL" and (not s.channel_number or s.channel_number == "" or not s.channel_name or s.channel_name == "") then
		s.deferredChannelExtraction = true
	elseif not found then
		s.channel_number = ""
		s.channel_name = ""
	end
end

-- ============================================================================
-- CHANNEL NAME SHORTENING FUNCTIONS
-- ============================================================================

--- Helper function to look up the short name for a channel
local function lookupShortChannelName(fullName)
	if not fullName or fullName == "" then return nil end

	local normalizedName = fullName:lower():gsub("[%s%-]", "")

	for _, replacement in ipairs(SHORT_CHANNEL_REPLACEMENTS) do
		local longPattern, shortName = unpack(replacement)
		if longPattern and shortName then
			local patternMatched

			if longPattern:find("%[") then
				patternMatched = (normalizedName:match("^" .. longPattern .. "$") ~= nil)
			else
				patternMatched = (longPattern:lower() == normalizedName)
			end

			if patternMatched then
				return shortName
			end
		end
	end

	return nil
end

local function applyShortChannelNamesToSections(m)
	if not addon then return end

	if not (_G.XCHT_DB and _G.XCHT_DB.shortNames) then
		if addon and addon.dbg then
			addon.dbg("applyShortChannelNamesToSections: shortNames disabled")
		end
		return
	end

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
	if (not m.channel_number or m.channel_number == "") and type(longName) == "string" then
		m.channel_number = extractChannelNumberFromString(longName)
	end

	-- Extract the short channel name
	if m.channel_number and type(longName) == "string" then
		m.channel_name = extractChannelNameFromString(longName, m.channel_number)
	end

	local channelNum = m.channel_number

	if addon and addon.dbg then
		addon.dbg("applyShortChannelNamesToSections: extracted channelNum="..tostring(channelNum).." channel_name="..tostring(string.sub(m.channel_name or "", 1, 30)))
	end

	-- Try to find and replace the channel bracket with shortened version
	if channelNum then
		local bracketContent = longName:match("|Hchannel:%d+|h%["..channelNum.."%. [^%]]+%]|h") or
		                          longName:match("%["..channelNum.."%. [^%]]+%]")

		local shortName = lookupShortChannelName(m.channel_name or "")
		if shortName then
			m.channel_name = shortName
		end

		if bracketContent and shortName then
			local shortenedBracket = "["..channelNum.."] ["..shortName.."]"

			if bracketContent:find("|Hchannel:") then
				longName = longName:gsub("|Hchannel:"..channelNum.."|h%[([^%]]+)%]|h", "|Hchannel:"..channelNum.."|h["..channelNum.."] ["..shortName.."]|h", 1)
			else
				local innerBracket = bracketContent:match("%[([^%]]+)%]") or bracketContent
				local escapedBracket = innerBracket:gsub("[%(%)%.%*%+%?%[%]%^%$%-]", "%%%0")
				longName = string.gsub(longName, "%["..escapedBracket.."%]", shortenedBracket, 1)
			end

			if addon and addon.dbg then
				addon.dbg("applyShortChannelNamesToSections: replaced bracket with '"..shortName.."'")
			end
		end
	end

	m.OUTPUT = longName

	if m.channel_name and m.channel_name ~= "" then
		local shortName = lookupShortChannelName(m.channel_name)
		if shortName then
			m.channel_name = shortName
			if addon and addon.dbg then
				addon.dbg("applyShortChannelNamesToSections: fallback lookup mapped to '"..shortName.."'")
			end
		end
	end
end

-- Look up short channel name from message section during lockdown
local function getShortChannelPatternOnLockdown(m, channelNum)
	if not m or not channelNum then return "" end

	local channelName = m.channel_name or ""

	if (not channelName or channelName == "") and m.OUTPUT and addon.SafeType and addon.SafeType(m.OUTPUT) == "string" then
		channelName = extractChannelNameFromString(m.OUTPUT, channelNum) or ""
		if channelName and channelName ~= "" then
			m.channel_name = channelName
			if addon and addon.dbg then
				addon.dbg("getShortChannelPatternOnLockdown: extracted channel name from OUTPUT during lockdown - "..tostring(channelName))
			end
		end
	end

	if not channelName or channelName == "" then return "" end

	local shortName = lookupShortChannelName(channelName)
	if shortName then
		if addon and addon.dbg then
			addon.dbg("getShortChannelPatternOnLockdown: '"..channelName.."' -> '"..shortName.."'")
		end
		return shortName
	end

	if addon and addon.dbg then
		addon.dbg("getShortChannelPatternOnLockdown: no match for '"..channelName.."', returning original")
	end
	return channelName
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
addon.getShortChannelPatternOnLockdown = getShortChannelPatternOnLockdown
