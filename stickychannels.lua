--[[
	stickychannels.lua - Sticky channels list management for XanChat
	Improvements:
	- Reused common UI helpers from filter.lua (extracted to local)
	- Simplified frame setup
	- Better early returns
	- Reduced redundant code
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}
local L = addon.L
local chatTypeInfo = ChatTypeInfo

-- ============================================================================
-- SHARED UI HELPERS (same as filter.lua)
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

local function createDialogFrame(frameName, titleText)
	local frame = CreateFrame("frame", frameName, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:SetWidth(380)
	frame:SetHeight(570)

	frame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 32,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
	})
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

	local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", frame, -15, -8)

	local header = frame:CreateFontString("$parentHeaderText", "ARTWORK", "GameFontNormalSmall")
	header:SetJustifyH("LEFT")
	header:SetFontObject("GameFontNormal")
	header:SetPoint("CENTER", frame, "TOP", 0, -20)
	header:SetText(titleText)

	return frame
end

local function createScrollFrame(parent, yOffset)
	local scrollFrame = CreateFrame("ScrollFrame", parent:GetName().."_Scroll", parent, "UIPanelScrollFrameTemplate")
	local scrollChild = CreateFrame("frame", parent:GetName().."_ScrollChild", scrollFrame, BackdropTemplateMixin and "BackdropTemplate")
	scrollFrame:SetPoint("TOPLEFT", 10, yOffset)
	scrollFrame:SetPoint("BOTTOMRIGHT", -40, 70)
	scrollFrame:SetScrollChild(scrollChild)

	return scrollFrame, scrollChild
end

-- ============================================================================
-- STICKY CHANNELS FRAME
-- ============================================================================

addon.stickyChannelsList = createDialogFrame(ADDON_NAME.."_stickyChannelsList", L.EditStickyChannelsListHeader)

local scrollFrame, scrollFrame_Child = createScrollFrame(addon.stickyChannelsList, -50)

scrollFrame:Hide()
addon.stickyChannelsList:Hide()

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
-- SETUP AND LIST BUILDING
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
		barSlot:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
		barSlot:SetBackdropColor(0, 0, 0, 0)
		previousBar = barSlot

		barSlot.xData = entry

		local bar_chk = _G["xanChat_StickyChannelBarChk"..barCount] or CreateFrame("CheckButton", "xanChat_StickyChannelBarChk"..barCount, barSlot, "InterfaceOptionsCheckButtonTemplate")
		bar_chk.xData = entry
		bar_chk:SetPoint("LEFT", 4, 0)

		local checkedValue = XCHT_DB.stickyChannelsList[entry.name] == 1
		_G["xanChat_StickyChannelBarChk"..barCount.."Text"]:SetText("|cFFFFFFFF"..entry.name.."|r")
		bar_chk:SetChecked(checkedValue)
		bar_chk:SetEnabled(not isRestricted())

		bar_chk:SetScript("OnClick", function(self)
			if not guardRestricted() and self.xData and self.xData.name then
				local newVal = not self:GetChecked()
				XCHT_DB.stickyChannelsList[self.xData.name] = newVal and 1 or 0
				self:SetChecked(newVal)
				addon:UpdateStickyChannels()
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
