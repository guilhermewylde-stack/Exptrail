local _, ns = ...

-- Leitor de guias em texto, compatível com a sintaxe usada pelo RestedXP
-- Guides. Converte o texto em passos com elementos que o motor entende.
local P = {}
ns.Parser = P

-- uiMapID das zonas clássicas citadas por nome nos guias.
local ZONES = {
    ["Durotar"] = 1411, ["Mulgore"] = 1412, ["The Barrens"] = 1413, ["Alterac Mountains"] = 1416,
    ["Arathi Highlands"] = 1417, ["Badlands"] = 1418, ["Blasted Lands"] = 1419, ["Tirisfal Glades"] = 1420,
    ["Silverpine Forest"] = 1421, ["Western Plaguelands"] = 1422, ["Eastern Plaguelands"] = 1423,
    ["Hillsbrad Foothills"] = 1424, ["The Hinterlands"] = 1425, ["Dun Morogh"] = 1426,
    ["Searing Gorge"] = 1427, ["Burning Steppes"] = 1428, ["Elwynn Forest"] = 1429,
    ["Deadwind Pass"] = 1430, ["Duskwood"] = 1431, ["Loch Modan"] = 1432, ["Redridge Mountains"] = 1433,
    ["Stranglethorn Vale"] = 1434, ["Swamp of Sorrows"] = 1435, ["Westfall"] = 1436, ["Wetlands"] = 1437,
    ["Teldrassil"] = 1438, ["Darkshore"] = 1439, ["Ashenvale"] = 1440, ["Thousand Needles"] = 1441,
    ["Stonetalon Mountains"] = 1442, ["Desolace"] = 1443, ["Feralas"] = 1444, ["Dustwallow Marsh"] = 1445,
    ["Tanaris"] = 1446, ["Azshara"] = 1447, ["Felwood"] = 1448, ["Un'Goro Crater"] = 1449,
    ["Moonglade"] = 1450, ["Silithus"] = 1451, ["Winterspring"] = 1452, ["Stormwind City"] = 1453,
    ["Orgrimmar"] = 1454, ["Ironforge"] = 1455, ["Thunder Bluff"] = 1456, ["Darnassus"] = 1457,
    ["Undercity"] = 1458,
}

local COLORS = {
    FRIENDLY = "ff00ff25", ENEMY = "ffff5722", LOOT = "ff00bcd4",
    WARN = "fffcdc00", PICK = "ffdb2eef", BUY = "ff0e8312",
}

local XP_RATE = 1

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function recolor(text)
    if not text or text == "" then return nil end
    return (text:gsub("|cRXP_(%u+)_", function(key)
        return "|c" .. (COLORS[key] or "ffffffff")
    end))
end

local function mapID(zone)
    return tonumber(zone) or ZONES[zone]
end

local tokens
local function playerTokens()
    if not tokens then
        local _, class = UnitClass("player")
        local _, race = UnitRace("player")
        local faction = UnitFactionGroup("player") or ""
        if race == "Scourge" then race = "Undead" end
        tokens = { [class:lower()] = true, [race:lower()] = true, [faction:lower()] = true }
    end
    return tokens
end

-- Filtro "<< A B/!C": alternativas separadas por "/", cada uma exigindo
-- todas as suas palavras (classe, raça ou facção; "!" nega).
function P.Match(filter)
    if not filter or filter == "" then return true end
    local player = playerTokens()
    for alternative in filter:gmatch("[^/]+") do
        local ok, any = true, false
        for word in alternative:gmatch("%S+") do
            any = true
            local negated, name = word:match("^(!?)(.+)$")
            local has = player[name:lower()] or false
            if (negated == "!") == has then
                ok = false
                break
            end
        end
        if ok and any then return true end
    end
    return false
end

local function splitFilter(line)
    local body, filter = line:match("^(.-)%s*<<%s*(.-)%s*$")
    if not body then return line end
    return body, trim((filter:gsub("%s*%-%-.*$", "")))
end

local function rateAllowed(value)
    local low, high = value:match("^([%d%.]+)%-([%d%.]+)$")
    if low then return XP_RATE >= tonumber(low) and XP_RATE <= tonumber(high) end
    local op, number = value:match("^([<>])([%d%.]+)$")
    if op == "<" then return XP_RATE < tonumber(number) end
    if op == ">" then return XP_RATE > tonumber(number) end
    return true
