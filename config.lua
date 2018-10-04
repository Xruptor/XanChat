local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent)
end
addon = _G[ADDON_NAME]

addon.configEvent = CreateFrame("frame", ADDON_NAME.."_config_eventFrame",UIParent)
local configEvent = addon.configEvent
configEvent:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

local lastObject
local function addConfigEntry(objEntry, adjustX, adjustY)
	
	objEntry:ClearAllPoints()
	
	if not lastObject then
		objEntry:SetPoint("TOPLEFT", 20, -150)
	else
		objEntry:SetPoint("LEFT", lastObject, "BOTTOMLEFT", adjustX or 0, adjustY or -30)
	end
	
	lastObject = objEntry
end

local chkBoxIndex = 0
local function createCheckbutton(parentFrame, displayText)
	chkBoxIndex = chkBoxIndex + 1
	
	local checkbutton = CreateFrame("CheckButton", ADDON_NAME.."_config_chkbtn_" .. chkBoxIndex, parentFrame, "ChatConfigCheckButtonTemplate")
	getglobal(checkbutton:GetName() .. 'Text'):SetText(" "..displayText)
	
	return checkbutton
end

local buttonIndex = 0
local function createButton(parentFrame, displayText)
	buttonIndex = buttonIndex + 1
	
	local button = CreateFrame("Button", ADDON_NAME.."_config_button_" .. buttonIndex, parentFrame, "UIPanelButtonTemplate")
	button:SetText(displayText)
	button:SetHeight(30)
	button:SetWidth(button:GetTextWidth() + 30)

	return button
end

