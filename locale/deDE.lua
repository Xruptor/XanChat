local ADDON_NAME, addon = ...

local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "deDE")
if not L then return end

L.WhoPlayer = "Who Player?"
L.GuildInvite = "Guild Invite"
L.CopyName = "Copy Name"
L.URLCopy = "URL COPY"
L.ApplyChanges = "xanChat: Die Benutzeroberfläche --MUSS-- neu geladen werden um die Änderungen zu übernehmen!"
L.Yes = "Ja"
L.No = "Nein"
L.Page = "Seite"
L.CopyChat = "Chat kopieren"
L.Done = "Fertig"
L.Page = "Seite"
L.CopyChatError = "Beim Kopieren des Chats ist ein Fehler aufgetreten."
L.AdditionalSettings = "Erweiterte Einstellungen"
L.ChangeOutgoingWhisperColor = "Farbe des ausgehenden Flüsterchats ändern."
L.EnableOutWhisperColor = "Benutzerdefinierte Farbe für ausgehende Flüsterchats aktivieren."
L.DisableChatEnterLeaveNotice = "Channel-Benachhrichtigungen (|cFF99CC33Beitreten/Verlassen/Wechseln|r) ausschalten."

L.ProtectedChannel = " |cFFDF2B2B(Channel ist von Blizzard geschützt. Addon-Zugriff ist nicht erlaut.)|r."

