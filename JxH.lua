local Sv = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    PathfindingService = game:GetService("PathfindingService"),
    CoreGui = game:GetService("CoreGui"),
    UserInputService = game:GetService("UserInputService")
}

local LP = Sv.Players.LocalPlayer
local AutoSH_Enabled = false

local PathData = {
    Path = nil,
    Waypoints = {},
    CurrentIndex = 1,
    TargetPos = nil,
    LastCompute = 0,
    LastPos = Vector3.new(),
    LastPosTime = 0,
    StuckCount = 0
}

local State = {
    IsHiding = false,
    LobbyTarget = nil,
    LastJump = 0,
    ActionDelay = 0,
    TargetLocker = nil
}

local LOBBY_COORDS = {
    Vector3.new(-52.5388, 264.6762, 10.4454),
    Vector3.new(-37.3878, 260.8593, -5.1795),
    Vector3.new(-25.2802, 260.8593, -20.4532),
    Vector3.new(-18.4071, 260.8593, -20.2298),
    Vector3.new(-18.1125, 261.1531, -2.1110),
    Vector3.new(-12.9700, 260.8593, 15.2693),
    Vector3.new(-11.7560, 269.0895, -4.7729),
    Vector3.new(7.0312, 260.8593, 7.0861),
    Vector3.new(13.1345, 260.8593, -12.2344),
    Vector3.new(37.4509, 260.8593, -0.8731)
}

local sg = Instance.new("ScreenGui")
sg.Name = "AutoSH_Test"
sg.ResetOnSpawn = false
pcall(function() sg.Parent = Sv.CoreGui end)
if not sg.Parent then pcall(function() sg.Parent = LP:WaitForChild("PlayerGui") end) end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 150, 0, 50)
frame.Position = UDim2.new(0.5, -75, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(13, 139, 255)
frame.Active = true
frame.Draggable = true
frame.Parent = sg

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, 0, 1, 0)
btn.BackgroundTransparency = 1
btn.Text = "Auto SH: OFF"
btn.TextColor3 = Color3.fromRGB(255, 69, 69)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.Parent = frame

local function getTeam(p)
    if not p or not p.Team then return "lobby" end
    local t = p.Team.Name:lower()
    if t:find("killer") then return "killer" end
    if t:find("survivor") or t:find("innocent") or t:find("hider") then return "survivor" end
    return "lobby"
end

local function isDowned(p)
    local c = p.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return false end
    local r = c:FindFirstChild("HumanoidRootPart")
    if not r then return false end
    local boh = r:FindFirstChild("BleedOutHealth")
    if boh and boh.Enabled then return true end
    local dv = c:FindFirstChild("Downed")
    if dv and ((dv:IsA("BoolValue") and dv.Value) or (dv:IsA("IntValue") and dv.Value > 0)) then return true end
    local inc = c:FindFirstChild("Incapacitated")
    if inc and ((inc:IsA("BoolValue") and inc.Value) or (inc:IsA("IntValue") and inc.Value > 0)) then return true end
    local s = h:GetState()
    if (s == Enum.HumanoidStateType.FallingDown or s == Enum.HumanoidStateType.Ragdoll) and h.WalkSpeed < 5 then return true end
    return false
end

local function getMap()
    for _, obj in ipairs(workspace:GetChildren()) do
        if (obj:IsA("Model") or obj:IsA("Folder")) and obj ~= LP.Character then
            local n = obj.Name:lower()
            if not n:find("lobby") and not n:find("spawn") and not Sv.Players:GetPlayerFromCharacter(obj) then
                if n:find("map") or obj:FindFirstChild("LootSpawns", true) or obj:FindFirstChild("Exits", true) then
                    return obj
                end
            end
        end
    end
    return nil
end

local function getClosest(list, pos)
    local closest = nil
    local minDist = math.huge
    for _, obj in ipairs(list) do
        local objPos = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetModelCFrame().Position) or obj.Position
        local d = (pos - objPos).Magnitude
        if d < minDist then
            minDist = d
            closest = obj
        end
    end
    return closest, minDist
end

local function interact(obj)
    if not obj then return end
    for _, c in ipairs(obj:GetDescendants()) do
        if c:IsA("ProximityPrompt") and c.Enabled then
            pcall(function() fireproximityprompt(c) end)
        elseif c:IsA("ClickDetector") then
            pcall(function() fireclickdetector(c, 0) end)
        end
    end
end

local function getOpenExits()
    local exits = {}
    local map = getMap()
    if not map then return exits end
    local f = map:FindFirstChild("Exits", true)
    if f then
        for _, exitObj in ipairs(f:GetChildren()) do
            local hasTrigger = false
            for _, desc in ipairs(exitObj:GetDescendants()) do
                if desc:IsA("TouchTransmitter") and desc.Parent and desc.Parent.Name == "Trigger" then
                    hasTrigger = true
                    break
                end
            end
            if hasTrigger then
                local bouncer = exitObj:FindFirstChild("Bouncer", true)
                if not bouncer or not bouncer:IsA("BasePart") or not bouncer.CanCollide then
                    local gatePart = exitObj:FindFirstChildWhichIsA("BasePart", true)
                    if gatePart then table.insert(exits, gatePart) end
                end
            end
        end
    end
    return exits
