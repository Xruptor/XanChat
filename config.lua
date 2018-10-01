local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then _G[ADDON_NAME] = addon end

addon.configEvent = CreateFrame("frame", ADDON_NAME.."_config_eventFrame",UIParent)
local configEvent = addon.configEvent
configEvent:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

local L = LibStub("AceLocale-3.0"):GetLocale("xanChat")
local chkBoxIndex = 1

function createCheckbutton(parentFrame, displayText, dbObjectValue)
	chkBoxIndex = chkBoxIndex + 1
	
	local checkbutton = CreateFrame("CheckButton", ADDON_NAME.."_config_chkbtn_" .. chkBoxIndex, parentFrame, "ChatConfigCheckButtonTemplate")
	getglobal(checkbutton:GetName() .. 'Text'):SetText(" "..displayText)
	
	checkbutton:SetScript("OnShow", function()
			checkbutton:SetChecked(dbObjectValue)
	end)
	
	return checkbutton
end

local yModifer = 30
local startY = -150
local currY = 0

local function addConfigEntry(objEntry)

	if currY == 0 then
		currY = startY
	else
		currY = currY - yModifer
	end
	
	objEntry:SetPoint("TOPLEFT", 20, currY)
end

local function LoadAboutFrame()

	--Code inspired from tekKonfigAboutPanel
	local about = CreateFrame("Frame", ADDON_NAME.."AboutPanel", InterfaceOptionsFramePanelContainer)
	about.name = ADDON_NAME
	about:Hide()
	
    local fields = {"Version", "Author"}
	local notes = GetAddOnMetadata(ADDON_NAME, "Notes")

    local title = about:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")

	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(ADDON_NAME)

	local subtitle = about:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(32)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetPoint("RIGHT", about, -32, 0)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(notes)

	local anchor
	for _,field in pairs(fields) do
		local val = GetAddOnMetadata(ADDON_NAME, field)
		if val then
			local title = about:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			title:SetWidth(75)
			if not anchor then title:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", -2, -8)
			else title:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6) end
			title:SetJustifyH("RIGHT")
			title:SetText(field:gsub("X%-", ""))

			local detail = about:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			detail:SetPoint("LEFT", title, "RIGHT", 4, 0)
			detail:SetPoint("RIGHT", -16, 0)
			detail:SetJustifyH("LEFT")
			detail:SetText(val)

			anchor = title
		end
	end
	
	InterfaceOptions_AddCategory(about)

	return about
end

function configEvent:PLAYER_LOGIN()
	
	addon.aboutPanel = LoadAboutFrame()
	
	addon.aboutPanel.btnSocial = createCheckbutton(addon.aboutPanel, L.SlashSocialInfo, XCHT_DB.hideSocial)
	addon.aboutPanel.btnSocial.func = function()
		local value = addon.aboutPanel.btnSocial:GetChecked()
		
		if not value then
			XCHT_DB.hideSocial = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashSocialOn)
		else
			XCHT_DB.hideSocial = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashSocialOff)
		end
		
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
	addon.aboutPanel.btnSocial:SetScript("OnClick", addon.aboutPanel.btnSocial.func)
	addConfigEntry(addon.aboutPanel.btnSocial)

	addon.aboutPanel.btnScroll = createCheckbutton(addon.aboutPanel, L.SlashScrollInfo, XCHT_DB.hideScroll)
	addon.aboutPanel.btnScroll.func = function()
		local value = addon.aboutPanel.btnScroll:GetChecked()

		if not value then
			XCHT_DB.hideScroll = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashScrollOn)
		else
			XCHT_DB.hideScroll = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashScrollOff)
		end
		
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
	addon.aboutPanel.btnScroll:SetScript("OnClick", addon.aboutPanel.btnScroll.func)
	addConfigEntry(addon.aboutPanel.btnScroll)

	addon.aboutPanel.btnShortNames = createCheckbutton(addon.aboutPanel, L.SlashShortNamesInfo, XCHT_DB.shortNames)
	addon.aboutPanel.btnShortNames.func = function()
		local value = addon.aboutPanel.btnShortNames:GetChecked()

		if not value then
			XCHT_DB.shortNames = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashShortNamesOn)
		else
			XCHT_DB.shortNames = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashShortNamesOff)
		end
		
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
	addon.aboutPanel.btnShortNames:SetScript("OnClick", addon.aboutPanel.btnShortNames.func)
	addConfigEntry(addon.aboutPanel.btnShortNames)

	addon.aboutPanel.btnEditBox = createCheckbutton(addon.aboutPanel, L.SlashEditBoxInfo, XCHT_DB.editBoxTop)
	addon.aboutPanel.btnEditBox.func = function()
		local value = addon.aboutPanel.btnEditBox:GetChecked()

		if not value then
			XCHT_DB.editBoxTop = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashEditBoxBottom)
		else
			XCHT_DB.editBoxTop = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashEditBoxTop)
		end
		
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
	addon.aboutPanel.btnEditBox:SetScript("OnClick", addon.aboutPanel.btnEditBox.func)
	addConfigEntry(addon.aboutPanel.btnEditBox)

	addon.aboutPanel.btnTabs = createCheckbutton(addon.aboutPanel, L.SlashTabsInfo, XCHT_DB.hideTabs)
	addon.aboutPanel.btnTabs.func = function()
		local value = addon.aboutPanel.btnTabs:GetChecked()

		if not value then
			XCHT_DB.hideTabs = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashTabsOn)
		else
			XCHT_DB.hideTabs = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashTabsOff)
		end
		
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
	addon.aboutPanel.btnTabs:SetScript("OnClick", addon.aboutPanel.btnTabs.func)
	addConfigEntry(addon.aboutPanel.btnTabs)

	addon.aboutPanel.btnShadow = createCheckbutton(addon.aboutPanel, L.SlashShadowInfo, XCHT_DB.addFontShadow)
	addon.aboutPanel.btnShadow.func = function()
		local value = addon.aboutPanel.btnShadow:GetChecked()

		if not value then
			XCHT_DB.addFontShadow = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashShadowOff)
		else
			XCHT_DB.addFontShadow = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashShadowOn)
		end
		
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
	addon.aboutPanel.btnShadow:SetScript("OnClick", addon.aboutPanel.btnShadow.func)
	addConfigEntry(addon.aboutPanel.btnShadow)

	addon.aboutPanel.btnVoice = createCheckbutton(addon.aboutPanel, L.SlashVoiceInfo, XCHT_DB.hideVoice)
	addon.aboutPanel.btnVoice.func = function()
		local value = addon.aboutPanel.btnVoice:GetChecked()

		if not value then
			XCHT_DB.hideVoice = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashVoiceOn)
		else
			XCHT_DB.hideVoice = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashVoiceOff)
		end
		
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
	addon.aboutPanel.btnVoice:SetScript("OnClick", addon.aboutPanel.btnVoice.func)
	addConfigEntry(addon.aboutPanel.btnVoice)

	configEvent:UnregisterEvent("PLAYER_LOGIN")
end

if IsLoggedIn() then configEvent:PLAYER_LOGIN() else configEvent:RegisterEvent("PLAYER_LOGIN") end