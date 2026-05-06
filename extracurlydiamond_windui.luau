local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Network = require(RS.Modules.Communication.Network)

local lp = Players.LocalPlayer
local qte = lp.PlayerGui:WaitForChild("QTE")
local main = qte:WaitForChild("Main")
local line = main:WaitForChild("Line")
local bars = main:WaitForChild("Bars")
local wayStones = workspace:WaitForChild("WayStones")

local autoDigEventMethod = false
local autoTargetDig = false
local autoSell = false
local autoMerchant = false
local eventDelay = 0.5
local sellDelay = 30
local favoritedItems = {}
local weightFilters = {}
local selectedWeightItem = ""
local selectedBuyTool = ""
local minWeightInput = 0
local targetRarities = {}
local workerCount = 3
local lock = false

local fishList = {}
local shellTools = RS:WaitForChild("Assets"):WaitForChild("Shells"):WaitForChild("Tools")
for _, item in pairs(shellTools:GetChildren()) do
    table.insert(fishList, item.Name)
end
table.sort(fishList)

local equipList = {}
local equipTools = RS:WaitForChild("Assets"):WaitForChild("Equipment"):WaitForChild("Tools")
task.wait(3)
for _, item in pairs(equipTools:GetChildren()) do
    table.insert(equipList, item.Name)
end
table.sort(equipList)

local islandList = {}
for _, island in pairs(wayStones:GetChildren()) do
    table.insert(islandList, island.Name)
end
table.sort(islandList)

local function favoriteAll()
    for _, tool in pairs(lp.Backpack:GetChildren()) do
        local fishName = tool.Name:split("_")[1]
        if favoritedItems[fishName] then
            pcall(function()
                local args = {
                    buffer.fromstring("\003\001\001"),
                    {tool}
                }
                RS:WaitForChild("ByteNetReliable"):FireServer(unpack(args))
            end)
        end
    end
end

local function favoriteByWeight()
    for _, tool in pairs(lp.Backpack:GetChildren()) do
        local fishName = tool.Name:split("_")[1]
        local minWeight = weightFilters[fishName]
        if minWeight then
            local weight = tool:GetAttribute("Weight")
            if weight and weight >= minWeight then
                pcall(function()
                    local args = {
                        buffer.fromstring("\003\001\001"),
                        {tool}
                    }
                    RS:WaitForChild("ByteNetReliable"):FireServer(unpack(args))
                end)
            end
        end
    end
end

local function teleportTo(islandName)
    local island = wayStones:FindFirstChild(islandName)
    if island then
        local char = lp.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = island:GetModelCFrame()
        end
    end
end

local function buyAllMerchant()
    local buying = true
    while buying do
        buying = false
        local result = Network.TravellingMerchant.queries.GetShop.invoke()
        if result then
            local data = HttpService:JSONDecode(result)
            if data.isActive then
                for item, stock in pairs(data.stock or {}) do
                    if stock > 0 then
                        pcall(function()
                            local buyResult = Network.TravellingMerchant.queries.BuyItem.invoke(item)
                            if buyResult and buyResult.success then
                                if buyResult.remaining > 0 then
                                    buying = true
                                end
                            end
                        end)
                        task.wait(0.1)
                    end
                end
            end
        end
    end
end

local function isTargetRarity(rarity)
    return targetRarities[rarity] == true
end

local function spawnWorkers()
    for i = 1, workerCount do
        task.spawn(function()
            while autoTargetDig do
                if not lock then
                    lock = true
                    pcall(function()
                        local args1 = {
                            buffer.fromstring("\016"),
                            [3] = 16
                        }
                        RS:WaitForChild("ByteNetQuery"):InvokeServer(unpack(args1, 1, 3))
                        task.wait(0)
                        local result = Network.QTE.queries.StartQTE.invoke()
                        if result and result.rarity then
                            if isTargetRarity(result.rarity) then
                                task.wait(2)
                                Network.QTE.packets.FinishQTE.send({
                                    state = true,
                                    hits = 45,
                                    perfects = 30
                                })
                                task.wait(1)
                            else
                                Network.QTE.packets.CancelQTE.send()
                            end
                        end
                    end)
                    lock = false
                end
                task.wait(0)
            end
        end)
        task.wait(0.05)
    end
end

-- WindUI v2 Window
local Window = WindUI:CreateWindow({
    Title = "extracurlydiamond",
    Icon = "🌀",
    Author = "CoiledTom",
    Folder = "extracurlydiamond",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
})

local Tabs = {
    Dig      = Window:Tab({ Title = "Auto Dig",      Icon = "pickaxe" }),
    Sell     = Window:Tab({ Title = "Auto Sell",     Icon = "dollar-sign" }),
    Fav      = Window:Tab({ Title = "Auto Favorite", Icon = "star" }),
    FavW     = Window:Tab({ Title = "Fav by Weight", Icon = "scale" }),
    Buy      = Window:Tab({ Title = "Buy Tool",      Icon = "shopping-cart" }),
    Tp       = Window:Tab({ Title = "Teleport",      Icon = "map-pin" }),
    Merchant = Window:Tab({ Title = "Merchant",      Icon = "store" }),
}

