--[[
	ChatFrameSetup.lua - Chat frame initialization and configuration for XanChat
	Refactored for:
	- Consolidated redundant nil checks
	- Simplified frame setup logic
	- Better separation of concerns
	- Improved early returns
	- More efficient alpha and font handling
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- CHAT FRAME SETUP
-- ============================================================================

-- Table to track processed frames
local processedFrames = {}

-- ============================================================================
-- FRAME CONFIGURATION HELPERS
-- ============================================================================

-- Set max lines on a chat frame based on CVar and default
local function configureMaxLines(frame)
	if not frame.SetMaxLines then return end

	local minLines = 2000
	if _G.C_CVar and _G.C_CVar.GetCVar then
		local cvar = tonumber(_G.C_CVar.GetCVar("chatMaxLines"))
		if cvar and cvar > minLines then
			minLines = cvar
		end
	end
	frame:SetMaxLines(minLines)
end

-- Configure alpha levels on a chat frame
local function configureAlpha(frame, frameName)
	local alpha = _G.DEFAULT_CHATFRAME_ALPHA or 0.25

	if _G.XCHT_DB and _G.XCHT_DB.disableChatFrameFade then
		alpha = _G.XCHT_DB.userChatAlpha or alpha
	end

	if _G.CHAT_FRAME_TEXTURES then
		for i = 1, #_G.CHAT_FRAME_TEXTURES do
			local object = _G[frameName.._G.CHAT_FRAME_TEXTURES[i]]
			if object then
				object:SetAlpha(alpha)
			end
		end
	end
end

-- Configure text fading on a chat frame
local function configureFading(frame)
	if _G.XCHT_DB and _G.XCHT_DB.enableChatTextFade then
		frame:SetFading(true)
		frame:SetTimeVisible(120)
	else
		frame:SetFading(false)
	end
end

-- Configure frame locking
local function configureLocking(frame, chatID)
	if _G.SetChatWindowLocked then
		_G.SetChatWindowLocked(chatID, true)
	end
	if _G.FCF_SetLocked then
		_G.FCF_SetLocked(frame, true)
	end
end

-- Configure font effects (outline/shadow)
local function configureFont(frame)
	if not _G.XCHT_DB then return end

	if not (_G.XCHT_DB.addFontOutline or _G.XCHT_DB.addFontShadow) then return end

	local font, size = frame:GetFont()
	if not font then return end

	frame:SetFont(font, size, "THINOUTLINE")

	-- Only set shadow color if shadows are enabled
	if not _G.XCHT_DB.addFontShadow then
		frame:SetShadowColor(0, 0, 0, 0)
	end
end

-- Configure editbox design
local function configureEditbox(editBox, frameName, chatFrame)
	if not editBox then return end
	if not _G.XCHT_DB then return end

	-- Store references to editbox components
	if not editBox.left then
		editBox.left = _G[frameName.."EditBoxLeft"]
		editBox.right = _G[frameName.."EditBoxRight"]
		editBox.mid = _G[frameName.."EditBoxMid"]
	end

	-- Remove alt keypress from EditBox
	editBox:SetAltArrowKeyMode(false)

	-- Setup backdrop based on design option
	local editBoxBackdrop
	if _G.XCHT_DB.enableSEBDesign then
		editBoxBackdrop = {
			bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
			edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
			tile = true,
			tileSize = 16,
			edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 }
		}
	else
		editBoxBackdrop = {
			bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
			edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
			edgeSize = 16,
			insets = { left = 3, right = 3, top = 3, bottom = 3 }
		}
	end

	-- Apply backdrop mixin if needed (for newer WoW versions)
	if not editBox.SetBackdrop and _G.Mixin and _G.BackdropTemplateMixin then
		_G.Mixin(editBox, _G.BackdropTemplateMixin)
	end

	-- Apply simple editbox design or normal design
	if _G.XCHT_DB.enableSimpleEditbox then
		editBox.left:SetAlpha(0)
		editBox.right:SetAlpha(0)
		editBox.mid:SetAlpha(0)

		-- Clear focus textures to prevent overlapping borders
		if editBox.focusLeft then editBox.focusLeft:SetTexture(nil) end
		if editBox.focusRight then editBox.focusRight:SetTexture(nil) end
		if editBox.focusMid then editBox.focusMid:SetTexture(nil) end

		if editBox.SetBackdrop then
			editBox:SetBackdrop(editBoxBackdrop)
			editBox:SetBackdropColor(0, 0, 0, 0.6)
			editBox:SetBackdropBorderColor(0.6, 0.6, 0.6)
		end

	elseif not _G.XCHT_DB.hideEditboxBorder then
		if editBox.focusLeft then editBox.focusLeft:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Left2]]) end
		if editBox.focusRight then editBox.focusRight:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Right2]]) end
		if editBox.focusMid then editBox.focusMid:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Mid2]]) end
	else
		if editBox.focusLeft then editBox.focusLeft:SetTexture(nil) end
		if editBox.focusRight then editBox.focusRight:SetTexture(nil) end
		if editBox.focusMid then editBox.focusMid:SetTexture(nil) end
		editBox.left:SetAlpha(0)
		editBox.right:SetAlpha(0)
		editBox.mid:SetAlpha(0)
	end
end

