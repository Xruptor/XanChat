--[[
	AceHookIntegration.lua - AceHook integration and hook management for XanChat
	Improvements:
	- Consolidated proxy transfer state cleanup
	- Simplified frame field iteration
	- Better nil handling in CreateProxy
	- Improved resetCaptureState efficiency
	- Cleaner proxy frame setup
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
		if addon.IsHooked and not addon:IsHooked(captureProxyFrame, "AddMessage") then
			addon:RawHook(captureProxyFrame, "AddMessage", true)
			addon._rawHooks = addon._rawHooks or {}
			addon._rawHooks["DummyFrame"] = true
		end
		return captureProxyFrame
	end

	if addon.dbg then addon.dbg("Creating capture proxy frame") end

	captureProxyFrame = CreateFrame("ScrollingMessageFrame")
	if Mixin and ChatFrameMixin then
		Mixin(captureProxyFrame, ChatFrameMixin)
	end

	addon:RawHook(captureProxyFrame, "AddMessage", true)
	addon._rawHooks = addon._rawHooks or {}
	addon._rawHooks["DummyFrame"] = true
	addon.captureProxyFrame = captureProxyFrame

	return captureProxyFrame
end

local function clearProxyTransferState()
	for i = #proxyTransferState.touched, 1, -1 do
		local key = proxyTransferState.touched[i]
		proxyTransferState.snapshot[key] = nil
		proxyTransferState.touched[i] = nil
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

	if type(frame) ~= "table" then
		return proxy
	end

	-- Mirror all valid frame fields
	for key, value in pairs(frame) do
		if isMirrorableFrameField(key, value) then
			if proxyTransferState.snapshot[key] == nil then
				proxyTransferState.snapshot[key] = (proxy[key] == nil and MISSING_VALUE) or proxy[key]
				table.insert(proxyTransferState.touched, key)
			end
			proxy[key] = value
		end
	end

	-- Override IsShown to always return true
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
-- ADD MESSAGE HANDLER (for AceHook RawHook)
-- ============================================================================

addon.AddMessage = function(_, frame, text, r, g, b, id, ...)
	if captureState.proxy == frame and not captureState.text then
		captureState.text = text
		captureState.color.r = r
		captureState.color.g = g
		captureState.color.b = b
		captureState.color.id = id
		if addon.dbg then addon.dbg("capture proxy stored formatter output") end
		return
	end

	return addon.hooks[frame].AddMessage(frame, text, r, g, b, id, ...)
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

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
