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

function eFrame:PLAYER_LOGIN()

	--do the DB stuff
	if not XCHT_DB then XCHT_DB = {} end
	if XCHT_DB.hideSocial == nil then XCHT_DB.hideSocial = false end
	if XCHT_DB.hideScroll == nil then XCHT_DB.hideScroll = false end
	if XCHT_DB.shortNames == nil then XCHT_DB.shortNames = false end
	
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
			
			--hide the scroll bars
			if XCHT_DB.hideScroll then
				_G[n.."ButtonFrameUpButton"]:Hide()
				_G[n.."ButtonFrameUpButton"]:SetScript("OnShow", dummy)
				_G[n.."ButtonFrameDownButton"]:Hide()
				_G[n.."ButtonFrameDownButton"]:SetScript("OnShow", dummy)
				_G[n.."ButtonFrame"]:Hide()
				_G[n.."ButtonFrame"]:SetScript("OnShow", dummy)
			end
			
			--enable/disable short channel names by hooking into AddMessage
			if XCHT_DB.shortNames and not msgHooks[n] then
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
			end
		end

		DEFAULT_CHAT_FRAME:AddMessage("xanChat")
		DEFAULT_CHAT_FRAME:AddMessage("/xanchat social - toggles the chat social buttons")
		DEFAULT_CHAT_FRAME:AddMessage("/xanchat scroll - toggles the chat scroll bars")
		DEFAULT_CHAT_FRAME:AddMessage("/xanchat shortnames - toggles short channels names")
	end
	
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

if IsLoggedIn() then eFrame:PLAYER_LOGIN() else eFrame:RegisterEvent("PLAYER_LOGIN") end
