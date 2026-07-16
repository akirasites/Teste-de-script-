--[[
    ╔══════════════════════════════════════════════════════╗
    ║              BUTTON SPY v2.0                         ║
    ║         by CoiledTom Hub — Mobile Ready              ║
    ║   Detecta tudo que um botão faz no lado do cliente   ║
    ╚══════════════════════════════════════════════════════╝
    
    COMPATÍVEL COM: Delta Executor (mobile), PC executors
    RECURSOS:
      - Detecta TextButton e ImageButton clicados
      - Monitora mudanças pós-clique (GUIs, sons, tweens, etc.)
      - Remote Spy integrado
      - Script Spy integrado
      - GUI arrastável, scroll logs, botões de cópia
--]]

-- ═══════════════════════════════════════════════
--  SERVIÇOS & VARIÁVEIS GLOBAIS
-- ═══════════════════════════════════════════════

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local CoreGui            = game:GetService("CoreGui")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local SoundService       = game:GetService("SoundService")

local LocalPlayer        = Players.LocalPlayer
local PlayerGui          = LocalPlayer:WaitForChild("PlayerGui")
local Mouse              = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════
--  UTILITÁRIOS
-- ═══════════════════════════════════════════════

local function safeToString(v)
    if v == nil then return "nil" end
    local ok, res = pcall(tostring, v)
    return ok and res or "<erro ao converter>"
end

local function getTypeName(v)
    if typeof then return typeof(v) end
    return type(v)
end

local function serializeArg(v)
    local t = getTypeName(v)
    if t == "string"  then return '"' .. v .. '"' end
    if t == "number"  then return tostring(v) end
    if t == "boolean" then return tostring(v) end
    if t == "Instance" then
        local ok, path = pcall(function() return v:GetFullName() end)
        return ok and ("[Instance] " .. path) or "[Instance] <sem acesso>"
    end
    if t == "Vector3"   then return string.format("Vector3(%g, %g, %g)", v.X, v.Y, v.Z) end
    if t == "Vector2"   then return string.format("Vector2(%g, %g)", v.X, v.Y) end
    if t == "CFrame"    then return string.format("CFrame(%g, %g, %g)", v.X, v.Y, v.Z) end
    if t == "Color3"    then return string.format("Color3(%g, %g, %g)", v.R, v.G, v.B) end
    if t == "UDim2"     then return string.format("UDim2(%g,%g,%g,%g)", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset) end
    if t == "table"     then
        local parts = {}
        for k, val in pairs(v) do
            table.insert(parts, "[" .. safeToString(k) .. "] = " .. serializeArg(val))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return "[" .. t .. "] " .. safeToString(v)
end

local function copyToClipboard(text)
    if setclipboard then
        pcall(setclipboard, text)
        return true
    elseif syn and syn.clipboard then
        pcall(syn.clipboard.set, text)
        return true
    end
    return false
end

local function getScriptSource(scr)
    -- Tenta obter source via decompiler do executor
    if decompile then
        local ok, src = pcall(decompile, scr)
        if ok and type(src) == "string" and #src > 0 then
            return src
        end
    end
    if getscriptbytecode then
        local ok, bc = pcall(getscriptbytecode, scr)
        if ok and type(bc) == "string" and #bc > 0 then
            return "[Bytecode apenas — sem decompilador disponível]"
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════
--  REMOTE SPY — HOOK
-- ═══════════════════════════════════════════════

local remoteLog = {}   -- { time, remotePath, remoteType, args, response }
local _origFireServer, _origInvokeServer

local function hookRemotes()
    -- FireServer
    if hookfunction and pcall(function()
        local mt = getrawmetatable and getrawmetatable(game)
        return mt ~= nil
    end) then
        -- Método via metamethod __namecall (compatível com Delta/Synapse)
        local mt = getrawmetatable(game)
        if mt then
            local oldNamecall = mt.__namecall
            local setOk = pcall(setreadonly, mt, false)

            mt.__namecall = newcclosure(function(self, ...)
                local args = {...}
                local method = getnamecallmethod and getnamecallmethod() or ""

                if (method == "FireServer" or method == "InvokeServer") and self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                    local path = "?"
                    pcall(function() path = self:GetFullName() end)
                    local serializedArgs = {}
                    for _, a in ipairs(args) do
                        table.insert(serializedArgs, serializeArg(a))
                    end
                    table.insert(remoteLog, {
                        time       = os.clock(),
                        remotePath = path,
                        remoteType = method,
                        args       = serializedArgs,
                        response   = nil
                    })
                end

                return oldNamecall(self, ...)
            end)

            if setOk then pcall(setreadonly, mt, true) end
        end
    end
end

pcall(hookRemotes)

-- Fallback: monitorar RemoteEvents existentes sem hook profundo
local function monitorRemoteEvents()
    local function watchRemote(remote)
        if remote:IsA("RemoteEvent") then
            -- Não podemos interceptar FireServer do lado do cliente
            -- sem hook; registramos OnClientEvent como proxy
            pcall(function()
                remote.OnClientEvent:Connect(function(...)
                    local args = {...}
                    local serializedArgs = {}
                    for _, a in ipairs(args) do
                        table.insert(serializedArgs, serializeArg(a))
                    end
                    table.insert(remoteLog, {
                        time       = os.clock(),
                        remotePath = remote:GetFullName(),
                        remoteType = "OnClientEvent (servidor → cliente)",
                        args       = serializedArgs,
                        response   = nil
                    })
                end)
            end)
        end
    end

    local function scanDescendants(parent)
        pcall(function()
            for _, v in ipairs(parent:GetDescendants()) do
                watchRemote(v)
            end
            parent.DescendantAdded:Connect(function(v)
                watchRemote(v)
            end)
        end)
    end

    pcall(function() scanDescendants(ReplicatedStorage) end)
    pcall(function() scanDescendants(game:GetService("Workspace")) end)
