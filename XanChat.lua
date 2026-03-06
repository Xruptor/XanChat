--[[
	XanChat chat pipeline
	- proxy capture path for normal messages
	- direct safe path for secret message payloads
	- section-based formatting + callback stages
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- WoW Project Detection
local WOW_PROJECT_ID = _G.WOW_PROJECT_ID
local WOW_PROJECT_MAINLINE = _G.WOW_PROJECT_MAINLINE
local WOW_PROJECT_CLASSIC = _G.WOW_PROJECT_CLASSIC
local WOW_PROJECT_WRATH_CLASSIC = _G.WOW_PROJECT_WRATH_CLASSIC

addon.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
addon.IsClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
addon.IsWLK_C = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

-- ============================================================================
-- ADDMESSAGE HANDLER (for AceHook RawHook)
-- ============================================================================
addon.AddMessage = function(self, frame, text, r, g, b, id, ...)
	-- Capture text when called on the capture proxy frame
	if addon.captureState.proxy == frame and addon.captureState.text == nil then
		addon.captureState.text = text
		addon.captureState.color.r = r
		addon.captureState.color.g = g
		addon.captureState.color.b = b
		addon.captureState.color.id = id
		addon.dbg("capture proxy stored formatter output")
		return
	end
	-- Call original AddMessage for non-capture calls
	return self.hooks[frame].AddMessage(frame, text, r, g, b, id, ...)
end

-- ============================================================================
-- EVENT CALLBACK SYSTEM
-- Event constants
local EVENTS = {
	FRAME_MESSAGE = "XanChat_FrameMessage",
	PRE_ADDMESSAGE = "XanChat_PreAddMessage",
	POST_ADDMESSAGE = "XanChat_PostAddMessage",
	POST_ADDMESSAGE_BLOCKED = "XanChat_PostAddMessageBlocked",
}
addon.EVENTS = EVENTS

-- ============================================================================
-- MAIN MESSAGE HANDLER
-- ============================================================================

-- Parse WoW event args into chat sections
function addon:SplitChatMessage(frame, event, ...)
	addon.dbg("SplitChatMessage: START event=" .. tostring(event))
	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17 = ...
	local isSecret = _G.issecretvalue and _G.issecretvalue(arg1)

	addon.dbg("SplitChatMessage: isSecret=" .. tostring(isSecret) .. " arg1=" .. addon.dbgValue(arg1))

	if type(event) ~= "string" or string.sub(event, 1, 8) ~= "CHAT_MSG" then
		addon.dbg("SplitChatMessage: not a CHAT_MSG event, returning nil")
		return nil, nil
	end

	if arg16 then
		-- Hidden sender in cinematic letterbox
		return true
	end

	local chatType = string.sub(event, 10)
	local info

	-- Get chat info (color, etc.)
	local infoType = chatType
	if _G.ChatTypeInfo and _G.ChatTypeInfo[infoType] then
		info = _G.ChatTypeInfo[infoType]
	else
		info = _G.ChatTypeInfo and _G.ChatTypeInfo.SYSTEM or { r=1, g=1, b=1, id=0 }
	end

	-- Reset and repopulate pooled section buffers
	addon.resetSectionBuffer(addon.sectionOriginal)
	local s = addon.sectionOriginal

	s.LINE_ID = arg11 or 0
	s.INFOTYPE = infoType
	s.CHATTYPE = chatType
	s.EVENT = event

	-- Get chat category
	local chatGroup = chatType
	if _G.Chat_GetChatCategory then
		chatGroup = _G.Chat_GetChatCategory(chatType)
	elseif _G.ChatFrameUtil and _G.ChatFrameUtil.GetChatCategory then
		chatGroup = _G.ChatFrameUtil.GetChatCategory(chatType)
	end
	s.CHATGROUP = chatGroup

	-- Get chat target
	local chatTarget = nil
	if chatGroup == "CHANNEL" or chatGroup == "BN_CONVERSATION" then
		chatTarget = tostring(arg8 or "")
	elseif chatGroup == "WHISPER" or chatGroup == "BN_WHISPER" then
		chatTarget = arg2
	end
	s.CHATTARGET = chatTarget

	-- Message text
	s.message_text = isSecret and arg1 or (addon.safestr(arg1) or ""):gsub("^%s*(.-)%s*$", "%1")

	-- Check if player name is a secret value (SEPARATE from message text secret check)
	local isArg2Secret = _G.issecretvalue and _G.issecretvalue(arg2)
	local coloredName = arg2

		-- Extract player information
	if not isArg2Secret and type(arg2) == "string" and arg2 ~= "" then


		-- Trim arg2 only if not secret
		if not isArg2Secret then
			coloredName = string.match(coloredName, "^%s*(.-)%s*$") or coloredName
		end

		-- Check if secret (Ambiguate guard)
		if _G.Ambiguate and (not _G.issecretvalue or not _G.issecretvalue(arg2)) then
			if chatType == "GUILD" then
				coloredName = _G.Ambiguate(coloredName, "guild")
			else
				coloredName = _G.Ambiguate(coloredName, "none")
			end
		end

		-- Create player link
		if string.sub(chatType, 1, 7) ~= "MONSTER" and string.sub(chatType, 1, 18) ~= "RAID_BOSS_EMOTE" and
		    chatType ~= "CHANNEL_NOTICE" and chatType ~= "CHANNEL_NOTICE_USER" then

			local playerLink

			if chatType == "BN_WHISPER" or chatType == "BN_WHISPER_INFORM" or chatType == "BN_CONVERSATION" then
				if arg13 then
					playerLink = string.format("|HBNplayer:%s:%s:%s:%s:%s|h[%s]|h", arg2, arg13, arg11 or 0, chatGroup or 0, chatTarget or "", coloredName)
				else
					playerLink = "[" .. coloredName .. "]"
				end
			else
				playerLink = string.format("|Hplayer:%s:%s:%s:%s|h[%s]|h", arg2, arg11 or 0, chatGroup or 0, chatTarget or "", coloredName)
			end

			s.player_link = playerLink

			-- Extract name and server
			local plr, svr = arg2:match("([^%-]+)%-?(.*)")
			if plr then
				s.player_name = plr
			end
			if svr and string.len(svr) > 0 then
				s.server_separator = "-"
				s.server_name = svr
			end
		end
	end

	-- Extract channel information
	if type(arg3) == "string" and arg3 ~= "" and arg3 ~= "Universal" then
		s.language = arg3
	elseif type(arg3) == "string" and arg3 ~= "" then
		s.LANGUAGE_NOSHOW = arg3
	end

	-- Extract channel name
	if string.len(arg8 or "") > 0 or chatGroup == "BN_CONVERSATION" then
		if chatGroup == "BN_CONVERSATION" then
			s.channel_number = tostring((_G.MAX_WOW_CHAT_CHANNELS or 20) + (arg8 or 0))
			if _G.CHAT_BN_CONVERSATION_SEND then
				s.channel_name = string.match(_G.CHAT_BN_CONVERSATION_SEND or "", "%d%.%s+(.+)")
			end
		else
			local channelNum = tonumber(arg8) or tonumber(arg7) or tonumber(arg9) or tonumber(arg10) or 0
			if channelNum and channelNum > 0 then
				s.channel_number = tostring(channelNum)

				-- Try to get channel name from arg9
				local arg9Text = arg9 or ""
				if string.len(arg9Text) > 0 then
					s.channel_name = arg9Text
				end
			end
		end
	end

	-- Extract flags
	if type(arg6) == "string" and arg6 ~= "" then
		if arg6 == "GM" or arg6 == "DEV" then
			s.player_flag = "|TInterface\\ChatFrame\\UI-ChatIcon-Blizz:12:20:0:0:32:16:4:28:0:16|t "
		elseif arg6 == "GUIDE" and _G.ChatFrame_GetMentorChannelStatus then
			if _G.Enum and _G.Enum.PlayerMentorshipStatus and _G.C_ChatInfo then
				local mentorStatus = _G.ChatFrame_GetMentorChannelStatus(_G.Enum.PlayerMentorshipStatus.Mentor, _G.C_ChatInfo.GetChannelRulesetForChannelID(arg7))
				if mentorStatus == _G.Enum.PlayerMentorshipStatus.Mentor then
					s.player_flag = (_G.NPEV2_CHAT_USER_TAG_GUIDE or "[Guide]") .. " "
				elseif mentorStatus == _G.Enum.PlayerMentorshipStatus.Newcomer then
					s.player_flag = _G.NPEV2_CHAT_USER_TAG_NEWCOMER or "[New]"
				end
			end
		elseif arg6 == "NEWCOMER" and _G.ChatFrame_GetMentorChannelStatus then
			if _G.Enum and _G.Enum.PlayerMentorshipStatus and _G.C_ChatInfo then
				local mentorStatus = _G.ChatFrame_GetMentorChannelStatus(_G.Enum.PlayerMentorshipStatus.Newcomer, _G.C_ChatInfo.GetChannelRulesetForChannelID(arg7))
				if mentorStatus == _G.Enum.PlayerMentorshipStatus.Newcomer then
					s.player_flag = _G.NPEV2_CHAT_USER_TAG_NEWCOMER or "[New]"
				end
			end
		elseif _G["CHAT_FLAG_" .. arg6] then
			s.player_flag = _G["CHAT_FLAG_" .. arg6] or ""
		end
	end

	-- Extract mobile texture
	if arg15 and info then
		local mobileFn = _G.ChatFrame_GetMobileEmbeddedTexture or (_G.ChatFrameUtil and _G.ChatFrameUtil.GetMobileEmbeddedTexture)
		if mobileFn then
			s.mobile_icon = mobileFn(info.r or 1, info.g or 1, info.b or 1) or ""
		end
	end

	s.INFO = info
	addon.prepareWorkingSections()
	return addon.sectionWorking, info
end

function addon:ChatFrame_MessageEventHandler(this, event, ...)
	local frameName = this and this.GetName and this:GetName() or "<unknown>"
	addon.dbg("ChatFrame_MessageEventHandler: START event=" .. tostring(event) .. " frame=" .. tostring(frameName))

	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15 = ...
	local isSecretPayload = _G.issecretvalue and _G.issecretvalue(arg1)
	local processMode = addon:EventIsProcessed(event)
	local handlerResult

	addon.dbg("ChatFrame_MessageEventHandler: isSecretPayload=" .. tostring(isSecretPayload) .. " processMode=" .. tostring(processMode))

	if not this then
		addon.dbg("ChatFrame_MessageEventHandler: missing frame, passthrough")
		return addon.callOriginalMessageHandler(self, this, event, ...)
	end
	if not addon.HookedFrames or not addon.HookedFrames[frameName] then
		addon.dbg("ChatFrame_MessageEventHandler: frame not managed, passthrough")
		return addon.callOriginalMessageHandler(self, this, event, ...)
	end

	addon.dbg("ChatFrame_MessageEventHandler: frame is managed by xanChat")

	if not isSecretPayload and type(arg1) == "string" and string.find(arg1, "\r", 1, true) then
		addon.dbg("ChatFrame_MessageEventHandler: cleaning carriage returns from message")
		arg1 = string.gsub(arg1, "\r", " ")
	end

	local shouldDiscard
	shouldDiscard, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14 =
		addon.runFrameMessageFilters(this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
	if shouldDiscard then
		addon.dbg("ChatFrame_MessageEventHandler: message discarded by Blizzard filters")
		return true
	end

	addon.dbg("ChatFrame_MessageEventHandler: message passed Blizzard filters, calling SplitChatMessage")

	local parsedMessage, info = addon:SplitChatMessage(this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
	if type(parsedMessage) == "boolean" and parsedMessage == true then
		addon.dbg("ChatFrame_MessageEventHandler: split returned boolean, passing through")
		return true
	end
	if not isSecretPayload and not info then
		addon.dbg("ChatFrame_MessageEventHandler: split failed for non-secret, passthrough")
		return addon.callOriginalMessageHandler(self, this, event, ...)
	end
	if type(parsedMessage) ~= "table" then
		addon.dbg("ChatFrame_MessageEventHandler: split did not return table, passthrough")
		return addon.callOriginalMessageHandler(self, this, event, ...)
	end

	addon.dbg("ChatFrame_MessageEventHandler: split successful, preparing message processing")

	local m = parsedMessage
	local resolvedEvent = m.EVENT or event

	addon.resetCaptureState()
	m.OUTPUT = nil
	m.DONOTPROCESS = nil

	if addon.fireCallback then
		addon.dbg("ChatFrame_MessageEventHandler: firing FRAME_MESSAGE callback")
		addon.fireCallback(addon.EVENTS.FRAME_MESSAGE, m, this, resolvedEvent)
	end

	-- Branch: non-secret uses proxy capture, secret uses direct output
	if not isSecretPayload then
		addon.dbg("ChatFrame_MessageEventHandler: NON-SECRET path, using proxy capture")
		local proxyFrame = addon:CreateProxy(this)
		m.CAPTUREOUTPUT = proxyFrame
		addon.captureState.proxy = proxyFrame
		handlerResult = addon.callOriginalMessageHandler(self, proxyFrame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
		addon:RestoreProxy()
		m.OUTPUT = addon.captureState.text
		addon.dbg("ChatFrame_MessageEventHandler: proxy capture result: " .. addon.dbgValue(m.OUTPUT))
	else
		addon.dbg("ChatFrame_MessageEventHandler: SECRET path, using direct output")
		handlerResult = true
		m.OUTPUT = arg1 or ""
	end

	m.CAPTUREOUTPUT = false
	addon.captureState.proxy = nil

	if not isSecretPayload and type(m.OUTPUT) ~= "string" then
		addon.dbg("ChatFrame_MessageEventHandler: capture miss, passthrough")
		addon.resetCaptureState()
		m.CAPTUREOUTPUT = nil
		return addon.callOriginalMessageHandler(self, this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
	end

	if type(m.message_text) ~= "string" then
		m.message_text = m.message_text and tostring(m.message_text) or ""
	end

	if type(m.OUTPUT) == "string" and not m.DONOTPROCESS then
		addon.dbg("ChatFrame_MessageEventHandler: building display text")
		local infoRow = m.INFO or info or {}
		local outR, outG, outB, outID = infoRow.r or 1, infoRow.g or 1, infoRow.b or 1, infoRow.id or 0
		local textToDisplay = m.OUTPUT
		local applyPatterns = addon.shouldRunPatternPass(isSecretPayload, processMode)

		addon.dbg("ChatFrame_MessageEventHandler: applyPatterns=" .. tostring(applyPatterns))

		if applyPatterns then
			addon.dbg("ChatFrame_MessageEventHandler: running MatchPatterns")
			m.message_text = addon:MatchPatterns(m, "FRAME")
			if type(m.message_text) ~= "string" then
				m.message_text = m.message_text and tostring(m.message_text) or ""
			end
		end

		if addon.fireCallback then
			addon.dbg("ChatFrame_MessageEventHandler: firing PRE_ADDMESSAGE callback")
			addon.fireCallback(addon.EVENTS.PRE_ADDMESSAGE, m, this, resolvedEvent, addon:BuildChatText(m), outR, outG, outB, outID)
		end

		if applyPatterns then
			addon.dbg("ChatFrame_MessageEventHandler: running ReplaceMatches")
			m.message_text = addon:ReplaceMatches(m, "FRAME")
		end

		-- Apply xanChat-specific transformations on the message sections
		addon.FormatPlayerSection(m)
		addon.applyShortChannelNamesToSections(m)

		if processMode == addon.EventProcessingType.Full then
			addon.dbg("ChatFrame_MessageEventHandler: using Full processing mode, building from sections")
			textToDisplay = addon:BuildChatText(m) or ""
		elseif processMode == addon.EventProcessingType.PatternsOnly then
			addon.dbg("ChatFrame_MessageEventHandler: using PatternsOnly processing mode")
			textToDisplay = (m.PRE or "") .. (m.message_text or "") .. (m.POST or "")
		else
			addon.dbg("ChatFrame_MessageEventHandler: using output-only processing mode")
			textToDisplay = (m.PRE or "") .. (m.OUTPUT or "") .. (m.POST or "")
		end

		-- Check for join/leave suppression
		if addon.shouldSuppressJoinLeaveMessage and addon.shouldSuppressJoinLeaveMessage(resolvedEvent, textToDisplay) then
			addon.dbg("ChatFrame_MessageEventHandler: suppressing join/leave message")
			m.DONOTPROCESS = true
		end

		m.OUTPUT = textToDisplay
		addon.dbg("ChatFrame_MessageEventHandler: final output=" .. addon.dbgValue(textToDisplay))

		if m.DONOTPROCESS then
			addon.dbg("ChatFrame_MessageEventHandler: message blocked, firing POST_ADDMESSAGE_BLOCKED callback")
			if addon.fireCallback then
				addon.fireCallback(addon.EVENTS.POST_ADDMESSAGE_BLOCKED, m, this, resolvedEvent, textToDisplay, outR, outG, outB, outID)
			end
		elseif isSecretPayload then
			addon.dbg("ChatFrame_MessageEventHandler: adding secret message to frame")
			this:AddMessage(textToDisplay, outR, outG, outB, outID, m.ACCESSID, m.TYPEID)
			if addon.fireCallback then
				addon.fireCallback(addon.EVENTS.POST_ADDMESSAGE, m, this, resolvedEvent, textToDisplay, outR, outG, outB, outID)
			end
		elseif string.len(textToDisplay) > 0 then
			addon.dbg("ChatFrame_MessageEventHandler: adding non-secret message to frame")
			local capturedR = addon.captureState.color.r or outR
			local capturedG = addon.captureState.color.g or outG
			local capturedB = addon.captureState.color.b or outB
			local capturedID = addon.captureState.color.id or outID
			local isCensored = arg11 and _G.C_ChatInfo and _G.C_ChatInfo.IsChatLineCensored(arg11)
			local visibleText = isCensored and (arg1 or "") or textToDisplay

			addon.dbg("ChatFrame_MessageEventHandler: isCensored=" .. tostring(isCensored))

			if isCensored then
				this:AddMessage(visibleText, capturedR, capturedG, capturedB, capturedID, m.ACCESSID, m.TYPEID, event, { ... }, function(text)
					return text
				end)
			else
				this:AddMessage(visibleText, capturedR, capturedG, capturedB, capturedID, m.ACCESSID, m.TYPEID)
			end

			if addon.fireCallback then
				addon.fireCallback(addon.EVENTS.POST_ADDMESSAGE, m, this, resolvedEvent, textToDisplay, capturedR, capturedG, capturedB, capturedID)
			end
		else
			addon.dbg("ChatFrame_MessageEventHandler: empty output, skipping display")
		end
	end

	addon.dbg("ChatFrame_MessageEventHandler: cleanup and return")
	addon.resetCaptureState()
	m.CAPTUREOUTPUT = nil
	return handlerResult
end

-- ============================================================================
-- XANCHAT FEATURES INTEGRATION
-- ============================================================================

addon.playerList = addon.playerList or {}
addon.playerListByName = addon.playerListByName or {}
addon.playerListRing = addon.playerListRing or {}
addon.playerListRingPos = addon.playerListRingPos or 0
addon.HookedFrames = addon.HookedFrames or {}

local DEFAULTS = {
	hideSocial = false,
	addFontShadow = false,
	addFontOutline = false,
	hideScroll = false,
	shortNames = false,
	editBoxTop = false,
	hideTabs = false,
	hideVoice = false,
	hideEditboxBorder = false,
	enableSimpleEditbox = true,
	enableSEBDesign = false,
	enableCopyButton = true,
	enablePlayerChatStyle = true,
	enableChatTextFade = true,
	disableChatFrameFade = true,
	enableCopyButtonLeft = false,
	lockChatSettings = false,
	userChatAlpha = 0.25,
	enableEditboxAdjusted = false,
	enableOutWhisperColor = false,
	outWhisperColor = "FFF2307C",
	disableChatEnterLeaveNotice = false,
	hideChatMenuButton = false,
	moveSocialButtonToBottom = false,
	hideSideButtonBars = false,
	pageBufferLimit = 0,
	debugWrapper = true,
	debugChat = true,
	debugNoThrow = false,
}

local function initializeDatabase()
	if not XCHT_DB then
		XCHT_DB = {}
	end
	ApplyDefaults(XCHT_DB, DEFAULTS)
	addon.wrapperDebug = XCHT_DB.debugWrapper

	-- Setup History DB
	local currentPlayer = UnitName("player") or "Unknown"
	local currentRealm = (UnitFullName and select(2, UnitFullName("player"))) or select(2, UnitName("player")) or GetRealmName() or "Unknown"
	if not XCHT_HISTORY then XCHT_HISTORY = {} end
	XCHT_HISTORY[currentRealm] = XCHT_HISTORY[currentRealm] or {}
	XCHT_HISTORY[currentRealm][currentPlayer] = XCHT_HISTORY[currentRealm][currentPlayer] or {}
	_G.HistoryDB = XCHT_HISTORY[currentRealm][currentPlayer]
end

local function rebuildHookedFrames()
	if _G.CHAT_FRAMES and #_G.CHAT_FRAMES > 0 then
		for i = 1, #_G.CHAT_FRAMES do
			local frameName = _G.CHAT_FRAMES[i]
			local frame = _G[frameName]
			if frame then
				addon.HookedFrames[frameName] = frame
			end
		end
	end
end

function addon:IsRestricted()
	return XCHT_DB and XCHT_DB.lockChatSettings and InCombatLockdown and InCombatLockdown() or false
end

function addon:NotifyConfigLocked()
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: " .. (addon.L.LockChatSettingsAlert or "Settings are locked in combat."))
	end
end

function addon:setOutWhisperColor()
	local r, g, b = ChatTypeInfo["WHISPER"].r, ChatTypeInfo["WHISPER"].g, ChatTypeInfo["WHISPER"].b
	if XCHT_DB and XCHT_DB.enableOutWhisperColor and XCHT_DB.outWhisperColor then
		r, g, b = addon.HexToRGBA(XCHT_DB.outWhisperColor)
	end
	if r and g and b then
		ChangeChatColor("WHISPER_INFORM", r, g, b)
	end
end

function addon:setUserAlpha()
	local alpha = (XCHT_DB and tonumber(XCHT_DB.userChatAlpha)) or DEFAULT_CHATFRAME_ALPHA or 0.25
	if not CHAT_FRAMES then return end
	for i = 1, #CHAT_FRAMES do
		local frameName = CHAT_FRAMES[i]
		local frame = _G[frameName]
		if frame and CHAT_FRAME_TEXTURES then
			for k = 1, #CHAT_FRAME_TEXTURES do
				local tex = _G[frameName .. CHAT_FRAME_TEXTURES[k]]
				if tex then
					if XCHT_DB and XCHT_DB.disableChatFrameFade then
						tex:SetAlpha(alpha)
					else
						tex:SetAlpha(0)
					end
				end
			end
		end
	end
end


-- Dump debug log function
function addon:DumpDebugLog(maxLines)
	if not XCHT_DB or not XCHT_DB.debugLog then
		if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
			DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: debug log empty")
		end
		return
	end
	local log = XCHT_DB.debugLog
	local size = log.size or 0
	local limit = log.limit or 2000
	if size == 0 then
		if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
			DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: debug log empty")
		end
		return
	end
	local count = tonumber(maxLines) or 60
	if count < 1 then count = 1 end
	if count > size then count = size end
	local head = log.head or 0
	for i = count, 1, -1 do
		local idx = head - (i - 1)
		if idx <= 0 then idx = idx + limit end
		local line = log.data and log.data[idx]
		if line then
			if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
				DEFAULT_CHAT_FRAME:AddMessage(line)
			end
		end
	end
end

-- ============================================================================
-- UI_SCALE_CHANGED EVENT HANDLER
-- ============================================================================

function addon:UI_SCALE_CHANGED()
	if XCHT_DB and XCHT_DB.lockChatSettings and addon.isInAnyInstance() then return end
	if NUM_CHAT_WINDOWS then
		for i = 1, NUM_CHAT_WINDOWS do
			local n = ("ChatFrame%d"):format(i)
			local f = _G[n]
			if f then
				-- Always lock the frames regardless (using both calls just in case)
				SetChatWindowLocked(i, true)
				FCF_SetLocked(f, true)
			end
		end
	end
end

-- ============================================================================
-- LOADERS
-- ============================================================================

function addon:OnLoad()
	addon.dbg("OnLoad: START xanChat initialization")

	initializeDatabase()
	rebuildHookedFrames()
	addon.ensureCaptureProxyFrame()
	addon.registerUrlPatterns()
	addon.installUrlCopyHook()
	self:setDisableChatEnterLeaveNotice()
	self:setOutWhisperColor()

	if self.EnableFilterList then
		self:EnableFilterList()
	end
	if self.EnableStickyChannelsList then
		self:EnableStickyChannelsList()
	end

	addon.initPlayerInfo()
	addon.initUpdateCurrentPlayer()
	addon.doRosterUpdate()
	addon.doFriendUpdate()
	addon.doGuildUpdate()

	-- Turn off profanity filter
	if C_CVar then
		C_CVar.SetCVar("profanityFilter", "0")
	elseif SetCVar then
		SetCVar("profanityFilter", "0")
	end

	-- Toggle class colors for all channels
	if ToggleChatColorNamesByClassGroup then
		if CHAT_CONFIG_CHAT_LEFT then
			for _, v in pairs(CHAT_CONFIG_CHAT_LEFT) do
				ToggleChatColorNamesByClassGroup(true, v.type)
			end
		end
		-- Toggle class colors for all global channels (CHANNEL1-15)
		for iCh = 1, 15 do
			ToggleChatColorNamesByClassGroup(true, "CHANNEL" .. iCh)
		end
	end

	-- Check for chat box fading
	if XCHT_DB.disableChatFrameFade then
		self:setUserAlpha()
	end

	-- Show/hide chat social buttons
	if addon.IsRetail and XCHT_DB.hideSocial then
		if QuickJoinToastButton then
			QuickJoinToastButton:Hide()
			QuickJoinToastButton:SetScript("OnShow", function() end)
		end
	end

	if addon.IsRetail and XCHT_DB.moveSocialButtonToBottom then
		if ChatAlertFrame then
			ChatAlertFrame:ClearAllPoints()
			ChatAlertFrame:SetPoint("TOPLEFT", ChatFrame1, "BOTTOMLEFT", -33, -60)
		end
	end

	if XCHT_DB.hideChatMenuButton then
		if ChatFrameMenuButton then
			ChatFrameMenuButton:Hide()
			ChatFrameMenuButton:SetScript("OnShow", function() end)
		end
	end

	-- Toggle voice chat buttons if disabled
	if XCHT_DB.hideVoice then
		if ChatFrameToggleVoiceDeafenButton then ChatFrameToggleVoiceDeafenButton:Hide() end
		if ChatFrameToggleVoiceMuteButton then ChatFrameToggleVoiceMuteButton:Hide() end
		if ChatFrameChannelButton then ChatFrameChannelButton:Hide() end
	end

	-- Remove annoying guild loot messages by replacing them with original ones
	if YOU_LOOT_MONEY then
		_G["YOU_LOOT_MONEY_GUILD"] = YOU_LOOT_MONEY
	end
	if LOOT_MONEY_SPLIT then
		_G["LOOT_MONEY_SPLIT_GUILD"] = LOOT_MONEY_SPLIT
	end

	-- Setup all chat frames
	if NUM_CHAT_WINDOWS then
		for i = 1, NUM_CHAT_WINDOWS do
			self:setupChatFrame(i)
		end
	end

	-- Hook FCF_OpenTemporaryWindow for temporary whisper windows
	if FCF_OpenTemporaryWindow then
		local old_OpenTemporaryWindow = FCF_OpenTemporaryWindow
		FCF_OpenTemporaryWindow = function(...)
			local frame = old_OpenTemporaryWindow(...)
			if frame and frame.GetID then
				self:setupChatFrame(frame:GetID())
			end
			return frame
		end
	end

	-- Register UI_SCALE_CHANGED event
	self:RegisterEvent("UI_SCALE_CHANGED")

	-- Versioned settings update - lock frames when version changes
	local ver = (addon.GetAddOnMetadata and addon.GetAddOnMetadata(ADDON_NAME, "Version")) or "1.0"
	if XCHT_DB.dbVer == nil or XCHT_DB.dbVer ~= ver then
		if NUM_CHAT_WINDOWS then
			for i = 1, NUM_CHAT_WINDOWS do
				local n = ("ChatFrame%d"):format(i)
				local f = _G[n]
				if f then
					-- Always lock the frames regardless (using both calls just in case)
					SetChatWindowLocked(i, true)
					FCF_SetLocked(f, true)
				end
			end
		end
		XCHT_DB.dbVer = ver
	end

	-- Setup slash commands
	_G["SLASH_XANCHAT1"] = "/xanchat"
	SlashCmdList = _G.SlashCmdList or {}
	SlashCmdList["XANCHAT"] = function(msg)
		local cmd = string.lower((msg and string.match(msg, "^%s*(%S+)")) or "")
		if cmd == "debug" then
			XCHT_DB.debugWrapper = not XCHT_DB.debugWrapper
			addon.wrapperDebug = XCHT_DB.debugWrapper
			if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
				DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: wrapper debug " .. (XCHT_DB.debugWrapper and "ON" or "OFF"))
			end
			if addon.wrapperDebug and addon.wrapperLoaded then
				if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
					DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: wrapper loaded = " .. tostring(addon.wrapperLoaded))
				end
			end
			return
		end
		if cmd == "debugchat" then
			XCHT_DB.debugChat = not XCHT_DB.debugChat
			addon.debugChat = XCHT_DB.debugChat
			if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
				DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: chat debug " .. (addon.debugChat and "ON" or "OFF"))
			end
			return
		end
		if cmd == "debugdump" then
			self:DumpDebugLog(300)
			return
		end
		if cmd == "debugclear" then
			if XCHT_DB and XCHT_DB.debugLog then
				XCHT_DB.debugLog = nil
			end
			if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
				DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: debug log cleared")
			end
			return
		end
		if cmd == "debugnothrow" then
			XCHT_DB.debugNoThrow = not XCHT_DB.debugNoThrow
			if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
				DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: debug no-throw " .. (XCHT_DB.debugNoThrow and "ON" or "OFF"))
			end
			return
		end

		-- Check if settings are locked
		if addon.isInAnyInstance() and XCHT_DB.lockChatSettings then
			if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
				DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: " .. (addon.L.LockChatSettingsAlert or addon.L.ChatSettingsLocked or "Chat settings locked in instances"))
			end
			return
		end

		-- Open settings
		if _G.Settings and _G.Settings.OpenToCategory then
			local categoryID = addon.settingsCategoryID
			if not categoryID and addon.settingsCategory and addon.settingsCategory.GetID then
				categoryID = addon.settingsCategory:GetID()
			end
			if categoryID then
				_G.Settings.OpenToCategory(categoryID)
			else
				_G.Settings.OpenToCategory("xanChat")
			end
		elseif _G.InterfaceOptionsFrame_OpenToCategory then
			if not addon.IsRetail and _G.InterfaceOptionsFrame then
				_G.InterfaceOptionsFrame:Show()
			elseif InCombatLockdown and InCombatLockdown() or GameMenuFrame and GameMenuFrame:IsShown() or _G.InterfaceOptionsFrame then
				return
			end
			_G.InterfaceOptionsFrame_OpenToCategory(addon.aboutPanel)
		end
	end

	-- Setup copy frame for chat windows
	self:setupCopyFrameFeature()

	addon.dbg("OnLoad: COMPLETE xanChat initialization")
	if addon.configFrame then addon.configFrame:EnableConfig() end

	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFF20ff20%s|r] loaded:   /xanchat", ADDON_NAME, ver or "1.0"))
end

function addon:OnEnable()
	addon.dbg("OnEnable: installing message hooks")
	rebuildHookedFrames()
	addon.registerUrlPatterns()
	self:EnableAddon()
	-- Setup auto-save hooks for chat settings changes
	self:hookupAutoSave()
end

function addon:OnDisable()
	addon.dbg("OnDisable: removing hooks and cleaning up")
	if addon.unregisterAllCallbacks then
		addon.unregisterAllCallbacks()
	end
	self:DisableAddon()
	addon.unregisterUrlPatterns()
end

function addon:EnableAddon()
	if self._addonEnabled then
		addon.dbg("EnableAddon: already enabled")
		return
	end

	addon.dbg("EnableAddon: START installing message hooks")

	-- Initialize hook storage for RawHook system
	self._hooks = self._hooks or {}
	self._rawHooks = self._rawHooks or {}

	-- Create DummyFrame for proxy capture
	addon.ensureCaptureProxyFrame()

	-- Hook ChatFrame_MessageEventHandler using RawHook (stores original, unsafe)
	if _G["ChatFrame_MessageEventHandler"] then
		local uid = addon:RawHook(_G, "ChatFrame_MessageEventHandler", function(frame, event, ...)
			return addon:ChatFrame_MessageEventHandler(frame, event, ...)
		end)
		self._rawHooks["ChatFrame_MessageEventHandler"] = uid
		self._chatEventHooked = "global"
		addon.dbg("EnableAddon: global ChatFrame_MessageEventHandler RawHooked")
	elseif _G.ChatFrameMixin and _G.ChatFrameMixin.MessageEventHandler then
		-- Direct function assignment
		local hookCount = 0
		for frameName, frame in pairs(addon.HookedFrames) do
			if frame and frame.MessageEventHandler then
				-- Store original for restoration
				self._hooks[frameName] = frame.MessageEventHandler
				-- Direct assignment
				frame.MessageEventHandler = function(this, event, ...)
					return addon:ChatFrame_MessageEventHandler(this, event, ...)
				end
				self._rawHooks[frameName] = true
				hookCount = hookCount + 1
			end
		end
		self._chatEventHooked = "frame"
		addon.dbg("EnableAddon: hooked " .. hookCount .. " frame MessageEventHandlers with direct assignment")
	else
		addon.dbg("EnableAddon: ERROR - no message handler available")
	end

	-- Note: Proxy capture is handled by the manual AddMessage hook in ensureCaptureProxyFrame()
	-- which sets addon.captureState.text, addon.captureState.color, etc.

	self._addonEnabled = true
	addon.dbg("EnableAddon: COMPLETE hooks installed")
end

function addon:DisableAddon()
	if not self._addonEnabled then
		addon.dbg("DisableAddon: already disabled")
		return
	end

	addon.dbg("DisableAddon: START removing message hooks")

	-- Unhook RawHooked ChatFrame_MessageEventHandler
	if self._chatEventHooked == "global" and self._rawHooks and self._rawHooks["ChatFrame_MessageEventHandler"] then
		addon:Unhook(_G, "ChatFrame_MessageEventHandler")
		self._rawHooks["ChatFrame_MessageEventHandler"] = nil
		addon.dbg("DisableAddon: unhooked global ChatFrame_MessageEventHandler")
	elseif self._chatEventHooked == "frame" and self._hooks then
		-- Restore frame-based hooks by restoring original functions
		local restoreCount = 0
		for frameName, originalFunc in pairs(self._hooks) do
			if frameName ~= "DummyFrame" and frameName ~= "ChatFrame_MessageEventHandler" then
				local frame = addon.HookedFrames[frameName]
				if frame then
					frame.MessageEventHandler = originalFunc
					restoreCount = restoreCount + 1
				end
			end
		end
		addon.dbg("DisableAddon: restored " .. restoreCount .. " frame MessageEventHandlers")
	end

	-- Unhook DummyFrame.AddMessage
	if self._rawHooks and self._rawHooks["DummyFrame"] then
		addon:Unhook(addon.captureProxyFrame, "AddMessage")
		self._rawHooks["DummyFrame"] = nil
	end

	self._chatEventHooked = nil
	self._addonEnabled = false
	addon.dbg("DisableAddon: COMPLETE hooks removed")
end
