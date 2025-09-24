-- Advanced Parallel ESP System with Actor Support
-- Combines parallel processing with fallback to single-threaded mode

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local CorePackages = game:GetService("CorePackages")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Executor detection
local isSynapseV3 = not not gethui
local hasActorSupport = syn and syn.create_comm_channel

-- Configuration table (replaces UI library flags)
local ESPConfig = {
    enabled = true,
    showDistance = true,
    showHealth = true,
    maxDistance = 10000,
    teamCheck = false,
    visibilityCheck = true,
    useFOV = false,
    FOV = 90,
    espSearch = "", -- For search functionality
    colors = {
        default = Color3.new(1, 1, 1),
        team = Color3.new(0, 1, 0),
        enemy = Color3.new(1, 0, 0)
    }
}

-- Flag system for compatibility
local flags = setmetatable({}, {
    __index = function(self, key)
        -- Map common flag names to config
        if key:find("ShowDistance") then
            return ESPConfig.showDistance
        elseif key:find("ShowHealth") then
            return ESPConfig.showHealth
        elseif key:find("MaxDistance") then
            return ESPConfig.maxDistance
        elseif key:find("Color") then
            return ESPConfig.colors.default
        elseif key:find("espSearch") then
            return ESPConfig.espSearch
        end
        return rawget(self, key)
    end,
    __newindex = function(self, key, value)
        rawset(self, key, value)
    end
})

-- Maid implementation (simplified version)
local Maid = {}
Maid.__index = Maid
Maid.ClassName = "Maid"

function Maid.new()
    return setmetatable({
        _tasks = {}
    }, Maid)
end

function Maid.isMaid(value)
    return type(value) == "table" and value.ClassName == "Maid"
end

function Maid:__index(index)
    if Maid[index] then
        return Maid[index]
    else
        return self._tasks[index]
    end
end

function Maid:__newindex(index, newTask)
    if Maid[index] ~= nil then
        error(("'%s' is reserved"):format(tostring(index)), 2)
    end

    local tasks = self._tasks
    local oldTask = tasks[index]

    if oldTask == newTask then
        return
    end

    tasks[index] = newTask

    if oldTask then
        if type(oldTask) == "function" then
            oldTask()
        elseif typeof(oldTask) == "RBXScriptConnection" then
            oldTask:Disconnect()
        elseif typeof(oldTask) == "thread" then
            task.cancel(oldTask)
        elseif oldTask.Destroy then
            oldTask:Destroy()
        end
    end
end

function Maid:GiveTask(task)
    if not task then
        error("Task cannot be false or nil", 2)
    end

    local taskId = #self._tasks + 1
    self[taskId] = task

    return taskId
end

function Maid:Destroy()
    local tasks = self._tasks

    -- Disconnect all events first
    for index, task in pairs(tasks) do
        if typeof(task) == "RBXScriptConnection" then
            tasks[index] = nil
            task:Disconnect()
        end
    end

    -- Clean remaining tasks
    local index, task = next(tasks)
    while task ~= nil do
        tasks[index] = nil
        if type(task) == "function" then
            task()
        elseif typeof(task) == "RBXScriptConnection" then
            task:Disconnect()
        elseif typeof(task) == "thread" then
            task.cancel(task)
        elseif task.Destroy then
            task:Destroy()
        end
        index, task = next(tasks)
    end
end

Maid.DoCleaning = Maid.Destroy

-- Signal implementation
local Signal = {}
Signal.__index = Signal
Signal.ClassName = "Signal"

function Signal.new()
    local self = setmetatable({}, Signal)
    self._bindableEvent = Instance.new("BindableEvent")
    self._argData = nil
    self._argCount = nil
    return self
end

function Signal.isSignal(object)
    return typeof(object) == 'table' and getmetatable(object) == Signal
end

function Signal:Fire(...)
    self._argData = {...}
    self._argCount = select("#", ...)
    self._bindableEvent:Fire()
    self._argData = nil
    self._argCount = nil
