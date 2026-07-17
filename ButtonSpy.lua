--[[
    BUTTON SPY v2.1 — CoiledTom Hub
    Versão leve: mobile-first, sem loops pesados
--]]

-- ══ SERVIÇOS ══
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP       = Players.LocalPlayer
local PGui     = LP:WaitForChild("PlayerGui")

-- ══ UTILS ══
local function safeStr(v)
    if v == nil then return "nil" end
    local ok, r = pcall(tostring, v); return ok and r or "?"
end

local function typeOf(v)
    return (typeof and typeof(v)) or type(v)
end

local function serializeArg(v)
    local t = typeOf(v)
    if t == "string"   then return '"'..v..'"' end
    if t == "number" or t == "boolean" then return tostring(v) end
    if t == "Instance" then
        local ok, p = pcall(function() return v:GetFullName() end)
        return ok and "[Inst] "..p or "[Inst] ?"
    end
    if t == "Vector3" then return ("V3(%g,%g,%g)"):format(v.X,v.Y,v.Z) end
    if t == "Vector2" then return ("V2(%g,%g)"):format(v.X,v.Y) end
    if t == "CFrame"  then local p=v.Position; return ("CF(%g,%g,%g)"):format(p.X,p.Y,p.Z) end
    if t == "Color3"  then return ("C3(%g,%g,%g)"):format(v.R,v.G,v.B) end
    if t == "UDim2"   then return ("U2(%g,%g,%g,%g)"):format(v.X.Scale,v.X.Offset,v.Y.Scale,v.Y.Offset) end
    return "["..t.."] "..safeStr(v)
end

local function copy(text)
    if setclipboard then pcall(setclipboard, text); return true end
    if syn and syn.clipboard then pcall(syn.clipboard.set, text); return true end
    return false
end

local function getSource(scr)
    if decompile then
        local ok, s = pcall(decompile, scr)
        if ok and type(s)=="string" and #s>0 then return s end
    end
    if getscriptbytecode then
        local ok, b = pcall(getscriptbytecode, scr)
        if ok and type(b)=="string" and #b>0 then return "[Bytecode — sem decompilador]" end
    end
    return nil
end

-- ══ REMOTE LOG (limitado a 200 entradas) ══
local remoteLog = {}
local MAX_REMOTE_LOG = 200

local function logRemote(path, rtype, args)
    if #remoteLog >= MAX_REMOTE_LOG then table.remove(remoteLog, 1) end
    table.insert(remoteLog, { time=os.clock(), remotePath=path, remoteType=rtype, args=args })
end

-- Hook __namecall (executores que suportam getrawmetatable)
pcall(function()
    local mt = getrawmetatable(game)
    if not mt then return end
    local old = mt.__namecall
    pcall(setreadonly, mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        if (method=="FireServer" or method=="InvokeServer")
        and (pcall(function() return self:IsA("RemoteEvent") or self:IsA("RemoteFunction") end)) then
            local path = "?"
            pcall(function() path = self:GetFullName() end)
            local sArgs = {}
            for _, a in ipairs({...}) do table.insert(sArgs, serializeArg(a)) end
            logRemote(path, method, sArgs)
        end
        return old(self, ...)
    end)
    pcall(setreadonly, mt, true)
end)

-- Fallback: OnClientEvent no ReplicatedStorage (sem Workspace — muito pesado)
pcall(function()
    local watched = {}
    local function watch(v)
        if watched[v] then return end
        if not v:IsA("RemoteEvent") then return end
        watched[v] = true
        v.OnClientEvent:Connect(function(...)
            local sArgs = {}
            for _, a in ipairs({...}) do table.insert(sArgs, serializeArg(a)) end
            logRemote(v:GetFullName(), "OnClientEvent", sArgs)
        end)
    end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do watch(v) end
    ReplicatedStorage.DescendantAdded:Connect(watch)
end)

-- ══ SNAPSHOTS LEVES (só PlayerGui + Character) ══

-- GUIs: só ScreenGui de 1º nível (não toda a árvore)
local function snapGUI()
    local s = {}
    pcall(function()
        for _, g in ipairs(PGui:GetChildren()) do
            if g:IsA("ScreenGui") or g:IsA("GuiBase2d") then
                s[g.Name] = g.Visible
            end
        end
    end)
    return s
end

