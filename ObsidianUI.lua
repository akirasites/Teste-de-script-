-- ObsidianUI Premium v1.0
-- Single file Lua UI Library clone
-- Compatible with Roblox executors

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

local function RippleEffect(button, color)
    color = color or Color3.fromRGB(255, 100, 0)
    local ripple = Create("Frame", {
        Parent = button,
        BackgroundColor3 = color,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = button.ZIndex + 10,
        ClipsDescendants = false,
    })
    Create("UICorner", { Parent = ripple, CornerRadius = UDim.new(1, 0) })

    local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    Tween(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, size, 0, size),
        BackgroundTransparency = 1,
    })
    game:GetService("Debris"):AddItem(ripple, 0.6)
end

-- Theme
local Themes = {
    Obsidian = {
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
        Accent2 = Color3.fromRGB(180, 80, 255),
    },
    Crimson = {
        Primary = Color3.fromRGB(200, 30, 60),
        PrimaryDark = Color3.fromRGB(150, 20, 40),
        Background = Color3.fromRGB(13, 10, 12),
        Surface = Color3.fromRGB(22, 15, 18),
        Surface2 = Color3.fromRGB(30, 20, 25),
        Surface3 = Color3.fromRGB(40, 28, 33),
        Border = Color3.fromRGB(55, 35, 42),
        Text = Color3.fromRGB(240, 235, 237),
        TextMuted = Color3.fromRGB(140, 120, 128),
        TextDim = Color3.fromRGB(80, 65, 72),
        Success = Color3.fromRGB(50, 205, 100),
        Warning = Color3.fromRGB(255, 180, 0),
        Info = Color3.fromRGB(50, 150, 255),
        Error = Color3.fromRGB(255, 60, 60),
        Accent2 = Color3.fromRGB(200, 50, 80),
    },
    Amethyst = {
        Primary = Color3.fromRGB(140, 60, 220),
        PrimaryDark = Color3.fromRGB(100, 40, 170),
        Background = Color3.fromRGB(12, 10, 18),
        Surface = Color3.fromRGB(20, 16, 30),
        Surface2 = Color3.fromRGB(28, 22, 42),
        Surface3 = Color3.fromRGB(38, 30, 55),
        Border = Color3.fromRGB(55, 42, 75),
        Text = Color3.fromRGB(238, 235, 245),
        TextMuted = Color3.fromRGB(138, 128, 158),
        TextDim = Color3.fromRGB(78, 68, 95),
        Success = Color3.fromRGB(50, 205, 100),
        Warning = Color3.fromRGB(255, 180, 0),
        Info = Color3.fromRGB(50, 150, 255),
        Error = Color3.fromRGB(255, 60, 60),
        Accent2 = Color3.fromRGB(180, 80, 255),
    },
    Ocean = {
        Primary = Color3.fromRGB(30, 140, 220),
        PrimaryDark = Color3.fromRGB(20, 100, 170),
        Background = Color3.fromRGB(8, 14, 22),
        Surface = Color3.fromRGB(12, 22, 35),
        Surface2 = Color3.fromRGB(18, 32, 48),
        Surface3 = Color3.fromRGB(25, 42, 62),
        Border = Color3.fromRGB(35, 58, 82),
        Text = Color3.fromRGB(230, 240, 250),
        TextMuted = Color3.fromRGB(120, 155, 185),
        TextDim = Color3.fromRGB(65, 95, 120),
        Success = Color3.fromRGB(50, 205, 100),
        Warning = Color3.fromRGB(255, 180, 0),
        Info = Color3.fromRGB(50, 200, 255),
        Error = Color3.fromRGB(255, 60, 60),
        Accent2 = Color3.fromRGB(50, 180, 230),
    },
    Matrix = {
        Primary = Color3.fromRGB(0, 200, 80),
        PrimaryDark = Color3.fromRGB(0, 150, 55),
        Background = Color3.fromRGB(5, 12, 8),
        Surface = Color3.fromRGB(8, 20, 12),
        Surface2 = Color3.fromRGB(12, 28, 18),
        Surface3 = Color3.fromRGB(18, 38, 25),
        Border = Color3.fromRGB(25, 55, 35),
        Text = Color3.fromRGB(200, 245, 215),
        TextMuted = Color3.fromRGB(90, 160, 115),
        TextDim = Color3.fromRGB(45, 95, 65),
        Success = Color3.fromRGB(0, 220, 90),
        Warning = Color3.fromRGB(200, 220, 0),
        Info = Color3.fromRGB(0, 200, 150),
        Error = Color3.fromRGB(255, 60, 60),
        Accent2 = Color3.fromRGB(0, 230, 100),
    },
}

local CurrentTheme = Themes.Obsidian

-- ScreenGui
local ScreenGui = Create("ScreenGui", {
    Parent = game:GetService("CoreGui"),
    Name = "ObsidianUI_Premium",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
})

-- Shadow backdrop
local Shadow = Create("Frame", {
    Parent = ScreenGui,
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.5,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 0,
    BorderSizePixel = 0,
    Name = "Shadow",
})

-- Main Window
local MainWindow = Create("Frame", {
    Parent = ScreenGui,
    Name = "MainWindow",
    BackgroundColor3 = CurrentTheme.Background,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 1060, 0, 680),
    Position = UDim2.new(0.5, -530, 0.5, -340),
    ZIndex = 1,
    ClipsDescendants = false,
})
Create("UICorner", { Parent = MainWindow, CornerRadius = UDim.new(0, 10) })
Create("UIStroke", { Parent = MainWindow, Color = CurrentTheme.Border, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })

MakeDraggable(MainWindow)

-- Glow effect on window
local WinGlow = Create("ImageLabel", {
    Parent = MainWindow,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 60, 1, 60),
    Position = UDim2.new(0, -30, 0, -30),
    Image = "rbxassetid://5028857084",
    ImageColor3 = CurrentTheme.Primary,
    ImageTransparency = 0.85,
    ZIndex = 0,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(24, 24, 276, 276),
})

-- =================== TOPBAR ===================
local TopBar = Create("Frame", {
    Parent = MainWindow,
    Name = "TopBar",
    BackgroundColor3 = CurrentTheme.Surface,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 55),
    ZIndex = 2,
})
Create("UICorner", { Parent = TopBar, CornerRadius = UDim.new(0, 10) })

-- Mask bottom corners of topbar
local TopBarMask = Create("Frame", {
    Parent = TopBar,
    BackgroundColor3 = CurrentTheme.Surface,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 15),
    Position = UDim2.new(0, 0, 1, -15),
    ZIndex = 2,
})

-- Logo area
local LogoFrame = Create("Frame", {
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 220, 1, 0),
    ZIndex = 3,
})

local LogoIcon = Create("Frame", {
    Parent = LogoFrame,
    BackgroundColor3 = CurrentTheme.Primary,
    Size = UDim2.new(0, 34, 0, 34),
    Position = UDim2.new(0, 12, 0.5, -17),
    ZIndex = 4,
})
Create("UICorner", { Parent = LogoIcon, CornerRadius = UDim.new(0, 8) })
Create("UIGradient", {
    Parent = LogoIcon,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 130, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 0)),
    }),
    Rotation = 135,
})

local LogoGem = Create("TextLabel", {
    Parent = LogoIcon,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    Text = "◆",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    ZIndex = 5,
})

local LogoText = Create("TextLabel", {
    Parent = LogoFrame,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 54, 0, 8),
    Size = UDim2.new(0, 140, 0, 20),
    Text = "OBSIDIAN UI",
    TextColor3 = CurrentTheme.Text,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
})

local LogoSub = Create("TextLabel", {
    Parent = LogoFrame,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 54, 0, 28),
    Size = UDim2.new(0, 140, 0, 14),
    Text = "PREMIUM • V1.0",
    TextColor3 = CurrentTheme.Primary,
    TextSize = 9,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
})

-- Search bar
local SearchFrame = Create("Frame", {
    Parent = TopBar,
    BackgroundColor3 = CurrentTheme.Surface2,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 380, 0, 34),
    Position = UDim2.new(0.5, -190, 0.5, -17),
    ZIndex = 3,
})
Create("UICorner", { Parent = SearchFrame, CornerRadius = UDim.new(0, 8) })
Create("UIStroke", { Parent = SearchFrame, Color = CurrentTheme.Border, Thickness = 1 })

local SearchIcon = Create("TextLabel", {
    Parent = SearchFrame,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 0),
    Size = UDim2.new(0, 24, 1, 0),
    Text = "🔍",
    TextSize = 13,
    ZIndex = 4,
})

local SearchBox = Create("TextBox", {
    Parent = SearchFrame,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 36, 0, 0),
    Size = UDim2.new(1, -100, 1, 0),
    Text = "",
    PlaceholderText = "Search anything...",
    TextColor3 = CurrentTheme.Text,
    PlaceholderColor3 = CurrentTheme.TextDim,
    TextSize = 13,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
})

local SearchHint = Create("Frame", {
    Parent = SearchFrame,
    BackgroundColor3 = CurrentTheme.Surface3,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 72, 0, 22),
    Position = UDim2.new(1, -80, 0.5, -11),
    ZIndex = 4,
})
Create("UICorner", { Parent = SearchHint, CornerRadius = UDim.new(0, 5) })

local SearchHintText = Create("TextLabel", {
    Parent = SearchHint,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    Text = "CTRL  K",
    TextColor3 = CurrentTheme.TextMuted,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    ZIndex = 5,
})

-- Right controls
local RightControls = Create("Frame", {
    Parent = TopBar,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -175, 0, 0),
    Size = UDim2.new(0, 175, 1, 0),
    ZIndex = 3,
})

