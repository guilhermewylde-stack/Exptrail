local ADDON, ns = ...

ns.guides, ns.order = {}, {}

function ns.RegisterGuide(guide)
    if not ns.guides[guide.name] then
        ns.order[#ns.order + 1] = guide.name
    end
    ns.guides[guide.name] = guide
end

-- Permite que arquivos de guia exportados pelo gravador se registrem.
Exptrail = { RegisterGuide = ns.RegisterGuide }

function ns.Print(msg)
    print("|cff33ccffExptrail|r: " .. tostring(msg))
end

-- Despacho de eventos. O registro usa pcall porque um evento inexistente
-- nesta versão do cliente geraria erro e interromperia o carregamento.
local frame = CreateFrame("Frame")
local handlers = {}

function ns.On(event, fn)
    if not handlers[event] then
        handlers[event] = {}
        pcall(frame.RegisterEvent, frame, event)
    end
    table.insert(handlers[event], fn)
end

frame:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do
        list[i](...)
    end
end)

local defaults = {
    step = 1,
    manual = {},   -- passos marcados como feitos manualmente (ou por chegada)
    done = {},     -- questIDs entregues
    names = {},    -- título da quest -> questID visto neste personagem
    recorded = {}, -- passos gravados pelo gravador de rotas
    auto = true,
    arrow = true,
    shown = true,
}

ns.On("ADDON_LOADED", function(name)
    if name ~= ADDON then return end
    ExptrailCharDB = ExptrailCharDB or {}
    for key, value in pairs(defaults) do
        if ExptrailCharDB[key] == nil then
            ExptrailCharDB[key] = value
        end
    end
    ns.db = ExptrailCharDB
end)

-- Posição do jogador: mapa atual, coordenadas 0-1 e posição no mundo.
-- Retorna nil dentro de instâncias, onde o cliente não informa a posição.
function ns.PlayerPosition()
    local map = C_Map.GetBestMapForUnit("player")
    if not map then return end
    local pos = C_Map.GetPlayerMapPosition(map, "player")
    if not pos then return end
    local x, y = pos:GetXY()
    local continent, world = C_Map.GetWorldPosFromMapPos(map, pos)
    return map, x, y, continent, world
end

SLASH_EXPTRAIL1, SLASH_EXPTRAIL2 = "/exptrail", "/et"
SlashCmdList.EXPTRAIL = function(input)
    local cmd, rest = (input or ""):match("^(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()
    local db, E = ns.db, ns.Engine

    if cmd == "" then
        db.shown = not db.shown
        ns.UI.Refresh()
    elseif cmd == "list" or cmd == "lista" then
        for _, name in ipairs(ns.order) do
            ns.Print((name == db.guide and "> " or "  ") .. name)
        end
    elseif cmd == "load" or cmd == "guia" then
        if not E.Load(rest, true) then
            ns.Print("Guia não encontrado: " .. rest .. " (use /et list)")
        end
    elseif cmd == "reset" then
        E.Load(db.guide, true)
    elseif cmd == "skip" or cmd == "pular" then
        E.Skip()
    elseif cmd == "back" or cmd == "voltar" then
        E.Back()
    elseif cmd == "auto" then
        db.auto = not db.auto
        ns.Print("Aceitar/entregar automático: " .. (db.auto and "ligado" or "desligado"))
    elseif cmd == "arrow" or cmd == "seta" then
        db.arrow = not db.arrow
        ns.UI.Refresh()
    elseif cmd == "rec" then
        ns.Recorder.Toggle()
    elseif cmd == "mark" or cmd == "marcar" then
        ns.Recorder.Mark(rest)
    elseif cmd == "export" or cmd == "exportar" then
        ns.Recorder.Export()
    elseif cmd == "clear" or cmd == "limpar" then
        ns.Recorder.Clear()
    else
        ns.Print("Comandos: /et (mostrar/ocultar), list, load <guia>, reset, skip, back, auto, arrow")
        ns.Print("Gravador: /et rec (liga/desliga), mark <texto>, export, clear")
    end
end
