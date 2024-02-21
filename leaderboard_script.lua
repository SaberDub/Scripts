local Run

if not game.Players.LocalPlayer.PlayerGui:FindFirstChild("LeaderboardGui") then
    local NewLB = game.StarterGui:FindFirstChild("LeaderboardGui"):Clone()
    NewLB.Parent = game.Players.LocalPlayer.PlayerGui
    NewLB.ResetOnSpawn = true
    local Connection
    Connection = game.Players.LocalPlayer.CharacterAdded:Connect(function()
        NewLB:Destroy()
        Connection:Disconnect()
        Run()
    end)
end
if game.Players.LocalPlayer.PlayerGui:FindFirstChild("StartMenu") then
    game.Players.LocalPlayer.PlayerGui:FindFirstChild("StartMenu").CopyrightBar:Destroy()
end
--CopyrightBar
workspace.CurrentCamera.CameraType = Enum.CameraType.Custom


Run = function()
    pcall(function()
        shared.SPRLS = script
        shared.SPROC = {}
    
        local Players = game:GetService "Players"
        local UIS = game:GetService "UserInputService"
        local RS = game:GetService "RunService"
        local LocalPlayer = Players.LocalPlayer
        local AdminMode = false
        local Spectating
        local PlayerData = {}
    
        LocalPlayer.PlayerGui:WaitForChild("LeaderboardGui"):WaitForChild("LeaderboardClient")
        wait()
    
        function Find(Upvalues, Function)
            local Constants = {}
            if typeof(Upvalues) == "function" then
                Constants = debug.getconstants(Upvalues)
                Upvalues = debug.getupvalues(Upvalues)
            end
    
            for i, v in pairs(Upvalues) do
                local Env = getfenv(Function)
                Env.Constants = Constants
                setfenv(Function, Env)
                local S, E = pcall(Function, v)
    
                if S and E then
                    local Env = getfenv(2)
                    Env.Value = v
                    Env.Index = i
                    setfenv(2, Env)
                    return v
                end
            end
    
            return false
        end
    
        function InTable(Table, Value)
            for i, v in pairs(Table) do
                if v == Value then
                    return true
                end
            end
    
            return false
        end
    
        UIS.InputEnded:Connect(function(Input, Processed)
                if Input.UserInputType.Name == "Keyboard" and Input.KeyCode.Name == "Tab" and not Processed and UIS:IsKeyDown "LeftControl" and not UIS:IsKeyDown "LeftAlt" then AdminMode = not AdminMode end
        end)
    
        local Runes = {}
    
        function OnCharacter(Character)
            if not Character then
                return false
            end
    
            local Humanoid = Character:WaitForChild("Humanoid")
            local LastHP = Humanoid.Health
    
            Humanoid.HealthChanged:Connect(function(NewHealth)
                if Spectating and NewHealth < LastHP and LocalPlayer.Character == Character then
                    Spectating = nil
                    workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                end
    
                LastHP = NewHealth
            end)
        end
    
        function NameRightClick(Player, Label)
            if script ~= shared.SPRLS then
                return false
            end
    
            local Button = Label:FindFirstChild "SPB" or Instance.new("TextButton", Label)
            Button.Name = "SPB"
            Button.Transparency = 1
            Button.Text = ""
            Button.Size = UDim2.new(1, 0, 1, 0)
            Button.Position = UDim2.new(0, 0, 0, 0)
    
            local SpeedLabel = Label:FindFirstChild "SPA" or Instance.new("TextLabel", Label)
            SpeedLabel.Visible = false
            SpeedLabel.Name = "SPA"
            SpeedLabel.BackgroundTransparency = 1
            SpeedLabel.Text = "0s"
            SpeedLabel.TextXAlignment = "Right"
            SpeedLabel.Size = UDim2.new(1, 0, 1, 0)
            SpeedLabel.Position = UDim2.new(0, -10, 0, 0)
            SpeedLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
            SpeedLabel.TextStrokeColor3 = Color3.fromRGB(35, 35, 35)
            SpeedLabel.TextStrokeTransparency = 0.75
            SpeedLabel.Font = Label.Font
            SpeedLabel.TextSize = Label.TextSize
    
            Button.MouseButton1Click:Connect(function()
                if script ~= shared.SPRLS then
                    return false
                end
    
                if (Spectating == Player or Player == LocalPlayer) and LocalPlayer.Character then
                    Spectating = nil
                    workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                else
                    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
                        Spectating = Player
                        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    
                        local T = Spectating.Character:GetDescendants()
                        
                        if LocalPlayer.Character then
                            for i, v in pairs(LocalPlayer.Character:GetDescendants()) do
                                table.insert(T, v)
                            end
                        end
    
                        for i, v in pairs(T) do
                            if v:IsA("Decal") and v.Parent.Name:match("Slot%d+") and not Runes[v] and v.Transparency == 1 then
                                Runes[v] = v.Transparency
    
                                v:GetPropertyChangedSignal "Transparency":Connect(function()
                                    v.Transparency = 1
                                end)
                            end
                        end
    
                        workspace.CurrentCamera.CameraSubject = Player.Character:FindFirstChildOfClass "Humanoid"
                    end
                end
            end)
    
            local Stats = Player:WaitForChild("leaderstats", .05)
            local Hidden = (Stats and Stats:WaitForChild("Hidden", .05) and Stats.Hidden.Value) or false
    
            PlayerData[Player] = {
                LastUpdate = 0,
                LastPosition = (Player.Character and Player.Character:FindFirstChild "HumanoidRootPart" and Player.Character.HumanoidRootPart.Position) or Vector3.new(0, 0, 0),
                Suspicious = 0,
                TPSafe = false,
                Hidden = Hidden,
                Label = Label,
                Button = Button,
                SpeedLabel = SpeedLabel
            }
            PlayerData[Player].LastPosition = Vector2.new(PlayerData[Player].LastPosition.X, PlayerData[Player].LastPosition.Z)
    
            Player.CharacterAdded:Connect(function(Character)
                PlayerData[Player].LastPosition = Character:WaitForChild "HumanoidRootPart".Position
                PlayerData[Player].LastPosition = Vector2.new(PlayerData[Player].LastPosition.X, PlayerData[Player].LastPosition.Z)
                PlayerData[Player].Suspicious = 0
            end)
    
            return Label
        end
    
        OnCharacter(LocalPlayer.Character)
        LocalPlayer.CharacterAdded:Connect(OnCharacter)
    
        for i, v in pairs(getreg()) do
            if typeof(v) == "function" and islclosure(v) and not is_synapse_function(v) then
                local ups = debug.getupvalues(v)
                local scr = getfenv(v).script
    
                if
                    Find(
                        ups,
                        function(x)
                            return scr.Name == "LeaderboardClient" and typeof(x) == "function" and
                                InTable(debug.getconstants(x), "HouseRank")
                        end
                    )
                then
                    local Labels = {}
    
                    if
                        Find(
                            Value,
                            function(x)
                                return typeof(x) == "table" and x[LocalPlayer]
                            end
                        )
                    then
                        Labels = Value
                        for i, v in pairs(Value) do
                            NameRightClick(i, v)
                        end
                    end
    
                    local Index = shared.SPROC[v] and shared.SPROC[v].Index or Index
                    local Original = shared.SPROC[v] and shared.SPROC[v].Function or debug.getupvalues(v)[Index]
                    shared.SPROC[v] = {Index = Index, Function = Original}
    
                    debug.setupvalue(
                        v,
                        Index,
                        function(Player, ...)
                            local Label = Original(Player, ...)
                            local DummyConstant = "HouseRank"
                            local DummyTable = Labels
    
                            NameRightClick(Player, Label)
    
                            return Label
                        end
                    )
                end
            end
        end
    
        local Last = 0
    
        RS:UnbindFromRenderStep("LSBI")
    
        RS:BindToRenderStep("LSBI",500,function()
            if tick() - Last > 1 / 2 then
                Last = tick()
    
                for Player, Data in pairs(PlayerData) do
                    local LastUpdate = Data.LastUpdate
                    local Suspicious = Data.Suspicious
                    local SpeedLabel = Data.SpeedLabel
                    local LastPosition = Data.LastPosition
    
                    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                        if tick() - LastUpdate > 0.1 then
                            LastUpdate = tick()
    
                            local NewPosition = Player.Character.HumanoidRootPart.Position
                            NewPosition = Vector2.new(NewPosition.X, NewPosition.Z)
                            local Velocity = (LastPosition - NewPosition).Magnitude
    
                            SpeedLabel.Text = math.floor(Velocity) .. "s"
    
                            if Velocity > 50 then
                                Suspicious = tick()
                            end
    
                            LastPosition = Player.Character.HumanoidRootPart.Position
                            LastPosition = Vector2.new(LastPosition.X, LastPosition.Z)
                        end
                    end
    
                    SpeedLabel.Visible = AdminMode
                    --SpeedLabel.TextColor3 = tick() - Suspicious < 5 and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(240, 240, 240)
    
                    local Color = Color3.fromRGB(240, 240, 240)
                    if tick() - Suspicious < 5 then
                        if Player.Character:FindFirstChild("TPSafe") then
                            Color = Color3.fromRGB(50, 255, 50)
                        elseif Player.Character:FindFirstChild("FlightOk") then
                            Color = Color3.fromRGB(255, 255, 50)
                        else
                            Color = Color3.fromRGB(255, 50, 50)
                        end
                    end
                    SpeedLabel.TextColor3 = Color 
    
                    if Player:FindFirstChild("leaderstats") and Player.leaderstats:FindFirstChild("Hidden") then
                        if AdminMode then
                            Player.leaderstats.Hidden.Value = false
                        else
                            Player.leaderstats.Hidden.Value = Data.Hidden
                        end
                    end
    
                    Data.Suspicious = Suspicious
                    Data.LastUpdate = LastUpdate
                    Data.LastPosition = LastPosition
    
                    PlayerData[Player] = Data
                end
            end
        end)
    end)    
end

Run()
