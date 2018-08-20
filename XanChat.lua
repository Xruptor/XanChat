--Some stupid custom Chat modifications for made for myself.
--Sharing it with the world in case anybody wants to actually use this.

local eFrame = CreateFrame("frame","xanChatEvent_Frame",UIParent)
eFrame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

local debugf = tekDebug and tekDebug:GetFrame("xanChat")
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

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
	text = "Who Player?",
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
	text = "Guild Invite",
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
	text = "Copy Name",
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
	text = "URL COPY",
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
  text = "xanChat: Would you like to apply the changes now?",
  button1 = "Yes",
  button2 = "No",
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
		text = gsub(text, "%[%d+%. General.-%]", "["..chatNum.."GN]")
		text = gsub(text, "%[%d+%. Trade.-%]", "["..chatNum.."TR]")
		text = gsub(text, "%[%d+%. WorldDefense%]", "["..chatNum.."WD]")
		text = gsub(text, "%[%d+%. LocalDefense.-%]", "["..chatNum.."LD]")
		text = gsub(text, "%[%d+%. LookingForGroup%]", "["..chatNum.."LFG]")
		text = gsub(text, "%[%d+%. GuildRecruitment.-%]", "["..chatNum.."GR]")
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
	local gpPoint, gpRelativeTo, gpRelativePoint, gpXOffset, gpYOffset = chatFrame:GetPoint()
	
	db.getPoint = {gpPoint, gpRelativeTo, gpRelativePoint, gpXOffset, gpYOffset}
	
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
	end
 	
 	if ( chatFrame:IsMovable() and db.point and db.xOffset ) then
 		chatFrame:ClearAllPoints()
		--do GetChatWindowSavedPosition first
		chatFrame:SetPoint(db.point, db.xOffset * GetScreenWidth(), db.yOffset * GetScreenHeight())
		--do old school positioning second
		--ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 33, 137)
 		chatFrame:SetUserPlaced(true)
 	else
 		chatFrame:SetUserPlaced(false)
 	end
	
	if sSwitch then
		chatFrame:SetMovable(false)
	end
end

local function SaveSettings(chatFrame, index)
	if not chatFrame then return end
	
	if not XCHT_DB then return end
	if not XCHT_DB.frames then return end
	if not XCHT_DB.frames[chatFrame:GetID()] then return end
	
	local db = XCHT_DB.frames[chatFrame:GetID()]
	
	local name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable = GetChatWindowInfo(index)
	local windowMessages = { GetChatWindowMessages(chatFrame:GetID())}
	local windowChannels = { GetChatWindowChannels(chatFrame:GetID())}
	
	db.chatParent = chatFrame:GetParent():GetName()
	db.windowInfo = {name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable}
	db.windowMessages = windowMessages
	db.windowChannels = windowChannels	
end

local function RestoreSettings(chatFrame, index)
	if not chatFrame then return end
	
	if not XCHT_DB then return end
	if not XCHT_DB.frames then return end
	if not XCHT_DB.frames[index] then return end
	
	local db = XCHT_DB.frames[index]
	
	if db.windowMessages then
		--remove current window messages
		local oldWindowMessages = { GetChatWindowMessages(index)}
		for k=1, #oldWindowMessages do
			RemoveChatWindowMessages(index, oldWindowMessages[k])
		end
		--add the stored ones
		local newWindowMessages = db.windowMessages
		for k=1, #newWindowMessages do
			AddChatWindowMessages(index, newWindowMessages[k])
		end
	end
	
	if db.windowChannels then
		--remove current window channels
		local oldWindowChannels = { GetChatWindowChannels(index)}
		for k=1, #oldWindowChannels do
			RemoveChatWindowChannel(index, oldWindowChannels[k])
		end
		--add the stored ones
		local newWindowChannels = db.windowChannels
		for k=1, #newWindowChannels do
			AddChatWindowChannel(index, newWindowChannels[k])
		end
	end

	if db.windowInfo then
		SetChatWindowName(index, db.windowInfo[1])
		SetChatWindowSize(index, db.windowInfo[2])
		SetChatWindowColor(index, db.windowInfo[3], db.windowInfo[4], db.windowInfo[5])
		SetChatWindowAlpha(index, db.windowInfo[6])
		SetChatWindowShown(index, db.windowInfo[7])
		SetChatWindowLocked(index, db.windowInfo[8])
		SetChatWindowDocked(index, db.windowInfo[9])
		SetChatWindowUninteractable(index, db.windowInfo[10])
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

--hook origFCF_SavePositionAndDimensions
local origFCF_SavePositionAndDimensions = FCF_SavePositionAndDimensions
FCF_SavePositionAndDimensions = function(chatFrame)
	SaveLayout(chatFrame)
	SaveSettings(chatFrame, chatFrame:GetID())
	origFCF_SavePositionAndDimensions(chatFrame)
