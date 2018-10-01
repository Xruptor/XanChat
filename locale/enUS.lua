
local L = LibStub("AceLocale-3.0"):NewLocale("xanChat", "enUS", true)
if not L then return end

--for non-english fonts
--https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/FrameXML/Fonts.xml

--Get the best possible font for the localization langugage.
--Some fonts are better than others to display special character sets.
L.GetFontType = "Fonts\\FRIZQT__.TTF"

L.WhoPlayer = "Who Player?"
L.GuildInvite = "Guild Invite"
L.CopyName = "Copy Name"
L.URLCopy = "URL COPY"
L.ApplyChanges = "xanChat: UI must be reloaded to apply changes!"
L.Yes = "Yes"
L.No = "No"

--Channel Config (Only change the actual english word, leave the characters.  It's case sensitive!)
L.ChannelGeneral = "%[%d+%. General.-%]"
L.ChannelTrade = "%[%d+%. Trade.-%]"
L.ChannelWorldDefense = "%[%d+%. WorldDefense%]"
L.ChannelLocalDefense = "%[%d+%. LocalDefense.-%]"
L.ChannelLookingForGroup = "%[%d+%. LookingForGroup%]"
L.ChannelGuildRecruitment = "%[%d+%. GuildRecruitment.-%]"

L.ShortGeneral = "GN"
L.ShortTrade = "TR"
L.ShortWorldDefense = "WD"
L.ShortLocalDefense = "LD"
L.ShortLookingForGroup = "LFG"
L.ShortGuildRecruitment = "GR"
	
--short channel globals
--Example: "|Hchannel:  Channel Type   |h  [short channel name]   |h %s: " 
--Example Yell: "|Hchannel:  Yell  |h  [Y]  |h %s: "   Channel Type = Yell, short name = Y
L.CHAT_WHISPER_GET 				= "[W] %s: "
L.CHAT_WHISPER_INFORM_GET 		= "[W2] %s: "
L.CHAT_YELL_GET 				= "|Hchannel:Yell|h[Y]|h %s: " 
L.CHAT_SAY_GET 					= "|Hchannel:Say|h[S]|h %s: "
L.CHAT_BATTLEGROUND_GET			= "|Hchannel:Battleground|h[BG]|h %s: "
L.CHAT_BATTLEGROUND_LEADER_GET 	= [[|Hchannel:Battleground|h[BG|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]]
L.CHAT_GUILD_GET   				= "|Hchannel:Guild|h[G]|h %s: "
L.CHAT_OFFICER_GET 				= "|Hchannel:Officer|h[O]|h %s: "
L.CHAT_PARTY_GET        			= "|Hchannel:Party|h[P]|h %s: "
L.CHAT_PARTY_LEADER_GET 			= [[|Hchannel:Party|h[P|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]]
L.CHAT_PARTY_GUIDE_GET  			= [[|Hchannel:Party|h[PG|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]]
L.CHAT_RAID_GET         			= "|Hchannel:Raid|h[R]|h %s: "
L.CHAT_RAID_LEADER_GET  			= [[|Hchannel:Raid|h[R|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]]
L.CHAT_RAID_WARNING_GET 			= [[|Hchannel:RaidWarning|h[RW|TInterface\GroupFrame\UI-GROUP-MAINASSISTICON:0|t]|h %s: ]]

L.SlashSocial = "social"
L.SlashSocialOn = "xanChat: Social buttons are now [|cFF99CC33ON|r]"
L.SlashSocialOff = "xanChat: Social buttons are now [|cFF99CC33OFF|r]"
L.SlashSocialInfo = "Toggles the chat social buttons"

L.SlashScroll = "scroll"
L.SlashScrollOn = "xanChat: Scroll buttons are now [|cFF99CC33ON|r]"
L.SlashScrollOff = "xanChat: Scroll buttons are now [|cFF99CC33OFF|r]"
L.SlashScrollInfo = "Toggles the chat scroll bars"

L.SlashShortNames = "shortnames"
L.SlashShortNamesOn = "xanChat: Short channel names are now [|cFF99CC33ON|r]"
L.SlashShortNamesOff = "xanChat: Short channel names are now [|cFF99CC33OFF|r]"
L.SlashShortNamesInfo = "Toggles short channels names"

L.SlashEditBox = "editbox"
L.SlashEditBoxBottom = "xanChat: The edit box is now at the [|cFF99CC33BOTTOM|r]"
L.SlashEditBoxTop = "xanChat: The edit box is now at the [|cFF99CC33TOP|r]"
L.SlashEditBoxInfo = "Toggles editbox to show at the top or the bottom"

L.SlashTabs = "tabs"
L.SlashTabsOn = "xanChat: The chat tabs are now [|cFF99CC33ON|r]"
L.SlashTabsOff = "xanChat: The chat tabs are now [|cFF99CC33OFF|r]"
L.SlashTabsInfo = "Toggles the chat tabs on or off"

L.SlashShadow = "shadow"
L.SlashShadowOn = "xanChat: Chat font shadows are now [|cFF99CC33ON|r]"
L.SlashShadowOff = "xanChat: Chat font shadows are now [|cFF99CC33OFF|r]"
L.SlashShadowInfo= "Toggles text shadows for chat fonts on or off"

L.SlashVoice = "voice"
L.SlashVoiceOn = "xanChat: Voice chat buttons are now [|cFF99CC33ON|r]"
L.SlashVoiceOff = "xanChat: Voice chat buttons are now [|cFF99CC33OFF|r]"
L.SlashVoiceInfo = "Toggles voice chat buttons on or off"
