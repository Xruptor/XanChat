local ADDON_NAME, private = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
local addon = _G[ADDON_NAME]
addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

local WOW_PROJECT_ID = _G.WOW_PROJECT_ID
local WOW_PROJECT_MAINLINE = _G.WOW_PROJECT_MAINLINE
local WOW_PROJECT_CLASSIC = _G.WOW_PROJECT_CLASSIC
--local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local WOW_PROJECT_WRATH_CLASSIC = _G.WOW_PROJECT_WRATH_CLASSIC

addon.IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
addon.IsClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
--BSYC.IsTBC_C = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
addon.IsWLK_C = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

local L = addon.L
local strfind = string.find
local strsub = string.sub
local strmatch = string.match
local gsub = string.gsub
local strlen = string.len
local tinsert = table.insert
local tremove = table.remove

local EXTRA_CHAT_FILTER_EVENTS = {
	"CHAT_MSG_ADDON",
	"CHAT_MSG_ADDON_LOGGED",
	"CHAT_MSG_BATTLEGROUND",
	"CHAT_MSG_BATTLEGROUND_LEADER",
	"CHAT_MSG_BN_CONVERSATION",
	"CHAT_MSG_BN_CONVERSATION_LIST",
	"CHAT_MSG_BN_CONVERSATION_NOTICE",
	"CHAT_MSG_BN_INLINE_TOAST_CONVERSATION",
}

local SHORT_CHANNEL_REPLACEMENTS = {
	{ L.ChannelGeneral, L.ShortGeneral },
	{ L.ChannelTradeServices, L.ShortTradeServices },
	{ L.ChannelTrade, L.ShortTrade },
	{ L.ChannelWorldDefense, L.ShortWorldDefense },
	{ L.ChannelLocalDefense, L.ShortLocalDefense },
	{ L.ChannelLookingForGroup, L.ShortLookingForGroup },
	{ L.ChannelGuildRecruitment, L.ShortGuildRecruitment },
	{ L.ChannelNewComerChat, L.ShortNewComerChat },
}

local function RegisterChatFilters(filterFunc)
	for group, values in pairs(ChatTypeGroup) do
		for _, value in pairs(values) do
			ChatFrame_AddMessageEventFilter(value, filterFunc)
		end
	end
	for _, eventName in ipairs(EXTRA_CHAT_FILTER_EVENTS) do
		ChatFrame_AddMessageEventFilter(eventName, filterFunc)
	end
end

local URL_PATTERNS = {
	{ "(%a+)://(%S+)%s?", "%1://%2" },
	{ "www%.([_A-Za-z0-9-]+)%.(%S+)%s?", "www.%1.%2" },
	{ "([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?", "%1@%2%3%4" },
	{ "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?):(%d%d?%d?%d?%d?)%s?", "%1.%2.%3.%4:%5" },
	{ "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?", "%1.%2.%3.%4" },
	{ "[wWhH][wWtT][wWtT][\46pP]%S+[^%p%s]", "%1" },
}

function addon:OnLoad()
	-- wrapper lifecycle hook (ADDON_LOADED)
end

function addon:OnEnable()
	self:EnableAddon()
end

--[[------------------------
	Scrolling and Chat Links
--------------------------]]

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

--[[------------------------
	URL COPY
--------------------------]]

local function doColor(url)
	url = " |cff99FF33|Hurl:"..url.."|h["..url.."]|h|r "
	return url
end

local function urlFilter(self, event, msg, author, ...)
	for i = 1, #URL_PATTERNS do
		local pattern, replacement = URL_PATTERNS[i][1], URL_PATTERNS[i][2]
		if strfind(msg, pattern) then
			return false, gsub(msg, pattern, doColor(replacement)), author, ...
		end
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
RegisterChatFilters(urlFilter)

--[[------------------------
	Stylized Player Names
--------------------------]]
--https://www.wowinterface.com/forums/showthread.php?t=39328

local messageIndex = 0
local lastMsgEvent = {}

local function playerInfoFilter(self, event, msg, author, arg1, arg2, arg3, ...)
	if not addon.isFilterListEnabled or not XCHT_DB.enablePlayerChatStyle then return false end
	--capture the events for AddMessage since they aren't forwarded.  Filters always go first before AddMessage
	--use a messageIndex to keep track when messages are filtered or not, otherwise AddMessage can have something sent that didn't go through these filters.
	messageIndex = messageIndex + 1
	lastMsgEvent = {event=event, msg=msg, author=author, messageIndex=messageIndex, arg1=arg1, arg2=arg2, arg3=arg3}
	return false
end

--register them all
RegisterChatFilters(playerInfoFilter)

local function ToHex(r, g, b, a)
	return string.format('%02X%02X%02X%02X', a * 255, r * 255, g * 255, b * 255)
end

--this is used as a super last resort
local function slowPlayerLinkStrip(msg)
	if not msg then return end

	local newMsg = msg
	local playerLink, player
	local p1_Start, p1_End
	local p2_Start, p2_End
	local p3_Start, p3_End

	--lets grab the first part
	p1_Start, p1_End = strfind(newMsg, "|Hplayer:", 1, true)

	--do we have anything to work with on first part
	if p1_Start and p1_End then
		--lets edit the message and move the pointer forward
		newMsg = newMsg:sub(p1_End + 1)

		--lets grab the second part
		if newMsg then
			p2_Start, p2_End = strfind(newMsg, "|h[", 1, true)
		end

		--do we have anything to work with on second part
		if p2_Start and p2_End then

			--first grab the playerLink
			playerLink = newMsg:sub(1, p2_Start - 1)
			--now move the pointer forward
			newMsg = newMsg:sub(p2_End + 1)

			--finally check for our third part
			if newMsg then
				p3_Start, p3_End = strfind(newMsg, "]|h", 1, true)
			end

			--do we have anything to work with?
			if p3_Start and p3_End then
				player = newMsg:sub(1, p3_Start - 1)

				--if we have playerlink and player then return it, otherwise nil
				if playerLink and player then
					return playerLink, player
				end
			end

		end

	end

end

--string.gsub has issues with special characters when doing replaces. So use this instead
local function plainTextReplace(text, old, new)
	local b, e = text:find(old, 1, true)
	if b == nil then
		return text, false
	else
		return text:sub(1,b-1)..new..text:sub(e+1), true
	end
end

local function stripAndLowercase(text)
	text = string.lower(text)
	text = text:gsub("%s+", "") --remove empty spaces
	return text
end

local function ContainsWholeWord(input, word)
	--return string.find(input, "%f[%a]" .. word .. "%f[%A]")
	return strfind(input, "%f[^%z%s]"..word.."%f[%z%s]")
end

local function replaceText(source, findStr, replaceStr, wholeword)
	if wholeword then
		--findStr = '%f[%a]'..findStr..'%f[%A]'  --does not properly escape certain characters like : and /
		findStr = "%f[^%z%s]"..findStr.."%f[%z%s]"
	end
	return (source:gsub(findStr, replaceStr))
end

