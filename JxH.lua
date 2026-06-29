local Sv = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    PathfindingService = game:GetService("PathfindingService"),
    CoreGui = game:GetService("CoreGui"),
    UserInputService = game:GetService("UserInputService")
}

local LP = Sv.Players.LocalPlayer
local AutoSH_Enabled = false

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

local function checkLineOfSight(startPos, endPos, ignoreList)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = ignoreList
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local dir = (endPos - startPos)
    local ray = workspace:Raycast(startPos, dir, rayParams)
    return ray == nil
end

local function simpleMove(targetPos)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    if hum.MoveDirection.Magnitude > 0 and root.Velocity.Magnitude < 2 then
        hum.Jump = true
    end

    local dist = (root.Position - targetPos).Magnitude
    if dist < 25 and checkLineOfSight(root.Position, targetPos, {char}) then
        hum:MoveTo(targetPos)
        return
    end

    local path = Sv.PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true
    })
    
    local s, e = pcall(function() path:ComputeAsync(root.Position, targetPos) end)
    if s and path.Status == Enum.PathStatus.Success then
        local wps = path:GetWaypoints()
        if wps[2] then
            hum:MoveTo(wps[2].Position)
            if wps[2].Action == Enum.PathWaypointAction.Jump then
                hum.Jump = true
            end
        end
    else
        hum:MoveTo(targetPos)
        if root.Velocity.Magnitude < 1 then hum.Jump = true end
    end
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

local function getLoot()
    local loot = {}
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
                    local val = getLootValue(obj)
                    if val and val >= 1 and val ~= 20 then
                        table.insert(loot, target)
                    end
                end
            end
        end
    end
    return loot
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
                    local gatePart = exitObj.PrimaryPart
                    if not gatePart then
                        for _, p in ipairs(exitObj:GetDescendants()) do
                            if p:IsA("BasePart") and p.Name ~= "Bouncer" then
                                gatePart = p
                                break
                            end
                        end
                    end
                    if gatePart then table.insert(exits, gatePart) end
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

local lobbyTarget = nil
local lastLobbyJump = 0
local function logicLobby(root, hum)
    if not lobbyTarget or (root.Position - lobbyTarget).Magnitude < 3 then
        lobbyTarget = LOBBY_COORDS[math.random(1, #LOBBY_COORDS)]
    end
    simpleMove(lobbyTarget)
    local now = tick()
    if now - lastLobbyJump > 20 then
        lastLobbyJump = now
        hum.Jump = true
    end
end

local function logicSurvivor(root, hum)
    local openExits = getOpenExits()
    if #openExits > 0 then
        local ce = getClosest(openExits, root.Position)
        if ce then
            simpleMove(ce.Position)
            return
        end
    end

    if isPlayerDowned(LP) then
        local aliveFriends = {}
        for _, p in ipairs(Sv.Players:GetPlayers()) do
            if p ~= LP and getTeam(p) == "survivor" and not isPlayerDowned(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(aliveFriends, p.Character.HumanoidRootPart)
            end
        end
        if #aliveFriends > 0 then
            local cf = getClosest(aliveFriends, root.Position)
            if cf then
                simpleMove(cf.Position)
                return
            end
        end
        return
    end

    local killer = nil
    local kDist = math.huge
    for _, p in ipairs(Sv.Players:GetPlayers()) do
        if isKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pr = p.Character.HumanoidRootPart
            local d = (root.Position - pr.Position).Magnitude
            if d < kDist then
                kDist = d
                killer = pr
            end
        end
    end

    if killer and kDist < 50 then
        local lockers = getLockerModels()
        local cl, lDist = getClosest(lockers, root.Position)
        if cl and lDist < 15 then
            local targetPos = cl:IsA("Model") and (cl.PrimaryPart and cl.PrimaryPart.Position or cl:GetModelCFrame().Position) or cl.Position
            simpleMove(targetPos)
            return
        end
        
        local runDir = (root.Position - killer.Position).Unit
        local runPos = root.Position + (runDir * 30)
        hum:MoveTo(runPos)
        if root.Velocity.Magnitude < 2 then hum.Jump = true end
        return
    end

    local loot = getLoot()
    if #loot > 0 then
        local cl = getClosest(loot, root.Position)
        if cl then
            simpleMove(cl.Position)
            return
        end
    end

    local nodes = getSafeNodes()
    if #nodes > 0 then
        local randomNode = nodes[math.random(1, #nodes)]
        simpleMove(randomNode)
    end
end

local lastAttackTime = 0
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
        simpleMove(targetSurv.Position)
        if sDist < 12 and tool and now - lastAttackTime > 0.6 then
            tool:Activate()
            lastAttackTime = now
        end
        return
    end

    local lockers = getLockerModels()
    if #lockers > 0 then
        local cl, lDist = getClosest(lockers, root.Position)
        if cl then
            local targetPos = cl:IsA("Model") and (cl.PrimaryPart and cl.PrimaryPart.Position or cl:GetModelCFrame().Position) or cl.Position
            simpleMove(targetPos)
            if lDist < 7 and tool and now - lastAttackTime > 1 then
                tool:Activate()
                lastAttackTime = now
            end
            return
        end
    end

    local nodes = getSafeNodes()
    if #nodes > 0 then
        local randomNode = nodes[math.random(1, #nodes)]
        simpleMove(randomNode)
    end
end

btn.MouseButton1Click:Connect(function()
    AutoSH_Enabled = not AutoSH_Enabled
    if AutoSH_Enabled then
        btn.Text = "Auto SH: ON"
        btn.TextColor3 = Color3.fromRGB(46, 204, 113)
        frame.BorderColor3 = Color3.fromRGB(46, 204, 113)
        lobbyTarget = nil
    else
        btn.Text = "Auto SH: OFF"
        btn.TextColor3 = Color3.fromRGB(255, 69, 69)
        frame.BorderColor3 = Color3.fromRGB(13, 139, 255)
        local c = LP.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then h:MoveTo(c.HumanoidRootPart.Position) end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if AutoSH_Enabled then
            pcall(function()
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
            end)
        end
    end
end)