local function MakeTopBtn(parent, x, icon, hasBadge, badgeNum)
    local btn = Create("TextButton", {
        Parent = parent,
        BackgroundColor3 = CurrentTheme.Surface2,
        BorderSizePixel = 0,
        Position = UDim2.new(0, x, 0.5, -16),
        Size = UDim2.new(0, 32, 0, 32),
        Text = icon,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextColor3 = CurrentTheme.TextMuted,
        ZIndex = 4,
    })
    Create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 8) })

    btn.MouseEnter:Connect(function()
        Tween(btn, TweenInfo.new(0.15), { BackgroundColor3 = CurrentTheme.Surface3, TextColor3 = CurrentTheme.Text })
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, TweenInfo.new(0.15), { BackgroundColor3 = CurrentTheme.Surface2, TextColor3 = CurrentTheme.TextMuted })
    end)

    if hasBadge then
        local badge = Create("Frame", {
            Parent = btn,
            BackgroundColor3 = CurrentTheme.Primary,
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(1, -8, 0, -4),
            ZIndex = 6,
        })
        Create("UICorner", { Parent = badge, CornerRadius = UDim.new(1, 0) })
        Create("TextLabel", {
            Parent = badge,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = tostring(badgeNum or 1),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 9,
            Font = Enum.Font.GothamBold,
            ZIndex = 7,
        })
    end
    return btn
end

MakeTopBtn(RightControls, 0, "🔔", false)
MakeTopBtn(RightControls, 42, "💬", true, 3)

-- Window control buttons
local WinControls = Create("Frame", {
    Parent = RightControls,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 88, 0.5, -12),
    Size = UDim2.new(0, 80, 0, 24),
    ZIndex = 4,
})

local function MakeWinBtn(parent, x, icon, color, action)
    local btn = Create("TextButton", {
        Parent = parent,
        BackgroundColor3 = CurrentTheme.Surface2,
        BorderSizePixel = 0,
        Position = UDim2.new(0, x, 0, 0),
        Size = UDim2.new(0, 22, 0, 22),
        Text = icon,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextColor3 = CurrentTheme.TextMuted,
        ZIndex = 5,
    })
    Create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 6) })

    btn.MouseEnter:Connect(function()
        Tween(btn, TweenInfo.new(0.15), { BackgroundColor3 = color or CurrentTheme.Surface3 })
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, TweenInfo.new(0.15), { BackgroundColor3 = CurrentTheme.Surface2 })
    end)

    if action then
        btn.MouseButton1Click:Connect(action)
    end
    return btn
end

MakeWinBtn(WinControls, 0, "—", Color3.fromRGB(60, 60, 70), function()
    MainWindow.Visible = false
    Shadow.Visible = false
end)
MakeWinBtn(WinControls, 28, "⊡", Color3.fromRGB(40, 100, 50))
MakeWinBtn(WinControls, 56, "✕", Color3.fromRGB(150, 30, 30), function()
    ScreenGui:Destroy()
end)

-- Divider under topbar
Create("Frame", {
    Parent = TopBar,
    BackgroundColor3 = CurrentTheme.Border,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -1),
    Size = UDim2.new(1, 0, 0, 1),
    ZIndex = 3,
})

-- =================== SIDEBAR ===================
local Sidebar = Create("Frame", {
    Parent = MainWindow,
    Name = "Sidebar",
    BackgroundColor3 = CurrentTheme.Surface,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 55),
    Size = UDim2.new(0, 220, 1, -55),
    ZIndex = 2,
})
Create("UICorner", { Parent = Sidebar, CornerRadius = UDim.new(0, 10) })
-- Mask top-right corner
Create("Frame", {
    Parent = Sidebar,
    BackgroundColor3 = CurrentTheme.Surface,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 20, 0, 20),
    Position = UDim2.new(1, -20, 0, 0),
    ZIndex = 2,
})

-- Right border on sidebar
Create("Frame", {
    Parent = Sidebar,
    BackgroundColor3 = CurrentTheme.Border,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -1, 0, 0),
    Size = UDim2.new(0, 1, 1, 0),
    ZIndex = 3,
})

-- Nav items
local NavItems = {
    { icon = "⌂", label = "Dashboard", active = true },
    { icon = "⚔", label = "Combat" },
    { icon = "↗", label = "Movement" },
    { icon = "◉", label = "Visuals" },
    { icon = "👤", label = "Players" },
    { icon = "🌐", label = "World" },
    { icon = "🎒", label = "Inventory" },
    { icon = "⚙", label = "Miscellaneous" },
    { icon = "⚙", label = "Settings" },
}

local ActiveNavBtn = nil
local NavButtons = {}

local NavList = Create("Frame", {
    Parent = Sidebar,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 18),
    Size = UDim2.new(1, 0, 1, -100),
    ZIndex = 3,
})

for i, item in ipairs(NavItems) do
    local isActive = item.active == true
    local btn = Create("TextButton", {
        Parent = NavList,
        BackgroundColor3 = isActive and CurrentTheme.Primary or Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = isActive and 0 or 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, (i - 1) * 52 + 2),
        Size = UDim2.new(1, -24, 0, 44),
        Text = "",
        ZIndex = 4,
    })
    Create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 8) })

    if isActive then
        Create("UIGradient", {
            Parent = btn,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 130, 30)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 0)),
            }),
            Rotation = 90,
        })
    end

    local iconLbl = Create("TextLabel", {
        Parent = btn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0, 24, 1, 0),
        Text = item.icon,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or CurrentTheme.TextMuted,
        ZIndex = 5,
    })

    local labelLbl = Create("TextLabel", {
        Parent = btn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 44, 0, 0),
        Size = UDim2.new(1, -50, 1, 0),
        Text = item.label,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or CurrentTheme.TextMuted,
        ZIndex = 5,
    })

    if isActive then
        ActiveNavBtn = { btn = btn, icon = iconLbl, label = labelLbl }
    end

    NavButtons[i] = { btn = btn, icon = iconLbl, label = labelLbl, item = item }

    btn.MouseEnter:Connect(function()
        if not item.active then
            Tween(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.9, BackgroundColor3 = CurrentTheme.Surface2 })
            Tween(iconLbl, TweenInfo.new(0.15), { TextColor3 = CurrentTheme.Text })
            Tween(labelLbl, TweenInfo.new(0.15), { TextColor3 = CurrentTheme.Text })
        end
    end)
    btn.MouseLeave:Connect(function()
        if not item.active then
            Tween(btn, TweenInfo.new(0.15), { BackgroundTransparency = 1 })
            Tween(iconLbl, TweenInfo.new(0.15), { TextColor3 = CurrentTheme.TextMuted })
            Tween(labelLbl, TweenInfo.new(0.15), { TextColor3 = CurrentTheme.TextMuted })
        end
    end)

    btn.MouseButton1Click:Connect(function()
        RippleEffect(btn, CurrentTheme.Primary)
        -- Deactivate all
        for _, nb in pairs(NavButtons) do
            nb.item.active = false
            nb.btn:ClearAllChildren()
            Create("UICorner", { Parent = nb.btn, CornerRadius = UDim.new(0, 8) })
            Tween(nb.btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1 })
            Tween(nb.icon, TweenInfo.new(0.2), { TextColor3 = CurrentTheme.TextMuted })
            Tween(nb.label, TweenInfo.new(0.2), { TextColor3 = CurrentTheme.TextMuted })
        end
        -- Activate this
        item.active = true
        btn:ClearAllChildren()
        Create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 8) })
        Create("UIGradient", {
            Parent = btn,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 130, 30)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 0)),
            }),
            Rotation = 90,
        })
        Tween(btn, TweenInfo.new(0.2), { BackgroundColor3 = CurrentTheme.Primary, BackgroundTransparency = 0 })
        Tween(iconLbl, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(255, 255, 255) })
        Tween(labelLbl, TweenInfo.new(0.2), { TextColor3 = Color3.fromRGB(255, 255, 255) })
    end)
end

-- Profile at bottom of sidebar
local ProfileFrame = Create("Frame", {
    Parent = Sidebar,
    BackgroundColor3 = CurrentTheme.Surface2,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 1, -85),
    Size = UDim2.new(1, -24, 0, 70),
    ZIndex = 4,
})
Create("UICorner", { Parent = ProfileFrame, CornerRadius = UDim.new(0, 10) })

local AvatarFrame = Create("Frame", {
    Parent = ProfileFrame,
    BackgroundColor3 = CurrentTheme.Surface3,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 10, 0.5, -20),
    Size = UDim2.new(0, 40, 0, 40),
    ZIndex = 5,
})
Create("UICorner", { Parent = AvatarFrame, CornerRadius = UDim.new(1, 0) })

local AvatarImg = Create("ImageLabel", {
    Parent = AvatarFrame,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=60&h=60",
    ZIndex = 6,
})
Create("UICorner", { Parent = AvatarImg, CornerRadius = UDim.new(1, 0) })

Create("TextLabel", {
    Parent = ProfileFrame,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 58, 0, 12),
    Size = UDim2.new(1, -68, 0, 20),
    Text = LocalPlayer.DisplayName,
    TextColor3 = CurrentTheme.Text,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 5,
})

Create("TextLabel", {
    Parent = ProfileFrame,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 58, 0, 32),
    Size = UDim2.new(1, -68, 0, 16),
    Text = "Administrator",
    TextColor3 = CurrentTheme.TextMuted,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 5,
})

local StatusDot = Create("Frame", {
    Parent = ProfileFrame,
    BackgroundColor3 = CurrentTheme.Success,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -22, 0.5, -6),
    Size = UDim2.new(0, 12, 0, 12),
    ZIndex = 5,
})
Create("UICorner", { Parent = StatusDot, CornerRadius = UDim.new(1, 0) })

-- Pulse animation on status dot
local pulsing = true
spawn(function()
    while pulsing and StatusDot and StatusDot.Parent do
        Tween(StatusDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Size = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 0.3,
        })
        wait(0.8)
        Tween(StatusDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Size = UDim2.new(0, 13, 0, 13),
            BackgroundTransparency = 0,
        })
        wait(0.8)
    end
end)

