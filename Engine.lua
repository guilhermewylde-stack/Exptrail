local _, ns = ...

local E = {}
ns.Engine = E

-- Elementos que precisam ser concluídos para o passo terminar.
local COMPLETABLE = {
    accept = true, turnin = true, complete = true, xp = true, collect = true,
    zone = true, subzone = true, train = true, event = true, manual = true,
}

local HEARTHSTONE_SPELL = 8690

local function flagged(id)
    return id and (ns.db.done[id] or C_QuestLog.IsQuestFlaggedCompleted(id)) or false
end

local function onQuest(id)
    return id and C_QuestLog.IsOnQuest(id) or false
end

local function questComplete(id)
    return onQuest(id) and (C_QuestLog.IsComplete(id) or C_QuestLog.ReadyForTurnIn(id) or false)
end

-- Descobre o questID real de um elemento. Guias nativos podem trazer o
-- título, usado quando o ID do guia não bate com o do jogo.
function E.QuestID(element)
    local id = element.quest
    if id and (onQuest(id) or flagged(id)) then return id end
    local name = element.name
    if name then
        if ns.db.names[name] then return ns.db.names[name] end
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and info.title == name then
                ns.db.names[name] = info.questID
                return info.questID
            end
        end
    end
    return id
end

local function itemCount(item)
    local count = C_Item and C_Item.GetItemCount or GetItemCount
    return count and count(item) or 0
end

local function spellKnown(spell)
    return (IsPlayerSpell and IsPlayerSpell(spell))
        or (IsSpellKnown and IsSpellKnown(spell))
        or (C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(spell))
        or false
end

local function inZone(map)
    local id = C_Map.GetBestMapForUnit("player")
    for _ = 1, 6 do
        if not id or id == 0 then return false end
        if id == map then return true end
        local info = C_Map.GetMapInfo(id)
        id = info and info.parentMapID
    end
    return false
end

local function inSubzone(area)
    local name = C_Map.GetAreaInfo and C_Map.GetAreaInfo(area)
    return name ~= nil and (name == GetSubZoneText() or name == GetZoneText())
end

local function xpReached(level, xp)
    local current, cur, max = UnitLevel("player"), UnitXP("player"), UnitXPMax("player")
    if xp < 0 then
        return current >= level or (current == level - 1 and max - cur <= -xp)
    elseif xp > 0 and xp < 1 then
        return current > level or (current == level and cur / max >= xp)
    end
    return current > level or (current == level and cur >= xp)
end

local function anyQuest(list, test)
    for _, id in ipairs(list) do
        if test(id) then return true end
    end
    return false
end

local function conditionOK(e)
    local test = e.test
    if test == "xp" then
        return xpReached(e.level, e.xp) == e.want
    elseif test == "item" then
        local have = itemCount(e.item)
        if e.op == "<" then return have < e.count end
        if e.op == ">" then return have > e.count end
        return have >= e.count
    elseif test == "money" then
        local money = GetMoney()
        if e.op == "<" then return money < e.copper end
        return money > e.copper
    elseif test == "spell" then
        return spellKnown(e.spell) == e.want
    elseif test == "zone" then
        return inZone(e.map) == e.want
    elseif test == "subzone" then
        return inSubzone(e.area) == e.want
    elseif test == "onQuest" then
        return anyQuest(e.quests, onQuest)
    elseif test == "notOnQuest" then
        return not anyQuest(e.quests, onQuest)
    elseif test == "questComplete" then
        return anyQuest(e.quests, questComplete)
    elseif test == "questTurnedIn" then
        return anyQuest(e.quests, flagged)
    elseif test == "questAvailable" then
        return anyQuest(e.quests, function(id) return not onQuest(id) and not flagged(id) end)
    end
    return true
end

