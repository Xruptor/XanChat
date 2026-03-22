--[[
	wrapper.lua - Event handling wrapper and lifecycle management for XanChat
	Improvements:
	- Simplified DebugPrint with direct table.concat
	- Consolidated event dispatch with early returns
	- Improved ticker management with direct cleanup
	- Better hook tracking to prevent duplicates
	- Cleaner callback integration
	- Removed redundant state initialization
]]

local ADDON_NAME, private = ...
if type(private) ~= "table" then
	private = {}
end

local addon = _G[ADDON_NAME]
if not addon then
	addon = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	_G[ADDON_NAME] = addon
end
local unpack = unpack or table.unpack

addon.private = private
addon.wrapper = addon

-- Initialize or reuse wrapper state to prevent duplicate registration
local state = addon._wrapperState or {
	events = {},
	registered = {},
	callbacks = {},
	tickers = {},
	useOnUpdate = false,
}
addon._wrapperState = state

-- Create or reuse wrapper frame
local frame = addon._wrapperFrame
if not frame then
	frame = CreateFrame("Frame", ADDON_NAME.."WrapperFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	addon._wrapperFrame = frame
end

-- ============================================================================
-- DEBUG OUTPUT
-- ============================================================================

local function DebugPrint(...)
	if not addon.wrapperDebug then return end

	local parts = {}
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		parts[i] = addon.dbgSafeValue and addon.dbgSafeValue(v) or tostring(v)
	end
	DEFAULT_CHAT_FRAME:AddMessage("xanChat wrapper: "..table.concat(parts, " "))
end

-- ============================================================================
-- EVENT DISPATCHING
-- ============================================================================

local function Dispatch(_, event, ...)
	if event == "ADDON_LOADED" then
		if ... == ADDON_NAME then
			addon.wrapperLoaded = true
			if type(addon.OnLoad) == "function" then
				addon:OnLoad()
			end
			DebugPrint("loaded")
		end
		return
	end

	if event == "PLAYER_LOGIN" then
		if type(addon.OnEnable) == "function" then
			addon:OnEnable()
		end
		DebugPrint("enabled")
		return
	end

	local handlers = state.events[event]
	if not handlers then return end

	for _, handler in ipairs(handlers) do
		if type(handler) == "string" then
			local fn = addon[handler]
			if fn then fn(addon, event, ...) end
		elseif type(handler) == "function" then
			handler(addon, event, ...)
		end
	end
end

frame:SetScript("OnEvent", Dispatch)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

-- ============================================================================
-- EVENT REGISTRATION
-- ============================================================================

function addon:RegisterEvent(event, handler)
	if type(event) ~= "string" or event == "" then return end

	handler = handler or event
	local list = state.events[event]
	if not list then
		list = {}
		state.events[event] = list
	end

	-- Prevent duplicate handlers
	for _, existing in ipairs(list) do
		if existing == handler then return end
	end
	table.insert(list, handler)

	-- Register event with frame if not already done
	if not state.registered[event] then
		state.registered[event] = true
		frame:RegisterEvent(event)
		DebugPrint("register", event)
	end
end

function addon:UnregisterEvent(event, handler)
	if type(event) ~= "string" or event == "" then return end

	local list = state.events[event]
	if not list then return end

	if handler then
		for i = #list, 1, -1 do
			if list[i] == handler then
				table.remove(list, i)
				break
			end
		end
		if #list == 0 then
			state.events[event] = nil
			state.registered[event] = nil
			frame:UnregisterEvent(event)
		end
	else
		state.events[event] = nil
		state.registered[event] = nil
		frame:UnregisterEvent(event)
		DebugPrint("unregister", event)
	end
end

function addon:UnregisterAllEvents()
	for event in pairs(state.events) do
		frame:UnregisterEvent(event)
	end
	wipe(state.events)
	wipe(state.registered)
end

-- ============================================================================
-- TICKER MANAGEMENT
-- ============================================================================

local function EnsureOnUpdate()
	if state.useOnUpdate then return end
	state.useOnUpdate = true
	frame:SetScript("OnUpdate", function(_, elapsed)
		for i = #state.tickers, 1, -1 do
			local t = state.tickers[i]
			if not t.cancelled then
				t.elapsed = (t.elapsed or 0) + elapsed
				if t.elapsed >= t.interval then
					t.elapsed = t.elapsed - t.interval
					t.func(unpack(t.args))
				end
			else
				table.remove(state.tickers, i)
			end
		end
	end)
end

function addon:NewTicker(interval, func, ...)
	if type(func) ~= "function" then return nil end

	interval = tonumber(interval) or 0
	if interval <= 0 then return nil end

	if C_Timer and C_Timer.NewTicker then
		return C_Timer.NewTicker(interval, func, ...)
	end

	local ticker = {
		interval = interval,
		func = func,
		args = { ... },
		elapsed = 0,
		cancelled = false,
	}
	table.insert(state.tickers, ticker)
	EnsureOnUpdate()
	return ticker
end

function addon:CancelTicker(ticker)
	if not ticker then return end

	if type(ticker) == "table" and ticker.Cancel then
		ticker:Cancel()
	elseif type(ticker) == "table" then
		ticker.cancelled = true
	end
end

-- ============================================================================
-- API COMPATIBILITY
-- ============================================================================

addon.GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
addon.GetCVar = (C_CVar and C_CVar.GetCVar) or GetCVar
addon.SetCVar = (C_CVar and C_CVar.SetCVar) or SetCVar

-- ============================================================================
-- CALLBACK HANDLER INTEGRATION
-- ============================================================================

local LibStub = _G.LibStub
if LibStub then
	local CallbackHandler = LibStub("CallbackHandler-1.0")
	if CallbackHandler then
		if type(addon) ~= "table" then
			DEFAULT_CHAT_FRAME:AddMessage("xanChat ERROR: addon is not a table, type is: "..type(addon))
			return
		end

		addon.callbacks = CallbackHandler:New(addon, "RegisterCallback", "UnregisterCallback", "UnregisterAllCallbacks")
		addon.fireCallback = function(event, ...)
			return addon.callbacks:Fire(event, ...)
		end
		addon.unregisterAllCallbacks = function()
			return addon:UnregisterAllCallbacks()
		end
		addon.registerCallback = function(event, handler)
			return addon:RegisterCallback(event, handler)
		end
		addon.unregisterCallback = function(event)
			return addon:UnregisterCallback(event)
		end
	end
end
