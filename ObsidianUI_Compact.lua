-- ObsidianUI Compact v2.0
-- Versão compacta e otimizada sem emojis
-- Ícones: Sistema Roblox Lucide Icons

local ObsidianUI = {}
ObsidianUI.__index = ObsidianUI

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ========== ICON SYSTEM ==========
local Icons = {
    settings = 10734950309,
    user = 10747373176,
    shield = 10723434711,
    eye = 10747318198,
    target = 10723407389,
    zap = 10747270876,
    activity = 10709752035,
    cpu = 10723386299,
    clock = 10709805703,
    search = 10734898355,
    check = 10709814937,
    x = 10747384394,
    info = 10723434823,
    alertcircle = 10709752996,
    alerttriangle = 10709753149,
    bell = 10709775704,
    maximize = 10734896206,
    minimize = 10734883554,
    menu = 10734921971,
    chevrondown = 10709790948,
    chevronup = 10709791437,
    home = 10723345866,
    package = 10723386962,
    layers = 10723386772,
    terminal = 10747373054,
    radio = 10723434557,
    globe = 10723343740,
    download = 10709805508,
    upload = 10734881617,
}

-- Utility
local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            obj[k] = v
        end
    end
    if props.Parent then
        obj.Parent = props.Parent
    end
    return obj
end

local function Tween(obj, info, props)
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function CreateIcon(parent, iconId, size, color, zindex)
    local icon = Create("ImageLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, size or 20, 0, size or 20),
        Image = "rbxassetid://" .. iconId,
        ImageColor3 = color or Color3.new(1, 1, 1),
        ZIndex = zindex or 5,
    })
    return icon
end

-- Theme
local Theme = {
    Primary = Color3.fromRGB(255, 100, 0),
    PrimaryDark = Color3.fromRGB(200, 70, 0),
    Background = Color3.fromRGB(13, 13, 15),
    Surface = Color3.fromRGB(20, 20, 24),
    Surface2 = Color3.fromRGB(28, 28, 33),
    Surface3 = Color3.fromRGB(35, 35, 42),
    Border = Color3.fromRGB(45, 45, 55),
    Text = Color3.fromRGB(240, 240, 245),
    TextMuted = Color3.fromRGB(140, 140, 155),
    TextDim = Color3.fromRGB(80, 80, 95),
    Success = Color3.fromRGB(50, 205, 100),
    Warning = Color3.fromRGB(255, 180, 0),
    Info = Color3.fromRGB(50, 150, 255),
    Error = Color3.fromRGB(255, 60, 60),
}

-- ScreenGui
local ScreenGui = Create("ScreenGui", {
    Parent = game:GetService("CoreGui"),
    Name = "ObsidianUI_Compact",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
})

-- Shadow backdrop
local Shadow = Create("Frame", {
    Parent = ScreenGui,
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.6,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 0,
    BorderSizePixel = 0,
})

-- Main Window (COMPACT: 720x480)
local MainWindow = Create("Frame", {
    Parent = ScreenGui,
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 720, 0, 480),
    Position = UDim2.new(0.5, -360, 0.5, -240),
    ZIndex = 1,
})
Create("UICorner", { Parent = MainWindow, CornerRadius = UDim.new(0, 8) })
Create("UIStroke", { Parent = MainWindow, Color = Theme.Border, Thickness = 1 })

-- ========== TOPBAR ==========
local Topbar = Create("Frame", {
    Parent = MainWindow,
    BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 46),
    ZIndex = 2,
})
Create("UICorner", { Parent = Topbar, CornerRadius = UDim.new(0, 8) })

-- Logo + Title
CreateIcon(Topbar, Icons.shield, 20, Theme.Primary, 3).Position = UDim2.new(0, 12, 0.5, -10)

Create("TextLabel", {
    Parent = Topbar,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 40, 0, 0),
    Size = UDim2.new(0, 180, 1, 0),
    Text = "OBSIDIAN",
    TextColor3 = Theme.Text,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3,
})

Create("TextLabel", {
    Parent = Topbar,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 125, 0, 0),
    Size = UDim2.new(0, 100, 1, 0),
    Text = "v2.0 COMPACT",
    TextColor3 = Theme.Primary,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3,
})

