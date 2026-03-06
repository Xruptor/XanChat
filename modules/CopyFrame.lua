--[[
	CopyFrame.lua - Chat copy functionality for XanChat
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- STRING UNSCAPE FOR PROTECTED STRINGS
-- ============================================================================

local function unescape(str)

	--this is for testing for protected strings and only for officer chat, since even the text in officer chat is protected not just the officer name
	local isOfficerChat = false
	if string.find(str, "|Hchannel:officer", 1, true) then
		isOfficerChat = true
	end
	--str = string.gsub(str, "|c%x%x%x%x%x%x%x%x", "") --color tag 1
	--str = string.gsub(str, "|r", "") --color tag 2

    str = string.gsub(str, "|T.-|t", "") --textures in chat like currency coins and such
	str = string.gsub(str, "|H.-|h(.-)|h", "%1") --links, just put the item description and chat color
	str = string.gsub(str, "{.-}", "") --remove raid icons from chat

	--so apparently blizzard protects certain strings and returns them as textures.
	--this causes the insert for the multiline to break and not display the line.
	--such is the case for protected BNET Friends names and in some rare occasions names in the chat in general.
	--These protected strings start with |K and end with |k.   Example: |K[gsf][0-9]+|k[0]+|k
	--look under the link below for escape sequences

	--I want to point out that event addons like ElvUI suffer from  this problem.
	--They get around it by not displaying protected messages at ALL.  Check MessageIsProtected(message) in ElvUI

	if string.find(str, "|K", 1, true) then

		--str = string.gsub(str, "|K(.-)|k", "%1")
		local presenceID = string.match(str, "|K(.-)|k")
		local accountName
		local stripBNet

		if presenceID and _G.C_BattleNet and _G.BNGetNumFriends and _G.C_BattleNet.GetFriendAccountInfo then
			local numBNet = _G.BNGetNumFriends()
			for i = 1, numBNet do
				local accountInfo = _G.C_BattleNet.GetFriendAccountInfo(i)
				--only continue if we have a account info to work with
				if accountInfo and accountInfo.gameAccountInfo then
					--grab the bnet name of the account, it will have |K|k in it so again it will be hidden
					accountName = accountInfo.accountName
					--do we even have a battle.net tag to replace it with?
					if accountName and accountInfo.battleTag then
						--grab the presenceID from in between the |K|k tags
						accountName = string.gsub(accountName, "|K(.-)|k", "%1")
						--if it matches the one we found earlier, then replace it with a battle.net tag instead
						if accountName and accountName == presenceID then
							--don't show entire bnet tag just the name
							stripBNet = string.match(accountInfo.battleTag, "(.-)#")
							str = string.gsub(str, "|K(.-)|k", stripBNet or accountInfo.battleTag)
							--return out of here since we already did the replace
							--we don't want to go to the failsafe below
							return str
						end
					end
				end
			end
		end

		--something went wrong with replacing the name text for |K|k
		--so lets just remove it since it will not allow text to be inserted into the multiline box, since it will be empty and or hidden because |K|k returns a hidden textures
		--for protected strings.  That's why we are just going to remove it
		str = string.gsub(str, "|K(.-)|k", "%1")

		--add extra text for protected strings, to let folks know it's protected
		if isOfficerChat then

			str = str..(addon.L and addon.L.ProtectedChannel or " (Protected)")
		end
	end

    return str
end

-- ============================================================================
-- COPY FRAME CREATION
-- ============================================================================

local function createCopyFrame()
	if not addon then return nil end

	--check to see if we have the frame already, if we do then return it
	if addon.copyFrame then return addon.copyFrame end

	local copyFrame = _G.CreateFrame("FRAME", ADDON_NAME.."CopyFrame", _G.UIParent, _G.BackdropTemplateMixin and "BackdropTemplate")
	copyFrame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	})
	copyFrame:SetBackdropColor(0, 0, 0, 1)
	copyFrame:EnableMouse(true)
	copyFrame:SetMovable(true)
	copyFrame:RegisterForDrag("LeftButton")
	copyFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	copyFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	copyFrame:SetFrameStrata("DIALOG")
	copyFrame:SetPoint("CENTER", _G.UIParent, "CENTER", 0, 0)
	copyFrame:SetWidth(830)
	copyFrame:SetHeight(490)

	local title = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", copyFrame, "TOPLEFT", 20, -12)
	title:SetText(addon.L and addon.L.CopyChat or "Copy Chat")

	local scrollFrame = _G.CreateFrame("ScrollFrame", ADDON_NAME.."CopyScrollFrame", copyFrame, "ScrollingEditBoxTemplate")
	scrollFrame:SetPoint("TOPLEFT", 20, -38)
	scrollFrame:SetPoint("BOTTOMRIGHT", -35, 45)
	scrollFrame:EnableMouseWheel(true)
	if scrollFrame.SetPropagateMouseWheel then
		scrollFrame:SetPropagateMouseWheel(true)
	end

	local editBox = scrollFrame.EditBox or _G[scrollFrame:GetName().."EditBox"]
	if not editBox then
		editBox = _G.CreateFrame("EditBox", ADDON_NAME.."CopyEditBox", scrollFrame)
		scrollFrame:SetScrollChild(editBox)
	end
	editBox:SetAutoFocus(false)
	editBox:EnableMouse(true)
	editBox:EnableMouseWheel(true)
	if editBox.SetPropagateMouseWheel then
		editBox:SetPropagateMouseWheel(true)
	end
	editBox:EnableKeyboard(true)
	editBox:SetMultiLine(true)
	editBox:SetFontObject("ChatFontNormal")
	editBox:SetJustifyH("LEFT")
	editBox:SetJustifyV("TOP")
	editBox:SetTextInsets(4, 4, 4, 4)
	editBox:SetText("")
	if not editBox.SetBackdrop then
		_G.Mixin(editBox, _G.BackdropTemplateMixin)
	end
	editBox:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	})
	editBox:SetBackdropColor(0, 0, 0, 0.5)
	editBox:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
	editBox:HookScript("OnMouseDown", function(self) self:SetFocus() end)
	editBox:HookScript("OnMouseUp", function(self) self:SetFocus() end)
	editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

	local function UpdateEditSize()
		local width = scrollFrame:GetWidth() or 0
		if width > 0 then
			editBox:SetWidth(width)
		end
		if scrollFrame.UpdateScrollChildRect then
			scrollFrame:UpdateScrollChildRect()
		end
	end

	scrollFrame:HookScript("OnShow", UpdateEditSize)
	scrollFrame:HookScript("OnSizeChanged", UpdateEditSize)

	copyFrame.scrollFrame = scrollFrame
	copyFrame.editBox = editBox
	addon.copyFrame = copyFrame

	return copyFrame
