local _, ns = ...

local E = {}
ns.Engine = E

local LABEL = {
    accept = "Aceite",
    turnin = "Entregue",
    complete = "Complete",
    ["goto"] = "Vá até",
    level = "Chegue ao nível",
    home = "Defina sua pedra de regresso",
    train = "Treine suas habilidades",
}

local function flagged(id)
    return id and (ns.db.done[id] or C_QuestLog.IsQuestFlaggedCompleted(id)) or false
end

-- Descobre o questID real de um passo. Se o ID do guia não bater com o do
-- jogo, cai para o título da quest (visto no log ou já aceito antes).
function E.QuestID(step)
    local id = step.quest
    if id and (C_QuestLog.IsOnQuest(id) or flagged(id)) then
        return id
    end
    local name = step.name
    if name then
        if ns.db.names[name] then
            return ns.db.names[name]
        end
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

local function objectivesDone(id, index)
    if index then
        local list = C_QuestLog.GetQuestObjectives(id)
        local objective = list and list[index]
        return objective and objective.finished or false
    end
    return C_QuestLog.IsComplete(id) or C_QuestLog.ReadyForTurnIn(id) or false
end

function E.IsDone(index)
    local step = E.guide.steps[index]
    if ns.db.manual[index] then return true end
    local kind = step.type
    if kind == "level" then
        return UnitLevel("player") >= step.level
    end
    if not (step.quest or step.name) then return false end
    local id = E.QuestID(step)
    if not id then return false end
    if kind == "accept" then
        return C_QuestLog.IsOnQuest(id) or flagged(id)
    elseif kind == "turnin" then
        return flagged(id)
    elseif kind == "complete" then
        return flagged(id) or (C_QuestLog.IsOnQuest(id) and objectivesDone(id, step.obj))
    end
    return false
end

function E.Current()
    local guide = E.guide
    if not guide then return end
    return guide.steps[ns.db.step], ns.db.step
end

function E.Title(step)
    local id = E.QuestID(step)
    return (id and C_QuestLog.GetTitleForQuestID(id)) or step.name or ("Quest " .. tostring(id))
end

-- Texto principal de um passo e, para passos "complete", os objetivos.
function E.Describe(step)
    local kind = step.type
    local text
    if kind == "accept" or kind == "turnin" or kind == "complete" then
        text = LABEL[kind] .. " |cffffd100" .. E.Title(step) .. "|r"
    elseif kind == "level" then
        text = LABEL.level .. " " .. step.level
    else
        text = LABEL[kind]
    end
    if step.text then
        text = text and (text .. " - " .. step.text) or step.text
    end

    local lines
    if kind == "complete" then
        local id = E.QuestID(step)
        local list = id and C_QuestLog.GetQuestObjectives(id)
        if list then
            lines = {}
            for i, objective in ipairs(list) do
                if not step.obj or step.obj == i then
                    local color = objective.finished and "|cff40ff40" or "|cffffffff"
                    lines[#lines + 1] = color .. (objective.text or "") .. "|r"
                end
            end
        end
    end
    return text or "", lines
end

function E.Update()
    local guide = E.guide
    if not guide then return end
    local db, count = ns.db, #guide.steps
    while db.step <= count and E.IsDone(db.step) do
        db.step = db.step + 1
    end
    if db.step > count and guide.next and ns.guides[guide.next] then
        ns.Print("Guia concluído. Carregando: " .. guide.next)
        E.Load(guide.next, true)
        return
    end
    ns.UI.Refresh()
end

-- Vários eventos chegam juntos; junta tudo em uma única atualização.
local queued
function E.Queue()
    if queued then return end
    queued = true
    C_Timer.After(0.1, function()
        queued = false
        E.Update()
    end)
end

function E.Load(name, restart)
    local guide = ns.guides[name]
    if not guide then return false end
    local db = ns.db
    if restart or db.guide ~= name then
        db.step = 1
        db.manual = {}
    end
    db.guide = name
    E.guide = guide

    -- Índices usados pela automação de aceitar/entregar.
    E.acceptSet, E.turninSet = {}, {}
    for _, step in ipairs(guide.steps) do
        local set = (step.type == "accept" and E.acceptSet) or (step.type == "turnin" and E.turninSet)
        if set then
            if step.quest then set[step.quest] = true end
            if step.name then set[step.name] = true end
        end
    end
    E.Update()
    return true
end

function E.Skip()
    local _, index = E.Current()
    if index and index <= #E.guide.steps then
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

-- Escolhe o guia salvo ou o primeiro compatível com a facção/raça.
local function pickGuide()
    local db = ns.db
    if db.guide and ns.guides[db.guide] then return db.guide end
    local faction = UnitFactionGroup("player")
    local _, race = UnitRace("player")
    local fallback
    for _, name in ipairs(ns.order) do
        local guide = ns.guides[name]
        if not guide.faction or guide.faction == faction then
            if guide.race == race then return name end
            fallback = fallback or name
        end
    end
    return fallback
end

ns.On("PLAYER_LOGIN", function()
    -- Rota gravada anteriormente fica disponível como guia.
    if #ns.db.recorded > 0 then
        ns.RegisterGuide({ name = "Gravado", steps = ns.db.recorded })
    end
    local name = pickGuide()
    if name then
        E.Load(name)
    else
        ns.UI.Refresh()
    end
end)

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

ns.On("HEARTHSTONE_BOUND", function()
    local step, index = E.Current()
    if step and step.type == "home" then
        ns.db.manual[index] = true
    end
    E.Queue()
end)

for _, event in ipairs({ "QUEST_LOG_UPDATE", "QUEST_REMOVED", "PLAYER_LEVEL_UP", "ZONE_CHANGED_NEW_AREA" }) do
    ns.On(event, E.Queue)
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
