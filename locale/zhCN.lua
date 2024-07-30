local ADDON_NAME, addon = ...

local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "zhCN")
if not L then return end

L.WhoPlayer = "是玩家？"
L.GuildInvite = "公会邀请"
L.CopyName = "复制名字"
L.URLCopy = "复制 URL"
L.ApplyChanges = "xanChat: 必需重新加载界面才能更改！"
L.Yes = "是"
L.No = "否"
L.Page = "页"
L.CopyChat = "复制聊天"
L.Done = "完成"
L.CopyChatError = "在复制聊天时出现错误。"
L.AdditionalSettings = "附加设置"
L.ChangeOutgoingWhisperColor = "改变发出密语颜色"
L.EnableOutWhisperColor = "启用自定义发出密语颜色"
L.DisableChatEnterLeaveNotice = "禁用聊天频道 (|cFF99CC33进入/离开/更改|r) 通知。"

L.ProtectedChannel = " |cFFDF2B2B（频道受暴雪保护，禁止插件修改）|r。"

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

L.EditFilterListHeader = "编辑过滤器列表"
L.EditStickyChannelsListHeader = "编辑频道列表"

L.SocialOn = "xanChat: 社交按钮现在是 [|cFF99CC33开|r]"
L.SocialOff = "xanChat: 社交按钮现在是 [|cFF99CC33关|r]"
L.SocialInfo = "隐藏社交按钮。"

L.ScrollOn = "xanChat: 滚动条现在是 [|cFF99CC33开|r]"
L.ScrollOff = "xanChat: 滚动条现在是 [|cFF99CC33关|r]"
L.ScrollInfo = "隐藏聊天滚动条。"

L.HideScrollBarsOn = "xanChat: 隐藏左侧和右侧栏按钮 [|cFF99CC33开|r]"
L.HideScrollBarsOff = "xanChat: 隐藏左侧和右侧栏按钮 [|cFF99CC33关|r]"
L.HideScrollBarsInfo = "隐藏聊天栏的左侧和右侧按钮。|cFFDF2B2B（隐藏所有按钮！）|r"

L.ShortNamesOn = "xanChat: 简写频道名 [|cFF99CC33开|r]"
L.ShortNamesOff = "xanChat: 简写频道名 [|cFF99CC33关|r]"
L.ShortNamesInfo = "使用简写频道名"

L.EditBoxBottom = "xanChat: 输入框位于 [|cFF99CC33底部|r]"
L.EditBoxTop = "xanChat: 输入框位于 [|cFF99CC33顶部|r]"
L.EditBoxInfo = "在顶部显示聊天输入框。"

L.TabsOn = "xanChat: 聊天选项 [|cFF99CC33开|r]"
L.TabsOff = "xanChat: 聊天选项 [|cFF99CC33关|r]"
L.TabsInfo = "隐藏聊天选项。"

L.ShadowOn = "xanChat: 字体阴影 [|cFF99CC33开|r]"
L.ShadowOff = "xanChat: 字体阴影 [|cFF99CC33关|r]"
L.ShadowInfo = "给聊天字体添加阴影。 |cFFDF2B2B（包含轮廓选项。）|r"

L.OutlineOn = "xanChat: 字体轮廓 [|cFF99CC33开|r]"
L.OutlineOff = "xanChat: 字体轮廓 [|cFF99CC33关|r]"
L.OutlineInfo = "为聊天字体添加轮廓。"

L.EditBoxBorderOn = "xanChat: 输入框边框 [|cFF99CC33开|r]"
L.EditBoxBorderOff = "xanChat: 输入框边框 [|cFF99CC33关|r]"
L.EditBoxBorderInfo = "隐藏输入框边框。"

L.SimpleEditBoxOn = "xanChat: 简化输入框 [|cFF99CC33开|r]"
L.SimpleEditBoxOff = "xanChat: 简化输入框 [|cFF99CC33关|r]"
L.SimpleEditBoxInfo = "显示提示边框的简化输入框。"

