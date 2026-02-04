local ADDON_NAME, private = ...

local L = private:NewLocale("frFR")
if not L then return end

L.WhoPlayer = "Qui est le joueur ?"
L.GuildInvite = "Invitation de guilde"
L.CopyName = "Copier le nom"
L.URLCopy = "COPIER URL"
L.ApplyChanges = "xanChat : L'IU --DOIT-- être rechargée pour appliquer les changements !"
L.Yes = "Oui"
L.No = "Non"
L.Page = "Page"
L.CopyChat = "Copier le chat"
L.Done = "Terminé"
L.CopyChatError = "Une erreur s'est produite lors de la copie du chat."
L.AdditionalSettings = "Paramètres supplémentaires"
L.ChangeOutgoingWhisperColor = "Changer la couleur des chuchotements sortants."
L.EnableOutWhisperColor = "Activer une couleur personnalisée pour les chuchotements sortants."
L.DisableChatEnterLeaveNotice = "Désactiver les notifications de canal (|cFF99CC33Entrée/Sortie/Changé|r)."

L.ProtectedChannel = " |cFFDF2B2B(Canal protégé par Blizzard. Accès addon interdit.)|r."

--Channel Config (Only change the actual english word, leave the characters.  It's case sensitive!)
--trailing dash is to check for things like [WorldDefense - Alterac Mountains] so it will remove location
L.ChannelGeneral = "(%[%d+%. )Général.-%]"
L.ChannelTrade = "(%[%d+%. )Commerce.-%]"
L.ChannelWorldDefense = "(%[%d+%. )DéfenseGlobale.-%]"
L.ChannelLocalDefense = "(%[%d+%. )DéfenseLocale.-%]"
L.ChannelLookingForGroup = "(%[%d+%. )RechercheDeGroupe.-%]"
L.ChannelGuildRecruitment = "(%[%d+%. )RecrutementDeGuilde.-%]"
L.ChannelNewComerChat = "(%[%d+%. )Discussion des nouveaux.-%]"
L.ChannelTradeServices  = "(%[%d+%. )Commerce %([^()]*%).-%]"

L.ShortGeneral = "GE"
L.ShortTrade = "CO"
L.ShortWorldDefense = "DG"
L.ShortLocalDefense = "DL"
L.ShortLookingForGroup = "RDG"
L.ShortGuildRecruitment = "RG"
L.ShortNewComerChat = "NV"
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

L.EditFilterListHeader = "Modifier la liste de filtres stylisés"
L.EditStickyChannelsListHeader = "Modifier la liste des canaux persistants"

L.SocialOn = "xanChat : Boutons sociaux maintenant [|cFF99CC33ON|r]"
L.SocialOff = "xanChat : Boutons sociaux maintenant [|cFF99CC33OFF|r]"
L.SocialInfo = "Masquer le bouton social."

L.ScrollOn = "xanChat : Boutons de défilement maintenant [|cFF99CC33ON|r]"
L.ScrollOff = "xanChat : Boutons de défilement maintenant [|cFF99CC33OFF|r]"
L.ScrollInfo = "Masquer les barres de défilement du chat."

L.HideScrollBarsOn = "xanChat : Masquer les barres de boutons gauche et droite maintenant [|cFF99CC33ON|r]"
L.HideScrollBarsOff = "xanChat : Masquer les barres de boutons gauche et droite maintenant [|cFF99CC33OFF|r]"
L.HideScrollBarsInfo = "Masque les barres de boutons gauche et droite des fenêtres de chat. |cFFDF2B2B(Masque tous les boutons !)|r"

L.ShortNamesOn = "xanChat : Noms courts de canaux maintenant [|cFF99CC33ON|r]"
L.ShortNamesOff = "xanChat : Noms courts de canaux maintenant [|cFF99CC33OFF|r]"
L.ShortNamesInfo = "Utiliser des noms courts de canaux."

L.EditBoxBottom = "xanChat : La zone de saisie est maintenant en [|cFF99CC33BAS|r]"
L.EditBoxTop = "xanChat : La zone de saisie est maintenant en [|cFF99CC33HAUT|r]"
L.EditBoxInfo = "Afficher la zone de saisie en haut de la fenêtre de chat."

L.TabsOn = "xanChat : Les onglets de chat maintenant [|cFF99CC33ON|r]"
L.TabsOff = "xanChat : Les onglets de chat maintenant [|cFF99CC33OFF|r]"
L.TabsInfo = "Masquer les onglets de chat."

L.ShadowOn = "xanChat : Ombres de police du chat maintenant [|cFF99CC33ON|r]"
L.ShadowOff = "xanChat : Ombres de police du chat maintenant [|cFF99CC33OFF|r]"
L.ShadowInfo = "Ajouter des ombres à la police du texte du chat. |cFFDF2B2B(Écrase l'option de contour.)|r"

L.OutlineOn = "xanChat : Contour de police du chat maintenant [|cFF99CC33ON|r]"
L.OutlineOff = "xanChat : Contour de police du chat maintenant [|cFF99CC33OFF|r]"
L.OutlineInfo = "Ajouter un contour à la police du texte du chat."

L.EditBoxBorderOn = "xanChat : Bordure de la zone de saisie [|cFF99CC33ON|r]"
L.EditBoxBorderOff = "xanChat : Bordure de la zone de saisie [|cFF99CC33OFF|r]"
L.EditBoxBorderInfo = "Masquer la bordure de la zone de saisie."

L.SimpleEditBoxOn = "xanChat : Zone de saisie simple [|cFF99CC33ON|r]"
L.SimpleEditBoxOff = "xanChat : Zone de saisie simple [|cFF99CC33OFF|r]"
L.SimpleEditBoxInfo = "Afficher une zone de saisie simplifiée avec bordure d'info-bulle."

L.SEBDesignOn = "xanChat : Style alternatif de zone de saisie simple [|cFF99CC33ON|r]"
L.SEBDesignOff = "xanChat : Style alternatif de zone de saisie simple [|cFF99CC33OFF|r]"
L.SEBDesignInfo = "Activer un style alternatif pour la zone de saisie."

L.CopyPasteOn = "xanChat : Bouton copier/coller maintenant [|cFF99CC33ON|r]"
L.CopyPasteOff = "xanChat : Bouton copier/coller maintenant [|cFF99CC33OFF|r]"
L.CopyPasteInfo = "Afficher un bouton copier/coller dans la fenêtre de chat."

L.CopyPasteLeftOn = "xanChat : Bouton copier/coller à gauche [|cFF99CC33ON|r]"
L.CopyPasteLeftOff = "xanChat : Bouton copier/coller à gauche [|cFF99CC33OFF|r]"
L.CopyPasteLeftInfo = "Afficher le bouton copier/coller à gauche du cadre de chat."

L.PlayerChatStyleOn = "xanChat : Noms de joueur stylisés [Niveau+Couleur] [|cFF99CC33ON|r]"
L.PlayerChatStyleOff = "xanChat : Noms de joueur stylisés [Niveau+Couleur] [|cFF99CC33OFF|r]"
L.PlayerChatStyleInfo = "Afficher les noms de joueur stylisés et le niveau dans le chat. |cFF99CC33(Utilise la liste de filtres stylisés ci-dessus)|r"

L.ChatTextFadeOn = "xanChat : Fondu du texte de chat [|cFF99CC33ON|r]"
L.ChatTextFadeOff = "xanChat : Fondu du texte de chat [|cFF99CC33OFF|r]"
L.ChatTextFadeInfo = "Activer le fondu du texte dans les cadres de chat."

L.ChatFrameFadeOn = "xanChat : Désactiver le fondu du cadre de chat [|cFF99CC33ON|r]"
L.ChatFrameFadeOff = "xanChat : Désactiver le fondu du cadre de chat [|cFF99CC33OFF|r]"
L.ChatFrameFadeInfo = "Désactiver le fondu du fond dans les cadres de chat."

L.LockChatSettingsOn = "xanChat : Verrouillage des paramètres de chat [|cFF99CC33ON|r]"
L.LockChatSettingsOff = "xanChat : Verrouillage des paramètres de chat [|cFF99CC33OFF|r]"
L.LockChatSettingsInfo = "Verrouiller les paramètres et positions du chat pour éviter les modifications."
L.LockChatSettingsAlert = "Paramètres de chat [|cFFFF6347VERROUILLÉ|r]."

L.ChatAlphaSet = "xanChat : La transparence du chat a été réglée sur [|cFF20ff20%s|r]"
L.ChatAlphaSetInvalid = "xanChat : Alpha non valide ou nombre supérieur à 2"
L.ChatAlphaInfo = "Régler le niveau de transparence du cadre de chat. (0-100)"
L.ChatAlphaText = "Transparence du cadre de chat"

L.AdjustedEditboxOn = "xanChat : Espace de la zone de saisie ajusté [|cFF99CC33ON|r]"
L.AdjustedEditboxOff = "xanChat : Espace de la zone de saisie ajusté [|cFF99CC33OFF|r]"
L.AdjustedEditboxInfo = "Activer un espace supplémentaire entre le cadre de chat et la zone de saisie."

L.VoiceOn = "xanChat : Boutons canal/voix maintenant [|cFF99CC33ON|r]"
L.VoiceOff = "xanChat : Boutons canal/voix maintenant [|cFF99CC33OFF|r]"
L.VoiceInfo = "Masquer le bouton canal/voix."

L.ChatMenuButtonOn = "xanChat : Menu de chat maintenant [|cFF99CC33ON|r]"
L.ChatMenuButtonOff = "xanChat : Menu de chat maintenant [|cFF99CC33OFF|r]"
L.ChatMenuButtonInfo = "Masquer le bouton du menu de chat."

L.MoveSocialButtonOn = "xanChat : Déplacer les boutons sociaux et alertes en bas. [|cFF99CC33ON|r]"
L.MoveSocialButtonOff = "xanChat : Déplacer les boutons sociaux et alertes en bas. [|cFF99CC33OFF|r]"
L.MoveSocialButtonInfo = "Déplacer le bouton social et le cadre d'alerte en bas."

L.PageLimitText = "Pages de chat récentes à afficher dans Copie de chat. |cFF99CC33(0 sans limite)|r"
