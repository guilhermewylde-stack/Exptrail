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

local target -- { map, x, y, index, radius }

function Arrow.Refresh()
    target = nil
    local step, index = ns.Engine.Current()
    if ns.db.arrow and step and step.x and step.y then
        target = { map = step.map, x = step.x / 100, y = step.y / 100, index = index, radius = step.radius }
    end
    frame:SetShown(target ~= nil)
end

local function update()
    local map, _, _, continent, world = ns.PlayerPosition()
    if not world then
        texture:Hide()
        label:SetText("")
        return
    end

    -- Sem mapa válido no passo, as coordenadas valem para a zona atual.
    local targetMap = target.map
    if not (targetMap and C_Map.GetMapInfo(targetMap)) then
        targetMap = map
    end
    local targetContinent, targetWorld = C_Map.GetWorldPosFromMapPos(targetMap, CreateVector2D(target.x, target.y))
    if not targetWorld or targetContinent ~= continent then
        texture:Hide()
        label:SetText("outro continente")
        return
    end

    -- Coordenadas de mundo: x cresce para o norte, y cresce para o oeste.
    local px, py = world:GetXY()
    local tx, ty = targetWorld:GetXY()
    local north, west = tx - px, ty - py
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

    local step = ns.Engine.Current()
    if step and step.type == "goto" and distance <= (target.radius or ARRIVE_YARDS) then
        ns.db.manual[target.index] = true
        ns.Engine.Queue()
    end
end

local elapsed = 0
frame:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < 0.05 or not target then return end
    elapsed = 0
    update()
end)