-- Close Button
local CloseBtn = Create("TextButton", {
    Parent = Topbar,
    BackgroundColor3 = Theme.Surface2,
    Position = UDim2.new(1, -38, 0.5, -14),
    Size = UDim2.new(0, 28, 0, 28),
    Text = "",
    ZIndex = 3,
})
Create("UICorner", { Parent = CloseBtn, CornerRadius = UDim.new(0, 6) })
CreateIcon(CloseBtn, Icons.x, 16, Theme.Error, 4).Position = UDim2.new(0.5, -8, 0.5, -8)

CloseBtn.MouseButton1Click:Connect(function()
    Tween(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
    })
    Tween(Shadow, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
    wait(0.4)
    ScreenGui:Destroy()
end)

-- Minimize Button
local MinBtn = Create("TextButton", {
    Parent = Topbar,
    BackgroundColor3 = Theme.Surface2,
    Position = UDim2.new(1, -72, 0.5, -14),
    Size = UDim2.new(0, 28, 0, 28),
    Text = "",
    ZIndex = 3,
})
Create("UICorner", { Parent = MinBtn, CornerRadius = UDim.new(0, 6) })
CreateIcon(MinBtn, Icons.minimize, 16, Theme.Warning, 4).Position = UDim2.new(0.5, -8, 0.5, -8)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Tween(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 720, 0, 46),
        })
    else
        Tween(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 720, 0, 480),
        })
    end
end)

MakeDraggable(MainWindow, Topbar)

-- ========== SIDEBAR ==========
local Sidebar = Create("Frame", {
    Parent = MainWindow,
    BackgroundColor3 = Theme.Surface,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 46),
    Size = UDim2.new(0, 60, 1, -46),
    ZIndex = 2,
})

local sidebarButtons = {
    { icon = Icons.home, name = "Home" },
    { icon = Icons.shield, name = "Combat" },
    { icon = Icons.user, name = "Player" },
    { icon = Icons.eye, name = "Visual" },
    { icon = Icons.terminal, name = "Misc" },
    { icon = Icons.settings, name = "Config" },
}

local selectedTab = 1

for i, btn in ipairs(sidebarButtons) do
    local tabBtn = Create("TextButton", {
        Parent = Sidebar,
        BackgroundColor3 = i == 1 and Theme.Surface2 or Theme.Surface,
        Position = UDim2.new(0, 8, 0, (i-1)*54 + 8),
        Size = UDim2.new(0, 44, 0, 44),
        Text = "",
        ZIndex = 3,
    })
    Create("UICorner", { Parent = tabBtn, CornerRadius = UDim.new(0, 8) })
    
    if i == 1 then
        Create("UIStroke", { Parent = tabBtn, Color = Theme.Primary, Thickness = 1.5 })
    end

    local icon = CreateIcon(tabBtn, btn.icon, 22, i == 1 and Theme.Primary or Theme.TextMuted, 4)
    icon.Position = UDim2.new(0.5, -11, 0.5, -11)

    tabBtn.MouseButton1Click:Connect(function()
        for _, otherBtn in pairs(Sidebar:GetChildren()) do
            if otherBtn:IsA("TextButton") then
                Tween(otherBtn, TweenInfo.new(0.2), { BackgroundColor3 = Theme.Surface })
                local otherIcon = otherBtn:FindFirstChildOfClass("ImageLabel")
                if otherIcon then
                    Tween(otherIcon, TweenInfo.new(0.2), { ImageColor3 = Theme.TextMuted })
                end
                local stroke = otherBtn:FindFirstChildOfClass("UIStroke")
                if stroke then stroke:Destroy() end
            end
        end
        
        Tween(tabBtn, TweenInfo.new(0.2), { BackgroundColor3 = Theme.Surface2 })
        Tween(icon, TweenInfo.new(0.2), { ImageColor3 = Theme.Primary })
        Create("UIStroke", { Parent = tabBtn, Color = Theme.Primary, Thickness = 1.5 })
        
        selectedTab = i
    end)

    -- Hover effect
    tabBtn.MouseEnter:Connect(function()
        if selectedTab ~= i then
            Tween(tabBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Surface2 })
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if selectedTab ~= i then
            Tween(tabBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Surface })
        end
    end)
end

