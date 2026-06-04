--[[
    ╔══════════════════════════════════════════════════════════╗
    ║          REMOTEEVENT ANALYZER — CoiledTom Hub            ║
    ║         Ferramenta de análise e envio de RemoteEvents    ║
    ╚══════════════════════════════════════════════════════════╝

    MÓDULOS:
        1. Configurações & Constantes
        2. Utilitários
        3. Scanner de RemoteEvents
        4. Sistema de Análise de Argumentos
        5. Sistema de UI (Interface Gráfica)
        6. Sistema de Controles Dinâmicos
        7. Lógica de Envio
        8. Inicialização
]]

-- ════════════════════════════════════════════════════════════
-- [1] CONFIGURAÇÕES & CONSTANTES
-- ════════════════════════════════════════════════════════════

local CFG = {
    -- Janela
    WINDOW_W    = 700,
    WINDOW_H    = 500,
    TITLE       = "RemoteEvent Analyzer",
    VERSION     = "v1.0",

    -- Cores (tema escuro cyberpunk)
    C_BG        = Color3.fromRGB(8,  8,  14),
    C_PANEL     = Color3.fromRGB(14, 14, 24),
    C_SURFACE   = Color3.fromRGB(20, 20, 36),
    C_BORDER    = Color3.fromRGB(40, 40, 70),
    C_ACCENT1   = Color3.fromRGB(90,  60, 255),  -- roxo
    C_ACCENT2   = Color3.fromRGB(220, 40,  90),  -- vermelho
    C_ACCENT3   = Color3.fromRGB(40, 140, 255),  -- azul
    C_TEXT      = Color3.fromRGB(220, 220, 240),
    C_TEXTMUTED = Color3.fromRGB(100, 100, 140),
    C_SUCCESS   = Color3.fromRGB(50,  220, 120),
    C_WARNING   = Color3.fromRGB(255, 180,  40),
    C_ERROR     = Color3.fromRGB(255,  60,  60),

    -- Fontes
    FONT_TITLE  = Enum.Font.GothamBold,
    FONT_BODY   = Enum.Font.Gotham,
    FONT_MONO   = Enum.Font.Code,

    -- Análise
    MAX_HISTORY = 20,   -- máximo de chamadas armazenadas por Remote
    SCAN_DEPTH  = 5,    -- profundidade de busca recursiva
}

-- Ícones por tipo de argumento (unicode)
local TYPE_ICONS = {
    number  = "🔢",
    string  = "📝",
    boolean = "⚡",
    table   = "📦",
    ["nil"] = "∅",
    userdata= "🎯",
    unknown = "❓",
}

-- Enum keywords para detecção automática
local ENUM_KEYWORDS = {
    rarity   = {"Common","Uncommon","Rare","Epic","Legendary","Mythic"},
    rank     = {"Bronze","Silver","Gold","Platinum","Diamond","Master"},
    tier     = {"I","II","III","IV","V","VI"},
    class    = {"Warrior","Mage","Archer","Healer","Rogue","Tank"},
    category = {"Weapon","Armor","Accessory","Consumable","Material"},
    team     = {"Red","Blue","Green","Yellow"},
    status   = {"Active","Inactive","Pending","Disabled","Enabled"},
}

-- Patterns de nome que sugerem tipo numérico
local NUMBER_NAME_PATTERNS = {
    "amount","quantity","count","value","coins","cash","money",
    "gold","gems","level","exp","xp","health","hp","damage",
    "speed","price","score","points","time","duration","id",
    "index","num","number","size","max","min","limit","rate",
}

-- Patterns de nome que sugerem booleano
local BOOL_NAME_PATTERNS = {
    "enabled","active","visible","toggle","is","has","can",
    "allow","show","hide","locked","open","closed","paused",
}

-- ════════════════════════════════════════════════════════════
-- [2] UTILITÁRIOS
-- ════════════════════════════════════════════════════════════

local Util = {}

-- Obtém o caminho completo de uma instância
function Util.getFullPath(instance)
    local parts = {}
    local current = instance
    while current and current ~= game do
        table.insert(parts, 1, current.Name)
        current = current.Parent
    end
    return table.concat(parts, ".")
end

-- Verifica se string contém um dos padrões (case insensitive)
function Util.matchesAny(str, patterns)
    local lower = str:lower()
    for _, p in ipairs(patterns) do
        if lower:find(p:lower(), 1, true) then
            return true
        end
    end
    return false
end

-- Detecta tipo refinado de um valor Lua
function Util.detectType(value)
    local t = typeof(value)
    if t == "number" then
        if value == math.floor(value) then
            return "integer"
        end
        return "float"
    elseif t == "string"  then return "string"
    elseif t == "boolean" then return "boolean"
    elseif t == "table"   then return "table"
    elseif t == "nil"     then return "nil"
    elseif t == "Vector3" then return "Vector3"
    elseif t == "CFrame"  then return "CFrame"
    elseif t == "Color3"  then return "Color3"
    elseif t == "Instance"then return "Instance"
    else return t
    end
end

-- Converte valor para string legível
function Util.valueToString(value)
    local t = typeof(value)
    if t == "nil"     then return "nil"
    elseif t == "string"  then return '"' .. tostring(value) .. '"'
    elseif t == "boolean" then return tostring(value)
    elseif t == "number"  then return tostring(value)
    elseif t == "table"   then
        local ok, encoded = pcall(function()
            local parts = {}
            for k, v in pairs(value) do
                table.insert(parts, tostring(k) .. "=" .. tostring(v))
            end
            return "{" .. table.concat(parts, ", ") .. "}"
        end)
        return ok and encoded or "{...}"
    elseif t == "Instance" then
        return value:GetFullName()
    else
        return tostring(value)
    end
end

-- Trunca string
function Util.truncate(str, max)
    if #str > max then
        return str:sub(1, max - 3) .. "..."
    end
    return str
end

-- Cria animação de tween simples
function Util.tween(instance, props, t, style, dir)
    local TweenService = game:GetService("TweenService")
    local info = TweenInfo.new(
        t or 0.2,
        style or Enum.EasingStyle.Quad,
        dir   or Enum.EasingDirection.Out
    )
    local tw = TweenService:Create(instance, info, props)
    tw:Play()
    return tw
end

-- ════════════════════════════════════════════════════════════
-- [3] SCANNER DE REMOTEEVENTS
-- ════════════════════════════════════════════════════════════

local Scanner = {}