local function parsePlayerInfo(frame, text, ...)
	--local red, green, blue, messageId, holdTime = ...
	text = text or "" --fix string just in case, avoid nulls
	local playerLink, player, pmsg

	playerLink, player, pmsg = strmatch(text, "|Hplayer:(.-)|h%[(.-)%]|h(.+)")

	if not playerLink or not player then
		--only use this if top fails
		playerLink, player = slowPlayerLinkStrip(text)
	end

	--gsub(message, '|HBNplayer:(.-)|h%[(.-)%]|h', FormatBNPlayer)
	if playerLink and player then
		--check if our actual player has a hyphen server
		local chkPlayer, chkServer = player:match("([^%-]+)%-?(.*)")
		local linkName, linkMessageID, linkChannel = strsplit(":", playerLink)
		local playerName, playerServer

		if linkName then
			playerName, playerServer = linkName:match("([^%-]+)%-?(.*)")

			if not playerName or not playerServer then
				if chkPlayer and chkServer and strlen(chkPlayer) > 0 and strlen(chkServer) > 0 then
					playerName = chkPlayer
					playerServer = chkServer
				else
					--last case scenario, using a really crappy method
					local findFirst = strfind(linkName, "-", 1, true)
					if findFirst then
						playerName = strsub(linkName, 1, findFirst - 1)
						playerServer = strsub(linkName, findFirst + 1)
					else
						--didn't find anything, so give up
						return
					end
				end
			end
		end
		if not playerName or not playerServer then return end
		if strlen(playerName) <= 0 or strlen(playerServer) <= 0 then return end

		local playerInfo

		--lets check our list
		if addon.playerList[playerName.."@"..stripAndLowercase(playerServer)] then
			playerInfo = addon.playerList[playerName.."@"..stripAndLowercase(playerServer)]
		elseif addon.playerList[playerName.."@"..playerServer] then
			playerInfo = addon.playerList[playerName.."@"..playerServer]
		elseif addon.playerList[stripAndLowercase(playerName).."@"..stripAndLowercase(playerServer)] then
			playerInfo = addon.playerList[stripAndLowercase(playerName).."@"..stripAndLowercase(playerServer)]
		else
			--last resort for playername checking
			for k, v in pairs(addon.playerList) do
				--just in case
				if k and v then
					local pN, pR = strsplit("@", k)
					if pN and pR and pN == playerName then
						playerInfo = v
						break
					end
				end
			end
		end
		if not playerInfo then return end

		--Debug(playerInfo.name, playerInfo.realm, playerInfo.level, playerInfo.class, playerInfo.BNname)
		local playerLevel = playerInfo.level
		local colorFunc = GetQuestDifficultyColor or GetDifficultyColor
		local color = colorFunc(playerLevel)
		if color and playerInfo.level > 0 then
			--local colorCode = RGBTableToColorCode(colorFunc(playerLevel))
			local colorCode = ToHex(color.r, color.g, color.b, 1)
			if colorCode then
				playerLevel = "|c"..colorCode..playerLevel.."|r"
				return "|Hplayer:"..playerLink.."|h["..player.."]|h", "|Hplayer:"..playerLink.."|h["..playerLevel..":"..player.."]|h", playerLink, player, playerName, playerServer, playerInfo
			end
		end
	end
end

local function addToPlayerList(name, realm, level, class, BNname)
	if not name or not level or not class then return end
	if not addon.playerList then addon.playerList = {} end
	if level <= 0 then return end --don't store anything with no actual level

	--do the class list if it's missing, this is to check for localized classes, so we can get proper color
	if not addon.chkClassList then
		addon.chkClassList = {}
		for i = 1, GetNumClasses() do
			local className, classFile, classID = GetClassInfo(i)
			if className and classFile then
				addon.chkClassList[className] = classFile
			end
		end
	end

	local playerName, playerServer = name:match("([^%-]+)%-?(.*)")

	if playerName and strlen(playerName) > 0 then
		name = playerName
	end
	if playerServer and strlen(playerServer) > 0 then
		realm = playerServer
	end
	--one last try
	-- if not realm and string.find(name, "-", 1 true) then
		-- playerName = string.sub(linkName, 1, findFirst - 1)
		-- playerServer = string.sub(linkName, findFirst + 1)
		-- if playerServer and string.len(playerServer) > 0 then
			-- realm = playerServer
		-- end
	-- end
	if not realm or strlen(realm) <= 0 then
		realm = GetRealmName()
	end
	if not name or not realm then return end

	--fix the class color if needed, get the non-local blizzard one, that way we can grab the correct color
	if addon.chkClassList[class] then class = addon.chkClassList[class] end

	addon.playerList[name.."@"..stripAndLowercase(realm)] = {name=name, realm=realm, stripRealm=stripAndLowercase(realm), level=level, class=class, BNname=BNname}
end

local function initUpdateCurrentPlayer()
	local class = select(2, UnitClass("player"))
	local name, realm = UnitName("player")
	local level = UnitLevel("player")
	addToPlayerList(name, realm, level, class)
end

local function doRosterUpdate()

	local chkRaid = IsInRaid()
	local IsInGroup = chkRaid or IsInGroup()

	if IsInGroup then
		local playerNum, unit = (chkRaid and GetNumGroupMembers()) or MAX_PARTY_MEMBERS, (chkRaid and "raid") or "party"
		for i = 1, playerNum do
			if UnitExists(unit..i) then
				local playerName, playerServer = UnitName(unit..i)
				local _, class = UnitClass(unit..i)
				local level = UnitLevel(unit..i)
				addToPlayerList(playerName, playerServer, level, class)
			end
		end
	end

end

local function doFriendUpdate()
	for i = 1, C_FriendList.GetNumFriends() do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		--make sure they are online
		if info and info.connected then
			addToPlayerList(info.name, GetRealmName(), info.level, info.className)
		end
	end

	if C_BattleNet then
		local numBNet, onlineBNet = BNGetNumFriends()
		for i = 1, numBNet do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo and accountInfo.gameAccountInfo then
				local friendInfo = accountInfo.gameAccountInfo
				--make sure they are online and playing WOW
				if friendInfo and friendInfo.isOnline and friendInfo.clientProgram == BNET_CLIENT_WOW then
					--Whether or not the friend is known by their BattleTag
					local friendAccountName = accountInfo.isBattleTagFriend and accountInfo.battleTag or accountInfo.accountName

					if friendInfo.characterName and friendInfo.realmName and friendInfo.characterLevel and friendInfo.className then
						addToPlayerList(friendInfo.characterName, friendInfo.realmName, friendInfo.characterLevel, friendInfo.className, friendAccountName)
					end
				end
			end
		end
	end
end

local function doGuildUpdate()
	if IsInGuild()  then
		C_GuildInfo.GuildRoster()
		for i = 1, GetNumGuildMembers(true) do
			local name, _, _, level, _, _, _, _, online, _, class = GetGuildRosterInfo(i)
			if online then
				--only do online players
				local playerName, playerServer = name:match("([^%-]+)%-?(.*)")
				if playerName and playerServer then
					addToPlayerList(playerName, playerServer, level, class)
				else
					addToPlayerList(name, GetRealmName(), level, class)
				end
			end
		end
	end
end

local function initPlayerInfo()
	if not XCHT_DB.enablePlayerChatStyle then return end

	addon:RegisterEvent("GUILD_ROSTER_UPDATE", function() doGuildUpdate() end)
    addon:RegisterEvent("FRIENDLIST_UPDATE", function() doFriendUpdate() end)
	addon:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE", function() doFriendUpdate() end)
    addon:RegisterEvent("RAID_ROSTER_UPDATE", function() doRosterUpdate() end)
	addon:RegisterEvent("PLAYER_ENTERING_WORLD", function() doRosterUpdate() end)
	addon:RegisterEvent("UPDATE_INSTANCE_INFO", function() doRosterUpdate() end)
	addon:RegisterEvent("ZONE_CHANGED_NEW_AREA", function() doRosterUpdate() end)
	addon:RegisterEvent("UNIT_NAME_UPDATE", function() doRosterUpdate() end)
	addon:RegisterEvent("UNIT_PORTRAIT_UPDATE", function() doRosterUpdate() end)
    addon:RegisterEvent("GROUP_ROSTER_UPDATE", function() doRosterUpdate() end)

    addon:RegisterEvent("PLAYER_LEVEL_UP", function() initUpdateCurrentPlayer() end)
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
	OnShow = function ()
		addon.xanChatReloadPopup = true
	end,
	OnHide = function ()
		addon.xanChatReloadPopup = false
	end,
	OnAccept = function()
	  ReloadUI()
	end,
	OnCancel = function ()
		addon.xanChatReloadPopup = false
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

