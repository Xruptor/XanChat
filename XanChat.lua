--[[
	XanChat chat pipeline
	- proxy capture path for normal messages
	- direct safe path for secret message payloads
	- section-based formatting + callback stages
	Refactored for:
	- Extracted frame locking into helper function
	- Split ParseChatEvent into smaller helper functions
	- Removed duplicate hook installation calls
	- Added nil guards for global functions
	- Extracted player name fallback logic
	- Added constants for magic numbers
	- Consolidated slash commands into lookup table
	- Removed commented out dead code
	- Improved early returns and flattened conditionals
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

local CHAT_MSG_PREFIX = "CHAT_MSG"
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

local EVENTS = {
	FRAME_MESSAGE = "XanChat_FrameMessage",
	PRE_ADDMESSAGE = "XanChat_PreAddMessage",
	POST_ADDMESSAGE = "XanChat_PostAddMessage",
	POST_ADDMESSAGE_BLOCKED = "XanChat_PostAddMessageBlocked",
}
addon.EVENTS = EVENTS

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Lock all chat frames - extracted to eliminate duplication
local function lockAllChatFrames()
	if not _G.NUM_CHAT_WINDOWS then return end

	for i = 1, _G.NUM_CHAT_WINDOWS do
		local n = ("ChatFrame%d"):format(i)
		local f = _G[n]
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

-- Check if event is a CHAT_MSG event (starts with "CHAT_MSG")
local function isChatMessageEvent(event)
	if type(event) ~= "string" then return false end
	return string.sub(event, 1, 8) == CHAT_MSG_PREFIX
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
-- PLAYER NAME EXTRACTION HELPERS
-- ============================================================================

-- Try to get player info from GUID
local function tryGetPlayerFromGUID(guid)
	if not guid or type(guid) ~= "string" then return nil end
	if not _G.GetPlayerInfoByGUID then return nil end

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

	-- Try GetChatLineSenderName first
	if _G.C_ChatInfo.GetChatLineSenderName then
		local nameChk = _G.C_ChatInfo.GetChatLineSenderName(lineID)
		if nameChk then
			result.player_name_with_realm = nameChk
		end
	end

	-- Try GetChatLineSenderGUID + GetPlayerInfoByGUID as fallback
	-- Skip if we already have the GUID from a previous lookup
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

-- Extract player name from sender arg (arg2) with fallbacks
local function extractPlayerInfo(arg2, arg12, arg11, isArg2Secret)
	if not isArg2Secret then
		local senderName = arg2 or ""
		local coloredName = senderName

		-- Apply Ambiguate for name display
		if _G.Ambiguate then
			coloredName = _G.Ambiguate(coloredName, "none")
		end

		return {
			sender_name = senderName,
			player_name = parsePlayerName(coloredName),
		}
	end

	-- arg2 is secret, try fallbacks
	-- This matches Baseline's approach for secret boss encounter messages
	-- GetPlayerInfoByGUID returns: localizedClass, englishClass, localizedRace, englishRace, sex, name, realmName
	local playerInfo = tryGetPlayerFromGUID(arg12)
	if playerInfo then
		-- We have GUID info, but still try to get player_name_with_realm from lineID
		local lineInfo = tryGetPlayerFromLineID(arg11, true)
		if lineInfo and lineInfo.player_name_with_realm then
			playerInfo.player_name_with_realm = lineInfo.player_name_with_realm
		end
	else
		playerInfo = tryGetPlayerFromLineID(arg11)
	end

	return playerInfo or {}
end

-- ============================================================================
-- MAIN MESSAGE HANDLER
-- ============================================================================

function addon:DebugChatHandlerState(context)
	if not addon.dbg then return end
	local handler = _G.ChatFrame_MessageEventHandler
	local isSecureVar = _G.issecurevariable and _G.issecurevariable("ChatFrame_MessageEventHandler")
	local orig = addon.hooks and addon.hooks._G and addon.hooks._G.ChatFrame_MessageEventHandler

	local stateParts = {
		tostring(context),
		tostring(addon._chatEventHooked),
		tostring(isSecureVar),
		tostring(handler),
		tostring(orig),
		tostring(handler == orig),
		tostring(handler == addon.ChatFrame_MessageEventHandler),
	}
	local stateKey = table.concat(stateParts, "|")

	if addon._chatHandlerStateLast == stateKey then
		return
	end
	addon._chatHandlerStateLast = stateKey

	local debugParts = {
		"ChatHandlerState: context=" .. tostring(context),
		" hookMode=" .. tostring(addon._chatEventHooked),
		" isSecureVar=" .. tostring(isSecureVar),
		" handler=" .. (addon.dbgSafeValue and addon.dbgSafeValue(handler) or tostring(handler)),
		" orig=" .. (addon.dbgSafeValue and addon.dbgSafeValue(orig) or tostring(orig)),
		" handlerIsOrig=" .. tostring(handler == orig),
		" handlerIsSelf=" .. tostring(handler == addon.ChatFrame_MessageEventHandler),
	}
	addon.dbg(table.concat(debugParts))
end

-- Extract flag information (GM, DEV, GUIDE, NEWCOMER)
local function extractFlagInfo(s, arg6, arg7)
	if not s or type(arg6) ~= "string" or arg6 == "" then return end

	if arg6 == "GM" or arg6 == "DEV" then
		s.player_flag = "|TInterface\\ChatFrame\\UI-ChatIcon-Blizz:12:20:0:0:32:16:4:28:0:16|t "
		return
	end

	if arg6 == "GUIDE" or arg6 == "NEWCOMER" then
		if not _G.ChatFrame_GetMentorChannelStatus then return end
		if not _G.Enum or not _G.Enum.PlayerMentorshipStatus or not _G.C_ChatInfo then return end

		local mentorStatus
		if arg6 == "GUIDE" then
			mentorStatus = _G.ChatFrame_GetMentorChannelStatus(
				_G.Enum.PlayerMentorshipStatus.Mentor,
				_G.C_ChatInfo.GetChannelRulesetForChannelID(arg7)
			)
		else
			mentorStatus = _G.ChatFrame_GetMentorChannelStatus(
				_G.Enum.PlayerMentorshipStatus.Newcomer,
				_G.C_ChatInfo.GetChannelRulesetForChannelID(arg7)
			)
		end

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
	if not s then return end

	if chatType == "CHANNEL" then return end

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
	if not s then return end

	if type(arg3) ~= "string" or arg3 == "" then return end

	if arg3 == "Universal" then
		s.LANGUAGE_NOSHOW = arg3
	else
		s.language = arg3
	end
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

-- Parse WoW event args into chat sections
function addon:ParseChatEvent(_, event, ...)
	addon.dbg("ParseChatEvent: START event=" .. tostring(event))

	local arg1, arg2, arg3, _, _, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, _, arg15 = ...
	local isSecret = addon.isSecretValue and addon.isSecretValue(arg1)

	addon.dbg("ParseChatEvent: isSecret=" .. tostring(isSecret) .. " arg1=" .. (addon.dbgValue and addon.dbgValue(arg1) or tostring(arg1)))

	if not isChatMessageEvent(event) then
		addon.dbg("ParseChatEvent: not a CHAT_MSG event, returning nil")
		return nil, nil
	end

	local arg16 = select(16, ...)
	if arg16 then
		addon.dbg("ParseChatEvent: hidden sender in cinematic letterbox, returning true")
		return true
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

	-- Set ACCESSID and TYPEID for the report system using Blizzard's ChatHistory API
	-- These are used by AddMessage for proper message reporting functionality
	if _G.ChatHistory_GetAccessId then
		s.ACCESSID = _G.ChatHistory_GetAccessId(s.CHATGROUP, s.CHATTARGET) or arg11 or 0
	else
		s.ACCESSID = arg11 or 0
	end

	if _G.ChatHistory_GetTypeInfo then
		s.TYPEID = _G.ChatHistory_GetTypeInfo(s.CHATTYPE, s.CHATTARGET, arg12 or arg13) or 0
	else
		s.TYPEID = 0
	end

	-- Message text handling
	local isUnsafeMessage = isSecret or not (addon.isSafeString and addon.isSafeString(arg1))
	if isUnsafeMessage then
		s.message_text = arg1 or ""
	else
		s.message_text = (arg1 or ""):gsub("^%s*(.-)%s*$", "%1")
	end

	-- Player information extraction
	local isArg2Secret = addon.isSecretValue and addon.isSecretValue(arg2)

	if addon and addon.dbg and isArg2Secret then
		addon.dbg("ParseChatEvent: arg2 is secret, will try GUID/lineID fallbacks")
	end

	local playerInfo = extractPlayerInfo(arg2, arg12, arg11, isArg2Secret)

	if playerInfo.player_name then
		s.player_name = playerInfo.player_name
	end
	if playerInfo.player_class then
		s.player_class = playerInfo.player_class
	end
	if playerInfo.server_name then
		s.server_name = playerInfo.server_name
	end
	if playerInfo.player_guid then
		s.player_guid = playerInfo.player_guid
	end
	if playerInfo.player_name_with_realm then
		s.player_name_with_realm = playerInfo.player_name_with_realm
	end

	if not isArg2Secret then
		-- Extract name and server from colored name
		-- arg2 is known to be non-secret here (isArg2Secret is false)
		local nameToParse = arg2 or s.player_name_with_realm
		local plr, svr = parsePlayerName(nameToParse)
		if plr then
			s.player_name = plr
		end
		if svr and string.len(svr) > 0 then
			s.server_separator = "-"
			s.server_name = svr
		end

		-- Apply Ambiguate for guild vs non-guild
		if _G.Ambiguate and nameToParse then
			if chatType == "GUILD" then
				s.player_name_display = _G.Ambiguate(nameToParse, "guild")
			else
				s.player_name_display = _G.Ambiguate(nameToParse, "none")
			end
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

function addon:ChatFrame_MessageEventHandler(this, event, ...)
	local frameName = this and this.GetName and this:GetName() or "<unknown>"
	addon.dbg("ChatFrame_MessageEventHandler: START event=" .. tostring(event) .. " frame=" .. tostring(frameName))

	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15 = ...
	local isSecretPayload = (addon.isSecretValue and addon.isSecretValue(arg1)) or (addon.isSecretValue and addon.isSecretValue(arg2))
	local processMode = addon.EventIsProcessed and addon.EventIsProcessed(event)
	local handlerResult

	addon.dbg("ChatFrame_MessageEventHandler: isSecretPayload=" .. tostring(isSecretPayload) .. " processMode=" .. tostring(processMode))

	if not this then
		addon.dbg("ChatFrame_MessageEventHandler: missing frame, passthrough")
		return addon.callOriginalMessageHandler and addon.callOriginalMessageHandler(self, this, event, ...) or true
	end
	if not addon.HookedFrames or not addon.HookedFrames[frameName] then
		addon.dbg("ChatFrame_MessageEventHandler: frame not managed, passthrough")
		return addon.callOriginalMessageHandler and addon.callOriginalMessageHandler(self, this, event, ...) or true
	end

	addon.dbg("ChatFrame_MessageEventHandler: frame is managed by xanChat")

	-- BN_INLINE_TOAST_ALERT events are Battle.net toast notifications, not chat messages
	-- They need to be handled by Blizzard to show the friend's name properly
	-- Pass them through without any of our custom processing
	if event == "CHAT_MSG_BN_INLINE_TOAST_ALERT" then
		addon.dbg("ChatFrame_MessageEventHandler: BN_INLINE_TOAST_ALERT, passing to Blizzard handler")
		return addon.callOriginalMessageHandler and addon.callOriginalMessageHandler(self, this, event, ...) or true
	end

	-- Secret payload path - use direct safe rendering
	if isSecretPayload then
		addon.dbg("ChatFrame_MessageEventHandler: secret payload detected, using local safe rendering")
		self:DebugChatHandlerState("secret-payload")

		-- Reset capture state to avoid using stale colors from previous non-secret messages
		addon.resetCaptureState()

		-- During lockdown, we can't call the original handler to test if the frame should display
		-- Instead, use a per-message deduplication tracker - only the first frame processes
		-- This works because Blizzard routes the message to the correct frame first
		local messageKey = tostring(event) .. "_" .. tostring(arg11 or 0)
		if addon._lockdownProcessedMessages and addon._lockdownProcessedMessages[messageKey] then
			addon.dbg("ChatFrame_MessageEventHandler: message already processed during lockdown, skipping duplicate frame")
			return true
		end

		local parsedMessage, info = addon:ParseChatEvent(this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
		local m = type(parsedMessage) == "table" and parsedMessage or addon.sectionOriginal or {}

		-- Extract channel info from args if not already set (using unified function)
		-- Need to do this BEFORE getting colors so we have channel_number for proper color lookup
		if not m.channel_number or m.channel_number == "" then
			local argsSources = {arg7, arg9, arg10}
			addon.extractChannelInfoFromSources(m, argsSources)
		end

		-- Try to extract from OUTPUT if deferred extraction is set
		-- We can use string.match on secret values (just not gsub())
		addon.extractChannelFromOutputIfDeferred(m)

		-- IMPORTANT: During lockdown, we must use ChatTypeInfo["CHANNEL" + number] NOT ChatTypeInfo["CHANNEL"]
		-- ChatTypeInfo["CHANNEL"] = generic default color (WRONG)
		-- ChatTypeInfo["CHANNEL1"] = General channel color (CORRECT)
		-- ChatTypeInfo["CHANNEL3"] = Lockdown/Trade channel color (CORRECT)
		-- Each channel has its own color configured by the player - use the specific channel type key!
		local infoRow = m.INFO or info or {}
		local outR, outG, outB, outID = infoRow.r or 1, infoRow.g or 1, infoRow.b or 1, infoRow.id or 0

		-- For channel messages, try to get the channel-specific color by channel number
		if m.channel_number and m.channel_number ~= "" and m.channel_number ~= "0" then
			local channelTypeKey = "CHANNEL" .. m.channel_number
			if _G.ChatTypeInfo and _G.ChatTypeInfo[channelTypeKey] then
				outR = _G.ChatTypeInfo[channelTypeKey].r or outR
				outG = _G.ChatTypeInfo[channelTypeKey].g or outG
				outB = _G.ChatTypeInfo[channelTypeKey].b or outB
				outID = _G.ChatTypeInfo[channelTypeKey].id or outID
				addon.dbg("ChatFrame_MessageEventHandler: using channel-specific color for "..channelTypeKey.." - R="..tostring(outR).." G="..tostring(outG).." B="..tostring(outB))
			end
		end

		addon.dbg("ChatFrame_MessageEventHandler: initial colors from infoRow - R="..tostring(outR).." G="..tostring(outG).." B="..tostring(outB).." ID="..tostring(outID).." event="..tostring(event))


		-- Build channel info for display during lockdown
		-- Skip for events in SKIP_STYLING_EVENTS (system messages like AFK/DND) and for channel "0"
		local channelInfo = ""
		local skipChannelInfo = addon.SKIP_STYLING_EVENTS and m.chat_type and addon.SKIP_STYLING_EVENTS[m.chat_type] or false
		if not skipChannelInfo and m.channel_number and m.channel_number ~= "" and m.channel_number ~= "0" then
			local channelNum = m.channel_number
			local channelName = m.channel_name or ""

			-- Try to use centralized channel shortening function first
			-- This handles both channel extraction and shortening in one place
			local shorteningSucceeded = false
			if m.OUTPUT and not addon.isSecretValue(m.OUTPUT) then
				local success, err = pcall(addon.applyShortChannelNamesToSections, m)
				if success then
					-- applyShortChannelNamesToSections succeeded, use the updated values
					-- But only if it actually produced a channel name
					if m.channel_name and m.channel_name ~= "" then
						channelName = m.channel_name
						shorteningSucceeded = true
						addon.dbg("ChatFrame_MessageEventHandler: applyShortChannelNamesToSections succeeded during lockdown")
					else
						addon.dbg("ChatFrame_MessageEventHandler: applyShortChannelNamesToSections succeeded but returned empty channel_name, using fallback")
					end
				else
					addon.dbg("ChatFrame_MessageEventHandler: applyShortChannelNamesToSections failed during lockdown: "..tostring(err))
				end
			end

			-- Fallback: use lockdown-safe channel extraction and shortening if centralized function failed
			if not shorteningSucceeded then
				local useShortNames = _G.XCHT_DB and _G.XCHT_DB.shortNames
				if useShortNames then
					channelName = addon.getShortChannelPatternOnLockdown and addon.getShortChannelPatternOnLockdown(m, channelNum) or channelName
				end
			end

			-- Build channelInfo with the (potentially shortened) channel name
			local useShortNames = _G.XCHT_DB and _G.XCHT_DB.shortNames
			if channelName and channelName ~= "" then
				-- Use short format [1] GN] or long format [1. General] based on shortNames setting
				-- Note: Short format has the number and short name in one clickable link
				if useShortNames then
					channelInfo = "|Hchannel:"..channelNum.."|h["..channelNum.."] ["..channelName.."]|h "
				else
					channelInfo = "|Hchannel:"..channelNum.."|h["..channelNum..". "..channelName.."]|h "
				end
			else
				channelInfo = "|Hchannel:"..channelNum.."|h["..channelNum.."]|h "
			end

			addon.dbg("ChatFrame_MessageEventHandler: lockdown channelInfo - "..tostring(string.sub(channelInfo or "", 1, 50)))
		end

		-- Generate clickable player link using StylePlayerSection for secret payloads
		addon.StylePlayerSection(m)

		-- For events in SKIP_STYLING_EVENTS (emotes, system messages), use Blizzard's original formatting
		-- Otherwise build custom format with channel info and player link
		local skipStyling = addon.SKIP_STYLING_EVENTS and m.chat_type and addon.SKIP_STYLING_EVENTS[m.chat_type]
		local textToDisplay
		if skipStyling then
			textToDisplay = arg1 or ""
		else
			textToDisplay = channelInfo .. (m.player_link or "") .. (m.player_link and ": " or "") .. (arg1 or "")
		end
		local isSecretText = addon.isSecretValue and addon.isSecretValue(textToDisplay)

		addon.dbg("ChatFrame_MessageEventHandler: secret output len=" .. tostring(addon.dbgSafeLength and addon.dbgSafeLength(textToDisplay) or 0) .. " isSecretText=" .. tostring(isSecretText))
		if not isSecretText then
			if not (addon.isSafeString and addon.isSafeString(textToDisplay)) or textToDisplay == "" then
				addon.dbg("ChatFrame_MessageEventHandler: secret output empty or unsafe, skipping display")
				return true
			end
		end

		-- During lockdown, skip type_prefix to avoid double formatting
		-- The player_link already contains the necessary formatting
		-- textToDisplay = ((m.type_prefix and (m.type_prefix .. " ")) or "") .. (textToDisplay or "")

		addon.dbg("ChatFrame_MessageEventHandler: adding secret message to frame (direct output)")
		this:AddMessage(textToDisplay, outR, outG, outB, outID, false, m.ACCESSID, m.TYPEID)

		-- Mark this message as processed so duplicate frames don't process it
		messageKey = tostring(event) .. "_" .. tostring(arg11 or 0)
		addon._lockdownProcessedMessages = addon._lockdownProcessedMessages or {}
		addon._lockdownProcessedMessages[messageKey] = true
		return true
	end

	-- Clean carriage returns from message
	arg1 = cleanCarriageReturns(arg1)

	-- Run Blizzard frame message filters
	local shouldDiscard
	if addon.runFrameMessageFilters then
		shouldDiscard, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14 =
			addon.runFrameMessageFilters(this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
	end

	if shouldDiscard then
		addon.dbg("ChatFrame_MessageEventHandler: message discarded by Blizzard filters")
		return true
	end

	addon.dbg("ChatFrame_MessageEventHandler: message passed Blizzard filters, calling ParseChatEvent")

	local parsedMessage, info = addon:ParseChatEvent(this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)

	if type(parsedMessage) == "boolean" and parsedMessage == true then
		addon.dbg("ChatFrame_MessageEventHandler: ParseChatEvent returned boolean, passing through")
		return true
	end
	if not info then
		addon.dbg("ChatFrame_MessageEventHandler: ParseChatEvent failed (no info), passthrough")
		return addon.callOriginalMessageHandler and addon.callOriginalMessageHandler(self, this, event, ...) or true
	end
	if type(parsedMessage) ~= "table" then
		addon.dbg("ChatFrame_MessageEventHandler: ParseChatEvent did not return table, passthrough")
		return addon.callOriginalMessageHandler and addon.callOriginalMessageHandler(self, this, event, ...) or true
	end

	addon.dbg("ChatFrame_MessageEventHandler: ParseChatEvent successful, preparing message processing")

	local m = parsedMessage
	local resolvedEvent = m.EVENT or event

	addon.resetCaptureState()
	m.OUTPUT = nil
	m.DONOTPROCESS = nil

	if addon.fireCallback then
		addon.dbg("ChatFrame_MessageEventHandler: firing FRAME_MESSAGE callback")
		addon.fireCallback(addon.EVENTS.FRAME_MESSAGE, m, this, resolvedEvent)
	end

	addon.dbg("ChatFrame_MessageEventHandler: NON-SECRET path, using proxy capture")
	local proxyFrame = (addon.CreateProxy and addon:CreateProxy(this)) or nil
	if proxyFrame then
		m.CAPTUREOUTPUT = proxyFrame
		addon.captureState.proxy = proxyFrame
		handlerResult = addon.callOriginalMessageHandler(self, proxyFrame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
		addon:RestoreProxy()
		m.OUTPUT = addon.captureState.text
		addon.dbg("ChatFrame_MessageEventHandler: proxy capture result length=" .. tostring(addon.dbgSafeLength and addon.dbgSafeLength(m.OUTPUT) or 0))

		-- If channel number extraction was deferred, extract it now from OUTPUT
		addon.extractChannelFromOutputIfDeferred(m)
	end

	m.CAPTUREOUTPUT = false
	addon.captureState.proxy = nil

	if type(m.OUTPUT) ~= "string" then
		addon.dbg("ChatFrame_MessageEventHandler: capture miss, passthrough")
		addon.resetCaptureState()
		m.CAPTUREOUTPUT = nil
		return addon.callOriginalMessageHandler(self, this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
	end

	if type(m.message_text) ~= "string" then
		m.message_text = (addon.dbgSafeValue and addon.dbgSafeValue(m.message_text)) or (m.message_text and tostring(m.message_text)) or ""
	end

	if type(m.OUTPUT) == "string" and not m.DONOTPROCESS then
		addon.dbg("ChatFrame_MessageEventHandler: building display text")
		local infoRow = m.INFO or info or {}
		local outR, outG, outB, outID = infoRow.r or 1, infoRow.g or 1, infoRow.b or 1, infoRow.id or 0
		local textToDisplay = m.OUTPUT
		local applyPatterns = addon.shouldRunPatternPass and addon.shouldRunPatternPass(isSecretPayload, processMode)

		addon.dbg("ChatFrame_MessageEventHandler: initial colors from infoRow - R="..tostring(outR).." G="..tostring(outG).." B="..tostring(outB).." ID="..tostring(outID).." event="..tostring(event).." resolvedEvent="..tostring(resolvedEvent))
		addon.dbg("ChatFrame_MessageEventHandler: applyPatterns=" .. tostring(applyPatterns))

		if applyPatterns then
			addon.dbg("ChatFrame_MessageEventHandler: running MatchPatterns")
			m.message_text = addon.MatchPatterns(m, "FRAME")
			if type(m.message_text) ~= "string" then
				m.message_text = (addon.dbgSafeValue and addon.dbgSafeValue(m.message_text)) or (m.message_text and tostring(m.message_text)) or ""
			end
		end

		if addon.fireCallback then
			addon.dbg("ChatFrame_MessageEventHandler: firing PRE_ADDMESSAGE callback")
			addon.fireCallback(addon.EVENTS.PRE_ADDMESSAGE, m, this, resolvedEvent, addon.FormatChatMessage(m), outR, outG, outB, outID)
		end

		if applyPatterns then
			addon.dbg("ChatFrame_MessageEventHandler: running ReplaceMatches")
			m.message_text = addon.ReplaceMatches(m, "FRAME")
		end

		addon.StylePlayerSection(m)
		if addon.applyShortChannelNamesToSections then
			addon.applyShortChannelNamesToSections(m)
		end

		local useStyledOutput = false
		if _G.XCHT_DB then
			useStyledOutput = _G.XCHT_DB.enablePlayerChatStyle or _G.XCHT_DB.shortNames or applyPatterns
			addon.dbg("ChatFrame_MessageEventHandler: useStyledOutput=" .. tostring(useStyledOutput))
		end

		-- For channel events with non-standard argument structures, use Blizzard's formatted output directly
		-- These events have arg1 as notice type (e.g., "YOU_CHANGED"), not message text
		--
		-- ISSUE: For these events, arg1 is a notice type constant ("YOU_CHANGED", "YOU_JOINED", etc.)
		--        not the actual message text. FormatChatMessage() uses message_text which would
		--        incorrectly show "YOU_CHANGED" instead of the properly formatted message.
		--
		-- FIX: Use m.OUTPUT (Blizzard's formatted output) directly instead of FormatChatMessage()
		--      This ensures proper message display while still allowing short channel names and other features.
		--
		-- EVENTS AFFECTED:
		--   - CHAT_MSG_CHANNEL_NOTICE (arg1 = notice type like "YOU_CHANGED")
		--   - CHAT_MSG_CHANNEL_NOTICE_USER (arg1 = notice type for user actions)
		--   - CHAT_MSG_CHANNEL_JOIN (arg1 = notice type for joins)
		--   - CHAT_MSG_CHANNEL_LEAVE (arg1 = notice type for leaves)
		--
		-- NOTE: CHAT_MSG_BN_INLINE_TOAST_ALERT is NOT included here - these are Battle.net toast
		--       notifications, not channel messages. They should use normal message processing
		--       so Blizzard can format them properly with the friend's name.
		--
		-- NOTE: CHAT_MSG_TEXT_EMOTE and CHAT_MSG_EMOTE are included because arg1 contains
		--       "You wave." etc. but Blizzard's OUTPUT has already replaced "You" with the
		--       player's name ("Xruptor waves."). We must use Blizzard's OUTPUT directly.
		local isChannelNoticeEvent = resolvedEvent == "CHAT_MSG_CHANNEL_NOTICE" or
			resolvedEvent == "CHAT_MSG_CHANNEL_NOTICE_USER" or
			resolvedEvent == "CHAT_MSG_CHANNEL_JOIN" or
			resolvedEvent == "CHAT_MSG_CHANNEL_LEAVE" or
			resolvedEvent == "CHAT_MSG_TEXT_EMOTE" or
			resolvedEvent == "CHAT_MSG_EMOTE"

		if isChannelNoticeEvent then
			addon.dbg("ChatFrame_MessageEventHandler: using Blizzard output for channel/notice/emote event")
			textToDisplay = (m.PRE or "") .. (m.OUTPUT or "") .. (m.POST or "")
		elseif processMode == (addon.EventProcessingType and addon.EventProcessingType.Full) then
			addon.dbg("ChatFrame_MessageEventHandler: using Full processing mode")
			textToDisplay = addon.FormatChatMessage(m) or ""
		elseif processMode == (addon.EventProcessingType and addon.EventProcessingType.PatternsOnly) then
			addon.dbg("ChatFrame_MessageEventHandler: using PatternsOnly processing mode")
			textToDisplay = (m.PRE or "") .. (m.message_text or "") .. (m.POST or "")
		else
			addon.dbg("ChatFrame_MessageEventHandler: using output-only processing mode")
			textToDisplay = (m.PRE or "") .. (m.OUTPUT or "") .. (m.POST or "")
		end

		if addon.shouldSuppressJoinLeaveMessage and addon.shouldSuppressJoinLeaveMessage(resolvedEvent, textToDisplay) then
			addon.dbg("ChatFrame_MessageEventHandler: suppressing join/leave message")
			m.DONOTPROCESS = true
		end

		m.OUTPUT = textToDisplay
		addon.dbg("ChatFrame_MessageEventHandler: final output length=" .. tostring(addon.dbgSafeLength and addon.dbgSafeLength(textToDisplay) or 0))

		if m.DONOTPROCESS then
			addon.dbg("ChatFrame_MessageEventHandler: message blocked, firing POST_ADDMESSAGE_BLOCKED callback")
			if addon.fireCallback then
				addon.fireCallback(addon.EVENTS.POST_ADDMESSAGE_BLOCKED, m, this, resolvedEvent, textToDisplay, outR, outG, outB, outID)
			end
		elseif (addon.dbgSafeLength and addon.dbgSafeLength(textToDisplay) or 0) > 0 then
			addon.dbg("ChatFrame_MessageEventHandler: adding non-secret message to frame")
			local capturedR = addon.captureState.color.r or outR
			local capturedG = addon.captureState.color.g or outG
			local capturedB = addon.captureState.color.b or outB
			local capturedID = addon.captureState.color.id or outID
			local isCensored = arg11 and _G.C_ChatInfo.IsChatLineCensored(arg11)
			local visibleText = isCensored and (arg1 or "") or textToDisplay

			addon.dbg("ChatFrame_MessageEventHandler: captured colors - R="..tostring(capturedR).." G="..tostring(capturedG).." B="..tostring(capturedB).." ID="..tostring(capturedID).." isCensored="..tostring(isCensored))

			if isCensored then
				this:AddMessage(visibleText, capturedR, capturedG, capturedB, capturedID, false, m.ACCESSID, m.TYPEID, event, { ... }, function(text)
					return text
				end)
			else
				this:AddMessage(visibleText, capturedR, capturedG, capturedB, capturedID, false, m.ACCESSID, m.TYPEID)
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
	debugWrapper = false,
	debugChat = true,
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
	if not currentRealm then currentRealm = "Unknown" end
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
					if _G.XCHT_DB.disableChatFrameFade then
						tex:SetAlpha(alpha)
					else
						tex:SetAlpha(0)
					end
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
	local limit = log.limit or 2000

	if size == 0 then
		printToChat("|cFF20ff20XanChat|r: debug log empty")
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
			printToChat(line)
		end
	end
end

function addon:UI_SCALE_CHANGED()
	if _G.XCHT_DB and _G.XCHT_DB.lockChatSettings and addon.isInAnyInstance and addon.isInAnyInstance() then return end
	lockAllChatFrames()
end

-- ============================================================================
-- SLASH COMMAND HANDLER
-- ============================================================================

local function handleDebugToggle(_)
	_G.XCHT_DB.debugWrapper = not _G.XCHT_DB.debugWrapper
	addon.wrapperDebug = _G.XCHT_DB.debugWrapper
	printToChat("|cFF20ff20XanChat|r: wrapper debug " .. (_G.XCHT_DB.debugWrapper and "ON" or "OFF"))
	if addon.wrapperDebug and addon.wrapperLoaded then
		printToChat("|cFF20ff20XanChat|r: wrapper loaded = " .. tostring(addon.wrapperLoaded))
	end
end

local function handleDebugChatToggle(_)
	_G.XCHT_DB.debugChat = not _G.XCHT_DB.debugChat
	addon.debugChat = _G.XCHT_DB.debugChat
	printToChat("|cFF20ff20XanChat|r: chat debug " .. (addon.debugChat and "ON" or "OFF"))
end

local function handleDebugNoThrowToggle(_)
	_G.XCHT_DB.debugNoThrow = not _G.XCHT_DB.debugNoThrow
	printToChat("|cFF20ff20XanChat|r: debug no-throw " .. (_G.XCHT_DB.debugNoThrow and "ON" or "OFF"))
end

local function handleDebugDump(_)
	self:DumpDebugLog(300)
end

local function handleDebugClear(_)
	if _G.XCHT_DB and _G.XCHT_DB.debugLog then
		_G.XCHT_DB.debugLog = nil
	end
	printToChat("|cFF20ff20XanChat|r: debug log cleared")
end

-- Slash command lookup table for O(1) dispatch
local SLASH_COMMANDS = {
	debug = handleDebugToggle,
	debugchat = handleDebugChatToggle,
	debugdump = handleDebugDump,
	debugclear = handleDebugClear,
	debugnothrow = handleDebugNoThrowToggle,
}

local function handleSlashCommand(msg)
	local cmd = string.lower((msg and string.match(msg, "^%s*(%S+)")) or "")
	local handler = SLASH_COMMANDS[cmd]

	if handler then
		handler(cmd)
		return
	end

	-- Check if settings are locked
	if _G.XCHT_DB and _G.XCHT_DB.lockChatSettings and addon.isInAnyInstance and addon.isInAnyInstance() then
		printToChat("|cFF20ff20XanChat|r: " .. (addon.L.LockChatSettingsAlert or addon.L.ChatSettingsLocked or "Chat settings locked in instances"))
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

-- Hide social button
local function hideSocialButton()
	if addon.IsRetail and _G.XCHT_DB and _G.XCHT_DB.hideSocial then
		if _G.QuickJoinToastButton then
			_G.QuickJoinToastButton:Hide()
			_G.QuickJoinToastButton:SetScript("OnShow", function() end)
		end
	end
end

-- Move social button to bottom
local function moveSocialButtonToBottom()
	if not addon.IsRetail then return end
	if not _G.XCHT_DB or not _G.XCHT_DB.moveSocialButtonToBottom then return end

	if _G.ChatAlertFrame then
		_G.ChatAlertFrame:ClearAllPoints()
		_G.ChatAlertFrame:SetPoint("TOPLEFT", _G.ChatFrame1, "BOTTOMLEFT", -33, -60)
	end
end

-- Hide chat menu button
local function hideChatMenuButton()
	if not _G.XCHT_DB or not _G.XCHT_DB.hideChatMenuButton then return end

	if _G.ChatFrameMenuButton then
		_G.ChatFrameMenuButton:Hide()
		_G.ChatFrameMenuButton:SetScript("OnShow", function() end)
	end
end

-- Hide voice chat buttons
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

-- Setup class colors for chat
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
	if _G.C_CVar then
		_G.C_CVar.SetCVar("profanityFilter", "0")
	elseif _G.SetCVar then
		_G.SetCVar("profanityFilter", "0")
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

	-- Setup slash commands using RegisterChatCommand to avoid taint
	_G["SLASH_XANCHAT1"] = "/xanchat"
	_G["SLASH_XANCHAT2"] = "/xanchat"
	if _G.RegisterChatCommand then
		_G.RegisterChatCommand("xanchat", handleSlashCommand)
	elseif _G.SlashCmdList then
		-- Fallback for older WoW versions
		_G.SlashCmdList["XANCHAT"] = function(msg)
			handleSlashCommand(msg)
		end
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

	-- Register cleanup event for lockdown deduplication table
	self:RegisterEvent("PLAYER_LEAVING_WORLD", "ClearLockdownProcessedMessages")

	-- Initialize Instance Warning module
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

function addon:ClearLockdownProcessedMessages()
	addon._lockdownProcessedMessages = {}
	addon.dbg("ClearLockdownProcessedMessages: cleared deduplication table")
end

function addon:OnDisable()
	addon.dbg("OnDisable: removing hooks and cleaning up")
	self:ClearLockdownProcessedMessages()

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
	if addon._tempWindowHookInstalled then return end
	if not _G.FCF_OpenTemporaryWindow then return end

	addon._origFCF_OpenTemporaryWindow = addon._origFCF_OpenTemporaryWindow or _G.FCF_OpenTemporaryWindow
	_G.FCF_OpenTemporaryWindow = function(...)
		local frame = addon._origFCF_OpenTemporaryWindow(...)
		if frame and frame.GetID then
			if addon.setupChatFrame then
				addon.setupChatFrame(frame:GetID())
			end
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
