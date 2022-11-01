local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

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

filterList:SetBackdropColor(0,0,0,1)
filterList:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

local closeButton = CreateFrame("Button", nil, filterList, "UIPanelCloseButton");
closeButton:SetPoint("TOPRIGHT", filterList, -15, -8);

local header = filterList:CreateFontString("$parentHeaderText", "ARTWORK", "GameFontNormalSmall")
header:SetJustifyH("LEFT")
header:SetFontObject("GameFontNormal")
header:SetPoint("CENTER", filterList, "TOP", 0, -20)
header:SetText(L.EditFilterListHeader)

local scrollFrame = CreateFrame("ScrollFrame", ADDON_NAME.."_Scroll", filterList, "UIPanelScrollFrameTemplate")
local scrollFrame_Child = CreateFrame("frame", ADDON_NAME.."_ScrollChild", scrollFrame, BackdropTemplateMixin and "BackdropTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -50) 
--scrollbar on the right (x shifts the slider left or right)
scrollFrame:SetPoint("BOTTOMRIGHT", -40, 70) 
scrollFrame:SetScrollChild(scrollFrame_Child)

--hide both frames
scrollFrame:Hide()
filterList:Hide()

--https://raw.githubusercontent.com/Gethe/wow-ui-source/356d028f9d245f6e75dc8a806deb3c38aa0aa77f/FrameXML/ChatFrame.lua
--https://github.com/Gethe/wow-ui-source/blob/356d028f9d245f6e75dc8a806deb3c38aa0aa77f/AddOns/Blizzard_APIDocumentation/PartyInfoDocumentation.lua

--https://wowwiki.fandom.com/wiki/Events_A-Z_(full_list)

local coreList = {
	["CHAT_MSG_SYSTEM"] = true,
	["TIME_PLAYED_MSG"] = true,
	["PLAYER_LEVEL_UP"] = true,
	["UNIT_LEVEL"] = true,
	["CHARACTER_POINTS_CHANGED"] = true,
	["CHAT_MSG_BN_WHISPER_PLAYER_OFFLINE"] = true,
	["QUEST_TURNED_IN"] = true,
	["CHAT_MSG_EMOTE"] = true,
	["CHAT_MSG_TEXT_EMOTE"] = true,
	["CHAT_MSG_SKILL"] = true,
	["CHAT_MSG_CURRENCY"] = true,
	["CHAT_MSG_MONEY"] = true,
	["CHAT_MSG_WHISPER"] = true,
	["CHAT_MSG_BN_WHISPER_INFORM"] = true,
	["CHAT_MSG_OPENING"] = true,
	["CHAT_MSG_TRADESKILLS"] = true,
	["CHAT_MSG_PET_INFO"] = true,
	["CHAT_MSG_LOOT"] = true,
	["CHAT_MSG_NOTICE"] = true,
	["PARTY_LEADER_CHANGED"] = true,
	["PLAYER_ROLES_ASSIGNED"] = true,
	["READY_CHECK"] = true,
	["READY_CHECK_FINISHED"] = true,
}

local customList = {
	["_NOTICE"] = true,
	["_EMOTE"] = true,
	["ROLE_"] = true,
	["VOTE_KICK"] = true,
}

function addon:EnableFilterList()

	if not XCHT_DB.filterList then XCHT_DB.filterList = {} end
	if not XCHT_DB.filterList.core then XCHT_DB.filterList.core = coreList end
	if not XCHT_DB.filterList.custom then XCHT_DB.filterList.custom = customList end
	
	--update the list in case anything was added in future updates
	for k, v in pairs(coreList) do
		if k and XCHT_DB.filterList.core[k] == nil then
			XCHT_DB.filterList.core[k] = v
		end
	end
	for k, v in pairs(customList) do
		if k and XCHT_DB.filterList.custom[k] == nil then
			XCHT_DB.filterList.custom[k] = v
		end
	end
	
	addon.filterList:HookScript("OnShow", function(self)
		if not addon.filterList.ListLoaded then
			--populate scroll list
			addon:DoFilterList()
			addon.filterList.ListLoaded = true
		end
	end)
	
	--allow the stylized routines to work
	addon.isFilterListEnabled = true
end

function addon:DoFilterList()
	scrollFrame_Child:SetPoint("TOPLEFT")
	scrollFrame_Child:SetWidth(scrollFrame:GetWidth())
	scrollFrame_Child:SetHeight(scrollFrame:GetHeight())
	
	local previousBar
	local buildList = {}
	
	--core list
	for k, v in pairs(XCHT_DB.filterList.core) do
		table.insert(buildList, { name=k, val=1 } )
	end
	--custom list
	for k, v in pairs(XCHT_DB.filterList.custom) do
		table.insert(buildList, { name=k, val=2 } )
	end

	--sort it based on where the list is coming from
	table.sort(buildList, function(a,b)
		if a.val == b.val then
			return (a.name < b.name) 
		else
			return (a.val < b.val)
		end
	end)
	
	for barCount=1, table.getn(buildList) do
		
		local barSlot = _G["xanChat_FilterListBar"..barCount] or CreateFrame("button", "xanChat_FilterListBar"..barCount, scrollFrame_Child, BackdropTemplateMixin and "BackdropTemplate")
		
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
		local bar_chk = _G["xanChat_FilterListBarChk"..barCount] or CreateFrame("CheckButton", "xanChat_FilterListBarChk"..barCount, barSlot, "InterfaceOptionsCheckButtonTemplate")
		bar_chk.xData = buildList[barCount]
        bar_chk:SetPoint("LEFT", 4, 0)
		
		--change text color depending on where the entry came from
		if buildList[barCount].val == 1 then
			--core list
			_G["xanChat_FilterListBarChk"..barCount.."Text"]:SetText("|cFFFFFFFF"..buildList[barCount].name.."|r")
			
			--set if checked or not
			if XCHT_DB.filterList.core[buildList[barCount].name] then
				bar_chk:SetChecked(true)
			else
				bar_chk:SetChecked(false)
			end
		else
			--custom list
			_G["xanChat_FilterListBarChk"..barCount.."Text"]:SetText("|cFF61F200"..buildList[barCount].name.."|r")
			
			--set if checked or not
			if XCHT_DB.filterList.custom[buildList[barCount].name] then
				bar_chk:SetChecked(true)
			else
				bar_chk:SetChecked(false)
			end
		end
		_G["xanChat_FilterListBarChk"..barCount.."Text"]:SetFontObject("GameFontNormal")
        
		bar_chk:SetScript("OnClick", function(self)
			local checked = self:GetChecked()

			--update the DB
			if self.xData and self.xData.name then
				--core list
				if self.xData.val == 1 then
					XCHT_DB.filterList.core[self.xData.name] = checked
				--custom list
				else
					XCHT_DB.filterList.custom[self.xData.name] = checked
				end
			end
			
		end)
		
		--show them if hidden
		barSlot:Show()
		bar_chk:Show()
	end

	--show the scroll frame
	scrollFrame:Show()
end

function addon:searchFilterList(event, text)
	if not XCHT_DB.filterList then return false end
	if not event then return false end
	
	--first lets check the core
	if XCHT_DB.filterList.core[event] then return true end

	--if not lets check custom
	for k, v in pairs(XCHT_DB.filterList.custom) do
		--if it's enabled then check the string
		if v and string.find(event, k, 1, true) then
			return true
		end
	end

	return false
end