end

local function checkLineOfSight(startPos, endPos, ignoreList)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = ignoreList
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local dir = (endPos - startPos)
    local ray = workspace:Raycast(startPos, dir, rayParams)
    return ray == nil
end

local function smartMove(targetPos, isMovingTarget)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end

    local now = tick()
    local distToTarget = (root.Position - targetPos).Magnitude

    if distToTarget < 3 then
        hum:MoveTo(root.Position)
        PathData.Path = nil
        return true
    end

    if now - PathData.LastPosTime > 0.5 then
        if (root.Position - PathData.LastPos).Magnitude < 1 then
            PathData.StuckCount = PathData.StuckCount + 1
            if PathData.StuckCount > 2 then
                hum.Jump = true
                PathData.Path = nil
                PathData.StuckCount = 0
            end
        else
            PathData.StuckCount = 0
        end
        PathData.LastPos = root.Position
        PathData.LastPosTime = now
    end

    local hasLOS = checkLineOfSight(root.Position, targetPos, {char})
    if hasLOS and distToTarget < 40 then
        hum:MoveTo(targetPos)
        PathData.Path = nil
        return false
    end

    local needsRecompute = false
    if not PathData.Path then needsRecompute = true end
    if isMovingTarget and now - PathData.LastCompute > 1 then needsRecompute = true end
    if PathData.TargetPos and (PathData.TargetPos - targetPos).Magnitude > 6 then needsRecompute = true end

    if needsRecompute then
        PathData.TargetPos = targetPos
        PathData.LastCompute = now
        PathData.Path = Sv.PathfindingService:CreatePath({
            AgentRadius = 2.5,
            AgentHeight = 5,
            AgentCanJump = true,
            WaypointSpacing = 4
        })
        local s, e = pcall(function() PathData.Path:ComputeAsync(root.Position, targetPos) end)
        if s and PathData.Path.Status == Enum.PathStatus.Success then
            PathData.Waypoints = PathData.Path:GetWaypoints()
            PathData.CurrentIndex = 2
        else
            PathData.Path = nil
            hum:MoveTo(targetPos)
            if PathData.StuckCount > 0 then hum.Jump = true end
            return false
        end
    end

    if PathData.Path and PathData.Waypoints[PathData.CurrentIndex] then
        local wp = PathData.Waypoints[PathData.CurrentIndex]
        hum:MoveTo(wp.Position)
        if wp.Action == Enum.PathWaypointAction.Jump then
            hum.Jump = true
        end
        local wpPos2D = Vector3.new(wp.Position.X, 0, wp.Position.Z)
        local rootPos2D = Vector3.new(root.Position.X, 0, root.Position.Z)
        if (rootPos2D - wpPos2D).Magnitude < 3.5 then
            PathData.CurrentIndex = PathData.CurrentIndex + 1
        end
    end
    return false
end