-- Busca recursiva de RemoteEvents no game
function Scanner.findAll()
    local found = {}
    local visited = {}

    local function recurse(parent, depth)
        if depth > CFG.SCAN_DEPTH then return end
        if visited[parent] then return end
        visited[parent] = true

        local ok, children = pcall(function() return parent:GetChildren() end)
        if not ok then return end

        for _, child in ipairs(children) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                table.insert(found, child)
            end
            -- Entra em pastas, modelos e scripts conhecidos
            local cn = child.ClassName
            if cn == "Folder" or cn == "Model" or
               cn == "Script" or cn == "LocalScript" or
               cn == "ModuleScript" or cn == "Configuration" then
                recurse(child, depth + 1)
            end
        end
    end

    -- Raízes de busca
    local roots = {
        game:GetService("ReplicatedStorage"),
        game:GetService("Workspace"),
        game:GetService("Players"),
        game:GetService("ReplicatedFirst"),
    }

    for _, root in ipairs(roots) do
        pcall(recurse, root, 0)
    end

    -- Ordena por nome
    table.sort(found, function(a, b) return a.Name < b.Name end)
    return found
end

-- ════════════════════════════════════════════════════════════
-- [4] SISTEMA DE ANÁLISE DE ARGUMENTOS
-- ════════════════════════════════════════════════════════════

local Analyzer = {}
Analyzer._hooks    = {}  -- [Remote] = connection
Analyzer._data     = {}  -- [Remote] = { calls = {}, argProfiles = {} }

-- Inicia monitoramento de um RemoteEvent
function Analyzer.hook(remote)
    if Analyzer._hooks[remote] then
        Analyzer._hooks[remote]:Disconnect()
    end

    if not Analyzer._data[remote] then
        Analyzer._data[remote] = {
            calls       = {},
            argProfiles = {},
        }
    end

    -- Hook via OnClientEvent (apenas RE, não RF)
    if remote:IsA("RemoteEvent") then
        local ok, conn = pcall(function()
            return remote.OnClientEvent:Connect(function(...)
                local args = {...}
                local entry = {
                    time = os.clock(),
                    args = args,
                }
                local d = Analyzer._data[remote]
                table.insert(d.calls, 1, entry)
                -- Limita histórico
                if #d.calls > CFG.MAX_HISTORY then
                    table.remove(d.calls)
                end
                -- Atualiza perfis de argumentos
                Analyzer._updateProfiles(remote, args)
            end)
        end)
        if ok then
            Analyzer._hooks[remote] = conn
        end
    end
end

-- Remove hook de um Remote
function Analyzer.unhook(remote)
    if Analyzer._hooks[remote] then
        pcall(function() Analyzer._hooks[remote]:Disconnect() end)
        Analyzer._hooks[remote] = nil
    end
end

-- Atualiza perfis de tipo para cada posição de argumento
function Analyzer._updateProfiles(remote, args)
    local d = Analyzer._data[remote]
    for i, val in ipairs(args) do
        if not d.argProfiles[i] then
            d.argProfiles[i] = {
                types   = {},
                values  = {},
                name    = "arg" .. i,
            }
        end
        local p = d.argProfiles[i]
        local t = Util.detectType(val)
        p.types[t] = (p.types[t] or 0) + 1

        -- Guarda valores únicos (strings/numbers)
        local vs = Util.valueToString(val)
        local already = false
        for _, v in ipairs(p.values) do
            if v == vs then already = true break end
        end
        if not already then
            table.insert(p.values, vs)
            if #p.values > 15 then table.remove(p.values, 1) end
        end
    end
end

-- Retorna o tipo dominante de um perfil
function Analyzer.dominantType(profile)
    local best, bestCount = "unknown", 0
    for t, c in pairs(profile.types) do
        if c > bestCount then
            best = t
            bestCount = c
        end
    end
    return best
end

-- Verifica se valores observados batem com uma lista de enum
function Analyzer.detectEnum(profile)
    if #profile.values == 0 then return nil end
    local observed = {}
    for _, v in ipairs(profile.values) do
        -- Remove aspas de strings
        local clean = v:match('^"(.*)"$') or v
        observed[clean:lower()] = clean
    end

    for enumName, enumValues in pairs(ENUM_KEYWORDS) do
        local matches = 0
        for _, ev in ipairs(enumValues) do
            if observed[ev:lower()] then matches += 1 end
        end
        if matches >= 2 then
            return enumName, enumValues
        end
    end
    return nil
end

-- Gera descrição inteligente do controle para um perfil
function Analyzer.suggestControl(profile, argName)
    local dominant = Analyzer.dominantType(profile)
    local name = (argName or profile.name or ""):lower()

    -- Booleano direto
    if dominant == "boolean" then
        return { kind = "boolean", label = argName or profile.name }
    end

    -- Verifica enum pelos valores
    local enumName, enumValues = Analyzer.detectEnum(profile)
    if enumName then
        return { kind = "enum", label = argName or profile.name,
                 options = enumValues, enumName = enumName }
    end

    -- String com poucas opções únicas = dropdown
    if dominant == "string" and #profile.values >= 2 and #profile.values <= 10 then
        local opts = {}
        for _, v in ipairs(profile.values) do
            table.insert(opts, (v:match('^"(.*)"$') or v))
        end
        return { kind = "enum", label = argName or profile.name, options = opts }
    end

    -- Número por tipo detectado
    if dominant == "integer" or dominant == "float" then
        return { kind = "number", label = argName or profile.name }
    end

    -- Número por nome
    if Util.matchesAny(name, NUMBER_NAME_PATTERNS) then
        return { kind = "number", label = argName or profile.name }
    end

    -- Booleano por nome
    if Util.matchesAny(name, BOOL_NAME_PATTERNS) then
        return { kind = "boolean", label = argName or profile.name }
    end

    -- String por padrão
    if dominant == "string" then
        return { kind = "string", label = argName or profile.name }
    end

    -- Tabela
    if dominant == "table" then
        return { kind = "table", label = argName or profile.name }
    end

    -- Fallback string
    return { kind = "string", label = argName or profile.name }
end

-- ════════════════════════════════════════════════════════════
-- [5] SISTEMA DE UI
-- ════════════════════════════════════════════════════════════

local UI = {}
UI._remotes        = {}
UI._filtered       = {}
UI._selected       = nil
UI._controls       = {}   -- controles dinâmicos ativos
UI._logLines       = {}
UI._minimized      = false

-- Referências aos elementos principais
local Gui, MainFrame, ListPanel, AnalysisPanel
local SearchBox, RemoteList, LogFrame, LogLabel
local InfoName, InfoPath, InfoArgCount
local ControlsFrame, ControlsScroll
local StatusBar

-- ── Helpers de criação de instâncias ──────────────────────

