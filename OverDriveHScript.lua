--// Configuración
local Config = {
    Aimbot = {
        Enabled = true,
        Key = Enum.UserInputType.MouseButton2, -- Click derecho
        Smoothness = 0.15, -- Menor = más rápido (0.01 - 1)
        FOV = 150,
        TeamCheck = true,
        WallCheck = false,
        PredictMovement = true
    },
    AutoFire = {
        Enabled = true,
        Key = Enum.KeyCode.F, -- Tecla para activar/desactivar
        Delay = 0.01
    },
    Hitbox = {
        Enabled = true,
        Size = 10, -- Tamaño aumentado
        Transparency = 0.7,
        Color = Color3.fromRGB(255, 0, 0)
    },
    ESP = {
        Enabled = true,
        ShowName = true,
        ShowHealth = true,
        ShowDistance = true
    }
}

--// Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// Variables
local AimbotTarget = nil
local AutoFireEnabled = false
local Circle = Drawing.new("Circle")
Circle.Visible = false
Circle.Thickness = 1
Circle.Color = Color3.fromRGB(255, 255, 255)
Circle.Transparency = 0.5

--// Función para detectar el juego
local function GetGameType()
    local PlaceId = game.PlaceId
    
    -- Duelos (MM2 style)
    if PlaceId == 14259168140 or PlaceId == 1234567890 then
        return "Duelos"
    -- Murder Mystery 2
    elseif PlaceId == 142823291 or PlaceId == 177200806 then
        return "MM2"
    -- Duelist
    elseif PlaceId == 16556746132 or PlaceId == 17657005177 then
        return "Duelist"
    end
    
    return "Universal"
end

local GameType = GetGameType()

--// Función para obtener personaje del enemigo
local function GetCharacter(player)
    if not player then return nil end
    
    if GameType == "Duelos" or GameType == "Duelist" then
        return player.Character or player:WaitForChild("Character")
    else
        return player.Character
    end
end

--// Función para obtener la herramienta/equipo
local function GetTool()
    local Character = LocalPlayer.Character
    if not Character then return nil end
    
    return Character:FindFirstChildOfClass("Tool")
end

--// Función para obtener el HumanoidRootPart/Head objetivo
local function GetTargetPart(character)
    if not character then return nil end
    
    -- Prioridad: Head > HumanoidRootPart > Torso
    return character:FindFirstChild("Head") 
        or character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("UpperTorso")
end

--// Función para verificar si es enemigo
local function IsEnemy(player)
    if not Config.Aimbot.TeamCheck then return true end
    if player == LocalPlayer then return false end
    
    -- Verificación por equipo
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end
    
    -- Para MM2: verificar si es murderer/sheriff/inocente
    if GameType == "MM2" then
        -- Lógica específica de MM2 si es necesario
        return true
    end
    
    return true
end

--// Función para expandir hitbox
local function ExpandHitbox(player)
    if not Config.Hitbox.Enabled then return end
    
    local Character = GetCharacter(player)
    if not Character then return end
    
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if HumanoidRootPart then
        -- Guardar tamaño original si no existe
        if not HumanoidRootPart:GetAttribute("OriginalSize") then
            HumanoidRootPart:SetAttribute("OriginalSize", HumanoidRootPart.Size)
        end
        
        -- Expandir hitbox
        HumanoidRootPart.Size = Vector3.new(Config.Hitbox.Size, Config.Hitbox.Size, Config.Hitbox.Size)
        HumanoidRootPart.Transparency = Config.Hitbox.Transparency
        HumanoidRootPart.CanCollide = false
        HumanoidRootPart.Color = Config.Hitbox.Color
    end
    
    -- Expandir también la cabeza para mayor facilidad
    local Head = Character:FindFirstChild("Head")
    if Head then
        if not Head:GetAttribute("OriginalSize") then
            Head:SetAttribute("OriginalSize", Head.Size)
        end
        Head.Size = Vector3.new(Config.Hitbox.Size/2, Config.Hitbox.Size/2, Config.Hitbox.Size/2)
    end
end

