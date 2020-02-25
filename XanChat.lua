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

local addonLoaded = false

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

--register them all
for group, values in pairs(ChatTypeGroup) do
	for _, value in pairs(values) do
		ChatFrame_AddMessageEventFilter(value, urlFilter)
	end
end

--[[------------------------
	Extra Player Info
--------------------------]]
--https://www.wowinterface.com/forums/showthread.php?t=39328

-- function playerInfoFilter(self, event, msg, author, ...)
	-- --Debug(self, event, msg, author)
	-- return false
-- end

--register them all
-- for group, values in pairs(ChatTypeGroup) do
	-- for _, value in pairs(values) do
		-- ChatFrame_AddMessageEventFilter(value, playerInfoFilter)
	-- end
-- end

local function ToHex(r, g, b, a)
	return string.format('%02X%02X%02X%02X', a * 255, r * 255, g * 255, b * 255)
end

function parsePlayerInfo(frame, text, ...)
	--local red, green, blue, messageId, holdTime = ...
	text = text or "" --fix string just in case, avoid nulls
	local playerLink, player, pmsg = string.match(text, "|Hplayer:(.-)|h%[(.-)%]|h(.+)")
	if playerLink then
		--local playerName, playerServer = playerLink:match("([^%-]+)%-?(.*)")
		local playerLevel = 120
		local colorFunc = GetQuestDifficultyColor or GetDifficultyColor
		local color = colorFunc(playerLevel)
		if color then
			--local colorCode = RGBTableToColorCode(colorFunc(playerLevel))
			local colorCode = ToHex(color.r, color.g, color.b, 1)
			if colorCode then
				playerLevel = "|c"..colorCode..playerLevel.."|r"
				return "|Hplayer:"..playerLink.."|h["..player.."]|h", "|Hplayer:"..playerLink.."|h["..playerLevel..":"..player.."]|h", playerLink, player
			end
		end
	end
	Debug(playerLink, player, pmsg, playerName, playerServer)
end

--string.gsub has issues with special characters when doing replaces. So use this instead
function plainTextReplace(text, old, new)
	local b, e = text:find(old, 1, true)
	if b == nil then
		return text
	else
		return text:sub(1,b-1)..new..text:sub(e+1)
	end
end

function stripAndLowercase(text)
	text = string.lower(text)
	text = text:gsub("%s+", "") --remove empty spaces
	return text
end

function addToPlayerList(name, realm, level, class, BNname)
	if not name or not level or not class then return end
	if not addon.playerList then addon.playerList = {} end
	if not realm then realm = GetRealmName() end
	addon.playerList[name.."@"..stripAndLowercase(realm)] = {name=name, realm=realm, stripRealm=stripAndLowercase(realm), level=level, class=class, BNname=BNname}
end

function initUpdateCurrentPlayer()
	local class = select(2, UnitClass("player"))
	local name, realm = UnitName("player")
	local level = UnitLevel("player")
	--Debug('player', name, realm, level, class)
	addToPlayerList(name, realm, level, class)
end

local function doRaidUpdate()
	local GetNumRaidMembers = GetNumGroupMembers or GetNumRaidMembers
	for i = 1, GetNumRaidMembers() do
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
		local playerName, playerServer = UnitName("raid"..i)
		if playerName and playerServer then
			--Debug('raid1', playerName, playerServer, level, class)
			addToPlayerList(playerName, playerServer, level, class)
		else
			--Debug('raid2', name, GetRealmName(), level, class)
			addToPlayerList(name, GetRealmName(), level, class)
		end
	end
end
local function doPartyUpdate()
	--GetNumPartyMembers was replaced so lets check for that
	local GetNumPartyMembers = GetNumSubgroupMembers or GetNumPartyMembers
	for i = 1, GetNumPartyMembers() do
		local unit = "party" .. i
		local _, class = UnitClass(unit)
		local name, server = UnitName(unit)
		local level = UnitLevel(unit)
		--Debug('party', name, server or GetRealmName(), level, class)
		addToPlayerList(name, server or GetRealmName(), level, class)
	end
