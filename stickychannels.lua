local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent)
end
addon = _G[ADDON_NAME]

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

addon.stickyChannelsList = CreateFrame("frame", ADDON_NAME.."_stickyChannelsList", UIParent)

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

stickyChannelsList:SetBackdropColor(0,0,0,1)
stickyChannelsList:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

local closeButton = CreateFrame("Button", nil, stickyChannelsList, "UIPanelCloseButton");
closeButton:SetPoint("TOPRIGHT", stickyChannelsList, -15, -8);

local header = stickyChannelsList:CreateFontString("$parentHeaderText", "ARTWORK", "GameFontNormalSmall")
header:SetJustifyH("LEFT")
header:SetFontObject("GameFontNormal")
header:SetPoint("CENTER", stickyChannelsList, "TOP", 0, -20)
header:SetText(L.EditStickyChannelsListHeader)

local scrollFrame = CreateFrame("ScrollFrame", ADDON_NAME.."_Scroll", stickyChannelsList, "UIPanelScrollFrameTemplate")
local scrollFrame_Child = CreateFrame("frame", ADDON_NAME.."_ScrollChild", scrollFrame)
scrollFrame:SetPoint("TOPLEFT", 10, -50) 
--scrollbar on the right (x shifts the slider left or right)
scrollFrame:SetPoint("BOTTOMRIGHT", -40, 70) 
scrollFrame:SetScrollChild(scrollFrame_Child)

--hide both frames
scrollFrame:Hide()
stickyChannelsList:Hide()

local StickyTypeChannels = {
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

function addon:EnableStickyChannelsList()

	if not XCHT_DB.stickyChannelsList then XCHT_DB.stickyChannelsList = {} end

	--update the list in case anything was added in future updates
	for k, v in pairs(StickyTypeChannels) do
		if k and XCHT_DB.stickyChannelsList[k] == nil then
			XCHT_DB.stickyChannelsList[k] = 1 --enable it by default, so all will be sticky
		end
	end
	
	addon.stickyChannelsList:HookScript("OnShow", function(self)
		if not addon.stickyChannelsList.ListLoaded then
			--populate scroll list
			addon:DoStickyChannelsList()
			addon.stickyChannelsList.ListLoaded = true
		end
	end)
	
	addon:UpdateStickyChannels()
end

function addon:DoStickyChannelsList()
	scrollFrame_Child:SetPoint("TOPLEFT")
	scrollFrame_Child:SetWidth(scrollFrame:GetWidth())
	scrollFrame_Child:SetHeight(scrollFrame:GetHeight())
	
	local previousBar
	local buildList = {}
	
	for k, v in pairs(XCHT_DB.stickyChannelsList) do
		table.insert(buildList, { name=k, val=v } )
	end

	--sort it
	table.sort(buildList, function(a,b)
		return (a.name < b.name) 
	end)
	
	for barCount=1, table.getn(buildList) do
		
		local barSlot = _G["xanChat_StickyChannelBar"..barCount] or CreateFrame("button", "xanChat_StickyChannelBar"..barCount, scrollFrame_Child)
		
		if barCount==1 then
			barSlot:SetPoint("TOPLEFT",scrollFrame_Child, "TOPLEFT", 10, -10)
			barSlot:SetPoint("BOTTOMRIGHT",scrollFrame_Child, "TOPRIGHT", -10, -30)
		else
			barSlot:SetPoint("TOPLEFT", previousBar, "BOTTOMLEFT", 0, 0)
			barSlot:SetPoint("BOTTOMRIGHT", previousBar, "BOTTOMRIGHT", 0, -20)
		end

		barSlot:EnableMouse(true)
		barSlot:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
		})
        barSlot:SetBackdropColor(0,0,0,0)

		--store previous bar to position correctly for next one ;)
		previousBar = barSlot

		--store the data
		barSlot.xData = buildList[barCount]
		
		--check button stuff
		local bar_chk = _G["xanChat_StickyChannelBarChk"..barCount] or CreateFrame("CheckButton", "xanChat_StickyChannelBarChk"..barCount, barSlot, "OptionsCheckButtonTemplate")
		bar_chk.xData = buildList[barCount]
        bar_chk:SetPoint("LEFT", 4, 0)
		
		_G["xanChat_StickyChannelBarChk"..barCount.."Text"]:SetText("|cFFFFFFFF"..buildList[barCount].name.."|r")
		
		--set if checked or not
		if XCHT_DB.stickyChannelsList[buildList[barCount].name] == 1 then
			bar_chk:SetChecked(true)
		else
			bar_chk:SetChecked(false)
		end
		_G["xanChat_StickyChannelBarChk"..barCount.."Text"]:SetFontObject("GameFontNormal")
        
		bar_chk:SetScript("OnClick", function(self)
			local checked = self:GetChecked()

			--update the DB
			if self.xData and self.xData.name then
				if checked then
					XCHT_DB.stickyChannelsList[self.xData.name] = 1
				else
					XCHT_DB.stickyChannelsList[self.xData.name] = 0
				end
			end
			addon:UpdateStickyChannels()
		end)
		
		--show them if hidden
		barSlot:Show()
		bar_chk:Show()
	end

	--show the scroll frame
	scrollFrame:Show()
end

function addon:UpdateStickyChannels()
	for k, v in pairs(XCHT_DB.stickyChannelsList) do
		ChatTypeInfo[k].sticky = v
	end
end