local lastMsgIndex = 0
local AddMessage = function(frame, text, ...)

	if XCHT_DB.shortNames and type(text) == "string" then
		local chatNum = strmatch(text,"%d+") or ""
		if not tonumber(chatNum) then chatNum = "" else chatNum = chatNum..":" end
		for i = 1, #SHORT_CHANNEL_REPLACEMENTS do
			local longName = SHORT_CHANNEL_REPLACEMENTS[i][1]
			local shortName = SHORT_CHANNEL_REPLACEMENTS[i][2]
			if longName and shortName then
				text = gsub(text, longName, "["..chatNum..shortName.."]")
			end
		end
	end

	--only do stylized player names if it's even enabled and we have the filter list
	if addon.isFilterListEnabled and XCHT_DB.enablePlayerChatStyle and type(text) == "string" then

		--The string.find method provides an optional 4th parameter to enforce a plaintext search by itself.
		if strfind(text, "|Hplayer:", 1, true) then
			local old, new, playerLink, player, playerName, playerServer, playerInfo = parsePlayerInfo(frame, text, ...)
			if old and new and strfind(text, old, 1, true) then
				text = plainTextReplace(text, old, new)
			end
		end

		--ChatFrame_MessageEventHandler
		if lastMsgEvent and lastMsgEvent.event then
			--Debug(lastMsgEvent, lastMsgEvent.event, lastMsgEvent.messageIndex, text)

			--lastMsgEvent = {event=event, msg=msg, author=author, messageIndex=messageIndex, arg1=arg1, arg2=arg2, arg3=arg3}
			if lastMsgEvent and lastMsgEvent.messageIndex and lastMsgEvent.messageIndex ~= lastMsgIndex then
				lastMsgIndex = lastMsgEvent.messageIndex
				--Debug(lastMsgEvent.event, lastMsgEvent.msg, lastMsgEvent.author, lastMsgEvent.messageIndex, lastMsgEvent.arg1, lastMsgEvent.arg2, lastMsgEvent.arg3)

				--don't do this on strings with player links and we have a positive filter
				if not strfind(text, "|Hplayer:", 1, true) and not strfind(text, "|HBNplayer:", 1, true) and addon:searchFilterList(lastMsgEvent.event, text) then
					--Debug('system', lastMsgEvent.event, lastMsgEvent.msg, lastMsgEvent.author, lastMsgEvent.messageIndex, lastMsgEvent.arg1, lastMsgEvent.arg2, lastMsgEvent.arg3)
					local origText = text

					--check for names
					for k, v in pairs(addon.playerList) do
						--just in case
						if k and v then
							local pN, pR = strsplit("@", k)
							local passChk = false
							--playerName, playerServer = linkName:match("([^%-]+)%-?(.*)")

							--make sure we even have a player in the string before editing it
							if pN and pR and strfind(text, pN, 1, true) and v.class then

								--do the replace here
								local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[v.class] or RAID_CLASS_COLORS[v.class]
								if color then

									local colorCode = ToHex(color.r, color.g, color.b, 1)
									--replace if we have the name and hyphen server
									local hasReplaced = false

									--only do this for system messages that don't have a player link in it, otherwise it will ruin the player link
									if v.realm and v.stripRealm then
										text, passChk = plainTextReplace(text, pN.."-"..v.realm, "|c"..colorCode..pN.."-"..v.realm.."|r")
										if not passChk then
											text, passChk = plainTextReplace(text, pN.."-"..v.stripRealm, "|c"..colorCode..pN.."-"..v.stripRealm.."|r")
										end
										if passChk then
											hasReplaced = true
										end
									end
									if not hasReplaced then
										--replace only whole words
										text = replaceText(text, pN, "|c"..colorCode..pN.."|r", true)
									end

									--exit out of loop
									break
								else
									--something went wrong, exit the loop
									break
								end
							end
						end
					end

				end

			end

		end

	end

	msgHooks[frame:GetName()].AddMessage(frame, text, ...)
end

--save and restore layout functions
local function SaveLayout(chatFrame)
	if not addonLoaded then return end
	if not chatFrame then return end
	if XCHT_DB.lockChatSettings then return end

	if not XCHT_DB then return end
	if not XCHT_DB.frames then XCHT_DB.frames = {} end

	--first check to see if we even store this chatFrame
	if chatFrame == DEFAULT_CHAT_FRAME or chatFrame.isDocked or chatFrame:IsShown() then
		if not XCHT_DB.frames[chatFrame:GetID()] then XCHT_DB.frames[chatFrame:GetID()] = {} end
	else
		--don't store it
		if XCHT_DB.frames[chatFrame:GetID()] then XCHT_DB.frames[chatFrame:GetID()] = nil end
		return
	end

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

	if addon.IsRetail and chatFrame == DEFAULT_CHAT_FRAME then return end --don't set anything for the default chat frame in retail, it causes taints

 	if ( db.width and db.height ) then
		if not addon.IsRetail then
			chatFrame:SetSize(db.width, db.height) --causes a taint if you try to set the DEFAULT_CHAT_FRAME height and width in any way in retail due to edit mode
		end
		--force the sizing in blizzards settings
		SetChatWindowSavedDimensions(chatFrame:GetID(), db.width, db.height)

		if ( not chatFrame.isTemporary and not chatFrame.isDocked) then
			FCF_RestorePositionAndDimensions(chatFrame)
		end
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
	if XCHT_DB.lockChatSettings then return end

	if not XCHT_DB then return end
	if not XCHT_DB.frames then XCHT_DB.frames = {} end

	--first check to see if we even store this chatFrame
	if chatFrame == DEFAULT_CHAT_FRAME or chatFrame.isDocked or chatFrame:IsShown() then
		if not XCHT_DB.frames[chatFrame:GetID()] then XCHT_DB.frames[chatFrame:GetID()] = {} end
	else
		--don't store it
		if XCHT_DB.frames[chatFrame:GetID()] then XCHT_DB.frames[chatFrame:GetID()] = nil end
		return
	end

	if chatFrame.isMoving or chatFrame.isDragging then return end

	local db = XCHT_DB.frames[chatFrame:GetID()]

	local name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable = GetChatWindowInfo(chatFrame:GetID())
	local windowMessages = { GetChatWindowMessages(chatFrame:GetID())}
	local windowChannels = { GetChatWindowChannels(chatFrame:GetID())}
	local windowMessageColors = {}

	--lets save all the message type colors
	--https://www.townlong-yak.com/framexml/live/ChatConfigFrame.lua#1464
	for k=1, #windowMessages do
		if windowMessages[k] and ChatTypeGroup[windowMessages[k]] then
			local colorR, colorG, colorB, messageType = GetMessageTypeColor(windowMessages[k])
			if colorR and colorG and colorB then
				windowMessageColors[k] = {colorR, colorG, colorB, windowMessages[k]}
			end
		end
	end

	db.chatParent = chatFrame:GetParent():GetName()
	db.windowInfo = {name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable}
	db.windowMessages = windowMessages
	db.windowChannels = windowChannels
	db.windowMessageColors = windowMessageColors
	db.windowChannelColors = nil --remove old db stuff
	db.fadingDuration = chatFrame:GetTimeVisible() or 120
	db.defaultFrameAlpha = DEFAULT_CHATFRAME_ALPHA

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

	--lets set the windowMessageColors
	if db.windowMessageColors then
		--add the stored ones
		local newWindowMessageColors = db.windowMessageColors
		for k=1, #newWindowMessageColors do
			if newWindowMessageColors[k] and newWindowMessageColors[k][4] then
				--in future ChangeChatColor FCF_StripChatMsg() may be required.  https://www.townlong-yak.com/framexml/live/ChatConfigFrame.lua
				ChangeChatColor(newWindowMessageColors[k][4], newWindowMessageColors[k][1], newWindowMessageColors[k][2], newWindowMessageColors[k][3])
			end
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

	-- --lets set the windowChannelColors
	if XCHT_DB.channelColors then
		for k = 1, MAX_WOW_CHAT_CHANNELS do
			if XCHT_DB.channelColors[k] then
				local colorData = XCHT_DB.channelColors[k]
				if colorData then
					ChangeChatColor("CHANNEL"..k, colorData.r, colorData.g, colorData.b)
				end
			end
		end
	end

	if db.windowInfo and db.windowInfo[1] then
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
		local checkParent = (type(db.chatParent) == "table" and db.chatParent) or _G[db.chatParent]
		chatFrame:SetParent(checkParent)
	end

	--handling chat frame fading
	if XCHT_DB then
		if XCHT_DB.enableChatTextFade then
			chatFrame:SetFading(true)
			chatFrame:SetTimeVisible(db.fadingDuration or 120)
		else
			chatFrame:SetFading(false)
		end
	end

end

local function SaveChannelColors()
	if not addonLoaded then return end
	if XCHT_DB.lockChatSettings then return end
	if not XCHT_DB.channelColors then XCHT_DB.channelColors = {} end

	local function GetColorInfo(...)
		local count = 1
		for i=1, select("#", ...), 3 do
			local channelNum = select(i, ...)
			local tag = "CHANNEL"..channelNum
			local channelName = select(i+1, ...)
			local disabled = select(i+2, ...)

			if ChatTypeInfo[tag] then
				local colorR, colorG, colorB, messageType = GetMessageTypeColor(tag)
				if colorR and colorG and colorB then
					XCHT_DB.channelColors[count] = {r=colorR, g=colorG, b=colorB, channelNum=channelNum, channelName=channelName, tag=tag}
				end
			end
			count = count + 1
		end
	end

	GetColorInfo(GetChannelList())
