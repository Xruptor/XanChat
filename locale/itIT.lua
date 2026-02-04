local ADDON_NAME, private = ...

local L = private:NewLocale("itIT")
if not L then return end

L.WhoPlayer = "Chi è il giocatore?"
L.GuildInvite = "Invito di gilda"
L.CopyName = "Copia nome"
L.URLCopy = "COPIA URL"
L.ApplyChanges = "xanChat: L'UI --DEVE-- essere ricaricata per applicare le modifiche!"
L.Yes = "Sì"
L.No = "No"
L.Page = "Pagina"
L.CopyChat = "Copia chat"
L.Done = "Fatto"
L.CopyChatError = "Si è verificato un errore nella funzione Copia chat."
L.AdditionalSettings = "Impostazioni aggiuntive"
L.ChangeOutgoingWhisperColor = "Cambia il colore dei sussurri in uscita."
L.EnableOutWhisperColor = "Abilita colore personalizzato per i sussurri in uscita."
L.DisableChatEnterLeaveNotice = "Disabilita notifiche del canale (|cFF99CC33Entra/Esci/Modificato|r)."

L.ProtectedChannel = " |cFFDF2B2B(Il canale è protetto da Blizzard. L'accesso dell'addon è proibito.)|r."

--Channel Config (Only change the actual english word, leave the characters.  It's case sensitive!)
--trailing dash is to check for things like [WorldDefense - Alterac Mountains] so it will remove location
L.ChannelGeneral = "(%[%d+%. )Generale.-%]"
L.ChannelTrade = "(%[%d+%. )Commercio.-%]"
L.ChannelWorldDefense = "(%[%d+%. )DifesaGlobale.-%]"
L.ChannelLocalDefense = "(%[%d+%. )DifesaLocale.-%]"
L.ChannelLookingForGroup = "(%[%d+%. )CercaGruppo.-%]"
L.ChannelGuildRecruitment = "(%[%d+%. )ReclutamentoGilda.-%]"
L.ChannelNewComerChat = "(%[%d+%. )Chat dei nuovi arrivati.-%]"
L.ChannelTradeServices  = "(%[%d+%. )Commercio %([^()]*%).-%]"

L.ShortGeneral = "GE"
L.ShortTrade = "CO"
L.ShortWorldDefense = "DG"
L.ShortLocalDefense = "DL"
L.ShortLookingForGroup = "CG"
L.ShortGuildRecruitment = "RG"
L.ShortNewComerChat = "NA"
L.ShortTradeServices = "CS"

--short channel globals
--Example: "|Hchannel:  Channel Type   |h  [short channel name]   |h %s: " 
--Example Yell: "|Hchannel:  Yell  |h  [Y]  |h %s: "   Channel Type = Yell, short name = Y
L.CHAT_WHISPER_GET 				= "[W] %s: "
L.CHAT_WHISPER_INFORM_GET 		= "[W2] %s: "
L.CHAT_YELL_GET 					= "|Hchannel:yell|h[Y]|h %s: " 
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

L.EditFilterListHeader = "Modifica lista filtri stilizzati"
L.EditStickyChannelsListHeader = "Modifica lista canali fissi"

L.SocialOn = "xanChat: Pulsanti social ora [|cFF99CC33ON|r]"
L.SocialOff = "xanChat: Pulsanti social ora [|cFF99CC33OFF|r]"
L.SocialInfo = "Nascondi il pulsante social."

L.ScrollOn = "xanChat: Pulsanti di scorrimento ora [|cFF99CC33ON|r]"
L.ScrollOff = "xanChat: Pulsanti di scorrimento ora [|cFF99CC33OFF|r]"
L.ScrollInfo = "Nascondi le barre di scorrimento della chat."

L.HideScrollBarsOn = "xanChat: Nascondi barre pulsanti sinistra e destra ora [|cFF99CC33ON|r]"
L.HideScrollBarsOff = "xanChat: Nascondi barre pulsanti sinistra e destra ora [|cFF99CC33OFF|r]"
L.HideScrollBarsInfo = "Nasconde le barre di pulsanti sinistra e destra nelle finestre di chat. |cFFDF2B2B(Nasconde tutti i pulsanti!)|r"

L.ShortNamesOn = "xanChat: Nomi canali brevi ora [|cFF99CC33ON|r]"
L.ShortNamesOff = "xanChat: Nomi canali brevi ora [|cFF99CC33OFF|r]"
L.ShortNamesInfo = "Usa nomi canali brevi."

L.EditBoxBottom = "xanChat: La casella di testo ora è in [|cFF99CC33BASSO|r]"
L.EditBoxTop = "xanChat: La casella di testo ora è in [|cFF99CC33ALTO|r]"
L.EditBoxInfo = "Mostra la casella di testo in alto nella finestra di chat."

L.TabsOn = "xanChat: Le schede chat ora [|cFF99CC33ON|r]"
L.TabsOff = "xanChat: Le schede chat ora [|cFF99CC33OFF|r]"
L.TabsInfo = "Nascondi le schede chat."

L.ShadowOn = "xanChat: Ombre del font chat ora [|cFF99CC33ON|r]"
L.ShadowOff = "xanChat: Ombre del font chat ora [|cFF99CC33OFF|r]"
L.ShadowInfo = "Aggiungi ombre al font del testo chat. |cFFDF2B2B(Sovrascrive l'opzione contorno.)|r"

L.OutlineOn = "xanChat: Contorno del font chat ora [|cFF99CC33ON|r]"
L.OutlineOff = "xanChat: Contorno del font chat ora [|cFF99CC33OFF|r]"
L.OutlineInfo = "Aggiungi contorno al font del testo chat."

L.EditBoxBorderOn = "xanChat: Bordo della casella di testo [|cFF99CC33ON|r]"
L.EditBoxBorderOff = "xanChat: Bordo della casella di testo [|cFF99CC33OFF|r]"
L.EditBoxBorderInfo = "Nascondi il bordo della casella di testo."

L.SimpleEditBoxOn = "xanChat: Casella di testo semplice [|cFF99CC33ON|r]"
L.SimpleEditBoxOff = "xanChat: Casella di testo semplice [|cFF99CC33OFF|r]"
L.SimpleEditBoxInfo = "Mostra una casella di testo semplificata con bordo tooltip."

L.SEBDesignOn = "xanChat: Stile alternativo casella di testo semplice [|cFF99CC33ON|r]"
L.SEBDesignOff = "xanChat: Stile alternativo casella di testo semplice [|cFF99CC33OFF|r]"
L.SEBDesignInfo = "Abilita stile alternativo per la casella di testo."

L.CopyPasteOn = "xanChat: Pulsante copia e incolla ora [|cFF99CC33ON|r]"
L.CopyPasteOff = "xanChat: Pulsante copia e incolla ora [|cFF99CC33OFF|r]"
L.CopyPasteInfo = "Mostra un pulsante copia e incolla nella finestra di chat."

L.CopyPasteLeftOn = "xanChat: Pulsante copia e incolla a sinistra [|cFF99CC33ON|r]"
L.CopyPasteLeftOff = "xanChat: Pulsante copia e incolla a sinistra [|cFF99CC33OFF|r]"
L.CopyPasteLeftInfo = "Mostra il pulsante copia e incolla a sinistra del frame chat."

L.PlayerChatStyleOn = "xanChat: Nomi giocatore stilizzati [Livello+Colore] [|cFF99CC33ON|r]"
L.PlayerChatStyleOff = "xanChat: Nomi giocatore stilizzati [Livello+Colore] [|cFF99CC33OFF|r]"
L.PlayerChatStyleInfo = "Mostra nomi giocatore stilizzati e livello in chat. |cFF99CC33(Usa la lista filtri stilizzati sopra)|r"

L.ChatTextFadeOn = "xanChat: Dissolvenza testo chat [|cFF99CC33ON|r]"
L.ChatTextFadeOff = "xanChat: Dissolvenza testo chat [|cFF99CC33OFF|r]"
L.ChatTextFadeInfo = "Abilita dissolvenza del testo nei frame chat."

L.ChatFrameFadeOn = "xanChat: Disabilita dissolvenza frame chat [|cFF99CC33ON|r]"
L.ChatFrameFadeOff = "xanChat: Disabilita dissolvenza frame chat [|cFF99CC33OFF|r]"
L.ChatFrameFadeInfo = "Disabilita la dissolvenza dello sfondo nei frame chat."

L.LockChatSettingsOn = "xanChat: Blocco impostazioni chat [|cFF99CC33ON|r]"
L.LockChatSettingsOff = "xanChat: Blocco impostazioni chat [|cFF99CC33OFF|r]"
L.LockChatSettingsInfo = "Blocca le impostazioni e le posizioni della chat per evitare modifiche."
L.LockChatSettingsAlert = "Impostazioni chat [|cFFFF6347BLOCCATE|r]."

L.ChatAlphaSet = "xanChat: La trasparenza del chat è stata impostata a [|cFF20ff20%s|r]"
L.ChatAlphaSetInvalid = "xanChat: Alpha non valido o numero non può essere maggiore di 2"
L.ChatAlphaInfo = "Imposta il livello di trasparenza del frame chat. (0-100)"
L.ChatAlphaText = "Trasparenza del frame chat"

L.AdjustedEditboxOn = "xanChat: Spazio casella di testo regolato [|cFF99CC33ON|r]"
L.AdjustedEditboxOff = "xanChat: Spazio casella di testo regolato [|cFF99CC33OFF|r]"
L.AdjustedEditboxInfo = "Abilita spazio aggiuntivo tra il frame chat e la casella di testo."

L.VoiceOn = "xanChat: Pulsanti canale/voce ora [|cFF99CC33ON|r]"
L.VoiceOff = "xanChat: Pulsanti canale/voce ora [|cFF99CC33OFF|r]"
L.VoiceInfo = "Nascondi il pulsante canale/voce."

L.ChatMenuButtonOn = "xanChat: Menu chat ora [|cFF99CC33ON|r]"
L.ChatMenuButtonOff = "xanChat: Menu chat ora [|cFF99CC33OFF|r]"
L.ChatMenuButtonInfo = "Nascondi il pulsante menu chat."

L.MoveSocialButtonOn = "xanChat: Sposta social e avvisi in basso. [|cFF99CC33ON|r]"
L.MoveSocialButtonOff = "xanChat: Sposta social e avvisi in basso. [|cFF99CC33OFF|r]"
L.MoveSocialButtonInfo = "Sposta il pulsante social e il frame avvisi in basso."

L.PageLimitText = "Pagine chat recenti da mostrare in Copia chat. |cFF99CC33(0 senza limite)|r"
