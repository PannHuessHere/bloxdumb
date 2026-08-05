-- GARA ESP with Advanced Stamina System
-- Draggable GUI + Close + Player ESP (name / health / stamina)
-- Stamina system based on: https://github.com/ahmadtatatata57-coder/roblox-penetrar/blob/main/gara_stamina.lua
-- Usage: paste & run. Unload with _G.SIMPLE_GUI_DRAG_UNLOAD()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer or not LocalPlayer.Character then
    warn("GARA ESP: LocalPlayer tidak ditemukan atau belum spawn")
    return
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
local parent = PlayerGui or CoreGui

-- cleanup previous
pcall(function()
    local old = parent:FindFirstChild("SimpleDraggableGUI")
    if old then old:Destroy() end
end)

-- connection registry
local connections = {}
local function reg(c) if c then table.insert(connections, c) end return c end
local function disconnectAll()
    for i = #connections, 1, -1 do
        local c = connections[i]
        pcall(function()
            if typeof(c) == "RBXScriptConnection" then c:Disconnect()
            elseif type(c) == "table" and c.Disconnect then c:Disconnect()
            end
        end)
        connections[i] = nil
    end
end

-- ESP state
local ESP_ENABLED = false
local ESP_DISTANCE = 200
local espFolders = {} -- player -> folder

local function safeDestroy(obj)
    if obj and obj.Parent then pcall(function() obj:Destroy() end) end
end

-- [ADVANCED STAMINA SYSTEM] Based on gara_stamina.lua reference
local StaminaManager = {
    MaxStamina = 100,
    
    -- Get stamina value from character (supports Value objects and Attributes)
    getStamina = function(self, character)
        if not character then return 0 end
        
        -- Try as Value object (NumberValue/IntValue)
        local stamina = character:FindFirstChild("Posture")
                     or character:FindFirstChild("Stamina")
                     or character:FindFirstChild("PostureValue")
                     or character:FindFirstChild("Energy")
        
        if stamina and (stamina:IsA("NumberValue") or stamina:IsA("IntValue")) then
            return stamina.Value
        end
        
        -- Try as Attribute
        local postureAttr = character:GetAttribute("Posture")
        local staminaAttr = character:GetAttribute("Stamina")
        
        if postureAttr ~= nil then
            return tonumber(postureAttr) or 0
        end
        
        if staminaAttr ~= nil then
            return tonumber(staminaAttr) or 0
        end
        
        -- Check Humanoid for attributes
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hum then
            local humPosture = hum:GetAttribute("Posture")
            local humStamina = hum:GetAttribute("Stamina")
            
            if humPosture ~= nil then
                return tonumber(humPosture) or 0
            end
            
            if humStamina ~= nil then
                return tonumber(humStamina) or 0
            end
        end
        
        return 0
    end,
    
    -- Set stamina value to character
    setStamina = function(self, character, value)
        if not character then return false end
        
        value = math.clamp(value, 0, self.MaxStamina)
        
        -- Try as Value object
        local stamina = character:FindFirstChild("Posture")
                     or character:FindFirstChild("Stamina")
                     or character:FindFirstChild("PostureValue")
        
        if stamina and (stamina:IsA("NumberValue") or stamina:IsA("IntValue")) then
            stamina.Value = value
            return true
        end
        
        -- Try as Attribute
        local postureAttr = character:GetAttribute("Posture")
        local staminaAttr = character:GetAttribute("Stamina")
        
        if postureAttr ~= nil then
            character:SetAttribute("Posture", value)
            return true
        end
        
        if staminaAttr ~= nil then
            character:SetAttribute("Stamina", value)
            return true
        end
        
        return false
    end
}

-- Legacy function wrapper for compatibility
local function readStaminaValueForPlayer(pl)
    if not pl or not pl.Character then return nil end
    local value = StaminaManager:getStamina(pl.Character)
    return value > 0 and value or nil
end

