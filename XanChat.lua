--Some stupid custom Chat modifications for made for myself.
--Sharing it with the world in case anybody wants to actually use this.

local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent)
end
addon = _G[ADDON_NAME]

addon:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

local debugf = tekDebug and tekDebug:GetFrame(ADDON_NAME)
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

--[[------------------------
	Scrolling and Chat Links
--------------------------]]

local StickyTypeChannels = {
  SAY = 1,
  YELL = 0,
  EMOTE = 0,
  PARTY = 1, 
  RAID = 1,
  GUILD = 1,
  OFFICER = 1,
  WHISPER = 1,
  CHANNEL = 1,
};

local function scrollChat(frame, delta)
	--Faster Scroll
	if IsControlKeyDown()  then
		--Faster scrolling by triggering a few scroll up in a loop
		if ( delta > 0 ) then
			for i = 1,5 do frame:ScrollUp(); end;
		elseif ( delta < 0 ) then
			for i = 1,5 do frame:ScrollDown(); end;
		end
	elseif IsAltKeyDown() then
		--Scroll to the top or bottom
		if ( delta > 0 ) then
			frame:ScrollToTop();
		elseif ( delta < 0 ) then
			frame:ScrollToBottom();
		end		
	else
		--Normal Scroll
		if delta > 0 then
			frame:ScrollUp()
		elseif delta < 0 then
			frame:ScrollDown()
		end
	end
end

--DO CHAT DROPDOWN MENU
------------------------------
local customPopups = {}

StaticPopupDialogs["COPYNAME"] = {
	text = "COPY NAME",
	button2 = CANCEL,
	hasEditBox = true,
    hasWideEditBox = true,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
	whileDead = 1,
	maxLetters = 255,
}