-- =================== CONTENT AREA ===================
local Content = Create("Frame", {
    Parent = MainWindow,
    Name = "Content",
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 220, 0, 55),
    Size = UDim2.new(1, -220, 1, -55),
    ZIndex = 2,
    ClipsDescendants = true,
})

local Scroll = Create("ScrollingFrame", {
    Parent = Content,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    CanvasSize = UDim2.new(0, 0, 0, 920),
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = CurrentTheme.Primary,
    BorderSizePixel = 0,
    ZIndex = 2,
    AutomaticCanvasSize = Enum.AutomaticSize.None,
})

-- =================== WELCOME HEADER ===================
local Header = Create("Frame", {
    Parent = Scroll,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 18, 0, 18),
    Size = UDim2.new(1, -36, 0, 70),
    ZIndex = 3,
})

local WelcomeLabel = Create("TextLabel", {
    Parent = Header,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 400, 0, 34),
    Text = "Welcome back, ",
    TextColor3 = CurrentTheme.Text,
    TextSize = 26,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
})

local WelcomeName = Create("TextLabel", {
    Parent = Header,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(0, 600, 0, 34),
    Text = "Welcome back,   " .. LocalPlayer.DisplayName .. ".",
    TextColor3 = CurrentTheme.Text,
    TextSize = 26,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3,
})
-- Overlay the name in orange
local WelcomeOrange = Create("TextLabel", {
    Parent = Header,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 200, 0, 0),
    Size = UDim2.new(0, 300, 0, 34),
    Text = LocalPlayer.DisplayName .. ".",
    TextColor3 = CurrentTheme.Primary,
    TextSize = 26,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 5,
})

-- Recalculate orange text position
spawn(function()
    wait(0.1)
    local baseText = "Welcome back, "
    -- approximate offset: roughly 14.5px per char at size 26
    WelcomeOrange.Position = UDim2.new(0, #baseText * 13.2, 0, 0)
end)

Create("TextLabel", {
    Parent = Header,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 34),
    Size = UDim2.new(0, 400, 0, 22),
    Text = "Premium experience. Infinite possibilities.",
    TextColor3 = CurrentTheme.TextMuted,
    TextSize = 13,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
})

-- Status cards row
local function MakeStatCard(parent, x, icon, topLabel, mainVal, iconColor)
    local card = Create("Frame", {
        Parent = parent,
        BackgroundColor3 = CurrentTheme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.new(0, x, 0, 60),
        Size = UDim2.new(0, 160, 0, 55),
        ZIndex = 4,
    })
    Create("UICorner", { Parent = card, CornerRadius = UDim.new(0, 8) })
    Create("UIStroke", { Parent = card, Color = CurrentTheme.Border, Thickness = 1 })

    local iconFrame = Create("Frame", {
        Parent = card,
        BackgroundColor3 = iconColor,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0.5, -14),
        Size = UDim2.new(0, 28, 0, 28),
        ZIndex = 5,
    })
    Create("UICorner", { Parent = iconFrame, CornerRadius = UDim.new(0, 7) })
    Create("TextLabel", {
        Parent = iconFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = icon,
        TextColor3 = iconColor,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        ZIndex = 6,
    })

    Create("TextLabel", {
        Parent = card,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 44, 0, 8),
        Size = UDim2.new(1, -48, 0, 14),
        Text = topLabel,
        TextColor3 = CurrentTheme.TextMuted,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    Create("TextLabel", {
        Parent = card,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 44, 0, 24),
        Size = UDim2.new(1, -48, 0, 20),
        Text = mainVal,
        TextColor3 = CurrentTheme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    return card
end

local statusData = {
    { icon = "🛡", label = "STATUS", val = "Undetected", color = CurrentTheme.Success },
    { icon = "📦", label = "BUILD", val = "v1.0.0", color = CurrentTheme.Primary },
    { icon = "⏱", label = "UPTIME", val = "00:00:00", color = CurrentTheme.Info },
    { icon = "👥", label = "USERS", val = "1,248", color = CurrentTheme.Accent2 },
}

local uptimeSeconds = 0
local uptimeLabel = nil
for i, sd in ipairs(statusData) do
    local card = MakeStatCard(Header, (i - 1) * 168, sd.icon, sd.label, sd.val, sd.color)
    if sd.label == "UPTIME" then
        -- find the value label
        for _, ch in pairs(card:GetChildren()) do
            if ch:IsA("TextLabel") and ch.Text == "00:00:00" then
                uptimeLabel = ch
                break
            end
        end
    end
end

-- Uptime ticker
spawn(function()
    while true do
        wait(1)
        uptimeSeconds = uptimeSeconds + 1
        if uptimeLabel and uptimeLabel.Parent then
            local h = math.floor(uptimeSeconds / 3600)
            local m = math.floor((uptimeSeconds % 3600) / 60)
            local s = uptimeSeconds % 60
            uptimeLabel.Text = string.format("%02d:%02d:%02d", h, m, s)
        end
    end
end)

-- =================== THREE COLUMN LAYOUT ===================
local ColY = 130

-- ===== COLUMN 1: Quick Actions + Notifications =====
local Col1 = Create("Frame", {
    Parent = Scroll,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 18, 0, ColY),
    Size = UDim2.new(0, 232, 0, 560),
    ZIndex = 3,
})

-- QUICK ACTIONS CARD
local QACard = Create("Frame", {
    Parent = Col1,
    BackgroundColor3 = CurrentTheme.Surface,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 258),
    ZIndex = 4,
})
Create("UICorner", { Parent = QACard, CornerRadius = UDim.new(0, 10) })
Create("UIStroke", { Parent = QACard, Color = CurrentTheme.Border, Thickness = 1 })

Create("TextLabel", {
    Parent = QACard,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 16, 0, 14),
    Size = UDim2.new(1, -16, 0, 18),
    Text = "QUICK ACTIONS",
    TextColor3 = CurrentTheme.TextMuted,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 5,
})

local quickActions = {
    { icon = "⚡", label = "Execute Script", highlight = true },
    { icon = "🗑", label = "Clear Console" },
    { icon = "↺", label = "Rejoin Server" },
    { icon = "🌐", label = "Server Hop" },
}

for i, qa in ipairs(quickActions) do
    local row = Create("TextButton", {
        Parent = QACard,
        BackgroundColor3 = CurrentTheme.Surface2,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 38 + (i - 1) * 52),
        Size = UDim2.new(1, -24, 0, 44),
        Text = "",
        ZIndex = 5,
    })
    Create("UICorner", { Parent = row, CornerRadius = UDim.new(0, 8) })

    Create("TextLabel", {
        Parent = row,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0, 24, 1, 0),
        Text = qa.icon,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextColor3 = qa.highlight and CurrentTheme.Primary or CurrentTheme.TextMuted,
        ZIndex = 6,
    })

    Create("TextLabel", {
        Parent = row,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 40, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Text = qa.label,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextColor3 = CurrentTheme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    })

    -- Arrow button
    local arrowBtn = Create("TextButton", {
        Parent = row,
        BackgroundColor3 = qa.highlight and CurrentTheme.Primary or CurrentTheme.Surface3,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -38, 0.5, -12),
        Size = UDim2.new(0, 26, 0, 24),
        Text = "›",
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 7,
    })
    Create("UICorner", { Parent = arrowBtn, CornerRadius = UDim.new(0, 6) })

    if qa.highlight then
        Create("UIGradient", {
            Parent = arrowBtn,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 130, 30)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 0)),
            }),
            Rotation = 135,
        })
    end

    row.MouseEnter:Connect(function()
        Tween(row, TweenInfo.new(0.15), { BackgroundColor3 = CurrentTheme.Surface3 })
    end)
    row.MouseLeave:Connect(function()
        Tween(row, TweenInfo.new(0.15), { BackgroundColor3 = CurrentTheme.Surface2 })
    end)
    row.MouseButton1Click:Connect(function()
        RippleEffect(row, CurrentTheme.Primary)
    end)
    arrowBtn.MouseButton1Click:Connect(function()
        RippleEffect(arrowBtn, CurrentTheme.Primary)
    end)
end

-- NOTIFICATIONS CARD
local NotifCard = Create("Frame", {
    Parent = Col1,
    BackgroundColor3 = CurrentTheme.Surface,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 268),
    Size = UDim2.new(1, 0, 0, 248),
    ZIndex = 4,
})
Create("UICorner", { Parent = NotifCard, CornerRadius = UDim.new(0, 10) })
Create("UIStroke", { Parent = NotifCard, Color = CurrentTheme.Border, Thickness = 1 })

local NotifHeader = Create("Frame", {
    Parent = NotifCard,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 36),
    ZIndex = 5,
})

Create("TextLabel", {
    Parent = NotifHeader,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 16, 0, 10),
    Size = UDim2.new(0, 120, 0, 16),
    Text = "NOTIFICATIONS",
    TextColor3 = CurrentTheme.TextMuted,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 6,
})

local ClearAllBtn = Create("TextButton", {
    Parent = NotifHeader,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -80, 0, 8),
    Size = UDim2.new(0, 70, 0, 20),
    Text = "Clear All",
    TextColor3 = CurrentTheme.Primary,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    ZIndex = 6,
})

local notifTypes = {
    { icon = "✓", color = CurrentTheme.Success, title = "Success", msg = "Action completed successfully.", time = "Now" },
    { icon = "⚠", color = CurrentTheme.Warning, title = "Warning", msg = "This is a warning message.", time = "3m ago" },
    { icon = "ℹ", color = CurrentTheme.Info, title = "Information", msg = "This is an information message.", time = "5m ago" },
    { icon = "✕", color = CurrentTheme.Error, title = "Error", msg = "This is an error message.", time = "10m ago" },
}