end

-- ============================================================================
-- GET CHAT TEXT FOR COPYING
-- ============================================================================

local function getChatText(copyFrame, chatIndex, pageNum)
	if not addon or not copyFrame then return nil end

	local chatFrame = _G["ChatFrame" .. chatIndex]
	if not chatFrame then return nil end

	local maxLines = chatFrame:GetNumMessages() or 0
	if maxLines == 0 then return nil end

	local text = ""
	local startLine = pageNum and (pageNum - 1) * 500 + 1 or 1
	local endLine = math.min(startLine + 499, maxLines)

	for i = startLine, endLine do
		local lineInfo = chatFrame:GetMessageInfo(i)
		if lineInfo then
			local lineText = lineInfo.message or ""
			if lineText and lineText ~= "" then
				lineText = unescape(lineText)
				if lineText and lineText ~= "" then
					text = text .. lineText .. "\n"
				end
			end
		end
	end

	return text
end

-- ============================================================================
-- COPY CHAT BUTTON CREATION
-- ============================================================================

local function createCopyChatButton(chatIndex, chatFrame)
	if not addon or not chatFrame then return nil end

	local frameName = chatFrame:GetName()
	if not frameName then return nil end

	local buttonName = frameName .. "CopyChatButton"
	if _G[buttonName] then return _G[buttonName] end

	local button = _G.CreateFrame("BUTTON", buttonName, chatFrame)
	button:SetWidth(30)
	button:SetHeight(30)
	button:SetNormalTexture("Interface\\Buttons\\UI-Panel-MaximizeButton-Up")
	button:SetPushedTexture("Interface\\Buttons\\UI-Panel-MaximizeButton-Down")
	button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
	button:SetScript("OnClick", function()
		local frame = createCopyFrame()
		if not frame then return end

		local text = getChatText(frame, chatIndex, 1)
		if text then
			frame.editBox:SetText(text)
			frame.editBox:SetFocus()
			frame.editBox:HighlightText()
		end

		if not frame:IsShown() then
			frame:Show()
		else
			frame:Hide()
		end
	end)

	button:SetScript("OnEnter", function(self)
		if _G.GameTooltip then
			_G.GameTooltip:SetOwner(self, "ANCHOR_TOP")
			_G.GameTooltip:SetText(addon.L and addon.L.CopyChat or "Copy Chat", 1, 1, 1)
			_G.GameTooltip:Show()
		end
	end)

	button:SetScript("OnLeave", function()
		if _G.GameTooltip then
			_G.GameTooltip:Hide()
		end
	end)

	-- Position the button
	local leftButtonFrame
	if addon.IsRetail then
		leftButtonFrame = frameName .. "BottomButton"
	else
		leftButtonFrame = frameName .. "ResizeButton"
	end

	local offSetY = -5
	if addon.IsClassic or addon.IsWLK_C then
		--we have to move this as it will be on the scrollbars on classic
		offSetY = 60
	end

	if _G[leftButtonFrame] then
		button:SetPoint("TOPLEFT", _G[leftButtonFrame], "TOPLEFT", 5, offSetY)
	else
		button:SetPoint("TOPLEFT", chatFrame, "TOPLEFT", -30, offSetY)
	end
	button:Show()

	return button
end

-- ============================================================================
-- SETUP COPY FRAME FEATURE
-- ============================================================================

local function setupCopyFrameFeature()
	if not addon then return end

	if not _G.XCHT_DB or not _G.XCHT_DB.enableCopyButton then return end

	if _G.NUM_CHAT_WINDOWS then
		for i = 1, _G.NUM_CHAT_WINDOWS do
			local frameName = ("ChatFrame%d"):format(i)
			local frame = _G[frameName]
			if frame then
				createCopyChatButton(i, frame)
			end
		end
	end
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.unescape = unescape
addon.createCopyFrame = createCopyFrame
addon.getChatText = getChatText
addon.createCopyChatButton = createCopyChatButton
addon.setupCopyFrameFeature = setupCopyFrameFeature
