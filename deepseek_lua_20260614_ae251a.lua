-- Roblox Emergency Response - VWR Uyumlu Aimbot + Anti-Ban + Silent ESP + Loadsteering
-- Kullanım: Bu scripti raw GitHub'a yükleyip loadstring ile çağırın.

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
    loadSteeringEnabled = true,  -- Araç otomatik yönlendirme
    steeringSpeed = 0.3,
    teamCheck = true,
    visibleCheck = false
}

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

-- ==================== ANTI-BAN (Rastgele gecikme + fare sapması) ====================
local function antiBanNoise()
    if not config.antiBan then return end
    wait(math.random(10, 40) / 1000)
    if math.random(1, 100) > 85 then
        mousemoverel(math.random(-2,2), math.random(-2,2))
    end
end

-- ==================== ESP (Sessiz) ====================
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
                objs.box.Visible = config.espBox
                objs.box.Size = Vector2.new(size, size)
                objs.box.Position = Vector2.new(pos.X - size/2, pos.Y - size/2)
                objs.line.Visible = config.espLine
                objs.line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                objs.line.To = Vector2.new(pos.X, pos.Y)
                objs.text.Visible = config.espHealth
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

-- ==================== LOADSTEERING (Araç otomatik yönlendirme) ====================
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
    -- Simüle edilen direksiyon girişi (A/D veya mouse)
    if steer > 0.1 then
        -- sağa dön
        LocalPlayer.Character.Humanoid:Move(Enum.KeyCode.D, true)
    elseif steer < -0.1 then
        -- sola dön
        LocalPlayer.Character.Humanoid:Move(Enum.KeyCode.A, true)
    end
end

-- ==================== ANA DÖNGÜ ====================
RunService.RenderStepped:Connect(function()
    -- Aimbot
    if config.aimbotEnabled then
        target = findBestTarget()
        if target and config.silentAim then
            silentAim(target)
            antiBanNoise()
        end
    end
    
    -- ESP güncelleme
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then createESP(plr) end
    end
    updateESP()
    
    -- Steering
    steeringToTarget()
end)

-- ==================== TOGGLE KOMUTLARI (F1-F4) ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F1 then
        config.aimbotEnabled = not config.aimbotEnabled
        warn("[Palo] Aimbot: " .. tostring(config.aimbotEnabled))
    elseif input.KeyCode == Enum.KeyCode.F2 then
        config.espEnabled = not config.espEnabled
        warn("[Palo] ESP: " .. tostring(config.espEnabled))
    elseif input.KeyCode == Enum.KeyCode.F3 then
        config.loadSteeringEnabled = not config.loadSteeringEnabled
        warn("[Palo] Loadsteering: " .. tostring(config.loadSteeringEnabled))
    elseif input.KeyCode == Enum.KeyCode.F4 then
        config.antiBan = not config.antiBan
        warn("[Palo] Anti-Ban: " .. tostring(config.antiBan))
    end
end)

print("[Palo] VWR Aimbot + Anti-Ban + Silent ESP + Loadsteering yüklendi. F1-F4 ile aç/kapa.")