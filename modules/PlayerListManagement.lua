--[[
	PlayerListManagement.lua - Player list management and caching for XanChat
	Improvements:
	- Consolidated event registration with table loop
	- Reduced redundant secret value checks
	- Simplified throttle function
	- Better nil handling in getPlayerInfo
	- Improved addToPlayerList flow
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- PLAYER LIST MANAGEMENT
-- ============================================================================

local PLAYERLIST_MAX = 1000

-- Strips and removes all whitespace characters. "Area 52" -> "area52"
local function stripAndLowercase(text)
	if not text then return "" end
	return string.lower(string.gsub(text, "%s+", ""))
end

-- Strips and removes all non-alphanumeric. "Player-Area52" -> "playerarea52"
local function stripNameKey(text)
	if not text then return "" end
	return string.lower(string.gsub(text, "[^%a%d]", ""))
end

local function rotatePlayerListEntry(key, name, lowerName, cleanName, entry)
	if not addon or not key or not entry then return end

	local ring = addon.playerListRing
	local pos = (addon.playerListRingPos or 0) + 1
	if pos > PLAYERLIST_MAX then pos = 1 end
	addon.playerListRingPos = pos

	local old = ring[pos]
	if old then
		local current = addon.playerList and addon.playerList[old.key]
		if current and current._sig == old.sig and not current._pinned then
			addon.playerList[old.key] = nil
			local byName = addon.playerListByName
			if byName then
				for k, v in pairs(byName) do
					if v == current then
						byName[k] = nil
					end
				end
			end
		end
	end

	addon.playerListSig = (addon.playerListSig or 0) + 1
	entry._sig = addon.playerListSig
	ring[pos] = { key = key, sig = entry._sig, name = name, lowerName = lowerName, cleanName = cleanName }
end

-- ============================================================================
-- PLAYER LIST RETRIEVAL
-- ============================================================================

-- NOTE: Cannot do secret value lookups on tables!
-- Player List Management is NOT used for secret values for comparisons,
-- inclusion, insertion or anything dealing with the player name tables.
-- Secret Values cannot be compared to anything!

local function getPlayerInfo(guid, nameWithRealm, playerName, serverName)
	if not addon then return end

	local result = nil
	local isSecret = addon.isSecretValue

	-- 1. Check guid first (if provided and not secret)
	if guid and not isSecret(guid) and type(guid) == "string" then
		result = addon.playerListByName and addon.playerListByName[guid]
		if result and addon.dbg then
			addon.dbg("-->getPlayerInfo: found by guid="..addon.dbgSafeValue(guid))
		end
	end

	-- 2. Check exact name with realm (e.g., "Xruptor-Area52")
	if not result and nameWithRealm and not isSecret(nameWithRealm) and type(nameWithRealm) == "string" then
		result = addon.playerListByName and addon.playerListByName[nameWithRealm]
		if result and addon.dbg then
			addon.dbg("-->getPlayerInfo: found by nameWithRealm="..addon.dbgSafeValue(nameWithRealm))
		end

		-- Try lowercase version if not found
		if not result then
			local lowerWithRealm = nameWithRealm:lower()
			result = addon.playerListByName and addon.playerListByName[lowerWithRealm]
			if result and addon.dbg then
				addon.dbg("-->getPlayerInfo: found by lowerWithRealm="..addon.dbgSafeValue(lowerWithRealm))
			end
		end
	end

	-- 3+4. Combined name lookups — only worth trying if both are safe strings
	if not result and playerName and serverName then
		local nameIsSecret = isSecret(playerName)
		local realmIsSecret = isSecret(serverName)

		if not nameIsSecret and not realmIsSecret and type(playerName) == "string" and type(serverName) == "string" then
			-- 3. Try exact combined name (and lowercase variant)
			local combinedName = playerName.."-"..serverName
			result = addon.playerListByName and addon.playerListByName[combinedName]

			if not result then
				local lowerCombined = combinedName:lower()
				result = addon.playerListByName and addon.playerListByName[lowerCombined]
				if result and addon.dbg then
					addon.dbg("-->getPlayerInfo: found by combined lowercase="..addon.dbgSafeValue(lowerCombined))
				end
			elseif result and addon.dbg then
				addon.dbg("-->getPlayerInfo: found by combined name="..addon.dbgSafeValue(combinedName))
			end

			-- 4. Try cleanName + realmKey combination
			if not result then
				local cleanName = stripNameKey(playerName) or playerName:lower()
				local realmKey = stripAndLowercase(serverName)
				local key = cleanName.."-"..realmKey
				result = addon.playerList and addon.playerList[key]

				if result and addon.dbg then
					addon.dbg("-->getPlayerInfo: found by cleanName-key="..addon.dbgSafeValue(key))
				end
			end
		end
	end

	return result
end

local function addToPlayerList(guid, name, realm, level, class, bnName, pin)
	if not addon then return end

	if addon and addon.dbg then
		addon.dbg("addToPlayerList: guid="..addon.dbgSafeValue(guid).."name="..addon.dbgSafeValue(name).." level="..addon.dbgSafeValue(level).." class="..addon.dbgSafeValue(class).." realm="..addon.dbgSafeValue(realm))
	end

	if not name or not level or not class or level <= 0 then
		return
	end

	addon.chkClassList = addon.chkClassList or {}
	if next(addon.chkClassList) == nil and _G.GetNumClasses and _G.GetClassInfo then
		for i = 1, _G.GetNumClasses() do
			local className, classFile = _G.GetClassInfo(i)
			if className and classFile then
				addon.chkClassList[className] = classFile
			end
		end
	end

	local playerName, playerServer = string.match(name, "([^%-]+)%-?(.*)")
	local playerWithRealm

	if playerName and playerServer then
		playerWithRealm = name
	end

	if playerName and playerName ~= "" then
		name = playerName
	end
	if playerServer and playerServer ~= "" then
		realm = playerServer
	end
	if not realm or realm == "" then
		realm = GetRealmName()
	end
	if not name or not realm then
		return
	end

	if addon.chkClassList[class] then
		class = addon.chkClassList[class]
	end

	local realmKey = stripAndLowercase(realm)
	local lowerName = string.lower(name)
	local cleanName = stripNameKey(name) or lowerName
	local key = cleanName.."-"..realmKey
	local entry = addon.playerList[key]
	local isNew = false

	if entry then
		entry.guid = guid
		entry.name = name
		entry.realm = realm
		entry.stripRealm = realmKey
		entry.cleanName = cleanName
		entry.level = level
		entry.class = class
		entry.BNname = bnName
	else
		entry = {
			guid = guid,
			name = name,
			realm = realm,
			stripRealm = realmKey,
			cleanName = cleanName,
			level = level,
			class = class,
			BNname = bnName,
		}
		addon.playerList[key] = entry
		isNew = true
	end

	if pin then
		entry._pinned = true
	end

	playerWithRealm = playerWithRealm or name.."-"..realm
	addon.playerListByName[playerWithRealm] = entry
	addon.playerListByName[playerWithRealm:lower()] = entry

	if guid then
		addon.playerListByName[guid] = entry
	end

	if (isNew or not entry._sig) and not entry._pinned then
		rotatePlayerListEntry(key, name, lowerName, cleanName, entry)
	end
end

local function initUpdateCurrentPlayer()
	local _, classFile = UnitClass("player")
	local name, realm = UnitName("player")
	local level = UnitLevel("player")
	local guid = UnitGUID("player")

	if addon and addon.dbg then
		addon.dbg("-->initUpdateCurrentPlayer: name="..addon.dbgSafeValue(name).." level="..addon.dbgSafeValue(level).." class="..addon.dbgSafeValue(classFile))
	end

	if name and level and level > 0 then
		addToPlayerList(guid, name, realm, level, classFile, nil, true)
	end
end

local function doRosterUpdate()
	local inRaid = IsInRaid()
	local inGroup = inRaid or IsInGroup()
	if not inGroup then return end

	local playerNum = inRaid and GetNumGroupMembers() or MAX_PARTY_MEMBERS
	local unit = inRaid and "raid" or "party"

	for i = 1, playerNum do
		local unitId = unit..i
		if UnitExists(unitId) then
			local playerName, playerServer = UnitName(unitId)
			local className, classFile = UnitClass(unitId)
			local level = UnitLevel(unitId)
			local guid = UnitGUID(unitId)

			if addon and addon.dbg and playerName then
				addon.dbg("-->doRosterUpdate: unit="..addon.dbgSafeValue(unitId).." name="..addon.dbgSafeValue(playerName).." className="..addon.dbgSafeValue(className).." classFile="..addon.dbgSafeValue(classFile).." level="..addon.dbgSafeValue(level))
			end

			if playerName and level and level > 0 and classFile and classFile ~= 0 then
				addToPlayerList(guid, playerName, playerServer, level, classFile)
			elseif playerName and level and level > 0 and (not classFile or classFile == 0) then
				if addon and addon.dbg then
					addon.dbg("-->doRosterUpdate: Adding player with class=0: "..addon.dbgSafeValue(playerName))
				end
				addToPlayerList(guid, playerName, playerServer, level, 0)
			end
		end
	end
end

local function doFriendUpdate()
	local realmName = GetRealmName()
	if C_FriendList and C_FriendList.GetNumFriends then
		for i = 1, C_FriendList.GetNumFriends() or 0 do
			local info = C_FriendList.GetFriendInfoByIndex(i)
			if info and info.connected then
				addToPlayerList(info.guid, info.name, realmName, info.level, info.className, nil, true)
			end
		end
	end

	if C_BattleNet and BNGetNumFriends and C_BattleNet.GetFriendAccountInfo then
		for i = 1, BNGetNumFriends() do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo and accountInfo.gameAccountInfo then
				local friendInfo = accountInfo.gameAccountInfo
				if friendInfo and friendInfo.isOnline and friendInfo.clientProgram == BNET_CLIENT_WOW then
					local accountName = accountInfo.isBattleTagFriend and accountInfo.battleTag or accountInfo.accountName
					if friendInfo.characterName and friendInfo.realmName and friendInfo.characterLevel and friendInfo.className then
						addToPlayerList(friendInfo.playerGuid, friendInfo.characterName, friendInfo.realmName, friendInfo.characterLevel, friendInfo.className, accountName, true)
					end
				end
			end
		end
	end
end

local function doGuildUpdate()
	if not IsInGuild() then return end
	if C_GuildInfo and C_GuildInfo.GuildRoster then
		C_GuildInfo.GuildRoster()
	elseif GuildRoster then
		GuildRoster()
	end

	local numMembers = GetNumGuildMembers and GetNumGuildMembers(true) or 0
	for i = 1, numMembers do
		local name, _, _, level, _, _, _, _, online, _, class, _, _, _, _, _, guid = GetGuildRosterInfo(i)

		if online and name then
			local playerName, playerServer = string.match(name, "([^%-]+)%-?(.*)")
			if playerName and playerServer and playerServer ~= "" then
				addToPlayerList(guid, playerName, playerServer, level, class, nil, true)
			else
				addToPlayerList(guid, name, GetRealmName(), level, class, nil, true)
			end
		end
	end
end

-- ============================================================================
-- PLAYER INFO INITIALIZATION
-- ============================================================================

local function initPlayerInfo()
	if not addon then return end

	if not (XCHT_DB and XCHT_DB.enablePlayerChatStyle) then
		return
	end

	local throttlePending = {}
	local function throttle(key, delay, fn)
		if throttlePending[key] then return end
		throttlePending[key] = true
		if C_Timer and C_Timer.After then
			C_Timer.After(delay, function()
				throttlePending[key] = nil
				fn()
			end)
		else
			throttlePending[key] = nil
			fn()
		end
	end

	-- Consolidated event registration with table loop
	local EVENT_HANDLERS = {
		{ "GUILD_ROSTER_UPDATE", "guild", 0.5, doGuildUpdate },
		{ "PLAYER_GUILD_UPDATE", "guild", 0.5, doGuildUpdate },
		{ "FRIENDLIST_UPDATE", "friends", 0.5, doFriendUpdate },
		{ "BN_CONNECTED", "friends", 0.5, doFriendUpdate },
		{ "BN_DISCONNECTED", "friends", 0.5, doFriendUpdate },
		{ "BN_FRIEND_ACCOUNT_ONLINE", "friends", 0.5, doFriendUpdate },
		{ "BN_FRIEND_ACCOUNT_OFFLINE", "friends", 0.5, doFriendUpdate },
		{ "RAID_ROSTER_UPDATE", "roster", 0.3, doRosterUpdate },
		{ "GROUP_ROSTER_UPDATE", "roster", 0.3, doRosterUpdate },
		{ "PLAYER_ENTERING_WORLD", "roster", 0.3, doRosterUpdate },
		{ "UPDATE_INSTANCE_INFO", "roster", 0.3, doRosterUpdate },
		{ "ZONE_CHANGED_NEW_AREA", "roster", 0.3, doRosterUpdate },
		{ "UNIT_NAME_UPDATE", "roster", 0.3, doRosterUpdate },
		{ "UNIT_PORTRAIT_UPDATE", "roster", 0.3, doRosterUpdate },
		{ "PLAYER_LEVEL_UP", "levelup", 0, initUpdateCurrentPlayer },
	}

	for _, eventInfo in ipairs(EVENT_HANDLERS) do
		local event, throttleKey, delay, handler = unpack(eventInfo)
		if handler == initUpdateCurrentPlayer then
			addon:RegisterEvent(event, handler)
		else
			addon:RegisterEvent(event, function() throttle(throttleKey, delay, handler) end)
		end
	end
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.getPlayerInfo = getPlayerInfo
addon.addToPlayerList = addToPlayerList
addon.initPlayerInfo = initPlayerInfo
addon.initUpdateCurrentPlayer = initUpdateCurrentPlayer
addon.doRosterUpdate = doRosterUpdate
addon.doFriendUpdate = doFriendUpdate
addon.doGuildUpdate = doGuildUpdate