--Channel Config (Only change the actual english word, leave the	 characters.  It's case sensitive!)
--trailing dash is to check for things like [WorldDefense - Alterac Mountains] so it will remove location
L.ChannelGeneral = "(%[%d+%. )Allgemein.-%]"
L.ChannelTrade = "(%[%d+%. )Handel.-%]"
L.ChannelWorldDefense = "(%[%d+%. )Weltverteidigung.-%]"
L.ChannelLocalDefense = "(%[%d+%. )LokaleVerteidigung.-%]"
L.ChannelLookingForGroup = "(%[%d+%. )SucheNachGruppe.-%]"
L.ChannelGuildRecruitment = "(%[%d+%. )Gildenrekrutierung.-%]"
L.ChannelNewComerChat = "(%[%d+%. )Einsteigerchat.-%]"
L.ChannelTradeServices  = "(%[%d+%. )Handel %([^()]*%).-%]"

L.ShortGeneral = "A"
L.ShortTrade = "H"
L.ShortWorldDefense = "WV"
L.ShortLocalDefense = "LV"
L.ShortLookingForGroup = "SNG"
L.ShortGuildRecruitment = "GR"
L.ShortNewComerChat = "EC"
L.ShortTradeServices = "HS"
	
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

L.EditFilterListHeader = "Stilisierte Filterliste bearbeiten"
L.EditStickyChannelsListHeader = "Sticky Channels-Liste bearbeiten"

L.SocialOn = "xanChat: Schaltfläche für die Kontakte ist jetzt [|cFF99CC33AN|r]"
L.SocialOff = "xanChat: Schaltfläche für die Kontakte ist jetzt [|cFF99CC33AUS|r]"
L.SocialInfo = "Schaltfläche für die Kontakte ausblenden."

L.ScrollOn = "xanChat: Bildlaufpfeile sind jetzt [|cFF99CC33AN|r]"
L.ScrollOff = "xanChat: Bildlaufpfeile sind jetzt [|cFF99CC33AUS|r]"
L.ScrollInfo = "Bildlaufpfeile ausblenden."

L.ShortNamesOn = "xanChat: Abkürzungen für die Chat-Channels sind jetzt [|cFF99CC33AN|r]"
L.ShortNamesOff = "xanChat: Abkürzungen für die Chat-Channels sind jetzt [|cFF99CC33AUS|r]"
L.ShortNamesInfo = "Abkürzungen für die Chat-Channels benutzen."

L.EditBoxBottom = "xanChat: Eingabefenster ist jetzt [|cFF99CC33UNTEN|r]"
L.EditBoxTop = "xanChat: Eingabefenster ist jetzt [|cFF99CC33OBEN|r]"
L.EditBoxInfo = "Eingabefenster oberhalb des Chat-Fensters anzeigen."

L.TabsOn = "xanChat: Chat-Tabs sind jetzt [|cFF99CC33AN|r]"
L.TabsOff = "xanChat: Chat-Tabs sind jetzt [|cFF99CC33AUS|r]"
L.TabsInfo = "Chat-Tabs ausblenden."

L.ShadowOn = "xanChat: Kontur und Schatten sind jetzt [|cFF99CC33AN|r]"
L.ShadowOff = "xanChat: Kontur und Schatten sind jetzt [|cFF99CC33AUS|r]"
L.ShadowInfo = "Kontur und Schatten dem Chat-Text hinzufügen. |cFFDF2B2B(Überschreibt die Kontureinstellung.)|r"

L.OutlineOn = "xanChat: Kontur ist jetzt [|cFF99CC33AN|r]"
L.OutlineOff = "xanChat: Kontur ist jetzt [|cFF99CC33AUS|r]"
L.OutlineInfo = "Kontur dem Chat-Text hinzufügen."

L.VoiceOn = "xanChat: Schaltfläche für die Chat-Channels ist jetzt [|cFF99CC33AN|r]"
L.VoiceOff = "xanChat: Schaltfläche für die Chat-Channels ist jetzt [|cFF99CC33AUS|r]"
L.VoiceInfo = "Schaltfläche für die Chat-Channels ausblenden."

L.EditBoxBorderOn = "xanChat: Hintergrund ist jetzt [|cFF99CC33AN|r]"
L.EditBoxBorderOff = "xanChat: Hintergrund ist jetzt [|cFF99CC33AUS|r]"
L.EditBoxBorderInfo = "Hintergrund vom Eingabefenster ausblenden."

L.SimpleEditBoxOn = "xanChat: Vereinfachtes Eingabefenster ist jetzt [|cFF99CC33AN|r]"
L.SimpleEditBoxOff = "xanChat: Vereinfachtes Eingabefenster ist jetzt [|cFF99CC33AUS|r]"
L.SimpleEditBoxInfo = "Vereinfachtes Eingabefenster mit dem Rahmen des Tooltips benutzen."

L.SEBDesignOn = "xanChat: Alternativer Stil ist jetzt [|cFF99CC33AN|r]"
L.SEBDesignOff = "xanChat: Alternativer Stil ist jetzt [|cFF99CC33AUS|r]"
L.SEBDesignInfo = "Alternativen Stil für das vereinfachte Eingabefenster einschalten."

L.CopyPasteOn = "xanChat: Schaltfläche zum Kopieren/Einfügen ist jetzt [|cFF99CC33AN|r]"
L.CopyPasteOff = "xanChat: Schaltfläche zum Kopieren/Einfügen ist jetzt [|cFF99CC33AUS|r]"
L.CopyPasteInfo = "Schaltfläche zum Kopieren/Einfügen im Chat-Fenster anzeigen."

L.CopyPasteLeftOn = "xanChat: Schaltfläche zum Kopieren/Einfügen ist jetzt [|cFF99CC33LINKS|r]"
L.CopyPasteLeftOff = "xanChat: Schaltfläche zum Kopieren/Einfügen ist jetzt [|cFF99CC33RECHTS|r]"
L.CopyPasteLeftInfo = "Schaltfläche zum Kopieren/Einfügen auf der linken Seite anzeigen."

L.PlayerChatStyleOn = "xanChat: Stilisierte Spielernamen und Level sind jetzt [|cFF99CC33AN|r]"
L.PlayerChatStyleOff = "xanChat: Stilisierte Spielernamen und Level sind jetzt [|cFF99CC33AUS|r]"
L.PlayerChatStyleInfo = "Stilisierte Spielernamen und Level im Chat anzeigen. |cFF99CC33(Benutzt die Filterliste oben.)|r"

L.ChatTextFadeOn = "xanChat: Ausblenden des Chat-Textes ist jetzt [|cFF99CC33AN|r]"
L.ChatTextFadeOff = "xanChat: Ausblenden des Chat-Textes ist jetzt [|cFF99CC33AUS|r]"
L.ChatTextFadeInfo = "Ausblenden des Chat-Textes einschalten."

L.ChatFrameFadeOn = "xanChat: Ausblenden des Hintergrunds ist jetzt [|cFF99CC33AN|r]"
L.ChatFrameFadeOff = "xanChat: Ausblenden des Hintergrunds ist jetzt [|cFF99CC33AUS|r]"
L.ChatFrameFadeInfo = "Ausblenden des Hintergrunds ausschalten."

L.LockChatSettingsOn = "xanChat: Sperrung der Chat-Einstellungen ist jetzt [|cFF99CC33AN|r]"
L.LockChatSettingsOff = "xanChat: Sperrung der Chat-Einstellungen ist jetzt [|cFF99CC33AUS|r]"
L.LockChatSettingsInfo = "Chat-Einstellungen und Positionen gegen Änderungen sperren."
L.LockChatSettingsAlert = "Chat Settings [|cFFFF6347LOCKED|r]."

L.ChatAlphaSet = "xanChat: Transparenz wurde auf [|cFF20ff20%s|r] gesetzt"
L.ChatAlphaSetInvalid = "xanChat: Alpha invalid or number cannot be greater than 2"
L.ChatAlphaInfo = "Transparenz des Chat-Fensters festlegen. (0-100)"
L.ChatAlphaText = "Transparenz des Chat-Fensters"

L.AdjustedEditboxOn = "xanChat: Zusätzlicher Abstand ist jetzt [|cFF99CC33AN|r]"
L.AdjustedEditboxOff = "xanChat: Zusätzlicher Abstand ist jetzt [|cFF99CC33AUS|r]"
L.AdjustedEditboxInfo = "Zusätzlichen Abstand zwischen Eingabefenster und Chat-Fenster einschalten."

L.ChatMenuButtonOn = "xanChat: Schaltfläche für die Chat-Menü ist jetzt [|cFF99CC33AN|r]"
L.ChatMenuButtonOff = "xanChat: Schaltfläche für die Chat-Menü ist jetzt [|cFF99CC33AUS|r]"
L.ChatMenuButtonInfo = "Schaltfläche für das Chat-Menü ausblenden."

L.MoveSocialButtonOn = "xanChat: Schaltfläche für die Kontakte ist jetzt [|cFF99CC33UNTEN|r]"
L.MoveSocialButtonOff = "xanChat: Schaltfläche für die Kontakte ist jetzt [|cFF99CC33OBEN|r]"
L.MoveSocialButtonInfo = "Schaltfläche für die Kontakte unterhalb des Chat-Fensters anzeigen."