-- Sons: só do Character e PlayerGui (não game inteiro)
local function snapSounds()
    local s = {}
    local roots = {}
    pcall(function() table.insert(roots, LP.Character) end)
    pcall(function() table.insert(roots, PGui) end)
    for _, root in ipairs(roots) do
        if root then
            pcall(function()
                for _, v in ipairs(root:GetDescendants()) do
                    if v:IsA("Sound") then
                        s[v:GetFullName()] = v.IsPlaying
                    end
                end
            end)
        end
    end
    return s
end

-- Values: só do Character (leaderstats etc. ficam no servidor)
local function snapValues()
    local s = {}
    pcall(function()
        local char = LP.Character
        if not char then return end
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("IntValue") or v:IsA("NumberValue")
            or v:IsA("StringValue") or v:IsA("BoolValue") then
                s[v.Name] = v.Value
            end
        end
    end)
    -- Também leaderstats se acessível via PlayerGui
    pcall(function()
        local ls = LP:FindFirstChild("leaderstats")
        if ls then
            for _, v in ipairs(ls:GetChildren()) do
                s["leaderstats."..v.Name] = v.Value
            end
        end
    end)
    return s
end

-- Humanoid: snapshot direto (sem loop)
local function snapHum()
    local s = {}
    pcall(function()
        local char = LP.Character
        if not char then return end
        local h = char:FindFirstChildOfClass("Humanoid")
        if not h then return end
        s.WalkSpeed = h.WalkSpeed
        s.JumpPower = h.JumpPower
        s.Health    = math.floor(h.Health)
        s.MaxHealth = h.MaxHealth
    end)
    return s
end

-- Camera: só propriedades básicas
local function snapCam()
    local s = {}
    pcall(function()
        local c = workspace.CurrentCamera
        s.Type = tostring(c.CameraType)
        s.FOV  = c.FieldOfView
    end)
    return s
end

-- Diffs
local function diffTable(before, after, label)
    local out = {}
    for k, bv in pairs(before) do
        local av = after[k]
        if av ~= nil and tostring(av) ~= tostring(bv) then
            table.insert(out, ("  %s.%s: %s → %s"):format(label, k, safeStr(bv), safeStr(av)))
        end
    end
    return out
end

local function diffGUI(before, after)
    local out = {}
    for k, bv in pairs(before) do
        local av = after[k]
        if av ~= nil and av ~= bv then
            table.insert(out, ("  %s → %s"):format(k, av and "VISÍVEL" or "OCULTO"))
        end
    end
    for k, av in pairs(after) do
        if before[k] == nil then
            table.insert(out, ("  %s → CRIADA"):format(k))
        end
    end
    return out
end

local function diffSounds(before, after)
    local out = {}
    for k, av in pairs(after) do
        if av and not before[k] then
            table.insert(out, "  Iniciou: " .. k)
        end
    end
    return out
end

-- Scripts relacionados
local function findScripts(btn)
    local found = {}
    local seen  = {}
    local function check(inst)
        if seen[inst] then return end
        seen[inst] = true
        if inst:IsA("LocalScript") or inst:IsA("ModuleScript") then
            local p = "?"; pcall(function() p = inst:GetFullName() end)
            table.insert(found, { path=p, class=inst.ClassName, source=getSource(inst) })
        end
    end
    pcall(function()
        for _, v in ipairs(btn:GetDescendants()) do check(v) end
        if btn.Parent then
            for _, v in ipairs(btn.Parent:GetChildren()) do check(v) end
            check(btn.Parent)
        end
    end)
    return found
end

-- ══ GUI ══
pcall(function()
    local old = CoreGui:FindFirstChild("ButtonSpyV2")
    if old then old:Destroy() end
    local old2 = PGui:FindFirstChild("ButtonSpyV2")
    if old2 then old2:Destroy() end
end)

local SG = Instance.new("ScreenGui")
SG.Name           = "ButtonSpyV2"
SG.ResetOnSpawn   = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder   = 999
if not pcall(function() SG.Parent = CoreGui end) then
    SG.Parent = PGui
end

-- Cores
local CL = {
    bg      = Color3.fromRGB(7,9,16),
    panel   = Color3.fromRGB(11,14,26),
    border  = Color3.fromRGB(0,190,255),
    accent  = Color3.fromRGB(120,0,240),
    red     = Color3.fromRGB(210,30,75),
    txt     = Color3.fromRGB(200,215,235),
    dim     = Color3.fromRGB(90,105,135),
    ok      = Color3.fromRGB(0,210,130),
    warn    = Color3.fromRGB(255,175,0),
    head    = Color3.fromRGB(0,175,255),
}

