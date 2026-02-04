local ADDON_NAME, private = ...

local L = private:NewLocale("ruRU")
if not L then return end
-- Translator ZamestoTV
L.WhoPlayer = "Кто игрок?"
L.GuildInvite = "Приглашение в гильдию"
L.CopyName = "Копировать имя"
L.URLCopy = "КОПИРОВАТЬ URL"
L.ApplyChanges = "xanChat: Интерфейс --ДОЛЖЕН-- быть перезагружен для применения изменений!"
L.Yes = "Да"
L.No = "Нет"
L.Page = "Страница"
L.CopyChat = "Копировать чат"
L.Done = "Готово"
L.CopyChatError = "Произошла ошибка в функции копирования чата."
L.AdditionalSettings = "Дополнительные настройки"
L.ChangeOutgoingWhisperColor = "Изменить цвет исходящих сообщений в чате шепотом."
L.EnableOutWhisperColor = "Включить пользовательский цвет исходящих сообщений в чате шепотом."
L.DisableChatEnterLeaveNotice = "Отключить уведомления о входе/выходе/смене канала (|cFF99CC33Вход/Выход/Изменено|r) в чате."

L.ProtectedChannel = " |cFFDF2B2B(Канал защищен Blizzard. Доступ аддона запрещен.)|r."

