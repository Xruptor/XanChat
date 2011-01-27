--Some stupid custom Chat modifications for made for myself.
--Sharing it with the world in case anybody wants to actually use this.

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
--special thanks to Tekkub for tekPlayerMenu

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
	
local function insertbefore(t, before, val)
	for k,v in ipairs(t) do if v == before then return table.insert(t, k, val) end end
	table.insert(t, val)
end

local clickers = {["COPYNAME"] = function(a1) xanChat_DoCopyName(a1) end, ["WHO"] = SendWho, ["GUILD_INVITE"] = GuildInvite}

UnitPopupButtons["COPYNAME"] = {text = "Copy Name", dist = 0}
UnitPopupButtons["GUILD_INVITE"] = {text = "Guild Invite", dist = 0}
UnitPopupButtons["WHO"] = {text = "Who", dist = 0}

insertbefore(UnitPopupMenus["FRIEND"], "GUILD_PROMOTE", "GUILD_INVITE")
insertbefore(UnitPopupMenus["FRIEND"], "IGNORE", "COPYNAME")
insertbefore(UnitPopupMenus["FRIEND"], "IGNORE", "WHO")

hooksecurefunc("UnitPopup_HideButtons", function()
	local dropdownMenu = UIDROPDOWNMENU_INIT_MENU
	for i,v in pairs(UnitPopupMenus[dropdownMenu.which]) do
		if v == "GUILD_INVITE" then UnitPopupShown[i] = (not CanGuildInvite() or dropdownMenu.name == UnitName("player")) and 0 or 1
		elseif clickers[v] then UnitPopupShown[i] = (dropdownMenu.name == UnitName("player") and 0) or 1 end
	end
end)

hooksecurefunc("UnitPopup_OnClick", function(self)
	local dropdownFrame = UIDROPDOWNMENU_INIT_MENU
	local button = self.value
	if clickers[button] then clickers[button](dropdownFrame.name) end
	PlaySound("UChatScrollButton")
end)

function xanChat_DoCopyName(name) 
	local dialog = StaticPopup_Show("COPYNAME")
	local editbox = _G[dialog:GetName().."EditBox"]  
	editbox:SetText(name or "")
	editbox:SetFocus()
	editbox:HighlightText()
	local button = _G[dialog:GetName().."Button2"]
	button:ClearAllPoints()
	button:SetPoint("CENTER", editbox, "CENTER", 0, -30)
end

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

function xanChat_URLRef(link, text, button)
	if (strsub(link, 1, 3) == "url") then
		local url = strsub(link, 5)
	
		-- local activeWindow = ChatEdit_GetActiveWindow()
		
		-- if ( activeWindow ) then
			-- activeWindow:Insert(url)
			-- ChatEdit_FocusActiveWindow()
		-- else
			-- ChatEdit_GetLastActiveWindow():Show()
			-- ChatEdit_GetLastActiveWindow():Insert(url)
			-- ChatEdit_GetLastActiveWindow():SetFocus()
		-- end
		
		local dialog = StaticPopup_Show("LINKME")
		
		local editbox = _G[dialog:GetName().."EditBox"]  
		editbox:SetText(url)
		editbox:SetFocus()
		editbox:HighlightText()
		
		local button = _G[dialog:GetName().."Button2"]
		button:ClearAllPoints()
		button:SetPoint("CENTER", editbox, "CENTER", 0, -30)
		
	else
		SetItemRef_orig(link, text, button)
	end
end

SetItemRef = xanChat_URLRef

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

local eFrame = CreateFrame("frame","xanChatEvent_Frame",UIParent)
eFrame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

