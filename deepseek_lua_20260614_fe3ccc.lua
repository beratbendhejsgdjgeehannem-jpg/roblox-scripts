-- Roblox Emergency Response - Kullanma Panelli (GUI) Aimbot + Anti-Ban + ESP + Loadsteering
-- loadstring ile çağırmak için raw URL'ye kaydedin.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==================== KONFİGÜRASYON ====================
local config = {
    aimbotEnabled = true,
    silentAim = true,
    fov = 120,
    smoothness = 0.25,
    antiBan = true,
    espEnabled = true,
    espBox = true,
    espLine = true,
    espHealth = true,
    loadSteeringEnabled = true,
    steeringSpeed = 0.3,
    teamCheck = true,
    visibleCheck = false
}

-- ==================== GUI (Kullanma Paneli) ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PaloGUI"
screenGui.Parent = game:GetService("CoreGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
title.Text = "Palo VWR Panel"
title.TextColor3 = Color3.fromRGB(255, 0, 0)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
end)

local function createToggle(text, yPos, configKey, defaultValue)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 280, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Text = text .. ": " .. tostring(defaultValue)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.Parent = mainFrame
    btn.MouseButton1Click:Connect(function()
        config[configKey] = not config[configKey]
        btn.Text = text .. ": " .. tostring(config[configKey])
    end)
    return btn
end

local function createSlider(text, yPos, configKey, minVal, maxVal, defaultVal)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(0, 280, 0, 50)
    sliderFrame.Position = UDim2.new(0, 10, 0, yPos)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = mainFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = text .. ": " .. tostring(defaultVal)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSans
    label.TextSize = 12
    label.Parent = sliderFrame
    
    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(1, 0, 0, 20)
    slider.Position = UDim2.new(0, 0, 0, 25)
    slider.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    slider.Text = "[" .. defaultVal .. "]"
    slider.TextColor3 = Color3.fromRGB(255, 255, 255)
    slider.Font = Enum.Font.SourceSans
    slider.TextSize = 11
    slider.Parent = sliderFrame
    
    local dragging = false
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
        local val = minVal + (maxVal - minVal) * pos
        val = math.floor(val * 100) / 100
        config[configKey] = val
        label.Text = text .. ": " .. tostring(val)
        slider.Text = "[" .. string.format("%.2f", val) .. "]"
    end
    
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(input)
        end
    end)
    
    slider.InputEnded:Connect(function()
        dragging = false
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
end

-- Toggle butonları
createToggle("Aimbot", 40, "aimbotEnabled", config.aimbotEnabled)
createToggle("Silent Aim", 80, "silentAim", config.silentAim)
createToggle("Anti-Ban", 120, "antiBan", config.antiBan)
createToggle("ESP", 160, "espEnabled", config.espEnabled)
createToggle("ESP Box", 200, "espBox", config.espBox)
createToggle("ESP Line", 240, "espLine", config.espLine)
createToggle("ESP Health", 280, "espHealth", config.espHealth)
createToggle("Loadsteering", 320, "loadSteeringEnabled", config.loadSteeringEnabled)
createToggle("Team Check", 360, "teamCheck", config.teamCheck)

-- Sliderlar (kaydırma çubuğu)
createSlider("FOV", 400, "fov", 30, 180, config.fov)
createSlider("Smoothness", 455, "smoothness", 0.05, 1, config.smoothness)
createSlider("Steering Speed", 510, "steeringSpeed", 0.1, 1, config.steeringSpeed)

-- Frame boyutunu sliderlara göre ayarla
mainFrame.Size = UDim2.new(0, 300, 0, 580)

-- ==================== HEDEF BULMA ====================
local target = nil

local function getCharacter(plr)
    if not plr or not plr.Character then return nil end
    local char = plr.Character
    if char and char.Parent and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
        return char
    end
    return nil
end

local function getTargetPart(char)
    local priority = {"Head", "UpperTorso", "HumanoidRootPart"}
    for _, p in ipairs(priority) do
        local part = char:FindFirstChild(p)
        if part and part:IsA("BasePart") then return part end
    end
    return char:FindFirstChildWhichIsA("BasePart")
end

local function getAngle(targetPos)
    local vec = (targetPos - Camera.CFrame.Position).Unit
    local angle = math.acos(Camera.CFrame.LookVector:Dot(vec))
    return math.deg(angle)
end

local function isVisible(part)
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin).Unit
    local ray = Ray.new(origin, dir * 500)
    local hit = workspace:FindPartOnRay(ray, LocalPlayer.Character)
    return hit and hit:IsDescendantOf(part.Parent)
