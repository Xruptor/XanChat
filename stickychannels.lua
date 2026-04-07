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
-- FRAME SETUP
-- ============================================================================

local isRestricted = function() return addon.isRestricted() end
local guardRestricted = function() return addon.guardRestricted() end
local createDialogFrame = function(...) return addon.createDialogFrame(...) end
local createScrollFrame = function(...) return addon.createScrollFrame(...) end

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
