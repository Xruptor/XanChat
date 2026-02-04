local ADDON_NAME, private = ...
if type(private) ~= "table" then
	private = {}
end

local addon = _G[ADDON_NAME]
if not addon then
	addon = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	_G[ADDON_NAME] = addon
end

addon.private = private
addon.wrapper = addon

local state = addon._wrapperState or {
	events = {},
	registered = {},
	callbacks = {},
	tickers = {},
	useOnUpdate = false,
}
addon._wrapperState = state

local frame = addon._wrapperFrame
if not frame then
	frame = CreateFrame("Frame", ADDON_NAME.."WrapperFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	addon._wrapperFrame = frame
end

local function DebugPrint(...)
	if addon.wrapperDebug then
		DEFAULT_CHAT_FRAME:AddMessage("xanChat wrapper: " .. string.join(" ", tostringall(...)))
	end
end

local function Dispatch(_, event, ...)
	if event == "ADDON_LOADED" and ... == ADDON_NAME then
		addon.wrapperLoaded = true
		if type(addon.OnLoad) == "function" then
			addon:OnLoad()
		end
		DebugPrint("loaded")
	end

	if event == "PLAYER_LOGIN" then
		if type(addon.OnEnable) == "function" then
			addon:OnEnable()
		end
		DebugPrint("enabled")
	end

	local handlers = state.events[event]
	if not handlers then return end

	for i = 1, #handlers do
		local handler = handlers[i]
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

function addon:RegisterEvent(event, handler)
	if type(event) ~= "string" or event == "" then return end
	if handler == nil then
		handler = event
	end

	local list = state.events[event]
	if not list then
		list = {}
		state.events[event] = list
	end
	list[#list + 1] = handler

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

	if handler == nil then
		state.events[event] = nil
		state.registered[event] = nil
		frame:UnregisterEvent(event)
		DebugPrint("unregister", event)
		return
	end

	for i = #list, 1, -1 do
		if list[i] == handler then
			table.remove(list, i)
		end
	end

	if #list == 0 then
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
	state.events = {}
	state.registered = {}
end

function addon:RegisterCallback(name, func, owner)
	if type(name) ~= "string" or name == "" then return end
	if type(func) ~= "function" then return end
	local list = state.callbacks[name]
	if not list then
		list = {}
		state.callbacks[name] = list
	end
	list[#list + 1] = { func = func, owner = owner }
end

function addon:UnregisterCallback(name, funcOrOwner)
	local list = state.callbacks[name]
	if not list then return end
	if funcOrOwner == nil then
		state.callbacks[name] = nil
		return
	end
	for i = #list, 1, -1 do
		local entry = list[i]
		if entry.func == funcOrOwner or entry.owner == funcOrOwner then
			table.remove(list, i)
		end
	end
	if #list == 0 then
		state.callbacks[name] = nil
	end
end

function addon:Fire(name, ...)
	local list = state.callbacks[name]
	if not list then return end
	for i = 1, #list do
		list[i].func(list[i].owner, ...)
	end
end

local function EnsureOnUpdate()
	if state.useOnUpdate then return end
	state.useOnUpdate = true
	frame:SetScript("OnUpdate", function(_, elapsed)
		for i = #state.tickers, 1, -1 do
			local t = state.tickers[i]
			if not t.cancelled then
				t.elapsed = t.elapsed + elapsed
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
	state.tickers[#state.tickers + 1] = ticker
	EnsureOnUpdate()
	return ticker
end

function addon:CancelTicker(ticker)
	if not ticker then return end
	if type(ticker) == "table" and ticker.cancelled ~= nil then
		ticker.cancelled = true
		return
	end
	if type(ticker) == "table" and ticker.Cancel then
		ticker:Cancel()
	end
end

addon.GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
addon.GetCVar = (C_CVar and C_CVar.GetCVar) or GetCVar
addon.SetCVar = (C_CVar and C_CVar.SetCVar) or SetCVar
