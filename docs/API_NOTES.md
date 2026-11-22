# MWSE API для GHSO

## Core

При аудите установленная сборка MWSE `2.1.0-5469` и Lua DLL побайтно
совпали с официальным архивом. Локальный `mwse-version.txt` указывает на
ревизию `1dce8de6b87c7b216c6809fbc261a176157764ce`. По сообщению владельца
проекта, загрузка Lua, сохранения и диалоги ранее были проверены в игре.

- `event.register(tes3.event.initialized, callback)` вызывается после
  инициализации игры и загрузки плагинов. Core пишет в этот момент сообщение
  о старте. [Событие initialized](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/events/initialized.md)
- `event.register(tes3.event.loaded, callback)` вызывается после успешной
  загрузки. `e.newGame` и `e.filename` используются для подписи записи
  журнала. Ссылку на игрока Core получает заново внутри обработчика.
  [Событие loaded](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/events/loaded.md)
- `tes3.player.data` хранит сериализуемые данные в сохранении. Перед
  обращением к ним Core проверяет `supportsLuaData`, создаёт вложенные
  таблицы по отдельности и выставляет `modified` при изменении профиля.
  [Хранение данных](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/guides/storing-data.md)
- `mwse.log(message, ...)` пишет форматированное сообщение в `MWSE.log`.
  `mwse.buildDate` возвращает дату сборки в формате YYYYMMDD.
  [Справочник mwse](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/apis/mwse.md)

## Ванильное золото, репутация и фракции

