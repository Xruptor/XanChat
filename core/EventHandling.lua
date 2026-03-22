--[[
	EventHandling.lua - Core event handling for XanChat
	Improvements:
	- Consolidated callOriginalMessageHandler with secure variant
	- Simplified shouldRunPatternPass logic
	- Improved runFrameMessageFilters efficiency
	- Better early returns throughout
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

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

local function EventIsProcessed(event)
	-- Default to Full processing for all CHAT_MSG events
	if event and string.sub(event, 1, 8) == "CHAT_MSG" then
		return EventProcessingType.Full
	end
	return EventProcessingType.OutputOnly
end

-- Unified original message handler caller with optional secure execution
local function callOriginalMessageHandler(self, frame, event, ...)
	local original
	local isGlobalHook = self._chatEventHooked == "global"

	if isGlobalHook then
		original = self.hooks and self.hooks._G and self.hooks._G.ChatFrame_MessageEventHandler
	elseif frame then
		local frameName = frame.GetName and frame:GetName()
		original = frameName and self._hooks and self._hooks[frameName]
	end

	if not original then
		return nil
	end

	-- Check if we need secure execution
	if self._useSecureCalls then
		local secureCall = _G.securecallfunction or _G.securecall
		return secureCall and secureCall(original, frame, event, ...) or original(frame, event, ...)
	end

	return original(frame, event, ...)
end

local function shouldRunPatternPass(isSecretPayload, mode)
	return not isSecretPayload and (mode == EventProcessingType.Full or mode == EventProcessingType.PatternsOnly)
end

local function runFrameMessageFilters(frame, event, ...)
	if string.sub(event or "", 1, 8) ~= "CHAT_MSG" then
		return false, ...
	end

	if not (_G.ChatFrameUtil and _G.ChatFrameUtil.ProcessMessageEventFilters) then
		return false, ...
	end

	return _G.ChatFrameUtil.ProcessMessageEventFilters(frame, event, ...)
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.callOriginalMessageHandler = callOriginalMessageHandler
addon.shouldRunPatternPass = shouldRunPatternPass
addon.runFrameMessageFilters = runFrameMessageFilters
addon.EventIsProcessed = EventIsProcessed
addon.EventProcessingType = EventProcessingType
