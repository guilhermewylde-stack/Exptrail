local _, ns = ...

local UI = {}
ns.UI = UI

local UPCOMING = 3
local HINTS = 3
local WIDTH = 330

local frame = CreateFrame("Frame", "ExptrailFrame", UIParent, "BackdropTemplate")
UI.frame = frame
frame:SetSize(WIDTH, 120)
frame:SetPoint("LEFT", UIParent, "LEFT", 30, 80)
frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
frame:SetBackdropColor(0, 0, 0, 0.8)
frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relative, x, y = self:GetPoint()
    ns.db.pos = { point, relative, x, y }
end)

local function text(template, justify)
    local fs = frame:CreateFontString(nil, "OVERLAY", template)
    fs:SetWidth(WIDTH - 20)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(true)
    return fs
end

local header = text("GameFontNormalSmall")
header:SetPoint("TOPLEFT", 10, -8)
header:SetWidth(WIDTH - 70)
header:SetWordWrap(false)

local current = text("GameFontHighlight")
current:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)

local objectives = text("GameFontHighlightSmall")
objectives:SetPoint("TOPLEFT", current, "BOTTOMLEFT", 8, -3)
objectives:SetWidth(WIDTH - 28)

local upcoming = text("GameFontDisableSmall")
upcoming:SetPoint("TOPLEFT", objectives, "BOTTOMLEFT", -8, -6)

local footer = text("GameFontNormalSmall")
footer:SetPoint("TOPLEFT", upcoming, "BOTTOMLEFT", 0, -6)

local function button(label, tooltip, onClick)
    local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    b:SetSize(22, 18)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(tooltip)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

local skip = button(">", "Pular este passo", function() ns.Engine.Skip() end)
skip:SetPoint("TOPRIGHT", -6, -5)
local back = button("<", "Voltar um passo", function() ns.Engine.Back() end)
back:SetPoint("RIGHT", skip, "LEFT", -2, 0)

-- XP por hora da sessão.
local session = { gained = 0 }

local function trackXP()
    local xp, max = UnitXP("player"), UnitXPMax("player")
    if session.last then
        local delta = xp - session.last
        if delta < 0 then -- subiu de nível
            delta = (session.lastMax - session.last) + xp
        end
        session.gained = session.gained + delta
    else
        session.start = GetTime()
    end
    session.last, session.lastMax = xp, max
end

local function xpLine()
    if not session.start then return "" end
    local elapsed = GetTime() - session.start
    if elapsed < 30 or session.gained <= 0 then
        return "XP/h: calculando..."
    end
    local rate = session.gained / elapsed * 3600
    local minutes = (UnitXPMax("player") - UnitXP("player")) / rate * 60
    return string.format("XP/h: %dk  |  Próximo nível em %d min", rate / 1000, minutes)
end

function UI.Refresh()
    local db, E = ns.db, ns.Engine
    if not db then return end
    if not db.shown then
        frame:Hide()
        return
    end
    frame:Show()

    local guide = E.guide
    if not (guide and guide.main) then
        header:SetText("Exptrail")
        current:SetText("Nenhum guia carregado. Use /et list e /et load <guia>.")
        objectives:SetText("")
        upcoming:SetText("")
    else
        local count = #guide.main
        local step, index = E.Current()
        header:SetText(string.format("%s  (%d/%d)", guide.name, math.min(index, count), count))
        if step then
            current:SetText(table.concat(E.Lines(step, index), "\n"))
            local hints = E.Hints(HINTS)
            for i, hint in ipairs(hints) do
                hints[i] = "|cffa0a0a0Enquanto isso:|r " .. hint
            end
            objectives:SetText(table.concat(hints, "\n"))
            local list = {}
            for i = index + 1, count do
                local nextStep = guide.main[i]
                if E.Status(nextStep, i) == "active" then
                    list[#list + 1] = E.Lines(nextStep, i)[1]
                    if #list >= UPCOMING then break end
                end
                if i - index > 30 then break end
            end
            upcoming:SetText(table.concat(list, "\n"))
        else
            current:SetText("Guia concluído!")
            objectives:SetText("")
            upcoming:SetText("")
        end
    end
    footer:SetText(xpLine())

    local height = 8 + header:GetStringHeight() + 6 + current:GetStringHeight() + 3
        + objectives:GetStringHeight() + 6 + upcoming:GetStringHeight() + 6
        + footer:GetStringHeight() + 10
    frame:SetHeight(height)
    if ns.Arrow then ns.Arrow.Refresh() end
end

ns.On("PLAYER_LOGIN", function()
    local pos = ns.db.pos
    if pos then
        frame:ClearAllPoints()
        frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    end
    trackXP()
end)

ns.On("PLAYER_XP_UPDATE", trackXP)