end

pcall(monitorRemoteEvents)

-- ═══════════════════════════════════════════════
--  SNAPSHOT DO ESTADO DO JOGO (pré/pós clique)
-- ═══════════════════════════════════════════════

local function snapshotGUIs()
    local snap = {}
    pcall(function()
        for _, gui in ipairs(PlayerGui:GetDescendants()) do
            if gui:IsA("ScreenGui") or gui:IsA("Frame") or gui:IsA("ScrollingFrame") then
                snap[gui:GetFullName()] = gui.Visible
            end
        end
    end)
    return snap
end

local function snapshotSounds()
    local snap = {}
    pcall(function()
        for _, s in ipairs(game:GetDescendants()) do
            if s:IsA("Sound") then
                snap[s:GetFullName()] = { playing = s.IsPlaying, timePos = s.TimePosition }
            end
        end
    end)
    return snap
end

local function snapshotValues()
    local snap = {}
    pcall(function()
        for _, v in ipairs(game:GetDescendants()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue")
            or v:IsA("BoolValue") or v:IsA("Vector3Value") or v:IsA("Color3Value") then
                snap[v:GetFullName()] = v.Value
            end
        end
    end)
    return snap
end

local function snapshotHumanoid()
    local snap = {}
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                snap.WalkSpeed    = hum.WalkSpeed
                snap.JumpPower    = hum.JumpPower
                snap.Health       = hum.Health
                snap.MaxHealth    = hum.MaxHealth
                snap.HipHeight    = hum.HipHeight
                snap.StateType    = tostring(hum:GetState())
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                snap.Position = hrp.Position
            end
        end
    end)
    return snap
end

local function snapshotCamera()
    local snap = {}
    pcall(function()
        local cam = workspace.CurrentCamera
        snap.CameraType    = tostring(cam.CameraType)
        snap.FieldOfView   = cam.FieldOfView
        snap.Focus         = cam.Focus.Position
        snap.CFrame        = cam.CFrame.Position
        snap.Subject       = cam.CameraSubject and cam.CameraSubject:GetFullName() or "nil"
    end)
    return snap
end

local function snapshotAnimations()
    local snap = {}
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local animator = hum:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        table.insert(snap, { name = track.Name, animId = track.Animation.AnimationId, speed = track.Speed })
                    end
                end
            end
        end
    end)
    return snap
end

local function snapshotDescendantCount()
    local count = 0
    pcall(function()
        for _ in ipairs(PlayerGui:GetDescendants()) do count = count + 1 end
    end)
    return count
end

-- ═══════════════════════════════════════════════
--  COMPARAÇÃO DE SNAPSHOTS
-- ═══════════════════════════════════════════════

local function diffGUIs(before, after)
    local changes = {}
    for path, wasVisible in pairs(before) do
        local nowVisible = after[path]
        if nowVisible ~= nil and nowVisible ~= wasVisible then
            table.insert(changes, string.format("  %s → %s (era %s)",
                path,
                nowVisible and "VISÍVEL" or "OCULTO",
                wasVisible and "VISÍVEL" or "OCULTO"
            ))
        end
    end
    for path, nowVisible in pairs(after) do
        if before[path] == nil then
            table.insert(changes, string.format("  %s → CRIADA (visível: %s)", path, tostring(nowVisible)))
        end
    end
    return changes
end

local function diffSounds(before, after)
    local changes = {}
    for path, bState in pairs(before) do
        local aState = after[path]
        if aState and not bState.playing and aState.playing then
            table.insert(changes, "  Som iniciado: " .. path)
        end
    end
    for path, aState in pairs(after) do
        if before[path] == nil and aState.playing then
            table.insert(changes, "  Novo som tocando: " .. path)
        end
    end
    return changes
end

local function diffValues(before, after)
    local changes = {}
    for path, bVal in pairs(before) do
        local aVal = after[path]
        if aVal ~= nil and tostring(aVal) ~= tostring(bVal) then
            table.insert(changes, string.format("  %s: %s → %s", path, safeToString(bVal), safeToString(aVal)))
        end
    end
    return changes
end

local function diffHumanoid(before, after)
    local changes = {}
    for k, bVal in pairs(before) do
        local aVal = after[k]
        if aVal ~= nil and tostring(aVal) ~= tostring(bVal) then
            table.insert(changes, string.format("  Humanoid.%s: %s → %s", k, safeToString(bVal), safeToString(aVal)))
        end
    end
    return changes
end

local function diffCamera(before, after)
    local changes = {}
    for k, bVal in pairs(before) do
        local aVal = after[k]
        if aVal ~= nil and tostring(aVal) ~= tostring(bVal) then
            table.insert(changes, string.format("  Câmera.%s: %s → %s", k, safeToString(bVal), safeToString(aVal)))
        end
    end
    return changes
end

local function diffAnimations(before, after)
    local changes = {}
    local beforeIds = {}
    for _, t in ipairs(before) do beforeIds[t.animId] = t end
    for _, t in ipairs(after) do
        if not beforeIds[t.animId] then
            table.insert(changes, string.format("  Nova animação: %s (ID: %s)", t.name, t.animId))
        end
    end
    return changes
end

-- ═══════════════════════════════════════════════
--  DETECÇÃO DE SCRIPTS RELACIONADOS AO BOTÃO
-- ═══════════════════════════════════════════════

