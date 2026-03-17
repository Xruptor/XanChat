--[[
	EventHandling.lua - Core event handling for XanChat
	Refactored for:
	- Improved efficiency with consolidated nil checks
	- Removed redundant early returns
	- Simplified function flow
	- Better variable naming and clarity
	- Fixed unused variables
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- EVENT PROCESSING TYPES
-- ============================================================================

local EventProcessingType = {
	Full = 1,          -- Apply all processing: patterns + sections + formatting
	PatternsOnly = 2,   -- Apply only pattern matching on captured text
	OutputOnly = 3       -- Use only captured Blizzard output, no xanChat processing
}

local CHAT_MSG_PREFIX = "CHAT_MSG"

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function getEventSubtype(event)
	return event and string.sub(event, 1, 8) or ""
end

local function isChatMessageEvent(event)
	if type(event) ~= "string" then
		return false
	end
	return getEventSubtype(event) == CHAT_MSG_PREFIX
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

local function EventIsProcessed(event)
	-- Default to Full processing for all CHAT_MSG events
	if isChatMessageEvent(event) then
		return EventProcessingType.Full
	end
	return EventProcessingType.OutputOnly
end

local function callOriginalMessageHandler(self, frame, event, ...)
	if self._chatEventHooked == "global" then
		-- Use AceHook's stored original for global hook
		if self.hooks and self.hooks._G and self.hooks._G.ChatFrame_MessageEventHandler then
			return self.hooks._G.ChatFrame_MessageEventHandler(frame, event, ...)
		end
	elseif self._chatEventHooked == "frame" and frame then
		local frameName = frame.GetName and frame:GetName()
		if frameName and self._hooks[frameName] then
			-- Call the original function stored in self._hooks
			return self._hooks[frameName](frame, event, ...)
		end
	end
	return nil
end

local function callOriginalMessageHandlerSecure(self, frame, event, ...)
	local original

	if self._chatEventHooked == "global" then
		if self.hooks and self.hooks._G and self.hooks._G.ChatFrame_MessageEventHandler then
			original = self.hooks._G.ChatFrame_MessageEventHandler
		end
	elseif self._chatEventHooked == "frame" and frame then
		local frameName = frame.GetName and frame:GetName()
		if frameName and self._hooks[frameName] then
			original = self._hooks[frameName]
		end
	end

	if not original then
		return nil
	end

	-- Use securecall if available to properly handle protected functions
	local secureCall = _G.securecallfunction or _G.securecall
	return secureCall and secureCall(original, frame, event, ...) or original(frame, event, ...)
end

local function shouldRunPatternPass(isSecretPayload, mode)
	return not isSecretPayload and (mode == EventProcessingType.Full or mode == EventProcessingType.PatternsOnly)
end

local function runFrameMessageFilters(frame, event, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14)
	if not isChatMessageEvent(event) then
		return false, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14
	end

	if not (_G.ChatFrameUtil and _G.ChatFrameUtil.ProcessMessageEventFilters) then
		return false, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14
	end

	local discard = false
	discard, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14 =
		_G.ChatFrameUtil.ProcessMessageEventFilters(frame, event, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14)

	return discard, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.callOriginalMessageHandler = callOriginalMessageHandler
addon.callOriginalMessageHandlerSecure = callOriginalMessageHandlerSecure
addon.shouldRunPatternPass = shouldRunPatternPass
addon.runFrameMessageFilters = runFrameMessageFilters
addon.EventIsProcessed = EventIsProcessed
addon.EventProcessingType = EventProcessingType