for i, notif in ipairs(notifTypes) do
    local nRow = Create("Frame", {
        Parent = NotifCard,
        BackgroundColor3 = CurrentTheme.Surface2,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 38 + (i - 1) * 52),
        Size = UDim2.new(1, -24, 0, 46),
        ZIndex = 5,
    })
    Create("UICorner", { Parent = nRow, CornerRadius = UDim.new(0, 8) })

    -- Color icon circle
    local iconCircle = Create("Frame", {
        Parent = nRow,
        BackgroundColor3 = notif.color,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0.5, -12),
        Size = UDim2.new(0, 24, 0, 24),
        ZIndex = 6,
    })
    Create("UICorner", { Parent = iconCircle, CornerRadius = UDim.new(1, 0) })
    Create("TextLabel", {
        Parent = iconCircle,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = notif.icon,
        TextColor3 = notif.color,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        ZIndex = 7,
    })

    Create("TextLabel", {
        Parent = nRow,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 5),
        Size = UDim2.new(1, -90, 0, 16),
        Text = notif.title,
        TextColor3 = CurrentTheme.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    })

    Create("TextLabel", {
        Parent = nRow,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 22),
        Size = UDim2.new(1, -90, 0, 16),
        Text = notif.msg,
        TextColor3 = CurrentTheme.TextMuted,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    })

    Create("TextLabel", {
        Parent = nRow,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -52, 0, 5),
        Size = UDim2.new(0, 48, 0, 16),
        Text = notif.time,
        TextColor3 = CurrentTheme.TextDim,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 6,
    })
end

ClearAllBtn.MouseButton1Click:Connect(function()
    for _, child in pairs(NotifCard:GetChildren()) do
        if child:IsA("Frame") and child ~= NotifHeader then
            Tween(child, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
            for _, c2 in pairs(child:GetChildren()) do
                if c2:IsA("TextLabel") then
                    Tween(c2, TweenInfo.new(0.3), { TextTransparency = 1 })
                end
            end
        end
    end
    wait(0.4)
    -- Restore after 3s
    wait(3)
    for _, child in pairs(NotifCard:GetChildren()) do
        if child:IsA("Frame") and child ~= NotifHeader then
            Tween(child, TweenInfo.new(0.3), { BackgroundTransparency = 0 })
            for _, c2 in pairs(child:GetChildren()) do
                if c2:IsA("TextLabel") then
                    Tween(c2, TweenInfo.new(0.3), { TextTransparency = 0 })
                end
            end
        end
    end
end)

-- ===== COLUMN 2: Main Configuration =====
local Col2X = 260

local ConfigCard = Create("Frame", {
    Parent = Scroll,
    BackgroundColor3 = CurrentTheme.Surface,
    BorderSizePixel = 0,
    Position = UDim2.new(0, Col2X, 0, ColY),
    Size = UDim2.new(0, 398, 0, 516),
    ZIndex = 4,
})
Create("UICorner", { Parent = ConfigCard, CornerRadius = UDim.new(0, 10) })
Create("UIStroke", { Parent = ConfigCard, Color = CurrentTheme.Border, Thickness = 1 })

Create("TextLabel", {
    Parent = ConfigCard,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 16, 0, 14),
    Size = UDim2.new(1, -16, 0, 18),
    Text = "MAIN CONFIGURATION",
    TextColor3 = CurrentTheme.TextMuted,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 5,
})

local configY = 44

-- Helper: config row container
local function MakeConfigRow(parent, y, h)
    local row = Create("Frame", {
        Parent = parent,
        BackgroundColor3 = CurrentTheme.Surface2,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, y),
        Size = UDim2.new(1, -24, 0, h or 68),
        ZIndex = 5,
    })
    Create("UICorner", { Parent = row, CornerRadius = UDim.new(0, 8) })
    return row
end

local function MakeConfigIcon(parent, icon)
    local iconFrame = Create("Frame", {
        Parent = parent,
        BackgroundColor3 = CurrentTheme.Primary,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0.5, -14),
        Size = UDim2.new(0, 28, 0, 28),
        ZIndex = 6,
    })
    Create("UICorner", { Parent = iconFrame, CornerRadius = UDim.new(0, 7) })
    Create("TextLabel", {
        Parent = iconFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = icon,
        TextColor3 = CurrentTheme.Primary,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        ZIndex = 7,
    })
end

-- 1. Toggle Feature
local toggleRow = MakeConfigRow(ConfigCard, configY)
MakeConfigIcon(toggleRow, "⚙")
Create("TextLabel", {
    Parent = toggleRow, BackgroundTransparency = 1,
    Position = UDim2.new(0, 46, 0, 10), Size = UDim2.new(0, 180, 0, 18),
    Text = "Toggle Feature", TextColor3 = CurrentTheme.Text, TextSize = 13, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
})
Create("TextLabel", {
    Parent = toggleRow, BackgroundTransparency = 1,
    Position = UDim2.new(0, 46, 0, 30), Size = UDim2.new(0, 200, 0, 14),
    Text = "Enable or disable a specific feature.", TextColor3 = CurrentTheme.TextMuted, TextSize = 10, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
})

local toggleState = true
local toggleBg = Create("Frame", {
    Parent = toggleRow, BackgroundColor3 = CurrentTheme.Primary, BorderSizePixel = 0,
    Position = UDim2.new(1, -60, 0.5, -12), Size = UDim2.new(0, 46, 0, 24), ZIndex = 6,
})
Create("UICorner", { Parent = toggleBg, CornerRadius = UDim.new(1, 0) })
local toggleKnob = Create("Frame", {
    Parent = toggleBg, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
    Position = UDim2.new(1, -22, 0.5, -9), Size = UDim2.new(0, 18, 0, 18), ZIndex = 7,
})
Create("UICorner", { Parent = toggleKnob, CornerRadius = UDim.new(1, 0) })

local toggleBtn = Create("TextButton", {
    Parent = toggleRow, BackgroundTransparency = 1, Size = UDim2.new(0, 52, 0, 28),
    Position = UDim2.new(1, -64, 0.5, -14), Text = "", ZIndex = 8,
})
toggleBtn.MouseButton1Click:Connect(function()
    toggleState = not toggleState
    if toggleState then
        Tween(toggleBg, TweenInfo.new(0.2), { BackgroundColor3 = CurrentTheme.Primary })
        Tween(toggleKnob, TweenInfo.new(0.2), { Position = UDim2.new(1, -22, 0.5, -9) })
    else
        Tween(toggleBg, TweenInfo.new(0.2), { BackgroundColor3 = CurrentTheme.Surface3 })
        Tween(toggleKnob, TweenInfo.new(0.2), { Position = UDim2.new(0, 4, 0.5, -9) })
    end
end)

configY = configY + 76

-- 2. Slider
local sliderRow = MakeConfigRow(ConfigCard, configY)
MakeConfigIcon(sliderRow, "≡")
Create("TextLabel", {
    Parent = sliderRow, BackgroundTransparency = 1,
    Position = UDim2.new(0, 46, 0, 10), Size = UDim2.new(0, 180, 0, 18),
    Text = "Slider Value", TextColor3 = CurrentTheme.Text, TextSize = 13, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
})
Create("TextLabel", {
    Parent = sliderRow, BackgroundTransparency = 1,
    Position = UDim2.new(0, 46, 0, 30), Size = UDim2.new(0, 200, 0, 14),
    Text = "Adjust the value smoothly.", TextColor3 = CurrentTheme.TextMuted, TextSize = 10, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
})

local sliderVal = 75
local sliderValLabel = Create("TextLabel", {
    Parent = sliderRow, BackgroundTransparency = 1,
    Position = UDim2.new(1, -38, 0, 8), Size = UDim2.new(0, 30, 0, 18),
    Text = tostring(sliderVal), TextColor3 = CurrentTheme.Text, TextSize = 13, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6,
})

local sliderBg = Create("Frame", {
    Parent = sliderRow, BackgroundColor3 = CurrentTheme.Surface3, BorderSizePixel = 0,
    Position = UDim2.new(0, 46, 0, 46), Size = UDim2.new(1, -56, 0, 6), ZIndex = 6,
})
Create("UICorner", { Parent = sliderBg, CornerRadius = UDim.new(1, 0) })

local sliderFill = Create("Frame", {
    Parent = sliderBg, BackgroundColor3 = CurrentTheme.Primary, BorderSizePixel = 0,
    Size = UDim2.new(sliderVal / 100, 0, 1, 0), ZIndex = 7,
})
Create("UICorner", { Parent = sliderFill, CornerRadius = UDim.new(1, 0) })
Create("UIGradient", {
    Parent = sliderFill,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 150, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 0)),
    }),
})

local sliderKnob = Create("Frame", {
    Parent = sliderBg, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
    Position = UDim2.new(sliderVal / 100, -7, 0.5, -7), Size = UDim2.new(0, 14, 0, 14), ZIndex = 8,
})
Create("UICorner", { Parent = sliderKnob, CornerRadius = UDim.new(1, 0) })
Create("UIStroke", { Parent = sliderKnob, Color = CurrentTheme.Primary, Thickness = 2 })

local sliderDragging = false
sliderBg.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = true
    end
end)
sliderBg.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = false
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if sliderDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local rel = (inp.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
        rel = math.clamp(rel, 0, 1)
        sliderVal = math.floor(rel * 100)
        sliderValLabel.Text = tostring(sliderVal)
        sliderFill.Size = UDim2.new(rel, 0, 1, 0)
        sliderKnob.Position = UDim2.new(rel, -7, 0.5, -7)
    end
end)

configY = configY + 76

-- 3. Dropdown
local dropdownOpen = false
local dropdownOptions = { "Option 1", "Option 2", "Option 3", "Option 4" }
local dropdownSelected = "Option 2"

local dropRow = MakeConfigRow(ConfigCard, configY)
MakeConfigIcon(dropRow, "⊞")
Create("TextLabel", {
    Parent = dropRow, BackgroundTransparency = 1,
    Position = UDim2.new(0, 46, 0, 10), Size = UDim2.new(0, 180, 0, 18),
    Text = "Dropdown Menu", TextColor3 = CurrentTheme.Text, TextSize = 13, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
})
Create("TextLabel", {
    Parent = dropRow, BackgroundTransparency = 1,
    Position = UDim2.new(0, 46, 0, 30), Size = UDim2.new(0, 200, 0, 14),
    Text = "Select an option from the list.", TextColor3 = CurrentTheme.TextMuted, TextSize = 10, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
})