local function New(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        inst[k] = v
    end
    if parent then inst.Parent = parent end
    return inst
end

local function Stroke(parent, color, thickness, transparency)
    return New("UIStroke", {
        Color        = color or CFG.C_BORDER,
        Thickness    = thickness or 1,
        Transparency = transparency or 0,
    }, parent)
end

local function Corner(parent, radius)
    return New("UICorner", { CornerRadius = UDim.new(0, radius or 6) }, parent)
end

local function Gradient(parent, c0, c1, rot)
    return New("UIGradient", {
        Color    = ColorSequence.new(c0, c1),
        Rotation = rot or 90,
    }, parent)
end

local function Padding(parent, all, lr, tb)
    if all then lr = all tb = all end
    return New("UIPadding", {
        PaddingLeft   = UDim.new(0, lr or 6),
        PaddingRight  = UDim.new(0, lr or 6),
        PaddingTop    = UDim.new(0, tb or 4),
        PaddingBottom = UDim.new(0, tb or 4),
    }, parent)
end

local function Label(text, size, color, font, parent, props)
    local p = props or {}
    p.Text              = text
    p.TextSize          = size or 13
    p.TextColor3        = color or CFG.C_TEXT
    p.Font              = font or CFG.FONT_BODY
    p.BackgroundTransparency = 1
    p.TextXAlignment    = p.TextXAlignment or Enum.TextXAlignment.Left
    p.Size              = p.Size or UDim2.new(1, 0, 0, size and size + 4 or 18)
    return New("TextLabel", p, parent)
end

local function Button(text, parent, props)
    local p = props or {}
    p.Text              = text
    p.TextSize          = p.TextSize or 12
    p.Font              = p.Font or CFG.FONT_TITLE
    p.BackgroundColor3  = p.BackgroundColor3 or CFG.C_ACCENT1
    p.TextColor3        = p.TextColor3 or Color3.new(1,1,1)
    p.AutoButtonColor   = false
    p.Size              = p.Size or UDim2.new(0, 110, 0, 28)
    local btn = New("TextButton", p, parent)
    Corner(btn, 5)
    -- Hover
    btn.MouseEnter:Connect(function()
        Util.tween(btn, { BackgroundTransparency = 0.25 })
    end)
    btn.MouseLeave:Connect(function()
        Util.tween(btn, { BackgroundTransparency = 0 })
    end)
    return btn
end

-- ── Construção da janela principal ────────────────────────

function UI.build()
    -- Remove GUI existente
    local existing = game.Players.LocalPlayer.PlayerGui:FindFirstChild("REAnalyzerGui")
    if existing then existing:Destroy() end

    -- ScreenGui
    Gui = New("ScreenGui", {
        Name            = "REAnalyzerGui",
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        DisplayOrder    = 999,
    }, game.Players.LocalPlayer.PlayerGui)

    -- Frame principal
    MainFrame = New("Frame", {
        Name            = "MainFrame",
        Size            = UDim2.new(0, CFG.WINDOW_W, 0, CFG.WINDOW_H),
        Position        = UDim2.new(0.5, -CFG.WINDOW_W/2, 0.5, -CFG.WINDOW_H/2),
        BackgroundColor3= CFG.C_BG,
        BorderSizePixel = 0,
        ClipsDescendants= true,
    }, Gui)
    Corner(MainFrame, 10)
    Stroke(MainFrame, CFG.C_ACCENT1, 1.5, 0.3)

    -- Barra de título
    UI._buildTitleBar()

    -- Conteúdo (2 colunas)
    local content = New("Frame", {
        Size            = UDim2.new(1, 0, 1, -40),
        Position        = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
    }, MainFrame)

    -- Coluna esquerda: lista de remotes
    ListPanel = New("Frame", {
        Size            = UDim2.new(0, 220, 1, -50),
        Position        = UDim2.new(0, 8, 0, 8),
        BackgroundColor3= CFG.C_PANEL,
        BorderSizePixel = 0,
    }, content)
    Corner(ListPanel, 8)
    Stroke(ListPanel, CFG.C_BORDER, 1)

    -- Coluna direita: análise
    AnalysisPanel = New("Frame", {
        Size            = UDim2.new(1, -236, 1, -50),
        Position        = UDim2.new(0, 228, 0, 8),
        BackgroundColor3= CFG.C_PANEL,
        BorderSizePixel = 0,
    }, content)
    Corner(AnalysisPanel, 8)
    Stroke(AnalysisPanel, CFG.C_BORDER, 1)

    -- Barra de status (rodapé)
    StatusBar = New("Frame", {
        Size            = UDim2.new(1, -16, 0, 28),
        Position        = UDim2.new(0, 8, 1, -38),
        BackgroundColor3= CFG.C_SURFACE,
        BorderSizePixel = 0,
    }, content)
    Corner(StatusBar, 6)
    Stroke(StatusBar, CFG.C_BORDER, 1)

    UI._statusLabel = Label("Pronto.", 11, CFG.C_TEXTMUTED, CFG.FONT_MONO, StatusBar, {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    UI._buildListPanel()
    UI._buildAnalysisPanel()
    UI._makeDraggable(MainFrame)
end

-- ── Barra de título ───────────────────────────────────────

function UI._buildTitleBar()
    local bar = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 40),
        BackgroundColor3= CFG.C_SURFACE,
        BorderSizePixel = 0,
    }, MainFrame)
    Corner(bar, 10)

    -- Gradiente de acento
    Gradient(bar,
        Color3.fromRGB(20, 10, 50),
        Color3.fromRGB(8, 8, 14),
        180)

    -- Linha decorativa colorida
    local accent = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 2),
        Position        = UDim2.new(0, 0, 1, -2),
        BackgroundColor3= CFG.C_ACCENT1,
        BorderSizePixel = 0,
    }, bar)
    Gradient(accent,
        CFG.C_ACCENT1,
        CFG.C_ACCENT3,
        0)

    -- Título
    Label("⚡ " .. CFG.TITLE, 14, CFG.C_TEXT, CFG.FONT_TITLE, bar, {
        Size     = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
    })

    -- Versão
    Label(CFG.VERSION, 10, CFG.C_TEXTMUTED, CFG.FONT_MONO, bar, {
        Size     = UDim2.new(0, 40, 0, 14),
        Position = UDim2.new(0, 200, 0, 4),
    })

    -- Botão minimizar
    local minBtn = Button("▬", bar, {
        Size            = UDim2.new(0, 28, 0, 28),
        Position        = UDim2.new(1, -66, 0, 6),
        BackgroundColor3= CFG.C_SURFACE,
        TextColor3      = CFG.C_TEXTMUTED,
        TextSize        = 14,
        Font            = CFG.FONT_TITLE,
    })
    Stroke(minBtn, CFG.C_BORDER, 1)

    -- Botão fechar
    local closeBtn = Button("✕", bar, {
        Size            = UDim2.new(0, 28, 0, 28),
        Position        = UDim2.new(1, -34, 0, 6),
        BackgroundColor3= Color3.fromRGB(80, 20, 30),
        TextColor3      = CFG.C_ERROR,
        TextSize        = 13,
        Font            = CFG.FONT_TITLE,
    })

    minBtn.MouseButton1Click:Connect(function()
        UI._minimized = not UI._minimized
        local targetH = UI._minimized and 40 or CFG.WINDOW_H
        Util.tween(MainFrame, {
            Size = UDim2.new(0, CFG.WINDOW_W, 0, targetH)
        }, 0.25, Enum.EasingStyle.Quad)
        minBtn.Text = UI._minimized and "▲" or "▬"
    end)

    closeBtn.MouseButton1Click:Connect(function()
        Util.tween(MainFrame, {
            Size = UDim2.new(0, CFG.WINDOW_W, 0, 0),
            BackgroundTransparency = 1,
        }, 0.2)
        task.delay(0.25, function() Gui:Destroy() end)
    end)