--Channel Config (Only change the actual english word, leave the characters.  It's case sensitive!)
--trailing dash is to check for things like [WorldDefense - Alterac Mountains] so it will remove location
L.ChannelGeneral = "(%[%d+%. )Общий.-%]"
L.ChannelTrade = "(%[%d+%. )Торговля.-%]"
L.ChannelWorldDefense = "(%[%d+%. )Оборона глобальный.-%]"
L.ChannelLocalDefense = "(%[%d+%. )Оборона локальный.-%]"
L.ChannelLookingForGroup = "(%[%d+%. )Поиск группы.-%]"
L.ChannelGuildRecruitment = "(%[%d+%. )Набор в гильдию.-%]"
L.ChannelNewComerChat = "(%[%d+%. )Чат новичков.-%]"
L.ChannelTradeServices  = "(%[%d+%. )Услуги %([^()]*%).-%]"

L.ShortGeneral = "ОБ"
L.ShortTrade = "ТР"
L.ShortWorldDefense = "МО"
L.ShortLocalDefense = "ЛО"
L.ShortLookingForGroup = "ПГ"
L.ShortGuildRecruitment = "НГ"
L.ShortNewComerChat = "НЧ"
L.ShortTradeServices = "ТУ"

--short channel globals
--Example: "|Hchannel:  Channel Type   |h  [short channel name]   |h %s: " 
--Example Yell: "|Hchannel:  Yell  |h  [Y]  |h %s: "   Channel Type = Yell, short name = Y
L.CHAT_WHISPER_GET 				= "[Ш] %s: "
L.CHAT_WHISPER_INFORM_GET 		= "[Ш2] %s: "
L.CHAT_YELL_GET 				= "|Hchannel:yell|h[К]|h %s: " 
L.CHAT_SAY_GET 					= "|Hchannel:say|h[С]|h %s: "
L.CHAT_BATTLEGROUND_GET			= "|Hchannel:battleground|h[ПБ]|h %s: "
L.CHAT_BATTLEGROUND_LEADER_GET 	= [[|Hchannel:battleground|h[ПБ|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]]
L.CHAT_GUILD_GET   				= "|Hchannel:guild|h[Г]|h %s: "
L.CHAT_OFFICER_GET 				= "|Hchannel:officer|h[О]|h %s: "
L.CHAT_PARTY_GET        			= "|Hchannel:party|h[Гр]|h %s: "
L.CHAT_PARTY_LEADER_GET 			= [[|Hchannel:party|h[Гр|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]]
L.CHAT_PARTY_GUIDE_GET  			= [[|Hchannel:party|h[ГЛ|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]]
L.CHAT_RAID_GET         			= "|Hchannel:raid|h[Р]|h %s: "
L.CHAT_RAID_LEADER_GET  			= [[|Hchannel:raid|h[РЛ|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]|h %s: ]]
L.CHAT_RAID_WARNING_GET 			= [[|Hchannel:raidwarning|h[РП|TInterface\GroupFrame\UI-GROUP-MAINASSISTICON:0|t]|h %s: ]]

L.EditFilterListHeader = "Редактировать список стилизованных фильтров"
L.EditStickyChannelsListHeader = "Редактировать список закрепленных каналов"

L.SocialOn = "xanChat: Социальные кнопки теперь [|cFF99CC33ВКЛ|r]"
L.SocialOff = "xanChat: Социальные кнопки теперь [|cFF99CC33ВЫКЛ|r]"
L.SocialInfo = "Скрыть социальную кнопку."

L.ScrollOn = "xanChat: Полосы прокрутки теперь [|cFF99CC33ВКЛ|r]"
L.ScrollOff = "xanChat: Полосы прокрутки теперь [|cFF99CC33ВЫКЛ|r]"
L.ScrollInfo = "Скрыть полосы прокрутки чата."

L.HideScrollBarsOn = "xanChat: Скрытие левой и правой панели кнопок теперь [|cFF99CC33ВКЛ|r]"
L.HideScrollBarsOff = "xanChat: Скрытие левой и правой панели кнопок теперь [|cFF99CC33ВЫКЛ|r]"
L.HideScrollBarsInfo = "Скрыть левые и правые панели кнопок в окнах чата. |cFFDF2B2B(Скрывает все кнопки!)|r"

L.ShortNamesOn = "xanChat: Короткие имена каналов теперь [|cFF99CC33ВКЛ|r]"
L.ShortNamesOff = "xanChat: Короткие имена каналов теперь [|cFF99CC33ВЫКЛ|r]"
L.ShortNamesInfo = "Использовать короткие имена каналов."

L.EditBoxBottom = "xanChat: Поле ввода теперь внизу [|cFF99CC33НИЗ|r]"
L.EditBoxTop = "xanChat: Поле ввода теперь вверху [|cFF99CC33ВЕРХ|r]"
L.EditBoxInfo = "Показывать поле ввода вверху окна чата."

L.TabsOn = "xanChat: Вкладки чата теперь [|cFF99CC33ВКЛ|r]"
L.TabsOff = "xanChat: Вкладки чата теперь [|cFF99CC33ВЫКЛ|r]"
L.TabsInfo = "Скрыть вкладки чата."

L.ShadowOn = "xanChat: Тени шрифта чата теперь [|cFF99CC33ВКЛ|r]"
L.ShadowOff = "xanChat: Тени шрифта чата теперь [|cFF99CC33ВЫКЛ|r]"
L.ShadowInfo = "Добавить тени к шрифту текста чата. |cFFDF2B2B(Переопределяет опцию контура.)|r"

L.OutlineOn = "xanChat: Контур шрифта чата теперь [|cFF99CC33ВКЛ|r]"
L.OutlineOff = "xanChat: Контур шрифта чата теперь [|cFF99CC33ВЫКЛ|r]"
L.OutlineInfo = "Добавить контур к шрифту текста чата."

L.EditBoxBorderOn = "xanChat: Граница поля ввода [|cFF99CC33ВКЛ|r]"
L.EditBoxBorderOff = "xanChat: Граница поля ввода [|cFF99CC33ВЫКЛ|r]"
L.EditBoxBorderInfo = "Скрыть границу поля ввода."

L.SimpleEditBoxOn = "xanChat: Упрощенное поле ввода [|cFF99CC33ВКЛ|r]"
L.SimpleEditBoxOff = "xanChat: Упрощенное поле ввода [|cFF99CC33ВЫКЛ|r]"
L.SimpleEditBoxInfo = "Показать упрощенное поле ввода с границей всплывающей подсказки."

L.SEBDesignOn = "xanChat: Альтернативный стиль поля ввода [|cFF99CC33ВКЛ|r]"
L.SEBDesignOff = "xanChat: Альтернативный стиль поля ввода [|cFF99CC33ВЫКЛ|r]"
L.SEBDesignInfo = "Включить альтернативный стиль для поля ввода."

L.CopyPasteOn = "xanChat: Кнопка копирования и вставки [|cFF99CC33ВКЛ|r]"
L.CopyPasteOff = "xanChat: Кнопка копирования и вставки [|cFF99CC33ВЫКЛ|r]"
L.CopyPasteInfo = "Показать кнопку копирования и вставки в окне чата."

L.CopyPasteLeftOn = "xanChat: Кнопка копирования и вставки слева [|cFF99CC33ВКЛ|r]"
L.CopyPasteLeftOff = "xanChat: Кнопка копирования и вставки слева [|cFF99CC33ВЫКЛ|r]"
L.CopyPasteLeftInfo = "Показать кнопку копирования и вставки слева от рамки чата."

L.PlayerChatStyleOn = "xanChat: Стилизованные имена игроков [Уровень+Цвет] [|cFF99CC33ВКЛ|r]"
L.PlayerChatStyleOff = "xanChat: Стилизованные имена игроков [Уровень+Цвет] [|cFF99CC33ВЫКЛ|r]"
L.PlayerChatStyleInfo = "Показывать стилизованные имена игроков и уровень в чате. |cFF99CC33(Использует список стилизованных фильтров выше)|r"

L.ChatTextFadeOn = "xanChat: Затухание текста чата [|cFF99CC33ВКЛ|r]"
L.ChatTextFadeOff = "xanChat: Затухание текста чата [|cFF99CC33ВЫКЛ|r]"
L.ChatTextFadeInfo = "Включить затухание текста в окнах чата."

L.ChatFrameFadeOn = "xanChat: Отключение затухания рамки чата [|cFF99CC33ВКЛ|r]"
L.ChatFrameFadeOff = "xanChat: Отключение затухания рамки чата [|cFF99CC33ВЫКЛ|r]"
L.ChatFrameFadeInfo = "Отключить затухание фона в окнах чата."

L.LockChatSettingsOn = "xanChat: Блокировка настроек чата [|cFF99CC33ВКЛ|r]"
L.LockChatSettingsOff = "xanChat: Блокировка настроек чата [|cFF99CC33ВЫКЛ|r]"
L.LockChatSettingsInfo = "Заблокировать настройки и позиции чата от изменений."
L.LockChatSettingsAlert = "Настройки чата [|cFFFF6347ЗАБЛОКИРОВАНЫ|r]."

L.ChatAlphaSet = "xanChat: Прозрачность рамки чата установлена на [|cFF20ff20%s|r]"
L.ChatAlphaSetInvalid = "xanChat: Неверная прозрачность или число не может быть больше 2"
L.ChatAlphaInfo = "Установить уровень прозрачности рамки чата. (0-100)"
L.ChatAlphaText = "Прозрачность рамки чата"

L.AdjustedEditboxOn = "xanChat: Поле ввода с дополнительным пространством [|cFF99CC33ВКЛ|r]"
L.AdjustedEditboxOff = "xanChat: Поле ввода с дополнительным пространством [|cFF99CC33ВЫКЛ|r]"
L.AdjustedEditboxInfo = "Включить дополнительное пространство между рамкой чата и полем ввода."

L.VoiceOn = "xanChat: Кнопки канала/голосового чата теперь [|cFF99CC33ВКЛ|r]"
L.VoiceOff = "xanChat: Кнопки канала/голосового чата теперь [|cFF99CC33ВЫКЛ|r]"
L.VoiceInfo = "Скрыть кнопку канала/голосового чата."

L.ChatMenuButtonOn = "xanChat: Кнопка меню чата теперь [|cFF99CC33ВКЛ|r]"
L.ChatMenuButtonOff = "xanChat: Кнопка меню чата теперь [|cFF99CC33ВЫКЛ|r]"
L.ChatMenuButtonInfo = "Скрыть кнопку меню чата."

L.MoveSocialButtonOn = "xanChat: Перемещение социальной кнопки и рамки уведомлений вниз [|cFF99CC33ВКЛ|r]"
L.MoveSocialButtonOff = "xanChat: Перемещение социальной кнопки и рамки уведомлений вниз [|cFF99CC33ВЫКЛ|r]"
L.MoveSocialButtonInfo = "Переместить социальную кнопку и рамку уведомлений вниз."

L.PageLimitText = "Недавние страницы чата для отображения в функции копирования чата. |cFF99CC33(0 для отсутствия ограничений)|r"