UnitPopupButtons["WHOPLAYER"] = {
	text = L.WhoPlayer,
	func = function()
		local dropdownFrame = UIDROPDOWNMENU_INIT_MENU
		local name = dropdownFrame.name

		if name then
			SendWho(name)
		end
	end
}
tinsert(UnitPopupMenus["FRIEND"], #UnitPopupMenus["FRIEND"] - 1, "WHOPLAYER")
customPopups["WHOPLAYER"] = true

UnitPopupButtons["GUILDINVITE"] = {
	text = L.GuildInvite,
	func = function()
		local dropdownFrame = UIDROPDOWNMENU_INIT_MENU
		local name = dropdownFrame.name

		if name then
			GuildInvite(name)
		end
	end
}
tinsert(UnitPopupMenus["FRIEND"], #UnitPopupMenus["FRIEND"] - 1, "GUILDINVITE")
customPopups["GUILDINVITE"] = true

UnitPopupButtons["COPYNAME"] = {
	text = L.CopyName,
	func = function()
		local dropdownFrame = UIDROPDOWNMENU_INIT_MENU
		local name = dropdownFrame.name

		if name then
			local dialog = StaticPopup_Show("COPYNAME")
			local editbox = _G[dialog:GetName().."EditBox"]  
			editbox:SetText(name or "")
			editbox:SetFocus()
			editbox:HighlightText()
			local button = _G[dialog:GetName().."Button2"]
			button:ClearAllPoints()
			button:SetPoint("CENTER", editbox, "CENTER", 0, -30)
		end
	end
}
tinsert(UnitPopupMenus["FRIEND"], #UnitPopupMenus["FRIEND"] - 1, "COPYNAME")
customPopups["COPYNAME"] = true
 
--we got to make sure our function occurs for our custom unitpopup, otherwise it will cause errors with other unitpopup entries
local function customPopupMenu(dropdownMenu, which, unit, name, userData, ...)
	for i=1, UIDROPDOWNMENU_MAXBUTTONS do
		local button = _G["DropDownList" .. UIDROPDOWNMENU_MENU_LEVEL .. "Button" .. i]
		local popup = customPopups[button.value]
		if popup then
			button.func = UnitPopupButtons[button.value].func
		end
	end
end

hooksecurefunc("UnitPopup_ShowMenu", customPopupMenu)

--[[------------------------
	URL COPY
--------------------------]]

local SetItemRef_orig = SetItemRef

function doColor(url)
	url = " |cff99FF33|Hurl:"..url.."|h["..url.."]|h|r "
	return url
end

function urlFilter(self, event, msg, author, ...)
	if strfind(msg, "(%a+)://(%S+)%s?") then
		return false, gsub(msg, "(%a+)://(%S+)%s?", doColor("%1://%2")), author, ...
	end
	if strfind(msg, "www%.([_A-Za-z0-9-]+)%.(%S+)%s?") then
		return false, gsub(msg, "www%.([_A-Za-z0-9-]+)%.(%S+)%s?", doColor("www.%1.%2")), author, ...
	end
	if strfind(msg, "([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?") then
		return false, gsub(msg, "([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?", doColor("%1@%2%3%4")), author, ...
	end
	if strfind(msg, "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?):(%d%d?%d?%d?%d?)%s?") then
		return false, gsub(msg, "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?):(%d%d?%d?%d?%d?)%s?", doColor("%1.%2.%3.%4:%5")), author, ...
	end
	if strfind(msg, "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?") then
		return false, gsub(msg, "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?", doColor("%1.%2.%3.%4")), author, ...
	end
	if strfind(msg, "[wWhH][wWtT][wWtT][\46pP]%S+[^%p%s]") then
		return false, gsub(msg, "[wWhH][wWtT][wWtT][\46pP]%S+[^%p%s]", doColor("%1")), author, ...
	end
end

StaticPopupDialogs["LINKME"] = {
	text = L.URLCopy,
	button2 = CANCEL,
	hasEditBox = true,
    hasWideEditBox = true,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
	whileDead = 1,
	maxLetters = 255,
}

local SetHyperlink = _G.ItemRefTooltip.SetHyperlink
function _G.ItemRefTooltip:SetHyperlink(link, ...)

	if type(link) ~= "string" then return end

	if link and (strsub(link, 1, 3) == "url") then
		local url = strsub(link, 5)
		local dialog = StaticPopup_Show("LINKME")
		local editbox = _G[dialog:GetName().."EditBox"]  
		
		editbox:SetText(url)
		editbox:SetFocus()
		editbox:HighlightText()
		
		local button = _G[dialog:GetName().."Button2"]
		button:ClearAllPoints()
		button:SetPoint("CENTER", editbox, "CENTER", 0, -30)
		
		return
     end
	 
	 SetHyperlink(self, link, ...)
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", urlFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_CONVERSATION", urlFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", urlFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", urlFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", urlFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_WARNING", urlFilter)

ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", urlFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", urlFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", urlFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", urlFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", urlFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", urlFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", urlFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", urlFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", urlFilter)

--[[------------------------
	CORE LOAD
--------------------------]]

local dummy = function(self) self:Hide() end
local msgHooks = {}
local HistoryDB

StaticPopupDialogs["XANCHAT_APPLYCHANGES"] = {
  text = L.ApplyChanges,
  button1 = L.Yes,
  button2 = L.No,
  OnAccept = function()
      ReloadUI()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
}

local AddMessage = function(frame, text, ...)
	if type(text) == "string" then
		local chatNum = string.match(text,"%d+") or ""
		if not tonumber(chatNum) then chatNum = "" else chatNum = chatNum..":" end
		text = gsub(text, L.ChannelGeneral, "["..chatNum..L.ShortGeneral.."]")
		text = gsub(text, L.ChannelTrade, "["..chatNum..L.ShortTrade.."]")
		text = gsub(text, L.ChannelWorldDefense, "["..chatNum..L.ShortWorldDefense.."]")
		text = gsub(text, L.ChannelLocalDefense, "["..chatNum..L.ShortLocalDefense.."]")
		text = gsub(text, L.ChannelLookingForGroup, "["..chatNum..L.ShortLookingForGroup.."]")
		text = gsub(text, L.ChannelGuildRecruitment, "["..chatNum..L.ShortGuildRecruitment.."]")
	end
	msgHooks[frame:GetName()].AddMessage(frame, text, ...)
end

local function setEditBox(sSwitch)
	for i = 1, NUM_CHAT_WINDOWS do
		local eb = _G[("ChatFrame%dEditBox"):format(i)]
		
		if sSwitch then
			eb:ClearAllPoints()
			eb:SetPoint("BOTTOMLEFT",  ("ChatFrame%d"):format(i), "TOPLEFT",  -5, 0)
			eb:SetPoint("BOTTOMRIGHT", ("ChatFrame%d"):format(i), "TOPRIGHT", 5, 0)
		else
			eb:ClearAllPoints()
			eb:SetPoint("TOPLEFT",  ("ChatFrame%d"):format(i), "BOTTOMLEFT",  -5, 0)
			eb:SetPoint("TOPRIGHT", ("ChatFrame%d"):format(i), "BOTTOMRIGHT", 5, 0)
		end
	end
end

--save and restore layout functions
local function SaveLayout(chatFrame)
	if not chatFrame then return end
	
	if not XCHT_DB then return end
	if not XCHT_DB.frames then XCHT_DB.frames = {} end
	if not XCHT_DB.frames[chatFrame:GetID()] then XCHT_DB.frames[chatFrame:GetID()] = {} end
	
	local db = XCHT_DB.frames[chatFrame:GetID()]

	local point, xOffset, yOffset = GetChatWindowSavedPosition(chatFrame:GetID())

	db.point = point
	db.xOffset = xOffset
	db.yOffset = yOffset
	db.width = chatFrame:GetWidth()
	db.height = chatFrame:GetHeight()
end

local function RestoreLayout(chatFrame)
	if not chatFrame then return end
	
	if not XCHT_DB then return end
	if not XCHT_DB.frames then return end
	if not XCHT_DB.frames[chatFrame:GetID()] then return end
	
	local db = XCHT_DB.frames[chatFrame:GetID()]
	
 	if ( db.width and db.height ) then
 		chatFrame:SetSize(db.width, db.height)
 	end
	
	local sSwitch = false
	
	--check to see if we can even move the frame
	if not chatFrame:IsMovable() then
		chatFrame:SetMovable(true)
		sSwitch = true
		Debug(chatFrame:GetID(), chatFrame:GetName(), "SetMovable")
	end
 	
 	if ( chatFrame:IsMovable() and db.point and db.xOffset and db.yOffset ) then
		chatFrame:SetUserPlaced(true)
 		chatFrame:ClearAllPoints()
		chatFrame:SetPoint(db.point, db.xOffset * GetScreenWidth(), db.yOffset * GetScreenHeight())
		Debug(chatFrame:GetID(), chatFrame:GetName(), chatFrame:IsMovable(), chatFrame:IsUserPlaced(), "SetPoint")
 	end
	
	if sSwitch then
		chatFrame:SetMovable(false)
		Debug(chatFrame:GetID(), chatFrame:GetName(), "SetMovable Off")
	end
	
	Debug(chatFrame:GetID(), chatFrame:GetName(), "Restored")
	Debug("   --   ")
end

local function SaveSettings(chatFrame)
	if not chatFrame then return end
	
	if not XCHT_DB then return end
	if not XCHT_DB.frames then return end
	if not XCHT_DB.frames[chatFrame:GetID()] then return end
	
	local db = XCHT_DB.frames[chatFrame:GetID()]
	
	local name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable = GetChatWindowInfo(chatFrame:GetID())
	local windowMessages = { GetChatWindowMessages(chatFrame:GetID())}
	local windowChannels = { GetChatWindowChannels(chatFrame:GetID())}
	
	db.chatParent = chatFrame:GetParent():GetName()
	db.windowInfo = {name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable}
	db.windowMessages = windowMessages
	db.windowChannels = windowChannels	
end

--https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/FrameXML/ChatConfigFrame.lua

local function RestoreSettings(chatFrame)
	if not chatFrame then return end
	
	if not XCHT_DB then return end
	if not XCHT_DB.frames then return end
	if not XCHT_DB.frames[chatFrame:GetID()] then return end
	
	local db = XCHT_DB.frames[chatFrame:GetID()]
	
	if db.windowMessages then
		--remove current window messages
		local oldWindowMessages = { GetChatWindowMessages(chatFrame:GetID())}
		for k=1, #oldWindowMessages do
			RemoveChatWindowMessages(chatFrame:GetID(), oldWindowMessages[k])
		end
		--add the stored ones
		local newWindowMessages = db.windowMessages
		for k=1, #newWindowMessages do
			AddChatWindowMessages(chatFrame:GetID(), newWindowMessages[k])
		end
	end
	
	if db.windowChannels then
		--remove current window channels
		local oldWindowChannels = { GetChatWindowChannels(chatFrame:GetID())}
		for k=1, #oldWindowChannels do
			RemoveChatWindowChannel(chatFrame:GetID(), oldWindowChannels[k])
		end
		--add the stored ones
		local newWindowChannels = db.windowChannels
		for k=1, #newWindowChannels do
			AddChatWindowChannel(chatFrame:GetID(), newWindowChannels[k])
		end
	end

	if db.windowInfo then
		SetChatWindowName(chatFrame:GetID(), db.windowInfo[1])
		FCF_SetWindowName(chatFrame, db.windowInfo[1])

		SetChatWindowSize(chatFrame:GetID(), db.windowInfo[2])
		FCF_SetChatWindowFontSize(nil, chatFrame, db.windowInfo[2])
		
		SetChatWindowColor(chatFrame:GetID(), db.windowInfo[3], db.windowInfo[4], db.windowInfo[5])
		FCF_SetWindowColor(chatFrame, db.windowInfo[3], db.windowInfo[4], db.windowInfo[5])
		
		SetChatWindowAlpha(chatFrame:GetID(), db.windowInfo[6])
		FCF_SetWindowAlpha(chatFrame, db.windowInfo[6])
		
		SetChatWindowShown(chatFrame:GetID(), db.windowInfo[7])
		
		SetChatWindowLocked(chatFrame:GetID(), db.windowInfo[8])
		FCF_SetLocked(chatFrame, db.windowInfo[8])
		
		SetChatWindowDocked(chatFrame:GetID(), db.windowInfo[9])
		FCF_DockFrame(chatFrame, db.windowInfo[9])
		
		SetChatWindowUninteractable(chatFrame:GetID(), db.windowInfo[10])
		FCF_SetUninteractable(chatFrame, db.windowInfo[10])
	end
	
	if db.chatParent then
		chatFrame:SetParent(db.chatParent)
	end
	
	--restore layout does this already, but just in case
	if ( db.width and db.height ) then
		chatFrame:SetWidth(db.width) --just in case
		chatFrame:SetHeight(db.height) --just in case
	end

end

local function doValueUpdate(checkBool, groupType)
	SaveSettings(FCF_GetCurrentChatFrame() or nil)
end

hooksecurefunc("ToggleChatMessageGroup", doValueUpdate)
hooksecurefunc("ToggleMessageSource", doValueUpdate)
hooksecurefunc("ToggleMessageDest", doValueUpdate)
hooksecurefunc("ToggleMessageTypeGroup", doValueUpdate)
hooksecurefunc("ToggleMessageType", doValueUpdate)
hooksecurefunc("ToggleChatChannel", doValueUpdate)
hooksecurefunc("ToggleChatColorNamesByClassGroup", doValueUpdate)


--[[------------------------
	Edit Box History
--------------------------]]

local function OnArrowPressed(self, key)
	if #self.historyLines == 0 then
		return
	end
	if key == "DOWN" then
		self.historyIndex = self.historyIndex + 1
		if self.historyIndex > #self.historyLines then
			self.historyIndex = 1
		end
	elseif key == "UP" then
		self.historyIndex = self.historyIndex - 1
		if self.historyIndex < 1 then
			self.historyIndex = #self.historyLines
		end
	else
		return
	end
	self:SetText(self.historyLines[self.historyIndex])
end

local function AddEditBoxHistoryLine(editBox)
	if not HistoryDB then return end
	
	local text = ""
	local type = editBox:GetAttribute("chatType")
	local header = _G["SLASH_" .. type .. "1"]

	if (header) then
		text = header
	end
	
	if (type == "WHISPER") then
		text = text .. " " .. editBox:GetAttribute("tellTarget")
	elseif (type == "CHANNEL") then
		text = "/" .. editBox:GetAttribute("channelTarget")
	end
		
	local editBoxText = editBox:GetText()
	if (strlen(editBoxText) > 0) then
	
		text = text .. " " .. editBox:GetText()
        if not text or (text == "") then
            return
        end
	
		local name = editBox:GetName()
		HistoryDB[name] = HistoryDB[name] or {}

		tinsert(HistoryDB[name], #HistoryDB[name] + 1, text)
		if #HistoryDB[name] > 40 then  --max number of lines we want 40 seems like a good number
			tremove(HistoryDB[name], 1)
		end
	end
end

local function ClearEditBoxHistory(editBox)
	if not HistoryDB then return end
	
	local name = editBox:GetName()
	HistoryDB[name] = {}
end

--[[------------------------
	PLAYER_LOGIN
--------------------------]]

for i = 1, NUM_CHAT_WINDOWS do
	local n = ("ChatFrame%d"):format(i)
	local f = _G[n]
	if f then
		--have to do this before player login otherwise issues occur
		f:SetMaxLines(500)
	end
end

function addon:PLAYER_LOGIN()

	local currentPlayer = UnitName("player")
	local currentRealm = select(2, UnitFullName("player")) --get shortend realm name with no spaces and dashes
	
	--do the DB stuff
	if not XCHT_DB then XCHT_DB = {} end
	if XCHT_DB.hideSocial == nil then XCHT_DB.hideSocial = false end
	if XCHT_DB.addFontShadow == nil then XCHT_DB.addFontShadow = false end
	if XCHT_DB.hideScroll == nil then XCHT_DB.hideScroll = false end
	if XCHT_DB.shortNames == nil then XCHT_DB.shortNames = false end
	if XCHT_DB.editBoxTop == nil then XCHT_DB.editBoxTop = false end
	if XCHT_DB.hideTabs == nil then XCHT_DB.hideTabs = false end
	if XCHT_DB.hideVoice == nil then XCHT_DB.hideVoice = false end
	
	--setup the history DB
	if not XCHT_HISTORY then XCHT_HISTORY = {} end
	XCHT_HISTORY[currentRealm] = XCHT_HISTORY[currentRealm] or {}
	XCHT_HISTORY[currentRealm][currentPlayer] = XCHT_HISTORY[currentRealm][currentPlayer] or {}
	HistoryDB = XCHT_HISTORY[currentRealm][currentPlayer]
	
	--turn off profanity filter
	SetCVar("profanityFilter", 0)
	
	--sticky channels
	for k, v in pairs(StickyTypeChannels) do
	  ChatTypeInfo[k].sticky = v;
	end
	
	--toggle class colors
	for i,v in pairs(CHAT_CONFIG_CHAT_LEFT) do
		ToggleChatColorNamesByClassGroup(true, v.type)
	end
	
	--this is to toggle class colors for all the global channels that is not listed under CHAT_CONFIG_CHAT_LEFT
	for iCh = 1, 15 do
		ToggleChatColorNamesByClassGroup(true, "CHANNEL"..iCh)
	end

	for i = 1, NUM_CHAT_WINDOWS do
		local n = ("ChatFrame%d"):format(i)
		local f = _G[n]
		
		if f then
		
			XANCHAT_Frame = XANCHAT_Frame or {}
			XANCHAT_Frame[i] = f

			--restore saved layout
			RestoreLayout(f)
			
			--restore any settings
			RestoreSettings(f)

			--save our settings
			hooksecurefunc(f, "StopMovingOrSizing", function(self)
				SaveLayout(f)
				SaveSettings(f)
			end)
			
			--always lock the frames regardless
			SetChatWindowLocked(i, true)
			FCF_SetLocked(f, true)
			
			--add font shadows
			if XCHT_DB.addFontShadow then
				local font, size = f:GetFont()
				f:SetFont(font, size, "THINOUTLINE")
				f:SetShadowColor(0, 0, 0, 0)
			end

			--few changes
			f:EnableMouseWheel(true)
			f:SetScript('OnMouseWheel', scrollChat)
			f:SetClampRectInsets(0,0,0,0)
			
			local editBox = _G[n.."EditBox"]
			
			if editBox then
			
                local name = editBox:GetName()
				HistoryDB[name] = HistoryDB[name] or {}
			
				--do the editbox history stuff
				---------------------------------
				editBox.historyLines = HistoryDB[name]
				editBox.historyIndex = 0
				editBox:HookScript("OnArrowPressed", OnArrowPressed)
				editBox:HookScript("OnShow", function(self)
					--reset the historyindex so we can always go back to the last thing said by pressing down
					self.historyIndex = 0
				end)
				
				local count = #HistoryDB[name]

				--count down, check for 0 very important!  It will cause a crash because it's an infinite loop
				if count > 0 then
					for i=count, 1, -1 do
						if HistoryDB[name][i] then
							editBox:AddHistoryLine(HistoryDB[name][i])
						else
							break
						end
					end
				end
				
				hooksecurefunc(editBox, "AddHistoryLine", AddEditBoxHistoryLine)
				hooksecurefunc(editBox, "ClearHistory", ClearEditBoxHistory)
				
				---------------------------------
				
				if not editBox.left then
					editBox.left = _G[n.."EditBoxLeft"]
					editBox.right = _G[n.."EditBoxRight"]
					editBox.mid = _G[n.."EditBoxMid"]
				end
				
				--remove alt keypress from the EditBox (no longer need alt to move around)
				editBox:SetAltArrowKeyMode(false)

				editBox.left:SetAlpha(0)
				editBox.right:SetAlpha(0)
				editBox.mid:SetAlpha(0)

				editBox.focusLeft:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Left2]])
				editBox.focusRight:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Right2]])
				editBox.focusMid:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Mid2]])
				
				--do editbox positioning
				if XCHT_DB.editBoxTop then
					setEditBox(true)
				else
					setEditBox()
				end
				
				--when the editbox is on the top, complications occur because sometimes you are not allowed to click on the tabs.
				--to fix this we'll just make the tab close the editbox
				--also force the editbox to hide itself when it loses focus
				_G[n.."Tab"]:HookScript("OnClick", function() editBox:Hide() end)
				editBox:HookScript("OnEditFocusLost", function(self) self:Hide() end)
			end
			--hide the scroll bars
			if XCHT_DB.hideScroll then
				if f.buttonFrame then
					f.buttonFrame:Hide()
					f.buttonFrame:SetScript("OnShow", dummy)
				end
				if f.ScrollToBottomButton then
					f.ScrollToBottomButton:Hide()
					f.ScrollToBottomButton:SetScript("OnShow", dummy)
				end
			end
			
			--enable/disable short channel names by hooking into AddMessage (ignore the combatlog)
			if XCHT_DB.shortNames and f ~= COMBATLOG and not msgHooks[n] then
				msgHooks[n] = {}
				msgHooks[n].AddMessage = f.AddMessage
				f.AddMessage = AddMessage
			end
			
		end

	end

	--show/hide the chat social buttons
	if XCHT_DB.hideSocial then
		ChatFrameMenuButton:Hide()
		ChatFrameMenuButton:SetScript("OnShow", dummy)
		QuickJoinToastButton:Hide()
		QuickJoinToastButton:SetScript("OnShow", dummy)
	end
	
	--enable short channel names for globals
	if XCHT_DB.shortNames then
        CHAT_WHISPER_GET 				= L.CHAT_WHISPER_GET
        CHAT_WHISPER_INFORM_GET 		= L.CHAT_WHISPER_INFORM_GET
		CHAT_BN_WHISPER_GET           	= L.CHAT_WHISPER_GET
		CHAT_BN_WHISPER_INFORM_GET    	= L.CHAT_WHISPER_INFORM_GET
        CHAT_YELL_GET 					= L.CHAT_YELL_GET
        CHAT_SAY_GET 					= L.CHAT_SAY_GET
        CHAT_BATTLEGROUND_GET			= L.CHAT_BATTLEGROUND_GET
        CHAT_BATTLEGROUND_LEADER_GET 	= L.CHAT_BATTLEGROUND_LEADER_GET
		CHAT_INSTANCE_CHAT_GET        	= L.CHAT_BATTLEGROUND_GET
		CHAT_INSTANCE_CHAT_LEADER_GET 	= L.CHAT_BATTLEGROUND_LEADER_GET
        CHAT_GUILD_GET   				= L.CHAT_GUILD_GET
        CHAT_OFFICER_GET 				= L.CHAT_OFFICER_GET
        CHAT_PARTY_GET        			= L.CHAT_PARTY_GET
        CHAT_PARTY_LEADER_GET 			= L.CHAT_PARTY_LEADER_GET
        CHAT_PARTY_GUIDE_GET  			= L.CHAT_PARTY_GUIDE_GET
        CHAT_RAID_GET         			= L.CHAT_RAID_GET
        CHAT_RAID_LEADER_GET  			= L.CHAT_RAID_LEADER_GET
        CHAT_RAID_WARNING_GET 			= L.CHAT_RAID_WARNING_GET
		
        CHAT_MONSTER_PARTY_GET   		= CHAT_PARTY_GET
        CHAT_MONSTER_SAY_GET     		= CHAT_SAY_GET
        CHAT_MONSTER_WHISPER_GET 		= CHAT_WHISPER_GET
        CHAT_MONSTER_YELL_GET    		= CHAT_YELL_GET
	end
	
	--do the settings for the tabs
	if XCHT_DB.hideTabs then
		--set the blizzard global variables to make the alpha of the chat tabs completely invisible
		CHAT_TAB_HIDE_DELAY = 1
		CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA = 1
		CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0
		CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA = 1
		CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 0
		CHAT_FRAME_TAB_ALERTING_MOUSEOVER_ALPHA = 1
		CHAT_FRAME_TAB_ALERTING_NOMOUSE_ALPHA = 0
	end
	
	--toggle the voice chat buttons if disabled
	if XCHT_DB.hideVoice then
		ChatFrameToggleVoiceDeafenButton:Hide()
		ChatFrameToggleVoiceMuteButton:Hide()
		ChatFrameChannelButton:Hide()
	end
	
	--remove the annoying guild loot messages by replacing them with the original ones
	YOU_LOOT_MONEY_GUILD = YOU_LOOT_MONEY
	LOOT_MONEY_SPLIT_GUILD = LOOT_MONEY_SPLIT

	--DO SLASH COMMANDS
	SLASH_XANCHAT1 = "/xanchat"
	SlashCmdList["XANCHAT"] = function(msg)
		local a,b,c=strfind(msg, "(%S+)")
		
		if a and XCHT_DB then
			if c and c:lower() == L.SlashSocial then
				addon.aboutPanel.btnSocial.func(true)
				return true
			elseif c and c:lower() == L.SlashScroll then
				addon.aboutPanel.btnScroll.func(true)
				return true
			elseif c and c:lower() == L.SlashShortNames then
				addon.aboutPanel.btnShortNames.func(true)
				return true
			elseif c and c:lower() == L.SlashEditBox then
				addon.aboutPanel.btnEditBox.func(true)
				return true
			elseif c and c:lower() == L.SlashTabs then
				addon.aboutPanel.btnTabs.func(true)
				return true
			elseif c and c:lower() == L.SlashShadow then
				addon.aboutPanel.btnShadow.func(true)
				return true
			elseif c and c:lower() == L.SlashVoice then
				addon.aboutPanel.btnVoice.func(true)
				return true
			end
		end

		DEFAULT_CHAT_FRAME:AddMessage(ADDON_NAME, 64/255, 224/255, 208/255)
		
		local preText = "/xanchat "
		DEFAULT_CHAT_FRAME:AddMessage(preText..L.SlashSocial.." - "..L.SlashSocialInfo)
		DEFAULT_CHAT_FRAME:AddMessage(preText..L.SlashScroll.." - "..L.SlashScrollInfo)
		DEFAULT_CHAT_FRAME:AddMessage(preText..L.SlashShortNames.." - "..L.SlashShortNamesInfo)
		DEFAULT_CHAT_FRAME:AddMessage(preText..L.SlashEditBox.." - "..L.SlashEditBoxInfo)
		DEFAULT_CHAT_FRAME:AddMessage(preText..L.SlashTabs.." - "..L.SlashTabsInfo)
		DEFAULT_CHAT_FRAME:AddMessage(preText..L.SlashShadow.." - "..L.SlashShadowInfo)
		DEFAULT_CHAT_FRAME:AddMessage(preText..L.SlashVoice.." - "..L.SlashVoiceInfo)
	end
	
	local ver = GetAddOnMetadata(ADDON_NAME,"Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFF20ff20%s|r] loaded:   /xanchat", ADDON_NAME, ver or "1.0"))
	
	addon:RegisterEvent("UI_SCALE_CHANGED")
	
	addon:UnregisterEvent("PLAYER_LOGIN")
end

--this is the fix for alt-tabbing resizing our chatboxes
function addon:UI_SCALE_CHANGED()
	for i = 1, NUM_CHAT_WINDOWS do
		local n = ("ChatFrame%d"):format(i)
		local f = _G[n]
		
		if f then
			--restore saved layout
			RestoreLayout(f)
			
			--restore any settings
			RestoreSettings(f)
			
			--always lock the frames regardless (using both calls just in case)
			SetChatWindowLocked(i, true)
			FCF_SetLocked(f, true)
		end
	end
end

if IsLoggedIn() then addon:PLAYER_LOGIN() else addon:RegisterEvent("PLAYER_LOGIN") end