end

local function doFriendUpdate()
	for i = 1, C_FriendList.GetNumFriends() do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		--make sure they are online
		if info and info.connected then
			--Debug('friend', info.name, GetRealmName(), info.level, info.className)
			addToPlayerList(info.name, GetRealmName(), info.level, info.className)
		end
	end
	
	local numBNet, onlineBNet = BNGetNumFriends()
	for i = 1, numBNet do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		local friendInfo = accountInfo.gameAccountInfo
		--make sure they are online and playing WOW
		if friendInfo and friendInfo.isOnline and friendInfo.clientProgram == BNET_CLIENT_WOW then
			--Whether or not the friend is known by their BattleTag
			local friendAccountName = accountInfo.isBattleTagFriend and accountInfo.battleTag or accountInfo.accountName
			
			if friendInfo.characterName and friendInfo.realmName and friendInfo.className and friendInfo.characterLevel then
				addToPlayerList(friendInfo.characterName, friendInfo.realmName, friendInfo.characterLevel, friendInfo.className, friendAccountName)
			end
		end
	end
end

function addon:FRIENDLIST_UPDATE()
	doFriendUpdate()
end

function addon:BN_FRIEND_ACCOUNT_ONLINE()
	doFriendUpdate()
end

function addon:GUILD_ROSTER_UPDATE()
	if IsInGuild()  then
		C_GuildInfo.GuildRoster()
		for i = 1, GetNumGuildMembers(true) do
			local name, _, _, level, _, _, _, _, online, _, class = GetGuildRosterInfo(i)
			if online then
				--only do online players
				local playerName, playerServer = name:match("([^%-]+)%-?(.*)")
				if playerName and playerServer then
					--Debug('guild1', playerName, playerServer, level, class)
					addToPlayerList(playerName, playerServer, level, class)
				else
					--Debug('guild2', name, GetRealmName(), level, class)
					addToPlayerList(name, GetRealmName(), level, class)
				end
			end
		end
	end
end

function addon:RAID_ROSTER_UPDATE()
	doRaidUpdate()
end

function addon:GROUP_ROSTER_UPDATE()
	doRaidUpdate()
	doPartyUpdate()
end

function addon:PARTY_MEMBERS_CHANGED()
	doPartyUpdate()
end

function addon:PLAYER_LEVEL_UP()
	initUpdateCurrentPlayer()
end

function initPlayerInfo()
    addon:RegisterEvent("FRIENDLIST_UPDATE")
	addon:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
    addon:RegisterEvent("GUILD_ROSTER_UPDATE")
    addon:RegisterEvent("RAID_ROSTER_UPDATE")
	
	--added in 5.0.4 to replace PARTY_MEMBERS_CHANGED and RAID_ROSTER_UPDATE
    if select(4, GetBuildInfo()) >= 50000 then
		addon:RegisterEvent("GROUP_ROSTER_UPDATE")
    end
	--this was removed in patch 8.0.1 so lets check for it
    if select(4, GetBuildInfo()) < 80000 and select(4, GetBuildInfo()) >= 20000 then
		addon:RegisterEvent("PARTY_MEMBERS_CHANGED")
    end
    addon:RegisterEvent("PLAYER_LEVEL_UP")
