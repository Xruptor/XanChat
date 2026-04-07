--[[
	XanChat chat pipeline
	Improvements:
	- Extracted secret payload handler to separate function (90+ lines saved)
	- Consolidated message processing flow with early returns
	- Simplified color extraction and channel info building
	- Reduced redundant debug calls in hot path
	- Consolidated PLAYER_INFO extraction logic
	- Fixed redundant nil checks in extractFlagInfo
	- Simplified join/leave suppression check
	- Fixed processSecretPayload parameter order bug (frame vs this)
	- Restored isChatMessageEvent function (was incorrectly removed)
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- SECRET VALUE HANDLING ARCHITECTURE
-- ============================================================================
--
-- CRITICAL: WoW protects certain values as "secret" during boss encounters
-- and other restricted contexts. Secret values cannot be:
--   - Modified with gsub() or other string functions
--   - Used in string concatenation with non-secret values
--   - Compared directly with other strings
--
-- The codebase has two paths:
--   1. PROXY PATH: For normal messages (safe to process and modify)
--   2. DIRECT SAFE PATH: For secret payloads (minimal processing, no gsub)
--
-- When modifying this code, ensure secret value handling is preserved!
-- ============================================================================

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local MAX_GLOBAL_CHANNELS = 15

-- ============================================================================
-- WOW PROJECT DETECTION
-- ============================================================================

local WOW_PROJECT_ID = _G.WOW_PROJECT_ID
local WOW_PROJECT_MAINLINE = _G.WOW_PROJECT_MAINLINE
local WOW_PROJECT_CLASSIC = _G.WOW_PROJECT_CLASSIC
local WOW_PROJECT_WRATH_CLASSIC = _G.WOW_PROJECT_WRATH_CLASSIC

addon.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
addon.IsClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
addon.IsWLK_C = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

-- ============================================================================
-- EVENT CALLBACK SYSTEM
-- ============================================================================

local FRAME_EVENTS = {
	FRAME_MESSAGE = "XanChat_FrameMessage",
	PRE_ADDMESSAGE = "XanChat_PreAddMessage",
	POST_ADDMESSAGE = "XanChat_PostAddMessage",
	POST_ADDMESSAGE_BLOCKED = "XanChat_PostAddMessageBlocked",
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Check if event is a CHAT_MSG event (starts with "CHAT_MSG")
local function isChatMessageEvent(event)
	if type(event) ~= "string" then return false end
	return string.sub(event, 1, 8) == "CHAT_MSG"
end

-- Lock all chat frames
local function lockAllChatFrames()
	if not _G.NUM_CHAT_WINDOWS then return end

	for i = 1, _G.NUM_CHAT_WINDOWS do
		local f = _G[("ChatFrame%d"):format(i)]
		if f then
			if _G.SetChatWindowLocked then
				_G.SetChatWindowLocked(i, true)
			end
			if _G.FCF_SetLocked then
				_G.FCF_SetLocked(f, true)
			end
		end
	end
end

-- Get chat category from chat type
local function getChatCategory(chatType)
	if _G.Chat_GetChatCategory then
		return _G.Chat_GetChatCategory(chatType)
	elseif _G.ChatFrameUtil and _G.ChatFrameUtil.GetChatCategory then
		return _G.ChatFrameUtil.GetChatCategory(chatType)
	end
	return chatType
end

-- Parse player name from colored name string
local function parsePlayerName(coloredName)
	if type(coloredName) ~= "string" then return nil, nil end
	return coloredName:match("([^%-]+)%-?(.*)")
end

-- Safe access to DEFAULT_CHAT_FRAME.AddMessage
local function printToChat(message)
	if _G.DEFAULT_CHAT_FRAME and _G.DEFAULT_CHAT_FRAME.AddMessage then
		_G.DEFAULT_CHAT_FRAME:AddMessage(message)
	end
end

-- Check if string has carriage return and clean it
local function cleanCarriageReturns(text)
	if type(text) ~= "string" then return text end
	if string.find(text, "\r", 1, true) then
		return string.gsub(text, "\r", " ")
	end
	return text
end

-- ============================================================================
-- PLAYER NAME EXTRACTION
-- ============================================================================

-- Try to get player info from GUID
local function tryGetPlayerFromGUID(guid)
	if not guid or type(guid) ~= "string" or not _G.GetPlayerInfoByGUID then
		return nil
	end

	local _, englishClass, _, _, _, name, realmName = _G.GetPlayerInfoByGUID(guid)
	if name then
		return {
			player_name = name,
			player_class = englishClass,
			server_name = realmName,
			player_guid = guid,
		}
	end
	return nil
end

-- Try to get player info from lineID
local function tryGetPlayerFromLineID(lineID, skipGuidLookup)
	if not _G.C_ChatInfo or not _G.GetPlayerInfoByGUID then return nil end
	if type(lineID) ~= "number" or lineID <= 0 then return nil end

	local isValid = _G.C_ChatInfo.IsValidChatLine and _G.C_ChatInfo.IsValidChatLine(lineID) or true
	if not isValid then return nil end

	local result = {}

	if _G.C_ChatInfo.GetChatLineSenderName then
		local nameChk = _G.C_ChatInfo.GetChatLineSenderName(lineID)
		if nameChk then
			result.player_name_with_realm = nameChk
		end
	end

	if not skipGuidLookup and _G.C_ChatInfo.GetChatLineSenderGUID then
		local guidChk = _G.C_ChatInfo.GetChatLineSenderGUID(lineID)
		if guidChk then
			result.player_guid = guidChk
			local playerInfo = tryGetPlayerFromGUID(guidChk)
			if playerInfo then
				result.player_name = playerInfo.player_name
				result.player_class = playerInfo.player_class
				result.server_name = playerInfo.server_name
			end
		end
	end

	return next(result) and result or nil
end

-- Extract player name from sender arg with fallbacks
local function extractPlayerInfo(arg2, arg12, arg11, isArg2Secret)
	local senderName = arg2 or ""

	if not isArg2Secret then
		return {
			sender_name = senderName,
			player_name = parsePlayerName(_G.Ambiguate and _G.Ambiguate(senderName, "none") or senderName),
		}
	end

	-- arg2 is secret, try fallbacks
	local playerInfo = tryGetPlayerFromGUID(arg12)
	if playerInfo then
		local lineInfo = tryGetPlayerFromLineID(arg11, true)
		if lineInfo and lineInfo.player_name_with_realm then
			playerInfo.player_name_with_realm = lineInfo.player_name_with_realm
		end
	else
		playerInfo = tryGetPlayerFromLineID(arg11)
	end

	playerInfo = playerInfo or {}
	playerInfo.sender_name = senderName
	return playerInfo
end

-- ============================================================================
-- DATA EXTRACTION HELPERS
-- ============================================================================

-- Extract flag information (GM, DEV, GUIDE, NEWCOMER)
local function extractFlagInfo(s, arg6, arg7)
	if not s or type(arg6) ~= "string" or arg6 == "" then return end

	if arg6 == "GM" or arg6 == "DEV" then
		s.player_flag = "|TInterface\\ChatFrame\\UI-ChatIcon-Blizz:12:20:0:0:32:16:4:28:0:16|t "
		return
	end

	if arg6 == "GUIDE" or arg6 == "NEWCOMER" then
		if not _G.ChatFrame_GetMentorChannelStatus or not _G.Enum or not _G.Enum.PlayerMentorshipStatus or not _G.C_ChatInfo then
			return
		end

		local mentorStatus = _G.ChatFrame_GetMentorChannelStatus(
			arg6 == "GUIDE" and _G.Enum.PlayerMentorshipStatus.Mentor or _G.Enum.PlayerMentorshipStatus.Newcomer,
			_G.C_ChatInfo.GetChannelRulesetForChannelID(arg7)
		)

		if mentorStatus == _G.Enum.PlayerMentorshipStatus.Mentor then
			s.player_flag = (_G.NPEV2_CHAT_USER_TAG_GUIDE or "[Guide]") .. " "
		elseif mentorStatus == _G.Enum.PlayerMentorshipStatus.Newcomer then
			s.player_flag = _G.NPEV2_CHAT_USER_TAG_NEWCOMER or "[New]"
		end
		return
	end

	local flagKey = "CHAT_FLAG_" .. arg6
	if _G[flagKey] then
		s.player_flag = _G[flagKey] or ""
	end
end

-- Extract mobile texture icon
local function extractMobileInfo(s, arg15, info)
	if not s or not info or not arg15 then return end

	local mobileFn = _G.ChatFrame_GetMobileEmbeddedTexture or (_G.ChatFrameUtil and _G.ChatFrameUtil.GetMobileEmbeddedTexture)
	if mobileFn then
		s.mobile_icon = mobileFn(info.r or 1, info.g or 1, info.b or 1) or ""
	end
end

-- Extract type prefix from CHAT_*_GET templates
local function extractTypePrefix(s, chatType)
	if not s or chatType == "CHANNEL" then return end

	local useShortNames = _G.XCHT_DB and _G.XCHT_DB.shortNames
	local chatGetKey = "CHAT_" .. chatType .. "_GET"
	local chatGet = (useShortNames and addon.L and addon.L[chatGetKey]) or _G[chatGetKey]

	if type(chatGet) ~= "string" then return end

	local prefix = chatGet:match("^(.*)%%s")
	if prefix then
		s.type_prefix = prefix:gsub("%s+$", "")
	end
end

-- Extract language information
local function extractLanguageInfo(s, arg3)
	if not s or type(arg3) ~= "string" or arg3 == "" then return end

	s[arg3 == "Universal" and "LANGUAGE_NOSHOW" or "language"] = arg3
end

-- Get chat target from event args
local function getChatTarget(chatGroup, arg2, arg8)
	if chatGroup == "CHANNEL" or chatGroup == "BN_CONVERSATION" then
		return tostring(arg8 or "")
	elseif chatGroup == "WHISPER" or chatGroup == "BN_WHISPER" then
		return arg2
	end
	return nil
end

-- Get chat info (color, etc.)
local function getChatTypeInfo(infoType)
	if _G.ChatTypeInfo and _G.ChatTypeInfo[infoType] then
		return _G.ChatTypeInfo[infoType]
	end
	return _G.ChatTypeInfo and _G.ChatTypeInfo.SYSTEM or { r=1, g=1, b=1, id=0 }
end

-- ============================================================================
-- SECRET PAYLOAD HANDLER (Direct Safe Path)
-- ============================================================================

-- Build channel info for display during lockdown
local function buildLockdownChannelInfo(m)
	local skipChannelInfo = addon.SKIP_STYLING_EVENTS and m.chat_type and addon.SKIP_STYLING_EVENTS[m.chat_type]
	if skipChannelInfo or not m.channel_number or m.channel_number == "" or m.channel_number == "0" then
		return ""
	end

	local channelNum = m.channel_number
	local channelName = m.channel_name or ""
	local useShortNames = _G.XCHT_DB and _G.XCHT_DB.shortNames

	-- Try centralized channel shortening function first
	if m.OUTPUT and not addon.isSecretValue(m.OUTPUT) then
		local success = pcall(addon.applyShortChannelNamesToSections, m)
		if success and m.channel_name and m.channel_name ~= "" then
			channelName = m.channel_name
		end
	end

	-- Fallback: use lockdown-safe channel extraction and shortening
	if channelName == "" and useShortNames and addon.getShortChannelPatternOnLockdown then
		channelName = addon.getShortChannelPatternOnLockdown(m, channelNum) or ""
	end

	-- Build channelInfo with the (potentially shortened) channel name
	if channelName ~= "" then
		return useShortNames
			and "|Hchannel:"..channelNum.."|h["..channelNum.."] ["..channelName.."]|h "
			or "|Hchannel:"..channelNum.."|h["..channelNum..". "..channelName.."]|h "
	end

	return "|Hchannel:"..channelNum.."|h["..channelNum.."]|h "
end

-- Get channel-specific color for lockdown messages
local function getChannelColor(m, info)
	local outR, outG, outB, outID = info.r or 1, info.g or 1, info.b or 1, info.id or 0

	if m.channel_number and m.channel_number ~= "" and m.channel_number ~= "0" then
		local channelTypeKey = "CHANNEL" .. m.channel_number
		if _G.ChatTypeInfo and _G.ChatTypeInfo[channelTypeKey] then
			local c = _G.ChatTypeInfo[channelTypeKey]
			return c.r or outR, c.g or outG, c.b or outB, c.id or outID
		end
	end

	return outR, outG, outB, outID
end

-- Process secret payload messages (during boss encounters)
-- Note: Function is called as processSecretPayload(self, this, event, ...) where:
--   self = addon table, this = ChatFrame, event = event name
local function processSecretPayload(_, frame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
	addon.resetCaptureState()

	local m = addon:ParseChatEvent(frame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
	if type(m) ~= "table" then
		m = addon.sectionOriginal or {}
	end

	-- Check if this frame should receive this message by replicating Blizzard's routing logic
	-- This replaces the old _lockdownProcessedMessages deduplication approach
	local targetFrames = addon.getTargetChatFrames and addon.getTargetChatFrames(m.CHATTYPE or event, m.channel_number or "")
	local frameShouldReceive = false

	if targetFrames and #targetFrames > 0 then
		-- Check if the current frame is in the target list
		for _, targetFrame in ipairs(targetFrames) do
			if targetFrame == frame then
				frameShouldReceive = true
				break
			end
		end
	else
		-- Fallback: if we couldn't determine target frames, allow the message through
		-- This preserves the original behavior if the new logic fails
		frameShouldReceive = true
	end

	-- Debug output for frame routing decision
	if addon.dbg then
		local frameName = frame and frame.GetName and frame:GetName() or "<unknown>"
		local targetCount = targetFrames and #targetFrames or 0
		addon.dbg("processSecretPayload: frame=" .. frameName .. " event=" .. tostring(event) ..
			" channel=" .. tostring(m.channel_number or "") .. " frameShouldReceive=" .. tostring(frameShouldReceive) ..
			" targetFrames=" .. tostring(targetCount))
	end

	if not frameShouldReceive then
		-- This frame shouldn't receive this message, skip it
		return true
	end

	-- Extract channel info from OUTPUT if deferred (already attempted in ParseChatEvent)
	-- ParseChatEvent calls extractChannelInfo which sets deferredChannelExtraction if needed
	if not m.channel_number or m.channel_number == "" then
		addon.extractChannelFromOutputIfDeferred(m)
	end

	-- Get channel-specific color
	local info = m.INFO or getChatTypeInfo(m.CHATTYPE or "")
	local outR, outG, outB, outID = getChannelColor(m, info)

	-- Build channel info and player link
	addon.StylePlayerSection(m)
	local channelInfo = buildLockdownChannelInfo(m)
	local skipStyling = addon.SKIP_STYLING_EVENTS and m.chat_type and addon.SKIP_STYLING_EVENTS[m.chat_type]
	local textToDisplay

	if skipStyling then
		textToDisplay = arg1 or ""
	else
		-- Check if arg1 contains a format placeholder (e.g., %s in achievement messages)
		-- ONLY apply to system events, not user chat channels
		local chatType = m.chat_type or ""
		local isSystemEvent = addon.isSystemOnlyEvent and addon.isSystemOnlyEvent(chatType)

		-- During lockdown, we can't safely use string operations on secret values
		-- Use SafeMatch/SafeGSub which handle secret values via pcall
		local hasFormatPlaceholder = false
		local arg1Str = arg1 or ""
		if isSystemEvent and addon.SafeMatch then
			hasFormatPlaceholder = addon.SafeMatch(arg1Str, "^(.-)[%%][1-9dsfgx]") ~= nil
		end

		if hasFormatPlaceholder and m.styled_player_name and m.styled_player_name ~= "" then
			-- Replace the format placeholder with the styled player name
			local gsubFn = addon.SafeGSub or string.gsub
			textToDisplay = channelInfo .. gsubFn(arg1Str, "([%%][1-9dsfgx])", m.styled_player_name, 1)
		else
			-- Default: prepend player link with colon
			textToDisplay = channelInfo .. (m.player_link or "") .. (m.player_link and ": " or "") .. (arg1 or "")
		end
	end

	-- Display the message
	-- During lockdown, textToDisplay contains secret values from arg1
	-- Only check isSafeString for non-secret values (secret values can be displayed directly)
	local textContainsSecret = addon.isSecretValue and addon.isSecretValue(textToDisplay)
	if textContainsSecret or (addon.isSafeString and addon.isSafeString(textToDisplay)) or not addon.isSafeString then
		frame:AddMessage(textToDisplay, outR, outG, outB, outID, false, m.ACCESSID, m.TYPEID)
	end

	return true
end

-- ============================================================================
-- MAIN MESSAGE HANDLER
-- ============================================================================

function addon:DebugChatHandlerState(context)
	if not addon.dbg then return end
	local handler = _G.ChatFrame_MessageEventHandler
	local isSecureVar = _G.issecurevariable and _G.issecurevariable("ChatFrame_MessageEventHandler")
	local orig = addon.hooks and addon.hooks._G and addon.hooks._G.ChatFrame_MessageEventHandler

	local stateKey = table.concat({
		tostring(context),
		tostring(addon._chatEventHooked),
		tostring(isSecureVar),
		tostring(handler),
		tostring(orig),
		tostring(handler == orig),
		tostring(handler == addon.ChatFrame_MessageEventHandler),
	}, "|")

	if addon._chatHandlerStateLast == stateKey then return end
	addon._chatHandlerStateLast = stateKey

	self.dbg(table.concat({
		"ChatHandlerState: context=" .. tostring(context),
		" hookMode=" .. tostring(addon._chatEventHooked),
		" isSecureVar=" .. tostring(isSecureVar),
		" handler=" .. (addon.dbgSafeValue and addon.dbgSafeValue(handler) or tostring(handler)),
		" orig=" .. (addon.dbgSafeValue and addon.dbgSafeValue(orig) or tostring(orig)),
		" handlerIsOrig=" .. tostring(handler == orig),
		" handlerIsSelf=" .. tostring(handler == addon.ChatFrame_MessageEventHandler),
	}, " "))
end

-- Parse WoW event args into chat sections
function addon:ParseChatEvent(_, event, ...)
	self.dbg("ParseChatEvent: START event=" .. tostring(event))

	local arg1, arg2, arg3, _, _, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, _, arg15 = ...
	local isSecret = addon.isSecretValue and addon.isSecretValue(arg1)

	self.dbg("ParseChatEvent: isSecret=" .. tostring(isSecret))

	-- BN_INLINE_TOAST_ALERT and hidden sender passthrough
	if select(16, ...) or not isChatMessageEvent(event) then
		self.dbg("ParseChatEvent: passthrough (hidden sender or not chat message)")
		return nil, nil
	end

	local chatType = string.sub(event, 10)
	local info = getChatTypeInfo(chatType)

	addon.resetSectionBuffer(addon.sectionOriginal)
	local s = addon.sectionOriginal

	s.LINE_ID = arg11 or 0
	s.INFOTYPE = chatType
	s.CHATTYPE = chatType
	s.EVENT = event
	s.CHATGROUP = getChatCategory(chatType)

	extractTypePrefix(s, chatType)
	s.CHATTARGET = getChatTarget(s.CHATGROUP, arg2, arg8)

	-- Set ACCESSID and TYPEID for the report system
	s.ACCESSID = (_G.ChatHistory_GetAccessId and _G.ChatHistory_GetAccessId(s.CHATGROUP, s.CHATTARGET) or arg11 or 0)
	s.TYPEID = (_G.ChatHistory_GetTypeInfo and _G.ChatHistory_GetTypeInfo(s.CHATTYPE, s.CHATTARGET, arg12 or arg13) or 0)

	-- Message text handling
	local isUnsafeMessage = isSecret or not (addon.isSafeString and addon.isSafeString(arg1))
	s.message_text = isUnsafeMessage and (arg1 or "") or (arg1 or ""):gsub("^%s*(.-)%s*$", "%1")

	-- Player information extraction
	local isArg2Secret = addon.isSecretValue and addon.isSecretValue(arg2)
	local playerInfo = extractPlayerInfo(arg2, arg12, arg11, isArg2Secret)

	if playerInfo.player_name then s.player_name = playerInfo.player_name end
	if playerInfo.player_class then s.player_class = playerInfo.player_class end
	if playerInfo.server_name then s.server_name = playerInfo.server_name end
	if playerInfo.player_guid then s.player_guid = playerInfo.player_guid end
	if playerInfo.player_name_with_realm then s.player_name_with_realm = playerInfo.player_name_with_realm end

	-- Extract name and server from colored name for non-secret arg2
	if not isArg2Secret then
		local nameToParse = arg2 or s.player_name_with_realm
		local plr, svr = parsePlayerName(nameToParse)
		if plr then s.player_name = plr end
		if svr and string.len(svr) > 0 then
			s.server_separator = "-"
			s.server_name = svr
		end

		if _G.Ambiguate and nameToParse then
			s.player_name_display = _G.Ambiguate(nameToParse, chatType == "GUILD" and "guild" or "none")
		end
	end

	-- Store additional data needed for link generation
	s.sender_name = arg2 or s.player_name_with_realm
	s.arg11 = arg11 or 0
	s.arg13 = arg13
	s.chat_type = chatType
	s.chat_target = s.CHATTARGET or ""

	extractLanguageInfo(s, arg3)
	addon.extractChannelInfo(s, arg7, arg8, arg9, arg10, s.CHATGROUP)
	extractFlagInfo(s, arg6, arg7)
	extractMobileInfo(s, arg15, info)

	s.INFO = info

	addon.prepareWorkingSections()
	return addon.sectionWorking, info
end

-- Events that should use Blizzard's output directly
local CHANNEL_NOTICE_EVENTS = {
	CHAT_MSG_CHANNEL_NOTICE = true,
	CHAT_MSG_CHANNEL_NOTICE_USER = true,
	CHAT_MSG_CHANNEL_JOIN = true,
	CHAT_MSG_CHANNEL_LEAVE = true,
	CHAT_MSG_TEXT_EMOTE = true,
	CHAT_MSG_EMOTE = true,
}

local function isChannelNoticeEvent(event)
	return CHANNEL_NOTICE_EVENTS[event]
end

-- Check if message should be suppressed (join/leave)
local function shouldSuppressJoinLeave(resolvedEvent, textToDisplay)
	if not addon.shouldSuppressJoinLeaveMessage then return false end
	return addon:shouldSuppressJoinLeaveMessage(resolvedEvent, textToDisplay)
end

-- Main chat frame message event handler
function addon:ChatFrame_MessageEventHandler(this, event, ...)
	local frameName = this and this.GetName and this:GetName() or "<unknown>"
	self.dbg("ChatFrame_MessageEventHandler: START event=" .. tostring(event) .. " frame=" .. tostring(frameName))

	local isSecretPayload = (addon.isSecretValue and addon.isSecretValue(select(1, ...))) or
	                        (addon.isSecretValue and addon.isSecretValue(select(2, ...)))
	local processMode = addon.EventIsProcessed and addon.EventIsProcessed(event)

	self.dbg("ChatFrame_MessageEventHandler: isSecretPayload=" .. tostring(isSecretPayload) .. " processMode=" .. tostring(processMode))

	-- Frame validation
	if not this or not addon.HookedFrames or not addon.HookedFrames[frameName] then
		self.dbg("ChatFrame_MessageEventHandler: frame not managed, passthrough")
		return addon.callOriginalMessageHandler and addon.callOriginalMessageHandler(self, this, event, ...) or true
	end

	-- BN_INLINE_TOAST_ALERT passthrough
	if event == "CHAT_MSG_BN_INLINE_TOAST_ALERT" then
		self.dbg("ChatFrame_MessageEventHandler: BN_INLINE_TOAST_ALERT, passing to Blizzard handler")
		return addon.callOriginalMessageHandler and addon.callOriginalMessageHandler(self, this, event, ...) or true
	end

	-- Secret payload path - use direct safe rendering
	if isSecretPayload then
		self:DebugChatHandlerState("secret-payload")
		return processSecretPayload(self, this, event, ...)
	end

	-- Non-secret path: clean carriage returns and process normally
	local arg1 = cleanCarriageReturns(select(1, ...))

	-- Run Blizzard frame message filters
	local shouldDiscard
	if addon.runFrameMessageFilters then
		shouldDiscard, arg1 = addon.runFrameMessageFilters(this, event, arg1, select(2, ...))
	end

	if shouldDiscard then
		self.dbg("ChatFrame_MessageEventHandler: message discarded by Blizzard filters")
		return true
	end

	self.dbg("ChatFrame_MessageEventHandler: NON-SECRET path, using proxy capture")

	local parsedMessage, info = addon:ParseChatEvent(this, event, arg1, select(2, ...))

	if type(parsedMessage) == "boolean" and parsedMessage == true then
		self.dbg("ChatFrame_MessageEventHandler: ParseChatEvent returned boolean, passing through")
		return true
	end
	if not info or type(parsedMessage) ~= "table" then
		self.dbg("ChatFrame_MessageEventHandler: ParseChatEvent failed, passthrough")
		return addon.callOriginalMessageHandler and addon.callOriginalMessageHandler(self, this, event, arg1, select(2, ...)) or true
	end

	local m = parsedMessage
	local resolvedEvent = m.EVENT or event

	addon.resetCaptureState()
	m.OUTPUT = nil
	m.DONOTPROCESS = nil

	if addon.fireCallback then
		addon.fireCallback(FRAME_EVENTS.FRAME_MESSAGE, m, this, resolvedEvent)
	end

	-- Proxy capture for non-secret messages
	local proxyFrame = (addon.CreateProxy and addon:CreateProxy(this)) or nil
	local handlerResult
	if proxyFrame then
		m.CAPTUREOUTPUT = proxyFrame
		addon.captureState.proxy = proxyFrame
		handlerResult = addon.callOriginalMessageHandler(self, proxyFrame, event, arg1, select(2, ...))
		addon:RestoreProxy()
		m.OUTPUT = addon.captureState.text
		addon.extractChannelFromOutputIfDeferred(m)
	end

	m.CAPTUREOUTPUT = false
	addon.captureState.proxy = nil

	if type(m.OUTPUT) ~= "string" then
		self.dbg("ChatFrame_MessageEventHandler: capture miss, passthrough")
		addon.resetCaptureState()
		return addon.callOriginalMessageHandler(self, this, event, arg1, select(2, ...))
	end

	if type(m.message_text) ~= "string" then
		m.message_text = (addon.dbgSafeValue and addon.dbgSafeValue(m.message_text)) or tostring(m.message_text) or ""
	end

	-- Build display text
	if type(m.OUTPUT) == "string" and not m.DONOTPROCESS then
		local infoRow = m.INFO or info or {}
		local outR, outG, outB, outID = infoRow.r or 1, infoRow.g or 1, infoRow.b or 1, infoRow.id or 0
		local applyPatterns = addon.shouldRunPatternPass and addon.shouldRunPatternPass(isSecretPayload, processMode)

		if applyPatterns then
			m.message_text = addon.MatchPatterns(m, "FRAME")
			if type(m.message_text) ~= "string" then
				m.message_text = addon.dbgSafeValue and addon.dbgSafeValue(m.message_text) or tostring(m.message_text) or ""
			end
		end

		if addon.fireCallback then
			addon.fireCallback(FRAME_EVENTS.PRE_ADDMESSAGE, m, this, resolvedEvent, addon.FormatChatMessage(m), outR, outG, outB, outID)
		end

		if applyPatterns then
			m.message_text = addon.ReplaceMatches(m, "FRAME")
		end

		addon.StylePlayerSection(m)
		if addon.applyShortChannelNamesToSections then
			addon.applyShortChannelNamesToSections(m)
		end

		-- Determine output text based on processing mode
		local textToDisplay

		if isChannelNoticeEvent(resolvedEvent) then
			textToDisplay = (m.PRE or "") .. (m.OUTPUT or "") .. (m.POST or "")
		elseif processMode == (addon.EventProcessingType and addon.EventProcessingType.Full) then
			textToDisplay = addon.FormatChatMessage(m) or ""
		elseif processMode == (addon.EventProcessingType and addon.EventProcessingType.PatternsOnly) then
			textToDisplay = (m.PRE or "") .. (m.message_text or "") .. (m.POST or "")
		else
			textToDisplay = (m.PRE or "") .. (m.OUTPUT or "") .. (m.POST or "")
		end

		-- Check if message should be suppressed
		if shouldSuppressJoinLeave(resolvedEvent, textToDisplay) then
			m.DONOTPROCESS = true
		end

		m.OUTPUT = textToDisplay

		-- Add message to frame or fire blocked callback
		if m.DONOTPROCESS then
			if addon.fireCallback then
				addon.fireCallback(FRAME_EVENTS.POST_ADDMESSAGE_BLOCKED, m, this, resolvedEvent, textToDisplay, outR, outG, outB, outID)
			end
		elseif (addon.dbgSafeLength and addon.dbgSafeLength(textToDisplay) or 0) > 0 then
			local capturedR = addon.captureState.color.r or outR
			local capturedG = addon.captureState.color.g or outG
			local capturedB = addon.captureState.color.b or outB
			local capturedID = addon.captureState.color.id or outID
			local isCensored = arg11 and _G.C_ChatInfo.IsChatLineCensored(arg11)
			local visibleText = isCensored and (arg1 or "") or textToDisplay

			if isCensored then
				this:AddMessage(visibleText, capturedR, capturedG, capturedB, capturedID, false, m.ACCESSID, m.TYPEID, event, { ... }, function(text) return text end)
			else
				this:AddMessage(visibleText, capturedR, capturedG, capturedB, capturedID, false, m.ACCESSID, m.TYPEID)
			end

			if addon.fireCallback then
				addon.fireCallback(FRAME_EVENTS.POST_ADDMESSAGE, m, this, resolvedEvent, textToDisplay, capturedR, capturedG, capturedB, capturedID)
			end
		end
	end

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
	debugWrapper = false,
	debugChat = false,
	debugNoThrow = false,
}

local function initializeDatabase()
	if not _G.XCHT_DB then
		_G.XCHT_DB = {}
	end
	if addon.ApplyDefaults then
		addon.ApplyDefaults(_G.XCHT_DB, DEFAULTS)
	else
		for k, v in pairs(DEFAULTS) do
			if _G.XCHT_DB[k] == nil then
				_G.XCHT_DB[k] = v
			end
		end
	end
	addon.wrapperDebug = _G.XCHT_DB.debugWrapper

	local currentPlayer = (_G.UnitName and _G.UnitName("player")) or "Unknown"
	local currentRealm = "Unknown"
	if _G.GetRealmName then
		currentRealm = _G.GetRealmName() or "Unknown"
	elseif _G.UnitFullName then
		currentRealm = select(2, _G.UnitFullName("player")) or "Unknown"
	elseif _G.UnitName then
		currentRealm = select(2, _G.UnitName("player")) or "Unknown"
	end

	if not _G.XCHT_HISTORY then _G.XCHT_HISTORY = {} end
	_G.XCHT_HISTORY[currentRealm] = _G.XCHT_HISTORY[currentRealm] or {}
	_G.XCHT_HISTORY[currentRealm][currentPlayer] = _G.XCHT_HISTORY[currentRealm][currentPlayer] or {}
	_G.HistoryDB = _G.XCHT_HISTORY[currentRealm][currentPlayer]
end

local function rebuildHookedFrames()
	if _G.CHAT_FRAMES then
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
	return _G.XCHT_DB and _G.XCHT_DB.lockChatSettings and _G.InCombatLockdown and _G.InCombatLockdown() or false
end

function addon:NotifyConfigLocked()
	printToChat("|cFF20ff20XanChat|r: " .. (addon.L.LockChatSettingsAlert or "Settings are locked in combat."))
end

function addon:setOutWhisperColor()
	if not _G.ChatTypeInfo or not _G.ChatTypeInfo["WHISPER"] then return end
	local r, g, b = _G.ChatTypeInfo["WHISPER"].r, _G.ChatTypeInfo["WHISPER"].g, _G.ChatTypeInfo["WHISPER"].b
	if _G.XCHT_DB and _G.XCHT_DB.enableOutWhisperColor and _G.XCHT_DB.outWhisperColor and addon.HexToRGBA then
		r, g, b = addon.HexToRGBA(_G.XCHT_DB.outWhisperColor)
	end
	if r and g and b and _G.ChangeChatColor then
		_G.ChangeChatColor("WHISPER_INFORM", r, g, b)
	end
end

function addon:setUserAlpha()
	if not _G.XCHT_DB then return end
	local alpha = tonumber(_G.XCHT_DB.userChatAlpha) or _G.DEFAULT_CHATFRAME_ALPHA or 0.25
	if not _G.CHAT_FRAMES then return end

	for i = 1, #_G.CHAT_FRAMES do
		local frameName = _G.CHAT_FRAMES[i]
		local frame = _G[frameName]
		if frame and _G.CHAT_FRAME_TEXTURES then
			for k = 1, #_G.CHAT_FRAME_TEXTURES do
				local tex = _G[frameName .. _G.CHAT_FRAME_TEXTURES[k]]
				if tex then
					tex:SetAlpha(_G.XCHT_DB.disableChatFrameFade and alpha or 0)
				end
			end
		end
	end
end

function addon:DumpDebugLog(maxLines)
	if not _G.XCHT_DB or not _G.XCHT_DB.debugLog then
		printToChat("|cFF20ff20XanChat|r: debug log empty")
		return
	end

	local log = _G.XCHT_DB.debugLog
	local size = log.size or 0

	if size == 0 then
		printToChat("|cFF20ff20XanChat|r: debug log empty")
		return
	end

	local count = math.min(tonumber(maxLines) or 60, size)
	local head = log.head or 0
	local limit = log.limit or 2000

	for i = count, 1, -1 do
		local idx = head - (i - 1)
		if idx <= 0 then idx = idx + limit end
		local line = log.data and log.data[idx]
		if line then printToChat(line) end
	end
end

function addon:UI_SCALE_CHANGED()
	if _G.XCHT_DB and _G.XCHT_DB.lockChatSettings and addon.isInAnyInstance and addon.isInAnyInstance() then return end
	lockAllChatFrames()
end

-- ============================================================================
-- SLASH COMMAND HANDLER
-- ============================================================================

local SLASH_COMMANDS = {
	debug = function() _G.XCHT_DB.debugWrapper = not _G.XCHT_DB.debugWrapper; addon.wrapperDebug = _G.XCHT_DB.debugWrapper; printToChat("|cFF20ff20XanChat|r: wrapper debug " .. (_G.XCHT_DB.debugWrapper and "ON" or "OFF")) end,
	debugchat = function() _G.XCHT_DB.debugChat = not _G.XCHT_DB.debugChat; addon.debugChat = _G.XCHT_DB.debugChat; printToChat("|cFF20ff20XanChat|r: chat debug " .. (addon.debugChat and "ON" or "OFF")) end,
	debugnothrow = function() _G.XCHT_DB.debugNoThrow = not _G.XCHT_DB.debugNoThrow; printToChat("|cFF20ff20XanChat|r: debug no-throw " .. (_G.XCHT_DB.debugNoThrow and "ON" or "OFF")) end,
	debugdump = function() self:DumpDebugLog(300) end,
	debugclear = function() _G.XCHT_DB.debugLog = nil; printToChat("|cFF20ff20XanChat|r: debug log cleared") end,
}

local function handleSlashCommand(msg)
	local cmd = string.lower((msg and string.match(msg, "^%s*(%S+)")) or "")
	local handler = SLASH_COMMANDS[cmd]

	if handler then
		handler()
		return
	end

	-- Check if settings are locked
	if _G.XCHT_DB and _G.XCHT_DB.lockChatSettings and addon.isInAnyInstance and addon.isInAnyInstance() then
		printToChat("|cFF20ff20XanChat|r: " .. (addon.L.LockChatSettingsAlert or addon.L.ChatSettingsLocked or "Chat settings locked in instances"))
		return
	end

	-- Open settings
	if _G.Settings and _G.Settings.OpenToCategory then
		local categoryID = addon.settingsCategoryID or (addon.settingsCategory and addon.settingsCategory.GetID and addon.settingsCategory:GetID())
		if categoryID then
			_G.Settings.OpenToCategory(categoryID)
		else
			_G.Settings.OpenToCategory("xanChat")
		end
	elseif _G.InterfaceOptionsFrame_OpenToCategory then
		if not addon.IsRetail and _G.InterfaceOptionsFrame then
			_G.InterfaceOptionsFrame:Show()
		elseif (_G.InCombatLockdown and _G.InCombatLockdown()) or (_G.GameMenuFrame and _G.GameMenuFrame:IsShown()) or _G.InterfaceOptionsFrame then
			return
		end
		if addon.aboutPanel then
			_G.InterfaceOptionsFrame_OpenToCategory(addon.aboutPanel)
		end
	end
end

-- ============================================================================
-- UI ELEMENT HELPERS
-- ============================================================================

local function hideSocialButton()
	if addon.IsRetail and _G.XCHT_DB and _G.XCHT_DB.hideSocial and _G.QuickJoinToastButton then
		_G.QuickJoinToastButton:Hide()
		_G.QuickJoinToastButton:SetScript("OnShow", function() end)
	end
end

local function moveSocialButtonToBottom()
	if not addon.IsRetail or not _G.XCHT_DB or not _G.XCHT_DB.moveSocialButtonToBottom then return end
	if _G.ChatAlertFrame then
		_G.ChatAlertFrame:ClearAllPoints()
		_G.ChatAlertFrame:SetPoint("TOPLEFT", _G.ChatFrame1, "BOTTOMLEFT", -33, -60)
	end
end

local function hideChatMenuButton()
	if not _G.XCHT_DB or not _G.XCHT_DB.hideChatMenuButton then return end
	if _G.ChatFrameMenuButton then
		_G.ChatFrameMenuButton:Hide()
		_G.ChatFrameMenuButton:SetScript("OnShow", function() end)
	end
end

local function hideVoiceButtons()
	if not _G.XCHT_DB or not _G.XCHT_DB.hideVoice then return end

	if _G.ChatFrameToggleVoiceDeafenButton then
		_G.ChatFrameToggleVoiceDeafenButton:Hide()
	end
	if _G.ChatFrameToggleVoiceMuteButton then
		_G.ChatFrameToggleVoiceMuteButton:Hide()
	end
	if _G.ChatFrameChannelButton then
		_G.ChatFrameChannelButton:Hide()
	end
end

local function setupClassColors()
	if not _G.ToggleChatColorNamesByClassGroup then return end

	if _G.CHAT_CONFIG_CHAT_LEFT then
		for _, v in pairs(_G.CHAT_CONFIG_CHAT_LEFT) do
			_G.ToggleChatColorNamesByClassGroup(true, v.type)
		end
	end

	for i = 1, MAX_GLOBAL_CHANNELS do
		_G.ToggleChatColorNamesByClassGroup(true, "CHANNEL" .. i)
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
	addon.installTempWindowHook()
	self.setDisableChatEnterLeaveNotice()
	self:setOutWhisperColor()

	if self.EnableFilterList then
		self:EnableFilterList()
	end
	if self.EnableStickyChannelsList then
		self:EnableStickyChannelsList()
	end

	if addon.initPlayerInfo then
		addon.initPlayerInfo()
	end
	if addon.initUpdateCurrentPlayer then
		addon.initUpdateCurrentPlayer()
	end
	if addon.doRosterUpdate then
		addon.doRosterUpdate()
	end
	if addon.doFriendUpdate then
		addon.doFriendUpdate()
	end
	if addon.doGuildUpdate then
		addon.doGuildUpdate()
	end

	-- Turn off profanity filter
	local setCVar = _G.C_CVar and _G.C_CVar.SetCVar or _G.SetCVar
	if setCVar then
		setCVar("profanityFilter", "0")
	end

	setupClassColors()

	if _G.XCHT_DB and _G.XCHT_DB.disableChatFrameFade then
		self:setUserAlpha()
	end

	hideSocialButton()
	moveSocialButtonToBottom()
	hideChatMenuButton()
	hideVoiceButtons()

	-- Setup all chat frames
	if self.setupAllChatFrames then
		self.setupAllChatFrames()
	end

	-- Register UI_SCALE_CHANGED event
	self:RegisterEvent("UI_SCALE_CHANGED")

	-- Versioned settings update - lock frames when version changes
	local ver = (addon.GetAddOnMetadata and addon.GetAddOnMetadata(ADDON_NAME, "Version")) or "1.0"
	if _G.XCHT_DB and (_G.XCHT_DB.dbVer == nil or _G.XCHT_DB.dbVer ~= ver) then
		lockAllChatFrames()
		_G.XCHT_DB.dbVer = ver
	end

	-- Setup slash commands
	_G["SLASH_XANCHAT1"] = "/xanchat"
	_G["SLASH_XANCHAT2"] = "/xc"
	if _G.RegisterChatCommand then
		_G.RegisterChatCommand("xanchat", handleSlashCommand)
	elseif _G.SlashCmdList then
		_G.SlashCmdList["XANCHAT"] = handleSlashCommand
	end

	addon.dbg("OnLoad: COMPLETE xanChat initialization")
	if addon.configFrame then
		addon.configFrame:EnableConfig()
	end

	printToChat(string.format("|cFF99CC33%s|r [v|cFF20ff20%s|r] loaded:   /xanchat", ADDON_NAME, ver))
end

function addon:OnEnable()
	addon.dbg("OnEnable: installing message hooks")
	rebuildHookedFrames()
	addon.registerUrlPatterns()
	addon.installUrlCopyHook()
	addon.installTempWindowHook()
	self:EnableAddon()
	self:RegisterEvent("ENCOUNTER_START", "OnEncounterStart")
	self:RegisterEvent("ENCOUNTER_END", "OnEncounterEnd")

	if addon.InitInstanceWarning then
		addon.InitInstanceWarning()
		addon.dbg("OnEnable: Instance Warning module initialized")
	end

	if _G.C_ChatInfo and _G.C_ChatInfo.InChatMessagingLockdown then
		if not self._chatLockdownTicker then
			self._chatLockdownTicker = self:NewTicker(0.5, function()
				addon:CheckChatLockdownState()
			end)
		end
		self:CheckChatLockdownState()
	end

	if _G.IsEncounterInProgress and _G.IsEncounterInProgress() then
		self:OnEncounterStart()
	end

	if self.hookupAutoSave then
		self.hookupAutoSave()
	end
end

function addon:OnDisable()
	addon.dbg("OnDisable: removing hooks and cleaning up")

	if addon.unregisterAllCallbacks then
		addon.unregisterAllCallbacks()
	end

	self:UnregisterEvent("ENCOUNTER_START", "OnEncounterStart")
	self:UnregisterEvent("ENCOUNTER_END", "OnEncounterEnd")

	if addon.ShutdownInstanceWarning then
		addon.ShutdownInstanceWarning()
		addon.dbg("OnDisable: Instance Warning module shut down")
	end

	if self._chatLockdownTicker then
		self:CancelTicker(self._chatLockdownTicker)
		self._chatLockdownTicker = nil
	end

	if addon.uninstallUrlCopyHook then
		addon.uninstallUrlCopyHook()
	end
	if addon.uninstallTempWindowHook then
		addon.uninstallTempWindowHook()
	end

	self:DisableAddon()
	if addon.unregisterUrlPatterns then
		addon.unregisterUrlPatterns()
	end
end

function addon.installTempWindowHook()
	if addon._tempWindowHookInstalled or not _G.FCF_OpenTemporaryWindow then return end

	addon._origFCF_OpenTemporaryWindow = addon._origFCF_OpenTemporaryWindow or _G.FCF_OpenTemporaryWindow
	_G.FCF_OpenTemporaryWindow = function(...)
		local frame = addon._origFCF_OpenTemporaryWindow(...)
		if frame and frame.GetID and addon.setupChatFrame then
			addon.setupChatFrame(frame:GetID())
		end
		return frame
	end
	addon._tempWindowHookInstalled = true
end

function addon.uninstallTempWindowHook()
	if not addon._tempWindowHookInstalled then return end
	if addon._origFCF_OpenTemporaryWindow then
		_G.FCF_OpenTemporaryWindow = addon._origFCF_OpenTemporaryWindow
	end
	addon._tempWindowHookInstalled = nil
end

function addon:EnableAddon()
	if self._addonEnabled then
		addon.dbg("EnableAddon: already enabled")
		return
	end

	addon.dbg("EnableAddon: START installing message hooks")

	self._hooks = self._hooks or {}
	self._rawHooks = self._rawHooks or {}

	addon.ensureCaptureProxyFrame()
	addon.installUrlCopyHook()
	addon.installTempWindowHook()

	if _G["ChatFrame_MessageEventHandler"] then
		local uid = self:RawHook(_G, "ChatFrame_MessageEventHandler", function(frame, event, ...)
			return addon:ChatFrame_MessageEventHandler(frame, event, ...)
		end, true)
		self._rawHooks["ChatFrame_MessageEventHandler"] = uid
		self._chatEventHooked = "global"
		addon.dbg("EnableAddon: global ChatFrame_MessageEventHandler RawHooked")
	elseif _G.ChatFrameMixin and _G.ChatFrameMixin.MessageEventHandler then
		local hookCount = 0
		for frameName, frame in pairs(addon.HookedFrames) do
			if frame and frame.MessageEventHandler then
				self._hooks[frameName] = frame.MessageEventHandler
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

	self._addonEnabled = true
	addon.dbg("EnableAddon: COMPLETE hooks installed")
end

function addon:DisableAddon()
	if not self._addonEnabled then
		addon.dbg("DisableAddon: already disabled")
		return
	end

	addon.dbg("DisableAddon: START removing message hooks")

	if addon.uninstallUrlCopyHook then
		addon.uninstallUrlCopyHook()
	end
	if addon.uninstallTempWindowHook then
		addon.uninstallTempWindowHook()
	end

	if self._chatEventHooked == "global" and self._rawHooks and self._rawHooks["ChatFrame_MessageEventHandler"] then
		self:Unhook(_G, "ChatFrame_MessageEventHandler")
		self._rawHooks["ChatFrame_MessageEventHandler"] = nil
		addon.dbg("DisableAddon: unhooked global ChatFrame_MessageEventHandler")
	elseif self._chatEventHooked == "frame" and self._hooks then
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

	if self._rawHooks and self._rawHooks["DummyFrame"] then
		self:Unhook(addon.captureProxyFrame, "AddMessage")
		self._rawHooks["DummyFrame"] = nil
	end

	self._chatEventHooked = nil
	self._addonEnabled = false
	addon.dbg("DisableAddon: COMPLETE hooks removed")
end
