--[[
	PatternMatching.lua - Pattern matching system for XanChat
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- PATTERN MATCHING SYSTEM
-- ============================================================================

local PatternRegistry = { patterns = {}, sortedList = {}, sorted = true }
local tokennum = 0
local MatchTable = {}

-- UUID generator for pattern IDs
local function uuid()
	local template = 'xyxxxxyx'
	return template:gsub('[xy]', function(c)
		local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
		return string.format('%x', v)
	end)
end

-- Register a pattern with the pattern matching engine
local function RegisterPattern(pattern, owner)
	local idx
	repeat
		idx = uuid()
	until PatternRegistry.patterns[idx] == nil

	PatternRegistry.patterns[idx] = pattern
	table.insert(PatternRegistry.sortedList, pattern)
	PatternRegistry.sorted = false

	pattern.owner = owner
	pattern.idx = idx

	if addon.dbg then addon.dbg("RegisterPattern: idx="..tostring(idx).." priority="..tostring(pattern.priority)) end
	return idx
end

-- Unregister all patterns for a specific owner
local function UnregisterAllPatterns(owner)
	if addon.dbg then addon.dbg("UnregisterAllPatterns: owner="..tostring(owner)) end

	for i = #PatternRegistry.sortedList, 1, -1 do
		local pattern = PatternRegistry.sortedList[i]
		if pattern and pattern.owner == owner then
			table.remove(PatternRegistry.sortedList, i)
			PatternRegistry.patterns[pattern.idx] = nil
		end
	end
end

-- RegisterMatch: Create a token for matched text
function RegisterMatch(text, ptype)
	tokennum = tokennum + 1

	local token = "@##"..tokennum.."##@"

	if addon.dbg then addon.dbg("RegisterMatch: token="..token.." text="..addon.dbgSafeValue(text)) end

	local mt = MatchTable[ptype or "FRAME"]
	if not mt then
		MatchTable[ptype or "FRAME"] = {}
		mt = MatchTable[ptype or "FRAME"]
	end
	mt[token] = text

	return token
end

-- Remove matched strings and replace them with temporary tokens
local function MatchPatterns(m, ptype)
	local text = m.message_text or ""

	-- Secret value guard
	if _G.issecretvalue and _G.issecretvalue(text) then
		if addon.dbg then addon.dbg("MatchPatterns: secret value, returning") end
		return text
	end

	ptype = ptype or "FRAME"
	tokennum = 0

	-- Sort patterns by priority
	if not PatternRegistry.sorted then
		table.sort(PatternRegistry.sortedList, function(a, b)
			local ap = a.priority or 50
			local bp = b.priority or 50
			return ap < bp
		end)
		PatternRegistry.sorted = true
	end

	-- Match and remove strings
	for _, v in ipairs(PatternRegistry.sortedList) do
		if text and ptype == (v.type or "FRAME") then
				if type(v.pattern) == "string" and string.len(v.pattern) > 0 then
					if addon.dbg then addon.dbg("MatchPatterns: checking pattern="..tostring(v.pattern)) end
					if v.matchfunc ~= nil then
						text = string.gsub(text, v.pattern, function(...)
							local parms = { ... }
							table.insert(parms, m)
							return v.matchfunc(unpack(parms))
						end)
					end
			end
		end
	end

	if addon.dbg then addon.dbg("MatchPatterns: result="..addon.dbgSafeValue(text)) end
	return text
end

-- Put tokenized matches back into the text
local function ReplaceMatches(m, ptype)
	local text = m.message_text or ""

	-- Secret value guard
	if _G.issecretvalue and _G.issecretvalue(text) then
		if addon.dbg then addon.dbg("ReplaceMatches: secret value, returning") end
		return text
	end

	ptype = ptype or "FRAME"
	local mt = MatchTable[ptype]

	-- Substitute tokens back
	for t = tokennum, 1, -1 do
		local k = "@##"..tostring(t).."##@"

		if mt and mt[k] then
			local cleaned = mt[k]:gsub("([%%W])", "%%%1")
			text = string.gsub(text, k, cleaned)
		else
			if addon.dbg then addon.dbg("ReplaceMatches: token not found: "..k) end
		end
		if mt then
			mt[k] = nil
		end
	end

	if addon.dbg then addon.dbg("ReplaceMatches: result="..addon.dbgSafeValue(text)) end
	return text
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.MatchPatterns = MatchPatterns
addon.ReplaceMatches = ReplaceMatches
addon.RegisterPattern = RegisterPattern
addon.UnregisterAllPatterns = UnregisterAllPatterns
