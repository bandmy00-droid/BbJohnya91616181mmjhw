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
    TargetLocker = nil,
    MapWanderTarget = nil,
    CurrentTeam = "",
    LastAttack = 0
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

local function getTeam(player)
    if player == LP then
        local team = LP.Team
        if not team then return "lobby" end
        local t = team.Name:lower()
        if t:find("survivor") or t:find("innocent") or t:find("hider") then return "survivor" end
        if t:find("killer") then return "killer" end
        return "lobby"
    end
    local team = player.Team
    if not team then return "lobby" end
    local t = team.Name:lower()
    if t:find("killer") then return "killer" end
    if t:find("survivor") or t:find("innocent") or t:find("hider") then return "survivor" end
    return "lobby"
end

local function isKiller(player)
    if player == LP then return false end
    local team = player.Team
    if not team then return false end
    local t = team.Name:lower()
    if t == "killer" or t:find("^killer") then return true end
    if t:find("survivor") or t:find("innocent") or t:find("lobby") or t:find("hider") then return false end
    local myTeam = LP.Team
    if myTeam then
        local mt = myTeam.Name:lower()
        if mt:find("survivor") or mt:find("innocent") or mt:find("hider") then return team ~= myTeam end
    end
    return false
end

local function isPlayerDowned(player)
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or (hum.Health <= 0 and hum.MaxHealth > 0) then return false end
    if char:FindFirstChildOfClass("ForceField") then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local boh = root:FindFirstChild("BleedOutHealth")
    if boh and boh.Enabled then return true end
    local dv = char:FindFirstChild("Downed")
    if dv and ((dv:IsA("BoolValue") and dv.Value) or (dv:IsA("IntValue") and dv.Value > 0)) then return true end
    local inc = char:FindFirstChild("Incapacitated")
    if inc and ((inc:IsA("BoolValue") and inc.Value) or (inc:IsA("IntValue") and inc.Value > 0)) then return true end
    local state = hum:GetState()
    if (state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll) and hum.WalkSpeed < 5 then return true end
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
    local pos2D = Vector3.new(pos.X, 0, pos.Z)
    for _, obj in ipairs(list) do
        local objPos = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetModelCFrame().Position) or obj.Position
        local objPos2D = Vector3.new(objPos.X, 0, objPos.Z)
        local d = (pos2D - objPos2D).Magnitude
        if d < minDist then
            minDist = d
            closest = obj
        end
    end
    return closest, minDist
end

local lootValueCache = setmetatable({}, {__mode="k"})
local function getLootValue(obj)
    if lootValueCache[obj] ~= nil then return lootValueCache[obj] end
    local function cache(v)
        if v == 20 then v = nil end
        lootValueCache[obj] = v
        return v
    end
    local attr = obj:GetAttribute("Value") or obj:GetAttribute("Amount")
    if attr then
        local val = tonumber(attr)
        if val then return cache(val) end
    end
    local fallback = nil
    for _, c in ipairs(obj:GetDescendants()) do
        if c:IsA("ProximityPrompt") then
            local at = c:GetAttribute("ActionText")
            if at and type(at) == "string" then
                local n = at:match("%+(%d+)")
                if n then fallback = tonumber(n) break end
            end
            local txt = c.ActionText .. " " .. c.ObjectText
            local n = txt:match("%+(%d+)") or txt:match("(%d+)%s*[Cc]oin") or txt:match("(%d+)%s*[Gg]old")
            if n then fallback = tonumber(n) break end
        elseif c:IsA("ClickDetector") then
            local at = c:GetAttribute("ActionText")
            if at and type(at) == "string" then
                local n = at:match("%+(%d+)")
                if n then fallback = tonumber(n) break end
            end
        elseif c:IsA("TextLabel") or c:IsA("TextButton") then
            local n = c.Text:match("%+(%d+)")
            if n then fallback = tonumber(n) break end
        elseif (c:IsA("IntValue") or c:IsA("NumberValue")) and not fallback then
            fallback = c.Value
        elseif c:IsA("StringValue") and not fallback then
            local n = tonumber(c.Value)
            if n then fallback = n end
        end
    end
    if fallback then return cache(fallback) end
    local map = getMap()
    local lootFolder = map and map:FindFirstChild("LootSpawns", true) or workspace:FindFirstChild("LootSpawns", true)
    if lootFolder and obj:IsDescendantOf(lootFolder) then
        return cache(1)
    end
    return cache(nil)
end