-- Configure editbox positioning
local function configureEditboxPosition(editBox, chatFrame)
	if not editBox or not chatFrame then return end
	if not _G.XCHT_DB then return end

	local frameName = chatFrame:GetName()
	local frameTab = _G[frameName.."Tab"]

	local spaceAdjusted = _G.XCHT_DB and _G.XCHT_DB.enableEditboxAdjusted and -6 or 0

	editBox:ClearAllPoints()

	if _G.XCHT_DB.editBoxTop then
		editBox:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", -5, spaceAdjusted)
		editBox:SetPoint("BOTTOMRIGHT", chatFrame, "TOPRIGHT", 5, spaceAdjusted)
	else
		editBox:SetPoint("TOPLEFT", chatFrame, "BOTTOMLEFT", -5, spaceAdjusted)
		editBox:SetPoint("TOPRIGHT", chatFrame, "BOTTOMRIGHT", 5, spaceAdjusted)
	end

	-- When editbox is on top, tab click hides editbox
	if frameTab then
		frameTab:HookScript("OnClick", function() editBox:Hide() end)
	end
	editBox:HookScript("OnEditFocusLost", function() editBox:Hide() end)
end

-- Configure scroll bars visibility
local function configureScrollBars(chatFrame)
	if not chatFrame then return end
	if not _G.XCHT_DB then return end

	-- Hide scroll bars
	if _G.XCHT_DB.hideScroll then
		if chatFrame.ScrollBar then
			chatFrame.ScrollBar:Hide()
			chatFrame.ScrollBar:SetScript("OnShow", function() end)
		end
		if chatFrame.buttonFrame and chatFrame.buttonFrame.Background then
			chatFrame.buttonFrame.Background:SetTexture(nil)
			chatFrame.buttonFrame.Background:SetAlpha(0)
		end
		if chatFrame.buttonFrame and chatFrame.buttonFrame.minimizeButton then
			chatFrame.buttonFrame.minimizeButton:Hide()
			chatFrame.buttonFrame.minimizeButton:SetScript("OnShow", function() end)
		end
		if chatFrame.ScrollToBottomButton then
			chatFrame.ScrollToBottomButton:Hide()
			chatFrame.ScrollToBottomButton:SetScript("OnShow", function() end)
		end
	end

	-- Hide side button bars
	if _G.XCHT_DB.hideSideButtonBars and chatFrame.buttonFrame then
		chatFrame.buttonFrame:Hide()
		chatFrame.buttonFrame:SetScript("OnShow", function() end)
	end
end

-- Configure tabs visibility
local function configureTabs(chatFrame)
	if not chatFrame then return end
	if not _G.XCHT_DB or not _G.XCHT_DB.hideTabs then return end

	local frameName = chatFrame:GetName()
	local frameTab = _G[frameName.."Tab"]

	if frameTab then
		frameTab.mouseOverAlpha = _G.CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA or 0.5
		frameTab.noMouseAlpha = _G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA or 0.25
		if chatFrame.hasBeenFaded then
			frameTab:SetAlpha(frameTab.mouseOverAlpha)
		else
			frameTab:SetAlpha(frameTab.noMouseAlpha)
		end
	end
end

-- Setup editbox history hooks
local function setupEditboxHistory(editBox)
	if not editBox then return end

	local name = editBox:GetName()
	if not _G.HistoryDB then return end

	-- Initialize history array for this editbox if it doesn't exist
	_G.HistoryDB[name] = _G.HistoryDB[name] or {}
	editBox.historyLines = _G.HistoryDB[name]
	editBox.historyIndex = 0

	editBox:HookScript("OnShow", function(self)
		self.historyIndex = 0
	end)

	if addon.AddEditBoxHistoryLine then
		addon:SecureHook(editBox, "AddHistoryLine", function(eb)
			if eb then addon.AddEditBoxHistoryLine(eb) end
		end)
	end
	if addon.ClearEditBoxHistory then
		addon:SecureHook(editBox, "ClearHistory", function(eb)
			if eb then addon.ClearEditBoxHistory(eb) end
		end)
	end
	if addon.OnArrowPressed then
		editBox:HookScript("OnArrowPressed", function(self, key) addon.OnArrowPressed(self, key) end)
	end
end

-- ============================================================================
-- MAIN SETUP FUNCTION
-- ============================================================================

local function setupChatFrame(chatID)
	if not addon then return end
	if not chatID then return end

	local frameName = "ChatFrame"..chatID
	local f = _G[frameName]
	local editBox = _G[frameName.."EditBox"]

	if not f or processedFrames[frameName] then
		return
	end

	-- Configure frame properties
	configureMaxLines(f)
	configureAlpha(f, frameName)
	configureFading(f)
	configureLocking(f, chatID)
	configureFont(f)

	-- Basic frame settings
	f:EnableMouseWheel(true)
	if addon.scrollChat then
		f:SetScript('OnMouseWheel', addon.scrollChat)
	end
	f:SetClampRectInsets(0, 0, 0, 0)

	-- Configure editbox
	if editBox then
		setupEditboxHistory(editBox)
		configureEditbox(editBox, frameName, f)
		configureEditboxPosition(editBox, f)
	end

	-- Configure UI elements
	configureScrollBars(f)
	configureTabs(f)

	-- Create copy button if enabled
	if _G.XCHT_DB and _G.XCHT_DB.enableCopyButton and addon.createCopyChatButton then
		addon.createCopyChatButton(chatID, f)
	end

	-- Mark frame as processed
	processedFrames[frameName] = true
end

local function setupAllChatFrames()
	if not _G.NUM_CHAT_WINDOWS then return end

	for i = 1, _G.NUM_CHAT_WINDOWS do
		setupChatFrame(i)
	end
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.setupChatFrame = setupChatFrame
addon.setupAllChatFrames = setupAllChatFrames