end

function Signal:Connect(handler)
    if not self._bindableEvent then return error("Signal has been destroyed") end
    return self._bindableEvent.Event:Connect(function()
        handler(unpack(self._argData, 1, self._argCount))
    end)
end

function Signal:Destroy()
    if self._bindableEvent then
        self._bindableEvent:Destroy()
        self._bindableEvent = nil
    end
    self._argData = nil
    self._argCount = nil
end

-- Services wrapper
local Services = setmetatable({}, {
    __index = function(self, serviceName)
        local service = game:GetService(serviceName)
        rawset(self, serviceName, service)
        return service
    end
})

-- Helper function to convert to camelCase
local function toCamelCase(text)
    return string.lower(text):gsub("%s(.)", string.upper)
end

-- Utility module
local Utility = {}
Utility.onPlayerAdded = Signal.new()
Utility.onCharacterAdded = Signal.new()
Utility.onLocalCharacterAdded = Signal.new()

local playersData = {}

function Utility:getPlayerData(player)
    return playersData[player or LocalPlayer] or {}
end

function Utility:getCharacter(player)
    local playerData = self:getPlayerData(player)
    if not playerData.alive then return end
    
    local maxHealth, health = playerData.maxHealth, playerData.health
    return playerData.character, maxHealth, (health / maxHealth) * 100, math.floor(health), playerData.rootPart
end

function Utility:isTeamMate(player)
    local playerData, myPlayerData = self:getPlayerData(player), self:getPlayerData()
    local playerTeam, myTeam = playerData.team, myPlayerData.team
    
    if playerTeam == nil or myTeam == nil then
        return false
    end
    
    return playerTeam == myTeam
end

function Utility.listenToChildAdded(folder, listener, options)
    options = options or {listenToDestroying = false}
    
    local createListener = typeof(listener) == "table" and listener.new or listener
    
    local function onChildAdded(child)
        local listenerObject = createListener(child)
        
        if options.listenToDestroying then
            child.Destroying:Connect(function()
                if typeof(listenerObject) == "function" then
                    listenerObject(child)
                elseif typeof(listenerObject) == "table" and listenerObject.Destroy then
                    listenerObject:Destroy()
                end
            end)
        end
    end
    
    for _, child in pairs(folder:GetChildren()) do
        task.spawn(onChildAdded, child)
    end
    
    return folder.ChildAdded:Connect(createListener)
end

function Utility.listenToDescendantAdded(folder, listener, options)
    options = options or {listenToDestroying = false}
    
    local createListener = typeof(listener) == "table" and listener.new or listener
    
    local function onDescendantAdded(child)
        local listenerObject = createListener(child)
        
        if options.listenToDestroying then
            child.Destroying:Connect(function()
                if typeof(listenerObject) == "function" then
                    listenerObject(child)
                elseif typeof(listenerObject) == "table" and listenerObject.Destroy then
                    listenerObject:Destroy()
                end
            end)
        end
    end
    
    for _, child in pairs(folder:GetDescendants()) do
        task.spawn(onDescendantAdded, child)
    end
    
    return folder.DescendantAdded:Connect(onDescendantAdded)
end

function Utility.listenToTagAdded(tagName, listener)
    for _, v in pairs(CollectionService:GetTagged(tagName)) do
        task.spawn(listener, v)
    end
    
    return CollectionService:GetInstanceAddedSignal(tagName):Connect(listener)
end

