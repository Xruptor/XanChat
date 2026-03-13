--[[
	ChannelShortening.lua - Channel name shortening for XanChat
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

	if not (_G.XCHT_DB and _G.XCHT_DB.shortNames) or not m.channel_name or m.channel_name == "" then
		if addon and addon.dbg then
			addon.dbg("applyShortChannelNamesToSections: shortNames disabled or channel_name empty")
		end
		return
	end

	local longName = m.channel_name
	local shortName = longName -- Default to long name

	if addon and addon.dbg then
		addon.dbg("applyShortChannelNamesToSections: longName=" .. addon.dbgSafeValue(longName))
	end

	-- Shorten the channel name and remove zone suffix
	-- e.g., "General" -> "Gen" or "General - Orgrimmar" -> "Gen"
	for i = 1, #SHORT_CHANNEL_REPLACEMENTS do
		local Ln = SHORT_CHANNEL_REPLACEMENTS[i][1]
		local Sn = SHORT_CHANNEL_REPLACEMENTS[i][2]

		if Ln and Sn then
			-- Match with or without zone suffix, replace with just short name
			local withZone = "^" .. Ln .. " %-.+"
			local withoutZone = "^" .. Ln .. "$"
			shortName = gsub(shortName, withZone, Sn)
			shortName = gsub(shortName, withoutZone, Sn)
			if addon and addon.dbg then
				addon.dbg("applyShortChannelNamesToSections: matched Ln=" .. addon.dbgSafeValue(Ln) .. " shortName=" .. addon.dbgSafeValue(shortName))
			end
		end
	end

	m.channel_name = shortName
	if addon and addon.dbg then
		addon.dbg("applyShortChannelNamesToSections: final channel_name=" .. addon.dbgSafeValue(shortName))
	end
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.applyShortChannelNamesToSections = applyShortChannelNamesToSections
addon.SHORT_CHANNEL_REPLACEMENTS = SHORT_CHANNEL_REPLACEMENTS