local dropBtn = Create("TextButton", {
    Parent = dropRow, BackgroundColor3 = CurrentTheme.Surface3, BorderSizePixel = 0,
    Position = UDim2.new(1, -120, 0.5, -14), Size = UDim2.new(0, 108, 0, 28), Text = "", ZIndex = 6,
})
Create("UICorner", { Parent = dropBtn, CornerRadius = UDim.new(0, 6) })
local dropBtnLabel = Create("TextLabel", {
    Parent = dropBtn, BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -30, 1, 0),
    Text = dropdownSelected, TextColor3 = CurrentTheme.Text, TextSize = 12, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
})
Create("TextLabel", {
    Parent = dropBtn, BackgroundTransparency = 1,
    Position = UDim2.new(1, -22, 0, 0), Size = UDim2.new(0, 18, 1, 0),
    Text = "∨", TextColor3 = CurrentTheme.TextMuted, TextSize = 12, Font = Enum.Font.GothamBold, ZIndex = 7,
})

-- Dropdown popup
local dropPopup = Create("Frame", {
    Parent = ConfigCard, BackgroundColor3 = CurrentTheme.Surface2, BorderSizePixel = 0,
    Position = UDim2.new(1, -133, 0, configY + 42 + 36), Size = UDim2.new(0, 120, 0, 0),
    ZIndex = 20, Visible = false, ClipsDescendants = true,
})
Create("UICorner", { Parent = dropPopup, CornerRadius = UDim.new(0, 8) })
Create("UIStroke", { Parent = dropPopup, Color = CurrentTheme.Border, Thickness = 1 })

for i, opt in ipairs(dropdownOptions) do
    local optBtn = Create("TextButton", {
        Parent = dropPopup, BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, (i - 1) * 30), Size = UDim2.new(1, 0, 0, 30),
        Text = opt, TextColor3 = CurrentTheme.Text, TextSize = 12, Font = Enum.Font.Gotham, ZIndex = 21,
    })
    optBtn.MouseEnter:Connect(function()
        Tween(optBtn, TweenInfo.new(0.1), { BackgroundTransparency = 0.8, BackgroundColor3 = CurrentTheme.Primary })
    end)
    optBtn.MouseLeave:Connect(function()
        Tween(optBtn, TweenInfo.new(0.1), { BackgroundTransparency = 1 })
    end)
    optBtn.MouseButton1Click:Connect(function()
        dropdownSelected = opt
        dropBtnLabel.Text = opt
        dropdownOpen = false
        Tween(dropPopup, TweenInfo.new(0.15), { Size = UDim2.new(0, 120, 0, 0) })
        wait(0.15)
        dropPopup.Visible = false
    end)
end

dropBtn.MouseButton1Click:Connect(function()
    dropdownOpen = not dropdownOpen
    if dropdownOpen then
        dropPopup.Visible = true
        Tween(dropPopup, TweenInfo.new(0.15), { Size = UDim2.new(0, 120, 0, #dropdownOptions * 30) })
    else
        Tween(dropPopup, TweenInfo.new(0.15), { Size = UDim2.new(0, 120, 0, 0) })
        wait(0.15)
        dropPopup.Visible = false
    end
end)

configY = configY + 76

-- 4. Multi Select
local multiRow = MakeConfigRow(ConfigCard, configY, 90)
MakeConfigIcon(multiRow, "☰")
Create("TextLabel", {
    Parent = multiRow, BackgroundTransparency = 1,
    Position = UDim2.new(0, 46, 0, 8), Size = UDim2.new(0, 180, 0, 16),
    Text = "Multi Select", TextColor3 = CurrentTheme.Text, TextSize = 13, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
})
Create("TextLabel", {
    Parent = multiRow, BackgroundTransparency = 1,
    Position = UDim2.new(0, 46, 0, 26), Size = UDim2.new(0, 200, 0, 14),
    Text = "Choose multiple options.", TextColor3 = CurrentTheme.TextMuted, TextSize = 10, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
})

local multiExpand = Create("TextButton", {
    Parent = multiRow, BackgroundTransparency = 1,
    Position = UDim2.new(1, -24, 0, 8), Size = UDim2.new(0, 20, 0, 20),
    Text = "∨", TextColor3 = CurrentTheme.TextMuted, TextSize = 14, Font = Enum.Font.GothamBold, ZIndex = 6,
})

-- Multi tags
local multiSelected = { "Option 1", "Option 3" }
local multiTagsFrame = Create("Frame", {
    Parent = multiRow, BackgroundTransparency = 1,
    Position = UDim2.new(0, 46, 0, 48), Size = UDim2.new(1, -56, 0, 32), ZIndex = 6,
})

local function RefreshMultiTags()
    for _, c in pairs(multiTagsFrame:GetChildren()) do c:Destroy() end
    local xOff = 0
    for _, sel in pairs(multiSelected) do
        local tag = Create("Frame", {
            Parent = multiTagsFrame, BackgroundColor3 = CurrentTheme.Surface3, BorderSizePixel = 0,
            Position = UDim2.new(0, xOff, 0, 2), Size = UDim2.new(0, #sel * 7 + 30, 0, 24), ZIndex = 7,
        })
        Create("UICorner", { Parent = tag, CornerRadius = UDim.new(0, 5) })
        Create("TextLabel", {
            Parent = tag, BackgroundTransparency = 1,
            Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(1, -20, 1, 0),
            Text = sel, TextColor3 = CurrentTheme.Text, TextSize = 11, Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
        })
        local rmvBtn = Create("TextButton", {
            Parent = tag, BackgroundTransparency = 1,
            Position = UDim2.new(1, -18, 0, 0), Size = UDim2.new(0, 18, 1, 0),
            Text = "×", TextColor3 = CurrentTheme.TextMuted, TextSize = 13, Font = Enum.Font.GothamBold, ZIndex = 9,
        })
        local capSel = sel
        rmvBtn.MouseButton1Click:Connect(function()
            for j, s in pairs(multiSelected) do
                if s == capSel then table.remove(multiSelected, j) break end
            end
            RefreshMultiTags()
        end)
        xOff = xOff + #sel * 7 + 36
    end
end
RefreshMultiTags()

configY = configY + 98

-- 5. Text Input
local textRow = MakeConfigRow(ConfigCard, configY)
MakeConfigIcon(textRow, "✎")
Create("TextLabel", {
    Parent = textRow, BackgroundTransparency = 1,
    Position = UDim2.new(0, 46, 0, 10), Size = UDim2.new(0, 180, 0, 18),
    Text = "Text Input", TextColor3 = CurrentTheme.Text, TextSize = 13, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
})
Create("TextLabel", {
    Parent = textRow, BackgroundTransparency = 1,
    Position = UDim2.new(0, 46, 0, 30), Size = UDim2.new(0, 200, 0, 14),
    Text = "Enter custom text here.", TextColor3 = CurrentTheme.TextMuted, TextSize = 10, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
})

local textInputBox = Create("Frame", {
    Parent = textRow, BackgroundColor3 = CurrentTheme.Surface3, BorderSizePixel = 0,
    Position = UDim2.new(1, -156, 0.5, -14), Size = UDim2.new(0, 144, 0, 28), ZIndex = 6,
})
Create("UICorner", { Parent = textInputBox, CornerRadius = UDim.new(0, 6) })
local textInput = Create("TextBox", {
    Parent = textInputBox, BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -36, 1, 0),
    Text = "Obsidian UI", TextColor3 = CurrentTheme.Text, TextSize = 12, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 7,
    PlaceholderText = "Enter text...", PlaceholderColor3 = CurrentTheme.TextDim,
    ClearTextOnFocus = false,
})
local clearTextBtn = Create("TextButton", {
    Parent = textInputBox, BackgroundTransparency = 1,
    Position = UDim2.new(1, -28, 0, 0), Size = UDim2.new(0, 28, 1, 0),
    Text = "×", TextColor3 = CurrentTheme.TextMuted, TextSize = 16, Font = Enum.Font.GothamBold, ZIndex = 7,
})
clearTextBtn.MouseButton1Click:Connect(function() textInput.Text = "" end)

textInput.Focused:Connect(function()
    Tween(textInputBox, TweenInfo.new(0.15), { BackgroundColor3 = CurrentTheme.Surface2 })
end)
textInput.FocusLost:Connect(function()
    Tween(textInputBox, TweenInfo.new(0.15), { BackgroundColor3 = CurrentTheme.Surface3 })
end)

configY = configY + 76

-- 6. Keybind
local keybindRow = MakeConfigRow(ConfigCard, configY)
MakeConfigIcon(keybindRow, "⌨")
Create("TextLabel", {
    Parent = keybindRow, BackgroundTransparency = 1,
    Position = UDim2.new(0, 46, 0, 10), Size = UDim2.new(0, 180, 0, 18),
    Text = "Keybind", TextColor3 = CurrentTheme.Text, TextSize = 13, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
})
Create("TextLabel", {
    Parent = keybindRow, BackgroundTransparency = 1,
    Position = UDim2.new(0, 46, 0, 30), Size = UDim2.new(0, 200, 0, 14),
    Text = "Set a keybind for activation.", TextColor3 = CurrentTheme.TextMuted, TextSize = 10, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
})

local currentKeybind = "RightShift"
local listeningForKey = false

local keybindBox = Create("Frame", {
    Parent = keybindRow, BackgroundColor3 = CurrentTheme.Surface3, BorderSizePixel = 0,
    Position = UDim2.new(1, -156, 0.5, -14), Size = UDim2.new(0, 108, 0, 28), ZIndex = 6,
})
Create("UICorner", { Parent = keybindBox, CornerRadius = UDim.new(0, 6) })
local keybindLabel = Create("TextLabel", {
    Parent = keybindBox, BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 1, 0),
    Text = currentKeybind, TextColor3 = CurrentTheme.Text, TextSize = 11, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
})

local keybindSetBtn = Create("TextButton", {
    Parent = keybindRow, BackgroundColor3 = CurrentTheme.Surface3, BorderSizePixel = 0,
    Position = UDim2.new(1, -42, 0.5, -14), Size = UDim2.new(0, 30, 0, 28),
    Text = "⚙", TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = CurrentTheme.TextMuted, ZIndex = 6,
})
Create("UICorner", { Parent = keybindSetBtn, CornerRadius = UDim.new(0, 6) })

keybindSetBtn.MouseButton1Click:Connect(function()
    if not listeningForKey then
        listeningForKey = true
        keybindLabel.Text = "..."
        Tween(keybindBox, TweenInfo.new(0.15), { BackgroundColor3 = CurrentTheme.Primary })
    end
end)

UserInputService.InputBegan:Connect(function(inp, gp)
    if listeningForKey and not gp then
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            currentKeybind = tostring(inp.KeyCode):gsub("Enum.KeyCode.", "")
            keybindLabel.Text = currentKeybind
            listeningForKey = false
            Tween(keybindBox, TweenInfo.new(0.15), { BackgroundColor3 = CurrentTheme.Surface3 })
        end
    end
end)

-- ===== COLUMN 3: Color Customizer + Theme Presets =====
local Col3X = 672

local ColorCard = Create("Frame", {
    Parent = Scroll,
    BackgroundColor3 = CurrentTheme.Surface,
    BorderSizePixel = 0,
    Position = UDim2.new(0, Col3X, 0, ColY),
    Size = UDim2.new(0, 358, 0, 340),
    ZIndex = 4,
})
Create("UICorner", { Parent = ColorCard, CornerRadius = UDim.new(0, 10) })
Create("UIStroke", { Parent = ColorCard, Color = CurrentTheme.Border, Thickness = 1 })

-- Header
local ccHeader = Create("Frame", {
    Parent = ColorCard, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), ZIndex = 5,
})
Create("TextLabel", {
    Parent = ccHeader, BackgroundTransparency = 1,
    Position = UDim2.new(0, 16, 0, 10), Size = UDim2.new(0, 180, 0, 16),
    Text = "COLOR CUSTOMIZER", TextColor3 = CurrentTheme.TextMuted, TextSize = 10, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
})

-- HSV/RGB/HEX tabs
local colorMode = "HSV"
local colorModeBtns = {}
local colorModes = { "HSV", "RGB", "HEX" }
local colorTabsFrame = Create("Frame", {
    Parent = ColorCard, BackgroundColor3 = CurrentTheme.Surface3, BorderSizePixel = 0,
    Position = UDim2.new(1, -180, 0, 8), Size = UDim2.new(0, 162, 0, 24), ZIndex = 6,
})
Create("UICorner", { Parent = colorTabsFrame, CornerRadius = UDim.new(0, 6) })

for i, mode in ipairs(colorModes) do
    local tabBtn = Create("TextButton", {
        Parent = colorTabsFrame, BackgroundColor3 = mode == colorMode and CurrentTheme.Primary or Color3.fromRGB(0,0,0),
        BackgroundTransparency = mode == colorMode and 0 or 1,
        BorderSizePixel = 0, Position = UDim2.new(0, (i-1)*54, 0, 0), Size = UDim2.new(0, 54, 1, 0),
        Text = mode, TextColor3 = mode == colorMode and Color3.fromRGB(255,255,255) or CurrentTheme.TextMuted,
        TextSize = 11, Font = Enum.Font.GothamBold, ZIndex = 7,
    })
    Create("UICorner", { Parent = tabBtn, CornerRadius = UDim.new(0, 5) })
    colorModeBtns[mode] = tabBtn
    tabBtn.MouseButton1Click:Connect(function()
        colorMode = mode
        for _, m in pairs(colorModes) do
            Tween(colorModeBtns[m], TweenInfo.new(0.15), {
                BackgroundTransparency = m == mode and 0 or 1,
                BackgroundColor3 = m == mode and CurrentTheme.Primary or Color3.fromRGB(0,0,0),
                TextColor3 = m == mode and Color3.fromRGB(255,255,255) or CurrentTheme.TextMuted,
            })
        end
    end)
end

-- Color wheel (simulated with gradient image)
local wheelOuter = Create("Frame", {
    Parent = ColorCard, BackgroundColor3 = CurrentTheme.Surface2, BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 0, 42), Size = UDim2.new(0, 150, 0, 150), ZIndex = 5,
})
Create("UICorner", { Parent = wheelOuter, CornerRadius = UDim.new(1, 0) })

