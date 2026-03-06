--[[
	ChatSettings.lua - Settings save/restore system for XanChat
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- LAYOUT SETTINGS
-- ============================================================================

local function saveLayout(chatFrame)
	if not addon or not addon.addonLoaded then return end

	if not chatFrame then return end
	if not _G.XCHT_DB then return end

	if not _G.XCHT_DB.frames then
		_G.XCHT_DB.frames = {}
	end

	local frameID = chatFrame:GetID()
	if not frameID then return end

	-- first check to see if we even store this chatFrame
	if not _G.XCHT_DB.frames[frameID] and (chatFrame == _G.DEFAULT_CHAT_FRAME or chatFrame.isDocked or chatFrame:IsShown()) then
		_G.XCHT_DB.frames[frameID] = {}
	elseif not _G.XCHT_DB.frames[frameID] then
		return
	end

	local db = _G.XCHT_DB.frames[frameID]

	local point, relativeTo, relativePoint, xOffset, yOffset = chatFrame:GetPoint()

	-- error check for invalid object type for relativeTo
	if relativeTo == nil then
		relativeTo = "UIParent"
	elseif type(relativeTo) == "table" then
		relativeTo = relativeTo:GetName() or "UIParent"
	end

	db.point = point
	-- relativeTo returns the actual object, we just want to name
	db.relativeTo = relativeTo
	db.relativePoint = relativePoint
	db.xOffset = xOffset
	db.yOffset = yOffset
	db.width = chatFrame:GetWidth()
	db.height = chatFrame:GetHeight()
end

local function restoreLayout(chatFrame)
	if not addon then return end

	if not chatFrame then return end

	if not _G.XCHT_DB then return end
	if not _G.XCHT_DB.frames then return end

	local frameID = chatFrame:GetID()
	if not frameID then return end

	if not _G.XCHT_DB.frames[frameID] then return end

	local db = _G.XCHT_DB.frames[frameID]

	if addon.IsRetail and chatFrame == _G.DEFAULT_CHAT_FRAME then
		return -- don't set anything for the default chat frame in retail, it causes taints
	end

	if db.width and db.height then
		if not addon.IsRetail then
			chatFrame:SetSize(db.width, db.height) -- uses a taint if you try to set the DEFAULT_CHAT_FRAME height and width in any way in retail due to edit mode
		end
		-- force sizing in blizzards settings
		if _G.SetChatWindowSavedDimensions then
			_G.SetChatWindowSavedDimensions(chatFrame:GetID(), db.width, db.height)
		end

		if not chatFrame.isTemporary and not chatFrame.isDocked then
			if _G.FCF_RestorePositionAndDimensions then
				_G.FCF_RestorePositionAndDimensions(chatFrame)
			end
		end
	end

	local sSwitch = false

	-- check to see if we can even move the frame
	if not chatFrame:IsMovable() then
		chatFrame:SetMovable(true)
		sSwitch = true
	end

	if not chatFrame:IsMouseEnabled() then
		chatFrame:EnableMouse(true)
	end

	if chatFrame:IsMovable() and db.point and db.xOffset then
		chatFrame:SetUserPlaced(true)
		-- error check for invalid object type for relativeTo
		if db.relativeTo == nil or type(db.relativeTo) == "table" then
			db.relativeTo = "UIParent"
		end
		-- don't move docked chats
		if chatFrame == _G.DEFAULT_CHAT_FRAME or not chatFrame.isDocked or not db.windowInfo[9] then
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
	if not addon or not addon.addonLoaded then return end

	if not chatFrame then return end

	if not _G.XCHT_DB then return end

	if not _G.XCHT_DB.frames then
		_G.XCHT_DB.frames = {}
	end

	local frameID = chatFrame:GetID()
	if not frameID then return end

	-- first check to see if we even store this chatFrame
	if chatFrame == _G.DEFAULT_CHAT_FRAME or chatFrame.isDocked or chatFrame:IsShown() then
		if not _G.XCHT_DB.frames[frameID] then
			_G.XCHT_DB.frames[frameID] = {}
		end
	else
		-- don't store it
		if _G.XCHT_DB.frames[frameID] then
			_G.XCHT_DB.frames[frameID] = nil
		end
		return
	end

	if chatFrame.isMoving or chatFrame.isDragging then
		return
	end

	local db = _G.XCHT_DB.frames[frameID]

	if _G.GetChatWindowInfo then
		local name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable = _G.GetChatWindowInfo(frameID)
		local windowMessages = {}
		local windowChannels = {}
		local windowMessageColors = {}

		-- lets save all the message type colors
		for k = 1, #windowMessages do
			if windowMessages[k] and _G.ChatTypeGroup and _G.ChatTypeGroup[windowMessages[k]] then
				local colorR, colorG, colorB, messageType = _G.GetMessageTypeColor(windowMessages[k])
				if colorR and colorG and colorB then
					windowMessageColors[k] = {colorR, colorG, colorB, windowMessages[k]}
				end
			end
		end

		db.chatParent = chatFrame:GetParent():GetName()
		db.windowInfo = {name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable}
		db.windowMessages = windowMessages
		db.windowChannels = windowChannels
		db.windowMessageColors = windowMessageColors
		db.windowChannelColors = nil -- remove old db stuff
		db.fadingDuration = chatFrame:GetTimeVisible() or 120
		db.defaultFrameAlpha = _G.DEFAULT_CHATFRAME_ALPHA
	end
end

local function restoreSettings(chatFrame)
	if not addon then return end

	if not chatFrame then return end

	if not _G.XCHT_DB then return end
	if not _G.XCHT_DB.frames then return end

	local frameID = chatFrame:GetID()
	if not frameID then return end

	if not _G.XCHT_DB.frames[frameID] then return end

	local db = _G.XCHT_DB.frames[frameID]

	if db.windowMessages then
		-- remove current window messages
		local oldWindowMessages = {}
		if _G.GetChatWindowMessages then
			for k = 1, #_G.GetChatWindowMessages(frameID) do
				local msg = _G.GetChatWindowMessages(frameID)[k]
				oldWindowMessages[k] = msg
				if _G.RemoveChatWindowMessages then
					_G.RemoveChatWindowMessages(frameID, msg)
				end
			end
		end

		-- add stored ones
		local newWindowMessages = db.windowMessages
		for k = 1, #newWindowMessages do
			if newWindowMessages[k] and _G.AddChatWindowMessages then
				_G.AddChatWindowMessages(frameID, newWindowMessages[k])
			end
		end
	end

	-- lets set the windowMessageColors
	if db.windowMessageColors then
		-- add stored ones
		local newWindowMessageColors = db.windowMessageColors
		for k = 1, #newWindowMessageColors do
			if newWindowMessageColors[k] and newWindowMessageColors[k][4] then
				if _G.ChangeChatColor then
					_G.ChangeChatColor(newWindowMessageColors[k][4], newWindowMessageColors[k][1], newWindowMessageColors[k][2], newWindowMessageColors[k][3])
				end
			end
		end
	end

	if db.windowChannels then
		-- remove current window channels
		local oldWindowChannels = {}
		if _G.GetChatWindowChannels then
			for k = 1, #_G.GetChatWindowChannels(frameID) do
				local ch = _G.GetChatWindowChannels(frameID)[k]
				oldWindowChannels[k] = ch
				if _G.RemoveChatWindowChannel then
					_G.RemoveChatWindowChannel(frameID, ch)
				end
			end
		end

		-- add stored ones
		local newWindowChannels = db.windowChannels
		for k = 1, #newWindowChannels do
			if newWindowChannels[k] and _G.AddChatWindowChannel then
				_G.AddChatWindowChannel(frameID, newWindowChannels[k])
			end
		end
	end

	-- lets set the windowChannelColors
	if _G.XCHT_DB and _G.XCHT_DB.channelColors then
		for k = 1, _G.MAX_WOW_CHAT_CHANNELS do
			if _G.XCHT_DB.channelColors[k] then
				local colorData = _G.XCHT_DB.channelColors[k]
				if colorData and colorData.channelNum and _G.ChangeChatColor then
					_G.ChangeChatColor("CHANNEL"..colorData.channelNum, colorData.r, colorData.g, colorData.b)
				end
			end
		end
	end

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

	if db.chatParent then
		local checkParent = (type(db.chatParent) == "table" and db.chatParent) or _G[db.chatParent]
		chatFrame:SetParent(checkParent)
	end

	-- handling chat frame fading
	if _G.XCHT_DB then
		if _G.XCHT_DB.enableChatTextFade then
			chatFrame:SetFading(true)
			chatFrame:SetTimeVisible(db.fadingDuration or 120)
		else
			chatFrame:SetFading(false)
		end
	end
end

-- ============================================================================
-- CHANNEL COLORS
-- ============================================================================

local function saveChannelColors()
	if not addon or not addon.addonLoaded then return end

	if not _G.XCHT_DB then return end

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
			end
		end
		count = count + 1
	end
end

-- ============================================================================
-- DEBUG INFO
-- ============================================================================

local function saveDebugInfo(chatFrame)
	if not addon or not addon.addonLoaded then return end

	if not chatFrame then return end

	if not _G.XCHT_DB then return end

	local frameID = chatFrame:GetID()
	if not frameID then return end

	if _G.XCHT_DB.debugChannels then
		_G.XCHT_DB.debugChannels = nil -- remove old debug table
	end

	if not _G.XCHT_DB.debugInfo then
		_G.XCHT_DB.debugInfo = {}
	end

	if chatFrame == _G.DEFAULT_CHAT_FRAME or chatFrame.isDocked or chatFrame:IsShown() then
		if not _G.XCHT_DB.debugInfo[frameID] then
			_G.XCHT_DB.debugInfo[frameID] = {}
		end
	else
		-- don't store it
		if _G.XCHT_DB.debugInfo[frameID] then
			_G.XCHT_DB.debugInfo[frameID] = nil
		end
		return
	end

	local debugDB = _G.XCHT_DB.debugInfo[frameID]
	local channelList = chatFrame.channelList

	if not channelList or #channelList < 1 then
		return
	end

	local channelIndexByName = {}
	for i = 1, #channelList do
		channelIndexByName[channelList[i]] = i
	end

	local channels = {}
	if _G.GetChannelList then
		channels = {_G.GetChannelList()}
	end

	for i = 1, #channels, 3 do
		local channelNum = channels[i]
		local channelName = channels[i + 1]
		if channelNum then
			local tag = "CHANNEL"..channelNum
			local index = channelIndexByName[channelName]
			local checked = index ~= nil
			debugDB[channelName] = {channelNum=channelNum, checked=checked}
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

	-- Hook multiple message-related functions with same handler
	local messageToggleFuncs = {
		"ToggleChatMessageGroup",
		"ToggleMessageSource",
		"ToggleMessageDest",
		"ToggleMessageTypeGroup",
		"ToggleMessageType",
		"ToggleChatColorNamesByClassGroup",
	}
	for _, funcName in ipairs(messageToggleFuncs) do
		if _G[funcName] then
			addon:SecureHook(funcName, function() doSaveCurrentChatFrame() end)
		end
	end

	-- Hook frame-related functions
	local frameFuncs = {
		{"FCF_SavePositionAndDimensions", function(chatFrame) saveChatSettings(chatFrame) end},
		{"FCF_RestorePositionAndDimensions", function(chatFrame) saveChatSettings(chatFrame) end},
		{"FCF_Close", function(chatFrame) saveChatSettings(chatFrame) end},
	}
	for _, funcData in ipairs(frameFuncs) do
		if _G[funcData[1]] then
			addon:SecureHook(funcData[1], funcData[2])
		end
	end

	-- Hook functions with same doSaveCurrentChatFrame handler
	local frameToggleFuncs = {
		"FCF_ToggleLock",
		"FCF_ToggleLockOnDockedFrame",
		"FCF_ToggleUninteractable",
	}
	for _, funcName in ipairs(frameToggleFuncs) do
		if _G[funcName] then
			addon:SecureHook(funcName, function() doSaveCurrentChatFrame() end)
		end
	end

	-- Hook additional frame operations
	if _G["FCF_DockFrame"] then
		addon:SecureHook("FCF_DockFrame", function(chatFrame, index, selected) saveChatSettings(chatFrame) end)
	end
	if _G["FCF_StopDragging"] then
		addon:SecureHook("FCF_StopDragging", function(chatFrame) saveChatSettings(chatFrame) end)
	end
	if _G["FCF_Tab_OnClick"] then
		addon:SecureHook("FCF_Tab_OnClick", function(self, button)
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
					local n = ("ChatFrame%d"):format(i)
					local f = _G[n]
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

