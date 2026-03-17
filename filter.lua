--[[
	filter.lua - Filter list management for XanChat
	Refactored for:
	- Fixed path separator consistency
	- Simplified frame creation and setup
	- Consolidated redundant code
	- Better early returns
	- Improved scroll handling
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}
local L = addon.L
local strfind = string.find

-- ============================================================================
-- RESTRICTION HELPERS
-- ============================================================================

local function isRestricted()
	return addon.IsRestricted and addon:IsRestricted()
end

local function guardRestricted()
	if isRestricted() then
		if addon.NotifyConfigLocked then
			addon:NotifyConfigLocked()
		end
		return true
	end
	return false
end

-- ============================================================================
-- FRAME SETUP
-- ============================================================================

addon.filterList = CreateFrame("frame", ADDON_NAME.."_filterList", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local filterList = addon.filterList
filterList:SetFrameStrata("DIALOG")
filterList:SetToplevel(true)
filterList:EnableMouse(true)
filterList:SetMovable(true)
filterList:SetClampedToScreen(true)
filterList:SetWidth(380)
filterList:SetHeight(570)

filterList:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 32,
	insets = { left = 5, right = 5, top = 5, bottom = 5 }
})
filterList:SetBackdropColor(0, 0, 0, 1)
filterList:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

local closeButton = CreateFrame("Button", nil, filterList, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", filterList, -15, -8)

local header = filterList:CreateFontString("$parentHeaderText", "ARTWORK", "GameFontNormalSmall")
header:SetJustifyH("LEFT")
header:SetFontObject("GameFontNormal")
header:SetPoint("CENTER", filterList, "TOP", 0, -20)
header:SetText(L.EditFilterListHeader)

local scrollFrame = CreateFrame("ScrollFrame", ADDON_NAME.."_Scroll", filterList, "UIPanelScrollFrameTemplate")
local scrollFrame_Child = CreateFrame("frame", ADDON_NAME.."_ScrollChild", scrollFrame, BackdropTemplateMixin and "BackdropTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -50)
scrollFrame:SetPoint("BOTTOMRIGHT", -40, 70)
scrollFrame:SetScrollChild(scrollFrame_Child)

-- Hide both frames initially
scrollFrame:Hide()
filterList:Hide()

-- ============================================================================
-- FILTER DATA
-- ============================================================================

local CORE_FILTER_EVENTS = {
	CHAT_MSG_ACHIEVEMENT = true,
	CHAT_MSG_ADDON = true,
	CHAT_MSG_AFK = true,
	CHAT_MSG_BN_CONVERSATION = true,
	CHAT_MSG_BN_CONVERSATION_NOTICE = true,
	CHAT_MSG_BN_INLINE_TOAST_ALERT = true,
	CHAT_MSG_BN_INLINE_TOAST_BROADCAST = true,
	CHAT_MSG_BN_INLINE_TOAST_BROADCAST_INFORM = true,
	CHAT_MSG_BN_INLINE_TOAST_CONVERSATION = true,
	CHAT_MSG_BN_WHISPER = true,
	CHAT_MSG_BN_WHISPER_INFORM = true,
	CHAT_MSG_BN_WHISPER_PLAYER_OFFLINE = true,
	CHAT_MSG_CHANNEL = true,
	CHAT_MSG_CHANNEL_JOIN = true,
	CHAT_MSG_CHANNEL_LEAVE = true,
	CHAT_MSG_CHANNEL_LIST = true,
	CHAT_MSG_CHANNEL_NOTICE = true,
	CHAT_MSG_CHANNEL_NOTICE_USER = true,
	CHAT_MSG_COMBAT_FACTION_CHANGE = true,
	CHAT_MSG_COMBAT_HONOR_GAIN = true,
	CHAT_MSG_COMBAT_MISC_INFO = true,
	CHAT_MSG_COMBAT_XP_GAIN = true,
	CHAT_MSG_CURRENCY = true,
	CHAT_MSG_DND = true,
	CHAT_MSG_EMOTE = true,
	CHAT_MSG_GUILD = true,
	CHAT_MSG_IGNORED = true,
	CHAT_MSG_INSTANCE_CHAT = true,
	CHAT_MSG_LOOT = true,
	CHAT_MSG_MONEY = true,
	CHAT_MSG_MONSTER_EMOTE = true,
	CHAT_MSG_MONSTER_PARTY = true,
	CHAT_MSG_MONSTER_RAID = true,
	CHAT_MSG_MONSTER_SAY = true,
	CHAT_MSG_MONSTER_WHISPER = true,
	CHAT_MSG_MONSTER_YELL = true,
	CHAT_MSG_NOTICE = true,
	CHAT_MSG_OFFICER = true,
	CHAT_MSG_OPENING = true,
	CHAT_MSG_PARTY = true,
	CHAT_MSG_PARTY_LEADER = true,
	CHAT_MSG_PET_INFO = true,
	CHAT_MSG_RAID = true,
	CHAT_MSG_RAID_LEADER = true,
	CHAT_MSG_RAID_WARNING = true,
	CHAT_MSG_SAY = true,
	CHAT_MSG_SKILL = true,
	CHAT_MSG_SYSTEM = true,
	CHAT_MSG_TEXT_EMOTE = true,
	CHAT_MSG_TRADESKILLS = true,
	CHAT_MSG_WHISPER = true,
	CHAT_MSG_YELL = true,
	CHARACTER_POINTS_CHANGED = true,
	PARTY_LEADER_CHANGED = true,
	PLAYER_LEVEL_UP = true,
	PLAYER_ROLES_ASSIGNED = true,
	QUEST_TURNED_IN = true,
	READY_CHECK = true,
	READY_CHECK_FINISHED = true,
	TIME_PLAYED_MSG = true,
	UNIT_LEVEL = true,
}

local CUSTOM_FILTER_EVENTS = {
	_NOTICE = true,
	_EMOTE = true,
	ROLE_ = true,
	VOTE_KICK = true,
}

-- ============================================================================
-- SETUP HELPERS
-- ============================================================================

local function setupFilterUI()
	if not XCHT_DB.filterList then
		XCHT_DB.filterList = {}
	end

	-- Apply defaults for core events
	if addon.ApplyDefaults then
		addon.ApplyDefaults(XCHT_DB.filterList.core, CORE_FILTER_EVENTS)
		addon.ApplyDefaults(XCHT_DB.filterList.custom, CUSTOM_FILTER_EVENTS)
	else
		for k, v in pairs(CORE_FILTER_EVENTS) do
			if XCHT_DB.filterList.core[k] == nil then
				XCHT_DB.filterList.core[k] = v
			end
		end
		for k, v in pairs(CUSTOM_FILTER_EVENTS) do
			if XCHT_DB.filterList.custom[k] == nil then
				XCHT_DB.filterList.custom[k] = v
			end
		end
	end

	if not addon.filterList._xanHooked then
		addon.filterList:HookScript("OnShow", function()
			guardRestricted()
			if not addon.filterList.ListLoaded then
				addon:DoFilterList()
				addon.filterList.ListLoaded = true
			end
		end)
		addon.filterList._xanHooked = true
	end

	addon.isFilterListEnabled = true
end

-- ============================================================================
-- LIST BUILDING
-- ============================================================================

local function buildFilterList()
	scrollFrame_Child:SetPoint("TOPLEFT")
	scrollFrame_Child:SetWidth(scrollFrame:GetWidth())
	scrollFrame_Child:SetHeight(scrollFrame:GetHeight())

	local previousBar
	local buildList = {}

	-- Build list entries
	for k, v in pairs(XCHT_DB.filterList.core) do
		table.insert(buildList, { name=k, val=1 })
	end
	for k, v in pairs(XCHT_DB.filterList.custom) do
		table.insert(buildList, { name=k, val=2 })
	end

	-- Sort: core first (val=1), then custom (val=2), both by name
	table.sort(buildList, function(a, b)
		if a.val == b.val then
			return (a.name < b.name)
		else
			return (a.val < b.val)
		end
	end)

	-- Create list items
	for barCount = 1, #buildList do
		local entry = buildList[barCount]
		local isCore = entry.val == 1

		local barSlot = _G["xanChat_FilterListBar"..barCount] or CreateFrame("button", "xanChat_FilterListBar"..barCount, scrollFrame_Child, BackdropTemplateMixin and "BackdropTemplate")

		if barCount == 1 then
			barSlot:SetPoint("TOPLEFT", scrollFrame_Child, "TOPLEFT", 10, -10)
			barSlot:SetPoint("BOTTOMRIGHT", scrollFrame_Child, "TOPRIGHT", -10, -30)
		else
			barSlot:SetPoint("TOPLEFT", previousBar, "BOTTOMLEFT", 0, 0)
			barSlot:SetPoint("BOTTOMRIGHT", previousBar, "BOTTOMRIGHT", 0, -20)
		end

		barSlot:EnableMouse(true)
		barSlot:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
		})
		barSlot:SetBackdropColor(0, 0, 0, 0)
		previousBar = barSlot

		-- Store entry data on bar slot
		barSlot.xData = entry

		-- Create checkbox
		local bar_chk = _G["xanChat_FilterListBarChk"..barCount] or CreateFrame("CheckButton", "xanChat_FilterListBarChk"..barCount, barSlot, "InterfaceOptionsCheckButtonTemplate")
		bar_chk.xData = entry
		bar_chk:SetPoint("LEFT", 4, 0)

		-- Set checkbox state and text color
		local isChecked
		if isCore then
			isChecked = XCHT_DB.filterList.core[entry.name]
			_G["xanChat_FilterListBarChk"..barCount.."Text"]:SetText("|cFFFFFFFF"..entry.name.."|r")
		else
			isChecked = XCHT_DB.filterList.custom[entry.name]
			_G["xanChat_FilterListBarChk"..barCount.."Text"]:SetText("|cFF61F200"..entry.name.."|r")
		end
		bar_chk:SetChecked(isChecked)
		bar_chk:SetEnabled(not isRestricted())

		-- Set checkbox click handler
		bar_chk:SetScript("OnClick", function(self)
			if not guardRestricted() then
				if self.xData and self.xData.name then
					local isChecked = self:GetChecked()
					if isCore then
						XCHT_DB.filterList.core[self.xData.name] = isChecked
					else
						XCHT_DB.filterList.custom[self.xData.name] = isChecked
					end
					self:SetChecked(isChecked)
				end
			end
		end)

		-- Show items
		barSlot:Show()
		bar_chk:Show()
	end

	scrollFrame:Show()
end

-- ============================================================================
-- FILTER SEARCH
-- ============================================================================

function addon:searchFilterList(event, text)
	local filterList = XCHT_DB.filterList
	if not filterList then return false end
	if not event then return false end

	if addon.DebugPrint then
		local textDump = addon.dbgSafeValue and addon.dbgSafeValue(text) or (addon.DebugValue and addon.DebugValue(text) or "<text>")
		addon.DebugPrint("searchFilterList: event="..tostring(event).." text="..textDump)
	end

	-- Check core events first
	if filterList.core[event] then
		if addon.DebugPrint then addon.DebugPrint("searchFilterList: core match") end
		return true
	end

	-- Check custom events via substring matching
	for k, v in pairs(filterList.custom) do
		if v and strfind(event, k, 1, true) then
			if addon.DebugPrint then addon.DebugPrint("searchFilterList: custom match key="..tostring(k)) end
			return true
		end
	end

	if addon.DebugPrint then addon.DebugPrint("searchFilterList: no match") end
	return false
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function addon:EnableFilterList()
	setupFilterUI()
end

function addon:DoFilterList()
	buildFilterList()
end