-- ESP create/remove (same as before), now uses readStaminaValueForPlayer to show stamina
local function createESPForPlayer(pl)
    if not pl or not pl.Character then return end
    if espFolders[pl] then return end
    local ch = pl.Character
    local folder = Instance.new("Folder")
    folder.Name = "GARA_ESP"
    folder.Parent = ch
    espFolders[pl] = folder

    local head = ch:FindFirstChild("Head") or ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("HumanoidRootPart")
    local adornee = head or ch:FindFirstChildWhichIsA("BasePart")
    local bg = Instance.new("BillboardGui")
    bg.Name = "GaraESP_Billboard"
    bg.Adornee = adornee
    bg.Size = UDim2.new(0,160,0,60)
    bg.StudsOffset = Vector3.new(0, 2.4, 0)
    bg.AlwaysOnTop = true
    bg.Parent = folder

    local frame = Instance.new("Frame", bg)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 0.4
    frame.BackgroundColor3 = Color3.fromRGB(10,10,10)
    frame.BorderSizePixel = 0
    local cr = Instance.new("UICorner", frame)
    cr.CornerRadius = UDim.new(0,6)

    local nameLabel = Instance.new("TextLabel", frame)
    nameLabel.Size = UDim2.new(1,-8,0,18)
    nameLabel.Position = UDim2.new(0,4,0,2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = pl.Name
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local hpLabel = Instance.new("TextLabel", frame)
    hpLabel.Size = UDim2.new(1,-8,0,16)
    hpLabel.Position = UDim2.new(0,4,0,22)
    hpLabel.BackgroundTransparency = 1
    hpLabel.Text = "HP: ?"
    hpLabel.Font = Enum.Font.SourceSans
    hpLabel.TextSize = 13
    hpLabel.TextColor3 = Color3.fromRGB(200,200,200)
    hpLabel.TextXAlignment = Enum.TextXAlignment.Left

    local stamLabel = Instance.new("TextLabel", frame)
    stamLabel.Size = UDim2.new(1,-8,0,16)
    stamLabel.Position = UDim2.new(0,4,0,38)
    stamLabel.BackgroundTransparency = 1
    stamLabel.Text = "Stamina: ?"
    stamLabel.Font = Enum.Font.SourceSans
    stamLabel.TextSize = 13
    stamLabel.TextColor3 = Color3.fromRGB(200,200,200)
    stamLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- store refs
    folder:SetAttribute("nameLabel", true)
    folder:SetAttribute("hpLabel", true)
    folder:SetAttribute("stamLabel", true)
end

local function removeESPForPlayer(pl)
    if not pl then return end
    local f = espFolders[pl]
    if f and f.Parent then pcall(function() f:Destroy() end) end
    espFolders[pl] = nil
end

-- Build GUI (draggable + controls + detect button)
local SG = Instance.new("ScreenGui")
SG.Name = "SimpleDraggableGUI"
SG.ResetOnSpawn = false
SG.Parent = parent

local Main = Instance.new("Frame", SG)
Main.Name = "Main"
Main.Size = UDim2.new(0, 400, 0, 240)
Main.Position = UDim2.new(0.5, -200, 0.5, -120)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(18,18,18)
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Title bar and drag capture
local TitleBar = Instance.new("Frame", Main)
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(28,28,28)
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)
local DragBtn = Instance.new("TextButton", TitleBar)
DragBtn.Size = UDim2.new(1, 1, 1, 0)
DragBtn.BackgroundTransparency = 1
DragBtn.AutoButtonColor = false
DragBtn.Text = ""
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 40, 0, 24)
CloseBtn.Position = UDim2.new(1, -46, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(170,20,20)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.Text = "X"
CloseBtn.TextSize = 18
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,6)
local Title = Instance.new("TextLabel", TitleBar)
Title.Size = UDim2.new(1, -12 - 46, 1, 0)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "GARA - ESP (with stamina detection)"
Title.Font = Enum.Font.SourceSansSemibold
Title.TextSize = 14
Title.TextColor3 = Color3.fromRGB(230,230,230)
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Controls area
local controls = Instance.new("Frame", Main)
controls.Size = UDim2.new(1, -24, 0, 92)
controls.Position = UDim2.new(0, 12, 0, 44)
controls.BackgroundTransparency = 1

