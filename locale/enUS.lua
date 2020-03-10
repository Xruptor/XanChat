local ADDON_NAME, addon = ...

local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "enUS", true)
if not L then return end

L.WhoPlayer = "Who Player?"
L.GuildInvite = "Guild Invite"
L.CopyName = "Copy Name"
L.URLCopy = "URL COPY"
L.ApplyChanges = "xanChat: UI --MUST-- be reloaded to apply changes!"
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
L.CHAT_YELL_GET 				= "|Hchannel:yell|h[Y]|h %s: " 
L.CHAT_SAY_GET 					= "|Hchannel:say|h[S]|h %s: "
L.CHAT_BATTLEGROUND_GET			= "|Hchannel:battleground|h[BG]|h %s: "
L.CHAT_BATTLEGROUND_LEADER_GET 	= [[|Hchannel:battleground|h[BG|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]]
L.CHAT_GUILD_GET   				= "|Hchannel:guild|h[G]|h %s: "
L.CHAT_OFFICER_GET 				= "|Hchannel:officer|h[O]|h %s: "
L.CHAT_PARTY_GET        			= "|Hchannel:party|h[P]|h %s: "
L.CHAT_PARTY_LEADER_GET 			= [[|Hchannel:party|h[P|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]]
L.CHAT_PARTY_GUIDE_GET  			= [[|Hchannel:party|h[PG|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]]
L.CHAT_RAID_GET         			= "|Hchannel:raid|h[R]|h %s: "
L.CHAT_RAID_LEADER_GET  			= [[|Hchannel:raid|h[R|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]]
L.CHAT_RAID_WARNING_GET 			= [[|Hchannel:raidwarning|h[RW|TInterface\GroupFrame\UI-GROUP-MAINASSISTICON:0|t]|h %s: ]]

L.EditFilterListHeader = "Stylized Filter List"

L.SlashSocial = "social"
L.SlashSocialOn = "xanChat: Social buttons are now [|cFF99CC33ON|r]"
L.SlashSocialOff = "xanChat: Social buttons are now [|cFF99CC33OFF|r]"
L.SlashSocialInfo = "Hide the chat social button."

L.SlashScroll = "scroll"
L.SlashScrollOn = "xanChat: Scroll buttons are now [|cFF99CC33ON|r]"
L.SlashScrollOff = "xanChat: Scroll buttons are now [|cFF99CC33OFF|r]"
L.SlashScrollInfo = "Hide the chat scroll bars."

L.SlashShortNames = "shortnames"
L.SlashShortNamesOn = "xanChat: Short channel names are now [|cFF99CC33ON|r]"
L.SlashShortNamesOff = "xanChat: Short channel names are now [|cFF99CC33OFF|r]"
L.SlashShortNamesInfo = "Use channel short names."

L.SlashEditBox = "editbox"
L.SlashEditBoxBottom = "xanChat: The edit box is now at the [|cFF99CC33BOTTOM|r]"
L.SlashEditBoxTop = "xanChat: The edit box is now at the [|cFF99CC33TOP|r]"
L.SlashEditBoxInfo = "Show editbox on the top of the chat window."

L.SlashTabs = "tabs"
L.SlashTabsOn = "xanChat: The chat tabs are now [|cFF99CC33ON|r]"
L.SlashTabsOff = "xanChat: The chat tabs are now [|cFF99CC33OFF|r]"
L.SlashTabsInfo = "Hide the chat tabs."

L.SlashShadow = "shadow"
L.SlashShadowOn = "xanChat: Chat font shadows are now [|cFF99CC33ON|r]"
L.SlashShadowOff = "xanChat: Chat font shadows are now [|cFF99CC33OFF|r]"
L.SlashShadowInfo= "Add shadows to the chat text font."

L.SlashVoice = "voice"
L.SlashVoiceOn = "xanChat: Voice chat buttons are now [|cFF99CC33ON|r]"
L.SlashVoiceOff = "xanChat: Voice chat buttons are now [|cFF99CC33OFF|r]"
L.SlashVoiceInfo = "Hide the chat voice button."

L.SlashEditBoxBorder = "editboxborder"
L.SlashEditBoxBorderOn = "xanChat: EditBox Border is [|cFF99CC33ON|r]"
L.SlashEditBoxBorderOff = "xanChat: EditBox Border is [|cFF99CC33OFF|r]"
L.SlashEditBoxBorderInfo = "Hide the EditBox Border."

L.SlashSimpleEditBox = "simpleeditbox"
L.SlashSimpleEditBoxOn = "xanChat: Simple EditBox is [|cFF99CC33ON|r]"
L.SlashSimpleEditBoxOff = "xanChat: Simple EditBox is [|cFF99CC33OFF|r]"
L.SlashSimpleEditBoxInfo = "Show a simplified EditBox with tooltip border."

L.SlashSEBDesign = "sebdesign"
L.SlashSEBDesignOn = "xanChat: Simple EditBox alternate box style is [|cFF99CC33ON|r]"
L.SlashSEBDesignOff = "xanChat: Simple EditBox alternate box style is [|cFF99CC33OFF|r]"
L.SlashSEBDesignInfo = "Enable alternate box style for Editbox."

L.SlashCopyPaste = "copypaste"
L.SlashCopyPasteOn = "xanChat: Copy and Paste button is [|cFF99CC33ON|r]"
L.SlashCopyPasteOff = "xanChat: Copy and Paste button is [|cFF99CC33OFF|r]"
L.SlashCopyPasteInfo = "Show a copy and paste button in the chat window."

L.SlashCopyPasteLeft = "copyleft"
L.SlashCopyPasteLeftOn = "xanChat: Copy and Paste Button positioned to the left is [|cFF99CC33ON|r]"
L.SlashCopyPasteLeftOff = "xanChat: Copy and Paste Button positioned to the left is [|cFF99CC33OFF|r]"
L.SlashCopyPasteLeftInfo = "Show the copy and paste button to the left of the chat frame."

L.SlashPlayerChatStyle = "playerchatstyle"
L.SlashPlayerChatStyleOn = "xanChat: Stylized Player Names [Level+Color] is [|cFF99CC33ON|r]"
L.SlashPlayerChatStyleOff = "xanChat: Stylized Player Names [Level+Color] is [|cFF99CC33OFF|r]"
L.SlashPlayerChatStyleInfo = "Show stylized player names and level in chat. |cFF99CC33(Uses Stylized Filter List Above)|r"

L.SlashChatTextFade = "textfade"
L.SlashChatTextFadeOn = "xanChat: Chat Text Fade is [|cFF99CC33ON|r]"
L.SlashChatTextFadeOff = "xanChat: Chat Text Fade is [|cFF99CC33OFF|r]"
L.SlashChatTextFadeInfo = "Enable text fade on chat frames."

L.SlashChatFrameFade = "chatfade"
L.SlashChatFrameFadeOn = "xanChat: Chat Frame Fade is [|cFF99CC33ON|r]"
L.SlashChatFrameFadeOff = "xanChat: Chat Frame Fade is [|cFF99CC33OFF|r]"
L.SlashChatFrameFadeInfo = "Enable background fade on chat frames."

L.SlashLockChatSettings = "lockchat"
L.SlashLockChatSettingsOn = "xanChat: Chat Settings Lock is [|cFF99CC33ON|r]"
L.SlashLockChatSettingsOff = "xanChat: Chat Settings Lock is [|cFF99CC33OFF|r]"
L.SlashLockChatSettingsInfo = "Lock the chat settings and positions from being modified."
L.SlashLockChatSettingsAlert = "Chat Settings [|cFFFF6347LOCKED|r]."

L.SlashChatAlpha = "chatalpha"
L.SlashChatAlphaSet = "xanChat: Chat alpha transparency has been set to [|cFF20ff20%s|r]"
L.SlashChatAlphaSetInvalid = "xanChat: Alpha invalid or number cannot be greater than 2"
L.SlashChatAlphaInfo = "Set the alpha transparency level of the chat frame. (0-100)"
L.SlashChatAlphaText = "Chat Frame Alpha Transparency"