local function findRelatedScripts(button)
    local results = {}
    pcall(function()
        -- Scripts no mesmo pai ou ancestral próximo
        local targets = { button.Parent, button.Parent and button.Parent.Parent }
        for _, target in ipairs(targets) do
            if target then
                for _, child in ipairs(target:GetDescendants()) do
                    if child:IsA("LocalScript") or child:IsA("ModuleScript") then
                        local info = {
                            path     = child:GetFullName(),
                            class    = child.ClassName,
                            source   = nil,
                            hasSource = false
                        }
                        local src = getScriptSource(child)
                        if src then
                            info.source    = src
                            info.hasSource = true
                        end
                        table.insert(results, info)
                    end
                end
            end
        end
    end)
    return results
end

-- ═══════════════════════════════════════════════
--  RELATÓRIO COMPLETO
-- ═══════════════════════════════════════════════

local function buildReport(data)
    local lines = {}
    local function add(s) table.insert(lines, s) end

    add("══════════════════════════════════════")
    add("        BUTTON SPY — RELATÓRIO")
    add("══════════════════════════════════════")
    add("")
    add("[ BOTÃO DETECTADO ]")
    add("  Nome   : " .. data.name)
    add("  Tipo   : " .. data.class)
    add("  Caminho: " .. data.path)
    add("  Texto  : " .. (data.text ~= "" and data.text or "—"))
    add("  Visível: " .. tostring(data.visible))
    add("  Tamanho: " .. data.size)
    add("  Posição: " .. data.position)
    add("")

    -- Ações detectadas
    local hasActions = false
    add("[ AÇÕES DETECTADAS ]")

    if #data.guiChanges > 0 then
        hasActions = true
        add("  GUIs alteradas:")
        for _, l in ipairs(data.guiChanges) do add(l) end
    end
    if #data.soundChanges > 0 then
        hasActions = true
        add("  Sons:")
        for _, l in ipairs(data.soundChanges) do add(l) end
    end
    if #data.valueChanges > 0 then
        hasActions = true
        add("  Valores alterados:")
        for _, l in ipairs(data.valueChanges) do add(l) end
    end
    if #data.humChanges > 0 then
        hasActions = true
        add("  Humanoid:")
        for _, l in ipairs(data.humChanges) do add(l) end
    end
    if #data.camChanges > 0 then
        hasActions = true
        add("  Câmera:")
        for _, l in ipairs(data.camChanges) do add(l) end
    end
    if #data.animChanges > 0 then
        hasActions = true
        add("  Animações:")
        for _, l in ipairs(data.animChanges) do add(l) end
    end
    if data.descendantDiff ~= 0 then
        hasActions = true
        local label = data.descendantDiff > 0 and "criados" or "removidos"
        add(string.format("  Objetos %s: %d elemento(s)", label, math.abs(data.descendantDiff)))
    end

    if not hasActions then
        add("  Nenhuma mudança detectada no cliente.")
    end
    add("")

    -- Remotes
    add("[ REMOTES DETECTADOS ]")
    if #data.remotes > 0 then
        for _, r in ipairs(data.remotes) do
            add("  Tipo   : " .. r.remoteType)
            add("  Caminho: " .. r.remotePath)
            if #r.args > 0 then
                add("  Args   :")
                for i, a in ipairs(r.args) do
                    add("    [" .. i .. "] " .. a)
                end
            else
                add("  Args   : (nenhum)")
            end
            add("  ──────────────────────────────")
        end
    else
        add("  Nenhum remote interceptado.")
        add("  Nota: intercepção completa requer hook __namecall.")
    end
    add("")

    -- Scripts
    add("[ SCRIPTS DETECTADOS ]")
    if #data.scripts > 0 then
        for _, s in ipairs(data.scripts) do
            add("  " .. s.class .. ": " .. s.path)
            if s.hasSource then
                add("  Código: DISPONÍVEL")
            else
                add("  Código: Indisponível. Protegido ou executado no servidor.")
            end
            add("  ──────────────────────────────")
        end
    else
        add("  Nenhum LocalScript/ModuleScript encontrado próximo ao botão.")
    end
    add("")
    add("══════════════════════════════════════")
    add(string.format("  Capturado em: %.2f s pós-clique", data.captureTime or 0))
    add("══════════════════════════════════════")

    return table.concat(lines, "\n")
end

-- ═══════════════════════════════════════════════
--  GUI — INTERFACE PRINCIPAL
-- ═══════════════════════════════════════════════