local wheel = Create("ImageLabel", {
    Parent = wheelOuter, BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    Image = "rbxassetid://4661637895",
    ZIndex = 6,
})
Create("UICorner", { Parent = wheel, CornerRadius = UDim.new(1, 0) })

-- Inner saturation square
local satSquare = Create("ImageLabel", {
    Parent = wheelOuter, BackgroundTransparency = 1,
    Position = UDim2.new(0.15, 0, 0.15, 0),
    Size = UDim2.new(0.7, 0, 0.7, 0),
    Image = "rbxassetid://4155801252",
    ZIndex = 7,
})
Create("UICorner", { Parent = satSquare, CornerRadius = UDim.new(0, 5) })

-- Color cursor on wheel
local wheelCursor = Create("Frame", {
    Parent = wheelOuter, BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0,
    Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0.5, -6, 0.05, -6), ZIndex = 8,
})
Create("UICorner", { Parent = wheelCursor, CornerRadius = UDim.new(1, 0) })
Create("UIStroke", { Parent = wheelCursor, Color = Color3.fromRGB(255,255,255), Thickness = 2 })

-- Sat/bright cursor
local satCursor = Create("Frame", {
    Parent = satSquare, BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0,
    Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -5, 0, -5), ZIndex = 9,
})
Create("UICorner", { Parent = satCursor, CornerRadius = UDim.new(1, 0) })
Create("UIStroke", { Parent = satCursor, Color = Color3.fromRGB(255,255,255), Thickness = 2 })

-- HSVA values panel
local hsvaPanel = Create("Frame", {
    Parent = ColorCard, BackgroundTransparency = 1,
    Position = UDim2.new(0, 170, 0, 42), Size = UDim2.new(0, 175, 0, 160), ZIndex = 5,
})

local hsvaLabels = { "H", "S", "V", "A" }
local hsvaValues = { 24, 100, 100, 100 }
local hsvaUnits = { "°", "%", "%", "%" }

for i, lbl in ipairs(hsvaLabels) do
    Create("TextLabel", {
        Parent = hsvaPanel, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, (i-1)*35), Size = UDim2.new(0, 20, 0, 28),
        Text = lbl, TextColor3 = CurrentTheme.TextMuted, TextSize = 13, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
    })
    local valBox = Create("Frame", {
        Parent = hsvaPanel, BackgroundColor3 = CurrentTheme.Surface3, BorderSizePixel = 0,
        Position = UDim2.new(0, 28, 0, (i-1)*35 + 2), Size = UDim2.new(0, 95, 0, 24), ZIndex = 6,
    })
    Create("UICorner", { Parent = valBox, CornerRadius = UDim.new(0, 5) })
    local valInput = Create("TextBox", {
        Parent = valBox, BackgroundTransparency = 1,
        Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(1, -26, 1, 0),
        Text = tostring(hsvaValues[i]), TextColor3 = CurrentTheme.Text, TextSize = 12, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right, BorderSizePixel = 0, ZIndex = 7, ClearTextOnFocus = false,
    })
    Create("TextLabel", {
        Parent = valBox, BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 0, 0), Size = UDim2.new(0, 18, 1, 0),
        Text = hsvaUnits[i], TextColor3 = CurrentTheme.TextMuted, TextSize = 12, Font = Enum.Font.Gotham, ZIndex = 7,
    })
end

-- Hex input
local hexFrame = Create("Frame", {
    Parent = ColorCard, BackgroundColor3 = CurrentTheme.Surface3, BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 0, 200), Size = UDim2.new(0, 215, 0, 28), ZIndex = 5,
})
Create("UICorner", { Parent = hexFrame, CornerRadius = UDim.new(0, 6) })

Create("TextLabel", {
    Parent = hexFrame, BackgroundTransparency = 1,
    Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(0, 30, 1, 0),
    Text = "HEX", TextColor3 = CurrentTheme.TextMuted, TextSize = 9, Font = Enum.Font.GothamBold, ZIndex = 6,
})
Create("TextBox", {
    Parent = hexFrame, BackgroundTransparency = 1,
    Position = UDim2.new(0, 36, 0, 0), Size = UDim2.new(1, -60, 1, 0),
    Text = "#FF4500", TextColor3 = CurrentTheme.Text, TextSize = 12, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 6, ClearTextOnFocus = false,
})
local copyHexBtn = Create("TextButton", {
    Parent = hexFrame, BackgroundTransparency = 1,
    Position = UDim2.new(1, -28, 0, 0), Size = UDim2.new(0, 28, 1, 0),
    Text = "⎘", TextColor3 = CurrentTheme.TextMuted, TextSize = 14, Font = Enum.Font.GothamBold, ZIndex = 6,
})

-- Color swatches
local swatchColors = {
    Color3.fromRGB(255, 100, 0),
    Color3.fromRGB(220, 50, 80),
    Color3.fromRGB(150, 60, 220),
    Color3.fromRGB(50, 130, 220),
    Color3.fromRGB(30, 190, 210),
    Color3.fromRGB(50, 200, 80),
    Color3.fromRGB(230, 200, 0),
    Color3.fromRGB(240, 240, 245),
}

local selectedSwatchIndex = 1

