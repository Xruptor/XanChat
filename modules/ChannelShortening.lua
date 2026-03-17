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

	-- Try each replacement pattern
	for _, replacement in ipairs(SHORT_CHANNEL_REPLACEMENTS) do
		local longPattern, shortName = unpack(replacement)
		if longPattern and shortName then
			-- Match with or without zone suffix
			local withZone = "^"..longPattern.." %-.+"
			local withoutZone = "^"..longPattern.."$"

			-- Apply replacements using string.gsub
			longName = string.gsub(longName, withZone, shortName)
			longName = string.gsub(longName, withoutZone, shortName)
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
