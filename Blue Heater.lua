local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

getgenv().MobFarm = true
getgenv().ChestFarm = true
getgenv().KillAura = true

local discordjoin = 'https://discord.gg/dYVZYNqTqf'

local Settings = {
    FarmSettings = {
        AutoFarmToggle = false,
        Distance = 5,
        Method = "Below",
        NPCs = {},
        SelectedNPCs = {},
        },
    Stam = true,
    CFrames = {
        Spawn = CFrame.new(975, 1600, -160)
    }
}

local Window = Library:CreateWindow({
	Title = 'Blue Heater',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

--functions

local function KillAura()
    while getgenv().KillAura == true do
        task.wait()
        for i, v in pairs(game.Workspace.SpawnedMobs:GetChildren()) do
            local RootPart1 = v:FindFirstChild("HumanoidRootPart", true)
            if RootPart1 ~= nil then
                local distance = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
                if distance <= 20 then
                    local args = {
                        [1] = v
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("CharacterEvents"):WaitForChild("DamageReached"):FireServer(unpack(args))
                end
            end
        end
    end
end



local function GetMobs()
    for i, v in pairs(game.Workspace.SpawnedMobs:GetChildren()) do
        if table.find(Settings.FarmSettings.NPCs, v.Name) ~= nil then
            continue
        end

        table.insert(Settings.FarmSettings.NPCs, v.Name)
    end
end

local function Stam()
    if Settings.Stam ~= true then
        return
    end

    getrenv()._G.Action = ""
    game.Players.LocalPlayer.Character.Stats.Stamina.Current.Value = 100
end

local function GoToMob(instance)
    if instance == nil then
        return nil
    end
    
    local Char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait(0)

    local RootPart1 = instance:FindFirstChild("HumanoidRootPart", true)
    if RootPart1 == nil or RootPart1.CFrame.Y < 1000 then
        return nil
    end

    if Settings.FarmSettings.Method == "Above" then
        Char:PivotTo(instance:GetPivot() * CFrame.new(0, Settings.FarmSettings.Distance, 0) * CFrame.Angles(math.rad(-90),0,0))
    elseif Settings.FarmSettings.Method == "Behind" then
        Char:PivotTo(instance:GetPivot() * CFrame.new(0, 0, Settings.FarmSettings.Distance))
    elseif Settings.FarmSettings.Method == "Below" then
        Char:PivotTo(instance:GetPivot() * CFrame.new(0, -Settings.FarmSettings.Distance, 0))
    end
end


local function Stam()
    if Settings.Stam ~= true then
        return
    end

    getrenv()._G.Action = ""
    game.Players.LocalPlayer.Character.Stats.Stamina.Current.Value = 100
end

local function ChestFarm()
    while getgenv().ChestFarm == true do
        task.wait()
    for i, v in pairs(game.Workspace:GetChildren()) do
            if string.find(v.Name, "Chest") then
                local Proxy = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                if Proxy then
                    game.Players.LocalPlayer.Character:PivotTo(v:GetPivot())
                    fireproximityprompt(Proxy)
                end
            end
        end
    end
end

local function toClipboard(String)
	local clipBoard = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
	if clipBoard then
		clipBoard(String)
    else end
end

local Tabs = {
	Main = Window:AddTab('Main'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local Autofarm = Tabs.Main:AddLeftGroupbox('Autofarming')

GetMobs()

Autofarm:AddToggle('Farming Toggle', {
    Text = 'Auto Farm Toggle',
    Default = false,
    Tooltip = 'Toggles the Autofarm',

    Callback = function(Value)
        Settings.FarmSettings.AutoFarmToggle = Value
    end
})

Autofarm:AddDropdown('Method', {
    Values = {"Above", "Below", "Behind"},
    Default = 2,
    Multi = false,

    Text = "Attack Method",
    Tooltip = 'Choose where you want to attack from',

    Callback = function(Value)
        Settings.FarmSettings.Method = Value
    end
})

Autofarm:AddSlider('Distance', {
    Text = 'Distance From Mob',
    Default = 3,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        Settings.FarmSettings.Distance = Value
    end
})

local NPCDrop = Autofarm:AddDropdown('NPCs', {
    Values = Settings.FarmSettings.NPCs;
    Default = 0,
    Multi = true,

    Text = "Mob Select",
    Tooltip = 'Select Mob to Farm them',

    Callback = function(Value)
        Settings.FarmSettings.SelectedNPCs = Value
    end
})

Autofarm:AddButton({
    Text = 'Refresh Mobs',
    DoubleClick = false,
    Tooltip = 'Refresh the Mobs in the Dropdown',
    Func = function()
        GetMobs()
        NPCDrop:SetValue(Settings.FarmSettings.NPCs)
    end,
})


local MyButton = Autofarm:AddButton({
    Text = 'Chest Farm',
    Func = function()
		for i, v in pairs(game.Workspace:GetChildren()) do
            if string.find(v.Name, "Chest") then
                local Proxy = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                if Proxy then
                    game.Players.LocalPlayer.Character:PivotTo(v:GetPivot())
                    fireproximityprompt(Proxy)
                end
            end
          end
    end,
    DoubleClick = false,
    Tooltip = 'Lets you respawn instantly'
})

local Toggles = Tabs.Main:AddLeftGroupbox('Toggles')

Toggles:AddToggle('KillAura', {
    Text = 'Kill Aura',
    Default = false,
    Tooltip = 'Toggle Kill Aura',

    Callback = function(Value)
        getgenv().KillAura = Value
        KillAura()
    end
})

Toggles:AddToggle('InfStam', {
    Text = 'Infinite Stamina',
    Default = false,
    Tooltip = 'Toggle Infinite Stamina',

    Callback = function(Value)
    Settings.Stam = Value
    Stam()
    end
})

Toggles:AddToggle('Chest Auto', {
    Text = 'Chest Auto Farm',
    Default = false,
    Tooltip = 'Toggle Kill Aura',

    Callback = function(Value)
        getgenv().ChestFarm = Value
        ChestFarm()
    end
})

local DiscordGroup = Tabs.Main:AddRightGroupbox('Discord')

local MyButton = DiscordGroup:AddButton({
    Text = 'Copy Discord Link',
    Func = function()
    toClipboard(discordjoin)
    end,
    DoubleClick = false,
    Tooltip = 'Join the Discord!'
})

DiscordGroup:AddLabel('Script made by Saber#2638')

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

game:GetService("RunService").Stepped:Connect(function()
    Stam()
    if Settings.FarmSettings.AutoFarmToggle == true then
        for _, v in pairs(game.Workspace.SpawnedMobs:GetChildren()) do
            if Settings.FarmSettings.SelectedNPCs[v.Name] == true and Settings.FarmSettings.AutoFarmToggle ~= false then
                while true do 
                    task.wait()
                    GoToMob(v)
                    if Settings.FarmSettings.AutoFarmToggle == false or v == nil or v.Humanoid.Health == 0 then
                        break
                    end
                end
            end
        end
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = Settings.CFrames.Spawn
    end
end)