local dummy = function(self) self:Hide() end
local msgHooks = {}

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
		text = gsub(text, "%[%d+%. General.-%]", "[GN]")
		text = gsub(text, "%[%d+%. Trade.-%]", "[TR]")
		text = gsub(text, "%[%d+%. WorldDefense%]", "[WD]")
		text = gsub(text, "%[%d+%. LocalDefense.-%]", "[LD]")
		text = gsub(text, "%[%d+%. LookingForGroup%]", "[LFG]")
		text = gsub(text, "%[%d+%. GuildRecruitment.-%]", "[GR]")
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
local function SaveLayout(obj)
	if (type(obj) == 'table') then obj = obj:GetName() end --get the name if a frame was passed
	if not obj then return end
	if not XCHT_DB.frames then XCHT_DB.frames = {} end
	if not XCHT_DB.frames[obj] then XCHT_DB.frames[obj] = {} end

	--don't reposition docked chatframe, in fact delete them.  Make sure it's not the primary dock window
	if _G[obj] ~= GENERAL_CHAT_DOCK.primary then
		if ( _G[obj].isDocked ) then
			XCHT_DB.frames[obj] = nil
			return
		end
	end

	local point,relativeTo,relativePoint,xOfs,yOfs = _G[obj]:GetPoint()

	XCHT_DB.frames[obj].point = point
	XCHT_DB.frames[obj].relativePoint = relativePoint
	XCHT_DB.frames[obj].xOfs = xOfs
	XCHT_DB.frames[obj].yOfs = yOfs
end

local function RestoreLayout(obj)
	if not obj then return end
	if not XCHT_DB.frames then XCHT_DB.frames = {} end
	if not XCHT_DB.frames[obj] then return end
	
	--don't reposition docked chatframe, in fact delete them.  Make sure it's not the primary dock window
	if _G[obj] ~= GENERAL_CHAT_DOCK.primary then
		if ( _G[obj].isDocked ) then
			XCHT_DB.frames[obj] = nil
			return
		end
	end

	_G[obj]:ClearAllPoints()
	_G[obj]:SetPoint( XCHT_DB.frames[obj].point, UIParent, XCHT_DB.frames[obj].relativePoint, XCHT_DB.frames[obj].xOfs, XCHT_DB.frames[obj].yOfs )
end

--hook origFCF_SavePositionAndDimensions
local origFCF_SavePositionAndDimensions = FCF_SavePositionAndDimensions
FCF_SavePositionAndDimensions = function(chatFrame)
	SaveLayout(chatFrame:GetName())
	origFCF_SavePositionAndDimensions(chatFrame)
end

--This is just in case the client is being mean and resetting the chatframes at loading screens or entering/leaving instances (zones)
-- function eFrame:PLAYER_ENTERING_WORLD()
	-- for i = 1, NUM_CHAT_WINDOWS do
		-- local n = ("ChatFrame%d"):format(i)
		-- RestoreLayout(n)
	-- end
-- end

--[[------------------------
	PLAYER_LOGIN
--------------------------]]
function eFrame:PLAYER_LOGIN()

	--do the DB stuff
	if not XCHT_DB then XCHT_DB = {} end
	if XCHT_DB.hideSocial == nil then XCHT_DB.hideSocial = false end
	if XCHT_DB.hideScroll == nil then XCHT_DB.hideScroll = false end
	if XCHT_DB.shortNames == nil then XCHT_DB.shortNames = false end
	if XCHT_DB.editBoxTop == nil then XCHT_DB.editBoxTop = false end
	if XCHT_DB.hideTabs == nil then XCHT_DB.hideTabs = false end
	
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
			--add more mouse wheel scrolling (alt key = scroll to top, ctrl = faster scrolling)
			f:EnableMouseWheel(true)
			f:SetScript('OnMouseWheel', scrollChat)
			--f:SetMaxLines(500)
			
			--this allows the chatframe to be put in the corners of the screen (or at the edge)
			f:SetClampRectInsets(0,0,0,0)
			
			local editBox = _G[n.."EditBox"]

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
			
			--delete old DB
			if XCHT_DB[n] then XCHT_DB[n] = nil end
			
			--finally restore whatever stored position the chatframes were moved to by the user
			RestoreLayout(n)
		end
		
	end

	--show/hide the chat social buttons
	if XCHT_DB.hideSocial then
		ChatFrameMenuButton:Hide()
		ChatFrameMenuButton:SetScript("OnShow", dummy)
		FriendsMicroButton:Hide()
		FriendsMicroButton:SetScript("OnShow", dummy)
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
					DEFAULT_CHAT_FRAME:AddMessage("xanChat: The chat tabs are now[|cFF99CC33OFF|r]")
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
	end
	
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

if IsLoggedIn() then eFrame:PLAYER_LOGIN() else eFrame:RegisterEvent("PLAYER_LOGIN") end
