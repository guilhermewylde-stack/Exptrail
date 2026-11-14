local _, ns = ...

local Arrow = {}
ns.Arrow = Arrow

local ARRIVE_YARDS = 12

local frame = CreateFrame("Frame", "ExptrailArrow", ns.UI.frame)
frame:SetSize(56, 56)
frame:SetPoint("BOTTOM", ns.UI.frame, "TOP", 0, 4)

local texture = frame:CreateTexture(nil, "OVERLAY")
texture:SetTexture("Interface\\Minimap\\MiniMap-QuestArrow") -- aponta para cima
texture:SetSize(42, 42)
texture:SetPoint("TOP")

local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
label:SetPoint("BOTTOM")

local visible = false

function Arrow.Refresh()
    visible = ns.db.arrow and ns.Engine.Target() ~= nil
    frame:SetShown(visible)
end

local function update()
    local target, index, key = ns.Engine.Target()
    if not target then return end
    local map, _, _, continent, world = ns.PlayerPosition()
    if not world then
        texture:Hide()
        label:SetText("")
        return
    end

    -- Coordenadas de mundo: x cresce para o norte, y cresce para o oeste.
    local north, west, targetContinent
    if target.north then
        north, west, targetContinent = target.north, target.west, target.instance
    else
        -- Sem mapa válido no passo, as coordenadas valem para a zona atual.
        local targetMap = target.map
        if not (targetMap and C_Map.GetMapInfo(targetMap)) then targetMap = map end
        local point
        targetContinent, point = C_Map.GetWorldPosFromMapPos(targetMap, CreateVector2D(target.x / 100, target.y / 100))
        if point then north, west = point:GetXY() end
    end
    if not north or targetContinent ~= continent then
        texture:Hide()
        label:SetText("outro continente")
        return
    end

    local px, py = world:GetXY()
    north, west = north - px, west - py
    local distance = math.sqrt(north * north + west * west)
    label:SetText(string.format("%d m", distance))

    local facing = GetPlayerFacing()
    if facing then
        -- Ângulo anti-horário a partir do norte, igual ao de GetPlayerFacing.
        texture:SetRotation(math.atan2(west, north) - facing)
        texture:Show()
    else
        texture:Hide()
    end

    if distance <= (target.radius or ARRIVE_YARDS) then
        ns.Engine.Reached(key, index)
    end
end

local elapsed = 0
frame:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < 0.05 or not visible then return end
    elapsed = 0
    update()
end)