-- Remove instância anterior se houver
pcall(function()
    local old = CoreGui:FindFirstChild("ButtonSpyHub")
    if old then old:Destroy() end
end)
pcall(function()
    local old = PlayerGui:FindFirstChild("ButtonSpyHub")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "ButtonSpyHub"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder    = 999

-- Tenta colocar no CoreGui (evita reset); fallback para PlayerGui
local guiParent = CoreGui
if not pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = PlayerGui
end

-- Paleta de cores
local C = {
    bg       = Color3.fromRGB(8,   10,  18),
    panel    = Color3.fromRGB(12,  15,  28),
    border   = Color3.fromRGB(0,   200, 255),
    accent   = Color3.fromRGB(130, 0,   255),
    red      = Color3.fromRGB(220, 30,  80),
    text     = Color3.fromRGB(210, 220, 240),
    dim      = Color3.fromRGB(100, 115, 145),
    success  = Color3.fromRGB(0,   220, 140),
    warning  = Color3.fromRGB(255, 180, 0),
    header   = Color3.fromRGB(0,   180, 255),
}

-- Helpers de criação de UI
local function newInst(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

local function makeCorner(radius, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function makeStroke(thickness, color, parent, transparency)
    local s = Instance.new("UIStroke")
    s.Thickness    = thickness
    s.Color        = color
    s.Transparency = transparency or 0
    s.Parent       = parent
    return s
end

local function makeGradient(c0, c1, rot, parent)
    local g = Instance.new("UIGradient")
    g.Color    = ColorSequence.new(c0, c1)
    g.Rotation = rot
    g.Parent   = parent
    return g
end

-- ── JANELA PRINCIPAL ──────────────────────────
local WINDOW_W = math.min(340, workspace.CurrentCamera.ViewportSize.X - 20)
local WINDOW_H = math.min(520, workspace.CurrentCamera.ViewportSize.Y - 40)

local MainFrame = newInst("Frame", {
    Name            = "MainFrame",
    Size            = UDim2.new(0, WINDOW_W, 0, WINDOW_H),
    Position        = UDim2.new(0, 10, 0, 40),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Parent          = ScreenGui,
    ClipsDescendants = true,
})
makeCorner(10, MainFrame)
makeStroke(1.5, C.border, MainFrame, 0.3)

-- Gradiente de fundo
makeGradient(
    Color3.fromRGB(8, 10, 22),
    Color3.fromRGB(14, 8, 30),
    135,
    MainFrame
)

-- ── BARRA DE TÍTULO ───────────────────────────
local TitleBar = newInst("Frame", {
    Name             = "TitleBar",
    Size             = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = C.panel,
    BorderSizePixel  = 0,
    Parent           = MainFrame,
})
makeCorner(10, TitleBar)
makeGradient(
    Color3.fromRGB(0, 160, 220),
    Color3.fromRGB(100, 0, 200),
    90,
    TitleBar
)

local TitleLabel = newInst("TextLabel", {
    Text             = " BUTTON SPY  v2.0",
    Size             = UDim2.new(1, -80, 1, 0),
    Position         = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    TextColor3       = Color3.fromRGB(255, 255, 255),
    TextSize         = 13,
    Font             = Enum.Font.GothamBold,
    TextXAlignment   = Enum.TextXAlignment.Left,
    Parent           = TitleBar,
})

-- Badge status
local StatusBadge = newInst("TextLabel", {
    Text             = "● ATIVO",
    Size             = UDim2.new(0, 60, 0, 20),
    Position         = UDim2.new(1, -130, 0.5, -10),
    BackgroundColor3 = Color3.fromRGB(0, 200, 100),
    TextColor3       = Color3.fromRGB(0, 0, 0),
    TextSize         = 9,
    Font             = Enum.Font.GothamBold,
    TextXAlignment   = Enum.TextXAlignment.Center,
    Parent           = TitleBar,
})
makeCorner(10, StatusBadge)

-- Botão minimizar
local MinBtn = newInst("TextButton", {
    Text             = "—",
    Size             = UDim2.new(0, 28, 0, 22),
    Position         = UDim2.new(1, -60, 0.5, -11),
    BackgroundColor3 = Color3.fromRGB(30, 35, 55),
    TextColor3       = C.text,
    TextSize         = 14,
    Font             = Enum.Font.GothamBold,
    BorderSizePixel  = 0,
    Parent           = TitleBar,
})
makeCorner(6, MinBtn)

-- Botão fechar
local CloseBtn = newInst("TextButton", {
    Text             = "✕",
    Size             = UDim2.new(0, 28, 0, 22),
    Position         = UDim2.new(1, -28, 0.5, -11),
    BackgroundColor3 = C.red,
    TextColor3       = Color3.fromRGB(255, 255, 255),
    TextSize         = 12,
    Font             = Enum.Font.GothamBold,
    BorderSizePixel  = 0,
    Parent           = TitleBar,
})
makeCorner(6, CloseBtn)

-- ── CONTEÚDO (abaixo do título) ───────────────
local ContentFrame = newInst("Frame", {
    Name             = "ContentFrame",
    Size             = UDim2.new(1, 0, 1, -36),
    Position         = UDim2.new(0, 0, 0, 36),
    BackgroundTransparency = 1,
    Parent           = MainFrame,
})

-- ── PAINEL INFO DO BOTÃO ──────────────────────
local InfoPanel = newInst("Frame", {
    Name             = "InfoPanel",
    Size             = UDim2.new(1, -16, 0, 90),
    Position         = UDim2.new(0, 8, 0, 8),
    BackgroundColor3 = C.panel,
    BorderSizePixel  = 0,
    Parent           = ContentFrame,
})
makeCorner(8, InfoPanel)
makeStroke(1, C.accent, InfoPanel, 0.5)

local InfoTitle = newInst("TextLabel", {
    Text             = "AGUARDANDO CLIQUE...",
    Size             = UDim2.new(1, -10, 0, 18),
    Position         = UDim2.new(0, 8, 0, 6),
    BackgroundTransparency = 1,
    TextColor3       = C.header,
    TextSize         = 11,
    Font             = Enum.Font.GothamBold,
    TextXAlignment   = Enum.TextXAlignment.Left,
    Parent           = InfoPanel,
})

local InfoBody = newInst("TextLabel", {
    Text             = "Clique em qualquer botão do jogo\npara iniciar a análise.",
    Size             = UDim2.new(1, -10, 1, -28),
    Position         = UDim2.new(0, 8, 0, 26),
    BackgroundTransparency = 1,
    TextColor3       = C.dim,
    TextSize         = 10,
    Font             = Enum.Font.Gotham,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Top,
    TextWrapped      = true,
    Parent           = InfoPanel,
})

-- ── BARRA DE ABAS ─────────────────────────────
local TabBar = newInst("Frame", {
    Name             = "TabBar",
    Size             = UDim2.new(1, -16, 0, 30),
    Position         = UDim2.new(0, 8, 0, 106),
    BackgroundTransparency = 1,
    Parent           = ContentFrame,
})

local tabNames = {"RELATÓRIO", "REMOTES", "SCRIPTS"}
local tabs = {}
local activeTab = "RELATÓRIO"

for i, name in ipairs(tabNames) do
    local btn = newInst("TextButton", {
        Text             = name,
        Size             = UDim2.new(0, (WINDOW_W - 32) / 3 - 4, 1, 0),
        Position         = UDim2.new(0, ((WINDOW_W - 32) / 3) * (i - 1) + (i-1)*2, 0, 0),
        BackgroundColor3 = i == 1 and C.border or Color3.fromRGB(20, 25, 45),
        TextColor3       = i == 1 and Color3.fromRGB(0,0,0) or C.dim,
        TextSize         = 9,
        Font             = Enum.Font.GothamBold,
        BorderSizePixel  = 0,
        Parent           = TabBar,
    })
    makeCorner(6, btn)
    tabs[name] = btn
end

-- ── ÁREA DE LOGS (ScrollingFrame) ─────────────
local LogScroll = newInst("ScrollingFrame", {
    Name                  = "LogScroll",
    Size                  = UDim2.new(1, -16, 1, -200),
    Position              = UDim2.new(0, 8, 0, 144),
    BackgroundColor3      = Color3.fromRGB(5, 8, 16),
    BorderSizePixel       = 0,
    ScrollBarThickness    = 4,
    ScrollBarImageColor3  = C.accent,
    CanvasSize            = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize   = Enum.AutomaticSize.Y,
    Parent                = ContentFrame,
})
makeCorner(8, LogScroll)
makeStroke(1, Color3.fromRGB(30, 35, 60), LogScroll, 0)

local LogList = newInst("UIListLayout", {
    Padding         = UDim.new(0, 2),
    SortOrder       = Enum.SortOrder.LayoutOrder,
    Parent          = LogScroll,
})

newInst("UIPadding", {
    PaddingLeft   = UDim.new(0, 6),
    PaddingRight  = UDim.new(0, 6),
    PaddingTop    = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, 6),
    Parent        = LogScroll,
})

-- ── BOTÕES DE AÇÃO INFERIORES ─────────────────
local BtnPanel = newInst("Frame", {
    Name             = "BtnPanel",
    Size             = UDim2.new(1, -16, 0, 52),
    Position         = UDim2.new(0, 8, 1, -58),
    BackgroundTransparency = 1,
    Parent           = ContentFrame,
})

local btnDefs = {
    { label = "Copiar Nome",    key = "name"     },
    { label = "Copiar Caminho", key = "path"     },
    { label = "Copiar Remote",  key = "remote"   },
    { label = "Copiar Args",    key = "args"     },
    { label = "Copiar Código",  key = "code"     },
    { label = "Copiar Tudo",    key = "all"      },
}

local copyBtns = {}
local btnW = (WINDOW_W - 32 - 10) / 3

for i, def in ipairs(btnDefs) do
    local col = (i - 1) % 3
    local row = math.floor((i - 1) / 3)
    local btn = newInst("TextButton", {
        Text             = def.label,
        Size             = UDim2.new(0, btnW, 0, 22),
        Position         = UDim2.new(0, col * (btnW + 5), 0, row * 26),
        BackgroundColor3 = Color3.fromRGB(18, 22, 40),
        TextColor3       = C.dim,
        TextSize         = 9,
        Font             = Enum.Font.Gotham,
        BorderSizePixel  = 0,
        Parent           = BtnPanel,
    })
    makeCorner(5, btn)
    makeStroke(1, Color3.fromRGB(40, 50, 80), btn, 0)
    copyBtns[def.key] = btn
end

-- ═══════════════════════════════════════════════
--  ESTADO ATUAL DO RELATÓRIO
-- ═══════════════════════════════════════════════

local currentReport = {
    name     = "",
    path     = "",
    text     = "",
    class    = "",
    visible  = false,
    size     = "",
    position = "",
    guiChanges   = {},
    soundChanges = {},
    valueChanges = {},
    humChanges   = {},
    camChanges   = {},
    animChanges  = {},
    descendantDiff = 0,
    remotes  = {},
    scripts  = {},
    captureTime = 0,
    fullReport  = "",
    sourceCode  = "",
}

local logsByTab = {
    ["RELATÓRIO"] = {},
    ["REMOTES"]   = {},
    ["SCRIPTS"]   = {},
}

-- ── FUNÇÕES DA GUI ────────────────────────────

local function clearLogs()
    for _, child in ipairs(LogScroll:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("Frame") then
            child:Destroy()
        end
    end
end

local function addLogLine(text, color, bold, layoutOrder)
    local lbl = newInst("TextLabel", {
        Text             = text,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        TextColor3       = color or C.text,
        TextSize         = 10,
        Font             = bold and Enum.Font.GothamBold or Enum.Font.Code,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        LayoutOrder      = layoutOrder or 0,
        Parent           = LogScroll,
    })
    return lbl
end

local logOrder = 0
local function addLog(tab, text, color, bold)
    logOrder = logOrder + 1
    table.insert(logsByTab[tab], { text = text, color = color, bold = bold, order = logOrder })
    if activeTab == tab then
        addLogLine(text, color, bold, logOrder)
        -- Auto-scroll
        task.defer(function()
            LogScroll.CanvasPosition = Vector2.new(0, LogScroll.AbsoluteCanvasSize.Y)
        end)
    end
end

local function renderTab(name)
    activeTab = name
    clearLogs()
    logOrder = 0
    -- Atualizar estilo dos tabs
    for n, btn in pairs(tabs) do
        if n == name then
            btn.BackgroundColor3 = C.border
            btn.TextColor3       = Color3.fromRGB(0, 0, 0)
        else
            btn.BackgroundColor3 = Color3.fromRGB(20, 25, 45)
            btn.TextColor3       = C.dim
        end
    end
    -- Renderizar logs da aba
    for _, entry in ipairs(logsByTab[name]) do
        addLogLine(entry.text, entry.color, entry.bold, entry.order)
    end
    task.defer(function()
        LogScroll.CanvasPosition = Vector2.new(0, LogScroll.AbsoluteCanvasSize.Y)
    end)
end

-- Conexão das abas
for _, name in ipairs(tabNames) do
    tabs[name].MouseButton1Click:Connect(function()
        renderTab(name)
    end)
end

local function flash(label, originalText, flashText, flashColor)
    label.Text = flashText
    local origColor = label.TextColor3
    label.TextColor3 = flashColor
    task.delay(1.2, function()
        if label and label.Parent then
            label.Text = originalText
            label.TextColor3 = origColor
        end
    end)
end

-- ── COPY BUTTONS ──────────────────────────────

copyBtns["name"].MouseButton1Click:Connect(function()
    if currentReport.name == "" then return end
    if copyToClipboard(currentReport.name) then
        flash(copyBtns["name"], "Copiar Nome", "✓ Copiado!", C.success)
    end
end)

copyBtns["path"].MouseButton1Click:Connect(function()
    if currentReport.path == "" then return end
    if copyToClipboard(currentReport.path) then
        flash(copyBtns["path"], "Copiar Caminho", "✓ Copiado!", C.success)
    end
end)

copyBtns["remote"].MouseButton1Click:Connect(function()
    if #currentReport.remotes == 0 then return end
    local paths = {}
    for _, r in ipairs(currentReport.remotes) do
        table.insert(paths, r.remotePath .. " [" .. r.remoteType .. "]")
    end
    if copyToClipboard(table.concat(paths, "\n")) then
        flash(copyBtns["remote"], "Copiar Remote", "✓ Copiado!", C.success)
    end
end)

copyBtns["args"].MouseButton1Click:Connect(function()
    if #currentReport.remotes == 0 then return end
    local lines = {}
    for _, r in ipairs(currentReport.remotes) do
        table.insert(lines, r.remotePath .. ":")
        for i, a in ipairs(r.args) do
            table.insert(lines, "  [" .. i .. "] " .. a)
        end
    end
    if copyToClipboard(table.concat(lines, "\n")) then
        flash(copyBtns["args"], "Copiar Args", "✓ Copiado!", C.success)
    end
end)

copyBtns["code"].MouseButton1Click:Connect(function()
    if currentReport.sourceCode == "" then return end
    if copyToClipboard(currentReport.sourceCode) then
        flash(copyBtns["code"], "Copiar Código", "✓ Copiado!", C.success)
    end
end)

copyBtns["all"].MouseButton1Click:Connect(function()
    if currentReport.fullReport == "" then return end
    if copyToClipboard(currentReport.fullReport) then
        flash(copyBtns["all"], "Copiar Tudo", "✓ Copiado!", C.success)
    end
end)

-- ── MINIMIZAR / FECHAR ────────────────────────
local minimized = false
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    ContentFrame.Visible = not minimized
    MainFrame.Size = minimized
        and UDim2.new(0, WINDOW_W, 0, 36)
        or  UDim2.new(0, WINDOW_W, 0, WINDOW_H)
    MinBtn.Text = minimized and "□" or "—"
end)

-- ═══════════════════════════════════════════════
--  DRAG (arrastar janela)
-- ═══════════════════════════════════════════════

do
    local dragging, dragStart, startPos = false, nil, nil

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = MainFrame.Position
        end
    end)

    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ═══════════════════════════════════════════════
--  ANÁLISE PÓS-CLIQUE
-- ═══════════════════════════════════════════════

local analyzing = false
local CAPTURE_DURATION = 2.5  -- segundos de monitoramento pós-clique

local function analyzeButton(button)
    if analyzing then return end
    analyzing = true
    StatusBadge.Text             = "● ANALISANDO"
    StatusBadge.BackgroundColor3 = C.warning

    -- Info básica do botão
    local bName, bPath, bText, bClass = "?", "?", "", "?"
    local bVisible, bSize, bPos = false, "?", "?"

    pcall(function() bName    = button.Name end)
    pcall(function() bPath    = button:GetFullName() end)
    pcall(function() bClass   = button.ClassName end)
    pcall(function() bVisible = button.Visible end)
    pcall(function()
        local s = button.Size
        bSize = string.format("{%g,%g},{%g,%g}", s.X.Scale, s.X.Offset, s.Y.Scale, s.Y.Offset)
    end)
    pcall(function()
        local p = button.AbsolutePosition
        bPos = string.format("(%g, %g)", p.X, p.Y)
    end)
    pcall(function()
        if button:IsA("TextButton") then bText = button.Text or "" end
    end)

    -- Atualizar painel de info
    InfoTitle.Text = bClass .. ":  " .. bName
    InfoTitle.TextColor3 = C.header
    InfoBody.Text = string.format(
        "Caminho: %s\nTamanho: %s  |  Posição: %s  |  Visível: %s",
        bPath, bSize, bPos, tostring(bVisible)
    )

    -- Limpar logs
    for k in pairs(logsByTab) do logsByTab[k] = {} end
    clearLogs()
    logOrder = 0

    -- Snapshot pré-clique
    local preRemoteCount = #remoteLog
    local preGUI   = snapshotGUIs()
    local preSound = snapshotSounds()
    local preVal   = snapshotValues()
    local preHum   = snapshotHumanoid()
    local preCam   = snapshotCamera()
    local preAnim  = snapshotAnimations()
    local preDesc  = snapshotDescendantCount()

    addLog("RELATÓRIO", "══ CAPTURANDO POR " .. CAPTURE_DURATION .. "s... ══", C.warning, true)
    renderTab("RELATÓRIO")

    -- Aguardar
    task.wait(CAPTURE_DURATION)

    -- Snapshot pós
    local postGUI   = snapshotGUIs()
    local postSound = snapshotSounds()
    local postVal   = snapshotValues()
    local postHum   = snapshotHumanoid()
    local postCam   = snapshotCamera()
    local postAnim  = snapshotAnimations()
    local postDesc  = snapshotDescendantCount()

    -- Remotes capturados durante a janela
    local capturedRemotes = {}
    for i = preRemoteCount + 1, #remoteLog do
        table.insert(capturedRemotes, remoteLog[i])
    end

    -- Diffs
    local guiCh  = diffGUIs(preGUI, postGUI)
    local sndCh  = diffSounds(preSound, postSound)
    local valCh  = diffValues(preVal, postVal)
    local humCh  = diffHumanoid(preHum, postHum)
    local camCh  = diffCamera(preCam, postCam)
    local animCh = diffAnimations(preAnim, postAnim)
    local descDiff = postDesc - preDesc

    -- Scripts relacionados
    local relScripts = findRelatedScripts(button)

    -- Montar currentReport
    currentReport.name          = bName
    currentReport.path          = bPath
    currentReport.text          = bText
    currentReport.class         = bClass
    currentReport.visible       = bVisible
    currentReport.size          = bSize
    currentReport.position      = bPos
    currentReport.guiChanges    = guiCh
    currentReport.soundChanges  = sndCh
    currentReport.valueChanges  = valCh
    currentReport.humChanges    = humCh
    currentReport.camChanges    = camCh
    currentReport.animChanges   = animCh
    currentReport.descendantDiff = descDiff
    currentReport.remotes       = capturedRemotes
    currentReport.scripts       = relScripts
    currentReport.captureTime   = CAPTURE_DURATION

    -- Source code
    currentReport.sourceCode = ""
    for _, s in ipairs(relScripts) do
        if s.hasSource and s.source then
            currentReport.sourceCode = currentReport.sourceCode .. "-- " .. s.path .. "\n" .. s.source .. "\n\n"
        end
    end

    -- Gerar relatório texto
    currentReport.fullReport = buildReport(currentReport)

    -- ── Popular aba RELATÓRIO ──
    for k in pairs(logsByTab) do logsByTab[k] = {} end

    -- Cabeçalho
    addLog("RELATÓRIO", "══════════════════════════════", C.border, true)
    addLog("RELATÓRIO", "  BOTÃO: " .. bName, C.header, true)
    addLog("RELATÓRIO", "  Tipo: " .. bClass, C.dim, false)
    addLog("RELATÓRIO", "  Caminho: " .. bPath, C.dim, false)
    if bText ~= "" then
        addLog("RELATÓRIO", "  Texto: \"" .. bText .. "\"", C.text, false)
    end
    addLog("RELATÓRIO", "  Visível: " .. tostring(bVisible), C.dim, false)
    addLog("RELATÓRIO", "══════════════════════════════", C.border, true)

    -- Ações
    addLog("RELATÓRIO", "[ AÇÕES DETECTADAS ]", C.accent, true)
    local hasAny = false

    if #guiCh > 0 then
        hasAny = true
        addLog("RELATÓRIO", "  GUIs alteradas:", C.success, true)
        for _, l in ipairs(guiCh) do addLog("RELATÓRIO", l, C.text) end
    end
    if #sndCh > 0 then
        hasAny = true
        addLog("RELATÓRIO", "  Sons:", C.success, true)
        for _, l in ipairs(sndCh) do addLog("RELATÓRIO", l, C.text) end
    end
    if #valCh > 0 then
        hasAny = true
        addLog("RELATÓRIO", "  Valores alterados:", C.success, true)
        for _, l in ipairs(valCh) do addLog("RELATÓRIO", l, C.text) end
    end
    if #humCh > 0 then
        hasAny = true
        addLog("RELATÓRIO", "  Humanoid:", C.warning, true)
        for _, l in ipairs(humCh) do addLog("RELATÓRIO", l, C.text) end
    end
    if #camCh > 0 then
        hasAny = true
        addLog("RELATÓRIO", "  Câmera:", C.warning, true)
        for _, l in ipairs(camCh) do addLog("RELATÓRIO", l, C.text) end
    end
    if #animCh > 0 then
        hasAny = true
        addLog("RELATÓRIO", "  Animações:", C.success, true)
        for _, l in ipairs(animCh) do addLog("RELATÓRIO", l, C.text) end
    end
    if descDiff ~= 0 then
        hasAny = true
        local lbl = descDiff > 0 and "criados" or "removidos"
        addLog("RELATÓRIO",
            string.format("  Objetos %s: %d", lbl, math.abs(descDiff)),
            descDiff > 0 and C.success or C.red, true
        )
    end

    if not hasAny then
        addLog("RELATÓRIO", "  Nenhuma mudança detectada.", C.dim)
    end

    -- ── Popular aba REMOTES ──
    addLog("REMOTES", "══════════════════════════════", C.border, true)
    addLog("REMOTES", "  REMOTES CAPTURADOS: " .. #capturedRemotes, C.header, true)
    addLog("REMOTES", "══════════════════════════════", C.border, true)

    if #capturedRemotes > 0 then
        for i, r in ipairs(capturedRemotes) do
            addLog("REMOTES", string.format("[%d] %s", i, r.remoteType), C.accent, true)
            addLog("REMOTES", "  Caminho: " .. r.remotePath, C.text)
            if #r.args > 0 then
                addLog("REMOTES", "  Argumentos:", C.warning, true)
                for j, a in ipairs(r.args) do
                    addLog("REMOTES", string.format("    [%d] %s", j, a), C.text)
                end
            else
                addLog("REMOTES", "  Args: (nenhum)", C.dim)
            end
            addLog("REMOTES", "  ──────────────────────", C.border)
        end
    else
        addLog("REMOTES", "  Nenhum remote interceptado nesta janela.", C.dim)
        addLog("REMOTES", "", C.dim)
        addLog("REMOTES", "  NOTA: intercepção total de FireServer requer", C.dim)
        addLog("REMOTES", "  hook __namecall (Synapse X / Fluxus / KRNL).", C.dim)
        addLog("REMOTES", "  OnClientEvent do servidor → cliente é monitorado.", C.dim)
    end

    -- ── Popular aba SCRIPTS ──
    addLog("SCRIPTS", "══════════════════════════════", C.border, true)
    addLog("SCRIPTS", "  SCRIPTS RELACIONADOS: " .. #relScripts, C.header, true)
    addLog("SCRIPTS", "══════════════════════════════", C.border, true)

    if #relScripts > 0 then
        for i, s in ipairs(relScripts) do
            addLog("SCRIPTS", string.format("[%d] %s", i, s.class), C.accent, true)
            addLog("SCRIPTS", "  Caminho: " .. s.path, C.text)
            if s.hasSource then
                addLog("SCRIPTS", "  Código: DISPONÍVEL", C.success, true)
                addLog("SCRIPTS", "  (use 'Copiar Código' para exportar)", C.dim)
                -- Preview das primeiras linhas
                local lines = {}
                for line in s.source:gmatch("[^\n]+") do
                    table.insert(lines, line)
                    if #lines >= 8 then break end
                end
                addLog("SCRIPTS", "  -- Preview --", C.dim)
                for _, line in ipairs(lines) do
                    addLog("SCRIPTS", "  " .. line, Color3.fromRGB(150, 220, 150))
                end
                if #lines == 8 then
                    addLog("SCRIPTS", "  ... (copiar para ver tudo)", C.dim)
                end
            else
                addLog("SCRIPTS", "  Código: INDISPONÍVEL", C.red, true)
                addLog("SCRIPTS", "  A lógica está protegida ou no servidor.", C.dim)
            end
            addLog("SCRIPTS", "  ──────────────────────", C.border)
        end
    else
        addLog("SCRIPTS", "  Nenhum LocalScript/ModuleScript encontrado", C.dim)
        addLog("SCRIPTS", "  próximo ao botão clicado.", C.dim)
    end

    -- Renderizar aba ativa
    renderTab(activeTab)

    -- Status final
    StatusBadge.Text             = "● ATIVO"
    StatusBadge.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    analyzing = false
end

-- ═══════════════════════════════════════════════
--  DETECTOR DE CLIQUES EM BOTÕES DO JOGO
-- ═══════════════════════════════════════════════

local hookedButtons = {}

local function hookButton(btn)
    if hookedButtons[btn] then return end
    hookedButtons[btn] = true

    btn.MouseButton1Click:Connect(function()
        -- Ignorar botões da nossa própria GUI
        local function isOurGui(inst)
            local cur = inst
            while cur do
                if cur == ScreenGui then return true end
                cur = cur.Parent
            end
            return false
        end
        if isOurGui(btn) then return end

        task.spawn(analyzeButton, btn)
    end)
end

local function scanForButtons(parent)
    pcall(function()
        for _, desc in ipairs(parent:GetDescendants()) do
            if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                hookButton(desc)
            end
        end
        parent.DescendantAdded:Connect(function(inst)
            task.defer(function()
                if (inst:IsA("TextButton") or inst:IsA("ImageButton")) then
                    hookButton(inst)
                end
            end)
        end)
    end)
end

-- Escanear PlayerGui
scanForButtons(PlayerGui)

-- Também escanear quando o character carrega (GUIs podem recriar)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    scanForButtons(PlayerGui)
end)

-- ── SCAN PERIÓDICO (para GUIs dinâmicas) ──────
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        task.wait(3)
        pcall(function()
            for _, desc in ipairs(PlayerGui:GetDescendants()) do
                if (desc:IsA("TextButton") or desc:IsA("ImageButton"))
                and not hookedButtons[desc] then
                    hookButton(desc)
                end
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════
--  LOG INICIAL
-- ═══════════════════════════════════════════════

addLog("RELATÓRIO", "  BUTTON SPY v2.0 — CoiledTom Hub", C.border, true)
addLog("RELATÓRIO", "  Clique em qualquer botão do jogo.", C.dim)
addLog("RELATÓRIO", "  A análise começa automaticamente.", C.dim)
addLog("RELATÓRIO", "  Duração da captura: " .. CAPTURE_DURATION .. "s", C.dim)
addLog("RELATÓRIO", "══════════════════════════════", C.border, true)

addLog("REMOTES", "  Aguardando clique em botão...", C.dim)
addLog("SCRIPTS", "  Aguardando clique em botão...", C.dim)

renderTab("RELATÓRIO")

print("[ButtonSpy] Carregado com sucesso — CoiledTom Hub")