end

local function SaveDebugInfo(chatFrame)
	if not addonLoaded then return end
	if not chatFrame then return end
	if not XCHT_DB then return end

	if XCHT_DB.debugChannels then XCHT_DB.debugChannels = nil end --remove old debug table
	if not XCHT_DB.debugInfo then XCHT_DB.debugInfo = {} end

	if chatFrame == DEFAULT_CHAT_FRAME or chatFrame.isDocked or chatFrame:IsShown() then
		if not XCHT_DB.debugInfo[chatFrame:GetID()] then XCHT_DB.debugInfo[chatFrame:GetID()] = {} end
	else
		--don't store it
		if XCHT_DB.debugInfo[chatFrame:GetID()] then XCHT_DB.debugInfo[chatFrame:GetID()] = nil end
		return
	end

	local debugDB = XCHT_DB.debugInfo[chatFrame:GetID()]
	local channelList = chatFrame.channelList
	local zoneChannelList = chatFrame.zoneChannelList

	local function IsChannelNameChecked(channelName)
		if not channelList then return false end
		for index, value in pairs(channelList) do
			if value == channelName then
				return true
			end
		end
		return false
	end
	local function GetChannelID(channelName)
		if not channelList then return 0 end
		if not zoneChannelList then return 0 end

		for index, value in pairs(channelList) do
			if value == channelName then
				if zoneChannelList[index] then
					return zoneChannelList[index]
				end
				return 0
			end
		end
		return 0
	end
	local function GetDebugInfo(...)
		if not channelList or #channelList < 1 then return end
		if not zoneChannelList or #zoneChannelList < 1 then return end

		for i=1, select("#", ...), 3 do

			local channelNum = select(i, ...)
			local tag = "CHANNEL"..channelNum
			local channelName = select(i+1, ...)
			local disabled = select(i+2, ...)
			local checked = IsChannelNameChecked(channelName)

			if channelNum then
				local _, longChannelName, instanceID, isCommunitiesChannel = GetChannelName(channelNum)

				debugDB[channelNum] = {
					channelNum = channelNum,
					tag = tag,
					channelName = channelName,
					isDisabled = disabled,
					isChecked = checked,
					chatFrameID = chatFrame:GetID() or 0,
					chatFrameName = chatFrame:GetName() or "Unknown",
					channelID = GetChannelID(channelName),
					longChannelName = longChannelName,
					instanceID = instanceID,
					isCommunitiesChannel = isCommunitiesChannel,
					channelShortcut = C_ChatInfo and C_ChatInfo.GetChannelShortcutForChannelID(GetChannelID(channelName)) or "?",
				}
			end

		end
	end

	GetDebugInfo(GetChannelList())
end

local function saveChatSettings(f)
	SaveLayout(f)
	SaveSettings(f)
	SaveDebugInfo(f)
	SaveChannelColors()
end

local function restoreChatSettings(f)
	RestoreSettings(f)
	RestoreLayout(f)
end

local function doSaveCurrentChatFrame()
    local chatFrame = FCF_GetCurrentChatFrame()
    if chatFrame then
        saveChatSettings(chatFrame)
    end
end

local function doValueUpdate(checkBool, groupType)
	saveChatSettings(FCF_GetCurrentChatFrame() or nil)
end

hooksecurefunc("ToggleChatMessageGroup", doValueUpdate)
hooksecurefunc("ToggleMessageSource", doValueUpdate)
hooksecurefunc("ToggleMessageDest", doValueUpdate)
hooksecurefunc("ToggleMessageTypeGroup", doValueUpdate)
hooksecurefunc("ToggleMessageType", doValueUpdate)
hooksecurefunc("ToggleChatColorNamesByClassGroup", doValueUpdate)

hooksecurefunc("FCF_SavePositionAndDimensions", function(chatFrame) saveChatSettings(chatFrame) end)
hooksecurefunc("FCF_RestorePositionAndDimensions", function(chatFrame) saveChatSettings(chatFrame) end)
hooksecurefunc("FCF_Close", function(chatFrame) saveChatSettings(chatFrame) end)
hooksecurefunc("FCF_ToggleLock", function() doSaveCurrentChatFrame() end)
hooksecurefunc("FCF_ToggleLockOnDockedFrame", function() doSaveCurrentChatFrame() end)
hooksecurefunc("FCF_ToggleUninteractable", function() doSaveCurrentChatFrame() end)
hooksecurefunc("FCF_DockFrame", function(chatFrame, index, selected) saveChatSettings(chatFrame) end)
hooksecurefunc("FCF_StopDragging", function(chatFrame) saveChatSettings(chatFrame) end)
hooksecurefunc("FCF_Tab_OnClick", function(self, button)
	local chatFrame = _G["ChatFrame"..self:GetID()]
	if chatFrame then
		saveChatSettings(chatFrame)
	end
end)

ChatConfigFrame:HookScript("OnHide", function(self)
	for i = 1, NUM_CHAT_WINDOWS do
		local n = ("ChatFrame%d"):format(i)
		local f = _G[n]
		if f then
			saveChatSettings(f)
		end
	end
end)

--[[------------------------
	CHAT COPY
--------------------------]]

--this will remove UI escaped textures from strings.  It causes an issue with highlighted text as it offsets it little by little
--https://wowwiki.fandom.com/wiki/UI_escape_sequences#Textures
--https://wow.gamepedia.com/UI_escape_sequences
local function unescape(str)

	--this is for testing for protected strings and only for officer chat, since even the text in officer chat is protected not just the officer name
	local isOfficerChat = false
	if strfind(str, "|Hchannel:officer", 1, true) then
		isOfficerChat = true
	end
	--str = gsub(str, "|c%x%x%x%x%x%x%x%x", "") --color tag 1
	--str = gsub(str, "|r", "") --color tag 2

    str = gsub(str, "|T.-|t", "") --textures in chat like currency coins and such
	str = gsub(str, "|H.-|h(.-)|h", "%1") --links, just put the item description and chat color
	str = gsub(str, "{.-}", "") --remove raid icons from chat

	--so apparently blizzard protects certain strings and returns them as textures.
	--this causes the insert for the multiline to break and not display the line.
	--such is the case for protected BNET Friends names and in some rare occasions names in the chat in general.
	--These protected strings start with |K and end with |k.   Example: |K[gsf][0-9]+|k[0]+|k
	--look under the link above for escape sequences

	--I want to point out that event addons like ElvUI suffer from  this problem.
	--They get around it by not displaying protected messages at ALL.  Check MessageIsProtected(message) in ElvUI

	if strfind(str, "|K", 1, true) then

		--str = gsub(str, "|K(.-)|k", "%1")
		local presenceID = strmatch(str, "|K(.-)|k")
		local accountName
		local stripBNet

		if presenceID then
			local numBNet, onlineBNet = BNGetNumFriends()
			for i = 1, numBNet do
				local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
				--only continue if we have a account info to work with
				if accountInfo and accountInfo.gameAccountInfo then
					--grab the bnet name of the account, it will have |K|k in it so again it will be hidden
					accountName = accountInfo.accountName
					--do we even have a battle.net tag to replace it with?
					if accountName and accountInfo.battleTag then
						--grab the presenceID from in between the |K|k tags
						accountName = gsub(accountName, "|K(.-)|k", "%1")
						--if it matches the one we found earlier, then replace it with a battle.net tag instead
						if accountName and accountName == presenceID then
							--don't show entire bnet tag just the name
						stripBNet = strmatch(accountInfo.battleTag, "(.-)#")
							str = gsub(str, "|K(.-)|k", stripBNet or accountInfo.battleTag)
							--return out of here since we already did the replace
							--we don't want to go to the failsafe below
							return str
						end
					end
				end
			end
		end

		--something went wrong with replacing the name text for |K|k
		--so lets just remove it since it will not allow text to be inserted into the multiline box, since it will be empty and or hidden because |K|k returns a hidden textures
		--for protected strings.  That's why we are just going to remove it
		str = gsub(str, "|K(.-)|k", "%1")

		--add extra text for protected strings, to let folks know it's protected
		if isOfficerChat then
			str = str..L.ProtectedChannel
		end
	end

    return str
