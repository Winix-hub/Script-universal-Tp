--[[
    Steal Mini GUI Script
    By Winix
]]

-- Переменные
local SpawnLocation = nil
local SpawnSaved = false
local IsTeleporting = false
local MiniGUI = nil

-- Функция для создания уведомления через Roblox (стандартные)
local function RobloxNotify(title, content, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = content,
        Duration = duration or 3,
        Icon = "rbxassetid://4483362458"
    })
end

-- Функция для симуляции реального удара (как от другого игрока)
local function SimulateRealHit(character)
    local humanoid = character:FindFirstChild("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not humanoidRootPart then 
        return false
    end
    
    -- 1. Сначала наносим реальный удар (TakeDamage)
    humanoid:TakeDamage(0.1) -- Минимальный урон, но достаточный для реакции
    
    -- 2. Заставляем упасть (FallingDown состояние)
    humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
    
    -- 3. Отключаем контроль игрока на время падения
    humanoid.PlatformStand = true
    
    -- 4. Добавляем эффект отбрасывания (реальный удар)
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(
        math.random(-30, 30),  -- Сильный горизонтальный удар
        25,                     -- Сильный подброс вверх
        math.random(-30, 30)
    )
    bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
    bodyVelocity.P = 1250
    bodyVelocity.Parent = humanoidRootPart
    
    -- 5. Добавляем сильное вращение (эффект удара)
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.AngularVelocity = Vector3.new(
        math.random(-25, 25),
        math.random(-25, 25),
        math.random(-25, 25)
    )
    bodyAngularVelocity.MaxTorque = Vector3.new(10000, 10000, 10000)
    bodyAngularVelocity.Parent = humanoidRootPart
    
    -- 6. Добавляем силу тяжести чтобы падал вниз после подброса
    wait(0.2)
    
    local gravityVelocity = Instance.new("BodyVelocity")
    gravityVelocity.Velocity = Vector3.new(0, -50, 0)  -- Сила тяжести вниз
    gravityVelocity.MaxForce = Vector3.new(0, 10000, 0)
    gravityVelocity.Parent = humanoidRootPart
    
    return bodyVelocity, bodyAngularVelocity, gravityVelocity
end

-- Функция для создания Mini GUI (МАЛЕНЬКАЯ И КОМПАКТНАЯ)
local function CreateMiniGUI()
    if MiniGUI then
        MiniGUI:Destroy()
        MiniGUI = nil
    end
    
    -- Создаем ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StealMiniGUI"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Создаем основное окно (КОМПАКТНОЕ)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 160, 0, 180)
    mainFrame.Position = UDim2.new(0.9, -170, 0.1, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    -- Добавляем закругленные углы
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Добавляем легкую тень
    local shadow = Instance.new("UIStroke")
    shadow.Color = Color3.fromRGB(20, 20, 20)
    shadow.Thickness = 1
    shadow.Transparency = 0.3
    shadow.Parent = mainFrame
    
    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    title.BackgroundTransparency = 0.5
    title.Text = "Steal Menu"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = mainFrame
    
    -- Закругление для заголовка
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Контейнер для кнопок
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, -10, 1, -40)
    buttonContainer.Position = UDim2.new(0, 4, 0, 20)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = mainFrame
    
    -- Создаем кнопки (КОМПАКТНЫЕ)
    local buttons = {
        {
            name = "Save Pos",
            color = Color3.fromRGB(52, 152, 219),
            position = UDim2.new(0, 0, 0, 0),
            callback = function()
                local player = game.Players.LocalPlayer
                if player and player.Character then
                    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        SpawnLocation = humanoidRootPart.CFrame
                        SpawnSaved = true
                        RobloxNotify("Position Saved", "Position saved successfully!", 3)
                    end
                end
            end
        },
        {
            name = "Tween Steal",
            color = Color3.fromRGB(46, 204, 113),
            position = UDim2.new(0, 0, 0, 40),
            callback = function()
                if not SpawnSaved then
                    RobloxNotify("Error", "Save position first!", 3)
                    return
                end
                
                if IsTeleporting then return end
                
                local player = game.Players.LocalPlayer
                if not player or not player.Character then return end
                
                local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if not humanoidRootPart then return end
                
                IsTeleporting = true
                
                local TweenService = game:GetService("TweenService")
                local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Linear)
                local tween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = SpawnLocation})
                tween:Play()
                
                tween.Completed:Wait()
                IsTeleporting = false
                
                RobloxNotify("Success", "Tween Steal complete!", 3)
            end
        },
        {
            name = "Steal TP",
            color = Color3.fromRGB(231, 76, 60),
            position = UDim2.new(0, 0, 0, 80),
            callback = function()
                if not SpawnSaved then
                    RobloxNotify("Error", "Save position first!", 3)
                    return
                end
                
                if IsTeleporting then return end
                
                local player = game.Players.LocalPlayer
                if not player or not player.Character then return end
                
                local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if not humanoidRootPart then return end
                
                IsTeleporting = true
                
                humanoidRootPart.CFrame = CFrame.new(0, 10000, 0)
                wait(0.1)
                humanoidRootPart.CFrame = SpawnLocation
                
                IsTeleporting = false
                
                RobloxNotify("Success", "TP Steal complete!", 3)
            end
        },
        {
            name = "Hit TP",
            color = Color3.fromRGB(155, 89, 182),
            position = UDim2.new(0, 0, 0, 120),
            callback = function()
                if not SpawnSaved then
                    RobloxNotify("Error", "Save position first!", 3)
                    return
                end
                
                if IsTeleporting then return end
                
                local player = game.Players.LocalPlayer
                if not player or not player.Character then return end
                
                local humanoid = player.Character:FindFirstChild("Humanoid")
                local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                
                if not humanoid or not humanoidRootPart then return end
                
                IsTeleporting = true
                
                -- Симулируем реальный удар
                local bodyVelocity, bodyAngularVelocity, gravityVelocity = SimulateRealHit(player.Character)
                
                if not bodyVelocity then
                    IsTeleporting = false
                    return
                end
                
                -- Ждем эффекта падения (1 секунда)
                wait(1)
                
                -- Убираем все физические эффекты
                if bodyVelocity then bodyVelocity:Destroy() end
                if bodyAngularVelocity then bodyAngularVelocity:Destroy() end
                if gravityVelocity then gravityVelocity:Destroy() end
                
                -- Телепортируем в сохраненную точку
                humanoidRootPart.CFrame = SpawnLocation
                
                -- Восстанавливаем состояние игрока
                wait(0.1)
                humanoid.PlatformStand = false
                
                -- Даем встать
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                wait(0.3)
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                
                IsTeleporting = false
                
                -- ТОЛЬКО ОДНО УВЕДОМЛЕНИЕ ОБ УСПЕХЕ
                RobloxNotify("Success", "Hit TP complete!", 3)
            end
        }
    }
    
    -- Создаем кнопки
    for _, buttonData in ipairs(buttons) do
        local button = Instance.new("TextButton")
        button.Name = buttonData.name .. "Button"
        button.Size = UDim2.new(1, 0, 0, 35)
        button.Position = buttonData.position
        button.BackgroundColor3 = buttonData.color
        button.Text = buttonData.name
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 12
        button.AutoButtonColor = true
        
        -- Закругление кнопки
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        -- Эффект при наведении
        button.MouseEnter:Connect(function()
            button.BackgroundTransparency = 0.2
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundTransparency = 0
        end)
        
        -- Обработчик клика
        button.MouseButton1Click:Connect(buttonData.callback)
        
        button.Parent = buttonContainer
    end
    
    -- Делаем окно перетаскиваемым
    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragInput, mousePos, framePos
    
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            mainFrame.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)
    
    mainFrame.Parent = screenGui
    MiniGUI = screenGui
    
    RobloxNotify("Steal Menu", "Steal GUI loaded! Drag to move.", 3)
end

-- Инициализация
wait(1)
CreateMiniGUI()

print("Steal Menu loaded successfully!")