local function getSafeLoot(killerPos)
    local lootList = {}
    local map = getMap()
    local lf = map and map:FindFirstChild("LootSpawns", true) or workspace:FindFirstChild("LootSpawns", true)
    if lf then
        for _, obj in ipairs(lf:GetDescendants()) do
            if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
                local parent = obj.Parent
                local target = nil
                if parent:IsA("BasePart") then
                    target = parent
                elseif parent:IsA("Model") then
                    target = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true)
                end
                if target and target.Transparency < 0.9 then
                    if not killerPos or (Vector3.new(target.Position.X, 0, target.Position.Z) - Vector3.new(killerPos.X, 0, killerPos.Z)).Magnitude > 45 then
                        local val = getLootValue(obj)
                        if val and val >= 1 and val ~= 20 then
                            table.insert(lootList, {obj = target, src = obj, value = val})
                        end
                    end
                end
            end
        end
    end
    table.sort(lootList, function(a, b) return a.value > b.value end)
    return lootList
end

local function getSafeExits(killerPos)
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
                    local gatePart = exitObj.PrimaryPart
                    if not gatePart then
                        for _, p in ipairs(exitObj:GetDescendants()) do
                            if p:IsA("BasePart") and p.Name ~= "Bouncer" then
                                gatePart = p
                                break
                            end
                        end
                    end
                    if gatePart then
                        if not killerPos or (Vector3.new(gatePart.Position.X, 0, gatePart.Position.Z) - Vector3.new(killerPos.X, 0, killerPos.Z)).Magnitude > 40 then
                            table.insert(exits, gatePart)
                        end
                    end
                end
            end
        end
    end
    return exits
end

local _lockerCache = {models = {}, time = 0}
local function getLockerModels()
    local now = tick()
    if now - _lockerCache.time < 4 and #_lockerCache.models > 0 then
        local valid = true
        for _, m in ipairs(_lockerCache.models) do if not m or not m.Parent then valid = false; break end end
        if valid then return _lockerCache.models end
    end
    local models = {}
    local seen = {}
    local map = getMap()
    local folder = nil
    for _, name in ipairs({"Lockers", "Locker", "lockers", "locker", "Wardrobes", "Wardrobe", "Cabinets", "Cabinet", "Hideouts", "Hideout", "Closets", "Closet"}) do
        local f = (map and map:FindFirstChild(name)) or workspace:FindFirstChild(name)
        if f then folder = f; break end
    end
    if folder then
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") and not seen[obj] then seen[obj] = true; table.insert(models, obj) end
        end
    end
    if #models == 0 then
        local searchRoot = map or workspace
        for _, obj in ipairs(searchRoot:GetDescendants()) do
            if obj:IsA("Model") and not seen[obj] and obj ~= LP.Character then
                local n = obj.Name:lower()
                for _, kw in ipairs({"locker", "wardrobe", "cabinet", "closet", "hideout", "armoire", "coffin", "chest"}) do
                    if n:find(kw) then seen[obj] = true; table.insert(models, obj); break end
                end
            end
        end
    end
    _lockerCache.models = models
    _lockerCache.time = tick()
    return models
end

local function getSafeNodes()
    local nodes = {}
    local map = getMap()
    local searchRoot = map or workspace
    local lf = searchRoot:FindFirstChild("LootSpawns", true)
    if lf then
        for _, v in ipairs(lf:GetDescendants()) do
            if v:IsA("BasePart") then table.insert(nodes, v.Position) end
        end
    end
    return nodes
end

local function interactWithPrompt(obj)
    if not obj then return end
    for _, c in ipairs(obj:GetDescendants()) do
        if c:IsA("ProximityPrompt") and c.Enabled then
            pcall(function()
                local oldLos = c.RequiresLineOfSight
                local oldMax = c.MaxActivationDistance
                c.RequiresLineOfSight = false
                c.MaxActivationDistance = 9e9
                fireproximityprompt(c)
                task.delay(0.5, function()
                    if c and c.Parent then
                        c.RequiresLineOfSight = oldLos
                        c.MaxActivationDistance = oldMax
                    end
                end)
            end)
        elseif c:IsA("ClickDetector") then
            pcall(function() fireclickdetector(c, 0) end)
        end
    end
end

local function handleTraps(char, hum)
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Enabled then
            pcall(function() fireproximityprompt(v) end)
        elseif v:IsA("ClickDetector") then
            pcall(function() fireclickdetector(v, 0) end)
        end
    end

    local state = hum:GetState()
    if state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        hum.Jump = true
    end

    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name == "Trap" then
            pcall(function() v:Destroy() end)
        end
    end

    local spaceLab = workspace:FindFirstChild("Space Lab")
    if spaceLab then
        local ratTraps = spaceLab:FindFirstChild("RatTraps")
        if ratTraps then
            for _, v in ipairs(ratTraps:GetChildren()) do
                pcall(function() v:Destroy() end)
            end
        end
    end
end