-- ========== CONTENT AREA ==========
local Content = Create("ScrollingFrame", {
    Parent = MainWindow,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 68, 0, 54),
    Size = UDim2.new(1, -76, 1, -62),
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Theme.Primary,
    CanvasSize = UDim2.new(0, 0, 0, 1200),
    ZIndex = 2,
})

-- ========== COMBAT SECTION ==========
local function CreateSection(title, iconId, posY)
    local section = Create("Frame", {
        Parent = Content,
        BackgroundColor3 = Theme.Surface,
        Position = UDim2.new(0, 8, 0, posY),
        Size = UDim2.new(1, -16, 0, 180),
        ZIndex = 3,
    })
    Create("UICorner", { Parent = section, CornerRadius = UDim.new(0, 8) })
    Create("UIStroke", { Parent = section, Color = Theme.Border, Thickness = 1 })

    -- Header
    CreateIcon(section, iconId, 16, Theme.Primary, 4).Position = UDim2.new(0, 12, 0, 12)
    
    Create("TextLabel", {
        Parent = section,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 36, 0, 8),
        Size = UDim2.new(1, -48, 0, 24),
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    })

    return section
end

local function CreateToggle(parent, text, iconId, posX, posY)
    local toggle = Create("Frame", {
        Parent = parent,
        BackgroundColor3 = Theme.Surface2,
        Position = UDim2.new(0, posX, 0, posY),
        Size = UDim2.new(0, 190, 0, 38),
        ZIndex = 4,
    })
    Create("UICorner", { Parent = toggle, CornerRadius = UDim.new(0, 6) })

    CreateIcon(toggle, iconId, 16, Theme.TextMuted, 5).Position = UDim2.new(0, 10, 0.5, -8)

    Create("TextLabel", {
        Parent = toggle,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 34, 0, 0),
        Size = UDim2.new(1, -100, 1, 0),
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    local toggleBtn = Create("TextButton", {
        Parent = toggle,
        BackgroundColor3 = Theme.Surface3,
        Position = UDim2.new(1, -48, 0.5, -10),
        Size = UDim2.new(0, 38, 0, 20),
        Text = "",
        ZIndex = 5,
    })
    Create("UICorner", { Parent = toggleBtn, CornerRadius = UDim.new(1, 0) })

    local indicator = Create("Frame", {
        Parent = toggleBtn,
        BackgroundColor3 = Theme.TextDim,
        Position = UDim2.new(0, 2, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        ZIndex = 6,
    })
    Create("UICorner", { Parent = indicator, CornerRadius = UDim.new(1, 0) })

    local enabled = false
    toggleBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            Tween(toggleBtn, TweenInfo.new(0.2), { BackgroundColor3 = Theme.Primary })
            Tween(indicator, TweenInfo.new(0.2), { 
                Position = UDim2.new(1, -18, 0.5, -8),
                BackgroundColor3 = Theme.Text 
            })
        else
            Tween(toggleBtn, TweenInfo.new(0.2), { BackgroundColor3 = Theme.Surface3 })
            Tween(indicator, TweenInfo.new(0.2), { 
                Position = UDim2.new(0, 2, 0.5, -8),
                BackgroundColor3 = Theme.TextDim 
            })
        end
    end)

    return toggle
end

local function CreateSlider(parent, text, iconId, posX, posY, min, max, default)
    local slider = Create("Frame", {
        Parent = parent,
        BackgroundColor3 = Theme.Surface2,
        Position = UDim2.new(0, posX, 0, posY),
        Size = UDim2.new(0, 190, 0, 50),
        ZIndex = 4,
    })
    Create("UICorner", { Parent = slider, CornerRadius = UDim.new(0, 6) })

    CreateIcon(slider, iconId, 14, Theme.TextMuted, 5).Position = UDim2.new(0, 10, 0, 8)

    local label = Create("TextLabel", {
        Parent = slider,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 32, 0, 4),
        Size = UDim2.new(1, -80, 0, 20),
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    local valueLabel = Create("TextLabel", {
        Parent = slider,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -45, 0, 4),
        Size = UDim2.new(0, 40, 0, 20),
        Text = tostring(default),
        TextColor3 = Theme.Primary,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 5,
    })

    local sliderBar = Create("Frame", {
        Parent = slider,
        BackgroundColor3 = Theme.Surface3,
        Position = UDim2.new(0, 10, 1, -16),
        Size = UDim2.new(1, -20, 0, 6),
        ZIndex = 5,
    })
    Create("UICorner", { Parent = sliderBar, CornerRadius = UDim.new(1, 0) })

    local fill = Create("Frame", {
        Parent = sliderBar,
        BackgroundColor3 = Theme.Primary,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        ZIndex = 6,
    })
    Create("UICorner", { Parent = fill, CornerRadius = UDim.new(1, 0) })

    local knob = Create("Frame", {
        Parent = sliderBar,
        BackgroundColor3 = Theme.Text,
        Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6),
        Size = UDim2.new(0, 12, 0, 12),
        ZIndex = 7,
    })
    Create("UICorner", { Parent = knob, CornerRadius = UDim.new(1, 0) })

    local dragging = false
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = math.clamp((Mouse.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * pos)
            
            fill.Size = UDim2.new(pos, 0, 1, 0)
            knob.Position = UDim2.new(pos, -6, 0.5, -6)
            valueLabel.Text = tostring(value)
        end
    end)

    return slider