end

local function questList(args)
    local list = {}
    for _, value in ipairs(args) do
        local id = tonumber(value)
        if id then list[#list + 1] = math.abs(id) end
    end
    return list
end

local builders = {}

builders["goto"] = function(a, state)
    local zone = a[1]
    if not zone or zone == "" then zone = state.zone end
    state.zone = zone
    if not zone then return end
    local first, second = tonumber(a[2]), tonumber(a[3])
    if not (first and second) then return end
    local element = { kind = "goto", radius = tonumber(a[4]), pass = a[5] ~= nil }
    if element.radius == 0 then element.radius = nil end
    local id, instance = zone:match("^(%d+)/(%d+)$")
    if id then
        -- Coordenadas de mundo: primeiro o eixo oeste, depois o eixo norte.
        element.west, element.north, element.instance = first, second, tonumber(instance)
    else
        element.map, element.x, element.y = mapID(zone), first, second
        if not element.map then return end
    end
    return element
end

function builders.accept(a)
    local id = tonumber(a[1])
    return id and { kind = "accept", quest = math.abs(id) }
end

function builders.turnin(a)
    local id = tonumber(a[1])
    return id and { kind = "turnin", quest = math.abs(id) }
end

function builders.complete(a)
    local id = tonumber(a[1])
    return id and { kind = "complete", quest = math.abs(id), obj = tonumber(a[2]) }
end

function builders.xp(a)
    local value = (a[1] or ""):gsub(" ", "")
    local op, level, extra = value:match("^(<?)(%d+)([%+%.%-]?%d*)$")
    if not level then return end
    local element = { level = tonumber(level), xp = tonumber(extra) or 0 }
    if op == "<" then
        element.kind, element.test, element.want = "cond", "xp", true
    elseif a[2] then
        element.kind, element.test, element.want = "cond", "xp", false
    else
        element.kind = "xp"
    end
    return element
end

function builders.collect(a)
    local item = tonumber(a[1])
    return item and { kind = "collect", item = item, count = tonumber(a[2]) or 1, quest = tonumber(a[3]) }
end

function builders.itemcount(a)
    local item = tonumber(a[1])
    local op, count = (a[2] or "1"):match("^([<>]?)(%d+)$")
    if not (item and count) then return end
    return { kind = "cond", test = "item", item = item, op = op, count = tonumber(count) }
end

function builders.money(a)
    local op, gold = (a[1] or ""):match("^([<>])([%d%.]+)$")
    return op and { kind = "cond", test = "money", op = op, copper = tonumber(gold) * 10000 }
end

function builders.train(a)
    local spell = tonumber(a[1])
    if not spell then return end
    if a[2] == "1" then return { kind = "cond", test = "spell", spell = spell, want = false } end
    if a[2] == "3" then return { kind = "cond", test = "spell", spell = spell, want = true } end
    return { kind = "train", spell = spell }
end

function builders.zone(a)
    local map = mapID(a[1])
    return map and { kind = "zone", map = map }
end

function builders.zoneskip(a)
    local map = mapID(a[1])
    return map and { kind = "cond", test = "zone", map = map, want = a[2] ~= nil }
end

function builders.subzone(a)
    local area = tonumber(a[1])
    return area and { kind = "subzone", area = area }
end

function builders.subzoneskip(a)
    local area = tonumber(a[1])
    return area and { kind = "cond", test = "subzone", area = area, want = a[2] ~= nil }
end

for name, test in pairs({
    isOnQuest = "onQuest", isNotOnQuest = "notOnQuest", isQuestComplete = "questComplete",
    isQuestTurnedIn = "questTurnedIn", isQuestAvailable = "questAvailable",
}) do
    builders[name] = function(a)
        return { kind = "cond", test = test, quests = questList(a) }
    end
end

for _, name in ipairs({ "home", "hs", "fp", "fly" }) do
    builders[name] = function()
        return { kind = "event", event = name }
    end
end

-- Lê só o cabeçalho de um guia (nome, filtro, raça padrão, guias seguintes).
function P.Header(text)
    local header = { next = {} }
    for raw in text:gmatch("[^\r\n]+") do
        local line = trim(raw)
        if line:find("^step") then break end
        local body, filter = splitFilter(line)
        if body == "" then
            header.filter = filter
        else
            local tag, value = body:match("^#(%a+)%s*(.*)$")
            if tag == "name" then
                header.name = value
            elseif tag == "defaultfor" then
                header.defaultfor = value
            elseif tag == "next" and P.Match(filter) then
                for name in value:gmatch("[^;]+") do
                    header.next[#header.next + 1] = trim((name:gsub("^.*\\", "")))
                end
            end
        end
    end
    return header
end

-- Lê os passos. Retorna a sequência principal e os passos paralelos
-- (#completewith / #sticky), que aparecem como lembretes.
function P.Steps(text)
    local main, side, labels = {}, {}, {}
    local step, drop
    local state = {}

    local function finish()
        if step and not drop and #step.elements > 0 then
            if step.completewith or step.sticky then
                step.after = #main
                side[#side + 1] = step
            else
                main[#main + 1] = step
                if step.label then labels[step.label] = #main end
            end
        end
        step = nil
    end

    for raw in text:gmatch("[^\r\n]+") do
        local line = trim(raw)
        if line ~= "" and not line:find("^%-%-") then
            local body, filter = splitFilter(line)
            if body == "step" then
                finish()
                step, drop = { elements = {} }, not P.Match(filter)
            elseif step and not drop and P.Match(filter) then
                local first = body:sub(1, 1)
                if first == "#" then
                    local tag, value = body:match("^#(%a+)%s*(.*)$")
                    if tag == "completewith" then
                        step.completewith = value
                    elseif tag == "sticky" then
                        step.sticky = true
                    elseif tag == "label" then
                        step.label = value
                    elseif tag == "hardcore" or tag == "ssf" then
                        drop = true
                    elseif tag == "season" then
                        drop = not ("," .. value .. ","):find(",0,", 1, true)
                    elseif tag == "xprate" then
                        drop = not rateAllowed(value)
                    end
                elseif first == ">" then
                    local text = recolor(trim((body:gsub("^>+", ""))))
                    if text then table.insert(step.elements, { kind = "text", text = text }) end
                elseif first == "+" then
                    local text = recolor(trim(body:sub(2)))
                    if text then table.insert(step.elements, { kind = "manual", text = text }) end
                elseif first == "." then
                    local command, rest = body:match("^%.(%a+)%s*(.*)$")
                    if command then
                        local arguments, text = rest:match("^(.-)%s*>>%s*(.*)$")
                        arguments = (arguments or rest):gsub("%s*%-%-.*$", "")
                        local a = {}
                        for part in (arguments .. ","):gmatch("(.-),") do
                            a[#a + 1] = trim(part)
                        end
                        local builder = builders[command]
                        local element = builder and builder(a, state)
                        text = recolor(text)
                        if element then
                            element.text = text
                            table.insert(step.elements, element)
                        elseif text then
                            table.insert(step.elements, { kind = "text", text = text })
                        end
                    end
                end
            end
        end
    end
    finish()

    for _, s in ipairs(side) do
        local target = s.completewith and labels[s.completewith]
        if s.sticky and not s.completewith then
            s.to = #main
        elseif target and target > s.after then
            s.to = target
        else
            s.to = s.after + 1
        end
    end
    return main, side
end

-- Converte o formato nativo (tabela Lua, usado pelo gravador) em passos.
function P.Native(steps)
    local main = {}
    for _, s in ipairs(steps) do
        local elements = {}
        if s.x and s.y then
            elements[#elements + 1] = { kind = "goto", map = s.map, x = s.x, y = s.y, radius = s.radius }
        end
        local kind = s.type
        if kind == "accept" or kind == "turnin" or kind == "complete" then
            elements[#elements + 1] = { kind = kind, quest = s.quest, name = s.name, obj = s.obj, note = s.text }
        elseif kind == "level" then
            elements[#elements + 1] = { kind = "xp", level = s.level, xp = 0, text = s.text }
        elseif kind == "home" then
            elements[#elements + 1] = { kind = "event", event = "home", text = s.text or "Defina sua pedra de regresso" }
        elseif kind == "goto" then
            elements[#elements + 1] = { kind = "text", text = s.text or "Vá até o local marcado" }
        else
            elements[#elements + 1] = { kind = "manual", text = s.text or "Passo manual" }
        end
        main[#main + 1] = { elements = elements }
    end
    return main, {}
end
