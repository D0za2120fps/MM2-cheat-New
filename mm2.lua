я сделал чит как добавить его в запуск через одну строчку в инжекторе там на гитхаб загрузить для роблокса : -- MM2 ULTIMATE v33.3 | HIGHER POSITION
-- 🔥 Обводка | Имена (еще выше) | Дистанция (еще выше) | Auto Shoot (X) | INS

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- ⚙️ НАСТРОЙКИ
local Settings = {
    Name = {
        Enabled = true,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        Offset = -95, -- ЕЩЕ ВЫШЕ (было -75)
    },
    Distance = {
        Enabled = true,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Color = Color3.new(1, 1, 0.4),
        Offset = 55, -- ЕЩЕ ВЫШЕ (было 35)
    },
    Outline = {
        Enabled = true,
        Transparency = 0.15,
    },
    GunESP = {
        Enabled = true,
        Color = Color3.new(1, 0.8, 0),
        Transparency = 0.2,
    },
    Speed = {
        Enabled = false,
        Value = 50,
    },
    Fly = {
        Enabled = false,
        Speed = 50,
    },
    NoClip = {
        Enabled = false,
    },
    AutoShoot = {
        Enabled = true,
        Key = Enum.KeyCode.X,
    },
}

-- 📦 Хранилище
local espObjects = {}
local cacheRoles = {}
local menuOpen = false
local menuGui = nil
local tpCooldown = 0
local flyActive = false
local lastShootTime = 0

-- 🎨 ЦВЕТА РОЛЕЙ
local COLORS = {
    Murderer = Color3.new(1, 0.05, 0.05),
    Sheriff = Color3.new(0.05, 0.3, 0.9),
    Innocent = Color3.new(0.1, 1, 0.1),
}

-- ============================================
-- 🔍 ОПРЕДЕЛЕНИЕ РОЛИ
-- ============================================
local function getPlayerRole(player)
    if player == LocalPlayer then
        local char = LocalPlayer.Character
        if char then
            if char:FindFirstChild("Gun") then return "Sheriff" end
            if char:FindFirstChild("Knife") then return "Murderer" end
        end
        return "Innocent"
    end
    
    local now = tick()
    if cacheRoles[player] and now - cacheRoles[player].Time < 0.5 then
        return cacheRoles[player].Role
    end
    
    local character = player.Character
    if not character then
        cacheRoles[player] = {Role = "Innocent", Time = now}
        return "Innocent"
    end
    
    local hasKnife = character:FindFirstChild("Knife") ~= nil
    local hasGun = character:FindFirstChild("Gun") ~= nil
    
    if not hasKnife and not hasGun then
        local backpack = player.Backpack
        if backpack then
            for _, item in pairs(backpack:GetChildren()) do
                if item:IsA("Tool") then
                    if item.Name == "Knife" then hasKnife = true end
                    if item.Name == "Gun" then hasGun = true end
                end
                if hasKnife and hasGun then break end
            end
        end
    end
    
    local role = "Innocent"
    if hasKnife and not hasGun then
        role = "Murderer"
    elseif hasGun and not hasKnife then
        role = "Sheriff"
    end
    
    cacheRoles[player] = {Role = role, Time = now}
    return role
end

-- ============================================
-- 🔫 AUTO SHOOT (РЕАЛЬНО СТРЕЛЯЕТ)
-- ============================================
local function getMurderer()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local role = getPlayerRole(player)
        if role == "Murderer" then
            local character = player.Character
            if character and character:FindFirstChild("Head") then
                return player
            end
        end
    end
    return nil
end

local function shootMurderer()
    if not Settings.AutoShoot.Enabled then return end
    
    local myRole = getPlayerRole(LocalPlayer)
    if myRole ~= "Sheriff" then
        print("⚠️ Ты не Шериф!")
        return
    end
    
    local murderer = getMurderer()
    if not murderer then
        print("❌ Убийца не найден!")
        return
    end
    
    local character = murderer.Character
    if not character then return end
    
    local head = character:FindFirstChild("Head")
    if not head then return end
    
    local now = tick()
    if now - lastShootTime < 0.3 then return end
    lastShootTime = now
    
    local targetPos = head.Position
    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
    
    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then return end
    
    local mouse = LocalPlayer:GetMouse()
    if mouse then
        mouse.Move(Vector2.new(headPos.X, headPos.Y))
        wait(0.05)
        
        mouse:Button1Down(Vector2.new(headPos.X, headPos.Y))
        wait(0.05)
        mouse:Button1Up(Vector2.new(headPos.X, headPos.Y))
        
        pcall(function()
            mouse1click()
        end)
        
        pcall(function()
            local VirtualUser = game:GetService("VirtualUser")
            if VirtualUser then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(headPos.X, headPos.Y))
            end
        end)
        
        print("🔫 Выстрел по убийце!")
    end
