--[[
	AceHookIntegration.lua - AceHook integration and hook management for XanChat
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

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
	if not addon then return nil end

	if captureProxyFrame then
		return captureProxyFrame
	end

	if addon.dbg then addon.dbg("Creating capture proxy frame") end

	captureProxyFrame = CreateFrame("ScrollingMessageFrame")
	if Mixin and ChatFrameMixin then
		Mixin(captureProxyFrame, ChatFrameMixin)
	end

	-- Use RawHook for AddMessage capture
	-- hookSecure = true allows hooking secure functions on the proxy frame
	-- The handler is addon:AddMessage which captures the formatted output
	addon:RawHook(captureProxyFrame, "AddMessage", true)
	addon.captureProxyFrame = captureProxyFrame

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

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

-- Embed AceHook into addon for self.hooks support (needed for AddMessage handler)
AceHook:Embed(addon)

addon.ensureCaptureProxyFrame = ensureCaptureProxyFrame
addon.resetCaptureState = resetCaptureState
addon.captureProxyFrame = captureProxyFrame
addon.captureState = captureState
addon.proxyTransferState = proxyTransferState
addon.proxyCopySkipLookup = proxyCopySkipLookup
addon.isMirrorableFrameField = isMirrorableFrameField
addon.clearProxyTransferState = clearProxyTransferState

-- AddMessage handler (for AceHook RawHook)
addon.AddMessage = function(self, frame, text, r, g, b, id, ...)
	-- Capture text when called on the capture proxy frame
	if captureState.proxy == frame and captureState.text == nil then
		captureState.text = text
		captureState.color.r = r
		captureState.color.g = g
		captureState.color.b = b
		captureState.color.id = id
		if addon.dbg then addon.dbg("capture proxy stored formatter output") end
		return
	end
	-- Call original AddMessage for non-capture calls
	return self.hooks[frame].AddMessage(frame, text, r, g, b, id, ...)
end

-- Proxy management functions
addon.CreateProxy = function(self, frame)
	if addon.dbg then addon.dbg("CreateProxy: mirroring frame state to proxy") end

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

addon.RestoreProxy = function(self)
	if addon.dbg then addon.dbg("RestoreProxy: undoing mirrored proxy state") end

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
