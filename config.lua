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
local function addConfigEntry(objEntry, adjustX, adjustY, isCustom)
	
	objEntry:ClearAllPoints()
	
	if not isCustom then
		if not lastObject then
			objEntry:SetPoint("TOPLEFT", 20, -150)
		else
			local point, relativeTo, relativePoint, xOfs, yOfs = lastObject:GetPoint()
			objEntry:SetPoint("TOPLEFT", adjustX or 0, (yOfs + adjustY) or -30)
		end
		
		lastObject = objEntry
	else
		objEntry:SetPoint("TOPLEFT", adjustX, adjustY)
	end
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

local function setEnabled(objType, obj, switch)
	if objType == "checkbox" then
		obj:SetEnabled(switch)
		if switch then
			obj.Text:SetTextColor(1, 1, 1) --white
		else
			obj.Text:SetTextColor(128/255, 128/255, 128/255) --gray
		end
	end
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
	
	local btnFilterList = createButton(addon.aboutPanel, L.EditFilterListHeader)
	btnFilterList.func = function()
		if addon.filterList then addon.filterList:Show() end
	end
	btnFilterList:SetScript("OnClick", btnFilterList.func)
	
	addConfigEntry(btnFilterList, 430, -30, true)
	addon.aboutPanel.btnFilterList = btnFilterList
	
	local btnLockChatSettings = createCheckbutton(addon.aboutPanel, "|cFF99CC33"..L.SlashLockChatSettingsInfo.."|r")
	btnLockChatSettings:SetScript("OnShow", function() btnLockChatSettings:SetChecked(XCHT_DB.lockChatSettings) end)
	btnLockChatSettings.func = function(slashSwitch)
		local value = XCHT_DB.lockChatSettings
		if not slashSwitch then value = btnLockChatSettings:GetChecked() end
		
		if value then
			XCHT_DB.lockChatSettings = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashLockChatSettingsOff)
		else
			XCHT_DB.lockChatSettings = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashLockChatSettingsOn)
		end
	end
	btnLockChatSettings:SetScript("OnClick", btnLockChatSettings.func)
	
	addConfigEntry(btnLockChatSettings, 20, -110, true)
	addon.aboutPanel.btnLockChatSettings = btnLockChatSettings
	
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
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnSocial:SetScript("OnClick", btnSocial.func)
	
	addConfigEntry(btnSocial, 20, -21)
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
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnScroll:SetScript("OnClick", btnScroll.func)
	
	addConfigEntry(btnScroll, 20, -21)
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
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnShortNames:SetScript("OnClick", btnShortNames.func)
	
	addConfigEntry(btnShortNames, 20, -21)
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
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnEditBox:SetScript("OnClick", btnEditBox.func)
	
	addConfigEntry(btnEditBox, 20, -21)
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
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnTabs:SetScript("OnClick", btnTabs.func)
	
	addConfigEntry(btnTabs, 20, -21)
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
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnShadow:SetScript("OnClick", btnShadow.func)
	
	addConfigEntry(btnShadow, 20, -21)
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
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnVoice:SetScript("OnClick", btnVoice.func)
	
	addConfigEntry(btnVoice, 20, -21)
	addon.aboutPanel.btnVoice = btnVoice
	
	local btnEditBoxBorder = createCheckbutton(addon.aboutPanel, L.SlashEditBoxBorderInfo)
	btnEditBoxBorder:SetScript("OnShow", function() btnEditBoxBorder:SetChecked(XCHT_DB.hideEditboxBorder) end)
	btnEditBoxBorder.func = function(slashSwitch)
		local value = XCHT_DB.hideEditboxBorder
		if not slashSwitch then value = btnEditBoxBorder:GetChecked() end

		if value then
			XCHT_DB.hideEditboxBorder = false
			XCHT_DB.enableSimpleEditbox = false --turn this off
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashEditBoxBorderOn)
		else
			XCHT_DB.hideEditboxBorder = true
			XCHT_DB.enableSimpleEditbox = false --turn this off
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashEditBoxBorderOff)
		end
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnEditBoxBorder:SetScript("OnClick", btnEditBoxBorder.func)
	
	addConfigEntry(btnEditBoxBorder, 20, -21)
	addon.aboutPanel.btnEditBoxBorder = btnEditBoxBorder

	local btnSimpleEditBox = createCheckbutton(addon.aboutPanel, L.SlashSimpleEditBoxInfo)
	btnSimpleEditBox:SetScript("OnShow", function() 
		btnSimpleEditBox:SetChecked(XCHT_DB.enableSimpleEditbox)
		setEnabled("checkbox", addon.aboutPanel.btnSEBDesign, XCHT_DB.enableSimpleEditbox)
	end)
	btnSimpleEditBox.func = function(slashSwitch)
		local value = XCHT_DB.enableSimpleEditbox
		if not slashSwitch then value = btnSimpleEditBox:GetChecked() end

		if value then
			XCHT_DB.enableSimpleEditbox = false
			XCHT_DB.hideEditboxBorder = false --turn this off
			setEnabled("checkbox", addon.aboutPanel.btnSEBDesign, XCHT_DB.enableSimpleEditbox)
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashSimpleEditBoxOff)
		else
			XCHT_DB.enableSimpleEditbox = true
			XCHT_DB.hideEditboxBorder = false --turn this off
			setEnabled("checkbox", addon.aboutPanel.btnSEBDesign, XCHT_DB.enableSimpleEditbox)
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashSimpleEditBoxOn)
		end
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnSimpleEditBox:SetScript("OnClick", btnSimpleEditBox.func)
	
	addConfigEntry(btnSimpleEditBox, 20, -21)
	addon.aboutPanel.btnSimpleEditBox = btnSimpleEditBox
	
	local btnSEBDesign = createCheckbutton(addon.aboutPanel, L.SlashSEBDesignInfo)
	btnSEBDesign:SetScript("OnShow", function() btnSEBDesign:SetChecked(XCHT_DB.enableSEBDesign) end)
	btnSEBDesign.func = function(slashSwitch)
		local value = XCHT_DB.enableSEBDesign
		if not slashSwitch then value = btnSEBDesign:GetChecked() end

		if value then
			XCHT_DB.enableSEBDesign = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashSEBDesignOff)
		else
			XCHT_DB.enableSEBDesign = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashSEBDesignOn)
		end
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnSEBDesign:SetScript("OnClick", btnSEBDesign.func)
	
	addConfigEntry(btnSEBDesign, 45, -21)
	addon.aboutPanel.btnSEBDesign = btnSEBDesign
	
	local btnCopyPaste = createCheckbutton(addon.aboutPanel, L.SlashCopyPasteInfo)
	btnCopyPaste:SetScript("OnShow", function() 
		btnCopyPaste:SetChecked(XCHT_DB.enableCopyButton)
		setEnabled("checkbox", addon.aboutPanel.btnCopyPasteLeft, XCHT_DB.enableCopyButton)
	end)
	btnCopyPaste.func = function(slashSwitch)
		local value = XCHT_DB.enableCopyButton
		if not slashSwitch then value = btnCopyPaste:GetChecked() end

		if value then
			XCHT_DB.enableCopyButton = false
			setEnabled("checkbox", addon.aboutPanel.btnCopyPasteLeft, XCHT_DB.enableCopyButton)
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashCopyPasteOff)
		else
			XCHT_DB.enableCopyButton = true
			setEnabled("checkbox", addon.aboutPanel.btnCopyPasteLeft, XCHT_DB.enableCopyButton)
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashCopyPasteOn)
		end
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnCopyPaste:SetScript("OnClick", btnCopyPaste.func)
	
	addConfigEntry(btnCopyPaste, 20, -21)
	addon.aboutPanel.btnCopyPaste = btnCopyPaste
	
	local btnCopyPasteLeft = createCheckbutton(addon.aboutPanel, L.SlashCopyPasteLeftInfo)
	btnCopyPasteLeft:SetScript("OnShow", function() btnCopyPasteLeft:SetChecked(XCHT_DB.enableCopyButtonLeft) end)
	btnCopyPasteLeft.func = function(slashSwitch)
		local value = XCHT_DB.enableCopyButtonLeft
		if not slashSwitch then value = btnCopyPasteLeft:GetChecked() end

		if value then
			XCHT_DB.enableCopyButtonLeft = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashCopyPasteLeftOff)
		else
			XCHT_DB.enableCopyButtonLeft = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashCopyPasteLeftOn)
		end
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnCopyPasteLeft:SetScript("OnClick", btnCopyPasteLeft.func)
	
	addConfigEntry(btnCopyPasteLeft, 45, -21)
	addon.aboutPanel.btnCopyPasteLeft = btnCopyPasteLeft
	
	local btnPlayerChatStyle = createCheckbutton(addon.aboutPanel, L.SlashPlayerChatStyleInfo)
	btnPlayerChatStyle:SetScript("OnShow", function() btnPlayerChatStyle:SetChecked(XCHT_DB.enablePlayerChatStyle) end)
	btnPlayerChatStyle.func = function(slashSwitch)
		local value = XCHT_DB.enablePlayerChatStyle
		if not slashSwitch then value = btnPlayerChatStyle:GetChecked() end

		if value then
			XCHT_DB.enablePlayerChatStyle = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashPlayerChatStyleOff)
		else
			XCHT_DB.enablePlayerChatStyle = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashPlayerChatStyleOn)
		end
		
	end
	btnPlayerChatStyle:SetScript("OnClick", btnPlayerChatStyle.func)
	
	addConfigEntry(btnPlayerChatStyle, 20, -21)
	addon.aboutPanel.btnPlayerChatStyle = btnPlayerChatStyle
	
	local btnChatTextFade = createCheckbutton(addon.aboutPanel, L.SlashChatTextFadeInfo)
	btnChatTextFade:SetScript("OnShow", function() btnChatTextFade:SetChecked(XCHT_DB.enableChatTextFade) end)
	btnChatTextFade.func = function(slashSwitch)
		local value = XCHT_DB.enableChatTextFade
		if not slashSwitch then value = btnChatTextFade:GetChecked() end

		if value then
			XCHT_DB.enableChatTextFade = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashChatTextFadeOff)
		else
			XCHT_DB.enableChatTextFade = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashChatTextFadeOn)
		end
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnChatTextFade:SetScript("OnClick", btnChatTextFade.func)
	
	addConfigEntry(btnChatTextFade, 20, -21)
	addon.aboutPanel.btnChatTextFade = btnChatTextFade
	
	local btnChatFrameFade = createCheckbutton(addon.aboutPanel, L.SlashChatFrameFadeInfo)
	btnChatFrameFade:SetScript("OnShow", function() btnChatFrameFade:SetChecked(XCHT_DB.enableChatFrameFade) end)
	btnChatFrameFade.func = function(slashSwitch)
		local value = XCHT_DB.enableChatFrameFade
		if not slashSwitch then value = btnChatFrameFade:GetChecked() end

		if value then
			XCHT_DB.enableChatFrameFade = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashChatFrameFadeOff)
		else
			XCHT_DB.enableChatFrameFade = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashChatFrameFadeOn)
		end
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnChatFrameFade:SetScript("OnClick", btnChatFrameFade.func)
	
	addConfigEntry(btnChatFrameFade, 20, -21)
	addon.aboutPanel.btnChatFrameFade = btnChatFrameFade
	
	--slider chat alpha
	local sliderChatAlpha = createSlider(addon.aboutPanel, L.SlashChatAlphaText, 0, 100)
	sliderChatAlpha:SetScript("OnShow", function()
		sliderChatAlpha:SetValue(floor(XCHT_DB.userChatAlpha * 100))
		sliderChatAlpha.currVal:SetText("("..floor(XCHT_DB.userChatAlpha * 100)..")")
	end)
	sliderChatAlpha.func = function(value)
		XCHT_DB.userChatAlpha = tonumber(value) / 100
		sliderChatAlpha:SetValue(floor(XCHT_DB.userChatAlpha * 100))
		sliderChatAlpha.currVal:SetText("("..floor(XCHT_DB.userChatAlpha * 100)..")")
		DEFAULT_CHAT_FRAME:AddMessage(string.format(L.SlashChatAlphaSet, floor(value)))
		addon:setChatAlpha()
	end
	sliderChatAlpha.sliderMouseUp = function(self, button)
		sliderChatAlpha.func(sliderChatAlpha:GetValue())
	end
	sliderChatAlpha.sliderFunc = function(self, value)
		sliderChatAlpha.currVal:SetText("("..floor(value)..")")
	end
	sliderChatAlpha:SetScript("OnValueChanged", sliderChatAlpha.sliderFunc)
	sliderChatAlpha:SetScript("OnMouseUp", sliderChatAlpha.sliderMouseUp)
	
	addConfigEntry(sliderChatAlpha, 20, -50)
	addon.aboutPanel.sliderChatAlpha = sliderChatAlpha
	
	configEvent:UnregisterEvent("PLAYER_LOGIN")
end

if IsLoggedIn() then configEvent:PLAYER_LOGIN() else configEvent:RegisterEvent("PLAYER_LOGIN") end