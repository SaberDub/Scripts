local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

getgenv().InfParry = true
getgenv().Invincible = true

local function InfParry()
    while getgenv().InfParry == true do
    task.wait(0.1)
	game.ReplicatedStorage.RemoteFunctions.Parry:InvokeServer()
    end
end

local function Invincible()
    while getgenv().Invincible == true do
    task.wait(0.1)
	game.ReplicatedStorage.RemoteFunctions.Spawn:InvokeServer()
    end
end

local Window = Library:CreateWindow({
	Title = 'Rampant: Blade Battleground',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
	Main = Window:AddTab('Main'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local Groupbox1 = Tabs.Main:AddLeftGroupbox('Toggles')

Groupbox1:AddToggle('Inf Parry', {
    Text = 'Infintie Parry',
    Default = false, -- Default value (true / false)
    Tooltip = 'Press this to infinitely parry', -- Information shown when you hover over the toggle

    Callback = function(Value)
        getgenv().InfParry = Value
		InfParry()
    end
})
Groupbox1:AddToggle('Invincible', {
    Text = 'Invincible',
    Default = false, -- Default value (true / false)
    Tooltip = 'Take no damage', -- Information shown when you hover over the toggle

    Callback = function(Value)
        getgenv().Invincible = Value
		Invincible()
    end
})

local MyButton = Groupbox1:AddButton({
    Text = 'Respawn',
    Func = function()
		game.ReplicatedStorage.RemoteEvents.Respawn:FireServer()
    end,
    DoubleClick = false,
    Tooltip = 'Lets you respawn instantly'
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