-- Parallel ESP script as string
local parallelESPCode = [[
    local Players = game:GetService('Players');
    local RunService = game:GetService('RunService');
    local LocalPlayer = Players.LocalPlayer;

    local camera, rootPart, rootPartPosition;

    local originalCommEvent = ...;
    local commEvent;

    if (typeof(originalCommEvent) == 'table') then
        commEvent = {
            _event = originalCommEvent._event,

            Connect = function(self, f)
                return self._event.Event:Connect(f)
            end,

            Fire = function(self, ...)
                self._event:Fire(...);
            end
        };
    else
        commEvent = getgenv().syn.get_comm_channel(originalCommEvent);
    end;

    local flags = {};
    local container = {};
    local activeContainer = {};
    
    local DEFAULT_ESP_COLOR = Color3.fromRGB(255, 255, 255);
    local mFloor = math.floor;
    local worldToViewportPoint = Instance.new('Camera').WorldToViewportPoint;
    local vector2New = Vector2.new;

    local updateDrawingQueue = {};
    local destroyDrawingQueue = {};

    local BaseESPParallel = {};
    BaseESPParallel.__index = BaseESPParallel;

    function BaseESPParallel.new(data, showESPFlag)
        local self = setmetatable(data, BaseESPParallel);
        
        local instance, tag, color = self._instance, self._tag, self._color;
        self._showFlag2 = showESPFlag;

        self._label = Drawing.new('Text');
        self._label.Transparency = 1;
        self._label.Color = color or DEFAULT_ESP_COLOR;
        self._label.Text = '[' .. tag .. ']';
        self._label.Center = true;
        self._label.Outline = true;

        container[self._id] = self;

        if self._isLazy then
            self._instancePosition = instance.Position;
        end;

        self:UpdateContainer();
        return self;
    end;

    function BaseESPParallel:Destroy()
        container[self._id] = nil;
        if (table.find(activeContainer, self)) then
            table.remove(activeContainer, table.find(activeContainer, self));
        end;
        table.insert(destroyDrawingQueue, self._label);
    end;

    function BaseESPParallel:Unload()
        table.insert(updateDrawingQueue, {
            label = self._label,
            visible = false
        });
    end;

    function BaseESPParallel:BaseUpdate()
        local instancePosition = self._instancePosition or self._instance.Position;
        if (not instancePosition) then return self:Unload() end;

        local distance = (rootPartPosition - instancePosition).Magnitude;
        local maxDist = flags[self._maxDistanceFlag] or 10000;
        if(distance >= maxDist and maxDist ~= 10000) then return self:Unload(); end;

        local visibleState = flags[self._showFlag];
        if(visibleState == nil) then
            visibleState = true;
        elseif (not visibleState) then
            return self:Unload();
        end;

        local position, visible = worldToViewportPoint(camera, instancePosition);
        if(not visible) then return self:Unload(); end;

        local newPos = vector2New(position.X, position.Y);
        local labelText = '[' .. self._text .. ']';

        if (flags[self._showDistanceFlag]) then
            labelText = labelText .. ' [' .. mFloor(distance) .. ']';
        end;

        local newColor = flags[self._colorFlag] or DEFAULT_ESP_COLOR;

        table.insert(updateDrawingQueue, {
            position = newPos,
            color = newColor,
            text = labelText,
            label = self._label,
            visible = true
        });
    end;

    function BaseESPParallel:UpdateContainer()
        local showFlag = self._showFlag;
        if (flags[showFlag] == false) then
            local exists = table.find(activeContainer, self);
            if (exists) then table.remove(activeContainer, exists); end;
            self:Unload();
        elseif (not table.find(activeContainer, self)) then
            table.insert(activeContainer, self);
        end;
    end;

    local updateTypes = {};

    function updateTypes.new(data)
        BaseESPParallel.new(data.data, data.showFlag);
    end;

    function updateTypes.destroy(data)
        for _, v in next, container do
            if (v._id == data.id) then
                v:Destroy();
            end;
        end;
    end;

    function updateTypes.giveEvent(data)
        local event = data.event;
        event.Event:Connect(function(data)
            if (data.type == 'color') then
                flags[data.flag] = data.color;
            elseif (data.type == 'slider') then
                flags[data.flag] = data.value;
            elseif (data.type == 'toggle') then
                flags[data.flag] = data.state;
            end;
        end);
    end;

    commEvent:Connect(function(data)
        local f = updateTypes[data.updateType];
        if (f) then f(data); end;
    end);

    commEvent:Fire({updateType = 'ready'});

    RunService.Heartbeat:Connect(function()
        task.desynchronize();

        camera = workspace.CurrentCamera;
        rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
        rootPartPosition = rootPart and rootPart.Position;

        if(not camera or not rootPart) then return; end;

        for i = 1, #activeContainer do
            activeContainer[i]:BaseUpdate();
        end;

        if (#updateDrawingQueue ~= 0 or #destroyDrawingQueue ~= 0) then 
            task.synchronize(); 
        end;

        for i = 1, #updateDrawingQueue do
            local v = updateDrawingQueue[i];
            v.label.Position = v.position;
            v.label.Visible = v.visible;
            v.label.Color = v.color;
            v.label.Text = v.text;
        end;

        for i = 1, #destroyDrawingQueue do
            destroyDrawingQueue[i]:Remove();
        end;

        updateDrawingQueue = {};
        destroyDrawingQueue = {};
    end);
]]

-- Main ESP System
local NUM_ACTORS = 8
local actors = {}
local readyCount = 0
local broadcastEvent = Instance.new('BindableEvent')

-- Create Base ESP constructor
local function createBaseEsp(flag, container)
    container = container or {}
    local BaseEsp = {}
    
    BaseEsp.ClassName = 'BaseEsp'
    BaseEsp.Flag = flag
    BaseEsp.Container = container
    BaseEsp.__index = BaseEsp
    
    local whiteColor = Color3.new(1, 1, 1)
    local count = 1
    
    local maxDistanceFlag = BaseEsp.Flag .. 'MaxDistance'
    local showHealthFlag = BaseEsp.Flag .. 'ShowHealth'
    local showESPFlag = BaseEsp.Flag
    
    function BaseEsp.new(instance, tag, color, isLazy)
        assert(instance, '#1 instance expected')
        assert(tag, '#2 tag expected')
        
        color = color or whiteColor
        
        local self = setmetatable({}, BaseEsp)
        self._tag = tag
        
        local displayName = tag
        if typeof(tag) == 'table' then
            displayName = tag.displayName
            self._tag = tag.tag
        end
        
        self._instance = instance
        self._text = displayName
        self._color = color
        self._showFlag = toCamelCase('Show ' .. self._tag)
        self._colorFlag = toCamelCase(self._tag .. ' Color')
        self._colorFlag2 = BaseEsp.Flag .. 'Color'
        self._showDistanceFlag = BaseEsp.Flag .. 'ShowDistance'
        self._isLazy = isLazy
        self._id = count
        self._maid = Maid.new()
        
        count = count + 1
        
        if isLazy and typeof(instance) == "Instance" then
            self._instancePosition = instance.Position
        end
        
        self._maxDistanceFlag = maxDistanceFlag
        self._showHealthFlag = showHealthFlag
        
        -- If actors are available, use parallel processing
        if #actors > 0 then
            self._actor = actors[(count % readyCount) + 1]
            
            local smallData = {}
            for k, v in pairs(self) do
                if k ~= "_actor" and k ~= "_maid" then
                    smallData[k] = v
                end
            end
            
            self._actor.commEvent:Fire({
                updateType = 'new',
                data = smallData,
                showFlag = showESPFlag
            })
        else
            -- Fallback to simple drawing
            self:CreateSimpleESP()
        end
        
        return self
    end
    
    function BaseEsp:CreateSimpleESP()
        -- Create simple ESP without parallel processing
        if Drawing then
            local text = Drawing.new("Text")
            text.Transparency = 1
            text.Color = self._color
            text.Text = "[" .. self._text .. "]"
            text.Center = true
            text.Outline = true
            text.Size = 13
            
            self._drawing = text
            
            self._maid:GiveTask(function()
                text:Remove()
            end)
        end
    end
    
    function BaseEsp:Update()
        if not self._drawing then return end
        
        local camera = workspace.CurrentCamera
        if not camera then return end
        
        if typeof(self._instance) == "Instance" and self._instance:IsA("BasePart") then
            local position, visible = camera:WorldToViewportPoint(self._instance.Position)
            
            if visible and ESPConfig.enabled then
                self._drawing.Visible = true
                self._drawing.Position = Vector2.new(position.X, position.Y)
                
                local distance = (camera.CFrame.Position - self._instance.Position).Magnitude
                
                if ESPConfig.showDistance then
                    self._drawing.Text = string.format("[%s]\n[%d]", self._text, math.floor(distance))
                else
                    self._drawing.Text = "[" .. self._text .. "]"
                end
            else
                self._drawing.Visible = false
            end
        end
    end
    
    function BaseEsp:Destroy()
        self._maid:Destroy()
        
        if self._actor then
            self._actor.commEvent:Fire({
                updateType = 'destroy',
                id = self._id
            })
        end
    end
    
    function BaseEsp:UpdateAll()
        for _, esp in pairs(container) do
            if esp.Update then
                esp:Update()
            end
        end
    end
    
    function BaseEsp:UnloadAll()
        for _, esp in pairs(container) do
            if esp.Destroy then
                esp:Destroy()
            end
        end
    end
    
    return BaseEsp
end

-- Initialize parallel actors if supported
local function initializeActors()
    if not hasActorSupport then
        print("[ESP] Running in single-threaded mode")
        return
    end
    
    local playerScripts = LocalPlayer:WaitForChild('PlayerScripts')
    local playerScriptsLoader = playerScripts:FindFirstChild('PlayerScriptsLoader')
    
    if not playerScriptsLoader then
        print("[ESP] No PlayerScriptsLoader found, using single-threaded mode")
        return
    end
    
    for i = 1, NUM_ACTORS do
        local commId, commEvent
        
        if isSynapseV3 then
            commEvent = {
                _event = Instance.new('BindableEvent'),
                Connect = function(self, f)
                    return self._event.Event:Connect(f)
                end,
                Fire = function(self, ...)
                    self._event:Fire(...)
                end
            }
        else
            commId, commEvent = syn.create_comm_channel()
        end
        
        local clone = playerScriptsLoader:Clone()
        local actor = Instance.new('Actor')
        clone.Parent = actor
        
        actor.Parent = LocalPlayer.PlayerScripts
        
        local connection
        connection = commEvent:Connect(function(data)
            if data.updateType == 'ready' then
                commEvent:Fire({
                    updateType = 'giveEvent', 
                    event = broadcastEvent
                })
                
                readyCount = readyCount + 1
                connection:Disconnect()
            end
        end)
        
        -- Run parallel code on actor
        if loadstring and run_on_actor then
            run_on_actor(actor, parallelESPCode, commId or commEvent)
        end
        
        table.insert(actors, {
            actor = actor,
            commEvent = commEvent
        })
    end
    
    -- Wait for actors to be ready
    repeat task.wait() until readyCount >= NUM_ACTORS
    print("[ESP] All actors loaded successfully")
end

-- ESP Factory
local function makeEsp(options)
    options = options or {}
    
    local tag = toCamelCase(options.sectionName or "Default")
    
    assert(options.callback, "options.callback is required")
    assert(options.args, "options.args is required")
    assert(options.type, "options.type is required")
    
    local espConstructor = createBaseEsp(tag)
    
    options.args = typeof(options.args) == "table" and options.args or {options.args}
    
    local watcherFunc
    
    if options.type == "childAdded" or options.type == "descendantAdded" then
        watcherFunc = Utility[options.type == "childAdded" and "listenToChildAdded" or "listenToDescendantAdded"]
    elseif options.type == "tagAdded" then
        watcherFunc = Utility.listenToTagAdded
    end
    
    if not watcherFunc then
        return error(tag .. " is not being watched!")
    end
    
    local connections = {}
    
    for _, parent in pairs(options.args) do
        local connection = watcherFunc(parent, function(obj)
            options.callback(obj, espConstructor)
        end)
        table.insert(connections, connection)
    end
    
    -- Update loop for non-parallel ESPs
    if #actors == 0 then
        local updateConnection = RunService.RenderStepped:Connect(function()
            espConstructor:UpdateAll()
        end)
        table.insert(connections, updateConnection)
    end
    
    return {
        espConstructor = espConstructor,
        connections = connections,
        destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            espConstructor:UnloadAll()
        end
    }
end

-- Player tracking
local function onCharacterAdded(player)
    local playerData = playersData[player]
    if not playerData then return end
    
    local character = player.Character
    if not character then return end
    
    playerData.character = character
    playerData.humanoid = character:WaitForChild("Humanoid", 10)
    playerData.rootPart = character:WaitForChild("HumanoidRootPart", 10)
    playerData.head = character:WaitForChild("Head", 10)
    
    if playerData.humanoid then
        playerData.alive = true
        playerData.health = playerData.humanoid.Health
        playerData.maxHealth = playerData.humanoid.MaxHealth
        
        playerData.humanoid.Died:Connect(function()
            playerData.alive = false
        end)
        
        playerData.humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            playerData.health = playerData.humanoid.Health
        end)
    end
    
    Utility.onCharacterAdded:Fire(playerData)
    
    if player == LocalPlayer then
        Utility.onLocalCharacterAdded:Fire(playerData)
    end