end

local function GetChatText(copyFrame, chatIndex, pageNum)

	copyFrame.MLEditBox:SetText("") --clear it first in case there were previous messages
	copyFrame.currChatIndex = chatIndex

	--the editbox of the multiline editbox (The parent of the multiline object)
	local parentEditBox = copyFrame.MLEditBox.editBox

	--there is a hard limit of text that can be highlighted in an editbox to 500 lines.
	local MAXLINES = 150 --150 don't use large numbers or it will cause LAG when frame opens.  EditBox was not made for large amounts of text
	local msgCount = _G["ChatFrame"..chatIndex]:GetNumMessages()
	local motdString = COMMUNITIES_MESSAGE_OF_THE_DAY_FORMAT:gsub("\"%%s\"", "")
	local startPos = 0
	local endPos = 0
	local lineText

	--lets create the pages
	local pages = {}
	local pageCount = 0 --start at zero
	for i = 1, msgCount, MAXLINES do
	  pageCount = i-1 --the block will extend by 1 past 150, so subtract 1
	  if pageCount <= 0 then pageCount = 1 end --this is the first page, so start at 1
	  table.insert(pages, pageCount)
	end

	--check for custom buffer limit by the user, ignore if it's set to zero
	if XCHT_DB.pageBufferLimit > 0 and #pages > XCHT_DB.pageBufferLimit then
		local counter = 0
		local tmpPages = {}
		for i = #pages, 1, -1 do
			counter = counter + 1
			if counter <= XCHT_DB.pageBufferLimit then
				table.insert(tmpPages, pages[i])
			else
				break
			end
		end
		pages = tmpPages
	end

	--load past page if we don't have a pageNum
	if not pageNum and startPos < 1 then
		if msgCount > MAXLINES then
			startPos = msgCount - MAXLINES
			endPos = startPos + MAXLINES
		else
			startPos = 1
			endPos = msgCount
		end
	--otherwise load the page number
	elseif pageNum and pages[pageNum] then
		if pages[pageNum] == 1 then
			--first page
			startPos = 1
			endPos = MAXLINES
		else
			startPos = pages[pageNum]
			endPos = pages[pageNum] + MAXLINES
		end
	else
		print("XanChat: "..L.CopyChatError)
		return
	end

	--adjust the endPos if it's greater than the total messages we have
	if endPos > msgCount then endPos = msgCount end

	for i = startPos, endPos do
		local chatMsg, r, g, b, chatTypeID = _G["ChatFrame"..chatIndex]:GetMessageInfo(i)
		if not chatMsg then break end

		--fix situations where links end the color prematurely
		if (r and g and b and chatTypeID) then
			local colorCode = RGBToColorCode(r, g, b)
			chatMsg = string.gsub(chatMsg, "|r", "|r"..colorCode)
			chatMsg = colorCode..chatMsg
		end

		if (i == startPos) then
			lineText = unescape(chatMsg).."|r"
		else
			lineText = "\n"..unescape(chatMsg).."|r"
		end

		parentEditBox:Insert(lineText)
	end

	if pageNum then
		copyFrame.currentPage = pageNum
	else
		copyFrame.currentPage = #pages
	end

	copyFrame.pages = pages
	copyFrame.pageNumText:SetText(L.Page.." "..copyFrame.currentPage)

	copyFrame.handleCursorChange = true -- just in case
	copyFrame:Show()
end

local function CreateCopyFrame()
	--check to see if we have the frame already, if we do then return it
	if addon.copyFrame then return addon.copyFrame end

	local copyFrame = CreateFrame("FRAME", ADDON_NAME.."CopyFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	copyFrame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	})
	copyFrame:SetBackdropColor(0, 0, 0, 1)
	copyFrame:EnableMouse(true)
	copyFrame:SetFrameStrata("DIALOG")
	copyFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	copyFrame:SetWidth(830)
	copyFrame:SetHeight(490)

	local title = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", copyFrame, "TOPLEFT", 20, -12)
	title:SetText(L.CopyChat)

	local scrollFrame = CreateFrame("ScrollFrame", ADDON_NAME.."CopyScrollFrame", copyFrame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 20, -38)
	scrollFrame:SetPoint("BOTTOMRIGHT", -35, 45)

	local editBox = CreateFrame("EditBox", ADDON_NAME.."CopyEditBox", scrollFrame)
	editBox:SetAutoFocus(false)
	editBox:SetMultiLine(true)
	editBox:SetFontObject("ChatFontNormal")
	editBox:SetWidth(scrollFrame:GetWidth())
	editBox:SetText("")
	scrollFrame:SetScrollChild(editBox)

	local function UpdateEditSize()
		local width = scrollFrame:GetWidth() or 0
		if width > 0 then
			editBox:SetWidth(width)
		end
		local height = editBox:GetTextHeight() + 10
		local minHeight = scrollFrame:GetHeight() or 0
		if height < minHeight then height = minHeight end
		editBox:SetHeight(height)
	end

	editBox:SetScript("OnTextChanged", UpdateEditSize)
	scrollFrame:HookScript("OnSizeChanged", UpdateEditSize)
	UpdateEditSize()

	local scrollBar = scrollFrame.ScrollBar or _G[scrollFrame:GetName().."ScrollBar"]
	local MLEditBox = {
		editBox = editBox,
		scrollFrame = scrollFrame,
		scrollBar = scrollBar,
		SetText = function(self, text)
			self.editBox:SetText(text or "")
			UpdateEditSize()
		end,
		GetText = function(self)
			return self.editBox:GetText()
		end,
		SetCursorPosition = function(self, pos)
			self.editBox:SetCursorPosition(pos)
		end,
		ClearFocus = function(self)
			self.editBox:ClearFocus()
		end,
		SetFocus = function(self)
			self.editBox:SetFocus()
		end,
	}
	copyFrame.MLEditBox = MLEditBox

	copyFrame.handleCursorChange = false --setting this to true will update the scrollbar to the cursor position
	scrollFrame:HookScript("OnUpdate", function(self, elapsed)
		if not scrollFrame:IsVisible() then return end

		self.OnUpdateCounter = (self.OnUpdateCounter or 0) + elapsed
		if self.OnUpdateCounter < 0.1 then return end
		self.OnUpdateCounter = 0

		local pos = math.max(strlen(editBox:GetText()), editBox:GetNumLetters())

		if copyFrame.handleCursorChange then
			editBox:SetFocus()
			editBox:SetCursorPosition(pos)
			editBox:ClearFocus()
			if scrollBar then
				local _, statusMax = scrollBar:GetMinMaxValues()
				scrollBar:SetValue(statusMax)
			else
				scrollFrame:SetVerticalScroll(scrollFrame:GetVerticalScrollRange())
			end
			copyFrame.handleCursorChange = false
		end
	end)
	copyFrame:HookScript("OnShow", function() copyFrame.handleCursorChange = true end)

	local close = CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
	close:SetScript("OnClick", function() copyFrame:Hide() end)
	close:SetPoint("BOTTOMRIGHT", -27, 13)
	close:SetFrameLevel(close:GetFrameLevel() + 1)
	close:SetHeight(20)
	close:SetWidth(100)
	close:SetText(L.Done)

    local buttonBack = CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
    buttonBack:SetText("<")
    buttonBack:SetHeight(25)
    buttonBack:SetWidth(25)
    buttonBack:SetPoint("BOTTOMLEFT", 10, 13)
	buttonBack:SetFrameLevel(buttonBack:GetFrameLevel() + 1)
    buttonBack:SetScript("OnClick", function()
		if copyFrame.currChatIndex and copyFrame.currentPage then
			if (copyFrame.currentPage - 1) > 0 then
				GetChatText(copyFrame, copyFrame.currChatIndex, copyFrame.currentPage - 1)
			end
		end
    end)
    copyFrame.buttonBack = buttonBack

    local buttonForward = CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
    buttonForward:SetText(">")
    buttonForward:SetHeight(25)
    buttonForward:SetWidth(25)
    buttonForward:SetPoint("BOTTOMLEFT", 40, 13)
	buttonForward:SetFrameLevel(buttonForward:GetFrameLevel() + 1)
    buttonForward:SetScript("OnClick", function()
		if copyFrame.currChatIndex and copyFrame.currentPage and copyFrame.pages then
			if (copyFrame.currentPage + 1) <= #copyFrame.pages then
				GetChatText(copyFrame, copyFrame.currChatIndex, copyFrame.currentPage + 1)
			end
		end
    end)
    copyFrame.buttonForward = buttonForward

	--this is to place it above the group layer
    local pageNumText = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageNumText:SetPoint("BOTTOMLEFT", 80, 18)
    pageNumText:SetShadowOffset(1, -1)
    pageNumText:SetText(L.Page.." 1")
    copyFrame.pageNumText = pageNumText

	copyFrame:Hide()

	--store it for the future
	addon.copyFrame = copyFrame

	return copyFrame
end

local function CreateCopyChatButtons(chatIndex, chatFrame)
	if not XCHT_DB.enableCopyButton then return end

	local copyFrame = CreateCopyFrame()

	local obj = CreateFrame("Button", "xanCopyChatButton"..chatIndex, chatFrame, BackdropTemplateMixin and "BackdropTemplate")
	obj:SetParent(chatFrame)
	obj:SetNormalTexture("Interface\\AddOns\\xanChat\\media\\copy")
	obj:SetHighlightTexture("Interface\\AddOns\\xanChat\\media\\copyhighlight")
	obj:SetPushedTexture("Interface\\AddOns\\xanChat\\media\\copy")
	obj.texture = obj.bg
	obj:SetFrameLevel(7)
	obj:SetWidth(18)
	obj:SetHeight(18)
	obj:Hide()
	obj:SetScript("OnClick", function(self)
		GetChatText(copyFrame, chatIndex)
	end)

	if not XCHT_DB.enableCopyButtonLeft then

		obj:SetPoint("BOTTOMRIGHT", -2, -3)

		chatFrame:HookScript("OnEnter", function(self)
			obj:Show()
		end)
		chatFrame:HookScript("OnLeave", function(self)
			obj:Hide()
		end)
		chatFrame.ScrollToBottomButton:HookScript("OnEnter", function(self)
			obj:Show()
		end)
		chatFrame.ScrollToBottomButton:HookScript("OnLeave", function(self)
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

	else
		local leftButtonFrame = "ChatFrame"..chatIndex.."ButtonFrame"

		local offSetY = -50
		if not addon.IsRetail and not XCHT_DB.hideScroll then
			--we have to move this as it will be on the scrollbars on classic
			offSetY = 60
		end

		if _G[leftButtonFrame] then
			obj:SetPoint("TOPLEFT", _G[leftButtonFrame], "TOPLEFT", 5, offSetY)
		else
			obj:SetPoint("TOPLEFT", chatFrame, "TOPLEFT", -30, offSetY)
		end
		obj:Show()
	end

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
	Chat Frame Fading
--------------------------]]

