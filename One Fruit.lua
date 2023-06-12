local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local MainWindow = Library:CreateWindow({
    Title = 'One Fruit',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = MainWindow:AddTab('Main'),
    ['UI Settings'] = MainWindow:AddTab('UI Settings'),
}

local attackfarmAuto = false
local chestfarmAuto = false
local fruitfarmAuto = false
local fruitstatfarmAuto = false
local defensestatfarmAuto = false
local Islands = {}
local NPCs = {}
local NPCLocations = {}
local IslandRequested
local NPCRequested
local fruits = {"Barrier", "Bomb", "Dark", "Dragon", "Electric", "Fire", "Gravity", "Ice", "Invisible", "Kilo", "Light", "Love", "Magma", "Mochi", "Paw", "Rubber", "Sand", "Smoke", "Snow", "Spin", "String", "Tremor"}


local function npcTP()
    for i, v in pairs(game.Workspace.__GAME.__Interactions:GetChildren()) do
        table.insert(NPCs, v.Name)
        
        local shipSellerPos = table.find(NPCs, "Ship Seller")
        if shipSellerPos then
            table.remove(NPCs, shipSellerPos)
        end
    end

    for i, v in pairs(game.Workspace.__GAME.__Interactions:GetChildren()) do
        for count = 1, 21, 1 do
            if v.Name == NPCs[count] then
                table.insert(NPCLocations, v)
            end
        end
    end
    
    if NPCRequested == "Gacha" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[1]:GetPivot())
    elseif NPCRequested == "Sword" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[2]:GetPivot())
    elseif NPCRequested == "Sword2" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[5]:GetPivot())
    elseif NPCRequested == "Sword3" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[6]:GetPivot())
    elseif NPCRequested == "GeppoGiver" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[3]:GetPivot())
    elseif NPCRequested == "HakiGiver" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[4]:GetPivot())
    elseif NPCRequested == "HakiColor" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[7]:GetPivot())
    elseif NPCRequested == "KenHaki" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[9]:GetPivot())
    elseif NPCRequested == "BlackLeg" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[8]:GetPivot())
    elseif NPCRequested == "Soru" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[10]:GetPivot())
    elseif NPCRequested == "Combat" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[11]:GetPivot())
    elseif NPCRequested == "GunMan" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[12]:GetPivot())
    elseif NPCRequested == "LogPose" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[13]:GetPivot())
    elseif NPCRequested == "TradeInvite" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[14]:GetPivot())
    elseif NPCRequested == "Hachi" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[15]:GetPivot())
    elseif NPCRequested == "StockMarket" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[16]:GetPivot())
    elseif NPCRequested == "TradeHubT" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[17]:GetPivot())
    elseif NPCRequested == "THub" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[18]:GetPivot())
    elseif NPCRequested == "PirateJoin" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[19]:GetPivot())
    elseif NPCRequested == "MarineJoin" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[20]:GetPivot())
    elseif NPCRequested == "SeaTeleport" then
        game.Players.LocalPlayer.Character:PivotTo(NPCLocations[21]:GetPivot())
    end
end

local function IslandTP()
    for i, v in pairs(game.Workspace.__Zones.__IslandPos:GetChildren()) do
        table.insert(Islands, v)
    end
    if IslandRequested == "Arena" then
        game.Players.LocalPlayer.Character:PivotTo(Islands[1]:GetPivot())
    elseif IslandRequested == "Arlong" then
        game.Players.LocalPlayer.Character:PivotTo(Islands[2]:GetPivot())
    elseif IslandRequested == "Baratie" then
        game.Players.LocalPlayer.Character:PivotTo(Islands[3]:GetPivot())
    elseif IslandRequested == "Buggy" then
        game.Players.LocalPlayer.Character:PivotTo(Islands[4]:GetPivot())
    elseif IslandRequested == "Jungle" then 
        game.Players.LocalPlayer.Character:PivotTo(Islands[5]:GetPivot())
    elseif IslandRequested == "Logue" then 
        game.Players.LocalPlayer.Character:PivotTo(Islands[6]:GetPivot())
    elseif IslandRequested == "Marine" then
        game.Players.LocalPlayer.Character:PivotTo(Islands[7]:GetPivot())
    elseif IslandRequested == "Starter" then
        game.Players.LocalPlayer.Character:PivotTo(Islands[8]:GetPivot())
    elseif IslandRequested == "Usopp" then
        game.Players.LocalPlayer.Character:PivotTo(Islands[9]:GetPivot())
    end
end

local function chestfarm()
        for i, v in pairs(game.Workspace:GetChildren()) do
            for i, x in pairs(v:GetDescendants()) do
                if x.Name == "ChestInteract" then
                    if chestfarmAuto == true then
                        game.Players.LocalPlayer.Character:PivotTo(x.Parent.Baixo.Detalhe:GetPivot())
                        task.wait(2)
                        fireproximityprompt(x)
                    else
                        break
                end
            end
        end
    end
end



local function fruitfarm()
        for i, v in pairs(game.Workspace:GetChildren()) do
            for i, x in pairs(v:GetDescendants()) do
                if x.Name == "Eat" then
                    if fruitfarmAuto == true then
                        game.Players.LocalPlayer.Character:PivotTo(x.Parent.PrimaryPart:GetPivot())
                        task.wait(0.5)
                        fireproximityprompt(x)
                    else
                        break
                end
            end
        end
    end
    for i, v in pairs(game.Workspace:GetChildren()) do
        if v:IsA("Tool") then 
            if string.find(v.Name, "Fruit") then
                if fruitfarmAuto == true then 
                    game.Players.LocalPlayer.Character:PivotTo(v:GetPivot())
                else
                    break
                end 
            end
        end
    end
