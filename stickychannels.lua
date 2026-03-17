--[[
	stickychannels.lua - Sticky channels list management for XanChat
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
local chatTypeInfo = ChatTypeInfo

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

addon.stickyChannelsList = CreateFrame("frame", ADDON_NAME.."_stickyChannelsList", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local stickyChannelsList = addon.stickyChannelsList
stickyChannelsList:SetFrameStrata("DIALOG")
stickyChannelsList:SetToplevel(true)
stickyChannelsList:EnableMouse(true)
stickyChannelsList:SetMovable(true)
stickyChannelsList:SetClampedToScreen(true)
stickyChannelsList:SetWidth(380)
stickyChannelsList:SetHeight(570)

stickyChannelsList:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 32,
	insets = { left = 5, right = 5, top = 5, bottom = 5 }
})
stickyChannelsList:SetBackdropColor(0, 0, 0, 1)
stickyChannelsList:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

local closeButton = CreateFrame("Button", nil, stickyChannelsList, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", stickyChannelsList, -15, -8)

local header = stickyChannelsList:CreateFontString("$parentHeaderText", "ARTWORK", "GameFontNormalSmall")
header:SetJustifyH("LEFT")
header:SetFontObject("GameFontNormal")
header:SetPoint("CENTER", stickyChannelsList, "TOP", 0, -20)
header:SetText(L.EditStickyChannelsListHeader)

local scrollFrame = CreateFrame("ScrollFrame", ADDON_NAME.."_Scroll", stickyChannelsList, "UIPanelScrollFrameTemplate")
local scrollFrame_Child = CreateFrame("frame", ADDON_NAME.."_ScrollChild", scrollFrame, BackdropTemplateMixin and "BackdropTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -50)
scrollFrame:SetPoint("BOTTOMRIGHT", -40, 70)
scrollFrame:SetScrollChild(scrollFrame_Child)

scrollFrame:Hide()
stickyChannelsList:Hide()

-- ============================================================================
-- CHANNEL DATA
-- ============================================================================

local STICKY_TYPE_CHANNELS = {
	SAY = 1,
	YELL = 0,
	EMOTE = 0,
	PARTY = 1,
	RAID = 1,
	GUILD = 1,
	OFFICER = 1,
	WHISPER = 1,
	CHANNEL = 1,
}

-- ============================================================================
-- SETUP HELPERS
-- ============================================================================

local function setupStickyChannelsUI()
	if not XCHT_DB.stickyChannelsList then
		XCHT_DB.stickyChannelsList = {}
	end

	if addon.ApplyDefaults then
		addon.ApplyDefaults(XCHT_DB.stickyChannelsList, STICKY_TYPE_CHANNELS)
	else
		for k, v in pairs(STICKY_TYPE_CHANNELS) do
			if XCHT_DB.stickyChannelsList[k] == nil then
				XCHT_DB.stickyChannelsList[k] = v
			end
		end
	end

	if not addon.stickyChannelsList._xanHooked then
		addon.stickyChannelsList:HookScript("OnShow", function()
			guardRestricted()
			if not addon.stickyChannelsList.ListLoaded then
				addon:DoStickyChannelsList()
				addon.stickyChannelsList.ListLoaded = true
			end
		end)
		addon.stickyChannelsList._xanHooked = true
	end
end

-- ============================================================================
-- LIST BUILDING
-- ============================================================================

local function buildStickyChannelsList()
	scrollFrame_Child:SetPoint("TOPLEFT")
	scrollFrame_Child:SetWidth(scrollFrame:GetWidth())
	scrollFrame_Child:SetHeight(scrollFrame:GetHeight())

	local previousBar
	local buildList = {}

	for k, v in pairs(XCHT_DB.stickyChannelsList) do
		table.insert(buildList, { name=k, val=v })
	end

	table.sort(buildList, function(a, b)
		return a.name < b.name
	end)

	for barCount = 1, #buildList do
		local entry = buildList[barCount]

		local barSlot = _G["xanChat_StickyChannelBar"..barCount] or CreateFrame("button", "xanChat_StickyChannelBar"..barCount, scrollFrame_Child, BackdropTemplateMixin and "BackdropTemplate")

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

		barSlot.xData = entry

		local bar_chk = _G["xanChat_StickyChannelBarChk"..barCount] or CreateFrame("CheckButton", "xanChat_StickyChannelBarChk"..barCount, barSlot, "InterfaceOptionsCheckButtonTemplate")
		bar_chk.xData = entry
		bar_chk:SetPoint("LEFT", 4, 0)

		local isChecked = XCHT_DB.stickyChannelsList[entry.name] == 1
		_G["xanChat_StickyChannelBarChk"..barCount.."Text"]:SetText("|cFFFFFFFF"..entry.name.."|r")
		bar_chk:SetChecked(isChecked)
		bar_chk:SetEnabled(not isRestricted())

		bar_chk:SetScript("OnClick", function(self)
			if not guardRestricted() then
				if self.xData and self.xData.name then
					local newVal = not self:GetChecked()
					XCHT_DB.stickyChannelsList[self.xData.name] = newVal and 1 or 0
					self:SetChecked(newVal)
					addon:UpdateStickyChannels()
				end
			end
		end)

		barSlot:Show()
		bar_chk:Show()
	end

	scrollFrame:Show()
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function addon:EnableStickyChannelsList()
	setupStickyChannelsUI()
end

function addon:DoStickyChannelsList()
	buildStickyChannelsList()
end

function addon:UpdateStickyChannels()
	if not chatTypeInfo or not XCHT_DB.stickyChannelsList then return end
	for k, v in pairs(XCHT_DB.stickyChannelsList) do
		if chatTypeInfo[k] then
			chatTypeInfo[k].sticky = v and 1 or 0
		end
	end
end