for i, sc in ipairs(swatchColors) do
    local swatch = Create("TextButton", {
        Parent = ColorCard, BackgroundColor3 = sc, BorderSizePixel = 0,
        Position = UDim2.new(0, 12 + (i-1)*36, 0, 242), Size = UDim2.new(0, 28, 0, 28), Text = "", ZIndex = 5,
    })
    Create("UICorner", { Parent = swatch, CornerRadius = UDim.new(1, 0) })

    if i == 1 then
        Create("UIStroke", { Parent = swatch, Color = Color3.fromRGB(255,255,255), Thickness = 2 })
    end

    local si = i
    swatch.MouseButton1Click:Connect(function()
        -- update selection
        for _, ch in pairs(ColorCard:GetChildren()) do
            if ch:IsA("TextButton") and ch.BackgroundColor3 == swatchColors[selectedSwatchIndex] then
                for _, stroke in pairs(ch:GetChildren()) do
                    if stroke:IsA("UIStroke") then stroke:Destroy() end
                end
            end
        end
        selectedSwatchIndex = si
        Create("UIStroke", { Parent = swatch, Color = Color3.fromRGB(255,255,255), Thickness = 2 })
        Tween(WinGlow, TweenInfo.new(0.5), { ImageColor3 = sc })
    end)
end

-- ===== THEME PRESETS CARD =====
local ThemeCard = Create("Frame", {
    Parent = Scroll,
    BackgroundColor3 = CurrentTheme.Surface,
    BorderSizePixel = 0,
    Position = UDim2.new(0, Col3X, 0, ColY + 348),
    Size = UDim2.new(0, 358, 0, 168),
    ZIndex = 4,
})
Create("UICorner", { Parent = ThemeCard, CornerRadius = UDim.new(0, 10) })
Create("UIStroke", { Parent = ThemeCard, Color = CurrentTheme.Border, Thickness = 1 })

Create("TextLabel", {
    Parent = ThemeCard, BackgroundTransparency = 1,
    Position = UDim2.new(0, 16, 0, 12), Size = UDim2.new(0, 150, 0, 16),
    Text = "THEME PRESETS", TextColor3 = CurrentTheme.TextMuted, TextSize = 10, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
})

local viewAllBtn = Create("TextButton", {
    Parent = ThemeCard, BackgroundTransparency = 1,
    Position = UDim2.new(1, -70, 0, 8), Size = UDim2.new(0, 60, 0, 20),
    Text = "View All", TextColor3 = CurrentTheme.Primary, TextSize = 11, Font = Enum.Font.GothamBold, ZIndex = 5,
})

local themePresets = {
    { name = "Obsidian", sub = "Default", color = Color3.fromRGB(255, 100, 0), selected = true, key = "Obsidian" },
    { name = "Crimson", sub = "Red Theme", color = Color3.fromRGB(220, 40, 70), key = "Crimson" },
    { name = "Amethyst", sub = "Purple Theme", color = Color3.fromRGB(140, 60, 220), key = "Amethyst" },
    { name = "Ocean", sub = "Blue Theme", color = Color3.fromRGB(30, 140, 220), key = "Ocean" },
    { name = "Matrix", sub = "Green Theme", color = Color3.fromRGB(0, 200, 80), key = "Matrix" },
}

local selectedThemeIdx = 1

local function ApplyTheme(theme)
    CurrentTheme = theme
    -- Update key elements
    Tween(MainWindow, TweenInfo.new(0.4), { BackgroundColor3 = theme.Background })
    Tween(TopBar, TweenInfo.new(0.4), { BackgroundColor3 = theme.Surface })
    Tween(TopBarMask, TweenInfo.new(0.4), { BackgroundColor3 = theme.Surface })
    Tween(Sidebar, TweenInfo.new(0.4), { BackgroundColor3 = theme.Surface })
    Tween(WinGlow, TweenInfo.new(0.4), { ImageColor3 = theme.Primary })
    Tween(StatusDot, TweenInfo.new(0.4), { BackgroundColor3 = theme.Success })
end

for i, tp in ipairs(themePresets) do
    local tw = 58
    local themeBtn = Create("TextButton", {
        Parent = ThemeCard, BackgroundColor3 = CurrentTheme.Surface2, BorderSizePixel = 0,
        Position = UDim2.new(0, 10 + (i-1)*(tw+4), 0, 36), Size = UDim2.new(0, tw, 0, 70),
        Text = "", ZIndex = 5,
    })
    Create("UICorner", { Parent = themeBtn, CornerRadius = UDim.new(0, 8) })

    if tp.selected then
        Create("UIStroke", { Parent = themeBtn, Color = tp.color, Thickness = 2 })
    end

    -- Color preview area
    local colorPreview = Create("Frame", {
        Parent = themeBtn, BackgroundColor3 = Color3.fromRGB(13,13,15), BorderSizePixel = 0,
        Position = UDim2.new(0, 4, 0, 4), Size = UDim2.new(1, -8, 0, 38), ZIndex = 6,
    })
    Create("UICorner", { Parent = colorPreview, CornerRadius = UDim.new(0, 6) })
    Create("UIGradient", {
        Parent = colorPreview,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, tp.color),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(
                math.floor(tp.color.R * 100),
                math.floor(tp.color.G * 100),
                math.floor(tp.color.B * 100)
            )),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(13,13,15)),
        }),
        Rotation = 135,
    })

    if tp.selected then
        local checkMark = Create("TextLabel", {
            Parent = colorPreview, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
            Text = "✓", TextColor3 = Color3.fromRGB(255,255,255), TextSize = 16, Font = Enum.Font.GothamBold, ZIndex = 7,
        })
    end

    Create("TextLabel", {
        Parent = themeBtn, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 0, 12),
        Text = tp.name, TextColor3 = CurrentTheme.Text, TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 6,
    })
    Create("TextLabel", {
        Parent = themeBtn, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 58), Size = UDim2.new(1, 0, 0, 10),
        Text = tp.sub, TextColor3 = CurrentTheme.TextMuted, TextSize = 8, Font = Enum.Font.Gotham, ZIndex = 6,
    })

    local tpi = i
    themeBtn.MouseButton1Click:Connect(function()
        selectedThemeIdx = tpi
        ApplyTheme(Themes[tp.key])
        -- Update strokes
        for j, _ in ipairs(themePresets) do
            -- We don't have refs to all theme btns here; just visual feedback
        end
        RippleEffect(themeBtn, tp.color)
    end)

    themeBtn.MouseEnter:Connect(function()
        Tween(themeBtn, TweenInfo.new(0.15), { BackgroundColor3 = CurrentTheme.Surface3 })
    end)
    themeBtn.MouseLeave:Connect(function()
        Tween(themeBtn, TweenInfo.new(0.15), { BackgroundColor3 = CurrentTheme.Surface2 })
    end)
end

-- Create Custom Theme button
local customThemeBtn = Create("TextButton", {
    Parent = ThemeCard, BackgroundColor3 = CurrentTheme.Surface2, BorderSizePixel = 0,
    Position = UDim2.new(0, 10, 0, 118), Size = UDim2.new(1, -20, 0, 38),
    Text = "", ZIndex = 5,
})
Create("UICorner", { Parent = customThemeBtn, CornerRadius = UDim.new(0, 8) })
Create("UIStroke", { Parent = customThemeBtn, Color = CurrentTheme.Border, Thickness = 1, LineJoinMode = Enum.LineJoinMode.Round })

Create("TextLabel", {
    Parent = customThemeBtn, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
    Text = "+ Create Custom Theme", TextColor3 = CurrentTheme.Primary, TextSize = 12,
    Font = Enum.Font.GothamBold, ZIndex = 6,
})
customThemeBtn.MouseEnter:Connect(function()
    Tween(customThemeBtn, TweenInfo.new(0.15), { BackgroundColor3 = CurrentTheme.Surface3 })
end)
customThemeBtn.MouseLeave:Connect(function()
    Tween(customThemeBtn, TweenInfo.new(0.15), { BackgroundColor3 = CurrentTheme.Surface2 })
end)
customThemeBtn.MouseButton1Click:Connect(function()
    RippleEffect(customThemeBtn, CurrentTheme.Primary)
end)

-- =================== CONSOLE OUTPUT ===================
local ConsoleCard = Create("Frame", {
    Parent = Scroll,
    BackgroundColor3 = CurrentTheme.Surface,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 18, 0, ColY + 524),
    Size = UDim2.new(0, 438, 0, 160),
    ZIndex = 4,
})
Create("UICorner", { Parent = ConsoleCard, CornerRadius = UDim.new(0, 10) })
Create("UIStroke", { Parent = ConsoleCard, Color = CurrentTheme.Border, Thickness = 1 })

local consoleHeader = Create("Frame", {
    Parent = ConsoleCard, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), ZIndex = 5,
})
Create("TextLabel", {
    Parent = consoleHeader, BackgroundTransparency = 1,
    Position = UDim2.new(0, 16, 0, 10), Size = UDim2.new(0, 160, 0, 14),
    Text = "CONSOLE OUTPUT", TextColor3 = CurrentTheme.TextMuted, TextSize = 10, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
})
local editConsoleBtn = Create("TextButton", {
    Parent = consoleHeader, BackgroundTransparency = 1,
    Position = UDim2.new(1, -32, 0, 6), Size = UDim2.new(0, 24, 0, 22),
    Text = "✎", TextColor3 = CurrentTheme.TextMuted, TextSize = 14, Font = Enum.Font.GothamBold, ZIndex = 6,
})

local ConsoleBg = Create("Frame", {
    Parent = ConsoleCard, BackgroundColor3 = Color3.fromRGB(8, 10, 12), BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 0, 36), Size = UDim2.new(1, -24, 1, -46), ZIndex = 5,
})
Create("UICorner", { Parent = ConsoleBg, CornerRadius = UDim.new(0, 6) })