local vp   = workspace.CurrentCamera.ViewportSize
local W    = math.min(320, vp.X - 16)
local H    = math.min(500, vp.Y - 36)

-- helpers
local function ni(class, props, parent)
    local o = Instance.new(class)
    for k,v in pairs(props) do o[k]=v end
    if parent then o.Parent = parent end
    return o
end
local function corner(r,p) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=p end
local function stroke(t,col,p,tr) local s=Instance.new("UIStroke"); s.Thickness=t; s.Color=col; s.Transparency=tr or 0; s.Parent=p end
local function grad(c0,c1,rot,p) local g=Instance.new("UIGradient"); g.Color=ColorSequence.new(c0,c1); g.Rotation=rot; g.Parent=p end

-- Janela
local Win = ni("Frame",{
    Name="Win", Size=UDim2.new(0,W,0,H), Position=UDim2.new(0,8,0,36),
    BackgroundColor3=CL.bg, BorderSizePixel=0, ClipsDescendants=true,
}, SG)
corner(10,Win)
stroke(1.2,CL.border,Win,0.4)
grad(Color3.fromRGB(7,9,20),Color3.fromRGB(13,7,28),130,Win)

-- Título
local TBar = ni("Frame",{
    Name="TBar", Size=UDim2.new(1,0,0,34), BackgroundColor3=CL.panel, BorderSizePixel=0,
}, Win)
corner(10,TBar)
grad(Color3.fromRGB(0,150,210),Color3.fromRGB(90,0,190),90,TBar)

ni("TextLabel",{
    Text=" BUTTON SPY  v2.1", Size=UDim2.new(1,-90,1,0), Position=UDim2.new(0,10,0,0),
    BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), TextSize=12,
    Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
}, TBar)

local Badge = ni("TextLabel",{
    Text="● ATIVO", Size=UDim2.new(0,56,0,18), Position=UDim2.new(1,-126,0.5,-9),
    BackgroundColor3=CL.ok, TextColor3=Color3.new(0,0,0),
    TextSize=8, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Center,
}, TBar)
corner(9,Badge)

local MinBtn = ni("TextButton",{
    Text="—", Size=UDim2.new(0,26,0,20), Position=UDim2.new(1,-58,0.5,-10),
    BackgroundColor3=Color3.fromRGB(28,33,52), TextColor3=CL.txt,
    TextSize=13, Font=Enum.Font.GothamBold, BorderSizePixel=0,
}, TBar)
corner(5,MinBtn)

local XBtn = ni("TextButton",{
    Text="✕", Size=UDim2.new(0,26,0,20), Position=UDim2.new(1,-28,0.5,-10),
    BackgroundColor3=CL.red, TextColor3=Color3.new(1,1,1),
    TextSize=11, Font=Enum.Font.GothamBold, BorderSizePixel=0,
}, TBar)
corner(5,XBtn)

-- Conteúdo
local Body = ni("Frame",{
    Size=UDim2.new(1,0,1,-34), Position=UDim2.new(0,0,0,34),
    BackgroundTransparency=1,
}, Win)

-- Info do botão
local InfoFr = ni("Frame",{
    Size=UDim2.new(1,-14,0,78), Position=UDim2.new(0,7,0,7),
    BackgroundColor3=CL.panel, BorderSizePixel=0,
}, Body)
corner(7,InfoFr)
stroke(1,CL.accent,InfoFr,0.55)

local InfoTop = ni("TextLabel",{
    Text="AGUARDANDO CLIQUE...",
    Size=UDim2.new(1,-8,0,16), Position=UDim2.new(0,6,0,5),
    BackgroundTransparency=1, TextColor3=CL.head, TextSize=11,
    Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
}, InfoFr)

local InfoSub = ni("TextLabel",{
    Text="Clique em qualquer botão do jogo\npara iniciar a análise.",
    Size=UDim2.new(1,-8,1,-24), Position=UDim2.new(0,6,0,22),
    BackgroundTransparency=1, TextColor3=CL.dim, TextSize=10,
    Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Top, TextWrapped=true,
}, InfoFr)

-- Abas
local TabRow = ni("Frame",{
    Size=UDim2.new(1,-14,0,28), Position=UDim2.new(0,7,0,93),
    BackgroundTransparency=1,
}, Body)