end

-- ── Painel esquerdo: lista de RemoteEvents ─────────────────

function UI._buildListPanel()
    -- Cabeçalho
    local header = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
    }, ListPanel)

    Label("REMOTES", 10, CFG.C_ACCENT1, CFG.FONT_TITLE, header, {
        Size     = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- Botão atualizar
    local refreshBtn = Button("↺", header, {
        Size            = UDim2.new(0, 28, 0, 24),
        Position        = UDim2.new(1, -34, 0, 6),
        BackgroundColor3= CFG.C_ACCENT3,
        TextSize        = 16,
        Font            = CFG.FONT_TITLE,
    })
    refreshBtn.MouseButton1Click:Connect(function()
        UI.refreshList()
    end)

    -- Caixa de pesquisa
    local searchFrame = New("Frame", {
        Size            = UDim2.new(1, -12, 0, 28),
        Position        = UDim2.new(0, 6, 0, 40),
        BackgroundColor3= CFG.C_SURFACE,
        BorderSizePixel = 0,
    }, ListPanel)
    Corner(searchFrame, 6)
    Stroke(searchFrame, CFG.C_BORDER, 1)

    Label("🔍", 12, CFG.C_TEXTMUTED, CFG.FONT_BODY, searchFrame, {
        Size     = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    SearchBox = New("TextBox", {
        Size            = UDim2.new(1, -30, 1, 0),
        Position        = UDim2.new(0, 28, 0, 0),
        BackgroundTransparency = 1,
        TextColor3      = CFG.C_TEXT,
        Font            = CFG.FONT_BODY,
        TextSize        = 12,
        PlaceholderText = "Pesquisar remote...",
        PlaceholderColor3= CFG.C_TEXTMUTED,
        Text            = "",
        ClearTextOnFocus= false,
    }, searchFrame)

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        UI.applyFilter(SearchBox.Text)
    end)

    -- Contador
    UI._countLabel = Label("0 remotes", 10, CFG.C_TEXTMUTED, CFG.FONT_MONO, ListPanel, {
        Size     = UDim2.new(1, -12, 0, 14),
        Position = UDim2.new(0, 6, 0, 72),
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- ScrollingFrame para a lista
    RemoteList = New("ScrollingFrame", {
        Size            = UDim2.new(1, -8, 1, -94),
        Position        = UDim2.new(0, 4, 0, 88),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CFG.C_ACCENT1,
        CanvasSize      = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, ListPanel)

    New("UIListLayout", {
        SortOrder  = Enum.SortOrder.LayoutOrder,
        Padding    = UDim.new(0, 2),
    }, RemoteList)
    Padding(RemoteList, 2)
end

-- ── Painel direito: análise ────────────────────────────────

function UI._buildAnalysisPanel()
    -- Cabeçalho
    local header = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
    }, AnalysisPanel)

    Label("ANÁLISE", 10, CFG.C_ACCENT2, CFG.FONT_TITLE, header, {
        Size     = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
    })

    -- Separador
    New("Frame", {
        Size            = UDim2.new(1, -12, 0, 1),
        Position        = UDim2.new(0, 6, 0, 36),
        BackgroundColor3= CFG.C_BORDER,
        BorderSizePixel = 0,
    }, AnalysisPanel)

    -- Info box
    local infoBox = New("Frame", {
        Size            = UDim2.new(1, -12, 0, 56),
        Position        = UDim2.new(0, 6, 0, 42),
        BackgroundColor3= CFG.C_SURFACE,
        BorderSizePixel = 0,
    }, AnalysisPanel)
    Corner(infoBox, 6)
    Stroke(infoBox, CFG.C_BORDER, 1)
    Padding(infoBox, 6)

    InfoName = Label("Nenhum remote selecionado", 12, CFG.C_ACCENT3, CFG.FONT_TITLE, infoBox, {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 0),
    })
    InfoPath = Label("", 10, CFG.C_TEXTMUTED, CFG.FONT_MONO, infoBox, {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 18),
    })
    InfoArgCount = Label("", 10, CFG.C_TEXTMUTED, CFG.FONT_BODY, infoBox, {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 34),
    })

    -- Label "CONTROLES"
    Label("CONTROLES DETECTADOS", 9, CFG.C_ACCENT1, CFG.FONT_TITLE, AnalysisPanel, {
        Size     = UDim2.new(1, -12, 0, 14),
        Position = UDim2.new(0, 6, 0, 103),
    })

    -- Área de controles dinâmicos (scrollable)
    local ctrlFrame = New("Frame", {
        Size            = UDim2.new(1, -12, 0, 170),
        Position        = UDim2.new(0, 6, 0, 118),
        BackgroundColor3= CFG.C_SURFACE,
        BorderSizePixel = 0,
        ClipsDescendants= true,
    }, AnalysisPanel)
    Corner(ctrlFrame, 6)
    Stroke(ctrlFrame, CFG.C_BORDER, 1)

    ControlsScroll = New("ScrollingFrame", {
        Size            = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CFG.C_ACCENT1,
        CanvasSize      = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, ctrlFrame)

    New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 4),
    }, ControlsScroll)
    Padding(ControlsScroll, 4, 6, 4)
    ControlsFrame = ControlsScroll

    -- Placeholder
    UI._ctrlPlaceholder = Label(
        "← Selecione um RemoteEvent para ver os controles",
        11, CFG.C_TEXTMUTED, CFG.FONT_BODY, ControlsFrame, {
        Size = UDim2.new(1, 0, 0, 100),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    -- Botões de ação
    local btnRow = New("Frame", {
        Size            = UDim2.new(1, -12, 0, 32),
        Position        = UDim2.new(0, 6, 0, 294),
        BackgroundTransparency = 1,
    }, AnalysisPanel)

    local monitorBtn = Button("▶ Monitorar", btnRow, {
        Size            = UDim2.new(0, 110, 1, 0),
        Position        = UDim2.new(0, 0, 0, 0),
        BackgroundColor3= CFG.C_ACCENT3,
    })
    monitorBtn.MouseButton1Click:Connect(function()
        UI.onMonitorClick()
    end)
    UI._monitorBtn = monitorBtn

    local sendBtn = Button("⚡ Enviar", btnRow, {
        Size            = UDim2.new(0, 100, 1, 0),
        Position        = UDim2.new(0, 118, 0, 0),
        BackgroundColor3= CFG.C_ACCENT2,
    })
    sendBtn.MouseButton1Click:Connect(function()
        UI.onSendClick()
    end)

    local clearBtn = Button("🗑 Limpar", btnRow, {
        Size            = UDim2.new(0, 100, 1, 0),
        Position        = UDim2.new(0, 226, 0, 0),
        BackgroundColor3= CFG.C_SURFACE,
        TextColor3      = CFG.C_TEXTMUTED,
    })
    Stroke(clearBtn, CFG.C_BORDER, 1)
    clearBtn.MouseButton1Click:Connect(function()
        if UI._selected then
            Analyzer._data[UI._selected] = {
                calls = {}, argProfiles = {}
            }
            UI.refreshAnalysis(UI._selected)
            UI.log("🗑 Dados de '" .. UI._selected.Name .. "' limpos.")
        end
    end)

    -- LOG
    Label("LOG DE ANÁLISE", 9, CFG.C_ACCENT1, CFG.FONT_TITLE, AnalysisPanel, {
        Size     = UDim2.new(1, -12, 0, 14),
        Position = UDim2.new(0, 6, 0, 332),
    })

    local logFrame = New("Frame", {
        Size            = UDim2.new(1, -12, 0, 100),
        Position        = UDim2.new(0, 6, 0, 348),
        BackgroundColor3= Color3.fromRGB(5, 5, 10),
        BorderSizePixel = 0,
        ClipsDescendants= true,
    }, AnalysisPanel)
    Corner(logFrame, 6)
    Stroke(logFrame, CFG.C_BORDER, 1)

    local logScroll = New("ScrollingFrame", {
        Size            = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CFG.C_ACCENT1,
        CanvasSize      = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, logFrame)

    New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 1),
    }, logScroll)
    Padding(logScroll, 1, 6, 2)
    LogFrame = logScroll

    UI._logScroll = logScroll
