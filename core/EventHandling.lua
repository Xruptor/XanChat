--[[
	EventHandling.lua - Core event handling for XanChat
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
	OutputOnly = 3       -- Use only the captured Blizzard output, no xanChat processing
}

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

local function EventIsProcessed(event)
	if not addon then return EventProcessingType.OutputOnly end

	-- Default to Full processing for all CHAT_MSG events
	if type(event) == "string" and string.sub(event, 1, 8) == "CHAT_MSG" then
		return EventProcessingType.Full
	end

	return EventProcessingType.OutputOnly
end

local function callOriginalMessageHandler(self, frame, event, ...)
	if not addon then return nil end

	if self._chatEventHooked == "global" then
		-- Use AceHook's stored original for global hook
		if self.hooks and self.hooks._G and self.hooks._G.ChatFrame_MessageEventHandler then
			return self.hooks._G.ChatFrame_MessageEventHandler(frame, event, ...)
		end
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
	if not addon then return false end

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

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.callOriginalMessageHandler = callOriginalMessageHandler
addon.shouldRunPatternPass = shouldRunPatternPass
addon.runFrameMessageFilters = runFrameMessageFilters
addon.EventIsProcessed = EventIsProcessed
addon.EventProcessingType = EventProcessingType

