--[[
	XanChat chat pipeline
	- proxy capture path for normal messages
	- direct safe path for secret message payloads
	- section-based formatting + callback stages
]]

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local ADDON_NAME, private = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
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
-- ACEHOOK INTEGRATION
-- ============================================================================
local LibStub = _G.LibStub
if not LibStub then
	error("AceHook-3.0 requires LibStub")
end

local AceHook = LibStub("AceHook-3.0", true)
if not AceHook then
	error("AceHook-3.0 not found in libs folder. Please ensure it is loaded.")
end

-- Embed AceHook into addon for self.hooks support (needed for AddMessage handler)
AceHook:Embed(addon)

-- ============================================================================
-- DEBUG SYSTEM
-- ============================================================================
local DEBUG_PREFIX = "XanChatDebug"
local function dbg(msg)
	if not msg then return end
	if not (addon.debugChat or (XCHT_DB and XCHT_DB.debugChat)) then return end
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		pcall(DEFAULT_CHAT_FRAME.AddMessage, DEFAULT_CHAT_FRAME, DEBUG_PREFIX .. ": " .. msg)
	end
end

local isSecretValue
local canAccessValue

local function dbgValue(v)
	local t = type(v)
	if t == "string" then
		if isSecretValue(v) then
			return "<secret-string>"
		end
		if not canAccessValue(v) then
			return "<inaccessible-string>"
		end
		return v
	end
	if t == "number" or t == "boolean" then
		return tostring(v)
	end
	if v == nil then
		return "nil"
	end
	return "<" .. t .. ">"
end

addon.DebugPrint = dbg
addon.DebugValue = dbgValue

local function ApplyDefaults(target, defaults)
	if not target or not defaults then return end
	for key, value in pairs(defaults) do
		if target[key] == nil then
			target[key] = value
		end
	end
end

addon.ApplyDefaults = ApplyDefaults

-- Secret Value Protection Functions
isSecretValue = function(v)
	local fn = _G.issecretvalue
	if type(fn) == "function" then
		local ok, res = pcall(fn, v)
		if ok then return not not res end
		return true
	end
	return false
end

canAccessValue = function(v)
	local fn = _G.canaccessvalue
	if type(fn) == "function" then
		local ok, res = pcall(fn, v)
		if ok then return not not res end
		return false
	end
	return true
end

local function isSafeString(v)
	if isSecretValue(v) then return false end
	if not canAccessValue(v) then return false end
	if type(v) ~= "string" then return false end
	return true
end

local function safestr(v)
	if isSecretValue(v) then return "<secret-string>" end
	if not canAccessValue(v) then return "<inaccessible-string>" end
	if type(v) ~= "string" then return "" end
	return v
end

-- Color Helper
local function RGBAToHex(r, g, b, a)
	r = math.min(math.max(tonumber(r) or 1, 0), 1)
	g = math.min(math.max(tonumber(g) or 1, 0), 1)
	b = math.min(math.max(tonumber(b) or 1, 0), 1)
	a = math.min(math.max(tonumber(a) or 1, 0), 1)
	return string.format("%02X%02X%02X%02X", a * 255, r * 255, g * 255, b * 255)
end

local function HexToRGBA(hex)
	if type(hex) ~= "string" or #hex < 8 then
		return 1, 1, 1, 1
	end
	return tonumber("0x" .. string.sub(hex, 3, 4), 10) / 255,
		tonumber("0x" .. string.sub(hex, 5, 6), 10) / 255,
		tonumber("0x" .. string.sub(hex, 7, 8), 10) / 255,
		tonumber("0x" .. string.sub(hex, 1, 2), 10) / 255
end

-- ============================================================================
-- MESSAGE PROCESSING POLICY
-- ============================================================================

local ProcessingMode = {
	Standard = 10,
	PatternOnly = 20,
}

addon.EventProcessingType = {
	Full = ProcessingMode.Standard,
	PatternsOnly = ProcessingMode.PatternOnly,
}

local defaultProcessingMode = {}
local processingModeOverrides = {}

local function applyDefaultMode(mode, eventList)
	for i = 1, #eventList do
		defaultProcessingMode[eventList[i]] = mode
	end
end

applyDefaultMode(ProcessingMode.Standard, {
	"CHAT_MSG_CHANNEL", "CHAT_MSG_SAY", "CHAT_MSG_GUILD", "CHAT_MSG_WHISPER",
	"CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_YELL", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_OFFICER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
	"CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_SYSTEM", "CHAT_MSG_DND",
	"CHAT_MSG_AFK", "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM", "CHAT_MSG_BN_CONVERSATION",
	"CHAT_MSG_COMMUNITIES_CHANNEL",
})
defaultProcessingMode.CHAT_MSG_LOOT = ProcessingMode.PatternOnly

local function resolveProcessingMode(event)
	local overrideMode = processingModeOverrides[event]
	if overrideMode ~= nil then
		return overrideMode
	end
	return defaultProcessingMode[event]
end

function addon:EnableProcessingForEvent(event, flag)
	if flag == nil or flag == true then
		processingModeOverrides[event] = ProcessingMode.Standard
		return
	end
	if flag == false then
		processingModeOverrides[event] = false
		return
	end
	processingModeOverrides[event] = flag
end

function addon:EventIsProcessed(event)
	return resolveProcessingMode(event)
end

-- ============================================================================
-- PROXY SYSTEM
-- ============================================================================

local proxyCopySkipFields = {
	"historyBuffer",
	"isLayoutDirty",
	"isDisplayDirty",
	"onDisplayRefreshedCallback",
	"onScrollChangedCallback",
	"onTextCopiedCallback",
	"scrollOffset",
	"visibleLines",
	"highlightTexturePool",
	"fontStringPool",
	"AddMessage",
	"IsShown",
}
local proxyCopySkipLookup = {}
for i = 1, #proxyCopySkipFields do
	proxyCopySkipLookup[proxyCopySkipFields[i]] = true
end

local captureProxyFrame = nil
local MISSING_VALUE = {}
local proxyTransferState = {
	touched = {},
	snapshot = {},
	originalIsShown = nil,
}
local captureState = {
	proxy = nil,
	text = nil,
	color = { r = nil, g = nil, b = nil, id = nil },
}

local function resetCaptureState()
	captureState.proxy = nil
	captureState.text = nil
	captureState.color.r = nil
	captureState.color.g = nil
	captureState.color.b = nil
	captureState.color.id = nil
end

local function ensureCaptureProxyFrame()
	if captureProxyFrame then
		return captureProxyFrame
	end

	dbg("Creating capture proxy frame")

	captureProxyFrame = CreateFrame("ScrollingMessageFrame")
	if Mixin and ChatFrameMixin then
		Mixin(captureProxyFrame, ChatFrameMixin)
	end

	-- Use RawHook for AddMessage capture
	-- hookSecure = true allows hooking secure functions on the proxy frame
	-- The handler is addon:AddMessage which captures the formatted output
	addon:RawHook(captureProxyFrame, "AddMessage", true)

	return captureProxyFrame
end

local function isMirrorableFrameField(fieldName, value)
	if type(value) == "function" then
		return false
	end
	return not proxyCopySkipLookup[fieldName]
end

local function clearProxyTransferState()
	for i = #proxyTransferState.touched, 1, -1 do
		local key = proxyTransferState.touched[i]
		proxyTransferState.touched[i] = nil
		proxyTransferState.snapshot[key] = nil
	end
	proxyTransferState.originalIsShown = nil
end