local function logicLobby(root, hum)
    if not State.LobbyTarget then
        State.LobbyTarget = LOBBY_COORDS[math.random(1, #LOBBY_COORDS)]
    end
    
    local reached = smartMove(State.LobbyTarget, false)
    if reached then
        local now = tick()
        if now - State.LastJump > 15 then
            State.LastJump = now
            hum.Jump = true
            task.delay(0.4, function() if math.random() > 0.5 then hum.Jump = true end end)
        end
        if math.random() > 0.98 then
            State.LobbyTarget = LOBBY_COORDS[math.random(1, #LOBBY_COORDS)]
        end
    end
end

local function logicSurvivor(root, hum)
    local killer = nil
    local kDist = math.huge
    local downedSurv = {}
    local upSurvs = {}
    
    for _, p in ipairs(Sv.Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pr = p.Character.HumanoidRootPart
            local d = (root.Position - pr.Position).Magnitude
            local t = getTeam(p)
            if t == "killer" and d < kDist then
                kDist = d
                killer = pr
            elseif t == "survivor" then
                if isDowned(p) then
                    table.insert(downedSurv, pr)
                else
                    table.insert(upSurvs, pr)
                end
            end
        end
    end

    if State.IsHiding then
        if killer and kDist > 60 then
            State.IsHiding = false
            State.TargetLocker = nil
            hum.Jump = true
        else
            hum:MoveTo(root.Position)
            if State.TargetLocker then interact(State.TargetLocker) end
            return
        end
    end

    if killer and kDist < 45 then
        if kDist < 25 then
            local lockers = {}
            local map = getMap()
            local searchRoot = map or workspace
            for _, obj in ipairs(searchRoot:GetDescendants()) do
                if obj:IsA("Model") and obj ~= LP.Character then
                    local n = obj.Name:lower()
                    if n:find("locker") or n:find("wardrobe") or n:find("cabinet") or n:find("closet") then
                        table.insert(lockers, obj)
                    end
                end
            end
            local cl, cd = getClosest(lockers, root.Position)
            if cl and cd < 40 then
                local targetPos = cl:IsA("Model") and (cl.PrimaryPart and cl.PrimaryPart.Position or cl:GetModelCFrame().Position) or cl.Position
                smartMove(targetPos, false)
                if cd < 6 then
                    interact(cl)
                    State.IsHiding = true
                    State.TargetLocker = cl
                end
                return
            end
        end
        
        local dir = (root.Position - killer.Position).Unit
        local escapePos = root.Position + (dir * 40)
        smartMove(escapePos, false)
        return
    end

    local openExits = getOpenExits()
    if #openExits > 0 then
        local ce, cd = getClosest(openExits, root.Position)
        if ce then
            smartMove(ce.Position, false)
            if cd < 6 then interact(ce) end
            return
        end
    end

    if isDowned(LP) then
        local cs, cd = getClosest(upSurvs, root.Position)
        if cs then smartMove(cs.Position, true) end
        return
    end

    if #downedSurv > 0 then
        local cs, cd = getClosest(downedSurv, root.Position)
        if cs then
            smartMove(cs.Position, true)
            if cd < 5 then
                hum:MoveTo(root.Position)
                interact(cs.Parent)
            end
            return
        end
    end

    local loot = {}
    local map = getMap()
    local searchRoot = map or workspace
    local lf = searchRoot:FindFirstChild("LootSpawns", true)
    if lf then
        for _, obj in ipairs(lf:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Transparency < 0.9 then
                local p = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                local c = obj:FindFirstChildWhichIsA("ClickDetector", true)
                if p or c then table.insert(loot, obj) end
            end
        end
    end

    if #loot > 0 then
        local cl, cd = getClosest(loot, root.Position)
        if cl then
            smartMove(cl.Position, false)
            if cd < 6 then
                hum:MoveTo(root.Position)
                interact(cl)
            end
            return
        end
    end
end

local function logicKiller(root, hum)
    local targetSurv = nil
    local sDist = math.huge
    
    for _, p in ipairs(Sv.Players:GetPlayers()) do
        if p ~= LP and getTeam(p) == "survivor" and not isDowned(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pr = p.Character.HumanoidRootPart
            local d = (root.Position - pr.Position).Magnitude
            if d < sDist then
                sDist = d
                targetSurv = pr
            end
        end
    end

    local tool = LP.Character:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LP.Backpack:FindFirstChildOfClass("Tool")
        if bp then hum:EquipTool(bp) end
    end

    if targetSurv then
        smartMove(targetSurv.Position, true)
        if sDist < 10 and tool then
            tool:Activate()
        end
        return
    end

    local now = tick()
    if now - State.ActionDelay > 3 then
        State.ActionDelay = now
        local lockers = {}
        local map = getMap()
        local searchRoot = map or workspace
        for _, obj in ipairs(searchRoot:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LP.Character then
                local n = obj.Name:lower()
                if n:find("locker") or n:find("wardrobe") or n:find("cabinet") or n:find("closet") then
                    table.insert(lockers, obj)
                end
            end
        end
        if #lockers > 0 then
            local cl, cd = getClosest(lockers, root.Position)
            if cl then
                local targetPos = cl:IsA("Model") and (cl.PrimaryPart and cl.PrimaryPart.Position or cl:GetModelCFrame().Position) or cl.Position
                smartMove(targetPos, false)
                if cd < 7 then
                    interact(cl)
                    if tool then tool:Activate() end
                end
            end
        end
    end
end

btn.MouseButton1Click:Connect(function()
    AutoSH_Enabled = not AutoSH_Enabled
    if AutoSH_Enabled then
        btn.Text = "Auto SH: ON"
        btn.TextColor3 = Color3.fromRGB(46, 204, 113)
        frame.BorderColor3 = Color3.fromRGB(46, 204, 113)
        State.LobbyTarget = nil
        State.IsHiding = false
        State.TargetLocker = nil
        PathData.Path = nil
    else
        btn.Text = "Auto SH: OFF"
        btn.TextColor3 = Color3.fromRGB(255, 69, 69)
        frame.BorderColor3 = Color3.fromRGB(13, 139, 255)
        PathData.Path = nil
        local c = LP.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then h:MoveTo(c.HumanoidRootPart.Position) end
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        if AutoSH_Enabled then
            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if root and hum and hum.Health > 0 then
                local team = getTeam(LP)
                if team == "lobby" then
                    logicLobby(root, hum)
                elseif team == "survivor" then
                    logicSurvivor(root, hum)
                elseif team == "killer" then
                    logicKiller(root, hum)
                end
            end
        end
    end
end)
