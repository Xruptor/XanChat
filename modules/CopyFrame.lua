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

    str = string.gsub(str, "|T.-|t", "") --textures in chat like currency coins and such
	str = string.gsub(str, "|H.-|h(.-)|h", "%1") --links, just put the item description and chat color
	str = string.gsub(str, "{.-}", "") --remove raid icons from chat
	str = string.gsub(str,"||","««")

	--so apparently blizzard protects certain strings and returns them as textures.
	--this causes the insert for the multiline to break and not display the line.
	--such is the case for protected BNET Friends names and in some rare occasions names in the chat in general.
	--These protected strings start with |K and end with |k.   Example: |K[gsf][0-9]+|k[0]+|k
	--look under the link below for escape sequences

	--I want to point out that event addons like ElvUI suffer from  this problem.
	--They get around it by not displaying protected messages at ALL.  Check MessageIsProtected(message) in ElvUI

	if string.find(str, "|K", 1, true) then
		local kStart, kNum, _, kInfo = string.match(str, "(.-)|K(.-)|k(.-)|k(.+)")
		if kNum then
			if kStart and kStart ~= "" then
				str = kStart.."-BNET-"..kNum
			else
				str = "-BNET-"..kNum
			end
			if kInfo and kInfo ~= "" then
				str = str..kInfo
			end
			if string.find(str, "|K", 1, true) then
				str = unescape(str)
			end
		end
	end

	-- protect safe |cFFxxxxxx color codes and |r resets before blanket | replacement
	local PIPE_PH = "\001"
	str = string.gsub(str, "|c(%x%x%x%x%x%x%x%x)", PIPE_PH.."c%1")
	str = string.gsub(str, "|r", PIPE_PH.."r")

	--remove remaining unsafe pipe symbols
	if (string.find(str, "|")) then
		str = string.gsub(str, "|", "¦")
	end

	-- restore safe color codes so they render in the copy frame
	str = string.gsub(str, PIPE_PH, "|")

	--add extra text for protected strings, to let folks know it's protected
	if isOfficerChat then
		str = str..(addon.L and addon.L.ProtectedChannel or " (Protected)")
	end

    return str
end

-- ============================================================================
-- GET CHAT TEXT FOR COPYING
-- ============================================================================

local function RGBToColorCode(r, g, b)
	return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