end

local function atkfarm()
while attackfarmAuto == true do
    for i,v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
        if v.name == "Combat" then
            v.Parent = game.Players.LocalPlayer.Character
        end
    end
        task.wait()
            local args = {
                [1] = {
                    [1] = {
                        [1] = "\4",
                        [2] = "Combat",
                        [3] = 1,
                        [4] = false,
                        [5] = game:GetService("Players").LocalPlayer.Character.Combat,
                        [6] = "Melee"
                    }
                }
            }

        game:GetService("ReplicatedStorage").RemoteEvent:FireServer(unpack(args))
    end
end

local function fruitstatfarm()
for i, v in pairs(game:GetService("Players").LocalPlayer.Character:GetChildren()) do
        if v:IsA("Tool") then
            if v:GetAttribute("Type") == "Fruit" then
                local fruitTool = v
                while fruitstatfarmAuto == true do
                    task.wait()
                        local args = {
                            [1] = {
                                [1] = {
                                    [1] = "\4",
                                    [2] = "Combat",
                                    [3] = 1,
                                    [4] = false,
                                    [5] = game:GetService("Players").LocalPlayer.Character:FindFirstChild(fruitTool.Name), -- this part doesn't work fix it
                                    [6] = "Fruit"
                                }
                            }
                        }
                    game:GetService("ReplicatedStorage").RemoteEvent:FireServer(unpack(args))
                end
            end
        end
    end
end

local function defensestatfarm()
    for i,v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
        if v.name == "Defence" then
            v.Parent = game.Players.LocalPlayer.Character
        end
    end
    while defensestatfarmAuto == true do
        task.wait()
            local args = {
                [1] = {
                    [1] = {
                        [1] = "\4",
                        [2] = "Defence",
                        [3] = game:GetService("Players").LocalPlayer.Character.Defence,
                        [4] = "Defence"
                    }
                }
            }
        game:GetService("ReplicatedStorage").RemoteEvent:FireServer(unpack(args))
    end
end

local ChestFarm = Tabs.Main:AddLeftGroupbox('Chest Farm')

ChestFarm:AddToggle('Chestframming', {
    Text = 'Autofarm',
    Default = false,
    Tooltip = 'Autofarm Chests',

    Callback = function(Value)
        chestfarmAuto = Value
        chestfarm()
    end
})

local FruitFarm = Tabs.Main:AddLeftGroupbox('Fruit Farm')

FruitFarm:AddToggle('Fruitframming', {
    Text = 'Autofarm',
    Default = false,
    Tooltip = 'Autofarm Fruits (also picks up dropped fruits)',

    Callback = function(Value)
        fruitfarmAuto = Value
        fruitfarm()
    end
})

local StatFarm = Tabs.Main:AddLeftGroupbox('Stat Farm')

StatFarm:AddToggle('Attackstatframming', { 
    Text = 'Farm Attack Stat',
    Default = false,
    Tooltip = 'Autofarms Attack Stat',

    Callback = function(Value)
        attackfarmAuto = Value
        atkfarm()
    end
})

StatFarm:AddToggle('Fruitstatframming', { 
    Text = 'Farm Fruit Stat',
    Default = false,
    Tooltip = 'Autofarms Fruit Stat (EQUIP FRUIT TOOL)',

    Callback = function(Value)
        fruitstatfarmAuto = Value
        fruitstatfarm()
    end
})

StatFarm:AddToggle('Defensestatframming', {
    Text = 'Farm Defense Stat',
    Default = false,
    Tooltip = 'Autofarms Defense Stat',

    Callback = function(Value)
        defensestatfarmAuto = Value
        defensestatfarm()
    end
})

local Teleport = Tabs.Main:AddRightGroupbox(' ')

Teleport:AddDropdown('MyDropdown', {
    Values = {'None', 'Arena', 'Arlong', 'Baratie', 'Buggy', 'Jungle', 'Logue', 'Marine', 'Starter', 'Usopp'},
    Default = 1,
    Multi = false,

    Text = 'Island TP',
    Tooltip = 'Teleports you to the selected island',

    Callback = function(Value)
        IslandRequested = Value
        IslandTP()
    end
})

Teleport:AddDropdown('MyDropdown', {
    Values = {'None', 'Gacha', 'Sword', 'Sword2', 'Sword3', 'GeppoGiver', 'HakiGiver', 'HakiColor', 'KenHaki', 'BlackLeg', 'Soru', 'Combat', 'GunMan', 'LogPose', 'TradeInvite', 'Hachi', 'StockMarket', 'TradeHubT', 'THub', 'PirateJoin', 'MarineJoin', 'SeaTeleport'},
    Default = 1,
    Multi = false,

    Text = 'NPC TP',
    Tooltip = 'Teleports you to the selected NPC',

    Callback = function(Value)
        NPCRequested = Value
        npcTP()
    end
})



local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'LeftControl', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/specific-game')

SaveManager:BuildConfigSection(Tabs['UI Settings'])

ThemeManager:ApplyToTab(Tabs['UI Settings'])

SaveManager:LoadAutoloadConfig()