end

-- ── Draggable ─────────────────────────────────────────────

function UI._makeDraggable(frame)
    local titleBar = frame:FindFirstChild("Frame") -- barra de título
    local dragging, dragStart, startPos

    local function onInput(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end

    local function onMove(input)
        if dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end

    local function onRelease(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end

    frame.InputBegan:Connect(onInput)
    game:GetService("UserInputService").InputChanged:Connect(onMove)
    game:GetService("UserInputService").InputEnded:Connect(onRelease)
end

-- ════════════════════════════════════════════════════════════
-- [6] SISTEMA DE CONTROLES DINÂMICOS
-- ════════════════════════════════════════════════════════════

local Controls = {}

-- Limpa todos os controles
function Controls.clear()
    for _, inst in ipairs(ControlsFrame:GetChildren()) do
        if not inst:IsA("UIListLayout") and not inst:IsA("UIPadding") then
            inst:Destroy()
        end
    end
    UI._controls = {}
    if UI._ctrlPlaceholder then
        UI._ctrlPlaceholder.Parent = ControlsFrame
    end
end

-- Cria um rótulo de seção
local function sectionLabel(text, order)
    local f = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        LayoutOrder     = order,
    }, ControlsFrame)
    Label(text, 9, CFG.C_ACCENT1, CFG.FONT_TITLE, f, {
        Size = UDim2.new(1, 0, 1, 0),
    })
end

-- Cria controle TextBox (string ou número)
local function makeTextControl(spec, index, order)
    local icon = spec.kind == "number" and TYPE_ICONS.number or TYPE_ICONS.string
    local f = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 44),
        BackgroundColor3= CFG.C_BG,
        BorderSizePixel = 0,
        LayoutOrder     = order,
    }, ControlsFrame)
    Corner(f, 5)
    Stroke(f, CFG.C_BORDER, 1)
    Padding(f, 4)

    Label(icon .. " " .. (spec.label or "arg"), 11, CFG.C_TEXT, CFG.FONT_BODY, f, {
        Size     = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 0),
    })

    local kindTag = Label(
        spec.kind == "number" and "NUMBER" or "STRING",
        8, spec.kind == "number" and CFG.C_WARNING or CFG.C_ACCENT3,
        CFG.FONT_MONO, f, {
        Size     = UDim2.new(0, 60, 0, 12),
        Position = UDim2.new(1, -64, 0, 1),
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    local inputFrame = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 22),
        Position        = UDim2.new(0, 0, 0, 18),
        BackgroundColor3= CFG.C_SURFACE,
        BorderSizePixel = 0,
    }, f)
    Corner(inputFrame, 4)
    Stroke(inputFrame, CFG.C_ACCENT1, 1, 0.6)

    local tb = New("TextBox", {
        Size            = UDim2.new(1, -8, 1, 0),
        Position        = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        TextColor3      = CFG.C_TEXT,
        Font            = CFG.FONT_MONO,
        TextSize        = 11,
        PlaceholderText = spec.kind == "number" and "0" or "valor...",
        PlaceholderColor3= CFG.C_TEXTMUTED,
        Text            = "",
        ClearTextOnFocus= false,
    }, inputFrame)

    tb.Focused:Connect(function()
        Util.tween(inputFrame, { BackgroundColor3 = Color3.fromRGB(25, 20, 50) })
        Stroke(inputFrame, CFG.C_ACCENT1, 1, 0)
    end)
    tb.FocusLost:Connect(function()
        Util.tween(inputFrame, { BackgroundColor3 = CFG.C_SURFACE })
    end)

    UI._controls[index] = {
        spec    = spec,
        getValue = function()
            local txt = tb.Text
            if spec.kind == "number" then
                return tonumber(txt)
            end
            return txt
        end,
    }
end

