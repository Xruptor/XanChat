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

local SHORT_CHANNEL_REPLACEMENTS = {}

local function applyShortChannelNamesToSections(m)
	if not addon then return end

	if not (_G.XCHT_DB and _G.XCHT_DB.shortNames) or not m.channel_name or m.channel_name == "" then
		return
	end

	local longName = m.channel_name
	local shortName = longName -- Default to long name
	for i = 1, #SHORT_CHANNEL_REPLACEMENTS do
		if SHORT_CHANNEL_REPLACEMENTS[i][1] == longName then
			shortName = SHORT_CHANNEL_REPLACEMENTS[i][2]
			break
		end
	end

    m.channel_name = shortName
end

local function initChannelShortening()
	if not addon then return end

	SHORT_CHANNEL_REPLACEMENTS = {
		{ addon.L.ChannelGeneral or "General", addon.L.ShortGeneral or "Gen" },
		{ addon.L.ChannelTradeServices or "Trade - Services", addon.L.ShortTradeServices or "Trade-S" },
		{ addon.L.ChannelTrade or "Trade", addon.L.ShortTrade or "Trade" },
		{ addon.L.ChannelWorldDefense or "WorldDefense", addon.L.ShortWorldDefense or "WDef" },
		{ addon.L.ChannelLocalDefense or "LocalDefense", addon.L.ShortLocalDefense or "LDef" },
		{ addon.L.ChannelLookingForGroup or "LookingForGroup", addon.L.ShortLookingForGroup or "LFG" },
		{ addon.L.ChannelGuildRecruitment or "GuildRecruitment", addon.L.ShortGuildRecruitment or "Guild" },
		{ addon.L.ChannelNewComerChat or "NewComers", addon.L.ShortNewComerChat or "New" },
	}
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.applyShortChannelNamesToSections = applyShortChannelNamesToSections
addon.initChannelShortening = initChannelShortening

