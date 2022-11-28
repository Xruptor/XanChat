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
L.Page = "Page"
L.CopyChat = "Copy Chat"
L.Done = "Done"
L.Page = "Page"
L.CopyChatError = "There was an error in Copy Chat function."
L.AdditionalSettings = "Additional Settings"
L.ChangeOutgoingWhisperColor = "Change outgoing whisper chat color."
L.EnableOutWhisperColor = "Enable custom outgoing whisper chat color."
L.DisableChatEnterLeaveNotice = "Disable chat channel (|cFF99CC33Enter/Leave/Changed|r) notifications."

L.ProtectedChannel = " |cFFDF2B2B(Channel is protected by Blizzard. Addon access is prohibited.)|r."

--Channel Config (Only change the actual english word, leave the characters.  It's case sensitive!)
--trailing dash is to check for things like [WorldDefense - Alterac Mountains] so it will remove location
L.ChannelGeneral = "(%[%d+%. )General.-%]"
L.ChannelTrade = "(%[%d+%. )Trade.-%]"
L.ChannelWorldDefense = "(%[%d+%. )WorldDefense.-%]"
L.ChannelLocalDefense = "(%[%d+%. )LocalDefense.-%]"
L.ChannelLookingForGroup = "(%[%d+%. )LookingForGroup.-%]"
L.ChannelGuildRecruitment = "(%[%d+%. )GuildRecruitment.-%]"
L.ChannelNewComerChat = "(%[%d+%. )Newcomer Chat.-%]"
L.ChannelTradeServices  = "(%[%d+%. )Trade %([^()]*%).-%]"

L.ShortGeneral = "GN"
L.ShortTrade = "TR"
L.ShortWorldDefense = "WD"
L.ShortLocalDefense = "LD"
L.ShortLookingForGroup = "LFG"
L.ShortGuildRecruitment = "GR"
L.ShortNewComerChat = "NC"
L.ShortTradeServices = "TRS"

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

L.EditFilterListHeader = "Edit Stylized Filter List"
L.EditStickyChannelsListHeader = "Edit Sticky Channels List"

L.SocialOn = "xanChat: Social buttons are now [|cFF99CC33ON|r]"
L.SocialOff = "xanChat: Social buttons are now [|cFF99CC33OFF|r]"
L.SocialInfo = "Hide the social button."

L.ScrollOn = "xanChat: Scroll buttons are now [|cFF99CC33ON|r]"
L.ScrollOff = "xanChat: Scroll buttons are now [|cFF99CC33OFF|r]"
L.ScrollInfo = "Hide the chat scroll bars."

L.ShortNamesOn = "xanChat: Short channel names are now [|cFF99CC33ON|r]"
L.ShortNamesOff = "xanChat: Short channel names are now [|cFF99CC33OFF|r]"
L.ShortNamesInfo = "Use channel short names."

L.EditBoxBottom = "xanChat: The edit box is now at the [|cFF99CC33BOTTOM|r]"
L.EditBoxTop = "xanChat: The edit box is now at the [|cFF99CC33TOP|r]"
L.EditBoxInfo = "Show Editbox on the top of the chat window."

L.TabsOn = "xanChat: The chat tabs are now [|cFF99CC33ON|r]"
L.TabsOff = "xanChat: The chat tabs are now [|cFF99CC33OFF|r]"
L.TabsInfo = "Hide the chat tabs."

L.ShadowOn = "xanChat: Chat font shadows are now [|cFF99CC33ON|r]"
L.ShadowOff = "xanChat: Chat font shadows are now [|cFF99CC33OFF|r]"
L.ShadowInfo = "Add shadows to the chat text font. |cFFDF2B2B(Overrides outline option.)|r"

L.OutlineOn = "xanChat: Chat font outline are now [|cFF99CC33ON|r]"
L.OutlineOff = "xanChat: Chat font outline are now [|cFF99CC33OFF|r]"
L.OutlineInfo = "Add outlines to the chat text font."

L.VoiceOn = "xanChat: Voice chat buttons are now [|cFF99CC33ON|r]"
L.VoiceOff = "xanChat: Voice chat buttons are now [|cFF99CC33OFF|r]"
L.VoiceInfo = "Hide the chat voice button."

L.EditBoxBorderOn = "xanChat: EditBox Border is [|cFF99CC33ON|r]"
L.EditBoxBorderOff = "xanChat: EditBox Border is [|cFF99CC33OFF|r]"
L.EditBoxBorderInfo = "Hide the EditBox Border."

L.SimpleEditBoxOn = "xanChat: Simple EditBox is [|cFF99CC33ON|r]"
L.SimpleEditBoxOff = "xanChat: Simple EditBox is [|cFF99CC33OFF|r]"
L.SimpleEditBoxInfo = "Show a simplified EditBox with tooltip border."

L.SEBDesignOn = "xanChat: Simple EditBox alternate box style is [|cFF99CC33ON|r]"
L.SEBDesignOff = "xanChat: Simple EditBox alternate box style is [|cFF99CC33OFF|r]"
L.SEBDesignInfo = "Enable alternate box style for Editbox."

L.CopyPasteOn = "xanChat: Copy and Paste button is [|cFF99CC33ON|r]"
L.CopyPasteOff = "xanChat: Copy and Paste button is [|cFF99CC33OFF|r]"
L.CopyPasteInfo = "Show a copy and paste button in the chat window."

L.CopyPasteLeftOn = "xanChat: Copy and Paste Button positioned to the left is [|cFF99CC33ON|r]"
L.CopyPasteLeftOff = "xanChat: Copy and Paste Button positioned to the left is [|cFF99CC33OFF|r]"
L.CopyPasteLeftInfo = "Show the copy and paste button to the left of the chat frame."

L.PlayerChatStyleOn = "xanChat: Stylized Player Names [Level+Color] is [|cFF99CC33ON|r]"
L.PlayerChatStyleOff = "xanChat: Stylized Player Names [Level+Color] is [|cFF99CC33OFF|r]"
L.PlayerChatStyleInfo = "Show stylized player names and level in chat. |cFF99CC33(Uses Stylized Filter List Above)|r"

L.ChatTextFadeOn = "xanChat: Chat Text Fade is [|cFF99CC33ON|r]"
L.ChatTextFadeOff = "xanChat: Chat Text Fade is [|cFF99CC33OFF|r]"
L.ChatTextFadeInfo = "Enable text fade on chat frames."

L.ChatFrameFadeOn = "xanChat: Disable Chat Frame Fade is [|cFF99CC33ON|r]"
L.ChatFrameFadeOff = "xanChat: Disable Chat Frame Fade is [|cFF99CC33OFF|r]"
L.ChatFrameFadeInfo = "Disable background fade on chat frames."

L.LockChatSettingsOn = "xanChat: Chat Settings Lock is [|cFF99CC33ON|r]"
L.LockChatSettingsOff = "xanChat: Chat Settings Lock is [|cFF99CC33OFF|r]"
L.LockChatSettingsInfo = "Lock the chat settings and positions from being modified."
L.LockChatSettingsAlert = "Chat Settings [|cFFFF6347LOCKED|r]."

L.ChatAlphaSet = "xanChat: Chat alpha transparency has been set to [|cFF20ff20%s|r]"
L.ChatAlphaSetInvalid = "xanChat: Alpha invalid or number cannot be greater than 2"
L.ChatAlphaInfo = "Set the alpha transparency level of the chat frame. (0-100)"
L.ChatAlphaText = "Chat Frame Alpha Transparency"

L.AdjustedEditboxOn = "xanChat: Space adjusted Editbox is [|cFF99CC33ON|r]"
L.AdjustedEditboxOff = "xanChat: Space adjusted Editbox is [|cFF99CC33OFF|r]"
L.AdjustedEditboxInfo = "Enable additional space between the chat frame and Editbox."

L.ChatChannelButtonOn = "xanChat: Chat channel are now [|cFF99CC33ON|r]"
L.ChatChannelButtonOff = "xanChat: Chat channel are now [|cFF99CC33OFF|r]"
L.ChatChannelButtonInfo = "Hide the chat channel button."

L.MoveSocialButtonOn = "xanChat: Move Social and Toast Alert Frame to the bottom. [|cFF99CC33ON|r]"
L.MoveSocialButtonOff = "xanChat: Move Social and Toast Alert Frame to the bottom. [|cFF99CC33OFF|r]"
L.MoveSocialButtonInfo = "Move the social button and toast alert frame to the bottom."
