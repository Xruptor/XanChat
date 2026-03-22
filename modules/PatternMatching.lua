--[[
	PatternMatching.lua - Pattern matching system for XanChat
	Improvements:
	- Simplified UUID generation with inline function
	- Improved token management with single source of truth
	- Better pattern registry with lazy sorting
	- Reduced redundant type checks
	- More efficient match/replace cycle
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- PATTERN MATCHING SYSTEM
-- ============================================================================

local PatternRegistry = { patterns = {}, sortedList = {}, sorted = true }
local tokenCount = 0
local MatchTable = {}

-- UUID generator - simple and efficient
local function generateUUID()
	return string.gsub('xyxxxxyx', '[xy]', function(c)
		return string.format('%x', c == 'x' and math.random(0, 0xf) or math.random(8, 0xb))
	end)
end

-- Register a pattern with the pattern matching engine
local function RegisterPattern(pattern, owner)
	local idx
	repeat
		idx = generateUUID()
	until not PatternRegistry.patterns[idx]

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

-- Register a match token for temporary storage
function RegisterMatch(text, ptype)
	tokenCount = tokenCount + 1
	local token = "@##"..tokenCount.."##@"

	if addon.dbg then addon.dbg("RegisterMatch: token="..token.." text="..addon.dbgSafeValue(text)) end

	local mt = MatchTable[ptype or "FRAME"]
	if not mt then
		MatchTable[ptype or "FRAME"] = {}
		mt = MatchTable[ptype or "FRAME"]
	end
	mt[token] = text

	return token
end

-- Match patterns against text and replace with tokens
local function MatchPatterns(m, ptype)
	local text = m.message_text or ""

	-- Secret value guard - cannot pattern match secret values
	if addon.isSecretValue(text) then
		if addon.dbg then addon.dbg("MatchPatterns: secret value, returning") end
		return text
	end

	ptype = ptype or "FRAME"
	tokenCount = 0

	-- Sort patterns by priority only when needed
	if not PatternRegistry.sorted then
		table.sort(PatternRegistry.sortedList, function(a, b)
			return (a.priority or 50) < (b.priority or 50)
		end)
		PatternRegistry.sorted = true
	end

	-- Match and replace patterns
	for _, pattern in ipairs(PatternRegistry.sortedList) do
		if text and ptype == (pattern.type or "FRAME") and type(pattern.pattern) == "string" and string.len(pattern.pattern) > 0 and pattern.matchfunc then
			if addon.dbg then addon.dbg("MatchPatterns: checking pattern="..tostring(pattern.pattern)) end
			text = string.gsub(text, pattern.pattern, function(...)
				local parms = { ... }
				table.insert(parms, m)
				return pattern.matchfunc(unpack(parms))
			end)
		end
	end

	if addon.dbg then addon.dbg("MatchPatterns: result="..addon.dbgSafeValue(text)) end
	return text
end

-- Replace tokens with their matched text
local function ReplaceMatches(m, ptype)
	local text = m.message_text or ""

	-- Secret value guard
	if addon.isSecretValue(text) then
		if addon.dbg then addon.dbg("ReplaceMatches: secret value, returning") end
		return text
	end

	ptype = ptype or "FRAME"
	local mt = MatchTable[ptype]

	-- Substitute tokens back in reverse order (most recent first)
	for i = tokenCount, 1, -1 do
		local token = "@##"..tostring(i).."##@"
		local match = mt and mt[token]

		if match then
			local cleaned = string.gsub(match, "([%%W])", "%%%1")
			text = string.gsub(text, token, cleaned)
		elseif addon.dbg then
			addon.dbg("ReplaceMatches: token not found: "..token)
		end

		if mt then
			mt[token] = nil
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