local function smartSteer(targetPos, stopDist)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end

    local rootPos2D = Vector3.new(root.Position.X, 0, root.Position.Z)
    local targetPos2D = Vector3.new(targetPos.X, 0, targetPos.Z)
    
    if (rootPos2D - targetPos2D).Magnitude <= stopDist then
        hum:Move(Vector3.new(0, 0, 0), false)
        PathData.Path = nil
        return true
    end

    local now = tick()
    if now - PathData.LastPosTime > 0.3 then
        if (root.Position - PathData.LastPos).Magnitude < 0.5 then
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

    local needsPath = false
    if not PathData.Path then needsPath = true end
    if PathData.TargetPos and (Vector3.new(PathData.TargetPos.X, 0, PathData.TargetPos.Z) - targetPos2D).Magnitude > 2 then needsPath = true end
    if now - PathData.LastCompute > 1.0 then needsPath = true end

    if needsPath then
        PathData.TargetPos = targetPos
        PathData.LastCompute = now
        local path = Sv.PathfindingService:CreatePath({
            AgentRadius = 2.5,
            AgentHeight = 5,
            AgentCanJump = true,
            WaypointSpacing = 3
        })
        local s, e = pcall(function() path:ComputeAsync(root.Position, targetPos) end)
        if s and path.Status == Enum.PathStatus.Success then
            PathData.Waypoints = path:GetWaypoints()
            PathData.CurrentIndex = 2
            PathData.Path = path
        else
            PathData.Path = nil
        end
    end

    local moveTarget = targetPos
    if PathData.Path and PathData.Waypoints[PathData.CurrentIndex] then
        local wp = PathData.Waypoints[PathData.CurrentIndex]
        moveTarget = wp.Position
        if wp.Action == Enum.PathWaypointAction.Jump then
            hum.Jump = true
        end
        local wpPos2D = Vector3.new(wp.Position.X, 0, wp.Position.Z)
        if (rootPos2D - wpPos2D).Magnitude < 3 then
            PathData.CurrentIndex = PathData.CurrentIndex + 1
        end
    end

    local dir = (moveTarget - root.Position)
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude > 0 then
        dir = dir.Unit
    else
        dir = Vector3.new(0, 0, 0)
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    local fRay = workspace:Raycast(root.Position, dir * 3, rayParams)
    if fRay and fRay.Instance and fRay.Instance.CanCollide then
        local rightDir = Vector3.new(-dir.Z, 0, dir.X)
        local leftDir = Vector3.new(dir.Z, 0, -dir.X)
        local rRay = workspace:Raycast(root.Position, rightDir * 3, rayParams)
        local lRay = workspace:Raycast(root.Position, leftDir * 3, rayParams)
        
        if not rRay then
            dir = (dir + rightDir).Unit
        elseif not lRay then
            dir = (dir + leftDir).Unit
        else
            hum.Jump = true
        end
    end

    hum:Move(dir, false)
    return false
end

