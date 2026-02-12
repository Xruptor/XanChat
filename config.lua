local ADDON_NAME, private = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
local addon = _G[ADDON_NAME]
addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

addon.configFrame = CreateFrame("frame", ADDON_NAME.."_config_eventFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local configFrame = addon.configFrame

local L = addon.L
local floor = math.floor
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
				objEntry:SetPoint("TOPLEFT", 20, -135)
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
	local label = _G[checkbutton:GetName() .. "Text"]
	if label then
		label:SetText(" "..displayText)
	end

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
		if type(value) == "table" then
			if value.GetRGBA then
				r, g, b, a = value:GetRGBA()
			elseif value.GetRGB then
				r, g, b = value:GetRGB()
				a = 1
			end
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
		if obj.Text then
			if switch then
				obj.Text:SetTextColor(1, 1, 1) --white
			else
				obj.Text:SetTextColor(128/255, 128/255, 128/255) --gray
			end
		end
	end
end

local function showReloadPopup()
	if not addon.xanChatReloadPopup then
		StaticPopup_Show("XANCHAT_APPLYCHANGES")
	end
end

local function bindToggle(btn, key, opts)
	opts = opts or {}
	btn:SetScript("OnShow", function()
		btn:SetChecked(XCHT_DB[key])
		if opts.onShow then opts.onShow(btn) end
	end)
	btn.func = function()
		local newValue = not XCHT_DB[key]
		XCHT_DB[key] = newValue
		if opts.onToggle then opts.onToggle(newValue, btn) end
		if opts.messageOn or opts.messageOff then
			DEFAULT_CHAT_FRAME:AddMessage(newValue and opts.messageOn or opts.messageOff)
		end
		if opts.showReload then
			showReloadPopup()
		end
	end
	btn:SetScript("OnClick", btn.func)
end

local function LoadAboutFrame()

	--Code inspired from tekKonfigAboutPanel
	local about = CreateFrame("Frame", ADDON_NAME.."AboutPanel", InterfaceOptionsFramePanelContainer, BackdropTemplateMixin and "BackdropTemplate")
	about.name = ADDON_NAME
	about:Hide()

    local fields = {"Version", "Author"}
	local getMetadata = addon.GetAddOnMetadata or (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
	local notes = getMetadata and getMetadata(ADDON_NAME, "Notes") or ""

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
		local val = getMetadata and getMetadata(ADDON_NAME, field)
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

	if InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(about)
	else
		local category, layout = _G.Settings.RegisterCanvasLayoutCategory(about, about.name);
		_G.Settings.RegisterAddOnCategory(category);
		addon.settingsCategory = category
		if category and category.GetID then
			addon.settingsCategoryID = category:GetID()
		end
	end

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

	if InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(addSettings)
	else
		if addon.settingsCategory then
			--local category = _G.Settings.GetCategory(addon.settingsCategory)
			local subcategory = _G.Settings.RegisterCanvasLayoutSubcategory(addon.settingsCategory, addSettings, addSettings.name)
			addon.addSettingsCategory = subcategory
		end
	end

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

	local btnLockChatSettings = createCheckbutton(addon.aboutPanel, "|cFF99CC33"..L.LockChatSettingsInfo.."|r")
	bindToggle(btnLockChatSettings, "lockChatSettings", {
		messageOn = L.LockChatSettingsOn,
		messageOff = L.LockChatSettingsOff,
		onToggle = function()
			configFrame:DoLock()
		end,
	})

	addConfigEntry(addon.aboutPanel.name, btnLockChatSettings, 20, -110, true, true)
	addon.aboutPanel.btnLockChatSettings = btnLockChatSettings

	if addon.IsRetail then
		local btnSocial = createCheckbutton(addon.aboutPanel, L.SocialInfo)
		bindToggle(btnSocial, "hideSocial", {
			messageOn = L.SocialOff,
			messageOff = L.SocialOn,
			showReload = true,
		})

		addConfigEntry(addon.aboutPanel.name, btnSocial, 20, -22)
		addon.aboutPanel.btnSocial = btnSocial

		local btnMoveSocialButton = createCheckbutton(addon.aboutPanel, L.MoveSocialButtonInfo)
		bindToggle(btnMoveSocialButton, "moveSocialButtonToBottom", {
			messageOn = L.MoveSocialButtonOn,
			messageOff = L.MoveSocialButtonOff,
			showReload = true,
		})

		addConfigEntry(addon.aboutPanel.name, btnMoveSocialButton, 45, -22)
		addon.aboutPanel.btnMoveSocialButton = btnMoveSocialButton

	end

	local btnChatMenu = createCheckbutton(addon.aboutPanel, L.ChatMenuButtonInfo)
	bindToggle(btnChatMenu, "hideChatMenuButton", {
		messageOn = L.ChatMenuButtonOff,
		messageOff = L.ChatMenuButtonOn,
		showReload = true,
	})

	addConfigEntry(addon.aboutPanel.name, btnChatMenu, 20, -22)
	addon.aboutPanel.btnChatMenu = btnChatMenu

	local btnScroll = createCheckbutton(addon.aboutPanel, L.ScrollInfo)
	bindToggle(btnScroll, "hideScroll", {
		messageOn = L.ScrollOff,
		messageOff = L.ScrollOn,
		showReload = true,
	})

	addConfigEntry(addon.aboutPanel.name, btnScroll, 20, -22)
	addon.aboutPanel.btnScroll = btnScroll

	local btnHideSideBars = createCheckbutton(addon.aboutPanel, L.HideScrollBarsInfo)
	bindToggle(btnHideSideBars, "hideSideButtonBars", {
		messageOn = L.HideScrollBarsOn,
		messageOff = L.HideScrollBarsOff,
		showReload = true,
	})
	
	addConfigEntry(addon.aboutPanel.name, btnHideSideBars, 20, -22)
	addon.aboutPanel.btnHideSideBars = btnHideSideBars

	local btnShortNames = createCheckbutton(addon.aboutPanel, L.ShortNamesInfo)
	bindToggle(btnShortNames, "shortNames", {
		messageOn = L.ShortNamesOn,
		messageOff = L.ShortNamesOff,
		showReload = true,
	})

	addConfigEntry(addon.aboutPanel.name, btnShortNames, 20, -22)
	addon.aboutPanel.btnShortNames = btnShortNames

	local btnEditBox = createCheckbutton(addon.aboutPanel, L.EditBoxInfo)
	bindToggle(btnEditBox, "editBoxTop", {
		messageOn = L.EditBoxTop,
		messageOff = L.EditBoxBottom,
		showReload = true,
	})

	addConfigEntry(addon.aboutPanel.name, btnEditBox, 20, -22)
	addon.aboutPanel.btnEditBox = btnEditBox

	local btnTabs = createCheckbutton(addon.aboutPanel, L.TabsInfo)
	bindToggle(btnTabs, "hideTabs", {
		messageOn = L.TabsOff,
		messageOff = L.TabsOn,
		showReload = true,
	})

	addConfigEntry(addon.aboutPanel.name, btnTabs, 20, -22)
	addon.aboutPanel.btnTabs = btnTabs

	local btnFontOutline = createCheckbutton(addon.aboutPanel, L.OutlineInfo)
	bindToggle(btnFontOutline, "addFontOutline", {
		messageOn = L.OutlineOn,
		messageOff = L.OutlineOff,
		showReload = true,
	})

	addConfigEntry(addon.aboutPanel.name, btnFontOutline, 20, -22)
	addon.aboutPanel.btnFontOutline = btnFontOutline

	local btnShadow = createCheckbutton(addon.aboutPanel, L.ShadowInfo)
	bindToggle(btnShadow, "addFontShadow", {
		messageOn = L.ShadowOn,
		messageOff = L.ShadowOff,
		showReload = true,
	})

	addConfigEntry(addon.aboutPanel.name, btnShadow, 45, -22)
	addon.aboutPanel.btnShadow = btnShadow

	local btnVoice = createCheckbutton(addon.aboutPanel, L.VoiceInfo)
	bindToggle(btnVoice, "hideVoice", {
		messageOn = L.VoiceOff,
		messageOff = L.VoiceOn,
		showReload = true,
	})

	addConfigEntry(addon.aboutPanel.name, btnVoice, 20, -22)
	addon.aboutPanel.btnVoice = btnVoice

	local btnEditBoxBorder = createCheckbutton(addon.aboutPanel, L.EditBoxBorderInfo)
	bindToggle(btnEditBoxBorder, "hideEditboxBorder", {
		messageOn = L.EditBoxBorderOff,
		messageOff = L.EditBoxBorderOn,
		showReload = true,
		onToggle = function()
			XCHT_DB.enableSimpleEditbox = false --turn this off
		end,
	})

	addConfigEntry(addon.aboutPanel.name, btnEditBoxBorder, 20, -22)
	addon.aboutPanel.btnEditBoxBorder = btnEditBoxBorder

	local btnSimpleEditBox = createCheckbutton(addon.aboutPanel, L.SimpleEditBoxInfo)
	bindToggle(btnSimpleEditBox, "enableSimpleEditbox", {
		messageOn = L.SimpleEditBoxOn,
		messageOff = L.SimpleEditBoxOff,
		showReload = true,
		onShow = function()
			setEnabled("checkbox", addon.aboutPanel.btnSEBDesign, XCHT_DB.enableSimpleEditbox)
		end,
		onToggle = function(value)
			XCHT_DB.hideEditboxBorder = false --turn this off
			setEnabled("checkbox", addon.aboutPanel.btnSEBDesign, value)
		end,
	})

	addConfigEntry(addon.aboutPanel.name, btnSimpleEditBox, 20, -22)
	addon.aboutPanel.btnSimpleEditBox = btnSimpleEditBox

	local btnSEBDesign = createCheckbutton(addon.aboutPanel, L.SEBDesignInfo)
	bindToggle(btnSEBDesign, "enableSEBDesign", {
		messageOn = L.SEBDesignOn,
		messageOff = L.SEBDesignOff,
		showReload = true,
	})

	addConfigEntry(addon.aboutPanel.name, btnSEBDesign, 45, -22)
	addon.aboutPanel.btnSEBDesign = btnSEBDesign

	local btnAdjustedEditbox = createCheckbutton(addon.aboutPanel, L.AdjustedEditboxInfo)
	bindToggle(btnAdjustedEditbox, "enableEditboxAdjusted", {
		messageOn = L.AdjustedEditboxOn,
		messageOff = L.AdjustedEditboxOff,
		showReload = true,
	})

	addConfigEntry(addon.aboutPanel.name, btnAdjustedEditbox, 20, -22)
	addon.aboutPanel.btnAdjustedEditbox = btnAdjustedEditbox

	local btnCopyPaste = createCheckbutton(addon.aboutPanel, L.CopyPasteInfo)
	bindToggle(btnCopyPaste, "enableCopyButton", {
		messageOn = L.CopyPasteOn,
		messageOff = L.CopyPasteOff,
		showReload = true,
		onShow = function()
			setEnabled("checkbox", addon.aboutPanel.btnCopyPasteLeft, XCHT_DB.enableCopyButton)
		end,
		onToggle = function(value)
			setEnabled("checkbox", addon.aboutPanel.btnCopyPasteLeft, value)
		end,
	})

	addConfigEntry(addon.aboutPanel.name, btnCopyPaste, 20, -22)
	addon.aboutPanel.btnCopyPaste = btnCopyPaste

	local btnCopyPasteLeft = createCheckbutton(addon.aboutPanel, L.CopyPasteLeftInfo)
	bindToggle(btnCopyPasteLeft, "enableCopyButtonLeft", {
		messageOn = L.CopyPasteLeftOn,
		messageOff = L.CopyPasteLeftOff,
		showReload = true,
	})

	addConfigEntry(addon.aboutPanel.name, btnCopyPasteLeft, 45, -22)
	addon.aboutPanel.btnCopyPasteLeft = btnCopyPasteLeft

	local btnChatTextFade = createCheckbutton(addon.aboutPanel, L.ChatTextFadeInfo)
	bindToggle(btnChatTextFade, "enableChatTextFade", {
		messageOn = L.ChatTextFadeOn,
		messageOff = L.ChatTextFadeOff,
		showReload = true,
	})

	addConfigEntry(addon.aboutPanel.name, btnChatTextFade, 20, -22)
	addon.aboutPanel.btnChatTextFade = btnChatTextFade

	local btnChatFrameFade = createCheckbutton(addon.aboutPanel, L.ChatFrameFadeInfo)
	bindToggle(btnChatFrameFade, "disableChatFrameFade", {
		messageOn = L.ChatFrameFadeOn,
		messageOff = L.ChatFrameFadeOff,
		showReload = true,
	})

	addConfigEntry(addon.aboutPanel.name, btnChatFrameFade, 20, -22)
	addon.aboutPanel.btnChatFrameFade = btnChatFrameFade

	--slider chat alpha
	local sliderChatAlpha = createSlider(addon.aboutPanel, L.ChatAlphaText, 0, 100)
	sliderChatAlpha:SetScript("OnShow", function()
		sliderChatAlpha:SetValue(floor(XCHT_DB.userChatAlpha * 100))
		sliderChatAlpha.currVal:SetText("("..floor(XCHT_DB.userChatAlpha * 100)..")")
	end)
	sliderChatAlpha.func = function(value)
		XCHT_DB.userChatAlpha = tonumber(value) / 100
		sliderChatAlpha:SetValue(floor(XCHT_DB.userChatAlpha * 100))
		sliderChatAlpha.currVal:SetText("("..floor(XCHT_DB.userChatAlpha * 100)..")")
		DEFAULT_CHAT_FRAME:AddMessage(string.format(L.ChatAlphaSet, floor(value)))
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

	addConfigEntry(addon.aboutPanel.name, sliderChatAlpha, 20, -45)
	addon.aboutPanel.sliderChatAlpha = sliderChatAlpha

	--do the lock settings onShow
	addon.aboutPanel:HookScript("OnShow", function()
		if XCHT_DB and XCHT_DB.lockChatSettings then
			--DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: "..L.LockChatSettingsAlert)
			configFrame:DoLock()
		end
	end)


	-------------------------------------------------------
	-------------------------------------------------------
	--ADDITIONAL SETTINGS


	local btnFilterList = createButton(addon.additionalSettings, L.EditFilterListHeader)
	btnFilterList.func = function()
		if addon.filterList then addon.filterList:Show() end
	end
	btnFilterList:SetScript("OnClick", btnFilterList.func)

	addConfigEntry(addon.additionalSettings.name, btnFilterList, 403, -20, true)
	addon.additionalSettings.btnFilterList = btnFilterList

	local btnOutWhisperColor = createCheckbutton(addon.additionalSettings, L.EnableOutWhisperColor)
	bindToggle(btnOutWhisperColor, "enableOutWhisperColor", {
		showReload = true,
		onToggle = function()
			addon:setOutWhisperColor()
		end,
	})

	addConfigEntry(addon.additionalSettings.name, btnOutWhisperColor, 20, -22, nil, nil, -70)
	addon.additionalSettings.btnOutWhisperColor = btnOutWhisperColor

	--color swatch
	local btnOutWhisperColorPicker = createColorPicker(addon.additionalSettings, XCHT_DB, "outWhisperColor", L.ChangeOutgoingWhisperColor)
	addConfigEntry(addon.additionalSettings.name, btnOutWhisperColorPicker, 20, -25)
	addon.additionalSettings.btnOutWhisperColorPicker = btnOutWhisperColorPicker

	local btnDisableChatEnterLeaveNotice = createCheckbutton(addon.additionalSettings, L.DisableChatEnterLeaveNotice)
	bindToggle(btnDisableChatEnterLeaveNotice, "disableChatEnterLeaveNotice", {
		onToggle = function()
			addon:setDisableChatEnterLeaveNotice()
		end,
	})

	addConfigEntry(addon.additionalSettings.name, btnDisableChatEnterLeaveNotice, 20, -30)
	addon.additionalSettings.btnDisableChatEnterLeaveNotice = btnDisableChatEnterLeaveNotice

	local btnPlayerChatStyle = createCheckbutton(addon.additionalSettings, L.PlayerChatStyleInfo)
	bindToggle(btnPlayerChatStyle, "enablePlayerChatStyle", {
		messageOn = L.PlayerChatStyleOn,
		messageOff = L.PlayerChatStyleOff,
	})

	addConfigEntry(addon.additionalSettings.name, btnPlayerChatStyle, 20, -30)
	addon.additionalSettings.btnPlayerChatStyle = btnPlayerChatStyle

	--slider page limit
	local sliderPageLimit = createSlider(addon.additionalSettings, L.PageLimitText, 0, 20)
	sliderPageLimit:SetScript("OnShow", function()
		sliderPageLimit:SetValue(floor(XCHT_DB.pageBufferLimit))
		sliderPageLimit.currVal:SetText("("..floor(XCHT_DB.pageBufferLimit)..")")
	end)
	sliderPageLimit.func = function(value)
		XCHT_DB.pageBufferLimit = floor(tonumber(value))
		sliderPageLimit:SetValue(floor(XCHT_DB.pageBufferLimit))
		sliderPageLimit.currVal:SetText("("..floor(XCHT_DB.pageBufferLimit)..")")
	end
	sliderPageLimit.sliderMouseUp = function(self, button)
		sliderPageLimit.func(sliderPageLimit:GetValue())
	end
	sliderPageLimit.sliderFunc = function(self, value)
		sliderPageLimit.currVal:SetText("("..floor(value)..")")
	end
	sliderPageLimit:SetScript("OnValueChanged", sliderPageLimit.sliderFunc)
	sliderPageLimit:SetScript("OnMouseUp", sliderPageLimit.sliderMouseUp)

	addConfigEntry(addon.additionalSettings.name, sliderPageLimit, 55, -55)
	addon.additionalSettings.sliderPageLimit = sliderPageLimit


	--do the lock for additional settings onShow as well
	addon.additionalSettings:HookScript("OnShow", function()
		if XCHT_DB and XCHT_DB.lockChatSettings then
			--DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: "..L.LockChatSettingsAlert)
			configFrame:DoLock()
		end
	end)
end

function configFrame:DoLock()
	local enabled = not (XCHT_DB and XCHT_DB.lockChatSettings)
	for i=1, #configObjList do
		configObjList[i]:SetEnabled(enabled)
	end
end
