local ADDON_NAME, private = ...

local L = private:NewLocale("zhTW")
if not L then return end

L.WhoPlayer = "誰是玩家？"
L.GuildInvite = "公會邀請"
L.CopyName = "複製名字"
L.URLCopy = "複製 URL"
L.ApplyChanges = "xanChat: 必須重新載入介面才能套用變更！"
L.Yes = "是"
L.No = "否"
L.Page = "頁"
L.CopyChat = "複製聊天"
L.Done = "完成"
L.CopyChatError = "複製聊天功能發生錯誤。"
L.AdditionalSettings = "其他設定"
L.ChangeOutgoingWhisperColor = "更改發出密語顏色。"
L.EnableOutWhisperColor = "啟用自訂發出密語顏色。"
L.DisableChatEnterLeaveNotice = "停用頻道(|cFF99CC33進入/離開/變更|r)通知。"

L.ProtectedChannel = " |cFFDF2B2B(頻道受暴雪保護，外掛存取被禁止。)|r."

--Channel Config (Only change the actual english word, leave the characters.  It's case sensitive!)
--trailing dash is to check for things like [WorldDefense - Alterac Mountains] so it will remove location
L.ChannelGeneral = "(%[%d+%. )綜合.-%]"
L.ChannelTrade = "(%[%d+%. )交易.-%]"
L.ChannelWorldDefense = "(%[%d+%. )世界防務.-%]"
L.ChannelLocalDefense = "(%[%d+%. )本地防務.-%]"
L.ChannelLookingForGroup = "(%[%d+%. )尋求組隊.-%]"
L.ChannelGuildRecruitment = "(%[%d+%. )公會招募.-%]"
L.ChannelNewComerChat = "(%[%d+%. )新手聊天.-%]"
L.ChannelTradeServices  = "(%[%d+%. )交易 %([^()]*%).-%]"

L.ShortGeneral = "綜"
L.ShortTrade = "交"
L.ShortWorldDefense = "世防"
L.ShortLocalDefense = "本防"
L.ShortLookingForGroup = "組隊"
L.ShortGuildRecruitment = "招募"
L.ShortNewComerChat = "新"
L.ShortTradeServices = "交服"

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

L.EditFilterListHeader = "編輯樣式化過濾清單"
L.EditStickyChannelsListHeader = "編輯黏著頻道清單"

L.SocialOn = "xanChat: 社交按鈕現在 [|cFF99CC33ON|r]"
L.SocialOff = "xanChat: 社交按鈕現在 [|cFF99CC33OFF|r]"
L.SocialInfo = "隱藏社交按鈕。"

L.ScrollOn = "xanChat: 捲動按鈕現在 [|cFF99CC33ON|r]"
L.ScrollOff = "xanChat: 捲動按鈕現在 [|cFF99CC33OFF|r]"
L.ScrollInfo = "隱藏聊天捲動條。"

L.HideScrollBarsOn = "xanChat: 隱藏左右按鈕欄現在 [|cFF99CC33ON|r]"
L.HideScrollBarsOff = "xanChat: 隱藏左右按鈕欄現在 [|cFF99CC33OFF|r]"
L.HideScrollBarsInfo = "隱藏聊天視窗的左右按鈕欄。 |cFFDF2B2B(會隱藏所有按鈕！)|r"

L.ShortNamesOn = "xanChat: 短頻道名稱現在 [|cFF99CC33ON|r]"
L.ShortNamesOff = "xanChat: 短頻道名稱現在 [|cFF99CC33OFF|r]"
L.ShortNamesInfo = "使用短頻道名稱。"

L.EditBoxBottom = "xanChat: 輸入框現在在 [|cFF99CC33下方|r]"
L.EditBoxTop = "xanChat: 輸入框現在在 [|cFF99CC33上方|r]"
L.EditBoxInfo = "在聊天視窗上方顯示輸入框。"

L.TabsOn = "xanChat: 聊天分頁現在 [|cFF99CC33ON|r]"
L.TabsOff = "xanChat: 聊天分頁現在 [|cFF99CC33OFF|r]"
L.TabsInfo = "隱藏聊天分頁。"

L.ShadowOn = "xanChat: 聊天字體陰影現在 [|cFF99CC33ON|r]"
L.ShadowOff = "xanChat: 聊天字體陰影現在 [|cFF99CC33OFF|r]"
L.ShadowInfo = "為聊天文字字體加入陰影。 |cFFDF2B2B(會覆蓋外框選項。)|r"

L.OutlineOn = "xanChat: 聊天字體外框現在 [|cFF99CC33ON|r]"
L.OutlineOff = "xanChat: 聊天字體外框現在 [|cFF99CC33OFF|r]"
L.OutlineInfo = "為聊天文字字體加入外框。"

L.EditBoxBorderOn = "xanChat: 輸入框邊框 [|cFF99CC33ON|r]"
L.EditBoxBorderOff = "xanChat: 輸入框邊框 [|cFF99CC33OFF|r]"
L.EditBoxBorderInfo = "隱藏輸入框邊框。"

L.SimpleEditBoxOn = "xanChat: 簡化輸入框 [|cFF99CC33ON|r]"
L.SimpleEditBoxOff = "xanChat: 簡化輸入框 [|cFF99CC33OFF|r]"
L.SimpleEditBoxInfo = "顯示帶提示框邊框的簡化輸入框。"

L.SEBDesignOn = "xanChat: 簡化輸入框替代樣式 [|cFF99CC33ON|r]"
L.SEBDesignOff = "xanChat: 簡化輸入框替代樣式 [|cFF99CC33OFF|r]"
L.SEBDesignInfo = "啟用輸入框替代樣式。"

L.CopyPasteOn = "xanChat: 複製與貼上按鈕 [|cFF99CC33ON|r]"
L.CopyPasteOff = "xanChat: 複製與貼上按鈕 [|cFF99CC33OFF|r]"
L.CopyPasteInfo = "在聊天視窗顯示複製與貼上按鈕。"

L.CopyPasteLeftOn = "xanChat: 複製與貼上按鈕位於左側 [|cFF99CC33ON|r]"
L.CopyPasteLeftOff = "xanChat: 複製與貼上按鈕位於左側 [|cFF99CC33OFF|r]"
L.CopyPasteLeftInfo = "在聊天框左側顯示複製與貼上按鈕。"

L.PlayerChatStyleOn = "xanChat: 樣式化玩家名稱 [等級+顏色] [|cFF99CC33ON|r]"
L.PlayerChatStyleOff = "xanChat: 樣式化玩家名稱 [等級+顏色] [|cFF99CC33OFF|r]"
L.PlayerChatStyleInfo = "在聊天中顯示樣式化玩家名稱與等級。 |cFF99CC33(使用上方的樣式化過濾清單)|r"

L.ChatTextFadeOn = "xanChat: 聊天文字淡出 [|cFF99CC33ON|r]"
L.ChatTextFadeOff = "xanChat: 聊天文字淡出 [|cFF99CC33OFF|r]"
L.ChatTextFadeInfo = "啟用聊天框文字淡出。"

L.ChatFrameFadeOn = "xanChat: 停用聊天框淡出 [|cFF99CC33ON|r]"
L.ChatFrameFadeOff = "xanChat: 停用聊天框淡出 [|cFF99CC33OFF|r]"
L.ChatFrameFadeInfo = "停用聊天框背景淡出。"

L.LockChatSettingsOn = "xanChat: 鎖定聊天設定 [|cFF99CC33ON|r]"
L.LockChatSettingsOff = "xanChat: 鎖定聊天設定 [|cFF99CC33OFF|r]"
L.LockChatSettingsInfo = "鎖定聊天設定與位置以避免變更。"
L.LockChatSettingsAlert = "聊天設定 [|cFFFF6347已鎖定|r]."

L.ChatAlphaSet = "xanChat: 聊天透明度已設定為 [|cFF20ff20%s|r]"
L.ChatAlphaSetInvalid = "xanChat: 透明度無效或數值不能大於 2"
L.ChatAlphaInfo = "設定聊天框透明度。 (0-100)"
L.ChatAlphaText = "聊天框透明度"

L.AdjustedEditboxOn = "xanChat: 輸入框間距調整 [|cFF99CC33ON|r]"
L.AdjustedEditboxOff = "xanChat: 輸入框間距調整 [|cFF99CC33OFF|r]"
L.AdjustedEditboxInfo = "啟用聊天框與輸入框之間的額外間距。"

L.VoiceOn = "xanChat: 頻道/語音按鈕 [|cFF99CC33ON|r]"
L.VoiceOff = "xanChat: 頻道/語音按鈕 [|cFF99CC33OFF|r]"
L.VoiceInfo = "隱藏頻道/語音按鈕。"

L.ChatMenuButtonOn = "xanChat: 聊天選單 [|cFF99CC33ON|r]"
L.ChatMenuButtonOff = "xanChat: 聊天選單 [|cFF99CC33OFF|r]"
L.ChatMenuButtonInfo = "隱藏聊天選單按鈕。"

L.MoveSocialButtonOn = "xanChat: 將社交與提示框移到底部。 [|cFF99CC33ON|r]"
L.MoveSocialButtonOff = "xanChat: 將社交與提示框移到底部。 [|cFF99CC33OFF|r]"
L.MoveSocialButtonInfo = "將社交按鈕與提示框移到底部。"

L.PageLimitText = "在複製聊天中顯示的最近聊天頁數。 |cFF99CC33(0 為不限制)|r"
