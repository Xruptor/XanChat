local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

addon.configFrame = CreateFrame("frame", ADDON_NAME.."_config_eventFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local configFrame = addon.configFrame

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
local configObjList = {}

local lastObject = {}

local function addConfigEntry(frameParentName, objEntry, adjustX, adjustY, isCustom, ignoreLock, customStartYPoint)

	if not ignoreLock then
		table.insert(configObjList, objEntry)
	end
	
	objEntry:ClearAllPoints()
	
	if not isCustom then
		if not lastObject[frameParentName] then
			if not customStartYPoint then
				objEntry:SetPoint("TOPLEFT", 20, -150)
			else
				objEntry:SetPoint("TOPLEFT", 20, customStartYPoint)
			end
		else
			local point, relativeTo, relativePoint, xOfs, yOfs = lastObject[frameParentName]:GetPoint()
			objEntry:SetPoint("TOPLEFT", adjustX or 0, (yOfs + adjustY) or -30)
		end
		
		lastObject[frameParentName] = objEntry
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
	
	local slider = CreateFrame("Slider", ADDON_NAME.."_config_slider_" .. sliderIndex, parentFrame, BackdropTemplateMixin and "BackdropTemplate")
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

local colorPickerIndex = 0
local function createColorPicker(parentFrame, dbObj, objName, displayText)
	colorPickerIndex = colorPickerIndex + 1
	
	local function ToRGBA(hex)
		return tonumber('0x' .. string.sub(hex, 3, 4), 10) / 255,
			tonumber('0x' .. string.sub(hex, 5, 6), 10) / 255,
			tonumber('0x' .. string.sub(hex, 7, 8), 10) / 255,
			tonumber('0x' .. string.sub(hex, 1, 2), 10) / 255
	end
	local function ToHex(r, g, b, a)
		return string.format('%02X%02X%02X%02X', a * 255, r * 255, g * 255, b * 255)
	end

	local function Update(self, value)
		local r, g, b, a
		if(type(value) == 'table' and r.GetRGB) then
			r, g, b, a = value:GetRGBA()
		else
			r, g, b, a = ToRGBA(value)
		end

		self.Swatch:SetVertexColor(r, g, b, a)
	
		--save values
		--r, g, b, a, value
		--value is hex
		dbObj[objName] = value
	end
	
	local Button = CreateFrame('Button', ADDON_NAME.."_config_colorpicker_" .. colorPickerIndex, parentFrame, BackdropTemplateMixin and "BackdropTemplate")
	Button:SetSize(25, 25)
	Button:SetScript('OnClick', function(self)
		local r, g, b, a = ToRGBA(dbObj[objName])
		ColorPickerFrame:SetColorRGB(r or 1, g or 1, b or 1)
		ColorPickerFrame.opacity = 1
		ColorPickerFrame.hasOpacity = false
		ColorPickerFrame.func = function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			local a = 1
			Update(self, ToHex(r, g, b, a))
		end

		ColorPickerFrame.opacityFunc = ColorPickerFrame.func
		ColorPickerFrame.cancelFunc = function()
			Update(self, ToHex(r, g, b, a))
		end
		ShowUIPanel(ColorPickerFrame)
	end)

	local Swatch = Button:CreateTexture(nil, 'OVERLAY')
	Swatch:SetPoint('CENTER')
	Swatch:SetSize(24, 24)
	Swatch:SetTexture([[Interface\ChatFrame\ChatFrameColorSwatch]])
	Button.Swatch = Swatch

	local text = parentFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	text:SetPoint("LEFT", Swatch, "RIGHT", 5, 0)
	text:SetText(displayText)
	
	--update to initial color stored
	Update(Button, dbObj[objName])

	return Button
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
	local about = CreateFrame("Frame", ADDON_NAME.."AboutPanel", InterfaceOptionsFramePanelContainer, BackdropTemplateMixin and "BackdropTemplate")
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

local function LoadAdditionalSettings(childFrameName, parentFrameName)

	local addSettings = CreateFrame("Frame", ADDON_NAME..childFrameName.."Panel", InterfaceOptionsFramePanelContainer, BackdropTemplateMixin and "BackdropTemplate")
	addSettings.name = childFrameName
	addSettings.parent = parentFrameName  --this is very important as it creates frame groups
	addSettings:Hide()

    local title = addSettings:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")

	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(ADDON_NAME)

	local subtitle = addSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(32)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetPoint("RIGHT", addSettings, -32, 0)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(childFrameName)
	
	InterfaceOptions_AddCategory(addSettings)

	return addSettings
end

function configFrame:EnableConfig()
	
	addon.aboutPanel = LoadAboutFrame()
	addon.additionalSettings = LoadAdditionalSettings(L.AdditionalSettings, ADDON_NAME)
	
	local btnStickyChannelsList = createButton(addon.aboutPanel, L.EditStickyChannelsListHeader)
	btnStickyChannelsList.func = function()
		if addon.stickyChannelsList then addon.stickyChannelsList:Show() end
	end
	btnStickyChannelsList:SetScript("OnClick", btnStickyChannelsList.func)
	
	addConfigEntry(addon.aboutPanel.name, btnStickyChannelsList, 403, -20, true)
	addon.aboutPanel.btnStickyChannelsList = btnStickyChannelsList
	
	local btnFilterList = createButton(addon.aboutPanel, L.EditFilterListHeader)
	btnFilterList.func = function()
		if addon.filterList then addon.filterList:Show() end
	end
	btnFilterList:SetScript("OnClick", btnFilterList.func)
	
	addConfigEntry(addon.aboutPanel.name, btnFilterList, 410, -55, true)
	addon.aboutPanel.btnFilterList = btnFilterList
	
	local btnLockChatSettings = createCheckbutton(addon.aboutPanel, "|cFF99CC33"..L.SlashLockChatSettingsInfo.."|r")
	btnLockChatSettings:SetScript("OnShow", function() btnLockChatSettings:SetChecked(XCHT_DB.lockChatSettings) end)
	btnLockChatSettings.func = function()
		local value = XCHT_DB.lockChatSettings

		if value then
			XCHT_DB.lockChatSettings = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashLockChatSettingsOff)
		else
			XCHT_DB.lockChatSettings = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashLockChatSettingsOn)
		end
		configFrame:DoLock()
	end
	btnLockChatSettings:SetScript("OnClick", btnLockChatSettings.func)
	
	addConfigEntry(addon.aboutPanel.name, btnLockChatSettings, 20, -110, true, true)
	addon.aboutPanel.btnLockChatSettings = btnLockChatSettings
	
	if addon.IsRetail then 
		local btnSocial = createCheckbutton(addon.aboutPanel, L.SlashSocialInfo)
		btnSocial:SetScript("OnShow", function() btnSocial:SetChecked(XCHT_DB.hideSocial) end)
		btnSocial.func = function()
			local value = XCHT_DB.hideSocial

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
	
		addConfigEntry(addon.aboutPanel.name, btnSocial, 20, -22)
		addon.aboutPanel.btnSocial = btnSocial
	end
	
	local btnScroll = createCheckbutton(addon.aboutPanel, L.SlashScrollInfo)
	btnScroll:SetScript("OnShow", function() btnScroll:SetChecked(XCHT_DB.hideScroll) end)
	btnScroll.func = function()
		local value = XCHT_DB.hideScroll

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
	
	addConfigEntry(addon.aboutPanel.name, btnScroll, 20, -22)
	addon.aboutPanel.btnScroll = btnScroll

	local btnShortNames = createCheckbutton(addon.aboutPanel, L.SlashShortNamesInfo)
	btnShortNames:SetScript("OnShow", function() btnShortNames:SetChecked(XCHT_DB.shortNames) end)
	btnShortNames.func = function()
		local value = XCHT_DB.shortNames

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
	
	addConfigEntry(addon.aboutPanel.name, btnShortNames, 20, -22)
	addon.aboutPanel.btnShortNames = btnShortNames

	local btnEditBox = createCheckbutton(addon.aboutPanel, L.SlashEditBoxInfo)
	btnEditBox:SetScript("OnShow", function() btnEditBox:SetChecked(XCHT_DB.editBoxTop) end)
	btnEditBox.func = function()
		local value = XCHT_DB.editBoxTop

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
	
	addConfigEntry(addon.aboutPanel.name, btnEditBox, 20, -22)
	addon.aboutPanel.btnEditBox = btnEditBox

	local btnTabs = createCheckbutton(addon.aboutPanel, L.SlashTabsInfo)
	btnTabs:SetScript("OnShow", function() btnTabs:SetChecked(XCHT_DB.hideTabs) end)
	btnTabs.func = function()
		local value = XCHT_DB.hideTabs

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
	
	addConfigEntry(addon.aboutPanel.name, btnTabs, 20, -22)
	addon.aboutPanel.btnTabs = btnTabs

	local btnFontOutline = createCheckbutton(addon.aboutPanel, L.SlashOutlineInfo)
	btnFontOutline:SetScript("OnShow", function() 
		btnFontOutline:SetChecked(XCHT_DB.addFontOutline)
	end)
	btnFontOutline.func = function()
		local value = XCHT_DB.addFontOutline

		if value then
			XCHT_DB.addFontOutline = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashOutlineOff)
		else
			XCHT_DB.addFontOutline = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashOutlineOn)
		end
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnFontOutline:SetScript("OnClick", btnFontOutline.func)
	
	addConfigEntry(addon.aboutPanel.name, btnFontOutline, 20, -22)
	addon.aboutPanel.btnFontOutline = btnFontOutline
	
	local btnShadow = createCheckbutton(addon.aboutPanel, L.SlashShadowInfo)
	btnShadow:SetScript("OnShow", function() btnShadow:SetChecked(XCHT_DB.addFontShadow) end)
	btnShadow.func = function()
		local value = XCHT_DB.addFontShadow

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
	
	addConfigEntry(addon.aboutPanel.name, btnShadow, 45, -22)
	addon.aboutPanel.btnShadow = btnShadow

	local btnVoice = createCheckbutton(addon.aboutPanel, L.SlashVoiceInfo)
	btnVoice:SetScript("OnShow", function() btnVoice:SetChecked(XCHT_DB.hideVoice) end)
	btnVoice.func = function()
		local value = XCHT_DB.hideVoice

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
	
	addConfigEntry(addon.aboutPanel.name, btnVoice, 20, -22)
	addon.aboutPanel.btnVoice = btnVoice

	local btnEditBoxBorder = createCheckbutton(addon.aboutPanel, L.SlashEditBoxBorderInfo)
	btnEditBoxBorder:SetScript("OnShow", function() btnEditBoxBorder:SetChecked(XCHT_DB.hideEditboxBorder) end)
	btnEditBoxBorder.func = function()
		local value = XCHT_DB.hideEditboxBorder

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
	
	addConfigEntry(addon.aboutPanel.name, btnEditBoxBorder, 20, -22)
	addon.aboutPanel.btnEditBoxBorder = btnEditBoxBorder

	local btnSimpleEditBox = createCheckbutton(addon.aboutPanel, L.SlashSimpleEditBoxInfo)
	btnSimpleEditBox:SetScript("OnShow", function() 
		btnSimpleEditBox:SetChecked(XCHT_DB.enableSimpleEditbox)
		setEnabled("checkbox", addon.aboutPanel.btnSEBDesign, XCHT_DB.enableSimpleEditbox)
	end)
	btnSimpleEditBox.func = function()
		local value = XCHT_DB.enableSimpleEditbox

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
	
	addConfigEntry(addon.aboutPanel.name, btnSimpleEditBox, 20, -22)
	addon.aboutPanel.btnSimpleEditBox = btnSimpleEditBox
	
	local btnSEBDesign = createCheckbutton(addon.aboutPanel, L.SlashSEBDesignInfo)
	btnSEBDesign:SetScript("OnShow", function() btnSEBDesign:SetChecked(XCHT_DB.enableSEBDesign) end)
	btnSEBDesign.func = function()
		local value = XCHT_DB.enableSEBDesign

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
	
	addConfigEntry(addon.aboutPanel.name, btnSEBDesign, 45, -22)
	addon.aboutPanel.btnSEBDesign = btnSEBDesign
	
	local btnAdjustedEditbox = createCheckbutton(addon.aboutPanel, L.SlashAdjustedEditboxInfo)
	btnAdjustedEditbox:SetScript("OnShow", function() 
		btnAdjustedEditbox:SetChecked(XCHT_DB.enableEditboxAdjusted)
	end)
	btnAdjustedEditbox.func = function()
		local value = XCHT_DB.enableEditboxAdjusted

		if value then
			XCHT_DB.enableEditboxAdjusted = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashAdjustedEditboxOff)
		else
			XCHT_DB.enableEditboxAdjusted = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashAdjustedEditboxOn)
		end
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnAdjustedEditbox:SetScript("OnClick", btnAdjustedEditbox.func)
	
	addConfigEntry(addon.aboutPanel.name, btnAdjustedEditbox, 20, -22)
	addon.aboutPanel.btnAdjustedEditbox = btnAdjustedEditbox
	
	local btnCopyPaste = createCheckbutton(addon.aboutPanel, L.SlashCopyPasteInfo)
	btnCopyPaste:SetScript("OnShow", function() 
		btnCopyPaste:SetChecked(XCHT_DB.enableCopyButton)
		setEnabled("checkbox", addon.aboutPanel.btnCopyPasteLeft, XCHT_DB.enableCopyButton)
	end)
	btnCopyPaste.func = function()
		local value = XCHT_DB.enableCopyButton

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
	
	addConfigEntry(addon.aboutPanel.name, btnCopyPaste, 20, -22)
	addon.aboutPanel.btnCopyPaste = btnCopyPaste
	
	local btnCopyPasteLeft = createCheckbutton(addon.aboutPanel, L.SlashCopyPasteLeftInfo)
	btnCopyPasteLeft:SetScript("OnShow", function() btnCopyPasteLeft:SetChecked(XCHT_DB.enableCopyButtonLeft) end)
	btnCopyPasteLeft.func = function()
		local value = XCHT_DB.enableCopyButtonLeft

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
	
	addConfigEntry(addon.aboutPanel.name, btnCopyPasteLeft, 45, -22)
	addon.aboutPanel.btnCopyPasteLeft = btnCopyPasteLeft
	
	local btnPlayerChatStyle = createCheckbutton(addon.aboutPanel, L.SlashPlayerChatStyleInfo)
	btnPlayerChatStyle:SetScript("OnShow", function() btnPlayerChatStyle:SetChecked(XCHT_DB.enablePlayerChatStyle) end)
	btnPlayerChatStyle.func = function()
		local value = XCHT_DB.enablePlayerChatStyle

		if value then
			XCHT_DB.enablePlayerChatStyle = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashPlayerChatStyleOff)
		else
			XCHT_DB.enablePlayerChatStyle = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashPlayerChatStyleOn)
		end
		
	end
	btnPlayerChatStyle:SetScript("OnClick", btnPlayerChatStyle.func)
	
	addConfigEntry(addon.aboutPanel.name, btnPlayerChatStyle, 20, -22)
	addon.aboutPanel.btnPlayerChatStyle = btnPlayerChatStyle
	
	local btnChatTextFade = createCheckbutton(addon.aboutPanel, L.SlashChatTextFadeInfo)
	btnChatTextFade:SetScript("OnShow", function() btnChatTextFade:SetChecked(XCHT_DB.enableChatTextFade) end)
	btnChatTextFade.func = function()
		local value = XCHT_DB.enableChatTextFade

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
	
	addConfigEntry(addon.aboutPanel.name, btnChatTextFade, 20, -22)
	addon.aboutPanel.btnChatTextFade = btnChatTextFade
	
	local btnChatFrameFade = createCheckbutton(addon.aboutPanel, L.SlashChatFrameFadeInfo)
	btnChatFrameFade:SetScript("OnShow", function() btnChatFrameFade:SetChecked(XCHT_DB.disableChatFrameFade) end)
	btnChatFrameFade.func = function()
		local value = XCHT_DB.disableChatFrameFade

		if value then
			XCHT_DB.disableChatFrameFade = false
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashChatFrameFadeOff)
		else
			XCHT_DB.disableChatFrameFade = true
			DEFAULT_CHAT_FRAME:AddMessage(L.SlashChatFrameFadeOn)
		end
		
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnChatFrameFade:SetScript("OnClick", btnChatFrameFade.func)
	
	addConfigEntry(addon.aboutPanel.name, btnChatFrameFade, 20, -22)
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
		addon:setUserAlpha()
	end
	sliderChatAlpha.sliderMouseUp = function(self, button)
		sliderChatAlpha.func(sliderChatAlpha:GetValue())
	end
	sliderChatAlpha.sliderFunc = function(self, value)
		sliderChatAlpha.currVal:SetText("("..floor(value)..")")
	end
	sliderChatAlpha:SetScript("OnValueChanged", sliderChatAlpha.sliderFunc)
	sliderChatAlpha:SetScript("OnMouseUp", sliderChatAlpha.sliderMouseUp)
	
	addConfigEntry(addon.aboutPanel.name, sliderChatAlpha, 20, -53)
	addon.aboutPanel.sliderChatAlpha = sliderChatAlpha
	
	--do the lock settings onShow
	addon.aboutPanel:HookScript("OnShow", function()
		if XCHT_DB and XCHT_DB.lockChatSettings then
			--DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: "..L.SlashLockChatSettingsAlert)
			configFrame:DoLock()
		end
	end)
	
	
	-------------------------------------------------------
	-------------------------------------------------------
	--ADDITIONAL SETTINGS

	local btnOutWhisperColor = createCheckbutton(addon.additionalSettings, L.EnableOutWhisperColor)
	btnOutWhisperColor:SetScript("OnShow", function() btnOutWhisperColor:SetChecked(XCHT_DB.enableOutWhisperColor) end)
	btnOutWhisperColor.func = function()
		local value = XCHT_DB.enableOutWhisperColor

		if value then
			XCHT_DB.enableOutWhisperColor = false
		else
			XCHT_DB.enableOutWhisperColor = true
		end
		
		addon:setOutWhisperColor()
	
		if not addon.xanChatReloadPopup then
			StaticPopup_Show("XANCHAT_APPLYCHANGES")
		end
	end
	btnOutWhisperColor:SetScript("OnClick", btnOutWhisperColor.func)
	
	addConfigEntry(addon.additionalSettings.name, btnOutWhisperColor, 20, -22, nil, nil, -70)
	addon.additionalSettings.btnOutWhisperColor = btnOutWhisperColor
	
	--color swatch
	local btnOutWhisperColorPicker = createColorPicker(addon.additionalSettings, XCHT_DB, "outWhisperColor", L.ChangeOutgoingWhisperColor)
	addConfigEntry(addon.additionalSettings.name, btnOutWhisperColorPicker, 20, -25)
	addon.additionalSettings.btnOutWhisperColorPicker = btnOutWhisperColorPicker

	local btnDisableChatEnterLeaveNotice = createCheckbutton(addon.additionalSettings, L.DisableChatEnterLeaveNotice)
	btnDisableChatEnterLeaveNotice:SetScript("OnShow", function() btnDisableChatEnterLeaveNotice:SetChecked(XCHT_DB.disableChatEnterLeaveNotice) end)
	btnDisableChatEnterLeaveNotice.func = function()
		local value = XCHT_DB.disableChatEnterLeaveNotice

		if value then
			XCHT_DB.disableChatEnterLeaveNotice = false
		else
			XCHT_DB.disableChatEnterLeaveNotice = true
		end
		
		addon:setDisableChatEnterLeaveNotice()
	end
	btnDisableChatEnterLeaveNotice:SetScript("OnClick", btnDisableChatEnterLeaveNotice.func)
	
	addConfigEntry(addon.additionalSettings.name, btnDisableChatEnterLeaveNotice, 20, -30)
	addon.additionalSettings.btnDisableChatEnterLeaveNotice = btnDisableChatEnterLeaveNotice
	
	--do the lock for additional settings onShow as well
	addon.additionalSettings:HookScript("OnShow", function()
		if XCHT_DB and XCHT_DB.lockChatSettings then
			--DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: "..L.SlashLockChatSettingsAlert)
			configFrame:DoLock()
		end
	end)
end

function configFrame:DoLock()
	if XCHT_DB and XCHT_DB.lockChatSettings then
		for i=1, #configObjList do
			configObjList[i]:SetEnabled(false)
		end
	else
		for i=1, #configObjList do
			configObjList[i]:SetEnabled(true)
		end
	end
end