- `tes3.getPlayerGold()` возвращает число золотых при игроке. Адаптер
  вызывается по запросу и читает текущее значение после проверки наличия
  `tes3.player`. Источник истины — инвентарь.
  [Справочник tes3 для целевой сборки](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/apis/tes3.md#tes3getplayergold)
- Общая ванильная репутация считывается из `tes3.mobilePlayer.object.reputation`
  при выборе тестовой темы. `object` возвращает экземпляр NPC игрока,
  а `reputation` — число. В GHSO значение не сохраняется.
  [Свойство object](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/types/tes3mobilePlayer.md#object),
  [свойство reputation](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/types/tes3npcInstance.md#reputation)
- Адаптер фракций вызывает `tes3.getFaction(id)` и считывает у игрока
  `playerJoined`, `playerExpelled` и `playerReputation`. Для действующего
  члена он читает `playerRank` и вызывает `faction:getRankName(rank)`
  с индексом от 0 до 9. Адаптер возвращает значения на момент вызова.
  Тестовый диалог использует ID `Telvanni`, подтверждённый по записи FACT
  в локальном `Morrowind.esm`.
  [Получение фракции](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/apis/tes3.md#tes3getfaction),
  [поля фракции и getRankName](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/types/tes3faction.md)
- Имя расы считывается из `tes3.mobilePlayer.object.race.name`.
  Для региона используется `tes3.getRegion()`: движок ищет регион
  текущей ячейки и при необходимости берёт последнюю внешнюю ячейку.
  [Раса экземпляра NPC](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/types/tes3npcInstance.md#race),
  [getRegion](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/apis/tes3.md#tes3getregion)
- Results передаёт ссылку на собеседника из окружения диалога. Адаптер
  считывает эффективное отношение из `reference.mobile.object.disposition`
  в момент выбора темы. При недоступном объекте диагностический вывод
  показывает `unavailable`.
  [Ссылка на mobile](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/types/tes3reference.md#mobile),
  [disposition экземпляра NPC](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/types/tes3npcInstance.md#disposition)
- Поле Results у INFO поддерживает вызов Lua-модуля через `;lua`.
  `tes3.messageBox(message, ...)` форматирует текст и по умолчанию
  выводит его в открытом диалоге. На `initialized` интеграция проверяет
  `tes3.isModActive(filename)`. При активном ESP она подписывается на
  `loaded` и добавляет тему в список игрока через `tes3.addTopic({ topic = ... })`.
  [Lua в диалогах](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/guides/lua-in-dialogues.md),
  [messageBox](https://mwse.github.io/MWSE/apis/tes3/#tes3messagebox),
  [addTopic](https://mwse.github.io/MWSE/apis/tes3/#tes3addtopic),
  [isModActive](https://mwse.github.io/MWSE/apis/tes3/#tes3ismodactive)

## Изменение отношения

В игровом прогоне на Далайн Арвел подтверждён фильтр
`event.register(tes3.event.disposition, callback, { filter = "dalyne arvel" })`.
В целевой сборке событие фильтруется по базовой записи NPC. Оно получает
уже рассчитанное ванилью отношение, включая фракционные модификаторы.
При `e.clamped == true` движок ограничивает итог диапазоном 0–100.
[Событие disposition](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/events/disposition.md),
[фильтр в исходниках сборки](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/MWSE/LuaDispositionEvent.cpp)

Запись `dalyne arvel` в локальном `Morrowind.esm` принадлежит фракции
`Telvanni` и размещена в `Sadrith Mora, Telvanni Council House, Entry`.
Дополнительный бонус за ранг использовался только для проверки события
и удалён после прогона. Ванильный расчёт остаётся источником отношения.

## Начисление влияния

Интеграция слушает `tes3.event.journal`. Она сверяет `e.topic.id` и
`e.index`. Событие целевой сборки не имеет фильтра по ID, поэтому для
остальных записей обработчик ограничивается проверкой индекса и темы.
После загрузки общий обработчик делает один запрос
`tes3.getJournalIndex({ id = ... })` на уникальный журнал. Сейчас
проверяется пять журналов влияния Телванни.
[Событие journal](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/events/journal.md),
[getJournalIndex](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/apis/tes3.md#tes3getjournalindex)

В локальном `Morrowind.esm` запись журнала `HT_Muck` с индексом 100
описывает сдачу пяти порций муска. В Results реплики `raven omayn`
подтверждён вызов `Journal HT_Muck 100`. Сдача начисляет одно очко
влияния GHSO в Доме Телванни. Источник привязан к журналу квеста,
поэтому начисление отделено от текущего членства и ранга.

Для каждого нового источника в локальном `Morrowind.esm` сверены запись
журнала с индексом 100 и команда `Journal` в Results принимающего NPC.
Правила собраны в [telvanniInfluenceSources.lua](../src/mwse/mods/GHSO/data/telvanniInfluenceSources.lua).

| Журнал | Подтверждённое завершение | NPC |
| --- | --- | --- |
| `HT_BlackJinx` | Передано кольцо «Чёрное зло». | `raven omayn` |
| `HT_CureBlight` | Подтверждена доставка зелий Андилу. | `galos mathendis` |
| `HT_DaedraSkin` | Передана кожа даэдра. | `aryon` |
| `HT_SloadSoap` | Передано мыло слоад. | `arara uvulas` |

## Завершённый пилот Горького Берега

В локальном `Morrowind.esm` ячейка Сейда Нин относится к
`Bitter Coast Region`. В реплике Фаргота о возврате кольца подтверждён
вызов `Journal MS_FargothRing 100`, а сама запись журнала описывает
возвращение предмета. В пилоте GHSO начислял за это одно очко.
Владелец проекта подтвердил в игре начисление и выдачу у Аррилла.
Пилот приостановлен. Его записи в профиле сохраняются для совместимости.

## Выдача припасов

В локальном `Morrowind.esm` подтверждены принадлежность Телванни и
размещение трёх [поставщиков](../src/mwse/mods/GHSO/data/telvanniSupplyProviders.lua),
а также записи ALCH `p_restore_magicka_s` и `p_levitation_s`. Results
общей темы передаёт `reference`. Обработчик сверяет `reference.baseObject.id`
с реестром поставщиков и проверяет условия и срок каждой позиции.
Для выдачи он получает базовое зелье через
`tes3.getObject(id)` и передаёт его в
`tes3.addItem({ reference = player, item = potion, count = 1 })`.
Первый результат `addItem` содержит количество выданных предметов.
[baseObject](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/types/tes3reference.md#baseobject),
[getObject](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/apis/tes3.md#tes3getobject),
[addItem](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/apis/tes3.md#tes3additem)

Отметка выдачи устанавливается до вызова `addItem`, чтобы вложенный
обработчик не смог повторить действие. При сбое интеграция сравнивает
количество зелий в инвентаре через `tes3.getItemCount`. При подтверждённом
отсутствии выдачи отметка сбрасывается. Если проверка инвентаря сама
завершается ошибкой, отметка сохраняется для защиты от дубля и причина
указывается в журнале.
[getItemCount](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/apis/tes3.md#tes3getitemcount)

Вложенный вызов общей темы блокируется до конца выдачи. Каждый вид
обрабатывается отдельно, поэтому сбой одного не мешает выдать другой.
Для диалога результаты собираются в одно сообщение `tes3.messageBox`.

Интервал выдачи измеряется в часах игрового мира через
`tes3.getSimulationTimestamp()`. Время считывается при обращении за
припасами и при переносе уже использованной привилегии в схему 4.
[getSimulationTimestamp](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/apis/tes3.md#tes3getsimulationtimestamp)

## Страница состояния GHSO

После `tes3.event.modConfigReady` мод регистрирует страницу через
`mwse.registerModConfig("GHSO", { onCreate = ... })`. В поставляемом
с MWSE `Data Files/MWSE/core/mcm/main.lua` выбор мода пересоздаёт
содержимое правой панели и вызывает `onCreate`. Страница строит строки
через `container:createLabel({ text = ... })` и использует ту же проверку
доступности припасов, что и диалог поставщика.
[modConfigReady](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/events/modConfigReady.md),
[registerModConfig](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/apis/mwse.md#mwse-registermodconfig),
[createLabel](https://github.com/MWSE/MWSE/blob/1dce8de6b87c7b216c6809fbc261a176157764ce/docs/source/types/tes3uiElement.md#createlabel)
