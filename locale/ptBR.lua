local ADDON_NAME, private = ...

local L = private:NewLocale("ptBR")
if not L then return end

L.WhoPlayer = "Quem é o jogador?"
L.GuildInvite = "Convite de guilda"
L.CopyName = "Copiar nome"
L.URLCopy = "COPIAR URL"
L.ApplyChanges = "xanChat: A IU --DEVE-- ser recarregada para aplicar as mudanças!"
L.Yes = "Sim"
L.No = "Não"
L.Page = "Página"
L.CopyChat = "Copiar chat"
L.Done = "Concluído"
L.CopyChatError = "Houve um erro na função de copiar chat."
L.AdditionalSettings = "Configurações adicionais"
L.ChangeOutgoingWhisperColor = "Alterar a cor do sussurro enviado."
L.EnableOutWhisperColor = "Ativar cor personalizada para sussurros enviados."
L.DisableChatEnterLeaveNotice = "Desativar notificações do canal (|cFF99CC33Entrar/Sair/Alterado|r)."

L.ProtectedChannel = " |cFFDF2B2B(O canal é protegido pela Blizzard. Acesso do addon é proibido.)|r."

--Channel Config (Only change the actual english word, leave the characters.  It's case sensitive!)
--trailing dash is to check for things like [WorldDefense - Alterac Mountains] so it will remove location
L.ChannelGeneral = "(%[%d+%. )Geral.-%]"
L.ChannelTrade = "(%[%d+%. )Comércio.-%]"
L.ChannelWorldDefense = "(%[%d+%. )DefesaMundial.-%]"
L.ChannelLocalDefense = "(%[%d+%. )DefesaLocal.-%]"
L.ChannelLookingForGroup = "(%[%d+%. )ProcurandoGrupo.-%]"
L.ChannelGuildRecruitment = "(%[%d+%. )RecrutamentoDeGuilda.-%]"
L.ChannelNewComerChat = "(%[%d+%. )Chat de novatos.-%]"
L.ChannelTradeServices  = "(%[%d+%. )Comércio %([^()]*%).-%]"

L.ShortGeneral = "GE"
L.ShortTrade = "CO"
L.ShortWorldDefense = "DM"
L.ShortLocalDefense = "DL"
L.ShortLookingForGroup = "PG"
L.ShortGuildRecruitment = "RG"
L.ShortNewComerChat = "CN"
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
L.EditStickyChannelsListHeader = "Editar lista de canais fixos"

L.SocialOn = "xanChat: Botões sociais agora [|cFF99CC33ON|r]"
L.SocialOff = "xanChat: Botões sociais agora [|cFF99CC33OFF|r]"
L.SocialInfo = "Ocultar o botão social."

L.ScrollOn = "xanChat: Botões de rolagem agora [|cFF99CC33ON|r]"
L.ScrollOff = "xanChat: Botões de rolagem agora [|cFF99CC33OFF|r]"
L.ScrollInfo = "Ocultar as barras de rolagem do chat."

L.HideScrollBarsOn = "xanChat: Ocultar barras de botões esquerda e direita agora [|cFF99CC33ON|r]"
L.HideScrollBarsOff = "xanChat: Ocultar barras de botões esquerda e direita agora [|cFF99CC33OFF|r]"
L.HideScrollBarsInfo = "Oculta as barras de botões esquerda e direita nas janelas de chat. |cFFDF2B2B(Oculta todos os botões!)|r"

L.ShortNamesOn = "xanChat: Nomes curtos de canais agora [|cFF99CC33ON|r]"
L.ShortNamesOff = "xanChat: Nomes curtos de canais agora [|cFF99CC33OFF|r]"
L.ShortNamesInfo = "Usar nomes curtos de canais."

L.EditBoxBottom = "xanChat: A caixa de edição agora está em [|cFF99CC33BAIXO|r]"
L.EditBoxTop = "xanChat: A caixa de edição agora está em [|cFF99CC33CIMA|r]"
L.EditBoxInfo = "Mostrar a caixa de edição no topo da janela de chat."

L.TabsOn = "xanChat: As abas de chat agora [|cFF99CC33ON|r]"
L.TabsOff = "xanChat: As abas de chat agora [|cFF99CC33OFF|r]"
L.TabsInfo = "Ocultar as abas de chat."

L.ShadowOn = "xanChat: Sombras da fonte do chat agora [|cFF99CC33ON|r]"
L.ShadowOff = "xanChat: Sombras da fonte do chat agora [|cFF99CC33OFF|r]"
L.ShadowInfo = "Adicionar sombras à fonte do texto do chat. |cFFDF2B2B(Substitui a opção de contorno.)|r"

L.OutlineOn = "xanChat: Contorno da fonte do chat agora [|cFF99CC33ON|r]"
L.OutlineOff = "xanChat: Contorno da fonte do chat agora [|cFF99CC33OFF|r]"
L.OutlineInfo = "Adicionar contorno à fonte do texto do chat."

L.EditBoxBorderOn = "xanChat: Borda da caixa de edição [|cFF99CC33ON|r]"
L.EditBoxBorderOff = "xanChat: Borda da caixa de edição [|cFF99CC33OFF|r]"
L.EditBoxBorderInfo = "Ocultar a borda da caixa de edição."

L.SimpleEditBoxOn = "xanChat: Caixa de edição simples [|cFF99CC33ON|r]"
L.SimpleEditBoxOff = "xanChat: Caixa de edição simples [|cFF99CC33OFF|r]"
L.SimpleEditBoxInfo = "Mostrar uma caixa de edição simplificada com borda de tooltip."

L.SEBDesignOn = "xanChat: Estilo alternativo da caixa de edição simples [|cFF99CC33ON|r]"
L.SEBDesignOff = "xanChat: Estilo alternativo da caixa de edição simples [|cFF99CC33OFF|r]"
L.SEBDesignInfo = "Ativar estilo alternativo para a caixa de edição."

L.CopyPasteOn = "xanChat: Botão copiar e colar agora [|cFF99CC33ON|r]"
L.CopyPasteOff = "xanChat: Botão copiar e colar agora [|cFF99CC33OFF|r]"
L.CopyPasteInfo = "Mostrar um botão de copiar e colar na janela de chat."

L.CopyPasteLeftOn = "xanChat: Botão copiar e colar à esquerda [|cFF99CC33ON|r]"
L.CopyPasteLeftOff = "xanChat: Botão copiar e colar à esquerda [|cFF99CC33OFF|r]"
L.CopyPasteLeftInfo = "Mostrar o botão de copiar e colar à esquerda do quadro de chat."

L.PlayerChatStyleOn = "xanChat: Nomes de jogador estilizados [Nível+Cor] [|cFF99CC33ON|r]"
L.PlayerChatStyleOff = "xanChat: Nomes de jogador estilizados [Nível+Cor] [|cFF99CC33OFF|r]"
L.PlayerChatStyleInfo = "Mostrar nomes de jogador estilizados e nível no chat. |cFF99CC33(Usa a lista de filtros estilizados acima)|r"

L.ChatTextFadeOn = "xanChat: Desvanecimento do texto do chat [|cFF99CC33ON|r]"
L.ChatTextFadeOff = "xanChat: Desvanecimento do texto do chat [|cFF99CC33OFF|r]"
L.ChatTextFadeInfo = "Ativar desvanecimento do texto nos quadros de chat."

L.ChatFrameFadeOn = "xanChat: Desativar desvanecimento do quadro de chat [|cFF99CC33ON|r]"
L.ChatFrameFadeOff = "xanChat: Desativar desvanecimento do quadro de chat [|cFF99CC33OFF|r]"
L.ChatFrameFadeInfo = "Desativar o desvanecimento do fundo nos quadros de chat."

L.LockChatSettingsOn = "xanChat: Bloqueio das configurações de chat [|cFF99CC33ON|r]"
L.LockChatSettingsOff = "xanChat: Bloqueio das configurações de chat [|cFF99CC33OFF|r]"
L.LockChatSettingsInfo = "Bloquear as configurações e posições do chat para evitar mudanças."
L.LockChatSettingsAlert = "Configurações de chat [|cFFFF6347BLOQUEADAS|r]."

L.ChatAlphaSet = "xanChat: A transparência do chat foi definida para [|cFF20ff20%s|r]"
L.ChatAlphaSetInvalid = "xanChat: Alpha inválido ou o número não pode ser maior que 2"
L.ChatAlphaInfo = "Definir o nível de transparência do quadro de chat. (0-100)"
L.ChatAlphaText = "Transparência do quadro de chat"

L.AdjustedEditboxOn = "xanChat: Espaço da caixa de edição ajustado [|cFF99CC33ON|r]"
L.AdjustedEditboxOff = "xanChat: Espaço da caixa de edição ajustado [|cFF99CC33OFF|r]"
L.AdjustedEditboxInfo = "Ativar espaço adicional entre o quadro de chat e a caixa de edição."

L.VoiceOn = "xanChat: Botões de canal/voz agora [|cFF99CC33ON|r]"
L.VoiceOff = "xanChat: Botões de canal/voz agora [|cFF99CC33OFF|r]"
L.VoiceInfo = "Ocultar o botão de canal/voz."

L.ChatMenuButtonOn = "xanChat: Menu do chat agora [|cFF99CC33ON|r]"
L.ChatMenuButtonOff = "xanChat: Menu do chat agora [|cFF99CC33OFF|r]"
L.ChatMenuButtonInfo = "Ocultar o botão do menu do chat."

L.MoveSocialButtonOn = "xanChat: Mover social e alertas para baixo. [|cFF99CC33ON|r]"
L.MoveSocialButtonOff = "xanChat: Mover social e alertas para baixo. [|cFF99CC33OFF|r]"
L.MoveSocialButtonInfo = "Mover o botão social e o quadro de alertas para baixo."

L.PageLimitText = "Páginas recentes de chat para exibir em Copiar chat. |cFF99CC33(0 sem limite)|r"
