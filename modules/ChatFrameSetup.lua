--[[
	ChatFrameSetup.lua - Chat frame initialization and configuration for XanChat
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

local function setupChatFrame(chatID)
	if not addon then return end

	if not chatID then return end

	local n = "ChatFrame" .. chatID
	local f = _G[n]
	local fTab = _G[n .. "Tab"]
	local editBox = _G[n .. "EditBox"]

	if f and not processedFrames[n] then
		-- Ensure new frames respect chat history size
		if f.SetMaxLines then
			local minLines = 2000
			if _G.C_CVar and _G.C_CVar.GetCVar then
				local cvar = tonumber(_G.C_CVar.GetCVar("chatMaxLines"))
				if cvar and cvar > minLines then
					minLines = cvar
				end
			end
			f:SetMaxLines(minLines)
		end

		-- Set alpha levels - NOTE: These are important, do not remove
		if _G.XCHT_DB and _G.XCHT_DB.disableChatFrameFade and _G.CHAT_FRAME_TEXTURES then
			local alpha = _G.XCHT_DB.userChatAlpha or _G.DEFAULT_CHATFRAME_ALPHA or 0.25
			for i = 1, #_G.CHAT_FRAME_TEXTURES do
				local object = _G[n .. _G.CHAT_FRAME_TEXTURES[i]]
				if object then
					object:SetAlpha(alpha)
				end
			end
		elseif _G.CHAT_FRAME_TEXTURES then
			for i = 1, #_G.CHAT_FRAME_TEXTURES do
				local object = _G[n .. _G.CHAT_FRAME_TEXTURES[i]]
				if object then
					object:SetAlpha(0)
				end
			end
		end

		-- Enable/disable chat text fading (different from frame fade)
		if _G.XCHT_DB and _G.XCHT_DB.enableChatTextFade then
			f:SetFading(true)
			f:SetTimeVisible(120)
		else
			f:SetFading(false)
		end

		-- Always lock the frames regardless
		if _G.SetChatWindowLocked then
			_G.SetChatWindowLocked(chatID, true)
		end
		if _G.FCF_SetLocked then
			_G.FCF_SetLocked(f, true)
		end

		-- Add font outlines or shadows
		if _G.XCHT_DB and (_G.XCHT_DB.addFontOutline or _G.XCHT_DB.addFontShadow) then
			local font, size = f:GetFont()
			if font then
				f:SetFont(font, size, "THINOUTLINE")
				-- Only apply this if we don't have shadows enabled
				if not _G.XCHT_DB.addFontShadow then
					f:SetShadowColor(0, 0, 0, 0)
				end
			end
		end

		-- Few changes
		f:EnableMouseWheel(true)
		if addon.scrollChat then
			f:SetScript('OnMouseWheel', addon.scrollChat)
		end
		f:SetClampRectInsets(0, 0, 0, 0)

		-- EditBox setup
		if editBox then
			-- Remove alt keypress from EditBox (no longer need alt to move around)
			editBox:SetAltArrowKeyMode(false)

			-- Check for editbox history
			local name = editBox:GetName()
			if _G.HistoryDB and _G.HistoryDB[name] then
				editBox.historyLines = _G.HistoryDB[name]
				editBox.historyIndex = 0

				editBox:HookScript("OnShow", function(self)
					self.historyIndex = 0
				end)

				local count = #_G.HistoryDB[name]
				if count > 0 then
					for dX = count, 1, -1 do
						if _G.HistoryDB[name][dX] then
							editBox:AddHistoryLine(_G.HistoryDB[name][dX])
						else
							break
						end
					end
				end

				if addon.AddEditBoxHistoryLine then
					addon:SecureHook(editBox, "AddHistoryLine", function(eb, text)
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

			-- EditBox design changes
			if not editBox.left then
				editBox.left = _G[n .. "EditBoxLeft"]
				editBox.right = _G[n .. "EditBoxRight"]
				editBox.mid = _G[n .. "EditBoxMid"]
			end

			local editBoxBackdrop
			if _G.XCHT_DB and _G.XCHT_DB.enableSEBDesign then
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
					edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
					insets = { left = 3, right = 3, top = 3, bottom = 3 }
				}
			end

			if _G.XCHT_DB and _G.XCHT_DB.enableSimpleEditbox then
				editBox.left:SetAlpha(0)
				editBox.right:SetAlpha(0)
				editBox.mid:SetAlpha(0)

				if not editBox.SetBackdrop and _G.Mixin and _G.BackdropTemplateMixin then
					_G.Mixin(editBox, _G.BackdropTemplateMixin)
				end

				if editBox.focusLeft then editBox.focusLeft:SetTexture(nil) end
				if editBox.focusRight then editBox.focusRight:SetTexture(nil) end
				if editBox.focusMid then editBox.focusMid:SetTexture(nil) end

				editBox:SetBackdrop(editBoxBackdrop)
				editBox:SetBackdropColor(0, 0, 0, 0.6)
				editBox:SetBackdropBorderColor(0.6, 0.6, 0.6)

			elseif _G.XCHT_DB and not _G.XCHT_DB.hideEditboxBorder then
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

			-- Do editbox positioning
			local spaceAdjusted = 0

			if _G.XCHT_DB and _G.XCHT_DB.editBoxTop then
				if _G.XCHT_DB.enableEditboxAdjusted then
					spaceAdjusted = 6
				end
				editBox:ClearAllPoints()
				editBox:SetPoint("BOTTOMLEFT", f, "TOPLEFT", -5, spaceAdjusted)
				editBox:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 5, spaceAdjusted)
			else
				if _G.XCHT_DB and _G.XCHT_DB.enableEditboxAdjusted then
					spaceAdjusted = -9
				end
				editBox:ClearAllPoints()
				editBox:SetPoint("TOPLEFT", f, "BOTTOMLEFT", -5, spaceAdjusted)
				editBox:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 5, spaceAdjusted)
			end

			-- When editbox is on the top, complications occur because sometimes you are not allowed to click on tabs
			-- To fix this we'll just make tab close editbox
			-- Also force the editbox to hide itself when it loses focus
			if fTab then
				fTab:HookScript("OnClick", function() editBox:Hide() end)
			end
			editBox:HookScript("OnEditFocusLost", function() editBox:Hide() end)
		end

		-- Create copy button for this chat frame
		if _G.XCHT_DB and _G.XCHT_DB.enableCopyButton and addon.createCopyChatButton then
			addon.createCopyChatButton(chatID, f)
		end

		-- Hide scroll bars
		if _G.XCHT_DB and _G.XCHT_DB.hideScroll then
			if f.ScrollBar then
				f.ScrollBar:Hide()
				f.ScrollBar:SetScript("OnShow", function() end)
			end
			if f.buttonFrame and f.buttonFrame.Background then
				f.buttonFrame.Background:SetTexture(nil)
				f.buttonFrame.Background:SetAlpha(0)
			end
			if f.buttonFrame and f.buttonFrame.minimizeButton then
				f.buttonFrame.minimizeButton:Hide()
				f.buttonFrame.minimizeButton:SetScript("OnShow", function() end)
			end
			if f.ScrollToBottomButton then
				f.ScrollToBottomButton:Hide()
				f.ScrollToBottomButton:SetScript("OnShow", function() end)
			end
		end

		if _G.XCHT_DB and _G.XCHT_DB.hideSideButtonBars then
			if f.buttonFrame then
				f.buttonFrame:Hide()
				f.buttonFrame:SetScript("OnShow", function() end)
			end
		end

		-- Force chat hide tabs on load
		if _G.XCHT_DB and _G.XCHT_DB.hideTabs and fTab then
			fTab.mouseOverAlpha = _G.CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA or 0.5
			fTab.noMouseAlpha = _G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA or 0.25
			if f.hasBeenFaded then
				fTab:SetAlpha(fTab.mouseOverAlpha)
			else
				fTab:SetAlpha(fTab.noMouseAlpha)
			end
		end

		-- Mark frame as processed
		processedFrames[n] = true
	end
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