L.SEBDesignOn = "xanChat: 简化输入框交替框样式 [|cFF99CC33开|r]"
L.SEBDesignOff = "xanChat: 简化输入框交替框样式 [|cFF99CC33关|r]"
L.SEBDesignInfo = "启用简化输入框交替框样式"

L.CopyPasteOn = "xanChat:  复制和粘贴按钮 [|cFF99CC33开|r]"
L.CopyPasteOff = "xanChat: 复制和粘贴按钮 [|cFF99CC33关|r]"
L.CopyPasteInfo = "在聊天窗口中显示复制和粘贴按钮。"

L.CopyPasteLeftOn = "xanChat: 复制和粘贴按钮在左的位置 [|cFF99CC33开|r]"
L.CopyPasteLeftOff = "xanChat: 复制和粘贴按钮在左的位置 [|cFF99CC33关|r]"
L.CopyPasteLeftInfo = "在聊天框左侧显示复制和粘贴按钮。"

L.PlayerChatStyleOn = "xanChat: 玩家名字风格 [等级+颜色] [|cFF99CC33开|r]"
L.PlayerChatStyleOff = "xanChat: 玩家名字风格 [等级+颜色] [|cFF99CC33关|r]"
L.PlayerChatStyleInfo = "在聊天中风格显示玩家名称和等级 |cFF99CC33（需要编辑过滤器）|r"

L.ChatTextFadeOn = "xanChat: 聊天字体渐变 [|cFF99CC33开|r]"
L.ChatTextFadeOff = "xanChat: 聊天字体渐变 [|cFF99CC33关|r]"
L.ChatTextFadeInfo = "启用聊天字体渐变。"

L.ChatFrameFadeOn = "xanChat: 禁用聊天框渐变 [|cFF99CC33开|r]"
L.ChatFrameFadeOff = "xanChat: 禁用聊天框渐变 [|cFF99CC33关|r]"
L.ChatFrameFadeInfo = "禁用聊天框渐变。"

L.LockChatSettingsOn = "xanChat: 聊天设置锁定 [|cFF99CC33开|r]"
L.LockChatSettingsOff = "xanChat: 聊天设置锁定 [|cFF99CC33关|r]"
L.LockChatSettingsInfo = "锁定聊天设置和位置，禁止修改。"
L.LockChatSettingsAlert = "聊天设置 [|cFFFF6347锁定|r]."

L.ChatAlphaSet = "xanChat: 聊天透明度设置为 [|cFF20ff20%s|r]"
L.ChatAlphaSetInvalid = "xanChat: 透明度设置无效，数值不允许大于 2"
L.ChatAlphaInfo = "设置聊天透明度等级 (0-100)"
L.ChatAlphaText = "聊天透明度"

L.AdjustedEditboxOn = "xanChat: 间距调整 [|cFF99CC33开|r]"
L.AdjustedEditboxOff = "xanChat: 间距调整 [|cFF99CC33关|r]"
L.AdjustedEditboxInfo = "启用聊天框和输入框的间距。"

L.VoiceOn = "xanChat: 聊天频道/语音按钮现在是 [|cFF99CC33开|r]"
L.VoiceOff = "xanChat: 聊天频道/语音按钮现在是 [|cFF99CC33关|r]"
L.VoiceInfo = "隐藏聊天频道/语音按钮。"

L.ChatMenuButtonOn = "xanChat: 聊天菜单 [|cFF99CC33开|r]"
L.ChatMenuButtonOff = "xanChat: 聊天菜单 [|cFF99CC33关|r]"
L.ChatMenuButtonInfo = "隐藏聊天菜单。"

L.MoveSocialButtonOn = "xanChat: 社交和提示框移动到底部。 [|cFF99CC33开|r]"
L.MoveSocialButtonOff = "xanChat: 社交和提示框移动到底部。 [|cFF99CC33关|r]"
L.MoveSocialButtonInfo = "将社交和提示框移动到底部。"

L.PageLimitText = "复制聊天中显示的最近聊天页面。 |cFF99CC33（0 是无限制）|r"
