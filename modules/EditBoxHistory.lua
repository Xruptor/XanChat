--[[
	EditBoxHistory.lua - Command history management for XanChat
	Refactored for:
	- Simplified arrow key navigation with cleaner logic
	- Consolidated redundant nil checks
	- Better early returns
	- Improved history limit handling
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- EDIT BOX HISTORY MANAGEMENT
-- ============================================================================

local MAX_HISTORY_LINES = 40

-- Handle arrow key navigation through history
local function onArrowPressed(editBox, key)
	if not editBox.historyLines or #editBox.historyLines == 0 then
		return
	end

	if key == "DOWN" then
		editBox.historyIndex = editBox.historyIndex + 1
		if editBox.historyIndex > #editBox.historyLines then
			editBox.historyIndex = 1
		end
	elseif key == "UP" then
		editBox.historyIndex = editBox.historyIndex - 1
		if editBox.historyIndex < 1 then
			editBox.historyIndex = #editBox.historyLines
		end
	else
		return
	end

	editBox:SetText(editBox.historyLines[editBox.historyIndex])
end

-- Build command text from chat type and editbox attributes
local function buildCommandText(editBox)
	local text = ""
	local chatType = editBox:GetAttribute("chatType")
	local header = chatType and _G["SLASH_"..chatType.."1"]

	if header then
		text = header
	end

	if chatType == "WHISPER" then
		text = text.." "..editBox:GetAttribute("tellTarget")
	elseif chatType == "CHANNEL" then
		text = "/"..editBox:GetAttribute("channelTarget")
	end

	return text
end

-- Add a new line to the editbox history
local function addEditBoxHistoryLine(editBox)
	if not _G.HistoryDB then return end

	local editBoxText = editBox:GetText()
	if not editBoxText or editBoxText == "" then return end

	local commandPrefix = buildCommandText(editBox)
	local fullText = commandPrefix ~= "" and (commandPrefix.." "..editBoxText) or editBoxText

	local name = editBox:GetName()
	_G.HistoryDB[name] = _G.HistoryDB[name] or {}
	table.insert(_G.HistoryDB[name], fullText)

	-- Enforce history limit
	if #_G.HistoryDB[name] > MAX_HISTORY_LINES then
		table.remove(_G.HistoryDB[name], 1)
	end
end

-- Clear the editbox history
local function clearEditBoxHistory(editBox)
	if not _G.HistoryDB then return end

	local name = editBox:GetName()
	if _G.wipe and _G.HistoryDB[name] then
		_G.wipe(_G.HistoryDB[name])
	else
		_G.HistoryDB[name] = {}
	end
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.OnArrowPressed = onArrowPressed
addon.AddEditBoxHistoryLine = addEditBoxHistoryLine
addon.ClearEditBoxHistory = clearEditBoxHistory
