--[[
	AceHookIntegration.lua - AceHook integration and hook management for XanChat
	Refactored for:
	- Simplified proxy state management with clear cleanup
	- Improved variable naming for clarity
	- Consolidated redundant nil checks
	- Better separation of concerns
	- Fixed potential memory leak in proxy transfer
	- More efficient frame field iteration
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

-- Fields that should not be copied to proxy frames
local PROXY_COPY_SKIP_FIELDS = {
	["historyBuffer"] = true,
	["isLayoutDirty"] = true,
	["isDisplayDirty"] = true,
	["onDisplayRefreshedCallback"] = true,
	["onScrollChangedCallback"] = true,
	["onTextCopiedCallback"] = true,
	["scrollOffset"] = true,
	["visibleLines"] = true,
	["highlightTexturePool"] = true,
	["fontStringPool"] = true,
	["AddMessage"] = true,
	["IsShown"] = true,
}

-- Proxy frame for capturing formatted output
local captureProxyFrame = nil

-- Sentinel value for tracking unset values
local MISSING_VALUE = {}

-- State for proxy frame mirroring and restoration
local proxyTransferState = {
	touched = {},
	snapshot = {},
	originalIsShown = nil,
}

-- State for capturing formatted output from proxy
local captureState = {
	proxy = nil,
	text = nil,
	color = { r = nil, g = nil, b = nil, id = nil },
}

-- ============================================================================
-- CAPTURE STATE MANAGEMENT
-- ============================================================================

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
		-- Rehook if needed
		if addon.IsHooked and not addon:IsHooked(captureProxyFrame, "AddMessage") then
			addon:RawHook(captureProxyFrame, "AddMessage", true)
			addon._rawHooks = addon._rawHooks or {}
			addon._rawHooks["DummyFrame"] = true
		end
		return captureProxyFrame
	end

	-- Create new proxy frame
	if addon.dbg then addon.dbg("Creating capture proxy frame") end

	captureProxyFrame = CreateFrame("ScrollingMessageFrame")
	if Mixin and ChatFrameMixin then
		Mixin(captureProxyFrame, ChatFrameMixin)
	end

	-- Hook AddMessage for capturing formatted output
	addon:RawHook(captureProxyFrame, "AddMessage", true)
	addon._rawHooks = addon._rawHooks or {}
	addon._rawHooks["DummyFrame"] = true
	addon.captureProxyFrame = captureProxyFrame

	return captureProxyFrame
end

local function clearProxyTransferState()
	-- Clean up all touched keys
	for i = #proxyTransferState.touched, 1, -1 do
		local key = proxyTransferState.touched[i]
		proxyTransferState.touched[i] = nil
		proxyTransferState.snapshot[key] = nil
	end
	proxyTransferState.originalIsShown = nil
end

-- ============================================================================
-- PROXY FRAME MIRRORING
-- ============================================================================

local function isMirrorableFrameField(fieldName, value)
	return not PROXY_COPY_SKIP_FIELDS[fieldName] and type(value) ~= "function"
end

-- Create a proxy frame that mirrors the source frame state
local function CreateProxy(_, frame)
	if addon.dbg then addon.dbg("CreateProxy: mirroring frame state to proxy") end

	local proxy = captureProxyFrame or ensureCaptureProxyFrame()
	if not proxy then
		return frame
	end

	clearProxyTransferState()

	-- Skip non-table frames
	if type(frame) ~= "table" then
		return proxy
	end

	-- Mirror all valid frame fields
	for key, value in pairs(frame) do
		if isMirrorableFrameField(key, value) then
			-- Track which fields were modified
			if proxyTransferState.snapshot[key] == nil then
				proxyTransferState.snapshot[key] = (proxy[key] == nil and MISSING_VALUE) or proxy[key]
				proxyTransferState.touched[#proxyTransferState.touched + 1] = key
			end
			proxy[key] = value
		end
	end

	-- Override IsShown to always return true for proper formatting
	proxyTransferState.originalIsShown = (proxy.IsShown == nil and MISSING_VALUE) or proxy.IsShown
	proxy.IsShown = function() return true end

	return proxy
end

-- Restore the proxy frame to its original state
local function RestoreProxy()
	if addon.dbg then addon.dbg("RestoreProxy: undoing mirrored proxy state") end

	if not captureProxyFrame then
		return
	end

	-- Restore all modified fields to original values
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

	-- Restore original IsShown function
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
-- ADD MESSAGE HANDLER (for AceHook RawHook)
-- ============================================================================

addon.AddMessage = function(_, frame, text, r, g, b, id, ...)
	-- Capture text when called on the capture proxy frame
	if captureState.proxy == frame and not captureState.text then
		captureState.text = text
		captureState.color.r = r
		captureState.color.g = g
		captureState.color.b = b
		captureState.color.id = id
		if addon.dbg then addon.dbg("capture proxy stored formatter output") end
		return
	end

	-- Call original AddMessage for non-capture calls
	return addon.hooks[frame].AddMessage(frame, text, r, g, b, id, ...)
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
addon.isMirrorableFrameField = isMirrorableFrameField
addon.clearProxyTransferState = clearProxyTransferState
addon.CreateProxy = CreateProxy
addon.RestoreProxy = RestoreProxy