end

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
	if XCHT_DB.shortNames and type(text) == "string" then
		local chatNum = string.match(text,"%d+") or ""
		if not tonumber(chatNum) then chatNum = "" else chatNum = chatNum..":" end
		text = gsub(text, L.ChannelGeneral, "["..chatNum..L.ShortGeneral.."]")
		text = gsub(text, L.ChannelTrade, "["..chatNum..L.ShortTrade.."]")
		text = gsub(text, L.ChannelWorldDefense, "["..chatNum..L.ShortWorldDefense.."]")
		text = gsub(text, L.ChannelLocalDefense, "["..chatNum..L.ShortLocalDefense.."]")
		text = gsub(text, L.ChannelLookingForGroup, "["..chatNum..L.ShortLookingForGroup.."]")
		text = gsub(text, L.ChannelGuildRecruitment, "["..chatNum..L.ShortGuildRecruitment.."]")
	end
	--The string.find method provides an optional 4th parameter to enforce a plaintext search by itself.
	if XCHT_DB.enableExtraPlayerInfo and type(text) == "string" and string.find(text, "|Hplayer:", 1, true) then
		local old, new, playerLink, player = parsePlayerInfo(frame, text, ...)
		if old and new and string.find(text, old, 1, true) then
			--Debug('replacing', old, new, playerLink, string.find(text, playerLink), gsub(text, "|", "!"))
			--Debug('found', playerLink, string.find(text, playerLink), gsub(text, "|", "!"))
			text = plainTextReplace(text, old, new)
		end
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
	if not addonLoaded then return end
	if not chatFrame then return end
	
	if not XCHT_DB then return end
	if not XCHT_DB.frames then XCHT_DB.frames = {} end
	if not XCHT_DB.frames[chatFrame:GetID()] then XCHT_DB.frames[chatFrame:GetID()] = {} end
	
	if chatFrame.isMoving or chatFrame.isDragging then return end

	local db = XCHT_DB.frames[chatFrame:GetID()]

	local point, relativeTo, relativePoint, xOffset, yOffset = chatFrame:GetPoint()
	
	--error check for invalid object type for relativeTo
	if relativeTo == nil then
		relativeTo = "UIParent"
	elseif type(relativeTo) == "table" then
		relativeTo = relativeTo:GetName() or "UIParent"
	end

	db.point = point
	--relativeTo returns the actual object, we just want the name
	db.relativeTo = relativeTo
	db.relativePoint = relativePoint
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
	if not chatFrame:IsMouseEnabled() then
		chatFrame:EnableMouse(true)
	end
 	
 	if ( chatFrame:IsMovable() and db.point and db.xOffset) then
		chatFrame:SetUserPlaced(true)
		
		--error check for invalid object type for relativeTo
		if db.relativeTo == nil or type(db.relativeTo) == "table" then db.relativeTo = "UIParent" end --reset it if it's a table, we just want the name
		
		--don't move docked chats
		if chatFrame == DEFAULT_CHAT_FRAME or not chatFrame.isDocked or not db.windowInfo[9] then
			chatFrame:ClearAllPoints()
			chatFrame:SetPoint(db.point, _G[db.relativeTo], db.relativePoint, db.xOffset, db.yOffset)
		else
			FCF_DockFrame(chatFrame, db.windowInfo[9])
		end
	
 	end
	
	if sSwitch then
		chatFrame:SetMovable(false)
	end
end

local function SaveSettings(chatFrame)
	if not addonLoaded then return end
	if not chatFrame then return end
	
	if not XCHT_DB then return end
	if not XCHT_DB.frames then return end
	if not XCHT_DB.frames[chatFrame:GetID()] then return end

	if chatFrame.isMoving or chatFrame.isDragging then return end

	local db = XCHT_DB.frames[chatFrame:GetID()]
	
	local name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable = GetChatWindowInfo(chatFrame:GetID())
	local windowMessages = { GetChatWindowMessages(chatFrame:GetID())}
	local windowChannels = { GetChatWindowChannels(chatFrame:GetID())}

	db.chatParent = chatFrame:GetParent():GetName()
	db.windowInfo = {name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable}
	db.windowMessages = windowMessages
	db.windowChannels = windowChannels	
	
end

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
		SetChatWindowSize(chatFrame:GetID(), db.windowInfo[2])
		SetChatWindowColor(chatFrame:GetID(), db.windowInfo[3], db.windowInfo[4], db.windowInfo[5])
		SetChatWindowAlpha(chatFrame:GetID(), db.windowInfo[6])
		SetChatWindowShown(chatFrame:GetID(), db.windowInfo[7])
		SetChatWindowLocked(chatFrame:GetID(), db.windowInfo[8])
		SetChatWindowDocked(chatFrame:GetID(), db.windowInfo[9])
		SetChatWindowUninteractable(chatFrame:GetID(), db.windowInfo[10])
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