end

-- ============================================
-- 🚀 ФУНКЦИИ
-- ============================================

local function updateSpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = Settings.Speed.Enabled and Settings.Speed.Value or 16
    end
end

local function updateFly()
    local char = LocalPlayer.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if Settings.Fly.Enabled then
        rootPart.Velocity = Vector3.new(0, 0, 0)
        flyActive = true
    else
        flyActive = false
        rootPart.Velocity = Vector3.new(0, 0, 0)
    end
end

local function updateNoClip()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = not Settings.NoClip.Enabled
        end
    end
end

local function findGuns()
    local guns = {}
    for _, child in pairs(workspace:GetChildren()) do
        if child:IsA("Tool") and child.Name == "Gun" then
            table.insert(guns, child)
        end
        if child:IsA("Folder") and child.Name == "Guns" then
            for _, gun in pairs(child:GetChildren()) do
                if gun:IsA("Tool") and gun.Name == "Gun" then
                    table.insert(guns, gun)
                end
            end
        end
    end
    return guns
end

local function teleportToGun()
    local now = tick()
    if now - tpCooldown < 1 then return end
    tpCooldown = now
    
    local guns = findGuns()
    if #guns == 0 then
        print("❌ Пистолетов на карте нет!")
        return
    end
    
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    
    local closest = nil
    local closestDist = math.huge
    
    for _, gun in pairs(guns) do
        if gun and gun:IsA("BasePart") then
            local dist = (gun.Position - char.PrimaryPart.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = gun
            end
        end
    end
    
    if closest then
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local targetPos = closest.Position + Vector3.new(0, 2, 0)
            rootPart.CFrame = CFrame.new(targetPos)
            print("✅ Телепорт к пистолету! (" .. string.format("%.0f", closestDist) .. "м)")
        end
    end
end

-- ============================================
-- 🎨 ОБВОДКИ
-- ============================================
local function updateGunESP(gun)
    if not Settings.GunESP.Enabled then return end
    if not gun or not gun.Parent then return end
    
    local isOnGround = gun.Parent == workspace or (gun.Parent and gun.Parent.Name == "Guns")
    if not isOnGround then return end
    
    local highlight = gun:FindFirstChild("GunHighlight")
    if highlight and highlight:IsA("Highlight") then
        highlight.OutlineColor = Settings.GunESP.Color
        highlight.OutlineTransparency = Settings.GunESP.Transparency
        highlight.Enabled = true
    else
        local newHighlight = Instance.new("Highlight")
        newHighlight.Name = "GunHighlight"
        newHighlight.Parent = gun
        newHighlight.Adornee = gun
        newHighlight.FillTransparency = 1
        newHighlight.OutlineTransparency = Settings.GunESP.Transparency
        newHighlight.OutlineColor = Settings.GunESP.Color
        newHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        newHighlight.Enabled = true
    end
end

local function removeGunESP(gun)
    if gun then
        local highlight = gun:FindFirstChild("GunHighlight")
        if highlight then highlight:Destroy() end
    end
end

local function updateOutline(player)
    if not Settings.Outline.Enabled then
        removeOutline(player)
        return
    end
    
    local character = player.Character
    if not character then return end
    
    local role = getPlayerRole(player)
    local color = COLORS[role] or COLORS.Innocent
    
    local highlight = character:FindFirstChild("BodyOutline")
    if highlight and highlight:IsA("Highlight") then
        highlight.OutlineColor = color
        highlight.OutlineTransparency = Settings.Outline.Transparency
        highlight.Enabled = true
    else
        local newHighlight = Instance.new("Highlight")
        newHighlight.Name = "BodyOutline"
        newHighlight.Parent = character
        newHighlight.Adornee = character
        newHighlight.FillTransparency = 1
        newHighlight.OutlineTransparency = Settings.Outline.Transparency
        newHighlight.OutlineColor = color
        newHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        newHighlight.Enabled = true
    end
end

local function removeOutline(player)
    local character = player.Character
    if not character then return end
    local highlight = character:FindFirstChild("BodyOutline")
    if highlight then highlight:Destroy() end
end

-- ============================================
-- 🖥️ МЕНЮ
-- ============================================
local function createMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "MM2Ultimate"
    gui.ResetOnSpawn = false
    gui.Parent = game.CoreGui
    gui.Enabled = true
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.new(0.3, 0.6, 1)
    mainFrame.Size = UDim2.new(0, 340, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -170, 0.5, -260)
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = gui
    
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.BackgroundColor3 = Color3.new(0.15, 0.3, 0.6)
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.Parent = mainFrame
    
    local titleText = Instance.new("TextLabel")
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎯 MM2 ULTIMATE v33.3"
    titleText.TextColor3 = Color3.new(1, 1, 1)
    titleText.TextSize = 17
    titleText.Font = Enum.Font.GothamBold
    titleText.Size = UDim2.new(1, -35, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.new(1, 0.3, 0.3)
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Size = UDim2.new(0, 35, 1, 0)
    closeBtn.Position = UDim2.new(1, -35, 0, 0)
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        menuOpen = false
        gui.Enabled = false
    end)
    
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, -10, 1, -45)
    content.Position = UDim2.new(0, 5, 0, 40)
    content.CanvasSize = UDim2.new(0, 0, 0, 600)
    content.ScrollBarThickness = 3
    content.Parent = mainFrame
    
    local function createSection(parent, title, yPos)
        local section = Instance.new("TextLabel")
        section.BackgroundTransparency = 1
        section.Text = "━━━ " .. title .. " ━━━"
        section.TextColor3 = Color3.new(0.4, 0.7, 1)
        section.TextSize = 12
        section.Font = Enum.Font.GothamBold
        section.Size = UDim2.new(1, 0, 0, 22)
        section.Position = UDim2.new(0, 0, 0, yPos)
        section.Parent = parent
        return section
    end
    
    local function createOption(parent, label, desc, yPos, callback)
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = Color3.new(0.08, 0.08, 0.15)
        btn.BorderSizePixel = 1
        btn.BorderColor3 = Color3.new(0.15, 0.15, 0.25)
        btn.Text = ""
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.Position = UDim2.new(0, 0, 0, yPos)
        btn.Parent = parent
        
        local labelText = Instance.new("TextLabel")
        labelText.BackgroundTransparency = 1
        labelText.Text = label
        labelText.TextColor3 = Color3.new(1, 1, 1)
        labelText.TextSize = 13
        labelText.Font = Enum.Font.Gotham
        labelText.Size = UDim2.new(0.5, 0, 0, 18)
        labelText.Position = UDim2.new(0, 10, 0, 2)
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.Parent = btn
        
        local descText = Instance.new("TextLabel")
        descText.BackgroundTransparency = 1
        descText.Text = desc or ""
        descText.TextColor3 = Color3.new(0.4, 0.4, 0.5)
        descText.TextSize = 10
        descText.Font = Enum.Font.Gotham
        descText.Size = UDim2.new(0.5, 0, 0, 14)
        descText.Position = UDim2.new(0, 10, 0, 20)
        descText.TextXAlignment = Enum.TextXAlignment.Left
        descText.Parent = btn
        
        local status = Instance.new("TextLabel")
        status.BackgroundTransparency = 1
        status.Text = "OFF"
        status.TextColor3 = Color3.new(0.4, 0.4, 0.4)
        status.TextSize = 12
        status.Font = Enum.Font.GothamBold
        status.Size = UDim2.new(0, 55, 1, 0)
        status.Position = UDim2.new(1, -65, 0, 0)
        status.Parent = btn
        
        local state = false
        
        btn.MouseButton1Click:Connect(function()
            state = not state
            status.Text = state and "ON" or "OFF"
            status.TextColor3 = state and Color3.new(0.3, 0.9, 1) or Color3.new(0.4, 0.4, 0.4)
            btn.BackgroundColor3 = state and Color3.new(0.12, 0.2, 0.3) or Color3.new(0.08, 0.08, 0.15)
            btn.BorderColor3 = state and Color3.new(0.3, 0.6, 1) or Color3.new(0.15, 0.15, 0.25)
            if callback then callback(state) end
        end)
        
        return {
            SetState = function(val)
                state = val
                status.Text = state and "ON" or "OFF"
                status.TextColor3 = state and Color3.new(0.3, 0.9, 1) or Color3.new(0.4, 0.4, 0.4)
                btn.BackgroundColor3 = state and Color3.new(0.12, 0.2, 0.3) or Color3.new(0.08, 0.08, 0.15)
                btn.BorderColor3 = state and Color3.new(0.3, 0.6, 1) or Color3.new(0.15, 0.15, 0.25)
                if callback then callback(state) end
            end,
        }
    end
    
    local function createButton(parent, label, desc, yPos, callback)
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = Color3.new(0.15, 0.25, 0.4)
        btn.BorderSizePixel = 1
        btn.BorderColor3 = Color3.new(0.3, 0.5, 0.8)
        btn.Text = ""
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.Position = UDim2.new(0, 0, 0, yPos)
        btn.Parent = parent
        
        local labelText = Instance.new("TextLabel")
        labelText.BackgroundTransparency = 1
        labelText.Text = label
        labelText.TextColor3 = Color3.new(1, 1, 1)
        labelText.TextSize = 13
        labelText.Font = Enum.Font.GothamBold
        labelText.Size = UDim2.new(0.6, 0, 1, 0)
        labelText.Position = UDim2.new(0, 10, 0, 0)
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.Parent = btn
        
        local descText = Instance.new("TextLabel")
        descText.BackgroundTransparency = 1
        descText.Text = desc or ""
        descText.TextColor3 = Color3.new(0.5, 0.6, 0.8)
        descText.TextSize = 10
        descText.Font = Enum.Font.Gotham
        descText.Size = UDim2.new(0.6, 0, 0, 14)
        descText.Position = UDim2.new(0, 10, 0, 22)
        descText.TextXAlignment = Enum.TextXAlignment.Left
        descText.Parent = btn
        
        local arrow = Instance.new("TextLabel")
        arrow.BackgroundTransparency = 1
        arrow.Text = "▶"
        arrow.TextColor3 = Color3.new(0.3, 0.8, 1)
        arrow.TextSize = 16
        arrow.Font = Enum.Font.Gotham
        arrow.Size = UDim2.new(0, 30, 1, 0)
        arrow.Position = UDim2.new(1, -40, 0, 0)
        arrow.Parent = btn
        
        btn.MouseButton1Click:Connect(callback)
        
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.new(0.2, 0.35, 0.5)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.new(0.15, 0.25, 0.4)
        end)
        
        return btn
    end
    
    local y = 5
    
    local sec1 = createSection(content, "👤 ИМЕНА", y)
    y = y + 26
    
    local opt1 = createOption(content, "Имена", "Показать имена игроков", y, function(val) 
        Settings.Name.Enabled = val
        for player, data in pairs(espObjects) do
            if data and data.Name then
                data.Name.Visible = val
            end
        end
    end)
    opt1:SetState(true)
    y = y + 42
    
    local sec2 = createSection(content, "📏 ДИСТАНЦИЯ", y)
    y = y + 26
    
    local opt2 = createOption(content, "Дистанция", "Показать расстояние", y, function(val) 
        Settings.Distance.Enabled = val
        for player, data in pairs(espObjects) do
            if data and data.Distance then
                data.Distance.Visible = val
            end
        end
    end)
    opt2:SetState(true)
    y = y + 42
    
    local sec3 = createSection(content, "🎨 ОБВОДКА", y)
    y = y + 26
    
    local opt3 = createOption(content, "Обводка тела", "Контур вокруг скина", y, function(val) 
        Settings.Outline.Enabled = val
        if val then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    updateOutline(player)
                end
            end
        else
            for _, player in pairs(Players:GetPlayers()) do
                removeOutline(player)
            end
        end
    end)
    opt3:SetState(true)
    y = y + 42
    
    local sec4 = createSection(content, "🔫 ПИСТОЛЕТ", y)
    y = y + 26
    
    local opt4 = createOption(content, "Обводка пистолета", "Золотой контур", y, function(val) 
        Settings.GunESP.Enabled = val
        if not val then
            for _, gun in pairs(findGuns()) do
                removeGunESP(gun)
            end
        end
    end)
    opt4:SetState(true)
    y = y + 42
    
    local btn1 = createButton(content, "📍 Телепорт к пистолету", "ТП к ближайшему", y, function()
        teleportToGun()
    end)
    y = y + 42
    
    local sec5 = createSection(content, "🚀 ФУНКЦИИ", y)
    y = y + 26
    
    local opt5 = createOption(content, "Speed Hack", "Ускорение бега", y, function(val) 
        Settings.Speed.Enabled = val
        updateSpeed()
    end)
    y = y + 42
    
    local opt6 = createOption(content, "Fly (Полёт)", "Летать [WASD + Space]", y, function(val) 
        Settings.Fly.Enabled = val
        updateFly()
    end)
    y = y + 42
    
    local opt7 = createOption(content, "NoClip", "Проход сквозь стены", y, function(val) 
        Settings.NoClip.Enabled = val
        updateNoClip()
    end)
    y = y + 42
    
    local sec6 = createSection(content, "🔫 AUTO SHOOT (X)", y)
    y = y + 26
    
    local opt8 = createOption(content, "Auto Shoot", "Стрелять по X в убийцу", y, function(val) 
        Settings.AutoShoot.Enabled = val
        print(val and "🔫 Auto Shoot включен (X)" or "🔫 Auto Shoot выключен")
    end)
    opt8:SetState(true)
    y = y + 42
    
    local info = Instance.new("TextLabel")
    info.BackgroundTransparency = 1
    info.Text = "📌 INSERT - меню | X - выстрел в убийцу"
    info.TextColor3 = Color3.new(0.3, 0.3, 0.4)
    info.TextSize = 11
    info.Font = Enum.Font.Gotham
    info.Size = UDim2.new(1, 0, 0, 25)
    info.Position = UDim2.new(0, 0, 0, y + 5)
    info.Parent = content
    
    content.CanvasSize = UDim2.new(0, 0, 0, y + 35)
    
    local drag = {active = false, offset = Vector2.new()}
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag.active = true
            drag.offset = Vector2.new(input.Position.X - mainFrame.AbsolutePosition.X,
                                      input.Position.Y - mainFrame.AbsolutePosition.Y)
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag.active = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if drag.active and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = input.Position - drag.offset
            mainFrame.Position = UDim2.new(0, pos.X, 0, pos.Y)
        end
    end)
    
    return gui