--// Función para restaurar hitbox
local function RestoreHitbox(player)
    local Character = GetCharacter(player)
    if not Character then return end
    
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if HumanoidRootPart and HumanoidRootPart:GetAttribute("OriginalSize") then
        HumanoidRootPart.Size = HumanoidRootPart:GetAttribute("OriginalSize")
        HumanoidRootPart.Transparency = 1
    end
    
    local Head = Character:FindFirstChild("Head")
    if Head and Head:GetAttribute("OriginalSize") then
        Head.Size = Head:GetAttribute("OriginalSize")
    end
end

--// Función para encontrar objetivo más cercano al mouse
local function GetClosestPlayerToMouse()
    local ClosestPlayer = nil
    local ClosestDistance = Config.Aimbot.FOV
    local MousePos = Vector2.new(Mouse.X, Mouse.Y)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if IsEnemy(player) then
            local Character = GetCharacter(player)
            local TargetPart = GetTargetPart(Character)
            
            if TargetPart then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(TargetPart.Position)
                
                if OnScreen then
                    local Distance = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                    
                    if Distance < ClosestDistance then
                        -- Verificar paredes si está activado
                        if Config.Aimbot.WallCheck then
                            local RaycastParams = RaycastParams.new()
                            RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Character}
                            RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                            
                            local Direction = (TargetPart.Position - Camera.CFrame.Position).Unit
                            local Raycast = Workspace:Raycast(Camera.CFrame.Position, Direction * 1000, RaycastParams)
                            
                            if Raycast and Raycast.Instance then
                                -- Hay algo bloqueando
                                continue
                            end
                        end
                        
                        ClosestDistance = Distance
                        ClosestPlayer = player
                    end
                end
            end
        end
    end
    
    return ClosestPlayer
end

--// Función de Aimbot suavizado
local function AimAt(target)
    if not target then return end
    
    local Character = GetCharacter(target)
    local TargetPart = GetTargetPart(Character)
    
    if TargetPart then
        local TargetPos = TargetPart.Position
        
        -- Predicción de movimiento
        if Config.Aimbot.PredictMovement then
            local Velocity = TargetPart.Velocity
            local Distance = (TargetPos - Camera.CFrame.Position).Magnitude
            local Prediction = Velocity * (Distance / 1000) * 0.1
            TargetPos = TargetPos + Prediction
        end
        
        -- Suavizado
        local TargetCFrame = CFrame.new(Camera.CFrame.Position, TargetPos)
        Camera.CFrame = Camera.CFrame:Lerp(TargetCFrame, Config.Aimbot.Smoothness)
    end
end

--// Función de AutoFire
local function AutoFire()
    if not AutoFireEnabled then return end
    
    local Tool = GetTool()
    if Tool then
        -- Simular click para disparar
        if Tool:FindFirstChild("Fire") then
            Tool.Fire:FireServer(AimbotTarget and GetTargetPart(GetCharacter(AimbotTarget)) or Mouse.Hit.Position)
        elseif Tool:FindFirstChild("Shoot") then
            Tool.Shoot:FireServer()
        elseif Tool:FindFirstChild("Activate") then
            Tool.Activate:FireServer()
        else
            -- Método universal: simular input
            mouse1press()
            task.wait(0.01)
            mouse1release()
        end
    end
end

--// UI Simple
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MultiHack"
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 300)
MainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.Text = "Multi-Game Script | " .. GameType
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Botones de toggle
local function CreateToggle(name, configTable, configKey, position)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0.9, 0, 0, 30)
    Button.Position = UDim2.new(0.05, 0, 0, position)
    Button.BackgroundColor3 = configTable[configKey] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    Button.Text = name .. ": " .. (configTable[configKey] and "ON" or "OFF")
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Parent = MainFrame
    
    Button.MouseButton1Click:Connect(function()
        configTable[configKey] = not configTable[configKey]
        Button.BackgroundColor3 = configTable[configKey] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        Button.Text = name .. ": " .. (configTable[configKey] and "ON" or "OFF")
    end)
end