local function elementDone(e, key, index)
    local kind = e.kind
    if kind == "accept" then
        local id = E.QuestID(e)
        return onQuest(id) or flagged(id)
    elseif kind == "turnin" then
        return flagged(E.QuestID(e))
    elseif kind == "complete" then
        local id = E.QuestID(e)
        if flagged(id) then return true end
        if not onQuest(id) then return false end
        if e.obj then
            local list = C_QuestLog.GetQuestObjectives(id)
            local objective = list and list[e.obj]
            if objective then return objective.finished or false end
        end
        return questComplete(id)
    elseif kind == "xp" then
        return xpReached(e.level, e.xp)
    elseif kind == "collect" then
        return itemCount(e.item) >= e.count or (e.quest and (flagged(e.quest) or questComplete(e.quest))) or false
    elseif kind == "zone" then
        return inZone(e.map)
    elseif kind == "subzone" then
        return inSubzone(e.area)
    elseif kind == "train" then
        return spellKnown(e.spell)
    elseif kind == "event" then
        return ns.db.marks[key .. ":" .. index] or false
    end
    return false
end

-- Próximo ponto de passagem ainda não visitado de um passo. Um ponto com
-- ações logo depois dele vale enquanto elas estiverem pendentes; um ponto
-- sem ações é só caminho e vale até ser alcançado.
local function pendingWaypoint(step, key)
    local elements = step.elements
    local last
    for i, e in ipairs(elements) do
        if e.kind == "goto" then
            last = i
            local bound, pending = 0, false
            for j = i + 1, #elements do
                local nextElement = elements[j]
                if nextElement.kind == "goto" then break end
                if COMPLETABLE[nextElement.kind] then
                    bound = bound + 1
                    if not elementDone(nextElement, key, j) then pending = true end
                end
            end
            if bound > 0 then
                if pending then return e, i end
            elseif not ns.db.marks[key .. ":g" .. i] then
                return e, i
            end
        end
    end
    return nil, nil, last
end

-- "done", "active" ou "skip" (alguma condição do passo não vale).
function E.Status(step, key)
    if ns.db.manual[key] then return "done" end
    local total, done = 0, 0
    for i, e in ipairs(step.elements) do
        if e.kind == "cond" then
            if not conditionOK(e) then return "skip" end
        elseif COMPLETABLE[e.kind] then
            total = total + 1
            if elementDone(e, key, i) then done = done + 1 end
        end
    end
    if total > 0 then
        return done == total and "done" or "active"
    end
    -- Passo só de deslocamento: termina ao chegar no último ponto.
    local waypoint, _, last = pendingWaypoint(step, key)
    if last and not waypoint then return "done" end
    return "active"
end

function E.Current()
    local guide = E.guide
    if not (guide and guide.main) then return end
    return guide.main[ns.db.step], ns.db.step
end

-- Destino da seta para o passo atual.
function E.Target()
    local step, key = E.Current()
    if not step then return end
    local waypoint, index, last = pendingWaypoint(step, key)
    if not waypoint and last then
        -- Todos os pontos visitados e o passo continua: recomeça a ronda.
        for i, e in ipairs(step.elements) do
            if e.kind == "goto" then ns.db.marks[key .. ":g" .. i] = nil end
        end
        waypoint, index = pendingWaypoint(step, key)
        if not waypoint then waypoint, index = step.elements[last], last end
    end
    return waypoint, index, key
end

function E.Reached(key, index)
    local mark = key .. ":g" .. index
    if ns.db.marks[mark] then return end
    ns.db.marks[mark] = true
    E.Queue()
end

local function questTitle(e)
    local id = E.QuestID(e)
    return (id and C_QuestLog.GetTitleForQuestID(id)) or e.name or ("quest " .. tostring(id))
end