local old_FCF_FadeInChatFrame = FCF_FadeInChatFrame
local old_FCF_FadeOutChatFrame = FCF_FadeOutChatFrame
local old_FCF_FadeOutScrollbar = FCF_FadeOutScrollbar
local old_FCF_SetWindowAlpha = FCF_SetWindowAlpha
local old_FCF_OnUpdate = FCF_OnUpdate

local function doAlphaCheck(chatFrame, chatName)
	local objChat = _G[chatName] or chatFrame
	local objName = chatName or chatFrame:GetName()

	if objChat and objName then
		objChat.oldAlpha = XCHT_DB.userChatAlpha or DEFAULT_CHATFRAME_ALPHA --could possibly lead to taint issues, blizzard doesn't like addons setting the alpha
		--objChat.hasBeenFaded = true --causes a taint in retail if set to true/false

		for index, value in pairs(CHAT_FRAME_TEXTURES) do
			local object = _G[objName..value]
			object:SetAlpha(XCHT_DB.userChatAlpha or DEFAULT_CHATFRAME_ALPHA)
			if ( object:IsShown() ) then
				UIFrameFadeIn(object, CHAT_FRAME_FADE_TIME, object:GetAlpha(), objChat.oldAlpha) --could possibly lead to taint issues, blizzard doesn't like addons setting the alpha
			end
		end

	end
end

local function disableChatFrameFading()

	FCF_FadeInChatFrame = function(chatframe)
		if chatframe:GetName() and strfind(chatframe:GetName(), "ChatFrame", 1, true) then
			doAlphaCheck(chatframe)
			return
		end
		old_FCF_FadeInChatFrame(chatframe)
	end

	FCF_FadeOutChatFrame = function(chatframe)
		if chatframe:GetName() and strfind(chatframe:GetName(), "ChatFrame", 1, true) then
			doAlphaCheck(chatframe)
			return
		end
		old_FCF_FadeOutChatFrame(chatframe)
	end

	FCF_FadeOutScrollbar = function(chatframe)
		if chatframe:GetName() and strfind(chatframe:GetName(), "ChatFrame", 1, true) then
			return
		end
		old_FCF_FadeOutScrollbar(chatframe)
	end

	FCF_SetWindowAlpha = function(frame, alpha, doNotSave)
		if frame:GetName() and strfind(frame:GetName(), "ChatFrame", 1, true) then
			frame.oldAlpha = XCHT_DB.userChatAlpha or DEFAULT_CHATFRAME_ALPHA --could possibly lead to taint issues, blizzard doesn't like addons setting the alpha
			return
		end
		old_FCF_SetWindowAlpha(frame, alpha, doNotSave)
	end

	FCF_OnUpdate = function(elapsed)
		local mouseIn = false

		for _, frameName in pairs(CHAT_FRAMES) do

			local chatFrame = _G[frameName]
			local fTab = _G[frameName.."Tab"]

			if ( chatFrame and fTab) then

				local topOffset = 28
				local mouseOver = chatFrame:IsMouseOver(topOffset, -2, -2, 2)

				if mouseOver then
					mouseIn = true
				end

				if XCHT_DB.hideTabs then
					--NOTE: Cannot rely on UIFrameFadeIn or UIFrameFadeOut as their threshold always stops at 0.9 for show and 0.2 for hide no matter what arguements are set
					--this is because of how elaspe time is handled in UIFrameFade
					--https://github.com/tomrus88/BlizzardInterfaceCode/blob/f0118d6ea34d2d7898a442b6b9a357f07b5d0117/Interface/FrameXML/UIParent.lua

					--overwrite it
					if mouseIn then
						fTab:SetAlpha(1) --we set this manually as we want it bright when they hover over
					else
						fTab:SetAlpha(0) --hide it when we mouse out
					end
				else
					--overwrite standard as well because it won't work properly
					if mouseIn then
						fTab:SetAlpha(1) --we set this manually as we want it bright when they hover over
					else
						fTab:SetAlpha(fTab.noMouseAlpha) --use default alpha when we mouse out
					end
				end

			end

		end

		old_FCF_OnUpdate(elapsed)
	end

end

--[[------------------------
	Custom outgoing whisper color
--------------------------]]

function addon:setOutWhisperColor()

	local function ToRGBA(hex)
		return tonumber('0x' .. string.sub(hex, 3, 4), 10) / 255,
			tonumber('0x' .. string.sub(hex, 5, 6), 10) / 255,
			tonumber('0x' .. string.sub(hex, 7, 8), 10) / 255,
			tonumber('0x' .. string.sub(hex, 1, 2), 10) / 255
	end

	local r, g, b, a = ChatTypeInfo["WHISPER"].r, ChatTypeInfo["WHISPER"].g, ChatTypeInfo["WHISPER"].b, 1

	if XCHT_DB.enableOutWhisperColor and XCHT_DB.outWhisperColor then
		r, g, b, a = ToRGBA(XCHT_DB.outWhisperColor)
	end

	if r and g and b then
		ChangeChatColor("WHISPER_INFORM", r, g, b) --change whisper outgoing color
	end

end

--[[------------------------
	Sets all the chat frames alpha to the user selected level
--------------------------]]

function addon:setUserAlpha()
	for _, frameName in pairs(CHAT_FRAMES) do
		doAlphaCheck(nil, frameName)
	end
end

--[[------------------------
	Disable enter/leave/changed channel notifications
--------------------------]]