local sliderIndex = 0
local function createSlider(parentFrame, displayText, minVal, maxVal)
	sliderIndex = sliderIndex + 1
	
	local SliderBackdrop  = {
		bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
		edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
		tile = true, tileSize = 8, edgeSize = 8,
		insets = { left = 3, right = 3, top = 6, bottom = 6 }
	}
	
	local slider = CreateFrame("Slider", ADDON_NAME.."_config_slider_" .. sliderIndex, parentFrame)
	slider:SetOrientation("HORIZONTAL")
	slider:SetHeight(15)
	slider:SetWidth(300)
	slider:SetHitRectInsets(0, 0, -10, 0)
	slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	slider:SetMinMaxValues(minVal or 0, maxVal or 100)
	slider:SetValue(0)
	slider:SetBackdrop(SliderBackdrop)

	local label = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("CENTER", slider, "CENTER", 0, 16)
	label:SetJustifyH("CENTER")
	label:SetHeight(15)
	label:SetText(displayText)

	local lowtext = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	lowtext:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 2, 3)
	lowtext:SetText(minVal)

	local hightext = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	hightext:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", -2, 3)
	hightext:SetText(maxVal)
	
	local currVal = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	currVal:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 45, 12)
	currVal:SetText('(?)')
	slider.currVal = currVal
	
	return slider
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
	
	local btnSocial = createCheckbutton(addon.aboutPanel, L.SlashSocialInfo)
	btnSocial:SetScript("OnShow", function() btnSocial:SetChecked(XCHT_DB.hideSocial) end)
	btnSocial.func = function(slashSwitch)
		local value = XCHT_DB.hideSocial
		if not slashSwitch then value = btnSocial:GetChecked() end
		
		if value then
			XCHT_DB.hideSocial = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashSocialOn)
		else
			XCHT_DB.hideSocial = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashSocialOff)
		end
		
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
	btnSocial:SetScript("OnClick", btnSocial.func)
	
	addConfigEntry(btnSocial, 0, -20)
	addon.aboutPanel.btnSocial = btnSocial

	local btnScroll = createCheckbutton(addon.aboutPanel, L.SlashScrollInfo)
	btnScroll:SetScript("OnShow", function() btnScroll:SetChecked(XCHT_DB.hideScroll) end)
	btnScroll.func = function(slashSwitch)
		local value = XCHT_DB.hideScroll
		if not slashSwitch then value = btnScroll:GetChecked() end

		if value then
			XCHT_DB.hideScroll = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashScrollOn)
		else
			XCHT_DB.hideScroll = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashScrollOff)
		end
		
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
	btnScroll:SetScript("OnClick", btnScroll.func)
	
	addConfigEntry(btnScroll, 0, -20)
	addon.aboutPanel.btnScroll = btnScroll

	local btnShortNames = createCheckbutton(addon.aboutPanel, L.SlashShortNamesInfo)
	btnShortNames:SetScript("OnShow", function() btnShortNames:SetChecked(XCHT_DB.shortNames) end)
	btnShortNames.func = function(slashSwitch)
		local value = XCHT_DB.shortNames
		if not slashSwitch then value = btnShortNames:GetChecked() end

		if value then
			XCHT_DB.shortNames = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashShortNamesOff)
		else
			XCHT_DB.shortNames = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashShortNamesOn)
		end
		
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
	btnShortNames:SetScript("OnClick", btnShortNames.func)
	
	addConfigEntry(btnShortNames, 0, -20)
	addon.aboutPanel.btnShortNames = btnShortNames

	local btnEditBox = createCheckbutton(addon.aboutPanel, L.SlashEditBoxInfo)
	btnEditBox:SetScript("OnShow", function() btnEditBox:SetChecked(XCHT_DB.editBoxTop) end)
	btnEditBox.func = function(slashSwitch)
		local value = XCHT_DB.editBoxTop
		if not slashSwitch then value = btnEditBox:GetChecked() end

		if value then
			XCHT_DB.editBoxTop = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashEditBoxBottom)
		else
			XCHT_DB.editBoxTop = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashEditBoxTop)
		end
		
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
	btnEditBox:SetScript("OnClick", btnEditBox.func)
	
	addConfigEntry(btnEditBox, 0, -20)
	addon.aboutPanel.btnEditBox = btnEditBox

	local btnTabs = createCheckbutton(addon.aboutPanel, L.SlashTabsInfo)
	btnTabs:SetScript("OnShow", function() btnTabs:SetChecked(XCHT_DB.hideTabs) end)
	btnTabs.func = function(slashSwitch)
		local value = XCHT_DB.hideTabs
		if not slashSwitch then value = btnTabs:GetChecked() end

		if value then
			XCHT_DB.hideTabs = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashTabsOn)
		else
			XCHT_DB.hideTabs = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashTabsOff)
		end
		
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
	btnTabs:SetScript("OnClick", btnTabs.func)
	
	addConfigEntry(btnTabs, 0, -20)
	addon.aboutPanel.btnTabs = btnTabs

	local btnShadow = createCheckbutton(addon.aboutPanel, L.SlashShadowInfo)
	btnShadow:SetScript("OnShow", function() btnShadow:SetChecked(XCHT_DB.addFontShadow) end)
	btnShadow.func = function(slashSwitch)
		local value = XCHT_DB.addFontShadow
		if not slashSwitch then value = btnShadow:GetChecked() end

		if value then
			XCHT_DB.addFontShadow = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashShadowOff)
		else
			XCHT_DB.addFontShadow = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashShadowOn)
		end
		
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
	btnShadow:SetScript("OnClick", btnShadow.func)
	
	addConfigEntry(btnShadow, 0, -20)
	addon.aboutPanel.btnShadow = btnShadow

	local btnVoice = createCheckbutton(addon.aboutPanel, L.SlashVoiceInfo)
	btnVoice:SetScript("OnShow", function() btnVoice:SetChecked(XCHT_DB.hideVoice) end)
	btnVoice.func = function(slashSwitch)
		local value = XCHT_DB.hideVoice
		if not slashSwitch then value = btnVoice:GetChecked() end

		if value then
			XCHT_DB.hideVoice = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashVoiceOn)
		else
			XCHT_DB.hideVoice = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashVoiceOff)
		end
		
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
	btnVoice:SetScript("OnClick", btnVoice.func)
	
	addConfigEntry(btnVoice, 0, -20)
	addon.aboutPanel.btnVoice = btnVoice

	configEvent:UnregisterEvent("PLAYER_LOGIN")
end

if IsLoggedIn() then configEvent:PLAYER_LOGIN() else configEvent:RegisterEvent("PLAYER_LOGIN") end