--[[
	ChatSettings.lua - Settings save/restore system for XanChat
	Improvements:
	- Simplified saveLayout with better early returns
	- Consolidated window info operations in restoreSettings
	- Reduced redundant db checks
	- Better function organization
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- LAYOUT SETTINGS
-- ============================================================================

local function saveLayout(chatFrame)
	if not addon or not addon.addonLoaded or not chatFrame or not _G.XCHT_DB then return end

	local frameID = chatFrame:GetID()
	if not frameID then return end

	if not _G.XCHT_DB.frames then
		_G.XCHT_DB.frames = {}
	end

	-- Only store shown frames or default chat frame
	if not _G.XCHT_DB.frames[frameID] and (chatFrame == _G.DEFAULT_CHAT_FRAME or chatFrame.isDocked or chatFrame:IsShown()) then
		_G.XCHT_DB.frames[frameID] = {}
	elseif not _G.XCHT_DB.frames[frameID] then
		return
	end

	local db = _G.XCHT_DB.frames[frameID]
	local point, relativeTo, relativePoint, xOffset, yOffset = chatFrame:GetPoint()

	-- Normalize relativeTo to string name
	if relativeTo == nil then
		relativeTo = "UIParent"
	elseif type(relativeTo) == "table" then
		relativeTo = relativeTo:GetName() or "UIParent"
	end

	db.point = point
	db.relativeTo = relativeTo
	db.relativePoint = relativePoint
	db.xOffset = xOffset
	db.yOffset = yOffset
	db.width = chatFrame:GetWidth()
	db.height = chatFrame:GetHeight()
end

local function restoreLayout(chatFrame)
	if not addon or not chatFrame or not _G.XCHT_DB or not _G.XCHT_DB.frames then return end

	local frameID = chatFrame:GetID()
	if not frameID or not _G.XCHT_DB.frames[frameID] then return end

	local db = _G.XCHT_DB.frames[frameID]

	-- Don't set DEFAULT_CHAT_FRAME in retail (causes taints)
	if addon.IsRetail and chatFrame == _G.DEFAULT_CHAT_FRAME then
		return
	end

	-- Restore size
	if db.width and db.height then
		if not addon.IsRetail then
			chatFrame:SetSize(db.width, db.height)
		end
		if _G.SetChatWindowSavedDimensions then
			_G.SetChatWindowSavedDimensions(chatFrame:GetID(), db.width, db.height)
		end
		if not chatFrame.isTemporary and not chatFrame.isDocked and _G.FCF_RestorePositionAndDimensions then
			_G.FCF_RestorePositionAndDimensions(chatFrame)
		end
	end

	-- Make movable and set position
	local sSwitch = false
	if not chatFrame:IsMovable() then
		chatFrame:SetMovable(true)
		sSwitch = true
	end
	if not chatFrame:IsMouseEnabled() then
		chatFrame:EnableMouse(true)
	end

	if chatFrame:IsMovable() and db.point and db.xOffset then
		chatFrame:SetUserPlaced(true)

		-- Normalize relativeTo for restore
		if db.relativeTo == nil or type(db.relativeTo) == "table" then
			db.relativeTo = "UIParent"
		end

		if chatFrame == _G.DEFAULT_CHAT_FRAME or not chatFrame.isDocked or not db.windowInfo or not db.windowInfo[9] then
			chatFrame:ClearAllPoints()
			chatFrame:SetPoint(db.point, _G[db.relativeTo], db.relativePoint, db.xOffset, db.yOffset)
		elseif _G.FCF_DockFrame then
			_G.FCF_DockFrame(chatFrame, db.windowInfo[9])
		end
	end

	if sSwitch then
		chatFrame:SetMovable(false)
	end
end

-- ============================================================================
-- CHAT SETTINGS
-- ============================================================================

local function saveSettings(chatFrame)
	if not addon or not addon.addonLoaded or not chatFrame or not _G.XCHT_DB then return end

	local frameID = chatFrame:GetID()
	if not frameID then return end

	if not _G.XCHT_DB.frames then
		_G.XCHT_DB.frames = {}
	end

	-- Only store shown frames
	if chatFrame == _G.DEFAULT_CHAT_FRAME or chatFrame.isDocked or chatFrame:IsShown() then
		if not _G.XCHT_DB.frames[frameID] then
			_G.XCHT_DB.frames[frameID] = {}
		end
	elseif _G.XCHT_DB.frames[frameID] then
		_G.XCHT_DB.frames[frameID] = nil
		return
	end

	if chatFrame.isMoving or chatFrame.isDragging then return end

	local db = _G.XCHT_DB.frames[frameID]

	if _G.GetChatWindowInfo then
		local name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable = _G.GetChatWindowInfo(frameID)
		local windowMessages = {}
		local windowMessageColors = {}

		-- Save message type colors
		for k = 1, #windowMessages do
			if windowMessages[k] and _G.ChatTypeGroup and _G.ChatTypeGroup[windowMessages[k]] then
				local colorR, colorG, colorB = _G.GetMessageTypeColor(windowMessages[k])
				if colorR and colorG and colorB then
					windowMessageColors[k] = {colorR, colorG, colorB, windowMessages[k]}
				end
			end
		end

		db.chatParent = chatFrame:GetParent():GetName()
		db.windowInfo = {name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable}
		db.windowMessages = windowMessages
		db.windowChannels = {}
		db.windowMessageColors = windowMessageColors
		db.windowChannelColors = nil
		db.fadingDuration = chatFrame:GetTimeVisible() or 120
		db.defaultFrameAlpha = _G.DEFAULT_CHATFRAME_ALPHA
	end
end

local function restoreSettings(chatFrame)
	if not addon or not chatFrame or not _G.XCHT_DB or not _G.XCHT_DB.frames then return end

	local frameID = chatFrame:GetID()
	if not frameID or not _G.XCHT_DB.frames[frameID] then return end

	local db = _G.XCHT_DB.frames[frameID]

	-- Restore window messages
	if db.windowMessages and _G.GetChatWindowMessages and _G.RemoveChatWindowMessages and _G.AddChatWindowMessages then
		for k = 1, #_G.GetChatWindowMessages(frameID) do
			local msg = _G.GetChatWindowMessages(frameID)[k]
			_G.RemoveChatWindowMessages(frameID, msg)
		end

		for k = 1, #db.windowMessages do
			_G.AddChatWindowMessages(frameID, db.windowMessages[k])
		end
	end

	-- Restore window message colors
	if db.windowMessageColors then
		for k = 1, #db.windowMessageColors do
			local colorData = db.windowMessageColors[k]
			if colorData and colorData[4] and _G.ChangeChatColor then
				_G.ChangeChatColor(colorData[4], colorData[1], colorData[2], colorData[3])
			end
		end
	end

	-- Restore window channels
	if db.windowChannels and _G.GetChatWindowChannels and _G.RemoveChatWindowChannel and _G.AddChatWindowChannel then
		for k = 1, #_G.GetChatWindowChannels(frameID) do
			local ch = _G.GetChatWindowChannels(frameID)[k]
			_G.RemoveChatWindowChannel(frameID, ch)
		end

		for k = 1, #db.windowChannels do
			_G.AddChatWindowChannel(frameID, db.windowChannels[k])
		end
	end

	-- Restore channel colors
	if _G.XCHT_DB and _G.XCHT_DB.channelColors then
		for k = 1, _G.MAX_WOW_CHAT_CHANNELS do
			local colorData = _G.XCHT_DB.channelColors[k]
			if colorData and colorData.channelNum and _G.ChangeChatColor then
				_G.ChangeChatColor("CHANNEL"..colorData.channelNum, colorData.r, colorData.g, colorData.b)
			end
		end
	end

	-- Restore window info
	if db.windowInfo and db.windowInfo[1] then
		if _G.SetChatWindowName then
			_G.SetChatWindowName(frameID, db.windowInfo[1])
		end
		if _G.SetChatWindowSize then
			_G.SetChatWindowSize(frameID, db.windowInfo[2])
		end
		if _G.SetChatWindowColor then
			_G.SetChatWindowColor(frameID, db.windowInfo[3], db.windowInfo[4], db.windowInfo[5])
		end
		if _G.SetChatWindowAlpha then
			_G.SetChatWindowAlpha(frameID, db.windowInfo[6])
		end
		if _G.SetChatWindowShown then
			_G.SetChatWindowShown(frameID, db.windowInfo[7])
		end
		if _G.SetChatWindowLocked then
			_G.SetChatWindowLocked(frameID, db.windowInfo[8])
		end
		if _G.SetChatWindowDocked then
			_G.SetChatWindowDocked(frameID, db.windowInfo[9])
		end
		if _G.SetChatWindowUninteractable then
			_G.SetChatWindowUninteractable(frameID, db.windowInfo[10])
		end
	end

	-- Restore parent
	if db.chatParent then
		local parent = type(db.chatParent) == "table" and db.chatParent or _G[db.chatParent]
		chatFrame:SetParent(parent)
	end

	-- Restore fading settings
	if _G.XCHT_DB then
		chatFrame:SetFading(_G.XCHT_DB.enableChatTextFade)
		if _G.XCHT_DB.enableChatTextFade then
			chatFrame:SetTimeVisible(db.fadingDuration or 120)
		end
	end
end

-- ============================================================================
-- CHANNEL COLORS
-- ============================================================================

local function saveChannelColors()
	if not addon or not addon.addonLoaded or not _G.XCHT_DB then return end

	if not _G.XCHT_DB.channelColors then
		_G.XCHT_DB.channelColors = {}
	end

	local channelData = {}
	if _G.GetChannelList then
		channelData = {_G.GetChannelList()}
	end

	local count = 1
	for i = 1, #channelData, 3 do
		local channelNum = channelData[i]
		local channelName = channelData[i + 1]
		local tag = "CHANNEL"..channelNum

		if _G.ChatTypeInfo and _G.ChatTypeInfo[tag] then
			local colorR, colorG, colorB = _G.GetMessageTypeColor(tag)
			if colorR and colorG and colorB then
				_G.XCHT_DB.channelColors[count] = {r=colorR, g=colorG, b=colorB, channelNum=channelNum, channelName=channelName, tag=tag}
				count = count + 1
			end
		end
	end
end

-- ============================================================================
-- DEBUG INFO
-- ============================================================================

local function saveDebugInfo(chatFrame)
	if not addon or not addon.addonLoaded or not chatFrame or not _G.XCHT_DB then return end

	local frameID = chatFrame:GetID()
	if not frameID then return end

	if _G.XCHT_DB.debugChannels then
		_G.XCHT_DB.debugChannels = nil
	end

	if not _G.XCHT_DB.debugInfo then
		_G.XCHT_DB.debugInfo = {}
	end

	-- Only store debug info for shown frames
	if chatFrame == _G.DEFAULT_CHAT_FRAME or chatFrame.isDocked or chatFrame:IsShown() then
		if not _G.XCHT_DB.debugInfo[frameID] then
			_G.XCHT_DB.debugInfo[frameID] = {}
		end
	elseif _G.XCHT_DB.debugInfo[frameID] then
		_G.XCHT_DB.debugInfo[frameID] = nil
		return
	end

	local debugDB = _G.XCHT_DB.debugInfo[frameID]
	local channelList = chatFrame.channelList

	if not channelList or #channelList < 1 then return end

	local channelIndexByName = {}
	for i = 1, #channelList do
		channelIndexByName[channelList[i]] = i
	end

	local channels = _G.GetChannelList and {_G.GetChannelList()} or {}

	for i = 1, #channels, 3 do
		local channelNum = channels[i]
		local channelName = channels[i + 1]
		if channelNum then
			local tag = "CHANNEL"..channelNum
			local index = channelIndexByName[channelName]
			debugDB[channelName] = {channelNum=channelNum, checked=index ~= nil}
		end
	end
end

-- ============================================================================
-- COMPOSITE FUNCTIONS
-- ============================================================================

local function saveChatSettings(f)
	saveLayout(f)
	saveSettings(f)
	saveDebugInfo(f)
	saveChannelColors()
end

local function restoreChatSettings(f)
	restoreSettings(f)
	restoreLayout(f)
end

local function doSaveCurrentChatFrame()
	if _G.FCF_GetCurrentChatFrame then
		local chatFrame = _G.FCF_GetCurrentChatFrame()
		if chatFrame then
			saveChatSettings(chatFrame)
		end
	end
end

-- ============================================================================
-- AUTO-SAVE HOOKS
-- ============================================================================

local function hookupAutoSave()
	if not addon then return end

	-- Hook message toggle functions
	local messageToggleFuncs = {
		"ToggleChatMessageGroup", "ToggleMessageSource", "ToggleMessageDest",
		"ToggleMessageTypeGroup", "ToggleMessageType", "ToggleChatColorNamesByClassGroup",
	}
	for _, funcName in ipairs(messageToggleFuncs) do
		if _G[funcName] then
			addon:SecureHook(funcName, doSaveCurrentChatFrame)
		end
	end

	-- Hook frame functions with saveChatSettings
	local frameFuncs = {
		{"FCF_SavePositionAndDimensions", saveChatSettings},
		{"FCF_RestorePositionAndDimensions", saveChatSettings},
		{"FCF_Close", saveChatSettings},
	}
	for _, funcData in ipairs(frameFuncs) do
		if _G[funcData[1]] then
			addon:SecureHook(funcData[1], funcData[2])
		end
	end

	-- Hook frame toggle functions
	local frameToggleFuncs = {
		"FCF_ToggleLock", "FCF_ToggleLockOnDockedFrame", "FCF_ToggleUninteractable",
	}
	for _, funcName in ipairs(frameToggleFuncs) do
		if _G[funcName] then
			addon:SecureHook(funcName, doSaveCurrentChatFrame)
		end
	end

	-- Hook additional frame operations
	if _G["FCF_DockFrame"] then
		addon:SecureHook("FCF_DockFrame", saveChatSettings)
	end
	if _G["FCF_StopDragging"] then
		addon:SecureHook("FCF_StopDragging", saveChatSettings)
	end
	if _G["FCF_Tab_OnClick"] then
		addon:SecureHook("FCF_Tab_OnClick", function(self)
			local chatFrame = _G["ChatFrame"..self:GetID()]
			if chatFrame then
				saveChatSettings(chatFrame)
			end
		end)
	end

	-- Hook ChatConfigFrame OnHide if available
	if _G.ChatConfigFrame and _G.ChatConfigFrame.HookScript then
		_G.ChatConfigFrame:HookScript("OnHide", function(self)
			if _G.NUM_CHAT_WINDOWS then
				for i = 1, _G.NUM_CHAT_WINDOWS do
					local f = _G[("ChatFrame%d"):format(i)]
					if f then
						saveChatSettings(f)
					end
				end
			end
		end)
	end
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.SaveLayout = saveLayout
addon.RestoreLayout = restoreLayout
addon.SaveSettings = saveSettings
addon.RestoreSettings = restoreSettings
addon.SaveChannelColors = saveChannelColors
addon.SaveDebugInfo = saveDebugInfo
addon.saveChatSettings = saveChatSettings
addon.restoreChatSettings = restoreChatSettings
addon.doSaveCurrentChatFrame = doSaveCurrentChatFrame
addon.hookupAutoSave = hookupAutoSave