function addon:setDisableChatEnterLeaveNotice()

	local function checkNotice(self, event, msg, author, ...)
		if XCHT_DB.disableChatEnterLeaveNotice then
			return true
		else
			return false, msg, author, ...
		end
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", checkNotice)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_JOIN", checkNotice)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_LEAVE", checkNotice)
end

for i = 1, NUM_CHAT_WINDOWS do
	local n = ("ChatFrame%d"):format(i)
	local f = _G[n]
	if f then
		--have to do this before player login otherwise issues occur
		f:SetMaxLines(500)
	end
end

local processedFrames = {}

local function SetupChatFrame(chatID, chatFrame)
	if not chatID then return end

	local n = "ChatFrame"..chatID
	local f = _G[n]
	local fTab = _G[n.."Tab"]
	local editBox = _G[n.."EditBox"]

	if f and not processedFrames[n] then

		--set alpha levels
		------------------------
		--only force fade in if we have it disabled
		--FCF_FadeInChatFrame causes TAINT issues during "Edit Mode" in retail
		--https://www.wowinterface.com/forums/showthread.php?t=59244

		--these two settings are very important, do not remove
		--DEFAULT_CHATFRAME_ALPHA = XCHT_DB.userChatAlpha or DEFAULT_CHATFRAME_ALPHA --causes taint issues in Edit Mode
		f.oldAlpha = 0 --could possibly lead to taint issues, blizzard doesn't like addons setting the alpha
		f.hasBeenFaded = nil --causes a taint in retail if set to true/false (old version)
		--f.hasBeenFaded = false --causes a taint in retail if set to true/false (new version)

		for index, value in pairs(CHAT_FRAME_TEXTURES) do
			local object = _G[n..value]
			if object then
				if XCHT_DB.disableChatFrameFade then
					object:SetAlpha(XCHT_DB.userChatAlpha or DEFAULT_CHATFRAME_ALPHA) --could possibly lead to taint issues, blizzard doesn't like addons setting the alpha
				else
					object:SetAlpha(0) --could possibly lead to taint issues, blizzard doesn't like addons setting the alpha
				end
			end
		end
		------------------------

		--create the copy chat buttons
		CreateCopyChatButtons(chatID, f)

		--restore any settings and layout
		restoreChatSettings(f)

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
			saveChatSettings(f)
		end)
		--Tab
		if fTab then
			hooksecurefunc(fTab, "StopMovingOrSizing", function(self)
				saveChatSettings(f)
			end)
		end

		--always lock the frames regardless
		SetChatWindowLocked(chatID, true)
		FCF_SetLocked(f, true)

		--add font outlines or shadows
		if XCHT_DB.addFontOutline or XCHT_DB.addFontShadow then

			local font, size = f:GetFont()
			f:SetFont(font, size, "THINOUTLINE")

			--only apply this if we don't have the shadows enabled. The code below removes the extended alpha layer creating a slimmer font shadow
			if not XCHT_DB.addFontShadow then
				f:SetShadowColor(0, 0, 0, 0)
			end
		end

		--few changes
		f:EnableMouseWheel(true)
		f:SetScript('OnMouseWheel', scrollChat)
		f:SetClampRectInsets(0,0,0,0)

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
				for dX=count, 1, -1 do
					if HistoryDB[name][dX] then
						editBox:AddHistoryLine(HistoryDB[name][dX])
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

			local editBoxBackdrop

			if XCHT_DB.enableSEBDesign then
				editBoxBackdrop = {
					bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
					edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
					tile = true,
					tileSize = 16,
					edgeSize = 12,
					insets = { left = 3, right = 3, top = 3, bottom = 3 }
				}
			else
				editBoxBackdrop = {
					bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
					edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
					insets = { left = 3, right = 3, top = 3, bottom = 3 }
				}
			end

			if XCHT_DB.enableSimpleEditbox then

				editBox.left:SetAlpha(0)
				editBox.right:SetAlpha(0)
				editBox.mid:SetAlpha(0)

				if not editBox.SetBackdrop then
					--add the backdrop mixin to the editbox frame
					Mixin(editBox, BackdropTemplateMixin)
				end

				if editBox.focusLeft then editBox.focusLeft:SetTexture(nil) end
				if editBox.focusRight then editBox.focusRight:SetTexture(nil) end
				if editBox.focusMid then editBox.focusMid:SetTexture(nil) end

				editBox:SetBackdrop(editBoxBackdrop)
				editBox:SetBackdropColor(0, 0, 0, 0.6)
				editBox:SetBackdropBorderColor(0.6, 0.6, 0.6)

			elseif not XCHT_DB.hideEditboxBorder then
				if editBox.focusLeft then editBox.focusLeft:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Left2]]) end
				if editBox.focusRight then editBox.focusRight:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Right2]]) end
				if editBox.focusMid then editBox.focusMid:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Mid2]]) end
			else
				if editBox.focusLeft then editBox.focusLeft:SetTexture(nil) end
				if editBox.focusRight then editBox.focusRight:SetTexture(nil) end
				if editBox.focusMid then editBox.focusMid:SetTexture(nil) end

				editBox.left:SetAlpha(0)
				editBox.right:SetAlpha(0)
				editBox.mid:SetAlpha(0)
			end

			--do editbox positioning
			local spaceAdjusted = 0

			if XCHT_DB.editBoxTop then
				if XCHT_DB.enableEditboxAdjusted then
					spaceAdjusted = 6
				end
				editBox:ClearAllPoints()
				editBox:SetPoint("BOTTOMLEFT",  f, "TOPLEFT",  -5, spaceAdjusted)
				editBox:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 5, spaceAdjusted)
			else
				if XCHT_DB.enableEditboxAdjusted then
					spaceAdjusted = -9
				end
				editBox:ClearAllPoints()
				editBox:SetPoint("TOPLEFT",  f, "BOTTOMLEFT",  -5, spaceAdjusted)
				editBox:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 5, spaceAdjusted)
			end

			--when the editbox is on the top, complications occur because sometimes you are not allowed to click on the tabs.
			--to fix this we'll just make the tab close the editbox
			--also force the editbox to hide itself when it loses focus
			if fTab then
				fTab:HookScript("OnClick", function() editBox:Hide() end)
			end
			editBox:HookScript("OnEditFocusLost", function(self) self:Hide() end)
		end

		--hide the scroll bars
		if XCHT_DB.hideScroll then
			if f.ScrollBar then
				f.ScrollBar:Hide()
				f.ScrollBar:SetScript("OnShow", dummy)
			end
			if f.buttonFrame and f.buttonFrame.Background then
				f.buttonFrame.Background:SetTexture(nil)
				f.buttonFrame.Background:SetAlpha(0)
			end
			if f.buttonFrame and f.buttonFrame.minimizeButton then
				f.buttonFrame.minimizeButton:Hide()
				f.buttonFrame.minimizeButton:SetScript("OnShow", dummy)
			end
			if f.ScrollToBottomButton then
				f.ScrollToBottomButton:Hide()
				f.ScrollToBottomButton:SetScript("OnShow", dummy)
			end
		end

		if XCHT_DB.hideSideButtonBars then
			if f.buttonFrame then
				f.buttonFrame:Hide()
				f.buttonFrame:SetScript("OnShow", dummy)
			end
		end

		--force the chat hide tabs on load
		if XCHT_DB.hideTabs and fTab then
			fTab.mouseOverAlpha = CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA
			fTab.noMouseAlpha = CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA
			if ( f.hasBeenFaded ) then
				fTab:SetAlpha(fTab.mouseOverAlpha)
			else
				fTab:SetAlpha(fTab.noMouseAlpha)
			end
		end

		--enable/disable short channel names by hooking into AddMessage (ignore the combatlog)
		if f ~= COMBATLOG and not msgHooks[n] then
			msgHooks[n] = {}
			msgHooks[n].AddMessage = f.AddMessage
			f.AddMessage = AddMessage
		end

		processedFrames[n] = true
	end
end