local TAB_NAMES = {"LOG","REMOTES","SCRIPTS"}
local tabBtns   = {}
local activeTab = "LOG"
local tabW      = (W-14-8)/3

for i, name in ipairs(TAB_NAMES) do
    local b = ni("TextButton",{
        Text=name, Size=UDim2.new(0,tabW,1,0),
        Position=UDim2.new(0,(tabW+4)*(i-1),0,0),
        BackgroundColor3 = i==1 and CL.border or Color3.fromRGB(18,22,42),
        TextColor3 = i==1 and Color3.new(0,0,0) or CL.dim,
        TextSize=9, Font=Enum.Font.GothamBold, BorderSizePixel=0,
    }, TabRow)
    corner(5,b)
    tabBtns[name] = b
end

-- Scroll de logs
local Scroll = ni("ScrollingFrame",{
    Size=UDim2.new(1,-14,1,-180), Position=UDim2.new(0,7,0,129),
    BackgroundColor3=Color3.fromRGB(4,7,14), BorderSizePixel=0,
    ScrollBarThickness=3, ScrollBarImageColor3=CL.accent,
    CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
}, Body)
corner(7,Scroll)
stroke(1,Color3.fromRGB(25,30,55),Scroll,0)

ni("UIListLayout",{ Padding=UDim.new(0,1), SortOrder=Enum.SortOrder.LayoutOrder }, Scroll)
ni("UIPadding",{
    PaddingLeft=UDim.new(0,5), PaddingRight=UDim.new(0,5),
    PaddingTop=UDim.new(0,5),  PaddingBottom=UDim.new(0,5),
}, Scroll)

-- Botões de cópia
local BtnArea = ni("Frame",{
    Size=UDim2.new(1,-14,0,48), Position=UDim2.new(0,7,1,-54),
    BackgroundTransparency=1,
}, Body)

local copyDefs = {
    {k="name",  l="Copiar Nome"},  {k="path",   l="Copiar Caminho"}, {k="remote", l="Copiar Remote"},
    {k="args",  l="Copiar Args"},  {k="code",   l="Copiar Código"},  {k="all",    l="Copiar Tudo"},
}
local cBtns = {}
local cbW   = (W-14-10)/3

for i, d in ipairs(copyDefs) do
    local col = (i-1)%3; local row = math.floor((i-1)/3)
    local b = ni("TextButton",{
        Text=d.l, Size=UDim2.new(0,cbW,0,20),
        Position=UDim2.new(0,col*(cbW+5),0,row*24),
        BackgroundColor3=Color3.fromRGB(15,19,36),
        TextColor3=CL.dim, TextSize=9, Font=Enum.Font.Gotham, BorderSizePixel=0,
    }, BtnArea)
    corner(4,b)
    stroke(1,Color3.fromRGB(35,42,70),b,0)
    cBtns[d.k] = b
end

-- ══ ESTADO ══
local report  = { name="",path="",remotes={},scripts={},fullText="",code="" }
local tabData = { LOG={}, REMOTES={}, SCRIPTS={} }
local logIdx  = 0