end

-- Combat Section
local combatSection = CreateSection("COMBAT FEATURES", Icons.target, 8)
CreateToggle(combatSection, "Silent Aim", Icons.target, 12, 40)
CreateToggle(combatSection, "Triggerbot", Icons.zap, 216, 40)
CreateToggle(combatSection, "Anti-Recoil", Icons.activity, 420, 40)

CreateSlider(combatSection, "Aim FOV", Icons.eye, 12, 88, 0, 360, 120)
CreateSlider(combatSection, "Smoothness", Icons.activity, 216, 88, 0, 100, 50)
CreateSlider(combatSection, "Hitbox Size", Icons.target, 420, 88, 1, 10, 3)

-- Visual Section
local visualSection = CreateSection("VISUAL ESP", Icons.eye, 196)
CreateToggle(visualSection, "Box ESP", Icons.package, 12, 40)
CreateToggle(visualSection, "Name ESP", Icons.user, 216, 40)
CreateToggle(visualSection, "Health ESP", Icons.activity, 420, 40)

CreateSlider(visualSection, "Distance", Icons.eye, 12, 88, 0, 500, 200)
CreateSlider(visualSection, "Opacity", Icons.layers, 216, 88, 0, 100, 80)
CreateToggle(visualSection, "Team Check", Icons.shield, 420, 88)

-- Movement Section
local movementSection = CreateSection("MOVEMENT", Icons.zap, 384)
CreateToggle(movementSection, "Speed Hack", Icons.zap, 12, 40)
CreateToggle(movementSection, "Fly Mode", Icons.upload, 216, 40)
CreateToggle(movementSection, "No Clip", Icons.radio, 420, 40)

CreateSlider(movementSection, "Walk Speed", Icons.zap, 12, 88, 16, 200, 16)
CreateSlider(movementSection, "Jump Power", Icons.upload, 216, 88, 50, 200, 50)
CreateToggle(movementSection, "Infinite Jump", Icons.chevronup, 420, 88)

-- Misc Section
local miscSection = CreateSection("UTILITIES", Icons.terminal, 572)
CreateToggle(miscSection, "Anti-AFK", Icons.clock, 12, 40)
CreateToggle(miscSection, "Auto-Farm", Icons.download, 216, 40)
CreateToggle(miscSection, "God Mode", Icons.shield, 420, 40)

CreateToggle(miscSection, "Full Bright", Icons.eye, 12, 88)
CreateToggle(miscSection, "Remove FOG", Icons.globe, 216, 88)
CreateToggle(miscSection, "Unlock FPS", Icons.activity, 420, 88)

-- ========== STATUS BAR ==========
local StatusBar = Create("Frame", {
    Parent = MainWindow,
    BackgroundColor3 = Theme.Surface,
    Position = UDim2.new(0, 68, 1, -32),
    Size = UDim2.new(1, -76, 0, 32),
    ZIndex = 3,
})
Create("UICorner", { Parent = StatusBar, CornerRadius = UDim.new(0, 6) })

CreateIcon(StatusBar, Icons.cpu, 14, Theme.Success, 4).Position = UDim2.new(0, 10, 0.5, -7)

local fpsLabel = Create("TextLabel", {
    Parent = StatusBar,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 32, 0, 0),
    Size = UDim2.new(0, 100, 1, 0),
    Text = "FPS: 144",
    TextColor3 = Theme.Success,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
})

