--Some stupid custom Chat modifications for me :P
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

------------------------------

function xanChat_doChat()
		
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
		local f = _G[("ChatFrame%d"):format(i)]

		--add more mouse wheel scrolling (alt key = scroll to top, ctrl = faster scrolling)
		f:EnableMouseWheel(true)
		f:SetScript('OnMouseWheel', scrollChat)
		f:SetMaxLines(250)
		
		local editBox = _G[("ChatFrame%dEditBox"):format(i)]

		if not editBox.left then
			editBox.left = _G[("ChatFrame%sEditBoxLeft"):format(i)]
			editBox.right = _G[("ChatFrame%sEditBoxRight"):format(i)]
			editBox.mid = _G[("ChatFrame%sEditBoxMid"):format(i)]
		end
		
		--remove alt keypress from the EditBox (no longer need alt to move around)
		editBox:SetAltArrowKeyMode(false)

		editBox.left:SetAlpha(0)
		editBox.right:SetAlpha(0)
		editBox.mid:SetAlpha(0)

		editBox.focusLeft:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Left2]])
		editBox.focusRight:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Right2]])
		editBox.focusMid:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Mid2]])
	end

end

function xanChat_CopyName(origin_frame, ...)
	print(a1)
	print(a2)
end

--URL COPY
local linklinkColor = "9ACD32"
local pattern = "[wWhH][wWtT][wWtT][\46pP]%S+[^%p%s]"

function string.linkColor(text, linkColor)
	return "|cff"..linkColor..text.."|r"
end

function string.link(text, type, value, linkColor)
	return "|H"..type..":"..tostring(value).."|h"..tostring(text):linkColor(linkColor or "ffffff").."|h"
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

local function fURL(url)
	return string.link("["..url.."]", "url", url, linkColor)
end

local function hook(self, text, ...)
	self:fURL(text:gsub(pattern, fURL), ...)
end

function LinkMeURL()
	for i = 1, NUM_CHAT_WINDOWS do
		if ( i ~= 2 ) then
			local frame = _G[("ChatFrame%d"):format(i)]
			frame.fURL = frame.AddMessage
			frame.AddMessage = hook
		end
	end
end
LinkMeURL()

local f = ChatFrame_OnHyperlinkShow
function ChatFrame_OnHyperlinkShow(self, link, text, button)
	local type, value = link:match("(%a+):(.+)")
	if ( type == "url" ) then
		local dialog = StaticPopup_Show("LINKME")
		local editbox = _G[dialog:GetName().."EditBox"]  
		editbox:SetText(value)
		editbox:SetFocus()
		editbox:HighlightText()
		local button = _G[dialog:GetName().."Button2"]
            
		button:ClearAllPoints()
           
		button:SetPoint("CENTER", editbox, "CENTER", 0, -30)
	else
		f(self, link, text, button)
	end
end

local eFrame = CreateFrame("frame","xanChatEventFrame",UIParent)
eFrame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

function eFrame:PLAYER_LOGIN()
	xanChat_doChat()
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

if IsLoggedIn() then eFrame:PLAYER_LOGIN() else eFrame:RegisterEvent("PLAYER_LOGIN") end