local function elementText(e)
    local kind = e.kind
    if kind == "complete" then
        local id = E.QuestID(e)
        local list = onQuest(id) and C_QuestLog.GetQuestObjectives(id)
        if list then
            local parts = {}
            for i, objective in ipairs(list) do
                if (not e.obj or e.obj == i) and objective.text then
                    parts[#parts + 1] = objective.text
                end
            end
            if #parts > 0 then return table.concat(parts, "\n") end
        end
        return e.text or ("Complete |cffffd100" .. questTitle(e) .. "|r")
    end
    if e.text then return e.text end
    if kind == "accept" then
        return "Aceite |cffffd100" .. questTitle(e) .. "|r" .. (e.note and (" - " .. e.note) or "")
    elseif kind == "turnin" then
        return "Entregue |cffffd100" .. questTitle(e) .. "|r" .. (e.note and (" - " .. e.note) or "")
    elseif kind == "xp" then
        return "Chegue ao nível " .. e.level
    end
end

-- Linhas de texto de um passo; ações já concluídas ficam marcadas.
function E.Lines(step, key)
    local lines = {}
    for i, e in ipairs(step.elements) do
        local text = elementText(e)
        if text then
            if COMPLETABLE[e.kind] and e.kind ~= "manual" and elementDone(e, key, i) then
                text = "|cff40ff40[ok]|r " .. text
            end
            lines[#lines + 1] = text
        end
    end
    return lines
end

-- Lembretes: passos paralelos ativos no trecho atual do guia.
function E.Hints(limit)
    local hints = {}
    local guide = E.guide
    if not (guide and guide.side) then return hints end
    local position = ns.db.step
    for n, s in ipairs(guide.side) do
        if position > s.after and position <= s.to then
            local key = "s" .. n
            if E.Status(s, key) == "active" then
                local lines = E.Lines(s, key)
                if lines[1] then hints[#hints + 1] = lines[1] end
                if #hints >= limit then break end
            end
        end
    end
    return hints
end

function E.Update()
    local guide = E.guide
    if not (guide and guide.main) then return end
    local db, count = ns.db, #guide.main
    while db.step <= count and E.Status(guide.main[db.step], db.step) ~= "active" do
        db.step = db.step + 1
    end
    if db.step > count and guide.next then
        for _, name in ipairs(guide.next) do
            if ns.guides[name] then
                ns.Print("Guia concluído. Carregando: " .. name)
                E.Load(name, true)
                return
            end
        end
    end
    ns.UI.Refresh()
end

-- Vários eventos chegam juntos; junta tudo em uma única atualização.
local queued
function E.Queue()
    if queued or not E.ready then return end
    queued = true
    C_Timer.After(0.1, function()
        queued = false
        E.Update()
    end)
end

function E.Find(name)
    if ns.guides[name] then return name end
    local wanted = name:lower()
    for _, candidate in ipairs(ns.order) do
        if candidate:lower():find(wanted, 1, true) then return candidate end
    end
end

function E.Load(name, restart)
    name = name and E.Find(name)
    local guide = name and ns.guides[name]
    if not guide then return false end
    local db = ns.db
    if restart or db.guide ~= name then
        db.step = 1
        db.manual = {}
        db.marks = {}
    end
    db.guide = name
    E.guide = guide

    if not guide.main then
        if guide.raw then
            guide.main, guide.side = ns.Parser.Steps(guide.raw)
        else
            guide.main, guide.side = ns.Parser.Native(guide.steps)
        end
    end

    -- Índices usados pela automação de aceitar/entregar.
    E.acceptSet, E.turninSet = {}, {}
    local function index(steps)
        for _, step in ipairs(steps) do
            for _, e in ipairs(step.elements) do
                local set = (e.kind == "accept" and E.acceptSet) or (e.kind == "turnin" and E.turninSet)
                if set then
                    if e.quest then set[e.quest] = true end
                    if e.name then set[e.name] = true end
                end
            end
        end
    end
    index(guide.main)
    index(guide.side)

    if E.ready then E.Update() end
    return true
end

function E.Skip()
    local step, index = E.Current()
    if step then
        ns.db.manual[index] = true
        E.Update()
    end
end

function E.Back()
    local db = ns.db
    if not E.guide or db.step <= 1 then return end
    db.step = db.step - 1
    db.manual[db.step] = nil
    ns.UI.Refresh()
end

-- Escolhe o guia salvo ou o indicado para a raça/classe do personagem.
local function pickGuide()
    local db = ns.db
    if db.guide and ns.guides[db.guide] then return db.guide end
    local faction = UnitFactionGroup("player")
    local _, race = UnitRace("player")
    local fallback
    for _, name in ipairs(ns.order) do
        local guide = ns.guides[name]
        if guide.raw then
            if guide.defaultfor and ns.Parser.Match(guide.defaultfor) then return name end
        elseif not guide.faction or guide.faction == faction then
            if guide.race == race then return name end
            fallback = fallback or name
        end
    end
    return fallback or ns.order[1]
end

ns.On("PLAYER_LOGIN", function()
    -- Guias em texto: registra só os que servem para este personagem.
    for _, text in ipairs(ns.rawGuides) do
        local header = ns.Parser.Header(text)
        if header.name and not ns.guides[header.name] and ns.Parser.Match(header.filter) then
            ns.RegisterGuide({ name = header.name, raw = text, next = header.next, defaultfor = header.defaultfor })
        end
    end
    -- Rota gravada anteriormente fica disponível como guia.
    if #ns.db.recorded > 0 then
        ns.RegisterGuide({ name = "Gravado", steps = ns.db.recorded })
    end
    local name = pickGuide()
    if name then E.Load(name) end
    ns.UI.Refresh()
end)

-- O log de quests só fica confiável um pouco depois de entrar no mundo;
-- avaliar antes disso faria o guia pular passos condicionais.
ns.On("PLAYER_ENTERING_WORLD", function()
    if E.ready then return end
    C_Timer.After(2, function()
        E.ready = true
        E.Update()
    end)
end)

-- Marca elementos de evento (pedra de regresso, voo) do trecho atual.
local function mark(event)
    local guide = E.guide
    if not (guide and guide.main) then return end
    local function apply(step, key)
        for i, e in ipairs(step.elements) do
            if e.kind == "event" and e.event == event then
                ns.db.marks[key .. ":" .. i] = true
            end
        end
    end
    local step, index = E.Current()
    if step then apply(step, index) end
    for n, s in ipairs(guide.side) do
        if ns.db.step > s.after and ns.db.step <= s.to then apply(s, "s" .. n) end
    end
    E.Queue()
end

ns.On("QUEST_ACCEPTED", function(a, b)
    local id = b or a -- mainline envia (questID); clientes clássicos, (índice, questID)
    local title = id and C_QuestLog.GetTitleForQuestID(id)
    if title then ns.db.names[title] = id end
    E.Queue()
end)

ns.On("QUEST_TURNED_IN", function(id)
    if id then ns.db.done[id] = true end
    E.Queue()
end)

ns.On("HEARTHSTONE_BOUND", function() mark("home") end)

ns.On("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spell)
    if unit == "player" and spell == HEARTHSTONE_SPELL then mark("hs") end
end)

ns.On("TAXIMAP_OPENED", function() mark("fp") end)

ns.On("PLAYER_CONTROL_LOST", function()
    C_Timer.After(1, function()
        if UnitOnTaxi and UnitOnTaxi("player") then mark("fly") end
    end)
end)

for _, event in ipairs({
    "QUEST_LOG_UPDATE", "QUEST_REMOVED", "PLAYER_LEVEL_UP", "PLAYER_XP_UPDATE", "ZONE_CHANGED",
    "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "BAG_UPDATE_DELAYED", "PLAYER_MONEY", "SPELLS_CHANGED",
}) do
    ns.On(event, function() E.Queue() end)
end

-- Automação: só age em quests que fazem parte do guia. Segure Shift para pular.
local function auto()
    return ns.db.auto and E.guide and not IsShiftKeyDown()
end

local function wanted(set, id, title)
    return set and ((id and set[id]) or (title and set[title])) or false
end

ns.On("GOSSIP_SHOW", function()
    if not auto() or not C_GossipInfo then return end
    for _, quest in ipairs(C_GossipInfo.GetActiveQuests() or {}) do
        if quest.isComplete and wanted(E.turninSet, quest.questID, quest.title) then
            return C_GossipInfo.SelectActiveQuest(quest.questID)
        end
    end
    for _, quest in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
        if wanted(E.acceptSet, quest.questID, quest.title) then
            return C_GossipInfo.SelectAvailableQuest(quest.questID)
        end
    end
end)

ns.On("QUEST_DETAIL", function()
    if auto() and wanted(E.acceptSet, GetQuestID(), GetTitleText()) then
        AcceptQuest()
    end
end)

ns.On("QUEST_PROGRESS", function()
    if auto() and IsQuestCompletable() and wanted(E.turninSet, GetQuestID(), GetTitleText()) then
        CompleteQuest()
    end
end)

ns.On("QUEST_COMPLETE", function()
    -- Com mais de uma recompensa para escolher, a decisão fica com o jogador.
    if auto() and GetNumQuestChoices() <= 1 and wanted(E.turninSet, GetQuestID(), GetTitleText()) then
        GetQuestReward(1)
    end
end)
