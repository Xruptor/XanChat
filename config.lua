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
local function addConfigEntry(objEntry)
	
	objEntry:ClearAllPoints()
	
	if not lastObject then
		objEntry:SetPoint("TOPLEFT", 20, -150)
	else
		objEntry:SetPoint("LEFT", lastObject, "BOTTOMLEFT", 0, -35)
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
	label:SetPoint("CENTER", slider, "CENTER", 0, 12)
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
	
	addon.aboutPanel.btnSocial = createCheckbutton(addon.aboutPanel, L.SlashSocialInfo)
	addon.aboutPanel.btnSocial:SetScript("OnShow", function() addon.aboutPanel.btnSocial:SetChecked(XCHT_DB.hideSocial) end)
	addon.aboutPanel.btnSocial.func = function(slashSwitch)
		local value = XCHT_DB.hideSocial
		if not slashSwitch then value = addon.aboutPanel.btnSocial:GetChecked() end
		
		if value then
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

	addon.aboutPanel.btnScroll = createCheckbutton(addon.aboutPanel, L.SlashScrollInfo)
	addon.aboutPanel.btnScroll:SetScript("OnShow", function() addon.aboutPanel.btnScroll:SetChecked(XCHT_DB.hideScroll) end)
	addon.aboutPanel.btnScroll.func = function(slashSwitch)
		local value = XCHT_DB.hideScroll
		if not slashSwitch then value = addon.aboutPanel.btnScroll:GetChecked() end

		if value then
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

	addon.aboutPanel.btnShortNames = createCheckbutton(addon.aboutPanel, L.SlashShortNamesInfo)
	addon.aboutPanel.btnShortNames:SetScript("OnShow", function() addon.aboutPanel.btnShortNames:SetChecked(XCHT_DB.shortNames) end)
	addon.aboutPanel.btnShortNames.func = function(slashSwitch)
		local value = XCHT_DB.shortNames
		if not slashSwitch then value = addon.aboutPanel.btnShortNames:GetChecked() end

		if value then
			XCHT_DB.shortNames = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashShortNamesOff)
		else
			XCHT_DB.shortNames = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashShortNamesOn)
		end
		
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
	addon.aboutPanel.btnShortNames:SetScript("OnClick", addon.aboutPanel.btnShortNames.func)
	addConfigEntry(addon.aboutPanel.btnShortNames)

	addon.aboutPanel.btnEditBox = createCheckbutton(addon.aboutPanel, L.SlashEditBoxInfo)
	addon.aboutPanel.btnEditBox:SetScript("OnShow", function() addon.aboutPanel.btnEditBox:SetChecked(XCHT_DB.editBoxTop) end)
	addon.aboutPanel.btnEditBox.func = function(slashSwitch)
		local value = XCHT_DB.editBoxTop
		if not slashSwitch then value = addon.aboutPanel.btnEditBox:GetChecked() end

		if value then
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

	addon.aboutPanel.btnTabs = createCheckbutton(addon.aboutPanel, L.SlashTabsInfo)
	addon.aboutPanel.btnTabs:SetScript("OnShow", function() addon.aboutPanel.btnTabs:SetChecked(XCHT_DB.hideTabs) end)
	addon.aboutPanel.btnTabs.func = function(slashSwitch)
		local value = XCHT_DB.hideTabs
		if not slashSwitch then value = addon.aboutPanel.btnTabs:GetChecked() end

		if value then
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

	addon.aboutPanel.btnShadow = createCheckbutton(addon.aboutPanel, L.SlashShadowInfo)
	addon.aboutPanel.btnShadow:SetScript("OnShow", function() addon.aboutPanel.btnShadow:SetChecked(XCHT_DB.addFontShadow) end)
	addon.aboutPanel.btnShadow.func = function(slashSwitch)
		local value = XCHT_DB.addFontShadow
		if not slashSwitch then value = addon.aboutPanel.btnShadow:GetChecked() end

		if value then
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

	addon.aboutPanel.btnVoice = createCheckbutton(addon.aboutPanel, L.SlashVoiceInfo)
	addon.aboutPanel.btnVoice:SetScript("OnShow", function() addon.aboutPanel.btnVoice:SetChecked(XCHT_DB.hideVoice) end)
	addon.aboutPanel.btnVoice.func = function(slashSwitch)
		local value = XCHT_DB.hideVoice
		if not slashSwitch then value = addon.aboutPanel.btnVoice:GetChecked() end

		if value then
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