end

--hook old toggle
local origFCF_ToggleLock = FCF_ToggleLock
FCF_ToggleLock = function()
	local chatFrame = FCF_GetCurrentChatFrame()
	if chatFrame then
		SaveLayout(chatFrame)
		SaveSettings(chatFrame, chatFrame:GetID())
	end
	origFCF_ToggleLock()
end

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

local function OnEditBoxShow(self)
	--reset the historyindex so we can always go back to the last thing said by pressing down
	self.historyIndex = 0
end

local function AddEditBoxHistoryLine(editBox, line)
	if not HistoryDB then return end
	
	if ( strlen(line) > 0 ) then
		tinsert(HistoryDB, #HistoryDB + 1, line)
		if #HistoryDB > 40 then  --max number of lines we want 40 seems like a good number
			tremove(HistoryDB, 1)
		end
	end
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

function eFrame:PLAYER_LOGIN()

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
		
			--restore saved layout
			RestoreLayout(f)
			
			--restore any settings
			RestoreSettings(f, i)
			
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
			
				--do the editbox history stuff
				---------------------------------
				editBox.historyLines = HistoryDB or {}
				editBox.historyIndex = 0
				editBox:HookScript("OnArrowPressed", OnArrowPressed)
				editBox:HookScript("OnShow", OnEditBoxShow)
				
				hooksecurefunc(editBox, "AddHistoryLine", AddEditBoxHistoryLine)
	
				for i, text in pairs(HistoryDB) do
					editBox:AddHistoryLine(text)
				end
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
				_G[n.."ButtonFrameUpButton"]:Hide()
				_G[n.."ButtonFrameUpButton"]:SetScript("OnShow", dummy)
				_G[n.."ButtonFrameDownButton"]:Hide()
				_G[n.."ButtonFrameDownButton"]:SetScript("OnShow", dummy)
				_G[n.."ButtonFrame"]:Hide()
				_G[n.."ButtonFrame"]:SetScript("OnShow", dummy)
				if _G[n.."ButtonFrameMinimizeButton"] then
					--this button doesn't always appear for all chat frames
					_G[n.."ButtonFrameMinimizeButton"]:Hide()
					_G[n.."ButtonFrameMinimizeButton"]:SetScript("OnShow", dummy)
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
        CHAT_WHISPER_GET 				= "[W] %s: "
        CHAT_WHISPER_INFORM_GET 		= "[W2] %s: "
        CHAT_YELL_GET 					= "|Hchannel:Yell|h[Y]|h %s: "
        CHAT_SAY_GET 					= "|Hchannel:Say|h[S]|h %s: "
        CHAT_BATTLEGROUND_GET			= "|Hchannel:Battleground|h[BG]|h %s: "
        CHAT_BATTLEGROUND_LEADER_GET 	= [[|Hchannel:Battleground|h[BG|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]]
        CHAT_GUILD_GET   				= "|Hchannel:Guild|h[G]|h %s: "
        CHAT_OFFICER_GET 				= "|Hchannel:Officer|h[O]|h %s: "
        CHAT_PARTY_GET        			= "|Hchannel:Party|h[P]|h %s: "
        CHAT_PARTY_LEADER_GET 			= [[|Hchannel:Party|h[P|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]]
        CHAT_PARTY_GUIDE_GET  			= CHAT_PARTY_LEADER_GET
        CHAT_RAID_GET         			= "|Hchannel:Raid|h[R]|h %s: "
        CHAT_RAID_LEADER_GET  			= [[|Hchannel:Raid|h[R|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]]
        CHAT_RAID_WARNING_GET 			= [[|Hchannel:RaidWarning|h[RW|TInterface\GroupFrame\UI-GROUP-MAINASSISTICON:0|t]|h %s: ]]
		
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
			if c and c:lower() == "social" then
				if XCHT_DB.hideSocial then
					XCHT_DB.hideSocial = false
					DEFAULT_CHAT_FRAME:AddMessage("xanChat: Social buttons are now [|cFF99CC33ON|r]")
				else
					XCHT_DB.hideSocial = true
					DEFAULT_CHAT_FRAME:AddMessage("XanDebuffTimers: Social buttons are now [|cFF99CC33OFF|r]")
				end
				StaticPopup_Show("XANCHAT_APPLYCHANGES")
				return true
			elseif c and c:lower() == "scroll" then
				if XCHT_DB.hideScroll then
					XCHT_DB.hideScroll = false
					DEFAULT_CHAT_FRAME:AddMessage("xanChat: Scroll buttons are now [|cFF99CC33ON|r]")
				else
					XCHT_DB.hideScroll = true
					DEFAULT_CHAT_FRAME:AddMessage("xanChat: Scroll buttons are now [|cFF99CC33OFF|r]")
				end
				StaticPopup_Show("XANCHAT_APPLYCHANGES")
				return true
			elseif c and c:lower() == "shortnames" then
				if XCHT_DB.shortNames then
					XCHT_DB.shortNames = false
					DEFAULT_CHAT_FRAME:AddMessage("xanChat: Short channel names are now [|cFF99CC33OFF|r]")
				else
					XCHT_DB.shortNames = true
					DEFAULT_CHAT_FRAME:AddMessage("xanChat: Short channel names are now [|cFF99CC33ON|r]")
				end
				StaticPopup_Show("XANCHAT_APPLYCHANGES")
				return true
			elseif c and c:lower() == "editbox" then
				if XCHT_DB.editBoxTop then
					XCHT_DB.editBoxTop = false
					setEditBox()
					DEFAULT_CHAT_FRAME:AddMessage("xanChat: The edit box is now at the [|cFF99CC33BOTTOM|r]")
				else
					XCHT_DB.editBoxTop = true
					setEditBox(true)
					DEFAULT_CHAT_FRAME:AddMessage("xanChat: The edit box is now at the [|cFF99CC33TOP|r]")
				end
				return true
			elseif c and c:lower() == "tabs" then
				if XCHT_DB.hideTabs then
					XCHT_DB.hideTabs = false
					DEFAULT_CHAT_FRAME:AddMessage("xanChat: The chat tabs are now [|cFF99CC33ON|r]")
				else
					XCHT_DB.hideTabs = true
					DEFAULT_CHAT_FRAME:AddMessage("xanChat: The chat tabs are now [|cFF99CC33OFF|r]")
				end
				StaticPopup_Show("XANCHAT_APPLYCHANGES")
				return true
			elseif c and c:lower() == "shadow" then
				if XCHT_DB.addFontShadow then
					XCHT_DB.addFontShadow = false
					DEFAULT_CHAT_FRAME:AddMessage("xanChat: Chat font shadows are now [|cFF99CC33OFF|r]")
				else
					XCHT_DB.addFontShadow = true
					DEFAULT_CHAT_FRAME:AddMessage("xanChat: Chat font shadows are now [|cFF99CC33ON|r]")
				end
				StaticPopup_Show("XANCHAT_APPLYCHANGES")
				return true
			elseif c and c:lower() == "voice" then
				if XCHT_DB.hideVoice then
					XCHT_DB.hideVoice = false
					DEFAULT_CHAT_FRAME:AddMessage("xanChat: Voice chat buttons are now [|cFF99CC33ON|r]")
				else
					XCHT_DB.hideVoice = true
					DEFAULT_CHAT_FRAME:AddMessage("xanChat: Voice chat buttons are now [|cFF99CC33OFF|r]")
					ChatFrameToggleVoiceDeafenButton:Hide()
					ChatFrameToggleVoiceMuteButton:Hide()
					ChatFrameChannelButton:Hide()
				end
				StaticPopup_Show("XANCHAT_APPLYCHANGES")
				return true
			end
		end

		DEFAULT_CHAT_FRAME:AddMessage("xanChat")
		DEFAULT_CHAT_FRAME:AddMessage("/xanchat social - toggles the chat social buttons")
		DEFAULT_CHAT_FRAME:AddMessage("/xanchat scroll - toggles the chat scroll bars")
		DEFAULT_CHAT_FRAME:AddMessage("/xanchat shortnames - toggles short channels names")
		DEFAULT_CHAT_FRAME:AddMessage("/xanchat editbox - toggles editbox to show at the top or the bottom")
		DEFAULT_CHAT_FRAME:AddMessage("/xanchat tabs - toggles the chat tabs on or off")
		DEFAULT_CHAT_FRAME:AddMessage("/xanchat shadow - toggles text shadows for chat fonts on or off")
		DEFAULT_CHAT_FRAME:AddMessage("/xanchat voice - toggles voice chat buttons on or off")
	end
	
	local ver = GetAddOnMetadata("xanChat","Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFF20ff20%s|r] Loaded", "xanChat", ver or "1.0"))

	eFrame:RegisterEvent("UI_SCALE_CHANGED")
	
	eFrame:UnregisterEvent("PLAYER_LOGIN")
end

--this is the fix for alt-tabbing resizing our chatboxes
function eFrame:UI_SCALE_CHANGED()
	for i = 1, NUM_CHAT_WINDOWS do
		local n = ("ChatFrame%d"):format(i)
		local f = _G[n]
		
		if f then
			--restore saved layout
			RestoreLayout(f)
			
			--restore any settings
			RestoreSettings(f, i)
			
			--always lock the frames regardless (using both calls just in case)
			SetChatWindowLocked(i, true)
			FCF_SetLocked(f, true)
		end
	end
end

if IsLoggedIn() then eFrame:PLAYER_LOGIN() else eFrame:RegisterEvent("PLAYER_LOGIN") end
