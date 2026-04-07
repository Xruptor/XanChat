--[[
	Utilities.lua - Utility functions for XanChat
	Improvements:
	- Consolidated secret value checks
	- Improved ApplyDefaults efficiency
	- Simplified SafeType with inline check
	- Better function organization
	- Removed redundant isNotSafeStr logic
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- INSTANCE DETECTION
-- ============================================================================

local function isInAnyInstance()
	return _G.IsInInstance and select(1, _G.IsInInstance()) or false
end

-- ============================================================================
-- SECRET VALUE PROTECTION
-- ============================================================================

local function SafeType(v)
	local ok, result = pcall(_G.type, v)
	return ok and result or nil
end

-- issecretvalue fails by raising an error on secret values
local function isSecretValue(v)
	local fn = _G.issecretvalue
	if type(fn) ~= "function" then
		return false
	end

	local ok, res = pcall(fn, v)
	return not (ok and not res)
end

local function canAccessValue(v)
	local fn = _G.canaccessvalue
	if type(fn) ~= "function" then
		return true
	end

	local ok, res = pcall(fn, v)
	return ok and res
end

-- Apply default values to a target table if keys are missing
local function ApplyDefaults(target, defaults)
	if not target or not defaults then return end

	for key, value in pairs(defaults) do
		if target[key] == nil then
			target[key] = value
		end
	end
end

-- Check if a value is a safe, accessible string
local function isSafeString(v)
	return not isSecretValue(v) and canAccessValue(v) and SafeType(v) == "string"
end

-- Return safe string representation for display
local function safestr(v)
	if isSecretValue(v) then
		return "<secret-string>"
	end
	if not canAccessValue(v) then
		return "<inaccessible-string>"
	end
	if SafeType(v) ~= "string" then
		return ""
	end
	return v
end

-- Return boolean indicating if value requires safe string handling
local function safestr_bool(v)
	return isSecretValue(v) or not canAccessValue(v) or SafeType(v) ~= "string"
end

-- ============================================================================
-- SAFE STRING OPERATIONS FOR SECRET VALUES
-- ============================================================================

-- Safely perform string.match, returns nil on error (e.g., secret values)
local function SafeMatch(str, pattern, init)
	if not isSafeString(str) then return nil end
	local ok, result = pcall(string.match, str, pattern, init)
	return ok and result or nil
end

-- Safely perform string.gsub, returns original string on error
local function SafeGSub(str, pattern, repl, n)
	if not isSafeString(str) then return str end
	local ok, result = pcall(string.gsub, str, pattern, repl, n)
	return ok and result or str
end

-- Safely perform string.format, returns original string on error
-- Takes a table of args for Lua 5.1 compatibility
local function SafeFormat(fmt, args)
	if not isSafeString(fmt) then return fmt end
	if type(args) ~= "table" then return fmt end
	local ok, result = pcall(string.format, fmt, unpack(args))
	return ok and result or fmt
end

-- ============================================================================
-- CHAT FRAME ROUTING
-- ============================================================================

-- Check if a chat frame is valid and should receive messages
local function isChatFrameValid(frame)
	if not frame then return false end
	if type(frame) ~= "table" then return false end
	if not frame.GetObjectType then return false end
	if frame:GetObjectType() ~= "Frame" then return false end

	-- Check if frame is registered in CHAT_FRAMES
	local frameName = frame:GetName()
	if not frameName then return false end

	if _G.CHAT_FRAMES then
		for _, name in ipairs(_G.CHAT_FRAMES) do
			if name == frameName then
				return true
			end
		end
	end

	return false
end

-- Check if a frame is visible (shown and not hidden)
local function isFrameVisible(frame)
	if not frame then return false end

	-- Check IsShown safely
	local isShown = true
	if frame.IsShown then
		local ok = pcall(function()
			isShown = frame:IsShown()
		end)
		if not ok then
			isShown = true
		end
	end

	return isShown
end

-- Check if a frame is the active tab in its dock
-- When frames are docked together, only the active tab receives messages
local function isActiveDockTab(frame)
	if not frame then return false end

	-- If the frame isn't docked, it's always "active" for receiving messages
	local isDocked = false
	if frame.IsDocked then
		local ok = pcall(function()
			isDocked = frame:IsDocked()
		end)
		if not ok then
			isDocked = false
		end
	end

	if not isDocked then
		return true
	end

	-- Frame is docked - check if it's the selected frame in the dock
	-- Use FCFDock_GetSelectedFrame if available (modern API)
	if _G.FCFDock_GetSelectedFrame then
		-- Get the dock for this frame
		local dock = frame:GetDock()
		if dock then
			local selectedFrame = _G.FCFDock_GetSelectedFrame(dock)
			return selectedFrame == frame
		end
	end

	-- Fallback: check if the frame has a dock reference and compare
	if frame.dock then
		local dock = frame.dock
		if dock.GetSelectedFrame then
			local selectedFrame = dock:GetSelectedFrame()
			return selectedFrame == frame
		end
	end

	-- If we can't determine, assume active (conservative approach)
	return true
end

-- Get all chat frames that should receive a message for a given event/channel
-- Returns a table of frame objects that are valid, visible, and configured for the event
-- @param event string: The chat event (e.g., "CHAT_MSG_CHANNEL", "CHAT_MSG_GUILD")
-- @param channelNumber string|number|nil: Optional channel number for channel events
-- @return table: Array of chat frames that should receive the message
local function getTargetChatFrames(event, channelNumber)
	local targetFrames = {}

	if not _G.CHAT_FRAMES then
		return targetFrames
	end

	for i = 1, #_G.CHAT_FRAMES do
		local frameName = _G.CHAT_FRAMES[i]
		local frame = _G[frameName]

		if not frame then
			-- Try direct lookup
			frame = _G["ChatFrame" .. i]
		end

		-- Check if frame is valid
		if not isChatFrameValid(frame) then
			-- skip this frame
		elseif not isFrameVisible(frame) then
			-- skip this frame
		elseif not isActiveDockTab(frame) then
			-- skip this frame (docked but not the active tab)
		else
			local shouldAdd = true

			-- For channel events, check if the specific channel is enabled
			if channelNumber and channelNumber ~= "" and channelNumber ~= "0" then
				local channelNum = tostring(channelNumber)
				local hasChannel = false

				-- Check frame's channel list
				if frame.channelList then
					for _, chan in ipairs(frame.channelList) do
						if tostring(chan) == channelNum then
							hasChannel = true
							break
						end
					end
				end

				-- Alternative check using Blizzard API
				if not hasChannel and _G.FCF_IsChatFrameEnabledForChannel then
					local ok, result = pcall(_G.FCF_IsChatFrameEnabledForChannel, frame, tonumber(channelNum))
					if ok and result then
						hasChannel = true
					end
				end

				if not hasChannel then
					shouldAdd = false
				end
			end

			-- Add frame to target list
			if shouldAdd then
				table.insert(targetFrames, frame)
			end
		end
	end

	return targetFrames
end

-- ============================================================================
-- CHAT EVENT CLASSIFICATION
-- ============================================================================

-- System-only CHAT_MSG events where users cannot type/communicate
-- These events may contain format placeholders (%s, %d, etc.) in message text
-- chatType is the event name with "CHAT_MSG_" prefix removed
-- Source: Compare with SKIP_STYLING_EVENTS in PlayerNameStyling.lua
local SYSTEM_ONLY_CHAT_EVENTS = {
	-- Achievement system events
	ACHIEVEMENT = true,
	GUILD_ACHIEVEMENT = true,

	-- System notifications
	SYSTEM = true,
	AFK = true,
	DND = true,
	IGNORED = true,
	ERRORS = true,
	ADDON = true,

	-- Channel system messages (not user chat in channels)
	CHANNEL_NOTICE = true,
	CHANNEL_NOTICE_USER = true,

	-- Combat and events
	COMBAT_MISC_INFO = true,
	COMBAT_XP_GAIN = true,
	COMBAT_FACTION_CHANGE = true,
	COMBAT_HONOR_GAIN = true,

	-- Economy/Items
	TRADESKILLS = true,
	LOOT = true,
	MONEY = true,
	CURRENCY = true,

	-- Pet system
	PET_INFO = true,
	PET_BATTLE_COMBAT_LOG = true,
	PET_BATTLE_INFO = true,

	-- NPC speech (not player-controlled)
	MONSTER_SAY = true,
	MONSTER_YELL = true,
	MONSTER_WHISPER = true,
	MONSTER_EMOTE = true,
	MONSTER_PARTY = true,
	MONSTER_RAID = true,

	-- Raid boss emotes
	RAID_BOSS_EMOTE = true,
	RAID_BOSS_WHISPER = true,

	-- Lockpicking/casting opening messages
	OPENING = true,

	-- Battleground system messages
	BG_SYSTEM_ALLIANCE = true,
	BG_SYSTEM_HORDE = true,
	BG_SYSTEM_NEUTRAL = true,

	-- Battle.net system notifications (not chat)
	BN_INLINE_TOAST_ALERT = true,
	BN_INLINE_TOAST_BROADCAST = true,
	BN_INLINE_TOAST_BROADCAST_INFORM = true,
	BN_INLINE_TOAST_CONVERSATION = true,
	BN_WHISPER_PLAYER_OFFLINE = true,
}

-- User chat events where players can type/communicate
-- These should NEVER have format placeholders replaced
local USER_CHAT_EVENTS = {
	SAY = true,
	YELL = true,
	EMOTE = true,          -- Player /emote commands
	TEXT_EMOTE = true,     -- Player emotes from emote menu
	WHISPER = true,
	WHISPER_INFORM = true,
	GUILD = true,
	OFFICER = true,
	PARTY = true,
	PARTY_LEADER = true,
	RAID = true,
	RAID_LEADER = true,
	RAID_WARNING = true,
	CHANNEL = true,        -- User chat channels (1-10)
	BN_WHISPER = true,
	BN_WHISPER_INFORM = true,
	BN_CONVERSATION = true,
	BN_CONVERSATION_NOTICE = true,
	COMMUNITIES_CHANNEL = true,
}

-- Check if a chat event type is a system-only event (not user chat)
-- @param chatType string: The chat type (e.g., "ACHIEVEMENT", "GUILD", "SAY")
-- @return boolean: true if this is a system-only event where users cannot type
local function isSystemOnlyEvent(chatType)
	if not chatType or type(chatType) ~= "string" then
		return false
	end
	return SYSTEM_ONLY_CHAT_EVENTS[chatType] or false
end

-- Check if a chat event type is a user chat event (players can type)
-- @param chatType string: The chat type (e.g., "GUILD", "SAY", "WHISPER")
-- @return boolean: true if this is a user chat event
local function isUserChatEvent(chatType)
	if not chatType or type(chatType) ~= "string" then
		return false
	end
	return USER_CHAT_EVENTS[chatType] or false
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.isInAnyInstance = isInAnyInstance
addon.ApplyDefaults = ApplyDefaults
addon.isSecretValue = isSecretValue
addon.canAccessValue = canAccessValue
addon.isSafeString = isSafeString
addon.safestr = safestr
addon.safestr_bool = safestr_bool
addon.SafeType = SafeType
addon.SafeMatch = SafeMatch
addon.SafeGSub = SafeGSub
addon.SafeFormat = SafeFormat
addon.isChatFrameValid = isChatFrameValid
addon.isFrameVisible = isFrameVisible
addon.isActiveDockTab = isActiveDockTab
addon.getTargetChatFrames = getTargetChatFrames
addon.isSystemOnlyEvent = isSystemOnlyEvent
addon.isUserChatEvent = isUserChatEvent
addon.SYSTEM_ONLY_CHAT_EVENTS = SYSTEM_ONLY_CHAT_EVENTS
addon.USER_CHAT_EVENTS = USER_CHAT_EVENTS

-- ============================================================================
-- SHARED UI HELPERS (used by filter.lua, stickychannels.lua)
-- ============================================================================

local function isRestricted()
	return addon.IsRestricted and addon:IsRestricted()
end

local function guardRestricted()
	if isRestricted() then
		if addon.NotifyConfigLocked then
			addon:NotifyConfigLocked()
		end
		return true
	end
	return false
end

local function createDialogFrame(frameName, titleText)
	local frame = _G.CreateFrame("frame", frameName, _G.UIParent, _G.BackdropTemplateMixin and "BackdropTemplate")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:SetWidth(380)
	frame:SetHeight(570)

	frame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 32,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
	})
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:SetPoint("CENTER", _G.UIParent, "CENTER", 0, 0)

	local closeButton = _G.CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", frame, -15, -8)

	local header = frame:CreateFontString("$parentHeaderText", "ARTWORK", "GameFontNormalSmall")
	header:SetJustifyH("LEFT")
	header:SetFontObject("GameFontNormal")
	header:SetPoint("CENTER", frame, "TOP", 0, -20)
	header:SetText(titleText)

	return frame
end

local function createScrollFrame(parent, yOffset)
	local scrollFrame = _G.CreateFrame("ScrollFrame", parent:GetName().."_Scroll", parent, "UIPanelScrollFrameTemplate")
	local scrollChild = _G.CreateFrame("frame", parent:GetName().."_ScrollChild", scrollFrame, _G.BackdropTemplateMixin and "BackdropTemplate")
	scrollFrame:SetPoint("TOPLEFT", 10, yOffset)
	scrollFrame:SetPoint("BOTTOMRIGHT", -40, 70)
	scrollFrame:SetScrollChild(scrollChild)

	return scrollFrame, scrollChild
end

addon.isRestricted = isRestricted
addon.guardRestricted = guardRestricted
addon.createDialogFrame = createDialogFrame
addon.createScrollFrame = createScrollFrame