local function logicLobby(root, hum)
    if not State.LobbyTarget then
        State.LobbyTarget = LOBBY_COORDS[math.random(1, #LOBBY_COORDS)]
    end
    local reached = smartSteer(State.LobbyTarget, 1.5)
    if reached then
        local now = tick()
        if now - State.LastJump > 20 then
            State.LastJump = now
            hum.Jump = true
        end
    end
end

local function logicSurvivor(root, hum)
    local killer = nil
    local kDist = math.huge
    local killerPos = nil
    
    for _, p in ipairs(Sv.Players:GetPlayers()) do
        if isKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pr = p.Character.HumanoidRootPart
            local d = (root.Position - pr.Position).Magnitude
            if d < kDist then
                kDist = d
                killer = pr
                killerPos = pr.Position
            end
        end
    end

    local safeExits = getSafeExits(killerPos)

    if isPlayerDowned(LP) then
        State.IsHiding = false
        if #safeExits > 0 then
            local ce = getClosest(safeExits, root.Position)
            if ce then
                smartSteer(ce.Position, 0.1)
                return
            end
        end
        
        local upSurvs = {}
        for _, p in ipairs(Sv.Players:GetPlayers()) do
            if p ~= LP and getTeam(p) == "survivor" and not isPlayerDowned(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(upSurvs, p.Character.HumanoidRootPart)
            end
        end
        
        if #upSurvs > 0 then
            local cs = getClosest(upSurvs, root.Position)
            if cs then
                smartSteer(cs.Position, 2)
                return
            end
        end
        
        if not State.MapWanderTarget or (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(State.MapWanderTarget.X, 0, State.MapWanderTarget.Z)).Magnitude < 5 then
            local nodes = getSafeNodes()
            if #nodes > 0 then
                State.MapWanderTarget = nodes[math.random(1, #nodes)]
            else
                State.MapWanderTarget = root.Position + Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
            end
        end
        if State.MapWanderTarget then
            smartSteer(State.MapWanderTarget, 2)
        end
        return
    end

    if State.IsHiding then
        if killer and kDist > 70 then
            State.IsHiding = false
            hum.Jump = true
        else
            hum:Move(Vector3.new(0, 0, 0), false)
            return
        end
    end

    if killer and kDist < 55 then
        local lockers = getLockerModels()
        local cl, cd = getClosest(lockers, root.Position)
        if cl and cd < 40 then
            local targetPos = cl:IsA("Model") and (cl.PrimaryPart and cl.PrimaryPart.Position or cl:GetModelCFrame().Position) or cl.Position
            local reached = smartSteer(targetPos, 0.1)
            if reached then
                State.IsHiding = true
            end
            return
        end
        
        local nodes = getSafeNodes()
        local bestEscapeNode = nil
        local maxKDist = 0
        for _, node in ipairs(nodes) do
            local dToK = (node - killer.Position).Magnitude
            if dToK > maxKDist then
                maxKDist = dToK
                bestEscapeNode = node
            end
        end
        
        if bestEscapeNode then
            smartSteer(bestEscapeNode, 2)
        else
            local dir = (root.Position - killer.Position).Unit
            local escapePos = root.Position + (dir * 50)
            smartSteer(escapePos, 2)
        end
        return
    end

    if #safeExits > 0 then
        local ce = getClosest(safeExits, root.Position)
        if ce then
            smartSteer(ce.Position, 0.1)
            return
        end
    end

    local safeLoot = getSafeLoot(killerPos)
    if #safeLoot > 0 then
        local targetLoot = safeLoot[1].obj
        local reached = smartSteer(targetLoot.Position, 0.1)
        if reached then
            interactWithPrompt(safeLoot[1].src)
        end
        return
    end
    
    if not State.MapWanderTarget or (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(State.MapWanderTarget.X, 0, State.MapWanderTarget.Z)).Magnitude < 5 then
        local nodes = getSafeNodes()
        if #nodes > 0 then
            State.MapWanderTarget = nodes[math.random(1, #nodes)]
        else
            State.MapWanderTarget = root.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
        end
    end
    if State.MapWanderTarget then
        smartSteer(State.MapWanderTarget, 2)
    end
end

local function logicKiller(root, hum)
    local targetSurv = nil
    local sDist = math.huge
    
    for _, p in ipairs(Sv.Players:GetPlayers()) do
        if p ~= LP and getTeam(p) == "survivor" and not isPlayerDowned(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
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

    local now = tick()

    if targetSurv then
        smartSteer(targetSurv.Position, 2)
        if sDist < 12 and tool and now - State.LastAttack > 0.6 then
            tool:Activate()
            State.LastAttack = now
        end
        return
    end

    if now - State.ActionDelay > 5 then
        local lockers = getLockerModels()
        local cl, cd = getClosest(lockers, root.Position)
        if cl then
            local targetPos = cl:IsA("Model") and (cl.PrimaryPart and cl.PrimaryPart.Position or cl:GetModelCFrame().Position) or cl.Position
            local reached = smartSteer(targetPos, 2)
            if reached and tool and now - State.LastAttack > 0.8 then
                tool:Activate()
                State.LastAttack = now
                State.ActionDelay = now
            end
            return
        end
    end

    if not State.MapWanderTarget or (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(State.MapWanderTarget.X, 0, State.MapWanderTarget.Z)).Magnitude < 5 then
        local map = getMap()
        local nodes = {}
        if map then
            local lf = map:FindFirstChild("LootSpawns", true)
            if lf then
                for _, v in ipairs(lf:GetDescendants()) do
                    if v:IsA("BasePart") then table.insert(nodes, v.Position) end
                end
            end
        end
        if #nodes > 0 then
            State.MapWanderTarget = nodes[math.random(1, #nodes)]
        else
            State.MapWanderTarget = root.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
        end
    end
    if State.MapWanderTarget then
        smartSteer(State.MapWanderTarget, 2)
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
        State.CurrentTeam = getTeam(LP)
        PathData.Path = nil
    else
        btn.Text = "Auto SH: OFF"
        btn.TextColor3 = Color3.fromRGB(255, 69, 69)
        frame.BorderColor3 = Color3.fromRGB(13, 139, 255)
        PathData.Path = nil
        local c = LP.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then h:Move(Vector3.new(0, 0, 0), false) end
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        if AutoSH_Enabled then
            pcall(function()
                local char = LP.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                
                if root and hum and hum.Health > 0 then
                    handleTraps(char, hum)
                    
                    local team = getTeam(LP)
                    if team ~= State.CurrentTeam then
                        State.CurrentTeam = team
                        State.LobbyTarget = nil
                        State.IsHiding = false
                        PathData.Path = nil
                    end
                    
                    if team == "lobby" then
                        logicLobby(root, hum)
                    elseif team == "survivor" then
                        logicSurvivor(root, hum)
                    elseif team == "killer" then
                        logicKiller(root, hum)
                    end
                end
            end)
        end
    end
end)