local consoleLines = {
    { prefix = "[INFO]", color = CurrentTheme.Info, msg = " 12:45:10 - System initialized successfully." },
    { prefix = "[WARN]", color = CurrentTheme.Warning, msg = " 12:45:12 - Low memory detected." },
    { prefix = "[INFO]", color = CurrentTheme.Info, msg = " 12:45:15 - Feature loaded: Combat Module" },
    { prefix = "[ERROR]", color = CurrentTheme.Error, msg = " 12:45:18 - Failed to load asset." },
    { prefix = "[INFO]", color = CurrentTheme.Info, msg = " 12:45:20 - Reconnecting to server..." },
}

for i, line in ipairs(consoleLines) do
    local lineFrame = Create("Frame", {
        Parent = ConsoleBg, BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, (i-1)*21 + 4), Size = UDim2.new(1, -16, 0, 20), ZIndex = 6,
    })

    local prefixLbl = Create("TextLabel", {
        Parent = lineFrame, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 52, 1, 0),
        Text = line.prefix, TextColor3 = line.color, TextSize = 11, Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    })
    Create("TextLabel", {
        Parent = lineFrame, BackgroundTransparency = 1,
        Position = UDim2.new(0, 52, 0, 0), Size = UDim2.new(1, -52, 1, 0),
        Text = line.msg, TextColor3 = CurrentTheme.TextMuted, TextSize = 11, Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    })
end

-- Blinking cursor at end
local blinkCursor = Create("TextLabel", {
    Parent = ConsoleBg, BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 0, #consoleLines * 21 + 4), Size = UDim2.new(1, -16, 0, 20),
    Text = "▋", TextColor3 = CurrentTheme.Primary, TextSize = 13, Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
})

spawn(function()
    while blinkCursor and blinkCursor.Parent do
        Tween(blinkCursor, TweenInfo.new(0.5), { TextTransparency = 1 })
        wait(0.5)
        Tween(blinkCursor, TweenInfo.new(0.1), { TextTransparency = 0 })
        wait(0.6)
    end
end)

-- =================== PERFORMANCE MONITOR ===================
local PerfCard = Create("Frame", {
    Parent = Scroll,
    BackgroundColor3 = CurrentTheme.Surface,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 466, 0, ColY + 524),
    Size = UDim2.new(0, 564, 0, 160),
    ZIndex = 4,
})
Create("UICorner", { Parent = PerfCard, CornerRadius = UDim.new(0, 10) })
Create("UIStroke", { Parent = PerfCard, Color = CurrentTheme.Border, Thickness = 1 })

Create("TextLabel", {
    Parent = PerfCard, BackgroundTransparency = 1,
    Position = UDim2.new(0, 16, 0, 12), Size = UDim2.new(0, 200, 0, 14),
    Text = "PERFORMANCE MONITOR", TextColor3 = CurrentTheme.TextMuted, TextSize = 10, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
})
local viewDetailsBtn = Create("TextButton", {
    Parent = PerfCard, BackgroundTransparency = 1,
    Position = UDim2.new(1, -90, 0, 8), Size = UDim2.new(0, 80, 0, 18),
    Text = "View Details", TextColor3 = CurrentTheme.Primary, TextSize = 11, Font = Enum.Font.GothamBold, ZIndex = 5,
})

-- Perf stats
local perfStats = {
    { label = "FPS", val = "144", color = CurrentTheme.Error },
    { label = "PING", val = "23ms", color = CurrentTheme.Error },
    { label = "MEMORY", val = "68%", color = CurrentTheme.Warning },
    { label = "CPU", val = "42%", color = CurrentTheme.Primary },
}

local perfLabels = {}

for i, stat in ipairs(perfStats) do
    local statCard = Create("Frame", {
        Parent = PerfCard, BackgroundColor3 = CurrentTheme.Surface2, BorderSizePixel = 0,
        Position = UDim2.new(0, 10 + (i-1)*138, 0, 38), Size = UDim2.new(0, 130, 0, 100), ZIndex = 5,
    })
    Create("UICorner", { Parent = statCard, CornerRadius = UDim.new(0, 8) })

    Create("TextLabel", {
        Parent = statCard, BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 8), Size = UDim2.new(1, -20, 0, 14),
        Text = stat.label, TextColor3 = CurrentTheme.TextMuted, TextSize = 10, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
    })

    local valLbl = Create("TextLabel", {
        Parent = statCard, BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 26), Size = UDim2.new(1, -20, 0, 28),
        Text = stat.val, TextColor3 = CurrentTheme.Text, TextSize = 22, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
    })
    perfLabels[stat.label] = valLbl

    -- Sparkline mini graph (Drawing simulation using frames)
    local graphFrame = Create("Frame", {
        Parent = statCard, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, -38), Size = UDim2.new(1, 0, 0, 35), ZIndex = 6,
        ClipsDescendants = true,
    })

    -- Generate sparkline bars
    local sparkValues = {}
    for j = 1, 20 do
        sparkValues[j] = math.random(30, 95) / 100
    end

    for j, sv in ipairs(sparkValues) do
        local bar = Create("Frame", {
            Parent = graphFrame, BackgroundColor3 = stat.color, BackgroundTransparency = 0.6,
            BorderSizePixel = 0,
            Position = UDim2.new(0, (j-1)*6, 1, 0), Size = UDim2.new(0, 4, 0, -math.floor(sv * 28)), ZIndex = 7,
        })
    end

    -- Animate sparklines
    local sparkBars = graphFrame:GetChildren()
    local si = i
    spawn(function()
        while statCard and statCard.Parent do
            wait(0.5 + (si * 0.1))
            for _, bar in pairs(sparkBars) do
                if bar:IsA("Frame") then
                    local newH = math.random(15, 32)
                    Tween(bar, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
                        Size = UDim2.new(0, 4, 0, -newH)
                    })
                end
            end
        end
    end)
end

-- Update FPS/Ping live
spawn(function()
    while PerfCard and PerfCard.Parent do
        wait(0.5)
        local fps = math.floor(1 / RunService.Heartbeat:Wait())
        if perfLabels["FPS"] and perfLabels["FPS"].Parent then
            perfLabels["FPS"].Text = tostring(fps)
        end
        if perfLabels["PING"] and perfLabels["PING"].Parent then
            local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            perfLabels["PING"].Text = math.floor(ping) .. "ms"
        end
    end
end)

-- =================== INTRO ANIMATION ===================
MainWindow.Position = UDim2.new(0.5, -530, 0.5, -340)
MainWindow.BackgroundTransparency = 1
Shadow.BackgroundTransparency = 1

Tween(Shadow, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.55 })
Tween(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0,
})

-- =================== KEYBIND TO TOGGLE UI ===================
local guiVisible = true
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightShift and not listeningForKey then
        guiVisible = not guiVisible
        MainWindow.Visible = guiVisible
        Shadow.Visible = guiVisible
    end
    if inp.KeyCode == Enum.KeyCode.LeftControl then
        -- CTRL+K focuses search
    end
end)

-- =================== NOTIFICATION TOAST SYSTEM ===================
local toastQueue = {}
local toastShowing = false

local function ShowToast(title, message, notifType)
    local typeColors = {
        success = CurrentTheme.Success,
        warning = CurrentTheme.Warning,
        error = CurrentTheme.Error,
        info = CurrentTheme.Info,
    }
    local typeIcons = { success = "✓", warning = "⚠", error = "✕", info = "ℹ" }
    local color = typeColors[notifType] or CurrentTheme.Info
    local icon = typeIcons[notifType] or "ℹ"

    local toast = Create("Frame", {
        Parent = ScreenGui, BackgroundColor3 = CurrentTheme.Surface, BorderSizePixel = 0,
        Position = UDim2.new(1, 10, 1, -80), Size = UDim2.new(0, 280, 0, 64), ZIndex = 100,
    })
    Create("UICorner", { Parent = toast, CornerRadius = UDim.new(0, 10) })
    Create("UIStroke", { Parent = toast, Color = color, Thickness = 1.5 })

    -- Left accent bar
    Create("Frame", {
        Parent = toast, BackgroundColor3 = color, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 8), Size = UDim2.new(0, 3, 1, -16), ZIndex = 101,
    })

    local iconCircle = Create("Frame", {
        Parent = toast, BackgroundColor3 = color, BackgroundTransparency = 0.8, BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0.5, -14), Size = UDim2.new(0, 28, 0, 28), ZIndex = 101,
    })
    Create("UICorner", { Parent = iconCircle, CornerRadius = UDim.new(1, 0) })
    Create("TextLabel", {
        Parent = iconCircle, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        Text = icon, TextColor3 = color, TextSize = 14, Font = Enum.Font.GothamBold, ZIndex = 102,
    })

    Create("TextLabel", {
        Parent = toast, BackgroundTransparency = 1,
        Position = UDim2.new(0, 48, 0, 10), Size = UDim2.new(1, -56, 0, 18),
        Text = title, TextColor3 = CurrentTheme.Text, TextSize = 13, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 101,
    })
    Create("TextLabel", {
        Parent = toast, BackgroundTransparency = 1,
        Position = UDim2.new(0, 48, 0, 30), Size = UDim2.new(1, -56, 0, 24),
        Text = message, TextColor3 = CurrentTheme.TextMuted, TextSize = 11, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 101, TextWrapped = true,
    })

    Tween(toast, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -298, 1, -80),
    })
    wait(3)
    Tween(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 10, 1, -80),
        BackgroundTransparency = 1,
    })
    wait(0.35)
    toast:Destroy()
end

-- Demo: show a toast on launch
spawn(function()
    wait(1.5)
    ShowToast("Obsidian UI Loaded", "Premium v1.0 initialized successfully.", "success")
end)

spawn(function()
    wait(4)
    ShowToast("Status", "All systems operational. Undetected.", "info")
end)

-- =================== API (return) ===================
ObsidianUI.ShowToast = ShowToast
ObsidianUI.ScreenGui = ScreenGui
ObsidianUI.MainWindow = MainWindow
ObsidianUI.Themes = Themes
ObsidianUI.ApplyTheme = ApplyTheme

print("[ObsidianUI] Premium v1.0 loaded successfully!")
print("[ObsidianUI] Toggle UI: RightShift")

return ObsidianUI