end

-- ============================================
-- 🎮 УПРАВЛЕНИЕ
-- ============================================
menuGui = createMenu()
menuOpen = true

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        menuOpen = not menuOpen
        if menuGui then
            menuGui.Enabled = menuOpen
        end
    end
    
    if input.KeyCode == Settings.AutoShoot.Key and Settings.AutoShoot.Enabled then
        shootMurderer()
    end
    
    if Settings.Fly.Enabled and flyActive then
        local char = LocalPlayer.Character
        if char then
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local speed = Settings.Fly.Speed
                local move = Vector3.new(0, 0, 0)
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    move = move + Camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    move = move - Camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    move = move - Camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    move = move + Camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    move = move + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    move = move - Vector3.new(0, 1, 0)
                end
                
                if move.Magnitude > 0 then
                    move = move.Unit * speed
                end
                
                rootPart.Velocity = move
                rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + move.Unit)
            end
        end
    end
end)

-- ============================================
-- 🖥️ СОЗДАНИЕ GUI ДЛЯ ИМЁН И ДИСТАНЦИИ
-- ============================================
local function createESP(player)
    if player == LocalPlayer or espObjects[player] then return end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "ESP_" .. player.Name
    gui.ResetOnSpawn = false
    gui.Parent = game.CoreGui
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextScaled = false
    nameLabel.TextSize = Settings.Name.TextSize
    nameLabel.Font = Settings.Name.Font
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Size = UDim2.new(0, 250, 0, 28)
    nameLabel.Position = UDim2.new(0.5, -125, 0.5, -14)
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Visible = Settings.Name.Enabled
    nameLabel.Parent = gui
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "Distance"
    distLabel.BackgroundTransparency = 1
    distLabel.Text = ""
    distLabel.TextColor3 = Settings.Distance.Color
    distLabel.TextSize = Settings.Distance.TextSize
    distLabel.Font = Settings.Distance.Font
    distLabel.Size = UDim2.new(0, 140, 0, 22)
    distLabel.Position = UDim2.new(0.5, -70, 0, 0)
    distLabel.TextStrokeTransparency = 0.2
    distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distLabel.Visible = Settings.Distance.Enabled
    distLabel.Parent = gui
    
    espObjects[player] = {
        Gui = gui,
        Name = nameLabel,
        Distance = distLabel,
    }