--hook origFCF_SavePositionAndDimensions
local origFCF_SavePositionAndDimensions = FCF_SavePositionAndDimensions
FCF_SavePositionAndDimensions = function(chatFrame)
    SaveLayout(chatFrame)
    SaveSettings(chatFrame)
    origFCF_SavePositionAndDimensions(chatFrame)
end

--hook old toggle
local origFCF_ToggleLock = FCF_ToggleLock
FCF_ToggleLock = function()
    local chatFrame = FCF_GetCurrentChatFrame()
    if chatFrame then
        SaveLayout(chatFrame)
        SaveSettings(chatFrame)
    end
    origFCF_ToggleLock()
end

hooksecurefunc("ToggleChatMessageGroup", doValueUpdate)
hooksecurefunc("ToggleMessageSource", doValueUpdate)
hooksecurefunc("ToggleMessageDest", doValueUpdate)
hooksecurefunc("ToggleMessageTypeGroup", doValueUpdate)
hooksecurefunc("ToggleMessageType", doValueUpdate)
hooksecurefunc("ToggleChatChannel", doValueUpdate)
hooksecurefunc("ToggleChatColorNamesByClassGroup", doValueUpdate)


--[[------------------------
	CHAT COPY
--------------------------]]

local function CreatCopyFrame()
	--check to see if we have the frame already, if we do then return it
	if addon.copyFrame then return addon.copyFrame end

	local frame = CreateFrame("Frame", "xanChatCopyFrame", UIParent)
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",    
		edgeSize = 10, 
		insets = {top = -1, left = -1, bottom = -1, right = -1}
	})
	
	frame:SetBackdropColor(0, 0, 0, .5)
	frame:SetWidth(600)
	frame:SetHeight(400)
	frame:SetPoint("CENTER", UIParent, "CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	tinsert(UISpecialFrames, "xanChatCopyFrame")
	frame:Hide()

	local scrollArea = CreateFrame("ScrollFrame", "xanChatCopyScroll", frame, "InputScrollFrameTemplate")
	scrollArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -32)
	scrollArea:SetBackdrop(nil)
	scrollArea.CharCount:Hide()
	scrollArea:SetHeight(frame:GetHeight() - 41)
	scrollArea:SetWidth(frame:GetWidth() - 16)

	--remove the stupid textures
	scrollArea.BottomLeftTex:SetTexture(nil)
	scrollArea.BottomRightTex:SetTexture(nil)
	scrollArea.BottomTex:SetTexture(nil)
	scrollArea.LeftTex:SetTexture(nil)
	scrollArea.RightTex:SetTexture(nil)
	scrollArea.MiddleTex:SetTexture(nil)
	scrollArea.TopLeftTex:SetTexture(nil)
	scrollArea.TopRightTex:SetTexture(nil)
	scrollArea.TopTex:SetTexture(nil)
	frame.copyScrollArea = scrollArea
	scrollArea:Show()
	
	scrollArea.EditBox:SetFont("Fonts\\ARIALN.ttf", 15)
	scrollArea.EditBox:SetText("")
	scrollArea.EditBox:SetWidth(scrollArea:GetWidth() - 15)
	scrollArea.EditBox:SetBackdrop(nil)
	frame.editBox = scrollArea.EditBox
	
	local close = CreateFrame("Button", "iCopyCloseButton", frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	frame.close = close
	
	frame:Show()
	
	--store it for the future
	addon.copyFrame = frame
	
	return frame
end

local function GetChatText(id)

	local copyFrame = CreatCopyFrame()
	copyFrame.editBox:SetText("") --clear it first in case there were previous messages
	
	local msgCount = _G["ChatFrame" .. id]:GetNumMessages()
	local motdString = COMMUNITIES_MESSAGE_OF_THE_DAY_FORMAT:gsub("\"%%s\"", "")
	
	for i = 1, msgCount do
		local chatMsg, r, g, b, chatTypeID = _G["ChatFrame"..id]:GetMessageInfo(i)
		
		--fix situations where links end the color prematurely
		if (r and g and b and chatTypeID) then
			local colorCode = RGBToColorCode(r, g, b)
			chatMsg = string.gsub(chatMsg, "|r", "|r"..colorCode)
			chatMsg = colorCode..chatMsg
		end
		
		--sometimes the guild motd doesn't color, so fix it
		if IsInGuild() then
			--check for our MOTD
			if string.find(chatMsg, GUILD.." "..motdString)then
				chatMsg = RGBTableToColorCode(ChatTypeInfo.GUILD)..chatMsg
			end
		end
		
		--if it's the first line don't start with newline
		if (i == 1) then
			copyFrame.editBox:Insert(chatMsg.."|r")
		else
			copyFrame.editBox:Insert("\n"..chatMsg.."|r")
		end	
	end
	
	copyFrame:Show()
end

local function CreateCopyChatButtons(i)

	local copyFrame = CreatCopyFrame()
	
	local obj = CreateFrame("Button", "xanCopyChatButton"..i, _G['ChatFrame'..i])
	obj.bg = obj:CreateTexture(nil,	"ARTWORK")
	obj.bg:SetTexture("Interface\\AddOns\\xanChat\\media\\copy")
	obj.bg:SetAllPoints(obj)
	obj:SetPoint("BOTTOMRIGHT", -2, -3)
	obj.texture = obj.bg
	obj:SetFrameLevel(7)
	obj:SetWidth(18)
	obj:SetHeight(18)
	obj:Hide()
	obj:SetScript("OnClick", function(self, arg)
		if (copyFrame:IsVisible()) then
    		copyFrame:Hide()
    	else
			--this allows it to refresh if we hide the window
			GetChatText(i)
		end
	end)

	_G['ChatFrame'..i]:SetScript("OnEnter", function(self)
		if (XCHT_DB.enableCopyButton) then
			obj:Show()
		end
	end)
	_G['ChatFrame'..i]:SetScript("OnLeave", function(self)
		obj:Hide()
	end)
	_G['ChatFrame'..i].ScrollToBottomButton:SetScript("OnEnter", function(self)
		if (XCHT_DB.enableCopyButton) then
			obj:Show()
		end
	end)
	_G['ChatFrame'..i].ScrollToBottomButton:SetScript("OnLeave", function(self)
		obj:Hide()
	end)
	
	--prevent object blinking because chat continues to scroll
	function obj.show()
		obj:Show()
	end
	function obj.hide()
		obj:Hide()
	end
	
	obj:SetScript("OnEnter", obj.show)
	obj:SetScript("OnLeave", obj.hide)
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
	if XCHT_DB.hideEditboxBorder == nil then XCHT_DB.hideEditboxBorder = false end
	if XCHT_DB.enableSimpleEditbox == nil then XCHT_DB.enableSimpleEditbox = true end
	if XCHT_DB.enableCopyButton == nil then XCHT_DB.enableCopyButton = true end
	if XCHT_DB.enableExtraPlayerInfo == nil then XCHT_DB.enableExtraPlayerInfo = true end
	
	--setup the history DB
	if not XCHT_HISTORY then XCHT_HISTORY = {} end
	XCHT_HISTORY[currentRealm] = XCHT_HISTORY[currentRealm] or {}
	XCHT_HISTORY[currentRealm][currentPlayer] = XCHT_HISTORY[currentRealm][currentPlayer] or {}
	HistoryDB = XCHT_HISTORY[currentRealm][currentPlayer]
	
	--iniate playerInfo events
	initPlayerInfo()
    if IsInGuild() then
      C_GuildInfo.GuildRoster()
    end
	initUpdateCurrentPlayer()
	
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
		local fTab = _G[n.."Tab"]
		
		if f then
			--create the copy chat buttons
			CreateCopyChatButtons(i)
		
			XANCHAT_Frame = XANCHAT_Frame or {}
			XANCHAT_Frame[i] = f

			--restore any settings
			RestoreSettings(f)
			
			--restore saved layout
			RestoreLayout(f)
			
			--ChatFrame
			f:HookScript("OnMouseDown", function(self, button)
				if not f.isMoving and not f.isLocked then
					f.isMoving = true
					self:StartMoving()
				end
			end)
			f:HookScript("OnMouseUp", function(self, button)
				if f.isMoving then
					f.isMoving = false
					self:StopMovingOrSizing()
				end
			end)
			f:HookScript("OnDragStart", function(self, button)
				if not f.isDragging and not f.isLocked then
					f.isDragging = true
					self:StartMoving()
				end
			end)
			f:HookScript("OnDragStop", function(self, button)
				if f.isDragging then
					f.isDragging = false
					self:StopMovingOrSizing()
				end
			end)
			
			--ChatFrame
			hooksecurefunc(f, "StopMovingOrSizing", function(self)
				SaveLayout(f)
				SaveSettings(f)
			end)
			--Tab
			hooksecurefunc(fTab, "StopMovingOrSizing", function(self)
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
				
				local editBoxBackdrop = {
					bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
					edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
					insets = { left = 3, right = 3, top = 3, bottom = 3 }
				}

				if XCHT_DB.enableSimpleEditbox then
					editBox.focusLeft:SetTexture(nil)
					editBox.focusRight:SetTexture(nil)
					editBox.focusMid:SetTexture(nil)
					editBox:SetBackdrop(editBoxBackdrop)
					editBox:SetBackdropColor(0, 0, 0, 0.6)
					editBox:SetBackdropBorderColor(0.6, 0.6, 0.6)
					
				elseif not XCHT_DB.hideEditboxBorder then
					editBox.focusLeft:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Left2]])
					editBox.focusRight:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Right2]])
					editBox.focusMid:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Mid2]])
				else
					editBox.focusLeft:SetTexture(nil)
					editBox.focusRight:SetTexture(nil)
					editBox.focusMid:SetTexture(nil)
				end
				
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
			if f ~= COMBATLOG and not msgHooks[n] then
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
			elseif c and c:lower() == L.SlashEditBoxBorder then
				addon.aboutPanel.btnEditBoxBorder.func(true)
				return true
			elseif c and c:lower() == L.SlashSimpleEditBox then
				addon.aboutPanel.btnSimpleEditBox.func(true)
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
		DEFAULT_CHAT_FRAME:AddMessage(preText..L.SlashEditBoxBorder.." - "..L.SlashEditBoxBorderInfo)
		DEFAULT_CHAT_FRAME:AddMessage(preText..L.SlashSimpleEditBox.." - "..L.SlashSimpleEditBoxInfo)
	end
	
	local ver = GetAddOnMetadata(ADDON_NAME,"Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFF20ff20%s|r] loaded:   /xanchat", ADDON_NAME, ver or "1.0"))
	
	addon:RegisterEvent("UI_SCALE_CHANGED")
	
	addon:UnregisterEvent("PLAYER_LOGIN")
	
	addonLoaded = true
end

--this is the fix for alt-tabbing resizing our chatboxes
function addon:UI_SCALE_CHANGED()
	for i = 1, NUM_CHAT_WINDOWS do
		local n = ("ChatFrame%d"):format(i)
		local f = _G[n]
		
		if f then
		
			--restore any settings
			RestoreSettings(f)
			
			--restore saved layout
			RestoreLayout(f)
			
			--always lock the frames regardless (using both calls just in case)
			SetChatWindowLocked(i, true)
			FCF_SetLocked(f, true)
		end
	end
end

if IsLoggedIn() then addon:PLAYER_LOGIN() else addon:RegisterEvent("PLAYER_LOGIN") end