-- Funções de log
local function clearScroll()
    for _, c in ipairs(Scroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
end

local function addLine(text, color, bold, order)
    ni("TextLabel",{
        Text=text, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, TextColor3=color or CL.txt,
        TextSize=10, Font=bold and Enum.Font.GothamBold or Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
        LayoutOrder=order or 0,
    }, Scroll)
end

local function pushLog(tab, text, color, bold)
    logIdx = logIdx + 1
    table.insert(tabData[tab], {t=text,c=color,b=bold,o=logIdx})
    if activeTab==tab then
        addLine(text,color,bold,logIdx)
        task.defer(function()
            if Scroll and Scroll.Parent then
                Scroll.CanvasPosition = Vector2.new(0, Scroll.AbsoluteCanvasSize.Y)
            end
        end)
    end
end

local function renderTab(name)
    activeTab = name
    clearScroll()
    logIdx = 0
    for n, b in pairs(tabBtns) do
        if n==name then b.BackgroundColor3=CL.border; b.TextColor3=Color3.new(0,0,0)
        else             b.BackgroundColor3=Color3.fromRGB(18,22,42); b.TextColor3=CL.dim end
    end
    for _, e in ipairs(tabData[name]) do
        addLine(e.t,e.c,e.b,e.o)
    end
    task.defer(function()
        if Scroll and Scroll.Parent then
            Scroll.CanvasPosition = Vector2.new(0, Scroll.AbsoluteCanvasSize.Y)
        end
    end)
end

for _, name in ipairs(TAB_NAMES) do
    tabBtns[name].MouseButton1Click:Connect(function() renderTab(name) end)
end

local function flashBtn(btn, orig, msg, col)
    btn.Text = msg; btn.TextColor3 = col
    task.delay(1.2, function()
        if btn and btn.Parent then btn.Text=orig; btn.TextColor3=CL.dim end
    end)
end

-- Copy buttons
cBtns["name"].MouseButton1Click:Connect(function()
    if report.name=="" then return end
    if copy(report.name) then flashBtn(cBtns["name"],"Copiar Nome","✓ OK!",CL.ok) end
end)
cBtns["path"].MouseButton1Click:Connect(function()
    if report.path=="" then return end
    if copy(report.path) then flashBtn(cBtns["path"],"Copiar Caminho","✓ OK!",CL.ok) end
end)
cBtns["remote"].MouseButton1Click:Connect(function()
    if #report.remotes==0 then return end
    local lines={}
    for _,r in ipairs(report.remotes) do table.insert(lines,r.remotePath.." ["..r.remoteType.."]") end
    if copy(table.concat(lines,"\n")) then flashBtn(cBtns["remote"],"Copiar Remote","✓ OK!",CL.ok) end
end)
cBtns["args"].MouseButton1Click:Connect(function()
    if #report.remotes==0 then return end
    local lines={}
    for _,r in ipairs(report.remotes) do
        table.insert(lines,r.remotePath..":")
        for i,a in ipairs(r.args) do table.insert(lines,"  ["..i.."] "..a) end
    end
    if copy(table.concat(lines,"\n")) then flashBtn(cBtns["args"],"Copiar Args","✓ OK!",CL.ok) end
end)
cBtns["code"].MouseButton1Click:Connect(function()
    if report.code=="" then return end
    if copy(report.code) then flashBtn(cBtns["code"],"Copiar Código","✓ OK!",CL.ok) end
end)
cBtns["all"].MouseButton1Click:Connect(function()
    if report.fullText=="" then return end
    if copy(report.fullText) then flashBtn(cBtns["all"],"Copiar Tudo","✓ OK!",CL.ok) end
end)

-- Minimizar / Fechar
local minimized = false
XBtn.MouseButton1Click:Connect(function() SG:Destroy() end)
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Body.Visible = not minimized
    Win.Size = minimized and UDim2.new(0,W,0,34) or UDim2.new(0,W,0,H)
    MinBtn.Text = minimized and "□" or "—"
end)

-- Drag
do
    local drag,dStart,wStart = false
    TBar.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true; dStart=inp.Position; wStart=Win.Position
        end
    end)
    TBar.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch) then
            local d = inp.Position-dStart
            Win.Position = UDim2.new(wStart.X.Scale,wStart.X.Offset+d.X,wStart.Y.Scale,wStart.Y.Offset+d.Y)
        end
    end)
end

-- ══ ANÁLISE ══
local CAPTURE = 1.5  -- segundos de espera (mais leve)
local analyzing = false

local function isOurGui(inst)
    local cur = inst
    while cur do
        if cur == SG then return true end
        cur = cur.Parent
    end
    return false
end