local function makeRow(parent, y, labelText)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,28)
    row.Position = UDim2.new(0,0,0, y)
    row.BackgroundTransparency = 1
    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0.5,0,1,0)
    label.Position = UDim2.new(0,0,0,0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(220,220,220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    return row, label
end

local row1, row1Label = makeRow(controls, 0, "Player ESP")
local toggleESP = Instance.new("TextButton", row1)
toggleESP.Size = UDim2.new(0, 60, 0, 22)
toggleESP.Position = UDim2.new(1, -70, 0, 3)
toggleESP.Text = "OFF"
toggleESP.Font = Enum.Font.SourceSansBold
toggleESP.TextSize = 14
toggleESP.BackgroundColor3 = Color3.fromRGB(60,60,60)
toggleESP.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", toggleESP).CornerRadius = UDim.new(0,6)

local row2 = makeRow(controls, 34, "Distance")
local distLabel = Instance.new("TextLabel", row2)
distLabel.Size = UDim2.new(0, 80, 1, 0)
distLabel.Position = UDim2.new(1, -150, 0, 0)
distLabel.BackgroundTransparency = 1
distLabel.Text = tostring(ESP_DISTANCE).." studs"
distLabel.Font = Enum.Font.SourceSans
distLabel.TextSize = 13
distLabel.TextColor3 = Color3.fromRGB(200,200,200)
distLabel.TextXAlignment = Enum.TextXAlignment.Right

local decBtn = Instance.new("TextButton", row2)
decBtn.Size = UDim2.new(0, 28, 0, 22)
decBtn.Position = UDim2.new(1, -116, 0, 3)
decBtn.Text = "-"
decBtn.Font = Enum.Font.SourceSansBold
decBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
decBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", decBtn).CornerRadius = UDim.new(0,6)

local incBtn = Instance.new("TextButton", row2)
incBtn.Size = UDim2.new(0, 28, 0, 22)
incBtn.Position = UDim2.new(1, -82, 0, 3)
incBtn.Text = "+"
incBtn.Font = Enum.Font.SourceSansBold
incBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
incBtn.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", incBtn).CornerRadius = UDim.new(0,6)

-- status & candidates display area
local status = Instance.new("TextLabel", Main)
status.Size = UDim2.new(1, -24, 0, 60)
status.Position = UDim2.new(0, 12, 0, 148)
status.BackgroundTransparency = 1
status.Text = "ESP: OFF\nDistance: "..tostring(ESP_DISTANCE)
status.Font = Enum.Font.SourceSans
status.TextSize = 13
status.TextColor3 = Color3.fromRGB(200,200,200)
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextWrapped = true

-- Draggable logic (capture overlay)
do
    local dragging = false
    local dragInput = nil
    local dragStart = Vector2.new()
    local startPos = Main.Position

    local function getMousePos()
        local ok, pos = pcall(function() return UserInputService:GetMouseLocation() end)
        if ok and pos then return pos end
        return Vector2.new()
    end

    reg(DragBtn.MouseButton1Down:Connect(function()
        dragging = true
        dragInput = Enum.UserInputType.MouseMovement
        dragStart = getMousePos()
        startPos = Main.Position
    end))
    reg(DragBtn.MouseButton1Up:Connect(function()
        dragging = false
        dragInput = nil
    end))
    reg(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            dragInput = nil
        end
    end))
    reg(TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = input
            dragStart = input.Position
            startPos = Main.Position
            reg(input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    dragInput = nil
                end
            end))
        end
    end))
    reg(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        local current
        if input.UserInputType == Enum.UserInputType.MouseMovement then current = getMousePos()
        elseif input.UserInputType == Enum.UserInputType.Touch then current = input.Position
        end
        if not current then return end
        local delta = current - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end))
end

-- Close / unload
reg(CloseBtn.MouseButton1Click:Connect(function()
    if _G.SIMPLE_GUI_DRAG_UNLOAD then
        pcall(_G.SIMPLE_GUI_DRAG_UNLOAD)
    else
        pcall(function() if SG and SG.Parent then SG:Destroy() end end)
        disconnectAll()
    end
end))