local function getChatText(copyFrame, chatIndex, pageNum)
	copyFrame.MLEditBox:SetText("") -- clear it first in case there were previous messages
	copyFrame.currChatIndex = chatIndex

	local chatFrame = _G["ChatFrame"..chatIndex]
	if not chatFrame then return end

	-- the editbox of the multiline editbox (The parent of the multiline object)
	local parentEditBox = copyFrame.MLEditBox.editBox

	-- there is a hard limit of text that can be highlighted in an editbox to 500 lines.
	local MAXLINES = 150 -- 150 don't use large numbers or it will cause LAG when frame opens.  EditBox was not made for large amounts of text
	local msgCount = chatFrame:GetNumMessages()
	local startPos = 0
	local endPos = 0
	local lineText

	-- lets create the pages
	local pages = {}
	for i = 1, msgCount, MAXLINES do
		pages[#pages + 1] = i
	end

	-- check for custom buffer limit by the user, ignore if it's set to zero
	if _G.XCHT_DB and _G.XCHT_DB.pageBufferLimit > 0 and #pages > _G.XCHT_DB.pageBufferLimit then
		local counter = 0
		local tmpPages = {}
		for i = #pages, 1, -1 do
			counter = counter + 1
			if counter <= _G.XCHT_DB.pageBufferLimit then
				tmpPages[#tmpPages + 1] = pages[i]
			else
				break
			end
		end
		pages = tmpPages
	end

	-- load past page if we don't have a pageNum
	if not pageNum and startPos < 1 then
		if msgCount > MAXLINES then
			startPos = msgCount - MAXLINES
			endPos = startPos + MAXLINES
		else
			startPos = 1
			endPos = msgCount
		end
	-- otherwise load the page number
	elseif pageNum and pages[pageNum] then
		if pages[pageNum] == 1 then
			-- first page
			startPos = 1
			endPos = MAXLINES
		else
			startPos = pages[pageNum]
			endPos = pages[pageNum] + MAXLINES
		end
	else
		print("XanChat: "..(addon.L and addon.L.CopyChatError or "Copy Chat Error"))
		return
	end

	-- adjust the endPos if it's greater than the total messages we have
	if endPos > msgCount then endPos = msgCount end

	for i = startPos, endPos do
		local chatMsg = chatFrame:GetMessageInfo(i)
		if not chatMsg then break end

		--check for secret values strings
		chatMsg = (addon.safestr_bool(chatMsg) and addon.L.ProtectedSecretValue) or chatMsg

		if (i == startPos) then
			lineText = unescape(chatMsg).."|r"
		else
			lineText = "\n"..unescape(chatMsg).."|r"
		end

		parentEditBox:Insert(lineText)
	end

	if pageNum then
		copyFrame.currentPage = pageNum
	else
		copyFrame.currentPage = #pages
	end

	copyFrame.pages = pages
	copyFrame.pageNumText:SetText((addon.L and addon.L.Page or "Page").." "..copyFrame.currentPage)

	copyFrame.handleCursorChange = true -- just in case
	copyFrame:Show()
end

-- ============================================================================
-- COPY FRAME CREATION
-- ============================================================================

local function createCopyFrame()
	-- check to see if we have the frame already, if we do then return it
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

	editBox:SetScript("OnTextChanged", UpdateEditSize)
	scrollFrame:HookScript("OnSizeChanged", UpdateEditSize)
	UpdateEditSize()

	local scrollBar = scrollFrame.ScrollBar or _G[scrollFrame:GetName().."ScrollBar"]
	if not scrollBar then
		scrollBar = _G.CreateFrame("Slider", ADDON_NAME.."CopyScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
		scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
		scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
		scrollBar:SetValueStep(20)
		scrollBar:SetObeyStepOnDrag(true)
		scrollFrame.ScrollBar = scrollBar
		scrollBar:SetScript("OnValueChanged", function(self, value)
			scrollFrame:SetVerticalScroll(value)
		end)
	end
	if scrollBar then
		scrollFrame:HookScript("OnScrollRangeChanged", function(self, xRange, yRange)
			local maxVal = math.max(0, yRange or 0)
			scrollBar:SetMinMaxValues(0, maxVal)
			scrollBar:SetShown(maxVal > 0)
		end)
		scrollBar:Show()
	end

	local function ScrollCopyFrame(delta)
		if scrollBar then
			local step = scrollBar:GetValueStep() or 20
			local minVal, maxVal = scrollBar:GetMinMaxValues()
			local newVal = scrollBar:GetValue() - (delta * step)
			if newVal < minVal then newVal = minVal end
			if newVal > maxVal then newVal = maxVal end
			scrollBar:SetValue(newVal)
		else
			local cur = scrollFrame:GetVerticalScroll()
			local max = scrollFrame:GetVerticalScrollRange()
			local newVal = cur - (delta * 20)
			if newVal < 0 then newVal = 0 end
			if newVal > max then newVal = max end
			scrollFrame:SetVerticalScroll(newVal)
		end
	end

	scrollFrame:SetScript("OnMouseWheel", function(self, delta) ScrollCopyFrame(delta) end)
	if scrollFrame.ScrollBox then
		scrollFrame.ScrollBox:EnableMouseWheel(true)
		scrollFrame.ScrollBox:SetScript("OnMouseWheel", function(self, delta) ScrollCopyFrame(delta) end)
	end
	editBox:SetScript("OnMouseWheel", function(self, delta) ScrollCopyFrame(delta) end)
	copyFrame:EnableMouseWheel(true)
	copyFrame:SetScript("OnMouseWheel", function(self, delta) ScrollCopyFrame(delta) end)

	local MLEditBox = {
		editBox = editBox,
		scrollFrame = scrollFrame,
		scrollBar = scrollBar,
		SetText = function(self, text)
			self.editBox:SetText(text or "")
			UpdateEditSize()
		end,
		GetText = function(self)
			return self.editBox:GetText()
		end,
		SetCursorPosition = function(self, pos)
			self.editBox:SetCursorPosition(pos)
		end,
		ClearFocus = function(self)
			self.editBox:ClearFocus()
		end,
		SetFocus = function(self)
			self.editBox:SetFocus()
		end,
	}
	copyFrame.MLEditBox = MLEditBox

	copyFrame.handleCursorChange = false -- setting this to true will update the scrollbar to the cursor position
	scrollFrame:HookScript("OnUpdate", function(self, elapsed)
		if not scrollFrame:IsVisible() then return end

		self.OnUpdateCounter = (self.OnUpdateCounter or 0) + elapsed
		if self.OnUpdateCounter < 0.1 then return end
		self.OnUpdateCounter = 0

		local pos = editBox:GetNumLetters()

		if copyFrame.handleCursorChange then
			editBox:SetFocus()
			editBox:SetCursorPosition(pos)
			editBox:ClearFocus()
			if scrollBar then
				local _, statusMax = scrollBar:GetMinMaxValues()
				scrollBar:SetValue(statusMax)
			else
				scrollFrame:SetVerticalScroll(scrollFrame:GetVerticalScrollRange())
			end
			copyFrame.handleCursorChange = false
		end
	end)
	copyFrame:HookScript("OnShow", function() copyFrame.handleCursorChange = true end)

	local close = _G.CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
	close:SetScript("OnClick", function() copyFrame:Hide() end)
	close:SetPoint("BOTTOMRIGHT", -27, 13)
	close:SetFrameLevel(close:GetFrameLevel() + 1)
	close:SetHeight(20)
	close:SetWidth(100)
	close:SetText(addon.L and addon.L.Done or "Done")

	local buttonBack = _G.CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
	buttonBack:SetText("<")
	buttonBack:SetHeight(25)
	buttonBack:SetWidth(25)
	buttonBack:SetPoint("BOTTOMLEFT", 10, 13)
	buttonBack:SetFrameLevel(buttonBack:GetFrameLevel() + 1)
	buttonBack:SetScript("OnClick", function()
		if copyFrame.currChatIndex and copyFrame.currentPage and copyFrame.pages then
			if (copyFrame.currentPage - 1) >= 1 then
				getChatText(copyFrame, copyFrame.currChatIndex, copyFrame.currentPage - 1)
			end
		end
	end)
	copyFrame.buttonBack = buttonBack

	local buttonForward = _G.CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
	buttonForward:SetText(">")
	buttonForward:SetHeight(25)
	buttonForward:SetWidth(25)
	buttonForward:SetPoint("BOTTOMLEFT", 40, 13)
	buttonForward:SetFrameLevel(buttonForward:GetFrameLevel() + 1)
	buttonForward:SetScript("OnClick", function()
		if copyFrame.currChatIndex and copyFrame.currentPage and copyFrame.pages then
			if (copyFrame.currentPage + 1) <= #copyFrame.pages then
				getChatText(copyFrame, copyFrame.currChatIndex, copyFrame.currentPage + 1)
			end
		end
	end)
	copyFrame.buttonForward = buttonForward

	-- this is to place it above the group layer
	local pageNumText = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	pageNumText:SetPoint("BOTTOMLEFT", 80, 18)
	pageNumText:SetShadowOffset(1, -1)
	pageNumText:SetText((addon.L and addon.L.Page or "Page").." 1")
	copyFrame.pageNumText = pageNumText

	copyFrame:Hide()

	-- store it for the future
	addon.copyFrame = copyFrame

	return copyFrame
end

-- ============================================================================
-- COPY CHAT BUTTON CREATION
-- ============================================================================

local function createCopyChatButton(chatIndex, chatFrame)
	if not addon or not chatFrame then return nil end

	local frameName = chatFrame:GetName()
	if not frameName then return nil end

	local buttonName = frameName.."CopyChatButton"
	if _G[buttonName] then return _G[buttonName] end

	local button = _G.CreateFrame("BUTTON", buttonName, chatFrame, _G.BackdropTemplateMixin and "BackdropTemplate")
	button:SetParent(chatFrame)
	button:SetWidth(18)
	button:SetHeight(18)
	button:SetNormalTexture("Interface\\AddOns\\xanChat\\media\\copy")
	button:SetHighlightTexture("Interface\\AddOns\\xanChat\\media\\copyhighlight")
	button:SetPushedTexture("Interface\\AddOns\\xanChat\\media\\copy")
	button:SetFrameLevel(7)
	button:SetScript("OnClick", function()
		local copyFrame = createCopyFrame()
		if not copyFrame then return end

		getChatText(copyFrame, chatIndex)
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
	if not _G.XCHT_DB or not _G.XCHT_DB.enableCopyButtonLeft then
		button:SetPoint("BOTTOMRIGHT", -2, -3)

		chatFrame:HookScript("OnEnter", function(self)
			button:Show()
		end)
		chatFrame:HookScript("OnLeave", function(self)
			button:Hide()
		end)
		if chatFrame.ScrollToBottomButton then
			chatFrame.ScrollToBottomButton:HookScript("OnEnter", function(self)
				button:Show()
			end)
			chatFrame.ScrollToBottomButton:HookScript("OnLeave", function(self)
				button:Hide()
			end)
		end

		-- Prevent object blinking because chat continues to scroll
		button.show = function() button:Show() end
		button.hide = function() button:Hide() end

		button:SetScript("OnEnter", button.show)
		button:SetScript("OnLeave", button.hide)

	else
		local leftButtonFrame = frameName.."ButtonFrame"

		local offSetY = -50
		if not addon.IsRetail and not _G.XCHT_DB.hideScroll then
			--we have to move this as it will be on the scrollbars on classic
			offSetY = 60
		end

		if _G[leftButtonFrame] then
			button:SetPoint("TOPLEFT", _G[leftButtonFrame], "TOPLEFT", 5, offSetY)
		else
			button:SetPoint("TOPLEFT", chatFrame, "TOPLEFT", -30, offSetY)
		end
		button:Show()
	end

	return button
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.unescape = unescape
addon.createCopyFrame = createCopyFrame
addon.getChatText = getChatText
addon.createCopyChatButton = createCopyChatButton