end

local function removeESP(player)
    if espObjects[player] then
        espObjects[player].Gui:Destroy()
        espObjects[player] = nil
    end
end

-- ============================================
-- ⚡ ГЛАВНЫЙ ЦИКЛ (ПОДНЯТО ЕЩЕ ВЫШЕ)
-- ============================================
RunService.RenderStepped:Connect(function()
    if Settings.Speed.Enabled then updateSpeed() end
    if Settings.NoClip.Enabled then updateNoClip() end
    if Settings.Fly.Enabled then updateFly() end
    
    if Settings.GunESP.Enabled then
        local guns = findGuns()
        for _, gun in pairs(guns) do
            updateGunESP(gun)
        end
    end
    
    local localChar = LocalPlayer.Character
    if not localChar or not localChar.PrimaryPart then return end
    
    local origin = localChar.PrimaryPart.Position
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local character = player.Character
        if not character then
            removeESP(player)
            removeOutline(player)
            continue
        end
        
        if Settings.Outline.Enabled then
            updateOutline(player)
        else
            removeOutline(player)
        end
        
        local head = character:FindFirstChild("Head")
        local root = character:FindFirstChild("HumanoidRootPart")
        
        if not head or not root then
            removeESP(player)
            continue
        end
        
        local distance = (root.Position - origin).Magnitude
        if distance > 300 then
            removeESP(player)
            continue
        end
        
        if not espObjects[player] then
            createESP(player)
        end
        
        local data = espObjects[player]
        if not data then continue end
        
        -- Поднял offset для головы еще выше (было 0.8, стало 1.5)
        local headPos, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
        local rootPos, rootOn = Camera:WorldToViewportPoint(root.Position)
        
        if not headOn or not rootOn then
            data.Gui.Enabled = false
            continue
        end
        
        data.Gui.Enabled = true
        
        local role = getPlayerRole(player)
        local color = COLORS[role] or COLORS.Innocent
        local emoji = role == "Murderer" and "🔪 " or role == "Sheriff" and "⭐ " or "👤 "
        
        -- Имя выше (смещение -95 вместо -75)
        data.Name.TextColor3 = color
        data.Name.Text = emoji .. player.Name
        data.Name.Position = UDim2.new(0, headPos.X - 125, 0, headPos.Y - 95)
        data.Name.Visible = Settings.Name.Enabled
        
        -- Дистанция выше (смещение +55 вместо +35)
        data.Distance.Text = string.format("📏 %.0fm", distance)
        data.Distance.Position = UDim2.new(0, headPos.X - 70, 0, rootPos.Y + 55)
        data.Distance.Visible = Settings.Distance.Enabled
    end
    
    for player, data in pairs(espObjects) do
        if not player.Parent or not player.Character then
            removeESP(player)
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(0.5)
        if Settings.Outline.Enabled then
            updateOutline(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    removeOutline(player)
end)

-- ============================================
-- 📋 ИНФО
-- ============================================
print("✅ MM2 ULTIMATE v33.3 загружен!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🔹 INSERT - меню")
print("🔹 X - выстрел в убийцу (реально стреляет!)")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🔥 ФУНКЦИИ:")
print("   • 👤 Имена (ЕЩЕ ВЫШЕ!)")
print("   • 📏 Дистанция (ЕЩЕ ВЫШЕ!)")
print("   • 🎨 Обводка тела")
print("   • 🔫 Обводка пистолета")
print("   • 📍 Телепорт к пистолету")
print("   • 🏃 Speed Hack")
print("   • ✈️ Fly")
print("   • 🧱 NoClip")
print("   • 🔫 Auto Shoot по X (работает!)")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")