-- ══════════════════════════════════════════
--  AUTO DIG TAB
-- ══════════════════════════════════════════

Tabs.Dig:Section({ Title = "Method 2 - Event Fire" })

Tabs.Dig:Toggle({
    Title = "Auto Dig (Events)",
    Default = false,
    Callback = function(val)
        autoDigEventMethod = val
        if val then
            task.spawn(function()
                while autoDigEventMethod do
                    pcall(function()
                        local args1 = {
                            buffer.fromstring("\016"),
                            [3] = 16
                        }
                        RS:WaitForChild("ByteNetQuery"):InvokeServer(unpack(args1, 1, 3))
                    end)
                    task.wait(eventDelay)
                    pcall(function()
                        local args2 = {
                            buffer.fromstring("*\001\002\000\002\000")
                        }
                        RS:WaitForChild("ByteNetReliable"):FireServer(unpack(args2))
                    end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

Tabs.Dig:Slider({
    Title = "Event Loop Delay (s)",
    Min = 0.1,
    Max = 1,
    Default = 0.5,
    Decimals = 1,
    Callback = function(val)
        eventDelay = val
    end
})

Tabs.Dig:Section({ Title = "Method 3 - Targeted Dig" })

Tabs.Dig:Toggle({
    Title = "Target: Legendary",
    Default = false,
    Callback = function(val)
        targetRarities["Legendary"] = val
    end
})

Tabs.Dig:Toggle({
    Title = "Target: Mythic",
    Default = false,
    Callback = function(val)
        targetRarities["Mythic"] = val
    end
})

Tabs.Dig:Toggle({
    Title = "Target: Exotic",
    Default = false,
    Callback = function(val)
        targetRarities["Exotic"] = val
    end
})

Tabs.Dig:Slider({
    Title = "Worker Count",
    Min = 1,
    Max = 10,
    Default = 3,
    Decimals = 0,
    Callback = function(val)
        workerCount = val
    end
})

Tabs.Dig:Toggle({
    Title = "Targeted Dig",
    Default = false,
    Callback = function(val)
        autoTargetDig = val
        if val then
            spawnWorkers()
        end
    end
})

-- ══════════════════════════════════════════
--  AUTO SELL TAB
-- ══════════════════════════════════════════

Tabs.Sell:Section({ Title = "Auto Sell" })

Tabs.Sell:Toggle({
    Title = "Auto Sell",
    Default = false,
    Callback = function(val)
        autoSell = val
        if val then
            task.spawn(function()
                while autoSell do
                    pcall(function()
                        Network.Merchant.packets.SellAll.send()
                    end)
                    task.wait(sellDelay)
                end
            end)
        end
    end
})

Tabs.Sell:Slider({
    Title = "Sell Delay (s)",
    Min = 10,
    Max = 60,
    Default = 30,
    Decimals = 0,
    Callback = function(val)
        sellDelay = val
    end
})

-- ══════════════════════════════════════════
--  AUTO FAVORITE TAB
-- ══════════════════════════════════════════

Tabs.Fav:Section({ Title = "Select Items to Favorite" })

for _, fishName in pairs(fishList) do
    Tabs.Fav:Toggle({
        Title = fishName,
        Default = false,
        Callback = function(val)
            favoritedItems[fishName] = val
        end
    })
end

Tabs.Fav:Section({ Title = "Run" })

Tabs.Fav:Button({
    Title = "Favorite Selected Now",
    Callback = function()
        favoriteAll()
        Window:Notification({
            Title = "Auto Favorite",
            Content = "Favorited all selected items in backpack!",
            Duration = 2,
        })
    end
})

Tabs.Fav:Toggle({
    Title = "Auto Favorite on Backpack Change",
    Default = false,
    Callback = function(val)
        if val then
            lp.Backpack.ChildAdded:Connect(function()
                task.wait(0.1)
                favoriteAll()
            end)
        end
    end
})

-- ══════════════════════════════════════════
--  FAV BY WEIGHT TAB
-- ══════════════════════════════════════════

Tabs.FavW:Section({ Title = "Add Weight Filter" })

Tabs.FavW:Dropdown({
    Title = "Select Item",
    Values = fishList,
    Default = fishList[1],
    Callback = function(val)
        selectedWeightItem = val
    end
})

Tabs.FavW:Input({
    Title = "Minimum Weight (kg)",
    Placeholder = "e.g. 50",
    Callback = function(val)
        minWeightInput = tonumber(val) or 0
    end
})

local weightListLabel = Tabs.FavW:Paragraph({
    Title = "Active Filters",
    Content = "None"
})

local function updateWeightList()
    local lines = {}
    for name, w in pairs(weightFilters) do
        table.insert(lines, name .. " >= " .. w .. " kg")
    end
    weightListLabel:Set({
        Title = "Active Filters",
        Content = #lines > 0 and table.concat(lines, "\n") or "None"
    })
end

Tabs.FavW:Button({
    Title = "Add Filter",
    Callback = function()
        if selectedWeightItem ~= "" and minWeightInput > 0 then
            weightFilters[selectedWeightItem] = minWeightInput
            updateWeightList()
            Window:Notification({
                Title = "Filter Added",
                Content = selectedWeightItem .. " >= " .. minWeightInput .. " kg",
                Duration = 2,
            })
        else
            Window:Notification({
                Title = "Error",
                Content = "Select an item and enter a valid weight!",
                Duration = 2,
            })
        end
    end
})

Tabs.FavW:Button({
    Title = "Remove Selected Filter",
    Callback = function()
        if weightFilters[selectedWeightItem] then
            weightFilters[selectedWeightItem] = nil
            updateWeightList()
            Window:Notification({
                Title = "Filter Removed",
                Content = selectedWeightItem .. " filter removed.",
                Duration = 2,
            })
        end
    end
})

Tabs.FavW:Section({ Title = "Run" })

Tabs.FavW:Button({
    Title = "Favorite by Weight Now",
    Callback = function()
        favoriteByWeight()
        Window:Notification({
            Title = "Auto Favorite",
            Content = "Favorited items matching weight filters!",
            Duration = 2,
        })
    end
})

Tabs.FavW:Toggle({
    Title = "Auto Favorite by Weight on Backpack Change",
    Default = false,
    Callback = function(val)
        if val then
            lp.Backpack.ChildAdded:Connect(function()
                task.wait(0.1)
                favoriteByWeight()
            end)
        end
    end
})

-- ══════════════════════════════════════════
--  BUY TOOL TAB
-- ══════════════════════════════════════════

Tabs.Buy:Section({ Title = "Select Tool to Buy" })

Tabs.Buy:Dropdown({
    Title = "Select Tool",
    Values = equipList,
    Default = equipList[1],
    Callback = function(val)
        selectedBuyTool = val
    end
})

Tabs.Buy:Button({
    Title = "Buy",
    Callback = function()
        if selectedBuyTool ~= "" then
            pcall(function()
                Network.Equipment.queries.Buy.invoke(selectedBuyTool)
            end)
            Window:Notification({
                Title = "Buy Tool",
                Content = "Attempted to buy: " .. selectedBuyTool,
                Duration = 2,
            })
        else
            Window:Notification({
                Title = "Error",
                Content = "Please select a tool first!",
                Duration = 2,
            })
        end
    end
})

-- ══════════════════════════════════════════
--  TELEPORT TAB
-- ══════════════════════════════════════════

Tabs.Tp:Section({ Title = "Islands" })

for _, name in pairs(islandList) do
    Tabs.Tp:Button({
        Title = name,
        Callback = function()
            teleportTo(name)
            Window:Notification({
                Title = "Teleport",
                Content = "Teleporting to " .. name,
                Duration = 2,
            })
        end
    })
end

-- ══════════════════════════════════════════
--  MERCHANT TAB
-- ══════════════════════════════════════════

Tabs.Merchant:Section({ Title = "Travelling Merchant" })

Tabs.Merchant:Button({
    Title = "Check Merchant Status",
    Callback = function()
        pcall(function()
            local result = Network.TravellingMerchant.queries.GetShop.invoke()
            if result then
                local data = HttpService:JSONDecode(result)
                if data.isActive then
                    Window:Notification({
                        Title = "Merchant",
                        Content = "Merchant is currently ACTIVE!",
                        Duration = 3,
                    })
                else
                    local timeLeft = data.nextChangeTime - os.time()
                    local mins = math.floor(timeLeft / 60)
                    local secs = timeLeft % 60
                    Window:Notification({
                        Title = "Merchant",
                        Content = "Arrives in: " .. mins .. "m " .. secs .. "s",
                        Duration = 3,
                    })
                end
            end
        end)
    end
})

Tabs.Merchant:Button({
    Title = "Buy All Now",
    Callback = function()
        pcall(function()
            local result = Network.TravellingMerchant.queries.GetShop.invoke()
            if result then
                local data = HttpService:JSONDecode(result)
                if data.isActive then
                    task.spawn(buyAllMerchant)
                    Window:Notification({
                        Title = "Merchant",
                        Content = "Buying all items!",
                        Duration = 2,
                    })
                else
                    Window:Notification({
                        Title = "Merchant",
                        Content = "Merchant is not active!",
                        Duration = 2,
                    })
                end
            end
        end)
    end
})

Tabs.Merchant:Toggle({
    Title = "Auto Buy When Merchant Arrives",
    Default = false,
    Callback = function(val)
        autoMerchant = val
        if val then
            task.spawn(function()
                local merchantBought = false
                while autoMerchant do
                    pcall(function()
                        local result = Network.TravellingMerchant.queries.GetShop.invoke()
                        if result then
                            local data = HttpService:JSONDecode(result)
                            if data.isActive and not merchantBought then
                                buyAllMerchant()
                                merchantBought = true
                                Window:Notification({
                                    Title = "Merchant",
                                    Content = "Bought all merchant items!",
                                    Duration = 3,
                                })
                            elseif not data.isActive then
                                merchantBought = false
                            end
                        end
                    end)
                    task.wait(5)
                end
            end)
        end
    end
})

Window:Notification({
    Title = "extracurlydiamond",
    Content = "Loaded successfully!",
    Duration = 3,
})