end

local function onPlayerAdded(player)
    local playerData = {
        player = player,
        team = player.Team,
        parts = {}
    }
    
    playersData[player] = playerData
    
    task.spawn(onCharacterAdded, player)
    
    player.CharacterAdded:Connect(function()
        onCharacterAdded(player)
    end)
    
    player:GetPropertyChangedSignal("Team"):Connect(function()
        playerData.team = player.Team
    end)
    
    Utility.onPlayerAdded:Fire(player)
end

-- Initialize system
task.spawn(initializeActors)

for _, player in pairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
    playersData[player] = nil
end)

-- Broadcast flag changes
broadcastEvent.Event:Connect(function(data)
    for _, actor in ipairs(actors) do
        actor.commEvent:Fire(data)
    end
end)

-- Export module
return {
    Utility = Utility,
    createBaseEsp = createBaseEsp,
    makeEsp = makeEsp,
    ESPConfig = ESPConfig,
    broadcastEvent = broadcastEvent,
    flags = flags,
    Maid = Maid,
    Signal = Signal,
    Services = Services,
    
    -- Configuration functions
    setConfig = function(key, value)
        ESPConfig[key] = value
        broadcastEvent:Fire({
            type = typeof(value) == "boolean" and "toggle" or "value",
            flag = key,
            state = value,
            value = value
        })
    end,
    
    setColor = function(colorType, color)
        ESPConfig.colors[colorType] = color
        broadcastEvent:Fire({
            type = "color",
            flag = colorType .. "Color",
            color = color
        })
    end
}

-- Example usage:
--[[
local ESP = loadstring(game:HttpGet('your_script_url'))()

-- Configure ESP
ESP.setConfig("enabled", true)
ESP.setConfig("showDistance", true)
ESP.setConfig("maxDistance", 5000)
ESP.setColor("enemy", Color3.new(1, 0, 0))

-- Create player ESP
local playerEsp = ESP.makeEsp({
    sectionName = "Players",
    type = "childAdded",
    args = {workspace},
    callback = function(obj, espConstructor)
        if obj:FindFirstChild("Humanoid") then
            local rootPart = obj:FindFirstChild("HumanoidRootPart")
            if rootPart then
                espConstructor.new(rootPart, obj.Name, Color3.new(1, 0, 0), true)
            end
        end
    end
})

-- Create item ESP
local itemEsp = ESP.makeEsp({
    sectionName = "Items",
    type = "descendantAdded",
    args = {workspace.Items},
    callback = function(obj, espConstructor)
        if obj:IsA("BasePart") then
            espConstructor.new(obj, obj.Name, Color3.new(0, 1, 0), true)
        end
    end
})
]]