CreateToggle("Aimbot", Config.Aimbot, "Enabled", 40)
CreateToggle("Auto Fire", Config, "AutoFire", 80)
CreateToggle("Hitbox Expand", Config.Hitbox, "Enabled", 120)
CreateToggle("Wall Check", Config.Aimbot, "WallCheck", 160)
CreateToggle("ESP", Config.ESP, "Enabled", 200)

-- Label de info
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(0.9, 0, 0, 40)
InfoLabel.Position = UDim2.new(0.05, 0, 0, 250)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Aim: RMB | AutoFire: F"
InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
InfoLabel.TextSize = 12
InfoLabel.Parent = MainFrame

--// Input handlers
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Aimbot toggle hold
    if input.UserInputType == Config.Aimbot.Key then
        AimbotTarget = GetClosestPlayerToMouse()
    end
    
    -- AutoFire toggle
    if input.KeyCode == Config.AutoFire.Key then
        AutoFireEnabled = not AutoFireEnabled
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Config.Aimbot.Key then
        AimbotTarget = nil
    end
end)

--// Loop principal
RunService.RenderStepped:Connect(function()
    -- Actualizar círculo FOV
    Circle.Position = Vector2.new(Mouse.X, Mouse.Y)
    Circle.Radius = Config.Aimbot.FOV
    Circle.Visible = Config.Aimbot.Enabled
    
    -- Aimbot activo
    if Config.Aimbot.Enabled and UserInputService:IsMouseButtonPressed(Config.Aimbot.Key) then
        if not AimbotTarget or not GetCharacter(AimbotTarget) then
            AimbotTarget = GetClosestPlayerToMouse()
        end
        
        if AimbotTarget then
            AimAt(AimbotTarget)
        end
    end
    
    -- AutoFire
    if Config.AutoFire.Enabled and AutoFireEnabled and AimbotTarget then
        AutoFire()
    end
    
    -- Expandir hitboxes
    if Config.Hitbox.Enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if IsEnemy(player) then
                ExpandHitbox(player)
            end
        end
    end
end)

--// ESP
if Config.ESP.Enabled then
    local function CreateESP(player)
        local Character = GetCharacter(player)
        if not Character then return end
        
        local Billboard = Instance.new("BillboardGui")
        Billboard.Name = "ESP"
        Billboard.AlwaysOnTop = true
        Billboard.Size = UDim2.new(0, 200, 0, 50)
        Billboard.StudsOffset = Vector3.new(0, 3, 0)
        
        local TextLabel = Instance.new("TextLabel")
        TextLabel.Size = UDim2.new(1, 0, 1, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        TextLabel.TextSize = 14
        TextLabel.TextStrokeTransparency = 0.5
        TextLabel.Parent = Billboard
        
        local function Update()
            if not player or not GetCharacter(player) then
                Billboard:Destroy()
                return
            end
            
            if IsEnemy(player) then
                local Char = GetCharacter(player)
                local Head = Char and Char:FindFirstChild("Head")
                
                if Head then
                    Billboard.Adornee = Head
                    
                    local Text = player.Name
                    if Config.ESP.ShowHealth then
                        local Humanoid = Char:FindFirstChildOfClass("Humanoid")
                        if Humanoid then
                            Text = Text .. " [" .. math.floor(Humanoid.Health) .. "/" .. math.floor(Humanoid.MaxHealth) .. "]"
                        end
                    end
                    if Config.ESP.ShowDistance then
                        local Distance = LocalPlayer:DistanceFromCharacter(Head.Position)
                        Text = Text .. " [" .. math.floor(Distance) .. "m]"
                    end
                    
                    TextLabel.Text = Text
                    Billboard.Parent = game.CoreGui
                end
            else
                Billboard.Enabled = false
            end
        end
        
        game:GetService("RunService").Heartbeat:Connect(Update)
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            CreateESP(player)
        end
    end
    
    Players.PlayerAdded:Connect(CreateESP)
end

--// Notificación de carga
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Multi-Game Script Loaded",
    Text = "Game detected: " .. GameType .. " | Press F for AutoFire",
    Duration = 5
})

print("Script cargado correctamente para: " .. GameType)
