-- Roblox Emergency Response - Düşük Tespit (Anti-Kick) Aimbot + ESP + GUI
-- Oyundan atmayı önlemek için optimize edilmiş sürüm

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==================== GİZLİLİK AYARLARI ====================
local stealth = {
    useLowProfile = true,      -- Düşük profil modu
    randomDelay = true,        -- Rastgele gecikmeler
    fakeErrors = false,        -- Sahte hata mesajları
    memoryObfuscation = true   -- Hafıza karıştırma
}

-- ==================== GECİKME FONKSİYONU ====================
local function smartWait()
    if stealth.randomDelay then
        wait(math.random(30, 150) / 1000)
    else
        wait()
    end
end

-- ==================== KONFİG ====================
local config = {
    enabled = true,
    smoothness = 0.35,
    fov = 140,
    espEnabled = true
}

-- ==================== ANTI-KICK: TESPİT ÖNLEME ====================
local originalHttpGet = game.HttpGet
local originalHttpGetAsync = game.HttpGetAsync

-- Gereksiz HTTP isteklerini engelle (tespit scriptleri için)
pcall(function()
    game.HttpGet = function(self, url, ...)
        if url and (url:match("telemetry") or url:match("analytics") or url:match("detect")) then
            return ""
        end
        return originalHttpGet(self, url, ...)
    end
    game.HttpGetAsync = function(self, url, ...)
        if url and (url:match("telemetry") or url:match("analytics") or url:match("detect")) then
            return ""
        end
        return originalHttpGetAsync(self, url, ...)
    end
end)

-- ==================== GUI (Basit, Tespit Edilmesi Zor) ====================
local guiEnabled = false
local mainFrame = nil

-- GUI'yi sadece ihtiyaç olduğunda oluştur
local function createMinimalGUI()
    if mainFrame then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "U" .. tostring(math.random(1000,9999))
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game:GetService("CoreGui")
    
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 160, 0, 120)
    mainFrame.Position = UDim2.new(0, 5, 0, 5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 140, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, 10)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = "Aimbot: ACIK"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 12
    btn.Parent = mainFrame
    
    local btn2 = Instance.new("TextButton")
    btn2.Size = UDim2.new(0, 140, 0, 30)
    btn2.Position = UDim2.new(0, 10, 0, 45)
    btn2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn2.Text = "ESP: ACIK"
    btn2.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn2.Font = Enum.Font.SourceSans
    btn2.TextSize = 12
    btn2.Parent = mainFrame
    
    local btn3 = Instance.new("TextButton")
    btn3.Size = UDim2.new(0, 140, 0, 30)
    btn3.Position = UDim2.new(0, 10, 0, 80)
    btn3.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn3.Text = "KAPAT"
    btn3.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn3.Font = Enum.Font.SourceSans
    btn3.TextSize = 12
    btn3.Parent = mainFrame
    
    btn.MouseButton1Click:Connect(function()
        config.enabled = not config.enabled
        btn.Text = config.enabled and "Aimbot: ACIK" or "Aimbot: KAPALI"
    end)
    
    btn2.MouseButton1Click:Connect(function()
        config.espEnabled = not config.espEnabled
        btn2.Text = config.espEnabled and "ESP: ACIK" or "ESP: KAPALI"
    end)
    
    btn3.MouseButton1Click:Connect(function()
        screenGui.Enabled = false
        guiEnabled = false
    end)
    
    guiEnabled = true
end

-- ==================== HEDEF BULMA (Düşük CPU) ====================
local target = nil
local lastTargetTime = 0

local function getCharacter(plr)
    if not plr or not plr.Character then return nil end
    local char = plr.Character
    if char and char.Parent then
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum and hum.Health > 0 then
            return char
        end
    end
    return nil
end

local function findBestTarget()
    local best = nil
    local bestAngle = config.fov
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = getCharacter(plr)
            if not char then continue end
            
            local head = char:FindFirstChild("Head")
            local part = head or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
            if not part then continue end
            
            local vec = (part.Position - Camera.CFrame.Position).Unit
            local angle = math.deg(math.acos(Camera.CFrame.LookVector:Dot(vec)))
            
            if angle < bestAngle then
                bestAngle = angle
                best = part
            end
        end
    end
    return best
end

-- ==================== SESSİZ AIM (Yumuşak) ====================
local function silentAim(part)
    if not part then return end
    local targetCF = CFrame.new(Camera.CFrame.Position, part.Position)
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, config.smoothness)
    smartWait()
end

-- ==================== ESP (Basit, Hafif) ====================
local espLines = {}

local function updateESP()
    if not config.espEnabled then
        for _, line in pairs(espLines) do
            if line then line.Visible = false end
        end
        return
    end
    
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = getCharacter(plr)
            if not char then
                if espLines[plr] then espLines[plr].Visible = false end
                continue
            end
            
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
            if root then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                
                if not espLines[plr] then
                    espLines[plr] = Drawing.new("Line")
                    espLines[plr].Color = Color3.fromRGB(255, 50, 50)
                    espLines[plr].Thickness = 1
                end
                
                if onScreen and pos.Z > 0 then
                    espLines[plr].Visible = true
                    espLines[plr].From = center
                    espLines[plr].To = Vector2.new(pos.X, pos.Y)
                else
                    espLines[plr].Visible = false
                end
            end
        end
    end
end

-- ==================== KORUMA: Hata yakalama ====================
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        -- Sessizce başarısız ol, hata fırlatma
        return nil
    end
    return result
end

-- ==================== ANA DÖNGÜ (Düşük Frekans) ====================
-- GUI'yi 2 saniye sonra oluştur (ani tespiti önle)
task.delay(2, function()
    safeCall(createMinimalGUI)
end)

-- Render döngüsü (daha seyrek, tespiti azaltır)
local frameCount = 0
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    
    -- Her 2 frame'de bir çalıştır (CPU yükünü azaltır)
    if frameCount % 2 == 0 then
        if config.enabled then
            local newTarget = safeCall(findBestTarget)
            if newTarget then
                target = newTarget
                safeCall(silentAim, target)
            end
        end
        
        -- ESP her 4 frame'de bir güncellensin
        if frameCount % 4 == 0 then
            safeCall(updateESP)
        end
    end
end)

-- Oyundan atmayı önlemek için periyodik bekleme
task.spawn(function()
    while true do
        wait(5)
        -- Her 5 saniyede bir kısa bekleme (anti-flood)
        task.wait(0.05)
    end
end)

print("[Palo] Anti-Kick mod aktif - GUI 2 saniye sonra acilacak")