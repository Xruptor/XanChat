local ADDON_NAME, private = ...

local L = private:NewLocale("koKR")
if not L then return end

L.WhoPlayer = "누구 플레이어?"
L.GuildInvite = "길드 초대"
L.CopyName = "이름 복사"
L.URLCopy = "URL 복사"
L.ApplyChanges = "xanChat: 변경 사항을 적용하려면 UI를 --반드시-- 리로드해야 합니다!"
L.Yes = "예"
L.No = "아니오"
L.Page = "페이지"
L.CopyChat = "채팅 복사"
L.Done = "완료"
L.CopyChatError = "채팅 복사 기능에 오류가 발생했습니다."
L.AdditionalSettings = "추가 설정"
L.ChangeOutgoingWhisperColor = "보내는 귓속말 색상 변경."
L.EnableOutWhisperColor = "사용자 지정 보내는 귓속말 색상 사용."
L.DisableChatEnterLeaveNotice = "채널 (|cFF99CC33입장/퇴장/변경|r) 알림 끄기."

L.ProtectedChannel = " |cFFDF2B2B(채널은 Blizzard에 의해 보호됩니다. 애드온 접근이 금지됩니다.)|r."

--Channel Config (Only change the actual english word, leave the characters.  It's case sensitive!)
--trailing dash is to check for things like [WorldDefense - Alterac Mountains] so it will remove location
L.ChannelGeneral = "(%[%d+%. )일반.-%]"
L.ChannelTrade = "(%[%d+%. )거래.-%]"
L.ChannelWorldDefense = "(%[%d+%. )세계방어.-%]"
L.ChannelLocalDefense = "(%[%d+%. )지역방어.-%]"
L.ChannelLookingForGroup = "(%[%d+%. )파티찾기.-%]"
L.ChannelGuildRecruitment = "(%[%d+%. )길드모집.-%]"
L.ChannelNewComerChat = "(%[%d+%. )새내기 대화.-%]"
L.ChannelTradeServices  = "(%[%d+%. )거래 %([^()]*%).-%]"

L.ShortGeneral = "일"
L.ShortTrade = "거"
L.ShortWorldDefense = "세방"
L.ShortLocalDefense = "지방"
L.ShortLookingForGroup = "파찾"
L.ShortGuildRecruitment = "길모"
L.ShortNewComerChat = "새"
L.ShortTradeServices = "거서"

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

L.EditFilterListHeader = "스타일 필터 목록 편집"
L.EditStickyChannelsListHeader = "고정 채널 목록 편집"

L.SocialOn = "xanChat: 소셜 버튼 [|cFF99CC33ON|r]"
L.SocialOff = "xanChat: 소셜 버튼 [|cFF99CC33OFF|r]"
L.SocialInfo = "소셜 버튼 숨기기."

L.ScrollOn = "xanChat: 스크롤 버튼 [|cFF99CC33ON|r]"
L.ScrollOff = "xanChat: 스크롤 버튼 [|cFF99CC33OFF|r]"
L.ScrollInfo = "채팅 스크롤 바 숨기기."

L.HideScrollBarsOn = "xanChat: 좌우 버튼 바 숨김 [|cFF99CC33ON|r]"
L.HideScrollBarsOff = "xanChat: 좌우 버튼 바 숨김 [|cFF99CC33OFF|r]"
L.HideScrollBarsInfo = "채팅 창의 좌우 버튼 바를 숨깁니다. |cFFDF2B2B(모든 버튼을 숨깁니다!)|r"

L.ShortNamesOn = "xanChat: 짧은 채널 이름 [|cFF99CC33ON|r]"
L.ShortNamesOff = "xanChat: 짧은 채널 이름 [|cFF99CC33OFF|r]"
L.ShortNamesInfo = "짧은 채널 이름 사용."

L.EditBoxBottom = "xanChat: 입력창 위치 [|cFF99CC33아래|r]"
L.EditBoxTop = "xanChat: 입력창 위치 [|cFF99CC33위|r]"
L.EditBoxInfo = "채팅 창 위에 입력창 표시."

L.TabsOn = "xanChat: 채팅 탭 [|cFF99CC33ON|r]"
L.TabsOff = "xanChat: 채팅 탭 [|cFF99CC33OFF|r]"
L.TabsInfo = "채팅 탭 숨기기."

L.ShadowOn = "xanChat: 채팅 글꼴 그림자 [|cFF99CC33ON|r]"
L.ShadowOff = "xanChat: 채팅 글꼴 그림자 [|cFF99CC33OFF|r]"
L.ShadowInfo = "채팅 글꼴에 그림자를 추가합니다. |cFFDF2B2B(윤곽선 옵션을 덮어씁니다.)|r"

L.OutlineOn = "xanChat: 채팅 글꼴 윤곽선 [|cFF99CC33ON|r]"
L.OutlineOff = "xanChat: 채팅 글꼴 윤곽선 [|cFF99CC33OFF|r]"
L.OutlineInfo = "채팅 글꼴에 윤곽선을 추가합니다."

L.EditBoxBorderOn = "xanChat: 입력창 테두리 [|cFF99CC33ON|r]"
L.EditBoxBorderOff = "xanChat: 입력창 테두리 [|cFF99CC33OFF|r]"
L.EditBoxBorderInfo = "입력창 테두리 숨기기."

L.SimpleEditBoxOn = "xanChat: 단순 입력창 [|cFF99CC33ON|r]"
L.SimpleEditBoxOff = "xanChat: 단순 입력창 [|cFF99CC33OFF|r]"
L.SimpleEditBoxInfo = "툴팁 테두리가 있는 단순 입력창을 표시합니다."

L.SEBDesignOn = "xanChat: 단순 입력창 대체 스타일 [|cFF99CC33ON|r]"
L.SEBDesignOff = "xanChat: 단순 입력창 대체 스타일 [|cFF99CC33OFF|r]"
L.SEBDesignInfo = "입력창에 대체 스타일 사용."

L.CopyPasteOn = "xanChat: 복사/붙여넣기 버튼 [|cFF99CC33ON|r]"
L.CopyPasteOff = "xanChat: 복사/붙여넣기 버튼 [|cFF99CC33OFF|r]"
L.CopyPasteInfo = "채팅 창에 복사/붙여넣기 버튼 표시."

L.CopyPasteLeftOn = "xanChat: 복사/붙여넣기 버튼 왼쪽 [|cFF99CC33ON|r]"
L.CopyPasteLeftOff = "xanChat: 복사/붙여넣기 버튼 왼쪽 [|cFF99CC33OFF|r]"
L.CopyPasteLeftInfo = "채팅 프레임 왼쪽에 복사/붙여넣기 버튼 표시."

L.PlayerChatStyleOn = "xanChat: 스타일 플레이어 이름 [레벨+색상] [|cFF99CC33ON|r]"
L.PlayerChatStyleOff = "xanChat: 스타일 플레이어 이름 [레벨+색상] [|cFF99CC33OFF|r]"
L.PlayerChatStyleInfo = "채팅에 스타일 플레이어 이름과 레벨 표시. |cFF99CC33(위의 스타일 필터 목록 사용)|r"

L.ChatTextFadeOn = "xanChat: 채팅 텍스트 페이드 [|cFF99CC33ON|r]"
L.ChatTextFadeOff = "xanChat: 채팅 텍스트 페이드 [|cFF99CC33OFF|r]"
L.ChatTextFadeInfo = "채팅 프레임에서 텍스트 페이드를 활성화합니다."

L.ChatFrameFadeOn = "xanChat: 채팅 프레임 페이드 비활성화 [|cFF99CC33ON|r]"
L.ChatFrameFadeOff = "xanChat: 채팅 프레임 페이드 비활성화 [|cFF99CC33OFF|r]"
L.ChatFrameFadeInfo = "채팅 프레임 배경 페이드를 비활성화합니다."

L.LockChatSettingsOn = "xanChat: 채팅 설정 잠금 [|cFF99CC33ON|r]"
L.LockChatSettingsOff = "xanChat: 채팅 설정 잠금 [|cFF99CC33OFF|r]"
L.LockChatSettingsInfo = "채팅 설정과 위치 변경을 잠급니다."
L.LockChatSettingsAlert = "채팅 설정 [|cFFFF6347잠김|r]."

L.ChatAlphaSet = "xanChat: 채팅 투명도가 [|cFF20ff20%s|r]로 설정되었습니다"
L.ChatAlphaSetInvalid = "xanChat: 알파 값이 잘못되었거나 숫자는 2를 초과할 수 없습니다"
L.ChatAlphaInfo = "채팅 프레임 투명도 설정. (0-100)"
L.ChatAlphaText = "채팅 프레임 투명도"

L.AdjustedEditboxOn = "xanChat: 입력창 간격 조정 [|cFF99CC33ON|r]"
L.AdjustedEditboxOff = "xanChat: 입력창 간격 조정 [|cFF99CC33OFF|r]"
L.AdjustedEditboxInfo = "채팅 프레임과 입력창 사이에 추가 간격을 활성화합니다."

L.VoiceOn = "xanChat: 채널/음성 버튼 [|cFF99CC33ON|r]"
L.VoiceOff = "xanChat: 채널/음성 버튼 [|cFF99CC33OFF|r]"
L.VoiceInfo = "채널/음성 버튼 숨기기."

L.ChatMenuButtonOn = "xanChat: 채팅 메뉴 [|cFF99CC33ON|r]"
L.ChatMenuButtonOff = "xanChat: 채팅 메뉴 [|cFF99CC33OFF|r]"
L.ChatMenuButtonInfo = "채팅 메뉴 버튼 숨기기."

L.MoveSocialButtonOn = "xanChat: 소셜/알림 프레임 아래로 이동. [|cFF99CC33ON|r]"
L.MoveSocialButtonOff = "xanChat: 소셜/알림 프레임 아래로 이동. [|cFF99CC33OFF|r]"
L.MoveSocialButtonInfo = "소셜 버튼과 알림 프레임을 아래로 이동합니다."

L.PageLimitText = "복사 채팅에 표시할 최근 채팅 페이지 수. |cFF99CC33(0은 제한 없음)|r"