-- toggle and distance buttons
reg(toggleESP.MouseButton1Click:Connect(function()
    ESP_ENABLED = not ESP_ENABLED
    toggleESP.Text = ESP_ENABLED and "ON" or "OFF"
    status.Text = (ESP_ENABLED and "ESP: ON\n" or "ESP: OFF\n").. "Distance: "..tostring(ESP_DISTANCE)
    if not ESP_ENABLED then
        for pl,_ in pairs(espFolders) do removeESPForPlayer(pl) end
    else
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                local myRoot = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Torso") or LocalPlayer.Character:FindFirstChild("UpperTorso"))
                if myRoot and pl.Character then
                    local otherRoot = pl.Character:FindFirstChild("HumanoidRootPart") or pl.Character:FindFirstChild("Torso") or pl.Character:FindFirstChild("UpperTorso")
                    if otherRoot and (otherRoot.Position - myRoot.Position).Magnitude <= ESP_DISTANCE then
                        pcall(function() createESPForPlayer(pl) end)
                    end
                end
            end
        end
    end
end))

reg(decBtn.MouseButton1Click:Connect(function()
    ESP_DISTANCE = math.max(50, ESP_DISTANCE - 50)
    distLabel.Text = tostring(ESP_DISTANCE).." studs"
    status.Text = (ESP_ENABLED and "ESP: ON\n" or "ESP: OFF\n").. "Distance: "..tostring(ESP_DISTANCE)
end))
reg(incBtn.MouseButton1Click:Connect(function()
    ESP_DISTANCE = math.min(2000, ESP_DISTANCE + 50)
    distLabel.Text = tostring(ESP_DISTANCE).." studs"
    status.Text = (ESP_ENABLED and "ESP: ON\n" or "ESP: OFF\n").. "Distance: "..tostring(ESP_DISTANCE)
end))

-- Player/character events to create ESP when appropriate
reg(Players.PlayerAdded:Connect(function(pl)
    reg(pl.CharacterAdded:Connect(function()
        if ESP_ENABLED then task.wait(0.2); if pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (pl.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if dist <= ESP_DISTANCE then pcall(function() createESPForPlayer(pl) end)
            end
        end
    end))
end))

reg(Players.PlayerRemoving:Connect(function(pl) removeESPForPlayer(pl) end))

-- Heartbeat: culling & label updates (stamina read directly without auto-detection)
reg(RunService.Heartbeat:Connect(function()
    if not ESP_ENABLED then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local otherRoot = pl.Character:FindFirstChild("HumanoidRootPart") or pl.Character:FindFirstChild("Torso") or pl.Character:FindFirstChild("UpperTorso")
            if otherRoot then
                local dist = (otherRoot.Position - myRoot.Position).Magnitude
                if dist <= ESP_DISTANCE then
                    if not espFolders[pl] then pcall(function() createESPForPlayer(pl) end) end
                    local f = espFolders[pl]
                    if f and f.Parent then
                        local bg = f:FindFirstChild("GaraESP_Billboard")
                        if bg then
                            local frame = bg:FindFirstChildOfClass("Frame")
                            if frame then
                                local children = {}
                                for _,c in ipairs(frame:GetChildren()) do if c:IsA("TextLabel") then table.insert(children, c) end end
                                local nameL = children[1]; local hpL = children[2]; local stamL = children[3]
                                if nameL then nameL.Text = pl.Name end
                                local hum = pl.Character:FindFirstChildOfClass("Humanoid")
                                if hpL and hum then
                                    local hp = math.floor(hum.Health + 0.5)
                                    local mh = math.floor(hum.MaxHealth + 0.5)
                                    hpL.Text = "HP: "..tostring(hp).."/"..tostring(mh)
                                end
                                if stamL then
                                    local s = readStaminaValueForPlayer(pl)
                                    if type(s) == "number" then stamL.Text = "Stamina: "..tostring(math.floor(s+0.5)) else stamL.Text = "Stamina: -" end
                                end
                            end
                        end
                    end
                else
                    if espFolders[pl] then pcall(function() removeESPForPlayer(pl) end) end
                end
            end
        end
    end
end))

-- Unload function
_G.SIMPLE_GUI_DRAG_UNLOAD = function()
    pcall(function()
        for pl,_ in pairs(espFolders) do removeESPForPlayer(pl) end
        safeDestroy(SG)
    end)
    disconnectAll()
    _G.SIMPLE_GUI_DRAG_UNLOAD = nil
    print("[simple_draggable_gui] Unloaded (ESP cleaned)")
end

print("[simple_draggable_gui] Loaded. ESP will display stamina if found in character/humanoid.")
