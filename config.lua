--[[
	config.lua - UI configuration system for XanChat
	Refactored for:
	- Simplified checkbox/button binding logic
	- Consolidated redundant nil checks
	- Better early returns
	- Improved slider handling
	- More efficient config object tracking
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

addon.configFrame = CreateFrame("frame", ADDON_NAME.."_config_eventFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
local configFrame = addon.configFrame
local L = addon.L
local floor = math.floor

-- Register static popup dialog for reload prompt
_G.StaticPopupDialogs["XANCHAT_APPLYCHANGES"] = _G.StaticPopupDialogs["XANCHAT_APPLYCHANGES"] or {
	text = L.ReloadRequired or "Some changes require reloading the UI to take effect.",
	button1 = _G.RELOADUI,
	button2 = _G.CANCEL,
	OnAccept = function()
		_G.ReloadUI()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}

-- Track configuration objects for lock functionality
local configObjList = {}
local lastObject = {}

-- ============================================================================
-- UI CREATION HELPERS
-- ============================================================================

local function addConfigEntry(frameParentName, objEntry, adjustX, adjustY, isCustom, ignoreLock, customStartYPoint)
	if not ignoreLock then
		table.insert(configObjList, objEntry)
	end

	objEntry:ClearAllPoints()

	if not isCustom then
		if not lastObject[frameParentName] then
			objEntry:SetPoint("TOPLEFT", 20, customStartYPoint or -135)
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

	local checkbutton = CreateFrame("CheckButton", ADDON_NAME.."_config_chkbtn_"..chkBoxIndex, parentFrame, "ChatConfigCheckButtonTemplate")
	local label = _G[checkbutton:GetName().."Text"]
	if label then
		label:SetText(" "..displayText)
	end

	return checkbutton
end

local buttonIndex = 0
local function createButton(parentFrame, displayText)
	buttonIndex = buttonIndex + 1

	local button = CreateFrame("Button", ADDON_NAME.."_config_button_"..buttonIndex, parentFrame, "UIPanelButtonTemplate")
	button:SetText(displayText)
	button:SetHeight(30)
	button:SetWidth(button:GetTextWidth() + 30)

	return button
end

local sliderIndex = 0
local function createSlider(parentFrame, displayText, minVal, maxVal)
	sliderIndex = sliderIndex + 1

	local SliderBackdrop = {
		bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
		edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
		tile = true, tileSize = 8, edgeSize = 8,
		insets = { left = 3, right = 3, top = 6, bottom = 6 }
	}

	local slider = CreateFrame("Slider", ADDON_NAME.."_config_slider_"..sliderIndex, parentFrame, BackdropTemplateMixin and "BackdropTemplate")
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

	-- Color conversion helpers
	local function ToRGBA(hex)
		return tonumber('0x'..string.sub(hex, 3, 4), 10) / 255,
			tonumber('0x'..string.sub(hex, 5, 6), 10) / 255,
			tonumber('0x'..string.sub(hex, 7, 8), 10) / 255,
			tonumber('0x'..string.sub(hex, 1, 2), 10) / 255
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
		dbObj[objName] = value
	end

	local Button = CreateFrame('Button', ADDON_NAME.."_config_colorpicker_"..colorPickerIndex, parentFrame, BackdropTemplateMixin and "BackdropTemplate")
	Button:SetSize(25, 25)
	Button:SetScript('OnClick', function(self)
		local r, g, b, a = ToRGBA(dbObj[objName])
		ColorPickerFrame:SetColorRGB(r or 1, g or 1, b or 1)
		ColorPickerFrame.opacity = 1
		ColorPickerFrame.hasOpacity = false
		ColorPickerFrame.func = function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			Update(self, ToHex(r, g, b, 1))
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

	Update(Button, dbObj[objName])

	return Button
end

-- ============================================================================
-- UI STATE MANAGEMENT
-- ============================================================================

local function setEnabled(objType, obj, switch)
	if objType == "checkbox" and obj then
		obj:SetEnabled(switch)
		if obj.Text then
			obj.Text:SetTextColor(switch and 1 or 0.5, switch and 1 or 0.5, switch and 1 or 0.5)
		end
	end
end

local function showReloadPopup()
	StaticPopup_Show("XANCHAT_APPLYCHANGES")
end

local function bindToggle(btn, key, opts)
	opts = opts or {}

	btn:SetScript("OnShow", function()
		btn:SetChecked(XCHT_DB[key])
		if opts.onShow then opts.onShow(btn) end
	end)

	btn.func = function()
		XCHT_DB[key] = not XCHT_DB[key]
		if opts.onToggle then opts.onToggle(not XCHT_DB[key], btn) end
		if opts.messageOn or opts.messageOff then
			DEFAULT_CHAT_FRAME:AddMessage(XCHT_DB[key] and opts.messageOn or opts.messageOff)
		end
		if opts.showReload then
			showReloadPopup()
		end
	end
	btn:SetScript("OnClick", btn.func)
end

-- ============================================================================
-- FRAME CREATION
-- ============================================================================

local function LoadAboutFrame()
	local about = CreateFrame("Frame", ADDON_NAME.."AboutPanel", InterfaceOptionsFramePanelContainer, BackdropTemplateMixin and "BackdropTemplate")
	about.name = ADDON_NAME
	about:Hide()

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
	for _, field in ipairs({"Version", "Author"}) do
		local val = getMetadata and getMetadata(ADDON_NAME, field)
		if val then
			local titleLabel = about:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			titleLabel:SetWidth(75)
			if not anchor then
				titleLabel:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", -2, -8)
			else
				titleLabel:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
			end
			titleLabel:SetJustifyH("RIGHT")
			titleLabel:SetText(field:gsub("X%-", ""))

			local detailLabel = about:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			detailLabel:SetPoint("LEFT", titleLabel, "RIGHT", 4, 0)
			detailLabel:SetPoint("RIGHT", -16, 0)
			detailLabel:SetJustifyH("LEFT")
			detailLabel:SetText(val)

			anchor = titleLabel
		end
	end

	if InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(about)
	else
		local category = _G.Settings.RegisterCanvasLayoutCategory(about, about.name)
		_G.Settings.RegisterAddOnCategory(category)
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
	addSettings.parent = parentFrameName
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
	elseif addon.settingsCategory then
		local subcategory = _G.Settings.RegisterCanvasLayoutSubcategory(addon.settingsCategory, addSettings, addSettings.name)
		addon.addSettingsCategory = subcategory
	end

	return addSettings
end

-- ============================================================================
-- MAIN ENABLE FUNCTION
-- ============================================================================

function configFrame:EnableConfig()
	addon.aboutPanel = LoadAboutFrame()
	addon.additionalSettings = LoadAdditionalSettings(L.AdditionalSettings, ADDON_NAME)

	-- Sticky Channels List button
	local btnStickyChannelsList = createButton(addon.aboutPanel, L.EditStickyChannelsListHeader)
	btnStickyChannelsList:SetScript("OnClick", function()
		if addon.stickyChannelsList then addon.stickyChannelsList:Show() end
	end)
	addConfigEntry(addon.aboutPanel.name, btnStickyChannelsList, 403, -20, true)
	addon.aboutPanel.btnStickyChannelsList = btnStickyChannelsList

	-- Lock Chat Settings checkbox
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

	-- Retail-only options
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

	-- Common chat options
	local options = {
		{ key = "hideChatMenuButton", info = L.ChatMenuButtonInfo, messageOn = L.ChatMenuButtonOff, messageOff = L.ChatMenuButtonOn, reload = true },
		{ key = "hideScroll", info = L.ScrollInfo, messageOn = L.ScrollOff, messageOff = L.ScrollOn, reload = true },
		{ key = "hideSideButtonBars", info = L.HideScrollBarsInfo, messageOn = L.HideScrollBarsOn, messageOff = L.HideScrollBarsOff, reload = true },
		{ key = "shortNames", info = L.ShortNamesInfo, messageOn = L.ShortNamesOn, messageOff = L.ShortNamesOff, reload = true },
		{ key = "editBoxTop", info = L.EditBoxInfo, messageOn = L.EditBoxTop, messageOff = L.EditBoxBottom, reload = true },
		{ key = "hideTabs", info = L.TabsInfo, messageOn = L.TabsOff, messageOff = L.TabsOn, reload = true },
		{ key = "addFontOutline", info = L.OutlineInfo, messageOn = L.OutlineOn, messageOff = L.OutlineOff, reload = true },
		{ key = "addFontShadow", info = L.ShadowInfo, messageOn = L.ShadowOn, messageOff = L.ShadowOff, reload = true, adjustX = 45 },
		{ key = "hideVoice", info = L.VoiceInfo, messageOn = L.VoiceOff, messageOff = L.VoiceOn, reload = true },
		{ key = "hideEditboxBorder", info = L.EditBoxBorderInfo, messageOn = L.EditBoxBorderOff, messageOff = L.EditBoxBorderOn, reload = true, onToggle = function() XCHT_DB.enableSimpleEditbox = false end },
		{ key = "enableSimpleEditbox", info = L.SimpleEditBoxInfo, messageOn = L.SimpleEditBoxOn, messageOff = L.SimpleEditBoxOff, reload = true, onShow = function(_) setEnabled("checkbox", addon.aboutPanel.btnSEBDesign, XCHT_DB.enableSimpleEditbox) end, onToggle = function(val, _) XCHT_DB.hideEditboxBorder = false setEnabled("checkbox", addon.aboutPanel.btnSEBDesign, val) end },
		{ key = "enableSEBDesign", info = L.SEBDesignInfo, messageOn = L.SEBDesignOn, messageOff = L.SEBDesignOff, reload = true, adjustX = 45 },
		{ key = "enableEditboxAdjusted", info = L.AdjustedEditboxInfo, messageOn = L.AdjustedEditboxOn, messageOff = L.AdjustedEditboxOff, reload = true },
		{ key = "enableCopyButton", info = L.CopyPasteInfo, messageOn = L.CopyPasteOn, messageOff = L.CopyPasteOff, reload = true, onShow = function(_) setEnabled("checkbox", addon.aboutPanel.btnCopyPasteLeft, XCHT_DB.enableCopyButton) end, onToggle = function(val, _) setEnabled("checkbox", addon.aboutPanel.btnCopyPasteLeft, val) end },
		{ key = "enableCopyButtonLeft", info = L.CopyPasteLeftInfo, messageOn = L.CopyPasteLeftOn, messageOff = L.CopyPasteLeftOff, reload = true, adjustX = 45 },
		{ key = "enableChatTextFade", info = L.ChatTextFadeInfo, messageOn = L.ChatTextFadeOn, messageOff = L.ChatTextFadeOff, reload = true },
		{ key = "disableChatFrameFade", info = L.ChatFrameFadeInfo, messageOn = L.ChatFrameFadeOn, messageOff = L.ChatFrameFadeOff, reload = true },
	}

	-- Create all options on MAIN panel
	for _, opt in ipairs(options) do
		local btn = createCheckbutton(addon.aboutPanel, opt.info)
		bindToggle(btn, opt.key, {
			messageOn = opt.messageOn,
			messageOff = opt.messageOff,
			showReload = opt.reload,
			onToggle = opt.onToggle,
			onShow = opt.onShow,
		})
		addConfigEntry(addon.aboutPanel.name, btn, opt.adjustX or 20, -22)
		addon.aboutPanel["btn"..opt.key] = btn
	end

	-- Chat Alpha slider (on MAIN panel as in original 012dff0)
	local sliderChatAlpha = createSlider(addon.aboutPanel, L.ChatAlphaText, 0, 100)
	sliderChatAlpha:SetScript("OnShow", function()
		local val = floor(XCHT_DB.userChatAlpha * 100)
		sliderChatAlpha:SetValue(val)
		sliderChatAlpha.currVal:SetText("("..val..")")
	end)
	sliderChatAlpha.func = function(value)
		XCHT_DB.userChatAlpha = tonumber(value) / 100
		local val = floor(XCHT_DB.userChatAlpha * 100)
		sliderChatAlpha:SetValue(val)
		sliderChatAlpha.currVal:SetText("("..val..")")
		DEFAULT_CHAT_FRAME:AddMessage(string.format(L.ChatAlphaSet, val))
		addon:setUserAlpha()
	end
	sliderChatAlpha.sliderMouseUp = function()
		sliderChatAlpha.func(sliderChatAlpha:GetValue())
	end
	sliderChatAlpha.sliderFunc = function(_, value)
		sliderChatAlpha.currVal:SetText("("..floor(value)..")")
	end
	sliderChatAlpha:SetScript("OnValueChanged", sliderChatAlpha.sliderFunc)
	sliderChatAlpha:SetScript("OnMouseUp", sliderChatAlpha.sliderMouseUp)
	addConfigEntry(addon.aboutPanel.name, sliderChatAlpha, 20, -45)
	addon.aboutPanel.sliderChatAlpha = sliderChatAlpha

	-- Hook OnShow to apply lock
	addon.aboutPanel:HookScript("OnShow", function()
		if XCHT_DB and XCHT_DB.lockChatSettings then
			configFrame:DoLock()
		end
	end)

	-- ============================================================================
	-- ADDITIONAL SETTINGS
	-- ============================================================================

	-- Filter List button
	local btnFilterList = createButton(addon.additionalSettings, L.EditFilterListHeader)
	btnFilterList:SetScript("OnClick", function()
		if addon.filterList then addon.filterList:Show() end
	end)
	addConfigEntry(addon.additionalSettings.name, btnFilterList, 403, -20, true)
	addon.additionalSettings.btnFilterList = btnFilterList

	-- Outgoing Whisper Color
	local btnOutWhisperColor = createCheckbutton(addon.additionalSettings, L.EnableOutWhisperColor)
	bindToggle(btnOutWhisperColor, "enableOutWhisperColor", {
		showReload = true,
		onToggle = function()
			addon:setOutWhisperColor()
		end,
	})
	addConfigEntry(addon.additionalSettings.name, btnOutWhisperColor, 20, -22, nil, nil, -70)
	addon.additionalSettings.btnOutWhisperColor = btnOutWhisperColor

	-- Color picker
	local btnOutWhisperColorPicker = createColorPicker(addon.additionalSettings, XCHT_DB, "outWhisperColor", L.ChangeOutgoingWhisperColor)
	addConfigEntry(addon.additionalSettings.name, btnOutWhisperColorPicker, 20, -25)
	addon.additionalSettings.btnOutWhisperColorPicker = btnOutWhisperColorPicker

	-- Disable Chat Enter/Leave Notice
	local btnDisableChatEnterLeaveNotice = createCheckbutton(addon.additionalSettings, L.DisableChatEnterLeaveNotice)
	bindToggle(btnDisableChatEnterLeaveNotice, "disableChatEnterLeaveNotice", {
		onToggle = function()
			addon:setDisableChatEnterLeaveNotice()
		end,
	})
	addConfigEntry(addon.additionalSettings.name, btnDisableChatEnterLeaveNotice, 20, -30)
	addon.additionalSettings.btnDisableChatEnterLeaveNotice = btnDisableChatEnterLeaveNotice

	-- Player Chat Style
	local btnPlayerChatStyle = createCheckbutton(addon.additionalSettings, L.PlayerChatStyleInfo)
	bindToggle(btnPlayerChatStyle, "enablePlayerChatStyle", {
		messageOn = L.PlayerChatStyleOn,
		messageOff = L.PlayerChatStyleOff,
	})
	addConfigEntry(addon.additionalSettings.name, btnPlayerChatStyle, 20, -30)
	addon.additionalSettings.btnPlayerChatStyle = btnPlayerChatStyle

	-- Page Limit slider
	local sliderPageLimit = createSlider(addon.additionalSettings, L.PageLimitText, 0, 20)
	sliderPageLimit:SetScript("OnShow", function()
		local val = floor(XCHT_DB.pageBufferLimit)
		sliderPageLimit:SetValue(val)
		sliderPageLimit.currVal:SetText("("..val..")")
	end)
	sliderPageLimit.func = function(value)
		XCHT_DB.pageBufferLimit = floor(tonumber(value))
		local val = floor(XCHT_DB.pageBufferLimit)
		sliderPageLimit:SetValue(val)
		sliderPageLimit.currVal:SetText("("..val..")")
	end
	sliderPageLimit.sliderMouseUp = function()
		sliderPageLimit.func(sliderPageLimit:GetValue())
	end
	sliderPageLimit.sliderFunc = function(_, value)
		sliderPageLimit.currVal:SetText("("..floor(value)..")")
	end
	sliderPageLimit:SetScript("OnValueChanged", sliderPageLimit.sliderFunc)
	sliderPageLimit:SetScript("OnMouseUp", sliderPageLimit.sliderMouseUp)
	addConfigEntry(addon.additionalSettings.name, sliderPageLimit, 55, -55)
	addon.additionalSettings.sliderPageLimit = sliderPageLimit

	-- Hook OnShow to apply lock
	addon.additionalSettings:HookScript("OnShow", function()
		if XCHT_DB and XCHT_DB.lockChatSettings then
			configFrame:DoLock()
		end
	end)
end

function configFrame:DoLock()
	local enabled = not (XCHT_DB and XCHT_DB.lockChatSettings)
	for _, obj in ipairs(configObjList) do
		obj:SetEnabled(enabled)
	end
end