local function analyze(btn)
    if analyzing then return end
    analyzing = true
    Badge.Text = "● ANALISANDO"; Badge.BackgroundColor3 = CL.warn

    -- Info básica
    local bName,bPath,bClass,bText,bVis,bSize,bPos = "?","?","?","",false,"?","?"
    pcall(function() bName  = btn.Name end)
    pcall(function() bPath  = btn:GetFullName() end)
    pcall(function() bClass = btn.ClassName end)
    pcall(function() if btn:IsA("TextButton") then bText=btn.Text end end)
    pcall(function() bVis   = btn.Visible end)
    pcall(function()
        local s=btn.Size
        bSize=("X:%g,%g Y:%g,%g"):format(s.X.Scale,s.X.Offset,s.Y.Scale,s.Y.Offset)
    end)
    pcall(function()
        local p=btn.AbsolutePosition
        bPos=("(%g,%g)"):format(p.X,p.Y)
    end)

    InfoTop.Text = bClass..": "..bName
    InfoSub.Text = bPath.."\n"..bSize.."  Vis:"..tostring(bVis)

    -- Reset logs
    for k in pairs(tabData) do tabData[k]={} end
    clearScroll(); logIdx=0

    pushLog("LOG","══ CAPTURANDO "..CAPTURE.."s... ══",CL.warn,true)
    renderTab(activeTab)

    -- Pré-snapshot (leve)
    local preGUI    = snapGUI()
    local preSnd    = snapSounds()
    local preVal    = snapValues()
    local preHum    = snapHum()
    local preCam    = snapCam()
    local preRemIdx = #remoteLog

    task.wait(CAPTURE)

    -- Pós-snapshot
    local guiCh = diffGUI(preGUI,   snapGUI())
    local sndCh = diffSounds(preSnd, snapSounds())
    local valCh = diffTable(preVal,  snapValues(),  "val")
    local humCh = diffTable(preHum,  snapHum(),     "hum")
    local camCh = diffTable(preCam,  snapCam(),     "cam")

    -- Remotes na janela
    local remotes = {}
    for i = preRemIdx+1, #remoteLog do
        table.insert(remotes, remoteLog[i])
    end

    -- Scripts
    local scripts = findScripts(btn)

    -- Montar código disponível
    local codeBlocks = {}
    for _, s in ipairs(scripts) do
        if s.source then table.insert(codeBlocks, "-- "..s.path.."\n"..s.source) end
    end

    report.name     = bName
    report.path     = bPath
    report.remotes  = remotes
    report.scripts  = scripts
    report.code     = table.concat(codeBlocks,"\n\n")

    -- ── Preencher LOG ──
    pushLog("LOG","══════════════════════════════",CL.border,true)
    pushLog("LOG","  "..bClass..": "..bName,CL.head,true)
    pushLog("LOG","  "..bPath,CL.dim)
    if bText~="" then pushLog("LOG","  Texto: \""..bText.."\"",CL.txt) end
    pushLog("LOG","  Visível: "..tostring(bVis),CL.dim)
    pushLog("LOG","══════════════════════════════",CL.border,true)
    pushLog("LOG","[ MUDANÇAS DETECTADAS ]",CL.accent,true)

    local any = false
    if #guiCh>0  then any=true; pushLog("LOG","  GUIs:",CL.ok,true);   for _,l in ipairs(guiCh)  do pushLog("LOG",l,CL.txt) end end
    if #sndCh>0  then any=true; pushLog("LOG","  Sons:",CL.ok,true);   for _,l in ipairs(sndCh)  do pushLog("LOG",l,CL.txt) end end
    if #valCh>0  then any=true; pushLog("LOG","  Valores:",CL.ok,true);for _,l in ipairs(valCh)  do pushLog("LOG",l,CL.txt) end end
    if #humCh>0  then any=true; pushLog("LOG","  Hum:",CL.warn,true);  for _,l in ipairs(humCh)  do pushLog("LOG",l,CL.txt) end end
    if #camCh>0  then any=true; pushLog("LOG","  Cam:",CL.warn,true);  for _,l in ipairs(camCh)  do pushLog("LOG",l,CL.txt) end end
    if #remotes>0 then any=true; pushLog("LOG","  Remotes: "..#remotes.." disparado(s)",CL.head,true) end
    if #scripts>0 then any=true; pushLog("LOG","  Scripts: "..#scripts.." encontrado(s)",CL.head,true) end
    if not any then pushLog("LOG","  Sem mudanças detectadas no cliente.",CL.dim) end

    -- ── Preencher REMOTES ──
    pushLog("REMOTES","══ REMOTES: "..#remotes.." ══",CL.border,true)
    if #remotes>0 then
        for i,r in ipairs(remotes) do
            pushLog("REMOTES",("[%d] %s"):format(i,r.remoteType),CL.accent,true)
            pushLog("REMOTES","  "..r.remotePath,CL.txt)
            if #r.args>0 then
                pushLog("REMOTES","  Args:",CL.warn,true)
                for j,a in ipairs(r.args) do pushLog("REMOTES",("    [%d] %s"):format(j,a),CL.txt) end
            else
                pushLog("REMOTES","  Args: (nenhum)",CL.dim)
            end
            pushLog("REMOTES","  ──────────────────────",CL.border)
        end
    else
        pushLog("REMOTES","  Nenhum remote nesta janela.",CL.dim)
        pushLog("REMOTES","  (hook __namecall + OnClientEvent ativo)",CL.dim)
    end

    -- ── Preencher SCRIPTS ──
    pushLog("SCRIPTS","══ SCRIPTS: "..#scripts.." ══",CL.border,true)
    if #scripts>0 then
        for i,s in ipairs(scripts) do
            pushLog("SCRIPTS",("[%d] %s"):format(i,s.class),CL.accent,true)
            pushLog("SCRIPTS","  "..s.path,CL.txt)
            if s.source then
                pushLog("SCRIPTS","  Código: DISPONÍVEL",CL.ok,true)
                local n=0
                for line in s.source:gmatch("[^\n]+") do
                    pushLog("SCRIPTS","  "..line,Color3.fromRGB(140,215,140))
                    n=n+1; if n>=6 then pushLog("SCRIPTS","  ...(use Copiar Código)",CL.dim); break end
                end
            else
                pushLog("SCRIPTS","  Código: INDISPONÍVEL",CL.red,true)
                pushLog("SCRIPTS","  Protegido ou executado no servidor.",CL.dim)
            end
            pushLog("SCRIPTS","  ──────────────────────",CL.border)
        end
    else
        pushLog("SCRIPTS","  Nenhum LocalScript/ModuleScript próximo.",CL.dim)
    end

    -- Relatório completo para copiar
    local lines={}
    table.insert(lines,"BUTTON SPY v2.1 — "..bClass..": "..bName)
    table.insert(lines,"Caminho: "..bPath)
    table.insert(lines,"Visível: "..tostring(bVis))
    table.insert(lines,"")
    table.insert(lines,"[MUDANÇAS]")
    for _,t in ipairs({guiCh,sndCh,valCh,humCh,camCh}) do
        for _,l in ipairs(t) do table.insert(lines,l) end
    end
    table.insert(lines,"")
    table.insert(lines,"[REMOTES: "..#remotes.."]")
    for _,r in ipairs(remotes) do
        table.insert(lines,r.remoteType.." | "..r.remotePath)
        for j,a in ipairs(r.args) do table.insert(lines,"  ["..j.."] "..a) end
    end
    table.insert(lines,"")
    table.insert(lines,"[SCRIPTS: "..#scripts.."]")
    for _,s in ipairs(scripts) do
        table.insert(lines,s.class.." | "..s.path)
        table.insert(lines,s.source and "Código: SIM" or "Código: NAO")
    end
    report.fullText = table.concat(lines,"\n")

    renderTab(activeTab)
    Badge.Text="● ATIVO"; Badge.BackgroundColor3=CL.ok
    analyzing = false
end

-- ══ HOOK DE BOTÕES ══
local hooked = {}

local function hookBtn(b)
    if hooked[b] then return end
    hooked[b] = true
    b.MouseButton1Click:Connect(function()
        if isOurGui(b) then return end
        task.spawn(analyze, b)
    end)
end

local function scanGui(parent)
    pcall(function()
        for _, d in ipairs(parent:GetDescendants()) do
            if d:IsA("TextButton") or d:IsA("ImageButton") then hookBtn(d) end
        end
        parent.DescendantAdded:Connect(function(inst)
            task.defer(function()
                if (inst:IsA("TextButton") or inst:IsA("ImageButton")) and not isOurGui(inst) then
                    hookBtn(inst)
                end
            end)
        end)
    end)
end

scanGui(PGui)

LP.CharacterAdded:Connect(function()
    task.wait(0.3)
    scanGui(PGui)
end)

-- Scan periódico mais espaçado
task.spawn(function()
    while SG and SG.Parent do
        task.wait(8)  -- 8s em vez de 3s
        pcall(function()
            for _, d in ipairs(PGui:GetChildren()) do
                pcall(function()
                    for _, dd in ipairs(d:GetDescendants()) do
                        if (dd:IsA("TextButton") or dd:IsA("ImageButton")) and not hooked[dd] then
                            hookBtn(dd)
                        end
                    end
                end)
            end
        end)
    end
end)

-- ══ LOG INICIAL ══
pushLog("LOG","  BUTTON SPY v2.1 — CoiledTom Hub",CL.border,true)
pushLog("LOG","  Clique em qualquer botão do jogo.",CL.dim)
pushLog("LOG","  Captura: "..CAPTURE.."s por clique",CL.dim)
pushLog("REMOTES","  Aguardando...",CL.dim)
pushLog("SCRIPTS","  Aguardando...",CL.dim)
renderTab("LOG")

print("[ButtonSpy v2.1] OK — CoiledTom Hub")
