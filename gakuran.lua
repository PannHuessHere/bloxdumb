local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- [FEATURE #4] Track all connections for cleanup
local connections = {}

-- [FEATURE #7] Logging System
local function log(message, level)
    level = level or "INFO"
    local timestamp = os.date("%H:%M:%S")
    local logMessage = "[XENO " .. timestamp .. "] [" .. level .. "] " .. message
    print(logMessage)
    return logMessage
end

-- [FEATURE #1] Safe Pcall wrapper
local function safePcall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[XENO] Error: " .. tostring(result))
        log("Error: " .. tostring(result), "ERROR")
    end
    return success, result
end

-- [FEATURE #2] Nil Check pada LocalPlayer
if not LocalPlayer or not LocalPlayer.Character then
    warn("XenoPremiumV7: LocalPlayer tidak ditemukan atau belum spawn")
    return
end

if CoreGui:FindFirstChild("XenoPremiumV7") then 
    CoreGui.XenoPremiumV7:Destroy() 
end

_G.XBActive = true
Settings = {ESP = false, Respawn = false, Hitbox = false, InfiniteStamina = false, StaminaRegen = false}
targetPlayerName = ""

-- [STAMINA SYSTEM] Infinite Stamina & Regen Manager
local StaminaManager = {
    Enabled = false,
    InfiniteMode = false,  -- true = Infinite, false = Regen
    MaxStamina = 100,
    RegenRate = 50,  -- % per second (Regen mode)
    
    -- Set stamina ke nilai tertentu
    setStamina = function(self, character, value)
        if not character then return false end
        
        -- Cari sebagai Value (NumberValue/IntValue)
        local stamina = character:FindFirstChild("Posture") 
                     or character:FindFirstChild("Stamina") 
                     or character:FindFirstChild("PostureValue")
        
        if stamina and (stamina:IsA("NumberValue") or stamina:IsA("IntValue")) then
            stamina.Value = math.clamp(value, 0, self.MaxStamina)
            return true
        end
        
        -- Cari sebagai Attribute
        local postureAttr = character:GetAttribute("Posture")
        local staminaAttr = character:GetAttribute("Stamina")
        
        if postureAttr ~= nil then
            character:SetAttribute("Posture", math.clamp(value, 0, self.MaxStamina))
            return true
        end
        
        if staminaAttr ~= nil then
            character:SetAttribute("Stamina", math.clamp(value, 0, self.MaxStamina))
            return true
        end
        
        return false
    end,
    
    -- Get current stamina value
    getStamina = function(self, character)
        if not character then return 0 end
        
        local stamina = character:FindFirstChild("Posture") 
                     or character:FindFirstChild("Stamina") 
                     or character:FindFirstChild("PostureValue")
        
        if stamina and (stamina:IsA("NumberValue") or stamina:IsA("IntValue")) then
            return stamina.Value
        end
        
        local postureAttr = character:GetAttribute("Posture")
        if postureAttr then return postureAttr end
        
        local staminaAttr = character:GetAttribute("Stamina")
        if staminaAttr then return staminaAttr end
        
        return 0
    end,
    
    -- Apply infinite stamina (always max)
    applyInfinite = function(self, character)
        if not character or not self.Enabled or not self.InfiniteMode then return end
        safePcall(function()
            self:setStamina(character, self.MaxStamina)
        end)
    end,
    
    -- Apply regen (increase stamina over time)
    applyRegen = function(self, character, deltaTime)
        if not character or not self.Enabled or self.InfiniteMode then return end
        safePcall(function()
            local currentStamina = self:getStamina(character)
            local regenAmount = (self.MaxStamina * self.RegenRate / 100) * deltaTime
            local newStamina = math.min(currentStamina + regenAmount, self.MaxStamina)
            self:setStamina(character, newStamina)
        end)
    end,
    
    -- Toggle infinite stamina
    toggleInfinite = function(self)
        self.InfiniteMode = not self.InfiniteMode
        if self.InfiniteMode then
            log("Infinite Stamina: ENABLED", "SUCCESS")
        else
            log("Infinite Stamina: DISABLED", "INFO")
        end
        return self.InfiniteMode
    end,
    
    -- Toggle stamina regen
    toggleRegen = function(self)
        if self.InfiniteMode then
            log("Cannot enable Regen while Infinite is active", "WARNING")
            return false
        end
        self.InfiniteMode = false
        log("Stamina Regen: ENABLED (" .. self.RegenRate .. "%/sec)", "SUCCESS")
        return true
    end,
    
    -- Reset to default
    reset = function(self)
        self.Enabled = false
        self.InfiniteMode = false
        log("Stamina Manager reset", "INFO")
    end
}

local SG = Instance.new("ScreenGui")
SG.Name = "XenoPremiumV7"
SG.ResetOnSpawn = false
SG.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 520)
MainFrame.Position = UDim2.new(0.02, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = SG

local MS = Instance.new("UIStroke")
MS.Thickness = 1.5
MS.Color = Color3.fromRGB(30, 80, 160)
MS.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MS.Parent = MainFrame

local MC = Instance.new("UICorner")
MC.CornerRadius = UDim.new(0, 10)
MC.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 38)
Title.Text = "  XENO V7 | GAKURAN"
Title.TextColor3 = Color3.fromRGB(240, 245, 255)
Title.TextSize = 13
Title.Font = Enum.Font.RobotoMono
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundColor3 = Color3.fromRGB(25, 50, 95)
Title.BorderSizePixel = 0
Title.Parent = MainFrame

local TC = Instance.new("UICorner")
TC.CornerRadius = UDim.new(0, 10)
TC.Parent = Title

local HideText = Instance.new("TextLabel")
HideText.Size = UDim2.new(0, 100, 1, 0)
HideText.Position = UDim2.new(1, -110, 0, 0)
HideText.Text = "[ RightShift ]"
HideText.TextColor3 = Color3.fromRGB(150, 180, 230)
HideText.TextSize = 11
HideText.Font = Enum.Font.SourceSans
HideText.TextXAlignment = Enum.TextXAlignment.Right
HideText.BackgroundTransparency = 1
HideText.Parent = Title

local B1 = Instance.new("TextButton")
B1.Size = UDim2.new(0, 210, 0, 35)
B1.Position = UDim2.new(0, 15, 0, 50)
B1.Text = "ESP + Bars Radar: OFF"
B1.TextColor3 = Color3.fromRGB(255, 255, 255)
B1.BackgroundColor3 = Color3.fromRGB(205, 45, 45)
B1.Font = Enum.Font.SourceSansBold
B1.TextSize = 14
B1.Parent = MainFrame

local BC1 = Instance.new("UICorner")
BC1.CornerRadius = UDim.new(0, 6)
BC1.Parent = B1

local B2 = Instance.new("TextButton")
B2.Size = UDim2.new(0, 210, 0, 35)
B2.Position = UDim2.new(0, 15, 0, 95)
B2.Text = "Same Server Rejoin: OFF"
B2.TextColor3 = Color3.fromRGB(255, 255, 255)
B2.BackgroundColor3 = Color3.fromRGB(205, 45, 45)
B2.Font = Enum.Font.SourceSansBold
B2.TextSize = 14
B2.Parent = MainFrame

local BC2 = Instance.new("UICorner")
BC2.CornerRadius = UDim.new(0, 6)
BC2.Parent = B2

local B4 = Instance.new("TextButton")
B4.Size = UDim2.new(0, 210, 0, 35)
B4.Position = UDim2.new(0, 15, 0, 140)
B4.Text = "M1 Damage Assist: OFF"
B4.TextColor3 = Color3.fromRGB(255, 255, 255)
B4.BackgroundColor3 = Color3.fromRGB(205, 45, 45)
B4.Font = Enum.Font.SourceSansBold
B4.TextSize = 14
B4.Parent = MainFrame

local BC4 = Instance.new("UICorner")
BC4.CornerRadius = UDim.new(0, 6)
BC4.Parent = B4

-- [STAMINA BUTTON] Infinite Stamina
local B9 = Instance.new("TextButton")
B9.Size = UDim2.new(0, 100, 0, 35)
B9.Position = UDim2.new(0, 15, 0, 185)
B9.Text = "∞ Stamina: OFF"
B9.TextColor3 = Color3.fromRGB(255, 255, 255)
B9.BackgroundColor3 = Color3.fromRGB(205, 45, 45)
B9.Font = Enum.Font.SourceSansBold
B9.TextSize = 12
B9.Parent = MainFrame

local BC9 = Instance.new("UICorner")
BC9.CornerRadius = UDim.new(0, 6)
BC9.Parent = B9

-- [STAMINA BUTTON] Stamina Regen
local B10 = Instance.new("TextButton")
B10.Size = UDim2.new(0, 100, 0, 35)
B10.Position = UDim2.new(0, 125, 0, 185)
B10.Text = "↑ Regen: OFF"
B10.TextColor3 = Color3.fromRGB(255, 255, 255)
B10.BackgroundColor3 = Color3.fromRGB(205, 45, 45)
B10.Font = Enum.Font.SourceSansBold
B10.TextSize = 12
B10.Parent = MainFrame

local BC10 = Instance.new("UICorner")
BC10.CornerRadius = UDim.new(0, 6)
BC10.Parent = B10

DropContainer = Instance.new("ScrollingFrame")
DropContainer.Size = UDim2.new(0, 210, 0, 80)
DropContainer.Position = UDim2.new(0, 15, 0, 230)
DropContainer.BackgroundColor3 = Color3.fromRGB(25, 35, 60)
DropContainer.BorderSizePixel = 0
DropContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
DropContainer.ScrollBarThickness = 4
DropContainer.Parent = MainFrame

DropListLayout = Instance.new("UIListLayout")
DropListLayout.Padding = UDim.new(0, 4)
DropListLayout.Parent = DropContainer

local DropCorner = Instance.new("UICorner")
DropCorner.CornerRadius = UDim.new(0, 6)
DropCorner.Parent = DropContainer

local B5 = Instance.new("TextButton")
B5.Size = UDim2.new(0, 210, 0, 35)
B5.Position = UDim2.new(0, 15, 0, 320)
B5.Text = "⚡ Teleport Behind Target"
B5.TextColor3 = Color3.fromRGB(255, 255, 255)
B5.BackgroundColor3 = Color3.fromRGB(25, 100, 210)
B5.Font = Enum.Font.SourceSansBold
B5.TextSize = 14
B5.Parent = MainFrame

local BC5 = Instance.new("UICorner")
BC5.CornerRadius = UDim.new(0, 6)
BC5.Parent = B5

-- [COOLDOWN DISPLAY] Heavy Attack Cooldown Button
local B6 = Instance.new("TextButton")
B6.Size = UDim2.new(0, 100, 0, 35)
B6.Position = UDim2.new(0, 15, 0, 365)
B6.Text = "Heavy Atk: RDY"
B6.TextColor3 = Color3.fromRGB(255, 255, 255)
B6.BackgroundColor3 = Color3.fromRGB(220, 120, 45)
B6.Font = Enum.Font.SourceSansBold
B6.TextSize = 12
B6.Parent = MainFrame

local BC6 = Instance.new("UICorner")
BC6.CornerRadius = UDim.new(0, 6)
BC6.Parent = B6

-- [COOLDOWN DISPLAY] Block Cooldown Button
local B7 = Instance.new("TextButton")
B7.Size = UDim2.new(0, 100, 0, 35)
B7.Position = UDim2.new(0, 125, 0, 365)
B7.Text = "Block: RDY"
B7.TextColor3 = Color3.fromRGB(255, 255, 255)
B7.BackgroundColor3 = Color3.fromRGB(100, 150, 220)
B7.Font = Enum.Font.SourceSansBold
B7.TextSize = 12
B7.Parent = MainFrame

local BC7 = Instance.new("UICorner")
BC7.CornerRadius = UDim.new(0, 6)
BC7.Parent = B7

-- [COOLDOWN DISPLAY] Evasion Cooldown Button
local B8 = Instance.new("TextButton")
B8.Size = UDim2.new(0, 100, 0, 35)
B8.Position = UDim2.new(0, 235, 0, 365)
B8.Text = "Evade: RDY"
B8.TextColor3 = Color3.fromRGB(255, 255, 255)
B8.BackgroundColor3 = Color3.fromRGB(150, 220, 150)
B8.Font = Enum.Font.SourceSansBold
B8.TextSize = 12
B8.Parent = MainFrame

local BC8 = Instance.new("UICorner")
BC8.CornerRadius = UDim.new(0, 6)
BC8.Parent = B8

local B3 = Instance.new("TextButton")
B3.Size = UDim2.new(0, 210, 0, 35)
B3.Position = UDim2.new(0, 15, 0, 470)
B3.Text = "⛔ Unload Script"
B3.TextColor3 = Color3.fromRGB(255, 255, 255)
B3.BackgroundColor3 = Color3.fromRGB(45, 50, 60)
B3.Font = Enum.Font.SourceSansBold
B3.TextSize = 14
B3.Parent = MainFrame

local BC3 = Instance.new("UICorner")
BC3.CornerRadius = UDim.new(0, 6)
BC3.Parent = B3

-- [FEATURE #8] Hotkey System
local Hotkeys = {
    ESP = Enum.KeyCode.E,
    Respawn = Enum.KeyCode.R,
    Hitbox = Enum.KeyCode.H,
    TeleportUndo = Enum.KeyCode.U,
    HeavyAttack = Enum.KeyCode.Q,
    Block = Enum.KeyCode.F,
    Evasion = Enum.KeyCode.Space,
    InfiniteStamina = Enum.KeyCode.I,
    StaminaRegen = Enum.KeyCode.T
}

-- [FEATURE #9] Teleport History
local teleportHistory = {}
local maxHistory = 5

local function recordTeleport(pos)
    table.insert(teleportHistory, 1, pos)
    if #teleportHistory > maxHistory then
        table.remove(teleportHistory)
    end
    log("Teleport recorded. History: " .. #teleportHistory, "INFO")
end

local function undoTeleport()
    if #teleportHistory > 0 then
        local lastPos = table.remove(teleportHistory, 1)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = lastPos
            log("Teleport undone!", "SUCCESS")
        end
    else
        log("No teleport history!", "WARNING")
    end
end

-- [FEATURE #10] FPS/Performance Indicator
local lastFrameTime = tick()
local lastDeltaTime = 0
local fps = 0

-- [FEATURE #6] Helper function untuk mendapatkan Posture/Stamina value
local function getPostureValue(character)
    if not character then return 100 end
    
    local postureValue = character:FindFirstChild("Posture") or character:FindFirstChild("Stamina") or character:FindFirstChild("PostureValue")
    if postureValue and (postureValue:IsA("NumberValue") or postureValue:IsA("IntValue")) then
        return math.clamp(postureValue.Value, 0, 100)
    end
    
    local att = character:GetAttribute("Posture") or character:GetAttribute("Stamina")
    if att then return math.clamp(tonumber(att) or 100, 0, 100) end
    
    return 100
end

local function clear()
    safePcall(function()
        for _, v in pairs(Workspace:GetChildren()) do
            if v:FindFirstChild("XESP") then v.XESP:Destroy() end
        end
        for _, v in pairs(Players:GetPlayers()) do
            if v.Character and v.Character:FindFirstChild("XESP") then v.Character.XESP:Destroy() end
        end
    end)
end

-- [FEATURE #3] Safe clean untuk memory leak prevention
local function safeClean()
    safePcall(function()
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:FindFirstChild("XESP") then
                pcall(function() v.XESP:Destroy() end)
            end
        end
    end)
end

local function buatSelfHUD()
    if CoreGui:FindFirstChild("XenoSelfHUD") then return end
    safePcall(function()
        local hudSG = Instance.new("ScreenGui")
        hudSG.Name = "XenoSelfHUD"
        hudSG.ResetOnSpawn = false
        hudSG.Parent = CoreGui

        local hudFrame = Instance.new("Frame")
        hudFrame.Name = "HUDFrame"
        hudFrame.Size = UDim2.new(0, 240, 0, 150)
        hudFrame.Position = UDim2.new(1, -255, 1, -165)
        hudFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
        hudFrame.BorderSizePixel = 0
        hudFrame.Parent = hudSG

        local hudCorner = Instance.new("UICorner")
        hudCorner.CornerRadius = UDim.new(0, 8)
        hudCorner.Parent = hudFrame

        local hudStroke = Instance.new("UIStroke")
        hudStroke.Thickness = 1.5
        hudStroke.Color = Color3.fromRGB(30, 80, 160)
        hudStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        hudStroke.Parent = hudFrame

        local hudTitle = Instance.new("TextLabel")
        hudTitle.Name = "HUDTitle"
        hudTitle.Size = UDim2.new(1, -20, 0, 25)
        hudTitle.Position = UDim2.new(0, 10, 0, 5)
        hudTitle.Text = "MY STATUS (FPS: 0)"
        hudTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
        hudTitle.TextSize = 11
        hudTitle.Font = Enum.Font.RobotoMono
        hudTitle.TextXAlignment = Enum.TextXAlignment.Left
        hudTitle.BackgroundTransparency = 1
        hudTitle.Parent = hudFrame

        local hpBack = Instance.new("Frame")
        hpBack.Name = "HPBack"
        hpBack.Size = UDim2.new(1, -20, 0, 15)
        hpBack.Position = UDim2.new(0, 10, 0, 35)
        hpBack.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
        hpBack.BorderSizePixel = 0
        hpBack.Parent = hudFrame

        local hpBar = Instance.new("Frame")
        hpBar.Name = "HPBar"
        hpBar.Size = UDim2.new(0, 0, 1, 0)
        hpBar.BackgroundColor3 = Color3.fromRGB(45, 185, 45)
        hpBar.BorderSizePixel = 0
        hpBar.Parent = hpBack

        local hpText = Instance.new("TextLabel")
        hpText.Name = "HPText"
        hpText.Size = UDim2.new(1, 0, 1, 0)
        hpText.Text = "HP: 0/0 (0%)"
        hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
        hpText.TextSize = 10
        hpText.Font = Enum.Font.SourceSansBold
        hpText.BackgroundTransparency = 1
        hpText.Parent = hpBack

        local stBack = Instance.new("Frame")
        stBack.Name = "STBack"
        stBack.Size = UDim2.new(1, -20, 0, 15)
        stBack.Position = UDim2.new(0, 10, 0, 55)
        stBack.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
        stBack.BorderSizePixel = 0
        stBack.Parent = hudFrame

        local stBar = Instance.new("Frame")
        stBar.Name = "STBar"
        stBar.Size = UDim2.new(0, 0, 1, 0)
        stBar.BackgroundColor3 = Color3.fromRGB(230, 160, 35)
        stBar.BorderSizePixel = 0
        stBar.Parent = stBack

        local stText = Instance.new("TextLabel")
        stText.Name = "STText"
        stText.Size = UDim2.new(1, 0, 1, 0)
        stText.Text = "POSTURE: 0 (0%)"
        stText.TextColor3 = Color3.fromRGB(255, 255, 255)
        stText.TextSize = 10
        stText.Font = Enum.Font.SourceSansBold
        stText.BackgroundTransparency = 1
        stText.Parent = stBack

        -- [FEATURE #11] Distance Indicator
        local distLabel = Instance.new("TextLabel")
        distLabel.Name = "DistanceLabel"
        distLabel.Size = UDim2.new(1, -20, 0, 15)
        distLabel.Position = UDim2.new(0, 10, 0, 75)
        distLabel.Text = "Target Distance: --"
        distLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
        distLabel.TextSize = 9
        distLabel.Font = Enum.Font.SourceSans
        distLabel.BackgroundTransparency = 1
        distLabel.Parent = hudFrame

        -- [COOLDOWN DISPLAY] Cooldown info on HUD
        local cooldownLabel = Instance.new("TextLabel")
        cooldownLabel.Name = "CooldownLabel"
        cooldownLabel.Size = UDim2.new(1, -20, 0, 15)
        cooldownLabel.Position = UDim2.new(0, 10, 0, 95)
        cooldownLabel.Text = "HA: 0.0s | BLK: 0.0s | EVD: 0.0s"
        cooldownLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        cooldownLabel.TextSize = 8
        cooldownLabel.Font = Enum.Font.SourceSans
        cooldownLabel.BackgroundTransparency = 1
        cooldownLabel.Parent = hudFrame

        -- [STAMINA MODE DISPLAY]
        local staminaStatus = Instance.new("TextLabel")
        staminaStatus.Name = "StaminaStatus"
        staminaStatus.Size = UDim2.new(1, -20, 0, 15)
        staminaStatus.Position = UDim2.new(0, 10, 0, 115)
        staminaStatus.Text = "Stamina: NORMAL"
        staminaStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
        staminaStatus.TextSize = 9
        staminaStatus.Font = Enum.Font.SourceSans
        staminaStatus.BackgroundTransparency = 1
        staminaStatus.Parent = hudFrame

        log("Self HUD created successfully", "SUCCESS")
    end)
end

local function updateSelfHUD()
    if not CoreGui:FindFirstChild("XenoSelfHUD") then return end
    safePcall(function()
        local f = CoreGui.XenoSelfHUD:FindFirstChild("HUDFrame")
        if not f or not LocalPlayer.Character then return end
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        local currentHP = math.clamp(hum.Health, 0, hum.MaxHealth)
        local maxHP = hum.MaxHealth
        local pctHP = maxHP > 0 and (currentHP / maxHP) or 0
        local hpPercent = math.floor(pctHP * 100)

        local currentStamina = getPostureValue(LocalPlayer.Character)
        local pctST = currentStamina / 100
        local stPercent = math.floor(pctST * 100)

        f.HPBack.HPBar.Size = UDim2.new(pctHP, 0, 1, 0)
        f.HPBack.HPText.Text = "HP: " .. math.floor(currentHP) .. " / " .. math.floor(maxHP) .. " (" .. hpPercent .. "%)"
        f.STBack.STBar.Size = UDim2.new(pctST, 0, 1, 0)
        f.STBack.STText.Text = "POSTURE/STM: " .. math.floor(currentStamina) .. " (" .. stPercent .. "%)"
        
        -- [FEATURE #10] Update FPS display
        f.HUDTitle.Text = "MY STATUS (FPS: " .. fps .. ")"
        
        -- [FEATURE #11] Update distance display
        if targetPlayerName ~= "" then
            local tPlr = Players:FindFirstChild(targetPlayerName)
            if tPlr and tPlr.Character then
                local tPos = tPlr.Character:FindFirstChild("HumanoidRootPart")
                local myPos = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if tPos and myPos then
                    local distance = math.floor((tPos.Position - myPos.Position).Magnitude)
                    f.DistanceLabel.Text = "Target Distance: " .. distance .. "m"
                end
            end
        else
            f.DistanceLabel.Text = "Target Distance: --"
        end
        
        -- [STAMINA STATUS] Update stamina mode display
        if StaminaManager.Enabled then
            if StaminaManager.InfiniteMode then
                f.StaminaStatus.Text = "Stamina: ∞ INFINITE"
                f.StaminaStatus.TextColor3 = Color3.fromRGB(255, 200, 50)
            else
                f.StaminaStatus.Text = "Stamina: ↑ REGEN (" .. StaminaManager.RegenRate .. "%/s)"
                f.StaminaStatus.TextColor3 = Color3.fromRGB(100, 200, 255)
            end
        else
            f.StaminaStatus.Text = "Stamina: NORMAL"
            f.StaminaStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)
end

local function updateDropdown()
    safePcall(function()
        for _, child in pairs(DropContainer:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -6, 0, 22)
                btn.Text = " " .. p.DisplayName .. " (@" .. p.Name .. ")"
                btn.TextColor3 = Color3.fromRGB(200, 220, 255)
                btn.BackgroundColor3 = Color3.fromRGB(35, 50, 85)
                btn.Font = Enum.Font.SourceSans
                btn.TextSize = 13
                btn.TextXAlignment = Enum.TextXAlignment.Left
                
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 4)
                btnCorner.Parent = btn
                
                if targetPlayerName == p.Name then
                    btn.BackgroundColor3 = Color3.fromRGB(45, 125, 230)
                    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
                
                table.insert(connections, btn.MouseButton1Click:Connect(function()
                    targetPlayerName = p.Name
                    updateDropdown()
                    log("Target selected: " .. p.Name, "INFO")
                end))
                btn.Parent = DropContainer
            end
        end
        DropContainer.CanvasSize = UDim2.new(0, 0, 0, DropListLayout.AbsoluteContentSize.Y)
    end)
end

table.insert(connections, B1.MouseButton1Click:Connect(function()
    if not _G.XBActive then return end
    Settings.ESP = not Settings.ESP
    B1.Text = Settings.ESP and "ESP + Bars Radar: ON" or "ESP + Bars Radar: OFF"
    B1.BackgroundColor3 = Settings.ESP and Color3.fromRGB(45, 185, 45) or Color3.fromRGB(205, 45, 45)
    if not Settings.ESP then 
        clear() 
        log("ESP disabled", "INFO")
    else
        log("ESP enabled", "SUCCESS")
    end
end))

local function rejoinSama()
    safePcall(function()
        local ts = game:GetService("TeleportService")
        if #Players:GetPlayers() <= 1 then
            ts:Teleport(game.PlaceId, LocalPlayer)
        else
            ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
        log("Rejoin initiated", "INFO")
    end)
end

table.insert(connections, B2.MouseButton1Click:Connect(function()
    if not _G.XBActive then return end
    Settings.Respawn = not Settings.Respawn
    B2.Text = Settings.Respawn and "Same Server Rejoin: ON" or "Same Server Rejoin: OFF"
    B2.BackgroundColor3 = Settings.Respawn and Color3.fromRGB(45, 185, 45) or Color3.fromRGB(205, 45, 45)
    if Settings.Respawn then 
        rejoinSama()
        log("Same server rejoin enabled", "SUCCESS")
    else
        log("Same server rejoin disabled", "INFO")
    end
end))

table.insert(connections, B4.MouseButton1Click:Connect(function()
    if not _G.XBActive then return end
    Settings.Hitbox = not Settings.Hitbox
    B4.Text = Settings.Hitbox and "M1 Damage Assist: ON" or "M1 Damage Assist: OFF"
    B4.BackgroundColor3 = Settings.Hitbox and Color3.fromRGB(45, 185, 45) or Color3.fromRGB(205, 45, 45)
    log("M1 Damage Assist: " .. (Settings.Hitbox and "ON" or "OFF"), "INFO")
end))

-- [STAMINA] Infinite Stamina Button
table.insert(connections, B9.MouseButton1Click:Connect(function()
    if not _G.XBActive then return end
    StaminaManager.Enabled = not StaminaManager.Enabled
    StaminaManager.InfiniteMode = true
    
    B9.Text = StaminaManager.Enabled and "∞ Stamina: ON" or "∞ Stamina: OFF"
    B9.BackgroundColor3 = StaminaManager.Enabled and Color3.fromRGB(45, 185, 45) or Color3.fromRGB(205, 45, 45)
    B10.BackgroundColor3 = Color3.fromRGB(205, 45, 45)
    B10.Text = "↑ Regen: OFF"
    
    log("Infinite Stamina: " .. (StaminaManager.Enabled and "ON" or "OFF"), "INFO")
end))

-- [STAMINA] Regen Stamina Button
table.insert(connections, B10.MouseButton1Click:Connect(function()
    if not _G.XBActive then return end
    if StaminaManager.Enabled and StaminaManager.InfiniteMode then
        -- Disable infinite first
        StaminaManager.Enabled = false
        B9.BackgroundColor3 = Color3.fromRGB(205, 45, 45)
        B9.Text = "∞ Stamina: OFF"
    end
    
    StaminaManager.Enabled = not StaminaManager.Enabled
    StaminaManager.InfiniteMode = false
    
    B10.Text = StaminaManager.Enabled and ("↑ Regen: ON (" .. StaminaManager.RegenRate .. "%/s)") or "↑ Regen: OFF"
    B10.BackgroundColor3 = StaminaManager.Enabled and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(205, 45, 45)
    
    log("Stamina Regen: " .. (StaminaManager.Enabled and "ON" or "OFF"), "INFO")
end))

table.insert(connections, B5.MouseButton1Click:Connect(function()
    if not _G.XBActive or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    if targetPlayerName ~= "" then
        safePcall(function()
            local tPlr = Players:FindFirstChild(targetPlayerName)
            if tPlr and tPlr.Character and tPlr.Character:FindFirstChild("HumanoidRootPart") then
                recordTeleport(LocalPlayer.Character.HumanoidRootPart.CFrame)
                LocalPlayer.Character.HumanoidRootPart.CFrame = tPlr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                log("Teleported behind " .. targetPlayerName, "SUCCESS")
            end
        end)
    else
        log("No target selected!", "WARNING")
    end
end))

table.insert(connections, UserInputService.InputBegan:Connect(function(i, g)
    if g then return end
    
    if i.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
        if CoreGui:FindFirstChild("XenoSelfHUD") and CoreGui.XenoSelfHUD:FindFirstChild("HUDFrame") then
            CoreGui.XenoSelfHUD.HUDFrame.Visible = MainFrame.Visible
        end
    end
    
    -- [FEATURE #8] Hotkey handlers
    if i.KeyCode == Hotkeys.ESP then
        Settings.ESP = not Settings.ESP
        B1.Text = Settings.ESP and "ESP + Bars Radar: ON" or "ESP + Bars Radar: OFF"
        B1.BackgroundColor3 = Settings.ESP and Color3.fromRGB(45, 185, 45) or Color3.fromRGB(205, 45, 45)
        if not Settings.ESP then clear() end
        log("ESP toggled: " .. (Settings.ESP and "ON" or "OFF"), "INFO")
    elseif i.KeyCode == Hotkeys.Respawn then
        Settings.Respawn = not Settings.Respawn
        B2.BackgroundColor3 = Settings.Respawn and Color3.fromRGB(45, 185, 45) or Color3.fromRGB(205, 45, 45)
        log("Respawn toggled: " .. (Settings.Respawn and "ON" or "OFF"), "INFO")
    elseif i.KeyCode == Hotkeys.Hitbox then
        Settings.Hitbox = not Settings.Hitbox
        B4.BackgroundColor3 = Settings.Hitbox and Color3.fromRGB(45, 185, 45) or Color3.fromRGB(205, 45, 45)
        log("Hitbox toggled: " .. (Settings.Hitbox and "ON" or "OFF"), "INFO")
    elseif i.KeyCode == Hotkeys.TeleportUndo then
        undoTeleport()
    
    -- [STAMINA HOTKEYS]
    elseif i.KeyCode == Hotkeys.InfiniteStamina then
        StaminaManager.Enabled = not StaminaManager.Enabled
        StaminaManager.InfiniteMode = true
        B9.Text = StaminaManager.Enabled and "∞ Stamina: ON" or "∞ Stamina: OFF"
        B9.BackgroundColor3 = StaminaManager.Enabled and Color3.fromRGB(45, 185, 45) or Color3.fromRGB(205, 45, 45)
        B10.BackgroundColor3 = Color3.fromRGB(205, 45, 45)
        B10.Text = "↑ Regen: OFF"
        log("Infinite Stamina hotkey: " .. (StaminaManager.Enabled and "ON" or "OFF"), "INFO")
    elseif i.KeyCode == Hotkeys.StaminaRegen then
        if StaminaManager.Enabled and StaminaManager.InfiniteMode then
            StaminaManager.Enabled = false
            B9.BackgroundColor3 = Color3.fromRGB(205, 45, 45)
            B9.Text = "∞ Stamina: OFF"
        end
        StaminaManager.Enabled = not StaminaManager.Enabled
        StaminaManager.InfiniteMode = false
        B10.Text = StaminaManager.Enabled and ("↑ Regen: ON (" .. StaminaManager.RegenRate .. "%/s)") or "↑ Regen: OFF"
        B10.BackgroundColor3 = StaminaManager.Enabled and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(205, 45, 45)
        log("Stamina Regen hotkey: " .. (StaminaManager.Enabled and "ON" or "OFF"), "INFO")
    end
end))

local function esp(ch, npc)
    if not ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("XESP") then return end
    
    safePcall(function()
        local f = Instance.new("Folder")
        f.Name = "XESP"
        f.Parent = ch
        
        local b = Instance.new("BillboardGui")
        b.AlwaysOnTop = true
        b.Size = UDim2.new(0, 140, 0, 55)
        b.MaxDistance = 350
        b.Adornee = ch:FindFirstChild("Head") or ch.HumanoidRootPart
        
        local titleL = Instance.new("TextLabel")
        titleL.Size = UDim2.new(1, 0, 0, 15)
        titleL.BackgroundTransparency = 1
        titleL.TextSize = 10
        titleL.Font = Enum.Font.RobotoMono
        titleL.TextColor3 = npc and Color3.fromRGB(255, 140, 140) or Color3.fromRGB(220, 235, 255)
        titleL.TextStrokeTransparency = 0.5
        titleL.Text = (npc and "[NPC] " or "") .. ch.Name
        titleL.Parent = b

        local hum = ch:FindFirstChildOfClass("Humanoid")
        local curHP = hum and hum.Health or 0
        local maxHP = hum and hum.MaxHealth or 100
        local pctHP = math.clamp(curHP / maxHP, 0, 1)
        local hpPercent = math.floor(pctHP * 100)

        local hpB = Instance.new("Frame")
        hpB.Name = "HPB"
        hpB.Size = UDim2.new(1, 0, 0, 10)
        hpB.Position = UDim2.new(0, 0, 0, 18)
        hpB.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
        hpB.BorderSizePixel = 0
        hpB.Parent = b

        local hpF = Instance.new("Frame")
        hpF.Size = UDim2.new(pctHP, 0, 1, 0)
        hpF.BackgroundColor3 = Color3.fromRGB(45, 185, 45)
        hpF.BorderSizePixel = 0
        hpF.Parent = hpB

        local hpT = Instance.new("TextLabel")
        hpT.Size = UDim2.new(1, 0, 1, 0)
        hpT.BackgroundTransparency = 1
        hpT.TextSize = 9
        hpT.Font = Enum.Font.SourceSansBold
        hpT.TextColor3 = Color3.fromRGB(255, 255, 255)
        hpT.Text = "HP: " .. hpPercent .. "%"
        hpT.Parent = hpB

        local curST = getPostureValue(ch)
        local pctST = math.clamp(curST / 100, 0, 1)

        local stB = Instance.new("Frame")
        stB.Name = "STB"
        stB.Size = UDim2.new(1, 0, 0, 10)
        stB.Position = UDim2.new(0, 0, 0, 32)
        stB.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
        stB.BorderSizePixel = 0
        stB.Parent = b

        local stF = Instance.new("Frame")
        stF.Size = UDim2.new(pctST, 0, 1, 0)
        stF.BackgroundColor3 = Color3.fromRGB(230, 160, 35)
        stF.BorderSizePixel = 0
        stF.Parent = stB

        local stT = Instance.new("TextLabel")
        stT.Size = UDim2.new(1, 0, 1, 0)
        stT.BackgroundTransparency = 1
        stT.TextSize = 9
        stT.Font = Enum.Font.SourceSansBold
        stT.TextColor3 = Color3.fromRGB(255, 255, 255)
        stT.Text = "STM: " .. math.floor(pctST * 100) .. "%"
        stT.Parent = stB

        b.Parent = f
    end)
end

table.insert(connections, RunService.RenderStepped:Connect(function()
    -- [FEATURE #10] FPS Counter
    local currentTime = tick()
    local delta = currentTime - lastFrameTime
    if delta > 0 then
        fps = math.floor(1 / delta)
    end
    lastDeltaTime = delta
    lastFrameTime = currentTime
    
    -- [STAMINA SYSTEM] Apply stamina modifications
    if _G.XBActive and LocalPlayer.Character and StaminaManager.Enabled then
        if StaminaManager.InfiniteMode then
            StaminaManager:applyInfinite(LocalPlayer.Character)
        else
            StaminaManager:applyRegen(LocalPlayer.Character, lastDeltaTime)
        end
    end
    
    if _G.XBActive and Settings.Hitbox and targetPlayerName ~= "" then
        safePcall(function()
            local tPlr = Players:FindFirstChild(targetPlayerName)
            if tPlr and tPlr.Character and tPlr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local myHRP = LocalPlayer.Character.HumanoidRootPart
                local tHRP = tPlr.Character.HumanoidRootPart
                local distance = (myHRP.Position - tHRP.Position).Magnitude
                if distance <= 18 then
                    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        tHRP.CFrame = myHRP.CFrame * CFrame.new(0, 0, -2.5)
                    end
                end
            end
        end)
    end
end))

task.spawn(function()
    buatSelfHUD()
    -- [FEATURE #6] Anti-crash loop protection
    local loopCount = 0
    while _G.XBActive and loopCount < 999999 do
        loopCount = loopCount + 1
        if loopCount % 100 == 0 then
            loopCount = 0
        end
        
        safePcall(function()
            updateDropdown()
            updateSelfHUD()
            if Settings.ESP and LocalPlayer.Character then
                clear()
                for _, v in pairs(Players:GetPlayers()) do
                    if v ~= LocalPlayer and v.Character then esp(v.Character, false) end
                end
                for _, v in pairs(Workspace:GetChildren()) do
                    if v:IsA("Model") and v ~= LocalPlayer.Character and v:FindFirstChildOfClass("Humanoid") then esp(v, true) end
                end
            end
        end)
        
        task.wait(0.5)
    end
    log("Main loop ended", "INFO")
end)

local function watch(ch)
    safePcall(function()
        local hum = ch:WaitForChild("Humanoid", 10)
        if hum then
            table.insert(connections, hum.Died:Connect(function()
                log("Character died, resetting stamina", "WARNING")
                
                if _G.XBActive and Settings.Respawn then
                    log("Character died, initiating rejoin...", "WARNING")
                    task.wait(0.1)
                    rejoinSama()
                end
            end))
        end
    end)
end

table.insert(connections, Players.PlayerAdded:Connect(function(plr)
    log("Player joined: " .. plr.Name, "INFO")
    updateDropdown()
end))

table.insert(connections, Players.PlayerRemoving:Connect(function(plr)
    log("Player left: " .. plr.Name, "INFO")
    if targetPlayerName == plr.Name then
        targetPlayerName = ""
        log("Target disconnected, cleared", "WARNING")
    end
    updateDropdown()
end))

table.insert(connections, LocalPlayer.CharacterAdded:Connect(watch))
if LocalPlayer.Character then watch(LocalPlayer.Character) end

table.insert(connections, B3.MouseButton1Click:Connect(function()
    -- [FEATURE #5] Unload with proper cleanup
    safePcall(function()
        log("Unloading script...", "WARNING")
        _G.XBActive = false
        clear()
        safeClean()
        
        if CoreGui:FindFirstChild("XenoSelfHUD") then 
            CoreGui.XenoSelfHUD:Destroy() 
        end
        if SG then SG:Destroy() end
        
        -- Disconnect semua events
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        
        log("Script unloaded successfully", "SUCCESS")
    end)
end))

updateDropdown()
log("XENO V7 loaded successfully!", "SUCCESS")
log("Stamina Hotkeys: I=Infinite | T=Regen | Hide UI: RightShift", "INFO")