-- Cria controle Toggle (boolean)
local function makeBoolControl(spec, index, order)
    local f = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 32),
        BackgroundColor3= CFG.C_BG,
        BorderSizePixel = 0,
        LayoutOrder     = order,
    }, ControlsFrame)
    Corner(f, 5)
    Stroke(f, CFG.C_BORDER, 1)
    Padding(f, 4)

    Label(TYPE_ICONS.boolean .. " " .. (spec.label or "arg"), 11, CFG.C_TEXT, CFG.FONT_BODY, f, {
        Size     = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
    })
    Label("BOOLEAN", 8, CFG.C_SUCCESS, CFG.FONT_MONO, f, {
        Size     = UDim2.new(0, 60, 0, 12),
        Position = UDim2.new(1, -64, 0, 2),
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    -- Toggle switch
    local value = false
    local track = New("Frame", {
        Size            = UDim2.new(0, 40, 0, 18),
        Position        = UDim2.new(1, -46, 0.5, -9),
        BackgroundColor3= CFG.C_BORDER,
        BorderSizePixel = 0,
    }, f)
    Corner(track, 9)

    local knob = New("Frame", {
        Size            = UDim2.new(0, 14, 0, 14),
        Position        = UDim2.new(0, 2, 0.5, -7),
        BackgroundColor3= Color3.new(0.7, 0.7, 0.7),
        BorderSizePixel = 0,
    }, track)
    Corner(knob, 7)

    local trackBtn = New("TextButton", {
        Size            = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text            = "",
    }, track)

    trackBtn.MouseButton1Click:Connect(function()
        value = not value
        if value then
            Util.tween(track, { BackgroundColor3 = CFG.C_SUCCESS })
            Util.tween(knob,  { Position = UDim2.new(1, -16, 0.5, -7),
                                BackgroundColor3 = Color3.new(1,1,1) })
        else
            Util.tween(track, { BackgroundColor3 = CFG.C_BORDER })
            Util.tween(knob,  { Position = UDim2.new(0, 2, 0.5, -7),
                                BackgroundColor3 = Color3.new(0.7,0.7,0.7) })
        end
    end)

    UI._controls[index] = {
        spec     = spec,
        getValue = function() return value end,
    }
end

-- Cria controle Dropdown (enum / opções fixas)
local function makeEnumControl(spec, index, order)
    local options = spec.options or {}
    local selected = options[1] or ""
    local expanded = false

    local f = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 44),
        BackgroundColor3= CFG.C_BG,
        BorderSizePixel = 0,
        LayoutOrder     = order,
        ClipsDescendants= false,
        ZIndex          = 10,
    }, ControlsFrame)
    Corner(f, 5)
    Stroke(f, CFG.C_BORDER, 1)
    Padding(f, 4)

    Label("📋 " .. (spec.label or "arg"), 11, CFG.C_TEXT, CFG.FONT_BODY, f, {
        Size     = UDim2.new(0.6, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex   = 10,
    })

    local tagColor = CFG.C_WARNING
    Label("ENUM" .. (spec.enumName and (":" .. spec.enumName:upper()) or ""),
        8, tagColor, CFG.FONT_MONO, f, {
        Size     = UDim2.new(0, 90, 0, 12),
        Position = UDim2.new(1, -94, 0, 1),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex   = 10,
    })

    -- Cabeça do dropdown
    local dropHead = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 22),
        Position        = UDim2.new(0, 0, 0, 18),
        BackgroundColor3= CFG.C_SURFACE,
        BorderSizePixel = 0,
        ZIndex          = 10,
    }, f)
    Corner(dropHead, 4)
    Stroke(dropHead, CFG.C_ACCENT1, 1, 0.5)

    local selLabel = Label(selected, 11, CFG.C_TEXT, CFG.FONT_MONO, dropHead, {
        Size     = UDim2.new(1, -28, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        ZIndex   = 10,
    })

    local arrow = Label("▼", 10, CFG.C_TEXTMUTED, CFG.FONT_BODY, dropHead, {
        Size     = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -22, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex   = 10,
    })

    -- Lista dropdown
    local dropList = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 0),
        Position        = UDim2.new(0, 0, 1, 2),
        BackgroundColor3= CFG.C_SURFACE,
        BorderSizePixel = 0,
        ClipsDescendants= true,
        ZIndex          = 20,
        Visible         = false,
    }, dropHead)
    Corner(dropList, 4)
    Stroke(dropList, CFG.C_ACCENT1, 1, 0.3)

    New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 1),
    }, dropList)

    for i, opt in ipairs(options) do
        local optBtn = New("TextButton", {
            Size            = UDim2.new(1, 0, 0, 22),
            BackgroundColor3= CFG.C_SURFACE,
            BackgroundTransparency = 0.5,
            TextColor3      = CFG.C_TEXT,
            Font            = CFG.FONT_MONO,
            TextSize        = 11,
            Text            = opt,
            TextXAlignment  = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            ZIndex          = 20,
            LayoutOrder     = i,
        }, dropList)
        Padding(optBtn, 0, 8, 0)

        optBtn.MouseEnter:Connect(function()
            Util.tween(optBtn, { BackgroundColor3 = Color3.fromRGB(40, 30, 80),
                                  BackgroundTransparency = 0 })
        end)
        optBtn.MouseLeave:Connect(function()
            Util.tween(optBtn, { BackgroundColor3 = CFG.C_SURFACE,
                                  BackgroundTransparency = 0.5 })
        end)
        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            selLabel.Text = opt
            expanded = false
            Util.tween(dropList, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
            task.delay(0.15, function() dropList.Visible = false end)
            arrow.Text = "▼"
        end)
    end

    -- Botão da cabeça
    local headBtn = New("TextButton", {
        Size            = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text            = "",
        ZIndex          = 11,
    }, dropHead)

    headBtn.MouseButton1Click:Connect(function()
        expanded = not expanded
        local targetH = expanded and (#options * 23) or 0
        dropList.Visible = true
        Util.tween(dropList, { Size = UDim2.new(1, 0, 0, targetH) }, 0.15)
        if not expanded then
            task.delay(0.15, function() dropList.Visible = false end)
        end
        arrow.Text = expanded and "▲" or "▼"
    end)

    UI._controls[index] = {
        spec     = spec,
        getValue = function() return selected end,
    }
end

-- Cria controle de tabela (JSON input)
local function makeTableControl(spec, index, order)
    local f = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 68),
        BackgroundColor3= CFG.C_BG,
        BorderSizePixel = 0,
        LayoutOrder     = order,
    }, ControlsFrame)
    Corner(f, 5)
    Stroke(f, CFG.C_BORDER, 1)
    Padding(f, 4)

    Label(TYPE_ICONS.table .. " " .. (spec.label or "arg"), 11, CFG.C_TEXT, CFG.FONT_BODY, f, {
        Size     = UDim2.new(0.6, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 0),
    })
    Label("TABLE/JSON", 8, CFG.C_ACCENT2, CFG.FONT_MONO, f, {
        Size     = UDim2.new(0, 80, 0, 12),
        Position = UDim2.new(1, -84, 0, 1),
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    local inputFrame = New("Frame", {
        Size            = UDim2.new(1, 0, 0, 46),
        Position        = UDim2.new(0, 0, 0, 18),
        BackgroundColor3= CFG.C_SURFACE,
        BorderSizePixel = 0,
    }, f)
    Corner(inputFrame, 4)
    Stroke(inputFrame, CFG.C_ACCENT1, 1, 0.6)

    local tb = New("TextBox", {
        Size            = UDim2.new(1, -8, 1, -4),
        Position        = UDim2.new(0, 4, 0, 2),
        BackgroundTransparency = 1,
        TextColor3      = CFG.C_TEXT,
        Font            = CFG.FONT_MONO,
        TextSize        = 10,
        PlaceholderText = '{"key": "value"}',
        PlaceholderColor3= CFG.C_TEXTMUTED,
        Text            = "",
        ClearTextOnFocus= false,
        MultiLine       = true,
        TextWrapped     = true,
    }, inputFrame)

    UI._controls[index] = {
        spec     = spec,
        getValue = function()
            -- Tenta parsear como Lua table literal
            local txt = tb.Text
            if txt == "" then return {} end
            local ok, result = pcall(function()
                local fn = load("return " .. txt)
                if fn then return fn() end
            end)
            return ok and result or txt
        end,
    }
end

-- Gera controles a partir dos perfis analisados
function Controls.generate(remote)
    Controls.clear()
    if UI._ctrlPlaceholder then
        UI._ctrlPlaceholder.Parent = nil
    end

    local d = Analyzer._data[remote]
    if not d or not next(d.argProfiles) then
        -- Sem dados ainda: mostra mensagem
        Label("Nenhum argumento detectado.\nClique em ▶ Monitorar e aguarde chamadas.", 11,
            CFG.C_TEXTMUTED, CFG.FONT_BODY, ControlsFrame, {
            Size = UDim2.new(1, 0, 0, 50),
            TextXAlignment = Enum.TextXAlignment.Center,
            TextWrapped = true,
        })
        return
    end

    sectionLabel("● ARGUMENTOS DETECTADOS (" .. #d.argProfiles .. ")", 0)

    for i, profile in ipairs(d.argProfiles) do
        local spec = Analyzer.suggestControl(profile, profile.name)

        if spec.kind == "number" then
            makeTextControl(spec, i, i * 10)
        elseif spec.kind == "boolean" then
            makeBoolControl(spec, i, i * 10)
        elseif spec.kind == "enum" then
            makeEnumControl(spec, i, i * 10)
        elseif spec.kind == "table" then
            makeTableControl(spec, i, i * 10)
        else
            makeTextControl(spec, i, i * 10)
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- [7] LÓGICA PRINCIPAL DA UI
-- ════════════════════════════════════════════════════════════

-- Log na interface
function UI.log(msg, color)
    local line = Label(
        os.date("%H:%M:%S") .. "  " .. msg,
        10, color or CFG.C_TEXT, CFG.FONT_MONO, LogFrame, {
        Size = UDim2.new(1, 0, 0, 14),
        LayoutOrder = #LogFrame:GetChildren(),
        TextWrapped = true,
    })
    task.delay(0.05, function()
        -- Auto-scroll para o final
        if LogFrame then
            LogFrame.CanvasPosition = Vector2.new(0, LogFrame.AbsoluteCanvasSize.Y)
        end
    end)

    table.insert(UI._logLines, 1, line)
    if #UI._logLines > 60 then
        local old = table.remove(UI._logLines)
        if old then pcall(function() old:Destroy() end) end
    end
end

-- Atualiza status bar
function UI.setStatus(msg, color)
    if UI._statusLabel then
        UI._statusLabel.Text = msg
        UI._statusLabel.TextColor3 = color or CFG.C_TEXTMUTED
    end
end

-- Popula o item na lista de remotes
function UI._addListItem(remote)
    local isRF = remote:IsA("RemoteFunction")
    local bg = New("TextButton", {
        Size            = UDim2.new(1, -4, 0, 32),
        BackgroundColor3= CFG.C_SURFACE,
        BackgroundTransparency = 0.3,
        AutoButtonColor = false,
        Text            = "",
        BorderSizePixel = 0,
    }, RemoteList)
    Corner(bg, 5)

    -- Ícone tipo
    local typeIcon = isRF and "⚙" or "📡"
    local typeColor = isRF and CFG.C_WARNING or CFG.C_ACCENT3

    Label(typeIcon, 12, typeColor, CFG.FONT_BODY, bg, {
        Size     = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    Label(Util.truncate(remote.Name, 22), 11, CFG.C_TEXT, CFG.FONT_BODY, bg, {
        Size     = UDim2.new(1, -28, 0, 16),
        Position = UDim2.new(0, 24, 0, 2),
    })
    Label(isRF and "RF" or "RE", 8, typeColor, CFG.FONT_MONO, bg, {
        Size     = UDim2.new(0, 20, 0, 12),
        Position = UDim2.new(1, -22, 0, 2),
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    -- Caminho truncado
    local pathLbl = Label(Util.truncate(Util.getFullPath(remote), 26),
        9, CFG.C_TEXTMUTED, CFG.FONT_MONO, bg, {
        Size     = UDim2.new(1, -28, 0, 12),
        Position = UDim2.new(0, 24, 0, 18),
    })

    -- Hover & seleção
    bg.MouseEnter:Connect(function()
        if UI._selected ~= remote then
            Util.tween(bg, { BackgroundTransparency = 0.1 })
        end
    end)
    bg.MouseLeave:Connect(function()
        if UI._selected ~= remote then
            Util.tween(bg, { BackgroundTransparency = 0.3 })
        end
    end)
    bg.MouseButton1Click:Connect(function()
        UI.selectRemote(remote, bg)
    end)

    return bg
end

-- Atualiza a lista de remotes
function UI.refreshList()
    UI.setStatus("🔄 Escaneando RemoteEvents...", CFG.C_ACCENT3)

    -- Limpa lista
    for _, c in ipairs(RemoteList:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
            c:Destroy()
        end
    end

    -- Remove hooks antigos
    for remote, _ in pairs(Analyzer._hooks) do
        Analyzer.unhook(remote)
    end

    task.spawn(function()
        UI._remotes = Scanner.findAll()
        UI._filtered = UI._remotes

        for _, remote in ipairs(UI._remotes) do
            UI._addListItem(remote)
        end

        UI._countLabel.Text = #UI._remotes .. " remote(s)"
        UI.setStatus("✅ " .. #UI._remotes .. " RemoteEvents encontrados.", CFG.C_SUCCESS)
        UI.log("🔍 Scan completo: " .. #UI._remotes .. " remotes encontrados.")
    end)
end

-- Filtra a lista por texto
function UI.applyFilter(query)
    local q = query:lower()
    local shown = 0
    for _, child in ipairs(RemoteList:GetChildren()) do
        if child:IsA("TextButton") then
            -- Encontra o remote associado por nome
            local nameLbl = child:FindFirstChildWhichIsA("TextLabel")
            if nameLbl then
                local match = (q == "") or nameLbl.Text:lower():find(q, 1, true)
                child.Visible = match and true or false
                if match then shown += 1 end
            end
        end
    end
    UI._countLabel.Text = shown .. " remote(s)"
end

-- Seleciona um remote
UI._selectedItem = nil

function UI.selectRemote(remote, item)
    -- Deseleciona anterior
    if UI._selectedItem then
        Util.tween(UI._selectedItem, {
            BackgroundColor3 = CFG.C_SURFACE,
            BackgroundTransparency = 0.3,
        })
    end

    UI._selected     = remote
    UI._selectedItem = item

    -- Destaca selecionado
    Util.tween(item, {
        BackgroundColor3 = Color3.fromRGB(30, 20, 70),
        BackgroundTransparency = 0,
    })
    Stroke(item, CFG.C_ACCENT1, 1.5, 0)

    UI.refreshAnalysis(remote)
    UI.log("📌 Selecionado: " .. Util.getFullPath(remote))
end

-- Atualiza painel de análise para o remote selecionado
function UI.refreshAnalysis(remote)
    InfoName.Text = remote.Name
    InfoPath.Text = Util.truncate(Util.getFullPath(remote), 50)

    local d = Analyzer._data[remote]
    local argCount  = d and #d.argProfiles or 0
    local callCount = d and #d.calls or 0

    InfoArgCount.Text = string.format(
        "%d argumento(s) detectado(s)  •  %d chamada(s) observada(s)",
        argCount, callCount
    )

    Controls.generate(remote)
end

-- Botão monitorar
UI._monitoring = false
function UI.onMonitorClick()
    if not UI._selected then
        UI.log("⚠ Nenhum RemoteEvent selecionado.", CFG.C_WARNING)
        return
    end

    if Analyzer._hooks[UI._selected] then
        -- Já está monitorando — para
        Analyzer.unhook(UI._selected)
        UI._monitorBtn.Text = "▶ Monitorar"
        Util.tween(UI._monitorBtn, { BackgroundColor3 = CFG.C_ACCENT3 })
        UI.log("⏹ Monitoramento parado: " .. UI._selected.Name)
        UI.setStatus("Monitoramento parado.", CFG.C_TEXTMUTED)
    else
        -- Inicia monitoramento
        Analyzer.hook(UI._selected)
        UI._monitorBtn.Text = "⏹ Parar"
        Util.tween(UI._monitorBtn, { BackgroundColor3 = CFG.C_ACCENT2 })
        UI.log("▶ Monitorando: " .. UI._selected.Name, CFG.C_SUCCESS)
        UI.setStatus("Monitorando '" .. UI._selected.Name .. "'...", CFG.C_SUCCESS)

        -- Auto-refresh da análise enquanto monitora
        task.spawn(function()
            while Analyzer._hooks[UI._selected] do
                task.wait(0.5)
                if UI._selected then
                    pcall(UI.refreshAnalysis, UI._selected)
                end
            end
        end)
    end
end

-- ════════════════════════════════════════════════════════════
-- [7B] SISTEMA DE ENVIO
-- ════════════════════════════════════════════════════════════

function UI.onSendClick()
    if not UI._selected then
        UI.log("⚠ Nenhum RemoteEvent selecionado.", CFG.C_WARNING)
        UI.setStatus("⚠ Selecione um RemoteEvent primeiro.", CFG.C_WARNING)
        return
    end

    -- Coleta argumentos dos controles
    local args = {}
    for i = 1, 20 do
        local ctrl = UI._controls[i]
        if not ctrl then break end
        local ok, val = pcall(ctrl.getValue)
        if ok then
            table.insert(args, val)
        else
            table.insert(args, nil)
        end
    end

    -- Prévia dos argumentos
    local preview = {}
    for i, v in ipairs(args) do
        table.insert(preview, string.format("  [%d] %s = %s",
            i,
            UI._controls[i] and UI._controls[i].spec.label or "?",
            Util.valueToString(v)
        ))
    end

    UI.log("📤 Enviando '" .. UI._selected.Name .. "' com " .. #args .. " arg(s):")
    for _, line in ipairs(preview) do
        UI.log(line, CFG.C_TEXTMUTED)
    end

    -- Dispara o RemoteEvent
    local ok, err = pcall(function()
        if UI._selected:IsA("RemoteEvent") then
            UI._selected:FireServer(table.unpack(args))
        elseif UI._selected:IsA("RemoteFunction") then
            local result = UI._selected:InvokeServer(table.unpack(args))
            UI.log("↩ Retorno: " .. Util.valueToString(result), CFG.C_SUCCESS)
        end
    end)

    if ok then
        UI.log("✅ Enviado com sucesso!", CFG.C_SUCCESS)
        UI.setStatus("✅ RemoteEvent enviado.", CFG.C_SUCCESS)
    else
        UI.log("❌ Erro: " .. tostring(err), CFG.C_ERROR)
        UI.setStatus("❌ Erro ao enviar.", CFG.C_ERROR)
    end
end

-- ════════════════════════════════════════════════════════════
-- [8] INICIALIZAÇÃO
-- ════════════════════════════════════════════════════════════

local function init()
    -- Constrói a interface
    UI.build()

    -- Animação de entrada
    MainFrame.Size = UDim2.new(0, CFG.WINDOW_W, 0, 0)
    MainFrame.BackgroundTransparency = 1
    Util.tween(MainFrame, {
        Size = UDim2.new(0, CFG.WINDOW_W, 0, CFG.WINDOW_H),
        BackgroundTransparency = 0,
    }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    UI.log("⚡ RemoteEvent Analyzer iniciado.", CFG.C_ACCENT1)
    UI.log("Clique em ↺ para escanear o jogo.", CFG.C_TEXTMUTED)
    UI.setStatus("Pronto. Clique em ↺ para escanear.", CFG.C_TEXTMUTED)

    -- Escaneia automaticamente após 0.5s
    task.delay(0.5, function()
        UI.refreshList()
    end)
end

init()