function addon:CreateProxy(frame)
	dbg("CreateProxy: mirroring frame state to proxy")

	local proxy = captureProxyFrame or ensureCaptureProxyFrame()
	if not proxy then
		return frame
	end

	clearProxyTransferState()

	if type(frame) ~= "table" then
		return proxy
	end

	for key, value in pairs(frame) do
		if isMirrorableFrameField(key, value) then
			if proxyTransferState.snapshot[key] == nil then
				local previous = proxy[key]
				proxyTransferState.snapshot[key] = previous == nil and MISSING_VALUE or previous
				proxyTransferState.touched[#proxyTransferState.touched + 1] = key
			end
			proxy[key] = value
		end
	end

	local priorIsShown = proxy.IsShown
	proxyTransferState.originalIsShown = priorIsShown == nil and MISSING_VALUE or priorIsShown
	proxy.IsShown = function()
		return true
	end

	return proxy
end

function addon:RestoreProxy()
	dbg("RestoreProxy: undoing mirrored proxy state")

	if not captureProxyFrame then
		return
	end

	for i = #proxyTransferState.touched, 1, -1 do
		local key = proxyTransferState.touched[i]
		local previous = proxyTransferState.snapshot[key]
		if previous == MISSING_VALUE then
			captureProxyFrame[key] = nil
		else
			captureProxyFrame[key] = previous
		end
		proxyTransferState.touched[i] = nil
		proxyTransferState.snapshot[key] = nil
	end

	if proxyTransferState.originalIsShown ~= nil then
		if proxyTransferState.originalIsShown == MISSING_VALUE then
			captureProxyFrame.IsShown = nil
		else
			captureProxyFrame.IsShown = proxyTransferState.originalIsShown
		end
		proxyTransferState.originalIsShown = nil
	end
end

-- ============================================================================
-- ADDMESSAGE HANDLER (for AceHook RawHook)
-- ============================================================================
addon.AddMessage = function(self, frame, text, r, g, b, id, ...)
	-- Capture text when called on the capture proxy frame
	if captureState.proxy == frame and captureState.text == nil then
		captureState.text = text
		captureState.color.r = r
		captureState.color.g = g
		captureState.color.b = b
		captureState.color.id = id
		dbg("capture proxy stored formatter output")
		return
	end
	-- Call original AddMessage for non-capture calls
	return self.hooks[frame].AddMessage(frame, text, r, g, b, id, ...)
end

-- ============================================================================
-- CHAT SECTIONS SYSTEM
-- ============================================================================

dbg("chat_sections_system_init")

-- Parse a space-separated section token specification into an ordered token list
local function parseSectionLayout(spec)
	dbg("parseSectionLayout: parsing spec")
	local out = {}
	for token in string.gmatch(spec, "%S+") do
		out[#out + 1] = token
	end
	dbg("parseSectionLayout: parsed " .. #out .. " tokens")
	return out
end

-- Chat line composition stages (logical grouping of section tokens)
-- These layouts define the structure of how Blizzard chat lines are assembled
local CHAT_LAYOUT_PREFIX = parseSectionLayout([[
PRE nN CHANLINK NN cC CHANNELNUM CC CHANNEL Cc TYPEPREFIX Nn
]])

local CHAT_LAYOUT_PLAYER = parseSectionLayout([[
fF FLAG Ff pP TIMERUNNER lL PLAYERLINK PLAYERLINKDATA LL PLAYER
NONPLAYER sS SERVER Ss Ll Pp
]])

local CHAT_LAYOUT_POST_PLAYER = parseSectionLayout([[
TYPEPOSTFIX mM gG LANGUAGE Gg MOBILE
]])

local CHAT_LAYOUT_SUFFIX = parseSectionLayout([[
Mm POST
]])

-- Complete section token registry for buffer initialization
-- This contains all possible section tokens that may appear in chat messages
local CHAT_SECTION_REGISTRY = parseSectionLayout([[
PRE nN CHANLINK NN cC CHANNELNUM CC CHANNEL zZ ZONE Zz Cc TYPEPREFIX Nn
fF FLAG Ff pP TIMERUNNER lL PLAYERLINK PLAYERLINKDATA LL PLAYER NONPLAYER sS
SERVER Ss Ll Pp TYPEPOSTFIX mM gG LANGUAGE Gg MOBILE MESSAGE Mm POST
]])

-- Pooled section buffers to avoid frequent table allocations
local sectionOriginal = {}
local sectionWorking = { ORG = sectionOriginal }
local buildPartsPrefix = {}
local buildPartsPlayer = {}
local buildPartsPostPlayer = {}
local buildPartsSuffix = {}

-- Initialize all section tokens in a buffer with empty string defaults
local function resetSectionBuffer(buffer)
	dbg("resetSectionBuffer: clearing buffer")
	for k in pairs(buffer) do
		buffer[k] = nil
	end
	for i = 1, #CHAT_SECTION_REGISTRY do
		buffer[CHAT_SECTION_REGISTRY[i]] = ""
	end
end

-- Prepare working sections by copying from original data
local function prepareWorkingSections()
	dbg("prepareWorkingSections: copying original to working")
	resetSectionBuffer(sectionWorking)
	for key, value in pairs(sectionOriginal) do
		sectionWorking[key] = value
	end
	sectionWorking.ORG = sectionOriginal
end

-- Clear a pooled build list for reuse
local function clearBuildList(list)
	for i = #list, 1, -1 do
		list[i] = nil
	end
end

-- Append layout tokens from a message to a build list
local function appendLayout(list, msg, layout)
	for i = 1, #layout do
		list[#list + 1] = msg[layout[i]] or ""
	end
end

-- Build complete chat text from parsed message sections
-- Assembles the message in Blizzard-standard format: prefix + player + post-player + message + suffix
function addon:BuildChatText(message)
	dbg("BuildChatText: building chat text")
	local msg = message or sectionWorking

	-- Clear pooled build lists for reuse
	clearBuildList(buildPartsPrefix)
	clearBuildList(buildPartsPlayer)
	clearBuildList(buildPartsPostPlayer)
	clearBuildList(buildPartsSuffix)

	-- Build each section stage
	appendLayout(buildPartsPrefix, msg, CHAT_LAYOUT_PREFIX)
	appendLayout(buildPartsPlayer, msg, CHAT_LAYOUT_PLAYER)
	appendLayout(buildPartsPostPlayer, msg, CHAT_LAYOUT_POST_PLAYER)
	appendLayout(buildPartsSuffix, msg, CHAT_LAYOUT_SUFFIX)

	-- Assemble complete chat line
	-- SPLAYER is inserted between player and post-player sections for custom player styling
	local result = table.concat(buildPartsPrefix, "")
		.. table.concat(buildPartsPlayer, "")
		.. (msg.SPLAYER or "")
		.. table.concat(buildPartsPostPlayer, "")
		.. (msg.MESSAGE or "")
		.. table.concat(buildPartsSuffix, "")

	if isSafeString(result) then
		dbg("BuildChatText: result length=" .. #result)
	end
	return result
end

-- ============================================================================
-- PATTERN MATCHING SYSTEM
-- ============================================================================

local PatternRegistry = { patterns = {}, sortedList = {}, sorted = true }
local tokennum = 1
local MatchTable = {}

-- UUID generator for pattern IDs
local function uuid()
	local template = 'xyxxxxyx'
	return template:gsub('[xy]', function(c)
		local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
		return string.format('%x', v)
	end)
end

-- Register a pattern with the pattern matching engine
local function RegisterPattern(pattern, owner)
	local idx
	repeat
		idx = uuid()
	until PatternRegistry.patterns[idx] == nil

	PatternRegistry.patterns[idx] = pattern
	table.insert(PatternRegistry.sortedList, pattern)
	PatternRegistry.sorted = false

	pattern.owner = owner
	pattern.idx = idx

	dbg("RegisterPattern: idx=" .. tostring(idx) .. " priority=" .. tostring(pattern.priority))
	return idx
end

-- Unregister all patterns for a specific owner
local function UnregisterAllPatterns(owner)
	dbg("UnregisterAllPatterns: owner=" .. tostring(owner))

	for i = #PatternRegistry.sortedList, 1, -1 do
		local pattern = PatternRegistry.sortedList[i]
		if pattern and pattern.owner == owner then
			table.remove(PatternRegistry.sortedList, i)
			PatternRegistry.patterns[pattern.idx] = nil
		end
	end
end

-- RegisterMatch: Create a token for matched text
function RegisterMatch(text, ptype)
	tokennum = tokennum + 1

	local token = "@##" .. tokennum .. "##@"

	dbg("RegisterMatch: token=" .. token .. " text=" .. text)

	local mt = MatchTable[ptype or "FRAME"]
	if not mt then
		MatchTable[ptype or "FRAME"] = {}
		mt = MatchTable[ptype or "FRAME"]
	end
	mt[token] = text

	return token
end

-- Remove matched strings and replace them with temporary tokens
function addon:MatchPatterns(m, ptype)
	local text = m.MESSAGE

	-- Secret value guard
	if _G.issecretvalue and _G.issecretvalue(text) then
		dbg("MatchPatterns: secret value, returning")
		return text
	end

	ptype = ptype or "FRAME"
	tokennum = 0

	-- Sort patterns by priority
	if not PatternRegistry.sorted then
		table.sort(PatternRegistry.sortedList, function(a, b)
			local ap = a.priority or 50
			local bp = b.priority or 50
			return ap < bp
		end)
		PatternRegistry.sorted = true
	end

	-- Match and remove strings
	for _, v in ipairs(PatternRegistry.sortedList) do
		if text and ptype == (v.type or "FRAME") then
				if type(v.pattern) == "string" and string.len(v.pattern) > 0 then
					dbg("MatchPatterns: checking pattern=" .. v.pattern)
					if v.matchfunc ~= nil then
						text = string.gsub(text, v.pattern, function(...)
							local parms = { ... }
							table.insert(parms, m)
							return v.matchfunc(unpack(parms))
						end)
					end
			end
		end
	end

	dbg("MatchPatterns: result=" .. text)
	return text
end

-- Put tokenized matches back into the text
function addon:ReplaceMatches(m, ptype)
	local text = m.MESSAGE

	-- Secret value guard
	if _G.issecretvalue and _G.issecretvalue(text) then
		dbg("ReplaceMatches: secret value, returning")
		return text
	end

	ptype = ptype or "FRAME"
	local mt = MatchTable[ptype]

	-- Substitute tokens back
	for t = tokennum, 1, -1 do
		local k = "@##" .. tostring(t) .. "##@"

		if mt and mt[k] then
			local cleaned = mt[k]:gsub("([%%W])", "%%%1")
			text = string.gsub(text, k, cleaned)
		else
			dbg("ReplaceMatches: token not found: " .. k)
		end
		if mt then
			mt[k] = nil
		end
	end

	dbg("ReplaceMatches: result=" .. text)
	return text
end

-- ============================================================================
-- EVENT CALLBACK SYSTEM
-- ============================================================================

local callbacks = nil

local function initCallbacks()
	if callbacks then return end

	callbacks = {
		registry = {},
	}

	function callbacks:Register(event, handler)
		if type(event) ~= "string" or type(handler) ~= "function" then
			return
		end
		if not callbacks.registry[event] then
			callbacks.registry[event] = {}
		end
		table.insert(callbacks.registry[event], handler)
	end

	function callbacks:Unregister(event, handler)
		if not callbacks.registry[event] then
			return
		end
		for i, h in ipairs(callbacks.registry[event]) do
			if h == handler then
				table.remove(callbacks.registry[event], i)
				break
			end
		end
	end

	function callbacks:Fire(event, ...)
		local list = callbacks.registry[event]
		if not list then
			return
		end
		for _, h in ipairs(list) do
			local ok, err = pcall(h, ...)
			if not ok then
				dbg("Callback error: " .. tostring(err))
			end
		end
	end

	function callbacks:UnregisterAll()
		for key in pairs(callbacks.registry) do
			callbacks.registry[key] = nil
		end
	end
end

-- Event constants
local EVENTS = {
	FRAME_MESSAGE = "XanChat_FrameMessage",
	PRE_ADDMESSAGE = "XanChat_PreAddMessage",
	POST_ADDMESSAGE = "XanChat_PostAddMessage",
	POST_ADDMESSAGE_BLOCKED = "XanChat_PostAddMessageBlocked",
}

-- ============================================================================
-- MAIN MESSAGE HANDLER
-- ============================================================================

-- Parse WoW event args into chat sections
function addon:SplitChatMessage(frame, event, ...)
	dbg("SplitChatMessage: START event=" .. tostring(event))
	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17 = ...
	local isSecret = _G.issecretvalue and _G.issecretvalue(arg1)

	dbg("SplitChatMessage: isSecret=" .. tostring(isSecret) .. " arg1=" .. dbgValue(arg1))

	if type(event) ~= "string" or string.sub(event, 1, 8) ~= "CHAT_MSG" then
		dbg("SplitChatMessage: not a CHAT_MSG event, returning nil")
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
	resetSectionBuffer(sectionOriginal)
	local s = sectionOriginal

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
	s.MESSAGE = isSecret and arg1 or (safestr(arg1) or ""):gsub("^%s*(.-)%s*$", "%1")

	-- Check if player name is a secret value (SEPARATE from message text secret check)
	local isArg2Secret = _G.issecretvalue and _G.issecretvalue(arg2)
	local coloredName = arg2

		-- Extract player information
	if not isArg2Secret and type(arg2) == "string" and arg2 ~= "" then
		-- Check if player name is a secret value (SEPARATE from message text secret check)
		local isArg2Secret = _G.issecretvalue and _G.issecretvalue(arg2)
		local coloredName = arg2

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

			s.PLAYERLINK = playerLink

			-- Extract name and server
			local plr, svr = arg2:match("([^%-]+)%-?(.*)")
			if plr then
				s.PLAYER = plr
			end
			if svr and string.len(svr) > 0 then
				s.sS = "-"
				s.SERVER = svr
				s.Ss = ""
			end
		end
	end

	-- Extract channel information
	if type(arg3) == "string" and arg3 ~= "" and arg3 ~= "Universal" then
		s.gG = "["
		s.LANGUAGE = arg3
		s.Gg = "] "
	elseif type(arg3) == "string" and arg3 ~= "" then
		s.LANGUAGE_NOSHOW = arg3
	end

	-- Extract channel name
	if string.len(arg8 or "") > 0 or chatGroup == "BN_CONVERSATION" then
		s.CC = "["

		if chatGroup == "BN_CONVERSATION" then
			s.CHANNELNUM = tostring((_G.MAX_WOW_CHAT_CHANNELS or 20) + (arg8 or 0))
			if _G.CHAT_BN_CONVERSATION_SEND then
				s.CHANNEL = string.match(_G.CHAT_BN_CONVERSATION_SEND or "", "%d%.%s+(.+)")
			end
		else
			local channelNum = tonumber(arg8) or tonumber(arg7) or tonumber(arg9) or tonumber(arg10) or 0
			if channelNum and channelNum > 0 then
				s.CHANNELNUM = tostring(channelNum)

				-- Try to get channel name from arg9
				local arg9Text = arg9 or ""
				if string.len(arg9Text) > 0 then
					s.CHANNEL = arg9Text
				end
			end
		end
		s.cC = "] "
	end

	-- Extract flags
	if type(arg6) == "string" and arg6 ~= "" then
		s.fF = ""

		if arg6 == "GM" or arg6 == "DEV" then
			s.FLAG = "|TInterface\\ChatFrame\\UI-ChatIcon-Blizz:12:20:0:0:32:16:4:28:0:16|t "
		elseif arg6 == "GUIDE" and _G.ChatFrame_GetMentorChannelStatus then
			if _G.Enum and _G.Enum.PlayerMentorshipStatus and _G.C_ChatInfo then
				local mentorStatus = _G.ChatFrame_GetMentorChannelStatus(_G.Enum.PlayerMentorshipStatus.Mentor, _G.C_ChatInfo.GetChannelRulesetForChannelID(arg7))
				if mentorStatus == _G.Enum.PlayerMentorshipStatus.Mentor then
					s.FLAG = (_G.NPEV2_CHAT_USER_TAG_GUIDE or "[Guide]") .. " "
				elseif mentorStatus == _G.Enum.PlayerMentorshipStatus.Newcomer then
					s.FLAG = _G.NPEV2_CHAT_USER_TAG_NEWCOMER or "[New]"
				end
			end
		elseif arg6 == "NEWCOMER" and _G.ChatFrame_GetMentorChannelStatus then
			if _G.Enum and _G.Enum.PlayerMentorshipStatus and _G.C_ChatInfo then
				local mentorStatus = _G.ChatFrame_GetMentorChannelStatus(_G.Enum.PlayerMentorshipStatus.Newcomer, _G.C_ChatInfo.GetChannelRulesetForChannelID(arg7))
				if mentorStatus == _G.Enum.PlayerMentorshipStatus.Newcomer then
					s.FLAG = _G.NPEV2_CHAT_USER_TAG_NEWCOMER or "[New]"
				end
			end
		elseif _G["CHAT_FLAG_" .. arg6] then
			s.FLAG = _G["CHAT_FLAG_" .. arg6] or ""
		end

		s.Ff = ""
	end

	-- Extract mobile texture
	if arg15 and info then
		local mobileFn = _G.ChatFrame_GetMobileEmbeddedTexture or (_G.ChatFrameUtil and _G.ChatFrameUtil.GetMobileEmbeddedTexture)
		if mobileFn then
			s.MOBILE = mobileFn(info.r or 1, info.g or 1, info.b or 1) or ""
		end
	end

	s.INFO = info
	prepareWorkingSections()
	return sectionWorking, info
end

local applyShortChannelNames
local applyPlayerChatStyle
local shouldSuppressJoinLeaveMessage

local function callOriginalMessageHandler(self, frame, event, ...)
	if self._chatEventHooked == "global" then
		-- Use AceHook's stored original for global hook
		return self.hooks and self.hooks.ChatFrame_MessageEventHandler and self.hooks.ChatFrame_MessageEventHandler(frame, event, ...)
	elseif self._chatEventHooked == "frame" and frame then
		local frameName = frame and frame.GetName and frame:GetName()
		if frameName and self._hooks[frameName] then
			-- Call the original function stored in self._hooks
			return self._hooks[frameName](frame, event, ...)
		end
	end
	return nil
end

local function shouldRunPatternPass(isSecretPayload, mode)
	if isSecretPayload then
		return false
	end
	return mode == addon.EventProcessingType.Full or mode == addon.EventProcessingType.PatternsOnly
end

local function runFrameMessageFilters(frame, event, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14)
	if string.sub(event or "", 1, 8) ~= "CHAT_MSG" then
		return false, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14
	end
	if not (_G.ChatFrameUtil or not _G.ChatFrameUtil.ProcessMessageEventFilters) then
		return false, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14
	end
	local discard = false
	discard, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14 =
		_G.ChatFrameUtil.ProcessMessageEventFilters(frame, event, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14)
	return discard, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14
end

function addon:ChatFrame_MessageEventHandler(this, event, ...)
	local frameName = this and this.GetName and this:GetName() or "<unknown>"
	dbg("ChatFrame_MessageEventHandler: START event=" .. tostring(event) .. " frame=" .. tostring(frameName))

	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15 = ...
	local isSecretPayload = _G.issecretvalue and _G.issecretvalue(arg1)
	local processMode = addon:EventIsProcessed(event)
	local handlerResult

	dbg("ChatFrame_MessageEventHandler: isSecretPayload=" .. tostring(isSecretPayload) .. " processMode=" .. tostring(processMode))

	if not this then
		dbg("ChatFrame_MessageEventHandler: missing frame, passthrough")
		return callOriginalMessageHandler(self, this, event, ...)
	end
	if not addon.HookedFrames or not addon.HookedFrames[frameName] then
		dbg("ChatFrame_MessageEventHandler: frame not managed, passthrough")
		return callOriginalMessageHandler(self, this, event, ...)
	end

	dbg("ChatFrame_MessageEventHandler: frame is managed by xanChat")

	if not isSecretPayload and type(arg1) == "string" and string.find(arg1, "\r", 1, true) then
		dbg("ChatFrame_MessageEventHandler: cleaning carriage returns from message")
		arg1 = string.gsub(arg1, "\r", " ")
	end

	local shouldDiscard
	shouldDiscard, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14 =
		runFrameMessageFilters(this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
	if shouldDiscard then
		dbg("ChatFrame_MessageEventHandler: message discarded by Blizzard filters")
		return true
	end

	dbg("ChatFrame_MessageEventHandler: message passed Blizzard filters, calling SplitChatMessage")

	local parsedMessage, info = addon:SplitChatMessage(this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
	if type(parsedMessage) == "boolean" and parsedMessage == true then
		dbg("ChatFrame_MessageEventHandler: split returned boolean, passing through")
		return true
	end
	if not isSecretPayload and not info then
		dbg("ChatFrame_MessageEventHandler: split failed for non-secret, passthrough")
		return callOriginalMessageHandler(self, this, event, ...)
	end
	if type(parsedMessage) ~= "table" then
		dbg("ChatFrame_MessageEventHandler: split did not return table, passthrough")
		return callOriginalMessageHandler(self, this, event, ...)
	end

	dbg("ChatFrame_MessageEventHandler: split successful, preparing message processing")

	local m = parsedMessage
	local resolvedEvent = m.EVENT or event

	resetCaptureState()
	m.OUTPUT = nil
	m.DONOTPROCESS = nil

	if callbacks and callbacks.Fire then
		dbg("ChatFrame_MessageEventHandler: firing FRAME_MESSAGE callback")
		callbacks:Fire(EVENTS.FRAME_MESSAGE, m, this, resolvedEvent)
	end

	-- Branch: non-secret uses proxy capture, secret uses direct output
	if not isSecretPayload then
		dbg("ChatFrame_MessageEventHandler: NON-SECRET path, using proxy capture")
		local proxyFrame = addon:CreateProxy(this)
		m.CAPTUREOUTPUT = proxyFrame
		captureState.proxy = proxyFrame
		handlerResult = callOriginalMessageHandler(self, proxyFrame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
		addon:RestoreProxy()
		m.OUTPUT = captureState.text
		dbg("ChatFrame_MessageEventHandler: proxy capture result: " .. dbgValue(m.OUTPUT))
	else
		dbg("ChatFrame_MessageEventHandler: SECRET path, using direct output")
		handlerResult = true
		m.OUTPUT = arg1 or ""
	end

	m.CAPTUREOUTPUT = false
	captureState.proxy = nil

	if not isSecretPayload and type(m.OUTPUT) ~= "string" then
		dbg("ChatFrame_MessageEventHandler: capture miss, passthrough")
		resetCaptureState()
		m.CAPTUREOUTPUT = nil
		return callOriginalMessageHandler(self, this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
	end

	if type(m.MESSAGE) ~= "string" then
		m.MESSAGE = m.MESSAGE and tostring(m.MESSAGE) or ""
	end

	if type(m.OUTPUT) == "string" and not m.DONOTPROCESS then
		dbg("ChatFrame_MessageEventHandler: building display text")
		local infoRow = m.INFO or info or {}
		local outR, outG, outB, outID = infoRow.r or 1, infoRow.g or 1, infoRow.b or 1, infoRow.id or 0
		local textToDisplay = m.OUTPUT
		local applyPatterns = shouldRunPatternPass(isSecretPayload, processMode)

		dbg("ChatFrame_MessageEventHandler: applyPatterns=" .. tostring(applyPatterns))

		if applyPatterns then
			dbg("ChatFrame_MessageEventHandler: running MatchPatterns")
			m.MESSAGE = addon:MatchPatterns(m, "FRAME")
			if type(m.MESSAGE) ~= "string" then
				m.MESSAGE = m.MESSAGE and tostring(m.MESSAGE) or ""
			end
		end

		if callbacks and callbacks.Fire then
			dbg("ChatFrame_MessageEventHandler: firing PRE_ADDMESSAGE callback")
			callbacks:Fire(EVENTS.PRE_ADDMESSAGE, m, this, resolvedEvent, addon:BuildChatText(m), outR, outG, outB, outID)
		end

		if applyPatterns then
			dbg("ChatFrame_MessageEventHandler: running ReplaceMatches")
			m.MESSAGE = addon:ReplaceMatches(m, "FRAME")
		end

		if processMode == addon.EventProcessingType.Full then
			dbg("ChatFrame_MessageEventHandler: using Full processing mode, building from sections")
			textToDisplay = addon:BuildChatText(m) or ""
		elseif processMode == addon.EventProcessingType.PatternsOnly then
			dbg("ChatFrame_MessageEventHandler: using PatternsOnly processing mode")
			textToDisplay = (m.PRE or "") .. (m.MESSAGE or "") .. (m.POST or "")
		else
			dbg("ChatFrame_MessageEventHandler: using output-only processing mode")
			textToDisplay = (m.PRE or "") .. (m.OUTPUT or "") .. (m.POST or "")
		end

		-- Apply xanChat-specific transformations
		if applyShortChannelNames then
			dbg("ChatFrame_MessageEventHandler: applying short channel names")
			textToDisplay = applyShortChannelNames(textToDisplay)
		end
		if applyPlayerChatStyle then
			dbg("ChatFrame_MessageEventHandler: applying player chat style")
			textToDisplay = applyPlayerChatStyle(this, resolvedEvent, textToDisplay)
		end

		-- Check for join/leave suppression
		if shouldSuppressJoinLeaveMessage and shouldSuppressJoinLeaveMessage(resolvedEvent, textToDisplay) then
			dbg("ChatFrame_MessageEventHandler: suppressing join/leave message")
			m.DONOTPROCESS = true
		end

		m.OUTPUT = textToDisplay
		dbg("ChatFrame_MessageEventHandler: final output=" .. dbgValue(textToDisplay))

		if m.DONOTPROCESS then
			dbg("ChatFrame_MessageEventHandler: message blocked, firing POST_ADDMESSAGE_BLOCKED callback")
			if callbacks and callbacks.Fire then
				callbacks:Fire(EVENTS.POST_ADDMESSAGE_BLOCKED, m, this, resolvedEvent, textToDisplay, outR, outG, outB, outID)
			end
		elseif isSecretPayload then
			dbg("ChatFrame_MessageEventHandler: adding secret message to frame")
			this:AddMessage(textToDisplay, outR, outG, outB, outID, m.ACCESSID, m.TYPEID)
			if callbacks and callbacks.Fire then
				callbacks:Fire(EVENTS.POST_ADDMESSAGE, m, this, resolvedEvent, textToDisplay, outR, outG, outB, outID)
			end
		elseif string.len(textToDisplay) > 0 then
			dbg("ChatFrame_MessageEventHandler: adding non-secret message to frame")
			local capturedR = captureState.color.r or outR
			local capturedG = captureState.color.g or outG
			local capturedB = captureState.color.b or outB
			local capturedID = captureState.color.id or outID
			local isCensored = arg11 and _G.C_ChatInfo and _G.C_ChatInfo.IsChatLineCensored(arg11)
			local visibleText = isCensored and (arg1 or "") or textToDisplay

			dbg("ChatFrame_MessageEventHandler: isCensored=" .. tostring(isCensored))

			if isCensored then
				this:AddMessage(visibleText, capturedR, capturedG, capturedB, capturedID, m.ACCESSID, m.TYPEID, event, { ... }, function(text)
					return text
				end)
			else
				this:AddMessage(visibleText, capturedR, capturedG, capturedB, capturedID, m.ACCESSID, m.TYPEID)
			end

			if callbacks and callbacks.Fire then
				callbacks:Fire(EVENTS.POST_ADDMESSAGE, m, this, resolvedEvent, textToDisplay, capturedR, capturedG, capturedB, capturedID)
			end
		else
			dbg("ChatFrame_MessageEventHandler: empty output, skipping display")
		end
	end

	dbg("ChatFrame_MessageEventHandler: cleanup and return")
	resetCaptureState()
	m.CAPTUREOUTPUT = nil
	return handlerResult
end

-- ============================================================================
-- XANCHAT FEATURES INTEGRATION
-- ============================================================================

addon.Frames = addon.Frames or {}
addon.HookedFrames = addon.HookedFrames or {}
addon.playerList = addon.playerList or {}
addon.playerListByName = addon.playerListByName or {}
addon.playerListRing = addon.playerListRing or {}
addon.playerListRingPos = addon.playerListRingPos or 0

addon.isFilterListEnabled = true
local function buildUrlLink(url)
	return " |cff99FF33|Hurl:" .. url .. "|h[" .. url .. "]|h|r "
end

local URL_PATTERNS = {
	{
		pattern = "(%a+)://(%S+)%s?",
		matchfunc = function(scheme, remainder)
			return RegisterMatch(buildUrlLink(scheme .. "://" .. remainder), "FRAME")
		end,
		priority = 50,
		type = "FRAME",
	},
	{
		pattern = "www%.([_A-Za-z0-9-]+)%.(%S+)%s?",
		matchfunc = function(domain, tail)
			return RegisterMatch(buildUrlLink("www." .. domain .. "." .. tail), "FRAME")
		end,
		priority = 50,
		type = "FRAME",
	},
	{
		pattern = "([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?",
		matchfunc = function(user, domain, dots, tld)
			return RegisterMatch(buildUrlLink(user .. "@" .. domain .. dots .. tld), "FRAME")
		end,
		priority = 50,
		type = "FRAME",
	},
	{
		pattern = "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?):(%d%d?%d?%d?%d?)%s?",
		matchfunc = function(a, b, c, d, port)
			return RegisterMatch(buildUrlLink(a .. "." .. b .. "." .. c .. "." .. d .. ":" .. port), "FRAME")
		end,
		priority = 50,
		type = "FRAME",
	},
	{
		pattern = "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?",
		matchfunc = function(a, b, c, d)
			return RegisterMatch(buildUrlLink(a .. "." .. b .. "." .. c .. "." .. d), "FRAME")
		end,
		priority = 50,
		type = "FRAME",
	},
}

local function registerUrlPatterns()
	if addon._urlPatternsRegistered then
		dbg("registerUrlPatterns: already registered")
		return
	end
	dbg("registerUrlPatterns: registering " .. #URL_PATTERNS .. " URL patterns")
	for _, pat in ipairs(URL_PATTERNS) do
		RegisterPattern(pat, "xanChat-URL")
	end
	addon._urlPatternsRegistered = true
end

local function unregisterUrlPatterns()
	if not addon._urlPatternsRegistered then
		return
	end
	UnregisterAllPatterns("xanChat-URL")
	addon._urlPatternsRegistered = false
end

local function installUrlCopyHook()
	if addon._urlCopyHookInstalled then
		return
	end
	if not _G.ItemRefTooltip or not _G.ItemRefTooltip.SetHyperlink then
		return
	end

	StaticPopupDialogs["LINKME"] = StaticPopupDialogs["LINKME"] or {
		text = addon.L.URLCopy or "Copy URL",
		button2 = CANCEL,
		hasEditBox = true,
		hasWideEditBox = true,
		timeout = 0,
		exclusive = 1,
		hideOnEscape = 1,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		whileDead = 1,
		maxLetters = 255,
	}

	local originalSetHyperlink = _G.ItemRefTooltip.SetHyperlink
	_G.ItemRefTooltip.SetHyperlink = function(self, link, ...)
		if type(link) == "string" and string.sub(link, 1, 3) == "url" then
			local url = string.sub(link, 5)
			local dialog = StaticPopup_Show("LINKME")
			if dialog then
				local editbox = _G[dialog:GetName() .. "EditBox"]
				if editbox then
					editbox:SetText(url)
					editbox:SetFocus()
					editbox:HighlightText()
					local button = _G[dialog:GetName() .. "Button2"]
					if button then
						button:ClearAllPoints()
						button:SetPoint("CENTER", editbox, "CENTER", 0, -30)
					end
				end
			end
			return
		end
		return originalSetHyperlink(self, link, ...)
	end

	addon._urlCopyHookInstalled = true
end

local SHORT_CHANNEL_REPLACEMENTS = {
	{ addon.L.ChannelGeneral or "General", addon.L.ShortGeneral or "Gen" },
	{ addon.L.ChannelTradeServices or "Trade - Services", addon.L.ShortTradeServices or "Trade-S" },
	{ addon.L.ChannelTrade or "Trade", addon.L.ShortTrade or "Trade" },
	{ addon.L.ChannelWorldDefense or "WorldDefense", addon.L.ShortWorldDefense or "WDef" },
	{ addon.L.ChannelLocalDefense or "LocalDefense", addon.L.ShortLocalDefense or "LDef" },
	{ addon.L.ChannelLookingForGroup or "LookingForGroup", addon.L.ShortLookingForGroup or "LFG" },
	{ addon.L.ChannelGuildRecruitment or "GuildRecruitment", addon.L.ShortGuildRecruitment or "Guild" },
	{ addon.L.ChannelNewComerChat or "NewComers", addon.L.ShortNewComerChat or "New" },
}

applyShortChannelNames = function(text)
	if not (XCHT_DB and XCHT_DB.shortNames) or type(text) ~= "string" then
		return text
	end

	dbg("applyShortChannelNames: processing text")
	local chatNum = string.match(text, "%d+") or ""
	if tonumber(chatNum) then
		chatNum = chatNum .. ":"
	else
		chatNum = ""
	end

	for i = 1, #SHORT_CHANNEL_REPLACEMENTS do
		local longName = SHORT_CHANNEL_REPLACEMENTS[i][1]
		local shortName = SHORT_CHANNEL_REPLACEMENTS[i][2]
		if longName and shortName then
			text = string.gsub(text, longName, "[" .. chatNum .. shortName .. "]")
		end
	end
	dbg("applyShortChannelNames: result=" .. text)
	return text
end

local PLAYERLIST_MAX = 500

local function plainTextReplace(text, old, new)
	if type(text) ~= "string" or type(old) ~= "string" or old == "" then
		return text, false
	end
	local b, e = string.find(text, old, 1, true)
	if b == nil then
		return text, false
	end
	return string.sub(text, 1, b - 1) .. new .. string.sub(text, e + 1), true
end

local function replaceText(source, findStr, replaceStr, wholeWord)
	if type(source) ~= "string" then return source end
	if wholeWord then
		findStr = "%f[^%z%s]" .. findStr .. "%f[%z%s]"
	end
	return (source:gsub(findStr, replaceStr))
end

local function stripAndLowercase(text)
	if not text then return "" end
	text = string.lower(text)
	text = string.gsub(text, "%s+", "")
	return text
end

local function stripNameKey(text)
	if not text then return "" end
	text = string.lower(text)
	text = string.gsub(text, "[^%a%d]", "")
	return text
end

local function slowPlayerLinkStrip(msg)
	if type(msg) ~= "string" then return end
	local findStart, findEnd = string.find(msg, "|Hplayer:", 1, true)
	if not findStart then return end

	local newMsg = string.sub(msg, findEnd + 1)
	local p2Start, p2End = string.find(newMsg, "|h[", 1, true)
	if not p2Start then return end
	local playerLink = string.sub(newMsg, 1, p2Start - 1)

	newMsg = string.sub(newMsg, p2End + 1)
	local p3Start = string.find(newMsg, "]|h", 1, true)
	if not p3Start then return end
	local player = string.sub(newMsg, 1, p3Start - 1)

	if playerLink and player then
		return playerLink, player
	end
end

local function rotatePlayerListEntry(key, name, lowerName, cleanName, entry)
	if not key or not entry then return end

	local ring = addon.playerListRing
	local pos = (addon.playerListRingPos or 0) + 1
	if pos > PLAYERLIST_MAX then pos = 1 end
	addon.playerListRingPos = pos

	local old = ring[pos]
	if old then
		local current = addon.playerList and addon.playerList[old.key]
		if current and current._sig == old.sig and not current._pinned then
			addon.playerList[old.key] = nil
			local byName = addon.playerListByName
			if byName then
				if old.name and byName[old.name] == current then byName[old.name] = nil end
				if old.lowerName and byName[old.lowerName] == current then byName[old.lowerName] = nil end
				if old.cleanName and byName[old.cleanName] == current then byName[old.cleanName] = nil end
			end
		end
	end

	addon.playerListSig = (addon.playerListSig or 0) + 1
	entry._sig = addon.playerListSig
	ring[pos] = { key = key, sig = entry._sig, name = name, lowerName = lowerName, cleanName = cleanName }
end

local function getPlayerInfoByName(name)
	if not name or not addon.playerList then return nil end
	local byName = addon.playerListByName
	if byName then
		local info = byName[name] or byName[string.lower(name)]
		if info and info.name then
			return info
		end
	end

	local nameLower = string.lower(name)
	for _, v in pairs(addon.playerList) do
		if v and v.name and string.lower(v.name) == nameLower then
			return v
		end
	end
	return nil
end

local function parsePlayerInfo(_, text)
	dbg("parsePlayerInfo: parsing player info from text")
	text = text or ""
	local playerLink, player = string.match(text, "|Hplayer:(.-)|h%[(.-)%]|h(.+)")
	if not playerLink or not player then
		playerLink, player = slowPlayerLinkStrip(text)
	end
	if not playerLink or not player then
		return
	end

	local linkName = string.match(playerLink, "([^:]+)")
	if not linkName then return end
	local playerName, playerServer = string.match(linkName, "([^%-]+)%-?(.*)")
	if not playerName then return end
	if not playerServer or playerServer == "" then
		playerServer = GetRealmName()
	end

	local playerInfo = getPlayerInfoByName(playerName)
	if not playerInfo then
		dbg("parsePlayerInfo: player info not found for " .. playerName)
		return
	end

	local playerLevel = playerInfo.level or 0
	local decoratedLevel = playerLevel

	if playerLevel and playerLevel > 0 then
		local colorFunc = _G.GetQuestDifficultyColor or _G.GetDifficultyColor
		local color = colorFunc and colorFunc(playerLevel)
		if color then
			local levelCode = RGBAToHex(color.r, color.g, color.b, 1)
			decoratedLevel = "|c" .. levelCode .. playerLevel .. "|r"
			dbg("parsePlayerInfo: adding level " .. playerLevel .. " to " .. playerName)
		end
	end

	return "|Hplayer:" .. playerLink .. "|h[" .. player .. "]|h", "|Hplayer:" .. playerLink .. "|h[" .. decoratedLevel .. ":" .. player .. "]|h"
end

local function addToPlayerList(name, realm, level, class, bnName, pin)
	if not name or not level or not class or level <= 0 then
		return
	end

	addon.chkClassList = addon.chkClassList or {}
	if next(addon.chkClassList) == nil and _G.GetNumClasses and _G.GetClassInfo then
		for i = 1, _G.GetNumClasses() do
			local className, classFile = _G.GetClassInfo(i)
			if className and classFile then
				addon.chkClassList[className] = classFile
			end
		end
	end

	local playerName, playerServer = string.match(name, "([^%-]+)%-?(.*)")
	if playerName and playerName ~= "" then
		name = playerName
	end
	if playerServer and playerServer ~= "" then
		realm = playerServer
	end
	if not realm or realm == "" then
		realm = GetRealmName()
	end
	if not name or not realm then
		return
	end

	if addon.chkClassList[class] then
		class = addon.chkClassList[class]
	end

	local realmKey = stripAndLowercase(realm)
	local lowerName = string.lower(name)
	local cleanName = stripNameKey(name)
	local key = name .. "@" .. realmKey
	local entry = addon.playerList[key]
	local isNew = false
	if entry then
		entry.name = name
		entry.realm = realm
		entry.stripRealm = realmKey
		entry.level = level
		entry.class = class
		entry.BNname = bnName
	else
		entry = {
			name = name,
			realm = realm,
			stripRealm = realmKey,
			level = level,
			class = class,
			BNname = bnName,
		}
		addon.playerList[key] = entry
		isNew = true
	end
	if pin then
		entry._pinned = true
	end

	addon.playerListByName[name] = entry
	addon.playerListByName[lowerName] = entry
	if cleanName ~= "" then
		addon.playerListByName[cleanName] = entry
	end

	if (isNew or not entry._sig) and not entry._pinned then
		rotatePlayerListEntry(key, name, lowerName, cleanName, entry)
	end
end

local function initUpdateCurrentPlayer()
	local class = select(2, UnitClass("player"))
	local name, realm = UnitName("player")
	local level = UnitLevel("player")
	addToPlayerList(name, realm, level, class, nil, true)
end

local function doRosterUpdate()
	local inRaid = IsInRaid()
	local inGroup = inRaid or IsInGroup()
	if not inGroup then return end

	local playerNum = inRaid and GetNumGroupMembers() or MAX_PARTY_MEMBERS
	local unit = inRaid and "raid" or "party"
	for i = 1, playerNum do
		if UnitExists(unit .. i) then
			local playerName, playerServer = UnitName(unit .. i)
			local _, class = UnitClass(unit .. i)
			local level = UnitLevel(unit .. i)
			addToPlayerList(playerName, playerServer, level, class)
		end
	end
end

local function doFriendUpdate()
	local realmName = GetRealmName()
	if C_FriendList and C_FriendList.GetNumFriends then
		for i = 1, C_FriendList.GetNumFriends() or 0 do
			local info = C_FriendList.GetFriendInfoByIndex(i)
			if info and info.connected then
				addToPlayerList(info.name, realmName, info.level, info.className, nil, true)
			end
		end
	end

	if C_BattleNet and BNGetNumFriends and C_BattleNet.GetFriendAccountInfo then
		for i = 1, BNGetNumFriends() do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo and accountInfo.gameAccountInfo then
				local friendInfo = accountInfo.gameAccountInfo
				if friendInfo and friendInfo.isOnline and friendInfo.clientProgram == BNET_CLIENT_WOW then
					local accountName = accountInfo.isBattleTagFriend and accountInfo.battleTag or accountInfo.accountName
					if friendInfo.characterName and friendInfo.realmName and friendInfo.characterLevel and friendInfo.className then
						addToPlayerList(friendInfo.characterName, friendInfo.realmName, friendInfo.characterLevel, friendInfo.className, accountName, true)
					end
				end
			end
		end
	end
end

local function doGuildUpdate()
	if not IsInGuild() then return end
	if C_GuildInfo and C_GuildInfo.GuildRoster then
		C_GuildInfo.GuildRoster()
	elseif GuildRoster then
		GuildRoster()
	end

	local numMembers = GetNumGuildMembers and GetNumGuildMembers(true) or 0
	for i = 1, numMembers do
		local name, _, _, level, _, _, _, _, online, _, class = GetGuildRosterInfo(i)
		if online and name then
			local playerName, playerServer = string.match(name, "([^%-]+)%-?(.*)")
			if playerName and playerServer and playerServer ~= "" then
				addToPlayerList(playerName, playerServer, level, class, nil, true)
			else
				addToPlayerList(name, GetRealmName(), level, class, nil, true)
			end
		end
	end
end

local function initPlayerInfo()
	if not (XCHT_DB and XCHT_DB.enablePlayerChatStyle) then
		return
	end

	local throttlePending = {}
	local function throttle(key, delay, fn)
		if throttlePending[key] then return end
		throttlePending[key] = true
		if C_Timer and C_Timer.After then
			C_Timer.After(delay, function()
				throttlePending[key] = nil
				fn()
			end)
		else
			throttlePending[key] = nil
			fn()
		end
	end

	local function safeRegister(event, handler)
		if addon.RegisterEvent then
			addon:RegisterEvent(event, handler)
		end
	end

	safeRegister("GUILD_ROSTER_UPDATE", function() throttle("guild", 0.5, doGuildUpdate) end)
	safeRegister("PLAYER_GUILD_UPDATE", function() throttle("guild", 0.5, doGuildUpdate) end)
	safeRegister("FRIENDLIST_UPDATE", function() throttle("friends", 0.5, doFriendUpdate) end)
	safeRegister("BN_CONNECTED", function() throttle("friends", 0.5, doFriendUpdate) end)
	safeRegister("BN_DISCONNECTED", function() throttle("friends", 0.5, doFriendUpdate) end)
	safeRegister("BN_FRIEND_ACCOUNT_ONLINE", function() throttle("friends", 0.5, doFriendUpdate) end)
	safeRegister("BN_FRIEND_ACCOUNT_OFFLINE", function() throttle("friends", 0.5, doFriendUpdate) end)
	safeRegister("RAID_ROSTER_UPDATE", function() throttle("roster", 0.3, doRosterUpdate) end)
	safeRegister("GROUP_ROSTER_UPDATE", function() throttle("roster", 0.3, doRosterUpdate) end)
	safeRegister("PLAYER_ENTERING_WORLD", function() throttle("roster", 0.3, doRosterUpdate) end)
	safeRegister("UPDATE_INSTANCE_INFO", function() throttle("roster", 0.3, doRosterUpdate) end)
	safeRegister("ZONE_CHANGED_NEW_AREA", function() throttle("roster", 0.3, doRosterUpdate) end)
	safeRegister("UNIT_NAME_UPDATE", function() throttle("roster", 0.3, doRosterUpdate) end)
	safeRegister("UNIT_PORTRAIT_UPDATE", function() throttle("roster", 0.3, doRosterUpdate) end)
	safeRegister("PLAYER_LEVEL_UP", initUpdateCurrentPlayer)
end

applyPlayerChatStyle = function(frame, event, text)
	if not (addon.isFilterListEnabled and XCHT_DB and XCHT_DB.enablePlayerChatStyle) then
		return text
	end
	if type(text) ~= "string" then
		return text
	end

	dbg("applyPlayerChatStyle: processing text for event=" .. tostring(event))

	local hasPlayerLink = string.find(text, "|Hplayer:", 1, true) ~= nil
	local hasBNPlayerLink = string.find(text, "|HBNplayer:", 1, true) ~= nil

	if hasPlayerLink then
		dbg("applyPlayerChatStyle: found player link, applying stylization")
		local old, new = parsePlayerInfo(frame, text)
		if old and new then
			-- Check if old exists in text before replacing
			if string.find(text, old, 1, true) then
				text = plainTextReplace(text, old, new)
			else
				-- Try partial match if exact match fails
				dbg("applyPlayerChatStyle: exact match failed, trying partial")
				local playerLink, player = string.match(text, "|Hplayer:(.-)|h%[(.-)%]|h")
				if playerLink and player then
					local newPattern = "|Hplayer:" .. playerLink .. "|h"
					local startPos, endPos = string.find(text, newPattern, 1, true)
					if startPos and endPos then
						local before = string.sub(text, 1, startPos - 1)
						local after = string.sub(text, endPos)
						text = before .. new .. after
					end
				end
			end
		end
	end

	return text
end

shouldSuppressJoinLeaveMessage = function(event, text)
	if not (XCHT_DB and XCHT_DB.disableChatEnterLeaveNotice) then
		return false
	end

	dbg("shouldSuppressJoinLeaveMessage: checking event=" .. tostring(event))

	if event == "CHAT_MSG_CHANNEL_NOTICE" or event == "CHAT_MSG_CHANNEL_JOIN" or event == "CHAT_MSG_CHANNEL_LEAVE" then
		dbg("shouldSuppressJoinLeaveMessage: suppressing channel notice event")
		return true
	end

	if event == "CHAT_MSG_SYSTEM" and type(text) == "string" then
		if string.find(text, "|Hplayer:", 1, true) and (string.find(text, "has joined", 1, true) or string.find(text, "has left", 1, true)) then
			dbg("shouldSuppressJoinLeaveMessage: suppressing system join/leave message")
			return true
		end
	end

	return false
end

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
		r, g, b = HexToRGBA(XCHT_DB.outWhisperColor)
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

local function checkNoticeFilter(_, _, _, _, ...)
	if XCHT_DB and XCHT_DB.disableChatEnterLeaveNotice then
		return true
	end
	return false
end

function addon:setDisableChatEnterLeaveNotice()
	if addon._noticeFilterRegistered then return end
	if ChatFrame_AddMessageEventFilter then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", checkNoticeFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_JOIN", checkNoticeFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_LEAVE", checkNoticeFilter)
	end
	addon._noticeFilterRegistered = true
end

local function rebuildHookedFrames()
	addon.Frames = {}
	addon.HookedFrames = {}
	if CHAT_FRAMES and #CHAT_FRAMES > 0 then
		for i = 1, #CHAT_FRAMES do
			local frameName = CHAT_FRAMES[i]
			local frame = _G[frameName]
			if frame then
				addon.Frames[frameName] = frame
				if not IsCombatLog or not IsCombatLog(frame) then
					addon.HookedFrames[frameName] = frame
				end
			end
		end
	end
end

-- ============================================================================
-- COPY FRAME FEATURE
-- ============================================================================

--this will remove UI escaped textures from strings.  It causes an issue with highlighted text as it offsets it little by little
--https://wowwiki.fandom.com/wiki/UI_escape_sequences#Textures
--https://wow.gamepedia.com/UI_escape_sequences
local function unescape(str)

	--this is for testing for protected strings and only for officer chat, since even the text in officer chat is protected not just the officer name
	local isOfficerChat = false
	if strfind(str, "|Hchannel:officer", 1, true) then
		isOfficerChat = true
	end
	--str = gsub(str, "|c%x%x%x%x%x%x%x%x", "") --color tag 1
	--str = gsub(str, "|r", "") --color tag 2

    str = gsub(str, "|T.-|t", "") --textures in chat like currency coins and such
	str = gsub(str, "|H.-|h(.-)|h", "%1") --links, just put the item description and chat color
	str = gsub(str, "{.-}", "") --remove raid icons from chat

	--so apparently blizzard protects certain strings and returns them as textures.
	--this causes the insert for the multiline to break and not display the line.
	--such is the case for protected BNET Friends names and in some rare occasions names in the chat in general.
	--These protected strings start with |K and end with |k.   Example: |K[gsf][0-9]+|k[0]+|k
	--look under the link above for escape sequences

	--I want to point out that event addons like ElvUI suffer from  this problem.
	--They get around it by not displaying protected messages at ALL.  Check MessageIsProtected(message) in ElvUI

	if strfind(str, "|K", 1, true) then

		--str = gsub(str, "|K(.-)|k", "%1")
		local presenceID = strmatch(str, "|K(.-)|k")
		local accountName
		local stripBNet

		if presenceID and C_BattleNet and BNGetNumFriends and C_BattleNet.GetFriendAccountInfo then
			local numBNet = BNGetNumFriends()
			for i = 1, numBNet do
				local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
				--only continue if we have a account info to work with
				if accountInfo and accountInfo.gameAccountInfo then
					--grab the bnet name of the account, it will have |K|k in it so again it will be hidden
					accountName = accountInfo.accountName
					--do we even have a battle.net tag to replace it with?
					if accountName and accountInfo.battleTag then
						--grab the presenceID from in between the |K|k tags
						accountName = gsub(accountName, "|K(.-)|k", "%1")
						--if it matches the one we found earlier, then replace it with a battle.net tag instead
						if accountName and accountName == presenceID then
							--don't show entire bnet tag just the name
							stripBNet = strmatch(accountInfo.battleTag, "(.-)#")
							str = gsub(str, "|K(.-)|k", stripBNet or accountInfo.battleTag)
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
		str = gsub(str, "|K(.-)|k", "%1")

		--add extra text for protected strings, to let folks know it's protected
		if isOfficerChat then
			str = str..addon.L.ProtectedChannel
		end
	end

    return str
end

-- Create the copy frame UI
local function createCopyFrame()
	--check to see if we have the frame already, if we do then return it
	if addon.copyFrame then return addon.copyFrame end

	local copyFrame = CreateFrame("FRAME", ADDON_NAME.."CopyFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
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
	copyFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	copyFrame:SetWidth(830)
	copyFrame:SetHeight(490)

	local title = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", copyFrame, "TOPLEFT", 20, -12)
	title:SetText(addon.L.CopyChat)

	local scrollFrame = CreateFrame("ScrollFrame", ADDON_NAME.."CopyScrollFrame", copyFrame, "ScrollingEditBoxTemplate")
	scrollFrame:SetPoint("TOPLEFT", 20, -38)
	scrollFrame:SetPoint("BOTTOMRIGHT", -35, 45)
	scrollFrame:EnableMouseWheel(true)
	if scrollFrame.SetPropagateMouseWheel then
		scrollFrame:SetPropagateMouseWheel(true)
	end

	local editBox = scrollFrame.EditBox or _G[scrollFrame:GetName().."EditBox"]
	if not editBox then
		editBox = CreateFrame("EditBox", ADDON_NAME.."CopyEditBox", scrollFrame)
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
		Mixin(editBox, BackdropTemplateMixin)
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
		scrollBar = CreateFrame("Slider", ADDON_NAME.."CopyScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
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

	copyFrame.handleCursorChange = false --setting this to true will update the scrollbar to the cursor position
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

	local close = CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
	close:SetScript("OnClick", function() copyFrame:Hide() end)
	close:SetPoint("BOTTOMRIGHT", -27, 13)
	close:SetFrameLevel(close:GetFrameLevel() + 1)
	close:SetHeight(20)
	close:SetWidth(100)
	close:SetText(addon.L.Done)

    local buttonBack = CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
    buttonBack:SetText("<")
    buttonBack:SetHeight(25)
    buttonBack:SetWidth(25)
    buttonBack:SetPoint("BOTTOMLEFT", 10, 13)
	buttonBack:SetFrameLevel(buttonBack:GetFrameLevel() + 1)
    buttonBack:SetScript("OnClick", function()
		if copyFrame.currChatIndex and copyFrame.currentPage then
			if (copyFrame.currentPage - 1) > 0 then
				getChatText(copyFrame, copyFrame.currChatIndex, copyFrame.currentPage - 1)
			end
		end
    end)
    copyFrame.buttonBack = buttonBack

    local buttonForward = CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
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

	--this is to place it above the group layer
    local pageNumText = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageNumText:SetPoint("BOTTOMLEFT", 80, 18)
    pageNumText:SetShadowOffset(1, -1)
    pageNumText:SetText(addon.L.Page.." 1")
    copyFrame.pageNumText = pageNumText

	copyFrame:Hide()

	--store it for the future
	addon.copyFrame = copyFrame

	return copyFrame
end

-- Extract chat text from a chat frame into the copy frame
local function getChatText(copyFrame, chatIndex, pageNum)

	copyFrame.MLEditBox:SetText("") --clear it first in case there were previous messages
	copyFrame.currChatIndex = chatIndex

	local chatFrame = _G["ChatFrame"..chatIndex]
	if not chatFrame then return end

	--the editbox of the multiline editbox (The parent of the multiline object)
	local parentEditBox = copyFrame.MLEditBox.editBox

	--there is a hard limit of text that can be highlighted in an editbox to 500 lines.
	local MAXLINES = 150 --150 don't use large numbers or it will cause LAG when frame opens.  EditBox was not made for large amounts of text
	local msgCount = chatFrame:GetNumMessages()
	local startPos = 0
	local endPos = 0
	local lineText

	--lets create the pages
	local pages = {}
	local pageCount = 0 --start at zero
	for i = 1, msgCount, MAXLINES do
	  pageCount = i-1 --the block will extend by 1 past 150, so subtract 1
	  if pageCount <= 0 then pageCount = 1 end --this is the first page, so start at 1
	  pages[#pages + 1] = pageCount
	end

	--check for custom buffer limit by the user, ignore if it's set to zero
	if XCHT_DB.pageBufferLimit > 0 and #pages > XCHT_DB.pageBufferLimit then
		local counter = 0
		local tmpPages = {}
		for i = #pages, 1, -1 do
			counter = counter + 1
			if counter <= XCHT_DB.pageBufferLimit then
				tmpPages[#tmpPages + 1] = pages[i]
			else
				break
			end
		end
		pages = tmpPages
	end

	--load past page if we don't have a pageNum
	if not pageNum and startPos < 1 then
		if msgCount > MAXLINES then
			startPos = msgCount - MAXLINES
			endPos = startPos + MAXLINES
		else
			startPos = 1
			endPos = msgCount
		end
	--otherwise load the page number
	elseif pageNum and pages[pageNum] then
		if pages[pageNum] == 1 then
			--first page
			startPos = 1
			endPos = MAXLINES
		else
			startPos = pages[pageNum]
			endPos = pages[pageNum] + MAXLINES
		end
	else
		print("XanChat: "..addon.L.CopyChatError)
		return
	end

	--adjust the endPos if it's greater than the total messages we have
	if endPos > msgCount then endPos = msgCount end

	for i = startPos, endPos do
		local chatMsg, r, g, b, chatTypeID = chatFrame:GetMessageInfo(i)
		if not chatMsg then break end

		--fix situations where links end the color prematurely
		if (r and g and b and chatTypeID) then
			local colorCode = RGBAToHex(r, g, b, 1)
			chatMsg = string.gsub(chatMsg, "|r", "|r"..colorCode)
			chatMsg = colorCode..chatMsg
		end

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
	copyFrame.pageNumText:SetText(addon.L.Page.." "..copyFrame.currentPage)

	copyFrame.handleCursorChange = true -- just in case
	copyFrame:Show()
end

local function createCopyChatButton(chatIndex, chatFrame)
	if not XCHT_DB.enableCopyButton then return end

	local copyFrame = createCopyFrame()

	local obj = CreateFrame("Button", "xanCopyChatButton"..chatIndex, chatFrame, BackdropTemplateMixin and "BackdropTemplate")
	obj:SetParent(chatFrame)
	obj:SetNormalTexture("Interface\\AddOns\\xanChat\\media\\copy")
	obj:SetHighlightTexture("Interface\\AddOns\\xanChat\\media\\copyhighlight")
	obj:SetPushedTexture("Interface\\AddOns\\xanChat\\media\\copy")
	obj:SetFrameLevel(7)
	obj:SetWidth(18)
	obj:SetHeight(18)
	obj:Hide()
	obj:SetScript("OnClick", function(self)
		getChatText(copyFrame, chatIndex)
	end)

	if not XCHT_DB.enableCopyButtonLeft then

		obj:SetPoint("BOTTOMRIGHT", -2, -3)

		chatFrame:HookScript("OnEnter", function(self)
			obj:Show()
		end)
		chatFrame:HookScript("OnLeave", function(self)
			obj:Hide()
		end)
		if chatFrame.ScrollToBottomButton then
			chatFrame.ScrollToBottomButton:HookScript("OnEnter", function(self)
				obj:Show()
			end)
			chatFrame.ScrollToBottomButton:HookScript("OnLeave", function(self)
				obj:Hide()
			end)
		end

		--prevent object blinking because chat continues to scroll
		function obj.show()
			obj:Show()
		end
		function obj.hide()
			obj:Hide()
		end

		obj:SetScript("OnEnter", obj.show)
		obj:SetScript("OnLeave", obj.hide)

	else
		local leftButtonFrame = "ChatFrame"..chatIndex.."ButtonFrame"

		local offSetY = -50
		if not addon.IsRetail and not XCHT_DB.hideScroll then
			--we have to move this as it will be on the scrollbars on classic
			offSetY = 60
		end

		if _G[leftButtonFrame] then
			obj:SetPoint("TOPLEFT", _G[leftButtonFrame], "TOPLEFT", 5, offSetY)
		else
			obj:SetPoint("TOPLEFT", chatFrame, "TOPLEFT", -30, offSetY)
		end
		obj:Show()
	end

end

-- Setup copy frame feature for all chat frames
function addon:setupCopyFrameFeature()
	if not XCHT_DB.enableCopyButton then return end
	if NUM_CHAT_WINDOWS then
		for i = 1, NUM_CHAT_WINDOWS do
			local frameName = ("ChatFrame%d"):format(i)
			local frame = _G[frameName]
			if frame then
				createCopyChatButton(i, frame)
			end
		end
	end
	end
local function isInAnyInstance()
	if not IsInInstance then return false end
	return select(1, IsInInstance())
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
-- INITIALIZATION
-- ============================================================================

-- Table to track processed frames
local processedFrames = {}

-- ============================================================================
-- SETUP CHAT FRAME
-- ============================================================================

function addon:SetupChatFrame(chatID)
	if not chatID then return end

	local n = "ChatFrame" .. chatID
	local f = _G[n]
	local fTab = _G[n .. "Tab"]
	local editBox = _G[n .. "EditBox"]

	if f and not processedFrames[n] then
		-- Ensure new frames respect chat history size
		if f.SetMaxLines then
			local minLines = 2000
			if C_CVar and C_CVar.GetCVar then
				local cvar = tonumber(C_CVar.GetCVar("chatMaxLines"))
				if cvar and cvar > minLines then
					minLines = cvar
				end
			end
			f:SetMaxLines(minLines)
		end

		-- Set alpha levels - NOTE: These are important, do not remove
		if XCHT_DB.disableChatFrameFade and CHAT_FRAME_TEXTURES then
			local alpha = XCHT_DB.userChatAlpha or DEFAULT_CHATFRAME_ALPHA or 0.25
			for i = 1, #CHAT_FRAME_TEXTURES do
				local object = _G[n .. CHAT_FRAME_TEXTURES[i]]
				if object then
					object:SetAlpha(alpha)
				end
			end
		elseif CHAT_FRAME_TEXTURES then
			for i = 1, #CHAT_FRAME_TEXTURES do
				local object = _G[n .. CHAT_FRAME_TEXTURES[i]]
				if object then
					object:SetAlpha(0)
				end
			end
		end

		-- Enable/disable chat text fading (different from frame fade)
		if XCHT_DB.enableChatTextFade then
			f:SetFading(true)
			f:SetTimeVisible(120)
		else
			f:SetFading(false)
		end

		-- Always lock the frames regardless
		SetChatWindowLocked(chatID, true)
		FCF_SetLocked(f, true)

		-- Add font outlines or shadows
		if XCHT_DB.addFontOutline or XCHT_DB.addFontShadow then
			local font, size = f:GetFont()
			if font then
				f:SetFont(font, size, "THINOUTLINE")
				-- Only apply this if we don't have shadows enabled
				if not XCHT_DB.addFontShadow then
					f:SetShadowColor(0, 0, 0, 0)
				end
			end
		end

		-- Few changes
		f:EnableMouseWheel(true)
		if self.scrollChat then
			f:SetScript('OnMouseWheel', self.scrollChat)
		end
		f:SetClampRectInsets(0, 0, 0, 0)

		-- EditBox setup
		if editBox then
			-- Remove alt keypress from EditBox (no longer need alt to move around)
			editBox:SetAltArrowKeyMode(false)

			-- Check for editbox history
			local name = editBox:GetName()
			if HistoryDB and HistoryDB[name] then
				editBox.historyLines = HistoryDB[name]
				editBox.historyIndex = 0

				editBox:HookScript("OnShow", function(self)
					self.historyIndex = 0
				end)

				local count = #HistoryDB[name]
				if count > 0 then
					for dX = count, 1, -1 do
						if HistoryDB[name][dX] then
							editBox:AddHistoryLine(HistoryDB[name][dX])
						else
							break
						end
					end
				end

				if self.AddEditBoxHistoryLine then
					editBox:HookScript("OnEditFocusGained", self.AddEditBoxHistoryLine)
				end
				if self.ClearEditBoxHistory then
					editBox:HookScript("OnEditFocusLost", self.ClearEditBoxHistory)
				end
			end

			-- EditBox design changes
			if not editBox.left then
				editBox.left = _G[n .. "EditBoxLeft"]
				editBox.right = _G[n .. "EditBoxRight"]
				editBox.mid = _G[n .. "EditBoxMid"]
			end

			local editBoxBackdrop
			if XCHT_DB.enableSEBDesign then
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

			if XCHT_DB.enableSimpleEditbox then
				editBox.left:SetAlpha(0)
				editBox.right:SetAlpha(0)
				editBox.mid:SetAlpha(0)

				if not editBox.SetBackdrop and Mixin and BackdropTemplateMixin then
					Mixin(editBox, BackdropTemplateMixin)
				end

				if editBox.focusLeft then editBox.focusLeft:SetTexture(nil) end
				if editBox.focusRight then editBox.focusRight:SetTexture(nil) end
				if editBox.focusMid then editBox.focusMid:SetTexture(nil) end

				editBox:SetBackdrop(editBoxBackdrop)
				editBox:SetBackdropColor(0, 0, 0, 0.6)
				editBox:SetBackdropBorderColor(0.6, 0.6, 0.6)

			elseif not XCHT_DB.hideEditboxBorder then
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

			if XCHT_DB.editBoxTop then
				if XCHT_DB.enableEditboxAdjusted then
					spaceAdjusted = 6
				end
				editBox:ClearAllPoints()
				editBox:SetPoint("BOTTOMLEFT", f, "TOPLEFT", -5, spaceAdjusted)
				editBox:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 5, spaceAdjusted)
			else
				if XCHT_DB.enableEditboxAdjusted then
					spaceAdjusted = -9
				end
				editBox:ClearAllPoints()
				editBox:SetPoint("TOPLEFT", f, "BOTTOMLEFT", -5, spaceAdjusted)
				editBox:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 5, spaceAdjusted)
			end

			-- When editbox is on the top, complications occur because sometimes you are not allowed to click on tabs
			-- To fix this we'll just make the tab close editbox
			-- Also force the editbox to hide itself when it loses focus
			if fTab then
				fTab:HookScript("OnClick", function() editBox:Hide() end)
			end
			editBox:HookScript("OnEditFocusLost", function() editBox:Hide() end)
		end

		-- Hide scroll bars
		if XCHT_DB.hideScroll then
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

		if XCHT_DB.hideSideButtonBars then
			if f.buttonFrame then
				f.buttonFrame:Hide()
				f.buttonFrame:SetScript("OnShow", function() end)
			end
		end

		-- Force chat hide tabs on load
		if XCHT_DB.hideTabs and fTab then
			fTab.mouseOverAlpha = CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA or 0.5
			fTab.noMouseAlpha = CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA or 0.25
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

function addon:OnLoad()
	dbg("OnLoad: START xanChat initialization")
	initCallbacks()
	initializeDatabase()
	rebuildHookedFrames()
	ensureCaptureProxyFrame()
	registerUrlPatterns()
	installUrlCopyHook()
	self:setDisableChatEnterLeaveNotice()
	self:setOutWhisperColor()

	if self.EnableFilterList then
		self:EnableFilterList()
	end
	if self.EnableStickyChannelsList then
		self:EnableStickyChannelsList()
	end

	initPlayerInfo()
	initUpdateCurrentPlayer()
	doRosterUpdate()
	doFriendUpdate()
	doGuildUpdate()

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
			self:SetupChatFrame(i)
		end
	end

	-- Hook FCF_OpenTemporaryWindow for temporary whisper windows
	if FCF_OpenTemporaryWindow then
		local old_OpenTemporaryWindow = FCF_OpenTemporaryWindow
		FCF_OpenTemporaryWindow = function(...)
			local frame = old_OpenTemporaryWindow(...)
			if frame and frame.GetID then
				self:SetupChatFrame(frame:GetID())
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
		local cmd = msg and string.lower(string.match(msg, "^%s*(%S+)")) or ""
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
		if isInAnyInstance() and XCHT_DB.lockChatSettings then
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

	dbg("OnLoad: COMPLETE xanChat initialization")
end

-- ============================================================================
-- UI_SCALE_CHANGED EVENT HANDLER
-- ============================================================================

function addon:UI_SCALE_CHANGED()
	if XCHT_DB and XCHT_DB.lockChatSettings and isInAnyInstance() then return end
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

function addon:OnEnable()
	dbg("OnEnable: installing message hooks")
	rebuildHookedFrames()
	registerUrlPatterns()
	self:EnableAddon()
end

function addon:OnDisable()
	dbg("OnDisable: removing hooks and cleaning up")
	if callbacks and callbacks.UnregisterAll then
		callbacks:UnregisterAll()
	end
	self:DisableAddon()
	unregisterUrlPatterns()
end

-- ============================================================================
-- HOOK INSTALLATION
-- ============================================================================

function addon:EnableAddon()
	if self._addonEnabled then
		dbg("EnableAddon: already enabled")
		return
	end

	dbg("EnableAddon: START installing message hooks")

	-- Initialize hook storage for RawHook system
	self._hooks = self._hooks or {}
	self._rawHooks = self._rawHooks or {}

	-- Create DummyFrame for proxy capture
	ensureCaptureProxyFrame()

	-- Hook ChatFrame_MessageEventHandler using RawHook (stores original, unsafe)
	if _G["ChatFrame_MessageEventHandler"] then
		local uid = addon:RawHook(_G, "ChatFrame_MessageEventHandler", function(frame, event, ...)
			return addon:ChatFrame_MessageEventHandler(frame, event, ...)
		end)
		self._rawHooks["ChatFrame_MessageEventHandler"] = uid
		self._chatEventHooked = "global"
		dbg("EnableAddon: global ChatFrame_MessageEventHandler RawHooked")
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
		dbg("EnableAddon: hooked " .. hookCount .. " frame MessageEventHandlers with direct assignment")
	else
		dbg("EnableAddon: ERROR - no message handler available")
	end

	-- Note: Proxy capture is handled by the manual AddMessage hook in ensureCaptureProxyFrame()
	-- which sets captureState.text, captureState.color, etc.

	self._addonEnabled = true
	dbg("EnableAddon: COMPLETE hooks installed")
end

function addon:DisableAddon()
	if not self._addonEnabled then
		dbg("DisableAddon: already disabled")
		return
	end

	dbg("DisableAddon: START removing message hooks")

	-- Unhook RawHooked ChatFrame_MessageEventHandler
	if self._chatEventHooked == "global" and self._rawHooks and self._rawHooks["ChatFrame_MessageEventHandler"] then
		addon:Unhook(_G, "ChatFrame_MessageEventHandler")
		self._rawHooks["ChatFrame_MessageEventHandler"] = nil
		dbg("DisableAddon: unhooked global ChatFrame_MessageEventHandler")
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
		dbg("DisableAddon: restored " .. restoreCount .. " frame MessageEventHandlers")
	end

	-- Unhook DummyFrame.AddMessage
	if self._rawHooks and self._rawHooks["DummyFrame"] then
		addon:Unhook(captureProxyFrame, "AddMessage")
		self._rawHooks["DummyFrame"] = nil
	end

	self._chatEventHooked = nil
	self._addonEnabled = false
	dbg("DisableAddon: COMPLETE hooks removed")
end
