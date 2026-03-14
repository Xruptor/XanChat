--[[
	EditBoxHistory.lua - Command history management for XanChat
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- EDIT BOX HISTORY MANAGEMENT
-- ============================================================================

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

local function addEditBoxHistoryLine(editBox)
	if not _G.HistoryDB then return end

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

	local editBoxText = editBox:GetText()
	if editBoxText and editBoxText ~= "" then
		text = text.." "..editBoxText
		if not text or text == "" then
			return
		end

		local name = editBox:GetName()
		_G.HistoryDB[name] = _G.HistoryDB[name] or {}
		_G.HistoryDB[name][#_G.HistoryDB[name] + 1] = text

		-- max number of lines we want 40 seems like a good number
		if #_G.HistoryDB[name] > 40 then
			if _G.tremove then
				_G.tremove(_G.HistoryDB[name], 1)
			end
		end
	end
end

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
