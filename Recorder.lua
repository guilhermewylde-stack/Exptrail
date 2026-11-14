local _, ns = ...

-- Gravador de rotas: enquanto ligado, cada quest aceita ou entregue vira um
-- passo com o questID, o título, o mapa e as coordenadas reais do jogo.
local R = {}
ns.Recorder = R

local function add(step)
    local map, x, y = ns.PlayerPosition()
    if map then
        step.map = map
        step.x = math.floor(x * 1000 + 0.5) / 10
        step.y = math.floor(y * 1000 + 0.5) / 10
    end
    table.insert(ns.db.recorded, step)
    ns.Print(string.format("Gravado #%d: %s %s", #ns.db.recorded, step.type, step.name or step.text or ""))
end

function R.Toggle()
    ns.db.recording = not ns.db.recording
    ns.Print("Gravador " .. (ns.db.recording and "ligado" or "desligado")
        .. string.format(" (%d passos gravados)", #ns.db.recorded))
end

function R.Mark(note)
    add({ type = "goto", text = note ~= "" and note or nil })
end

function R.Clear()
    ns.db.recorded = {}
    ns.Print("Rota gravada apagada.")
end

local function serialize()
    local out = { "Exptrail.RegisterGuide({", '    name = "Minha rota",', "    steps = {" }
    for _, step in ipairs(ns.db.recorded) do
        local parts = { string.format("type = %q", step.type) }
        if step.quest then parts[#parts + 1] = "quest = " .. step.quest end
        if step.name then parts[#parts + 1] = string.format("name = %q", step.name) end
        if step.text then parts[#parts + 1] = string.format("text = %q", step.text) end
        if step.map then
            parts[#parts + 1] = string.format("map = %d, x = %.1f, y = %.1f", step.map, step.x, step.y)
        end
        out[#out + 1] = "        { " .. table.concat(parts, ", ") .. " },"
    end
    out[#out + 1] = "    },"
    out[#out + 1] = "})"
    return table.concat(out, "\n")
end

local window
function R.Export()
    if not window then
        window = CreateFrame("Frame", "ExptrailExport", UIParent, "BackdropTemplate")
        window:SetSize(520, 340)
        window:SetPoint("CENTER")
        window:SetFrameStrata("DIALOG")
        window:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        window:SetBackdropColor(0, 0, 0, 0.95)

        local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT")

        local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 10, -30)
        scroll:SetPoint("BOTTOMRIGHT", -30, 10)

        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(470)
        edit:SetAutoFocus(false)
        edit:SetScript("OnEscapePressed", function() window:Hide() end)
        scroll:SetScrollChild(edit)
        window.edit = edit
    end
    window.edit:SetText(serialize())
    window:Show()
    window.edit:SetFocus()
    window.edit:HighlightText()
end

ns.On("QUEST_ACCEPTED", function(a, b)
    if not ns.db.recording then return end
    local id = b or a
    add({ type = "accept", quest = id, name = C_QuestLog.GetTitleForQuestID(id) })
end)

ns.On("QUEST_TURNED_IN", function(id)
    if not ns.db.recording then return end
    add({ type = "turnin", quest = id, name = C_QuestLog.GetTitleForQuestID(id) })
end)