function addon:EnableAddon()

	local currentPlayer = UnitName("player") or "Unknown"
	local currentRealm = select(2, UnitFullName("player")) --get shortend realm name with no spaces and dashes

	--do the DB stuff
	if not XCHT_DB then XCHT_DB = {} end
	local defaults = {
		hideSocial = false,
		addFontShadow = false,
		addFontOutline = false,
		hideScroll = false,
		shortNames = false,
		editBoxTop = false,
		hideTabs = false,
		hideVoice = false,
		hideEditboxBorder = false,
		enableSimpleEditbox = true,
		enableSEBDesign = false,
		enableCopyButton = true,
		enablePlayerChatStyle = true,
		enableChatTextFade = true,
		disableChatFrameFade = true,
		enableCopyButtonLeft = false,
		lockChatSettings = false,
		userChatAlpha = 0.25, --uses blizzard default value from DEFAULT_CHATFRAME_ALPHA
		enableEditboxAdjusted = false,
		enableOutWhisperColor = false,
		outWhisperColor = "FFF2307C",
		disableChatEnterLeaveNotice = false,
		hideChatMenuButton = false,
		moveSocialButtonToBottom = false,
		hideSideButtonBars = false,
		pageBufferLimit = 0, --set how many pages to display in CopyChat (0 for no limit)
		debugWrapper = false,
	}
	for key, value in pairs(defaults) do
		if XCHT_DB[key] == nil then
			XCHT_DB[key] = value
		end
	end
	addon.wrapperDebug = XCHT_DB.debugWrapper

	local ver = (addon.GetAddOnMetadata and addon.GetAddOnMetadata(ADDON_NAME, "Version")) or "1.0"

	--setup the history DB
	if not XCHT_HISTORY then XCHT_HISTORY = {} end
	XCHT_HISTORY[currentRealm] = XCHT_HISTORY[currentRealm] or {}
	XCHT_HISTORY[currentRealm][currentPlayer] = XCHT_HISTORY[currentRealm][currentPlayer] or {}
	HistoryDB = XCHT_HISTORY[currentRealm][currentPlayer]

	--do the filter list
	addon:EnableFilterList()

	--iniate playerInfo events
	initPlayerInfo()
    if IsInGuild() then
      C_GuildInfo.GuildRoster()
    end
	initUpdateCurrentPlayer()

	--turn off profanity filter
	if addon.SetCVar then
		addon.SetCVar("profanityFilter", 0)
	end

	--do the sticky channels list
	addon:EnableStickyChannelsList()

	--do we disable enter/leaving/changed channel notifications?
	addon:setDisableChatEnterLeaveNotice()

	--toggle class colors
	for i,v in pairs(CHAT_CONFIG_CHAT_LEFT) do
		ToggleChatColorNamesByClassGroup(true, v.type)
	end

	--this is to toggle class colors for all the global channels that is not listed under CHAT_CONFIG_CHAT_LEFT
	for iCh = 1, 15 do
		ToggleChatColorNamesByClassGroup(true, "CHANNEL"..iCh)
	end

	--do the custom outgoing whisper color
	addon:setOutWhisperColor()

	--check for chat box fading
	if XCHT_DB.disableChatFrameFade then
		disableChatFrameFading()
	end

	--show/hide the chat social buttons
	if addon.IsRetail and XCHT_DB.hideSocial then
		QuickJoinToastButton:Hide()
		QuickJoinToastButton:SetScript("OnShow", dummy)
	end

	if addon.IsRetail and XCHT_DB.moveSocialButtonToBottom then
		ChatAlertFrame:ClearAllPoints()
		ChatAlertFrame:SetPoint("TOPLEFT",  ChatFrame1, "BOTTOMLEFT",  -33, -60)
	end

	if XCHT_DB.hideChatMenuButton then
		ChatFrameMenuButton:Hide()
		ChatFrameMenuButton:SetScript("OnShow", dummy)
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
	--https://github.com/tomrus88/BlizzardInterfaceCode/blob/e2b884c714b3e751a9ec84b89a5fda964f35da05/Interface/FrameXML/FloatingChatFrame.lua

	--Note forcing some of these variables causes taint errors in Edit Mode
	-- if XCHT_DB.hideTabs then
		-- --set the blizzard global variables to make the alpha of the chat tabs completely invisible
		-- CHAT_TAB_HIDE_DELAY = 1
		-- CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA = 0.6
		-- CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0
		-- CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA = 1
		-- CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 0
		-- CHAT_FRAME_TAB_ALERTING_MOUSEOVER_ALPHA = 1
		-- CHAT_FRAME_TAB_ALERTING_NOMOUSE_ALPHA = 0
	-- else
		-- --set defaults
		-- CHAT_TAB_HIDE_DELAY = 1
		-- CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA = 1.0
		-- CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 0.4
		-- CHAT_FRAME_TAB_ALERTING_MOUSEOVER_ALPHA = 1.0
		-- CHAT_FRAME_TAB_ALERTING_NOMOUSE_ALPHA = 1.0
		-- CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA = 0.6
		-- CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0.2
	-- end

	--toggle the voice chat buttons if disabled
	if XCHT_DB.hideVoice then
		if ChatFrameToggleVoiceDeafenButton then ChatFrameToggleVoiceDeafenButton:Hide() end
		if ChatFrameToggleVoiceMuteButton then ChatFrameToggleVoiceMuteButton:Hide() end
		if ChatFrameChannelButton then ChatFrameChannelButton:Hide() end
	end

	--remove the annoying guild loot messages by replacing them with the original ones
	YOU_LOOT_MONEY_GUILD = YOU_LOOT_MONEY
	LOOT_MONEY_SPLIT_GUILD = LOOT_MONEY_SPLIT

	--finally, setup all the chat frames
	for i = 1, NUM_CHAT_WINDOWS do
		SetupChatFrame(i)
	end

	--DO SLASH COMMANDS
	SLASH_XANCHAT1 = "/xanchat"
	SlashCmdList["XANCHAT"] = function(msg)
		local cmd = msg and msg:lower():match("^%s*(%S+)") or ""
		if cmd == "debug" then
			XCHT_DB.debugWrapper = not XCHT_DB.debugWrapper
			addon.wrapperDebug = XCHT_DB.debugWrapper
			DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: wrapper debug "..(addon.wrapperDebug and "ON" or "OFF"))
			if addon.wrapperDebug then
				DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: wrapper loaded = "..tostring(addon.wrapperLoaded))
			end
			return
		end

		if Settings then
			Settings.OpenToCategory("xanChat")
		elseif InterfaceOptionsFrame_OpenToCategory then

			if not addon.IsRetail and InterfaceOptionsFrame then
				--only do this for Expansions less than Retail
				InterfaceOptionsFrame:Show() --has to be here to load the about frame onLoad
			else
				if InCombatLockdown() or GameMenuFrame:IsShown() or InterfaceOptionsFrame then
					return false
				end
			end

			InterfaceOptionsFrame_OpenToCategory(addon.aboutPanel)
		end
	end

	if XCHT_DB.lockChatSettings then
		DEFAULT_CHAT_FRAME:AddMessage("|cFF20ff20XanChat|r: "..L.LockChatSettingsAlert)
	end

	addon:RegisterEvent("UI_SCALE_CHANGED")
	addonLoaded = true

	--once everything is loaded updated the settings for the chat, only do this once per updated version
	if XCHT_DB.dbVer == nil or XCHT_DB.dbVer ~= ver then
		for i = 1, NUM_CHAT_WINDOWS do
			local n = ("ChatFrame%d"):format(i)
			local f = _G[n]

			if f then
				saveChatSettings(f)
			end
		end
		XCHT_DB.dbVer = ver
	end

	if addon.configFrame then addon.configFrame:EnableConfig() end

	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFF20ff20%s|r] loaded:   /xanchat", ADDON_NAME, ver or "1.0"))
end

--this is the fix for alt-tabbing resizing our chatboxes
function addon:UI_SCALE_CHANGED()
	for i = 1, NUM_CHAT_WINDOWS do
		local n = ("ChatFrame%d"):format(i)
		local f = _G[n]
		if f then
			--restore any settings and layout
			restoreChatSettings(f)

			--always lock the frames regardless (using both calls just in case)
			SetChatWindowLocked(i, true)
			FCF_SetLocked(f, true)
		end
	end
end

--this is for temporary Whisper windows.  They are NUM_CHAT_WINDOWS + 1 and so forth
local old_OpenTemporaryWindow = FCF_OpenTemporaryWindow
FCF_OpenTemporaryWindow = function(...)
	local frame = old_OpenTemporaryWindow(...)
	SetupChatFrame(frame:GetID())
	return frame
end
