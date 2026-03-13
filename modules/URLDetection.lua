--[[
	URLDetection.lua - URL detection and linking for XanChat
]]

local ADDON_NAME, private = ...
local addon = _G[ADDON_NAME]

addon.private = private or addon.private
addon.L = (private and private.L) or addon.L or {}

-- ============================================================================
-- URL DETECTION AND LINKING
-- ============================================================================

local function buildUrlLink(url)
	-- Build clickable URL link with green coloring
	-- Format: |cff99FF33|Hurl:url|h[url]|h|r
	return " |cff99FF33|Hurl:" .. url .. "|h[" .. url .. "]|h|r "
end

local URL_PATTERNS = {
	{
		pattern = "(%a+)://(%S+)%s?",
		matchfunc = function(scheme, remainder)
			return _G.RegisterMatch(buildUrlLink(scheme .. "://" .. remainder), "FRAME")
		end,
		priority = 50,
		type = "FRAME",
	},
	{
		pattern = "www%.([_A-Za-z0-9-]+)%.(%S+)%s?",
		matchfunc = function(domain, tail)
			return _G.RegisterMatch(buildUrlLink("www." .. domain .. "." .. tail), "FRAME")
		end,
		priority = 50,
		type = "FRAME",
	},
	{
		pattern = "([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?",
		matchfunc = function(user, domain, dots, tld)
			return _G.RegisterMatch(buildUrlLink(user .. "@" .. domain .. dots .. tld), "FRAME")
		end,
		priority = 50,
		type = "FRAME",
	},
	{
		pattern = "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?):(%d%d?%d?%d?%d?)%s?",
		matchfunc = function(a, b, c, d, port)
			return _G.RegisterMatch(buildUrlLink(a .. "." .. b .. "." .. c .. "." .. d .. ":" .. port), "FRAME")
		end,
		priority = 50,
		type = "FRAME",
	},
	{
		pattern = "(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?",
		matchfunc = function(a, b, c, d)
			return _G.RegisterMatch(buildUrlLink(a .. "." .. b .. "." .. c .. "." .. d), "FRAME")
		end,
		priority = 50,
		type = "FRAME",
	},
}

local function registerUrlPatterns()
	if not addon then return end

	if addon._urlPatternsRegistered then
		if addon.dbg then addon.dbg("registerUrlPatterns: already registered") end
		return
	end
	if addon.dbg then addon.dbg("registerUrlPatterns: registering " .. #URL_PATTERNS .. " URL patterns") end
	for _, pat in ipairs(URL_PATTERNS) do
		addon.RegisterPattern(pat, "xanChat-URL")
	end
	addon._urlPatternsRegistered = true
end

local function unregisterUrlPatterns()
	if not addon then return end

	if not addon._urlPatternsRegistered then
		return
	end
	addon.UnregisterAllPatterns("xanChat-URL")
	addon._urlPatternsRegistered = false
end

local function installUrlCopyHook()
	if not addon then return end

	if addon._urlCopyHookInstalled then
		return
	end
	if not _G.ItemRefTooltip or not _G.ItemRefTooltip.SetHyperlink then
		return
	end

	_G.StaticPopupDialogs["LINKME"] = _G.StaticPopupDialogs["LINKME"] or {
		text = addon.L and addon.L.URLCopy or "Copy URL",
		button2 = _G.CANCEL,
		hasEditBox = true,
		hasWideEditBox = true,
		timeout = 0,
		exclusive = 1,
		hideOnEscape = 1,
		EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
		whileDead = 1,
		maxLetters = 255,
	}

	if not addon._origItemRefTooltipSetHyperlink then
		addon._origItemRefTooltipSetHyperlink = _G.ItemRefTooltip.SetHyperlink
	end
	local originalSetHyperlink = addon._origItemRefTooltipSetHyperlink
	_G.ItemRefTooltip.SetHyperlink = function(self, link, ...)
		if type(link) == "string" and string.sub(link, 1, 3) == "url" then
			local url = string.sub(link, 5)
			local dialog = _G.StaticPopup_Show("LINKME")
			if dialog then
				local editbox = _G[dialog:GetName() .. "EditBox"]
				if editbox then
					editbox:SetText(url)
					editbox:SetFocus()
					editbox:HighlightText()
					local button = _G[dialog:GetName() .. "Button2"]
					if button then
						button:ClearAllPoints()
						button:SetPoint("CENTER", editbox, "CENTER", 0, -30)
					end
				end
			end
			return
		end
		return originalSetHyperlink(self, link, ...)
	end

	addon._urlCopyHookInstalled = true
end

local function uninstallUrlCopyHook()
	if not addon or not addon._urlCopyHookInstalled then
		return
	end
	if _G.ItemRefTooltip and addon._origItemRefTooltipSetHyperlink then
		_G.ItemRefTooltip.SetHyperlink = addon._origItemRefTooltipSetHyperlink
	end
	addon._urlCopyHookInstalled = false
end

-- ============================================================================
-- EXPORT FUNCTIONS TO ADDON
-- ============================================================================

addon.registerUrlPatterns = registerUrlPatterns
addon.unregisterUrlPatterns = unregisterUrlPatterns
addon.installUrlCopyHook = installUrlCopyHook
addon.uninstallUrlCopyHook = uninstallUrlCopyHook
addon.buildUrlLink = buildUrlLink
