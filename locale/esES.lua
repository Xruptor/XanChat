local ADDON_NAME, private = ...

local L = private:NewLocale("esES")
if not L then return end

L.WhoPlayer = "¿Quién es el jugador?"
L.GuildInvite = "Invitación de hermandad"
L.CopyName = "Copiar nombre"
L.URLCopy = "COPIAR URL"
L.ApplyChanges = "xanChat: ¡La IU --DEBE-- recargarse para aplicar los cambios!"
L.Yes = "Sí"
L.No = "No"
L.Page = "Página"
L.CopyChat = "Copiar chat"
L.Done = "Listo"
L.CopyChatError = "Hubo un error en la función de copiar chat."
L.AdditionalSettings = "Ajustes adicionales"
L.ChangeOutgoingWhisperColor = "Cambiar el color de los susurros salientes."
L.EnableOutWhisperColor = "Activar color personalizado para susurros salientes."
L.DisableChatEnterLeaveNotice = "Desactivar notificaciones de canal (|cFF99CC33Entrar/Salir/Cambiado|r)."

L.ProtectedChannel = " |cFFDF2B2B(El canal está protegido por Blizzard. El acceso del addon está prohibido.)|r."

--Channel Config (Only change the actual english word, leave the characters.  It's case sensitive!)
--trailing dash is to check for things like [WorldDefense - Alterac Mountains] so it will remove location
L.ChannelGeneral = "(%[%d+%. )General.-%]"
L.ChannelTrade = "(%[%d+%. )Comercio.-%]"
L.ChannelWorldDefense = "(%[%d+%. )DefensaGlobal.-%]"
L.ChannelLocalDefense = "(%[%d+%. )DefensaLocal.-%]"
L.ChannelLookingForGroup = "(%[%d+%. )BuscarGrupo.-%]"
L.ChannelGuildRecruitment = "(%[%d+%. )ReclutamientoDeHermandad.-%]"
L.ChannelNewComerChat = "(%[%d+%. )Chat de recién llegados.-%]"
L.ChannelTradeServices  = "(%[%d+%. )Comercio %([^()]*%).-%]"

L.ShortGeneral = "GE"
L.ShortTrade = "CO"
L.ShortWorldDefense = "DG"
L.ShortLocalDefense = "DL"
L.ShortLookingForGroup = "BG"
L.ShortGuildRecruitment = "RH"
L.ShortNewComerChat = "NL"
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

L.EditFilterListHeader = "Editar lista de filtros estilizados"
L.EditStickyChannelsListHeader = "Editar lista de canales fijos"

L.SocialOn = "xanChat: Botones sociales ahora [|cFF99CC33ON|r]"
L.SocialOff = "xanChat: Botones sociales ahora [|cFF99CC33OFF|r]"
L.SocialInfo = "Ocultar el botón social."

L.ScrollOn = "xanChat: Botones de desplazamiento ahora [|cFF99CC33ON|r]"
L.ScrollOff = "xanChat: Botones de desplazamiento ahora [|cFF99CC33OFF|r]"
L.ScrollInfo = "Ocultar las barras de desplazamiento del chat."

L.HideScrollBarsOn = "xanChat: Ocultar barras de botones izquierda y derecha ahora [|cFF99CC33ON|r]"
L.HideScrollBarsOff = "xanChat: Ocultar barras de botones izquierda y derecha ahora [|cFF99CC33OFF|r]"
L.HideScrollBarsInfo = "Oculta las barras de botones izquierda y derecha en las ventanas de chat. |cFFDF2B2B(¡Oculta todos los botones!)|r"

L.ShortNamesOn = "xanChat: Nombres cortos de canales ahora [|cFF99CC33ON|r]"
L.ShortNamesOff = "xanChat: Nombres cortos de canales ahora [|cFF99CC33OFF|r]"
L.ShortNamesInfo = "Usar nombres cortos de canales."

L.EditBoxBottom = "xanChat: La caja de edición ahora está en [|cFF99CC33ABAJO|r]"
L.EditBoxTop = "xanChat: La caja de edición ahora está en [|cFF99CC33ARRIBA|r]"
L.EditBoxInfo = "Mostrar la caja de edición en la parte superior de la ventana de chat."

L.TabsOn = "xanChat: Las pestañas de chat ahora [|cFF99CC33ON|r]"
L.TabsOff = "xanChat: Las pestañas de chat ahora [|cFF99CC33OFF|r]"
L.TabsInfo = "Ocultar las pestañas de chat."

L.ShadowOn = "xanChat: Sombras de fuente del chat ahora [|cFF99CC33ON|r]"
L.ShadowOff = "xanChat: Sombras de fuente del chat ahora [|cFF99CC33OFF|r]"
L.ShadowInfo = "Agregar sombras a la fuente del texto del chat. |cFFDF2B2B(Anula la opción de contorno.)|r"

L.OutlineOn = "xanChat: Contorno de fuente del chat ahora [|cFF99CC33ON|r]"
L.OutlineOff = "xanChat: Contorno de fuente del chat ahora [|cFF99CC33OFF|r]"
L.OutlineInfo = "Agregar contorno a la fuente del texto del chat."

L.EditBoxBorderOn = "xanChat: Borde de la caja de edición [|cFF99CC33ON|r]"
L.EditBoxBorderOff = "xanChat: Borde de la caja de edición [|cFF99CC33OFF|r]"
L.EditBoxBorderInfo = "Ocultar el borde de la caja de edición."

L.SimpleEditBoxOn = "xanChat: Caja de edición simple [|cFF99CC33ON|r]"
L.SimpleEditBoxOff = "xanChat: Caja de edición simple [|cFF99CC33OFF|r]"
L.SimpleEditBoxInfo = "Mostrar una caja de edición simplificada con borde de tooltip."

L.SEBDesignOn = "xanChat: Estilo alternativo de caja de edición simple [|cFF99CC33ON|r]"
L.SEBDesignOff = "xanChat: Estilo alternativo de caja de edición simple [|cFF99CC33OFF|r]"
L.SEBDesignInfo = "Habilitar estilo alternativo para la caja de edición."

L.CopyPasteOn = "xanChat: Botón de copiar y pegar ahora [|cFF99CC33ON|r]"
L.CopyPasteOff = "xanChat: Botón de copiar y pegar ahora [|cFF99CC33OFF|r]"
L.CopyPasteInfo = "Mostrar un botón de copiar y pegar en la ventana de chat."

L.CopyPasteLeftOn = "xanChat: Botón de copiar y pegar a la izquierda [|cFF99CC33ON|r]"
L.CopyPasteLeftOff = "xanChat: Botón de copiar y pegar a la izquierda [|cFF99CC33OFF|r]"
L.CopyPasteLeftInfo = "Mostrar el botón de copiar y pegar a la izquierda del marco de chat."

L.PlayerChatStyleOn = "xanChat: Nombres de jugador estilizados [Nivel+Color] [|cFF99CC33ON|r]"
L.PlayerChatStyleOff = "xanChat: Nombres de jugador estilizados [Nivel+Color] [|cFF99CC33OFF|r]"
L.PlayerChatStyleInfo = "Mostrar nombres de jugador estilizados y nivel en el chat. |cFF99CC33(Usa la lista de filtros estilizados arriba)|r"

L.ChatTextFadeOn = "xanChat: Desvanecido del texto de chat [|cFF99CC33ON|r]"
L.ChatTextFadeOff = "xanChat: Desvanecido del texto de chat [|cFF99CC33OFF|r]"
L.ChatTextFadeInfo = "Habilitar desvanecido del texto en marcos de chat."

L.ChatFrameFadeOn = "xanChat: Desactivar desvanecido del marco de chat [|cFF99CC33ON|r]"
L.ChatFrameFadeOff = "xanChat: Desactivar desvanecido del marco de chat [|cFF99CC33OFF|r]"
L.ChatFrameFadeInfo = "Desactivar el desvanecido del fondo en marcos de chat."

L.LockChatSettingsOn = "xanChat: Bloqueo de ajustes de chat [|cFF99CC33ON|r]"
L.LockChatSettingsOff = "xanChat: Bloqueo de ajustes de chat [|cFF99CC33OFF|r]"
L.LockChatSettingsInfo = "Bloquear los ajustes y posiciones del chat para evitar cambios."
L.LockChatSettingsAlert = "Ajustes de chat [|cFFFF6347BLOQUEADO|r]."

L.ChatAlphaSet = "xanChat: La transparencia del chat se ha establecido en [|cFF20ff20%s|r]"
L.ChatAlphaSetInvalid = "xanChat: Alpha no válido o el número no puede ser mayor que 2"
L.ChatAlphaInfo = "Establecer el nivel de transparencia del marco de chat. (0-100)"
L.ChatAlphaText = "Transparencia del marco de chat"

L.AdjustedEditboxOn = "xanChat: Espacio ajustado de la caja de edición [|cFF99CC33ON|r]"
L.AdjustedEditboxOff = "xanChat: Espacio ajustado de la caja de edición [|cFF99CC33OFF|r]"
L.AdjustedEditboxInfo = "Habilitar espacio adicional entre el marco de chat y la caja de edición."

L.VoiceOn = "xanChat: Botones de canal/voz ahora [|cFF99CC33ON|r]"
L.VoiceOff = "xanChat: Botones de canal/voz ahora [|cFF99CC33OFF|r]"
L.VoiceInfo = "Ocultar el botón de canal/voz."

L.ChatMenuButtonOn = "xanChat: Menú de chat ahora [|cFF99CC33ON|r]"
L.ChatMenuButtonOff = "xanChat: Menú de chat ahora [|cFF99CC33OFF|r]"
L.ChatMenuButtonInfo = "Ocultar el botón del menú de chat."

L.MoveSocialButtonOn = "xanChat: Mover social y alertas al fondo. [|cFF99CC33ON|r]"
L.MoveSocialButtonOff = "xanChat: Mover social y alertas al fondo. [|cFF99CC33OFF|r]"
L.MoveSocialButtonInfo = "Mover el botón social y el marco de alertas al fondo."

L.PageLimitText = "Páginas recientes de chat para mostrar en Copiar Chat. |cFF99CC33(0 sin límite)|r"