end

local function findBestTarget()
    local best = nil
    local bestAngle = config.fov
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if config.teamCheck and plr.Team == LocalPlayer.Team then continue end
            local char = getCharacter(plr)
            if not char then continue end
            local part = getTargetPart(char)
            if not part then continue end
            if config.visibleCheck and not isVisible(part) then continue end
            local angle = getAngle(part.Position)
            if angle < bestAngle then
                bestAngle = angle
                best = part
            end
        end
    end
    return best
end

-- ==================== SESSİZ AIMBOT ====================
local function silentAim(part)
    if not part then return end
    local newCF = CFrame.new(Camera.CFrame.Position, part.Position)
    Camera.CFrame = Camera.CFrame:Lerp(newCF, config.smoothness)
end

-- ==================== ANTI-BAN ====================
local function antiBanNoise()
    if not config.antiBan then return end
    wait(math.random(10, 40) / 1000)
    if math.random(1, 100) > 85 then
        pcall(function() mousemoverel(math.random(-2,2), math.random(-2,2)) end)
    end
end

-- ==================== ESP ====================
local espObjects = {}
local function createESP(player)
    if espObjects[player] then return end
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.new(1,0,0)
    box.Thickness = 1
    box.Filled = false
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.new(1,0,0)
    line.Thickness = 1
    local text = Drawing.new("Text")
    text.Visible = false
    text.Color = Color3.new(1,1,1)
    text.Size = 14
    text.Center = true
    espObjects[player] = {box = box, line = line, text = text}
end

local function updateESP()
    for plr, objs in pairs(espObjects) do
        local char = getCharacter(plr)
        if not char or not config.espEnabled then
            objs.box.Visible = false
            objs.line.Visible = false
            objs.text.Visible = false
            continue
        end
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
        if root then
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local size = 100 / pos.Z * 2
                objs.box.Visible = config.espEnabled and config.espBox
                objs.box.Size = Vector2.new(size, size)
                objs.box.Position = Vector2.new(pos.X - size/2, pos.Y - size/2)
                objs.line.Visible = config.espEnabled and config.espLine
                objs.line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                objs.line.To = Vector2.new(pos.X, pos.Y)
                objs.text.Visible = config.espEnabled and config.espHealth
                local health = char:FindFirstChildWhichIsA("Humanoid") and char.Humanoid.Health or 0
                objs.text.Text = string.format("%s [%d]", plr.Name, health)
                objs.text.Position = Vector2.new(pos.X, pos.Y - size/2 - 15)
            else
                objs.box.Visible = false
                objs.line.Visible = false
                objs.text.Visible = false
            end
        end
    end
end

-- ==================== LOADSTEERING ====================
local function steeringToTarget()
    if not config.loadSteeringEnabled or not target then return end
    local vehicle = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("VehicleSeat")
    if not vehicle then return end
    local parent = vehicle.Parent
    local root = parent and parent:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local targetPos = target.Position
    local dir = (targetPos - root.Position).Unit
    local forward = root.CFrame.LookVector
    local dot = forward:Dot(dir)
    local steer = math.clamp(dot * config.steeringSpeed, -1, 1)
    if steer > 0.1 then
        LocalPlayer.Character.Humanoid:Move(Enum.KeyCode.D, true)
    elseif steer < -0.1 then
        LocalPlayer.Character.Humanoid:Move(Enum.KeyCode.A, true)
    end
end

-- ==================== ANA DÖNGÜ ====================
RunService.RenderStepped:Connect(function()
    if config.aimbotEnabled then
        target = findBestTarget()
        if target and config.silentAim then
            silentAim(target)
            antiBanNoise()
        end
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then createESP(plr) end
    end
    updateESP()
    steeringToTarget()
end)

print("[Palo] Kullanma panelli VWR Aimbot + ESP + Loadsteering yüklendi. GUI ekranın sol üstünde.")