CreateIcon(StatusBar, Icons.activity, 14, Theme.Info, 4).Position = UDim2.new(0, 140, 0.5, -7)

local pingLabel = Create("TextLabel", {
    Parent = StatusBar,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 162, 0, 0),
    Size = UDim2.new(0, 100, 1, 0),
    Text = "PING: 23ms",
    TextColor3 = Theme.Info,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
})

CreateIcon(StatusBar, Icons.check, 14, Theme.Success, 4).Position = UDim2.new(1, -100, 0.5, -7)

Create("TextLabel", {
    Parent = StatusBar,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -78, 0, 0),
    Size = UDim2.new(0, 70, 1, 0),
    Text = "UNDETECTED",
    TextColor3 = Theme.Success,
    TextSize = 9,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
})

-- Update FPS/Ping live
spawn(function()
    while StatusBar and StatusBar.Parent do
        wait(0.5)
        local fps = math.floor(1 / RunService.Heartbeat:Wait())
        fpsLabel.Text = "FPS: " .. fps
        
        local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        pingLabel.Text = "PING: " .. math.floor(ping) .. "ms"
    end
end)

-- ========== NOTIFICATION SYSTEM ==========
local function ShowToast(title, message, notifType)
    local typeColors = {
        success = Theme.Success,
        warning = Theme.Warning,
        error = Theme.Error,
        info = Theme.Info,
    }
    local typeIcons = {
        success = Icons.check,
        warning = Icons.alerttriangle,
        error = Icons.x,
        info = Icons.info,
    }
    local color = typeColors[notifType] or Theme.Info
    local iconId = typeIcons[notifType] or Icons.info

    local toast = Create("Frame", {
        Parent = ScreenGui,
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 10, 1, -70),
        Size = UDim2.new(0, 260, 0, 56),
        ZIndex = 100,
    })
    Create("UICorner", { Parent = toast, CornerRadius = UDim.new(0, 8) })
    Create("UIStroke", { Parent = toast, Color = color, Thickness = 1.5 })

    local iconBg = Create("Frame", {
        Parent = toast,
        BackgroundColor3 = color,
        BackgroundTransparency = 0.85,
        Position = UDim2.new(0, 10, 0.5, -12),
        Size = UDim2.new(0, 24, 0, 24),
        ZIndex = 101,
    })
    Create("UICorner", { Parent = iconBg, CornerRadius = UDim.new(1, 0) })
    CreateIcon(iconBg, iconId, 14, color, 102).Position = UDim2.new(0.5, -7, 0.5, -7)

    Create("TextLabel", {
        Parent = toast,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0, 8),
        Size = UDim2.new(1, -50, 0, 16),
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 101,
    })
    
    Create("TextLabel", {
        Parent = toast,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0, 26),
        Size = UDim2.new(1, -50, 0, 22),
        Text = message,
        TextColor3 = Theme.TextMuted,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = 101,
    })

    Tween(toast, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -270, 1, -70),
    })
    wait(3)
    Tween(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 10, 1, -70),
        BackgroundTransparency = 1,
    })
    wait(0.35)
    toast:Destroy()
end

-- ========== INTRO ANIMATION ==========
MainWindow.Size = UDim2.new(0, 0, 0, 0)
MainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
Shadow.BackgroundTransparency = 1

Tween(Shadow, TweenInfo.new(0.3), { BackgroundTransparency = 0.6 })
Tween(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 720, 0, 480),
    Position = UDim2.new(0.5, -360, 0.5, -240),
})

-- ========== KEYBIND TO TOGGLE ==========
local guiVisible = true
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        guiVisible = not guiVisible
        MainWindow.Visible = guiVisible
        Shadow.Visible = guiVisible
    end
end)

-- Welcome notification
spawn(function()
    wait(1)
    ShowToast("Obsidian Compact", "v2.0 carregado com sucesso!", "success")
end)

-- ========== API ==========
ObsidianUI.ShowToast = ShowToast
ObsidianUI.ScreenGui = ScreenGui
ObsidianUI.MainWindow = MainWindow

print("[ObsidianUI] Compact v2.0 ✓")
print("[Toggle] RightShift")

return ObsidianUI
