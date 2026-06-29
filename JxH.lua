local Sv = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    PathfindingService = game:GetService("PathfindingService"),
    CoreGui = game:GetService("CoreGui"),
    UserInputService = game:GetService("UserInputService"),
    CollectionService = game:GetService("CollectionService"),
    Workspace = game:GetService("Workspace")
}

local LP = Sv.Players.LocalPlayer
local AutoSH_Enabled = false

-- ==================== CONFIGURATION ====================
local CONFIG = {
    -- Movement
    STOP_DISTANCE = 2.5,
    WAYPOINT_SPACING = 3,
    AGENT_RADIUS = 2.0,
    AGENT_HEIGHT = 5.0,
    JUMP_COOLDOWN = 0.3,
    STUCK_THRESHOLD = 0.8,
    STUCK_RESET_TIME = 0.4,
    MAX_STUCK_COUNT = 2,
    PATH_RECOMPUTE_TIME = 1.0,
    PATH_TIMEOUT = 8,
    WALL_AVOIDANCE_DIST = 6,
    WALL_AVOIDANCE_ANGLE = math.rad(45),

    -- Survivor
    KILLER_DETECT_RANGE = 80,
    HIDE_DIST_TO_KILLER = 70,
    SAFE_EXIT_DIST_FROM_KILLER = 40,
    LOCKER_SEARCH_RANGE = 40,
    LOOT_SAFE_DIST_FROM_KILLER = 50,
    ESCAPE_DIR_MULTIPLIER = 50,

    -- Killer
    ATTACK_RANGE = 12,
    ATTACK_COOLDOWN = 0.6,
    LOCKER_CHECK_COOLDOWN = 5,
    TOOL_SEARCH_RANGE = 1000,

    -- General
    UPDATE_RATE = 0.08,
    RAYCAST_LENGTH = 5,
    RAYCAST_ANGLE_STEP = 30,
    MAX_RAYCASTS = 6
}

-- ==================== STATE MANAGEMENT ====================
local PathData = {
    Path = nil,
    Waypoints = {},
    CurrentIndex = 1,
    TargetPos = nil,
    LastCompute = 0,
    LastPos = Vector3.new(),
    LastPosTime = 0,
    StuckCount = 0,
    LastStuckTime = 0,
    CurrentMoveTarget = nil,
    PathBlockedConn = nil,
    PathTimeout = 0
}

local State = {
    IsHiding = false,
    LobbyTarget = nil,
    LastJump = 0,
    ActionDelay = 0,
    TargetLocker = nil,
    CurrentLoot = nil,
    MapWanderTarget = nil,
    CurrentTeam = "",
    LastAttack = 0,
    LastWanderTime = 0,
    IsStuck = false,
    LastDirChange = 0,
    AvoidanceDir = nil
}

-- ==================== LOBBY COORDINATES ====================
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

-- ==================== UI CREATION ====================
local sg = Instance.new("ScreenGui")
sg.Name = "AutoSH_Improved"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() sg.Parent = Sv.CoreGui end)
if not sg.Parent then pcall(function() sg.Parent = LP:WaitForChild("PlayerGui") end) end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 160, 0, 55)
frame.Position = UDim2.new(0.5, -80, 0, 25)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(13, 139, 255)
stroke.Thickness = 2
stroke.Parent = frame

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, 0, 1, 0)
btn.BackgroundTransparency = 1
btn.Text = "Auto SH: OFF"
btn.TextColor3 = Color3.fromRGB(255, 80, 80)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 15
btn.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 18)
statusLabel.Position = UDim2.new(0, 0, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Idle"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.Parent = frame

-- ==================== UTILITY FUNCTIONS ====================
local function setStatus(text)
    statusLabel.Text = text:sub(1, 20)
end

local function getTeam(player)
    if not player then return "lobby" end
    local team = player.Team
    if not team then return "lobby" end
    local t = team.Name:lower()
    if t:find("survivor") or t:find("innocent") or t:find("hider") or t:find("player") then return "survivor" end
    if t:find("killer") or t:find("slasher") or t:find("hunter") then return "killer" end
    if t:find("lobby") or t:find("waiting") then return "lobby" end
    return "lobby"
end

local function isKiller(player)
    if player == LP then return false end
    if not player then return false end
    local team = player.Team
    if not team then return false end
    local t = team.Name:lower()
    if t == "killer" or t:find("^killer") or t:find("slasher") or t:find("hunter") then return true end
    if t:find("survivor") or t:find("innocent") or t:find("lobby") or t:find("hider") or t:find("waiting") then return false end
    local myTeam = LP.Team
    if myTeam then
        local mt = myTeam.Name:lower()
        if mt:find("survivor") or mt:find("innocent") or mt:find("hider") then return team ~= myTeam end
    end
    return false
end

local function isPlayerDowned(player)
    if not player then return false end
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    if hum.Health <= 0 and hum.MaxHealth > 0 then return false end
    if char:FindFirstChildOfClass("ForceField") then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    -- Check various downed indicators
    local boh = root:FindFirstChild("BleedOutHealth")
    if boh and boh:IsA("BoolValue") and boh.Value then return true end
    if boh and boh:IsA("NumberValue") and boh.Value > 0 then return true end

    local dv = char:FindFirstChild("Downed")
    if dv and ((dv:IsA("BoolValue") and dv.Value) or (dv:IsA("IntValue") and dv.Value > 0)) then return true end

    local inc = char:FindFirstChild("Incapacitated")
    if inc and ((inc:IsA("BoolValue") and inc.Value) or (inc:IsA("IntValue") and inc.Value > 0)) then return true end

    local state = hum:GetState()
    if (state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll) and hum.WalkSpeed < 5 then return true end

    return false
end

local function getMap()
    for _, obj in ipairs(Sv.Workspace:GetChildren()) do
        if (obj:IsA("Model") or obj:IsA("Folder")) and obj ~= LP.Character then
            local n = obj.Name:lower()
            if not n:find("lobby") and not n:find("spawn") and not Sv.Players:GetPlayerFromCharacter(obj) then
                if n:find("map") or obj:FindFirstChild("LootSpawns", true) or obj:FindFirstChild("Exits", true) or obj:FindFirstChild("Lockers", true) then
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
        if not obj or not obj.Parent then continue end
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

-- ==================== CACHING SYSTEM ====================
local Cache = {
    LootValue = setmetatable({}, {__mode = "k"}),
    Lockers = {models = {}, time = 0},
    Exits = {list = {}, time = 0},
    LootSpawns = {list = {}, time = 0},
    Map = {obj = nil, time = 0},
    CACHE_DURATION = 3
}

local function getCachedMap()
    local now = tick()
    if Cache.Map.obj and (now - Cache.Map.time < Cache.CACHE_DURATION) and Cache.Map.obj.Parent then
        return Cache.Map.obj
    end
    Cache.Map.obj = getMap()
    Cache.Map.time = now
    return Cache.Map.obj
end

local function getLootValue(obj)
    if not obj or not obj.Parent then return nil end
    if Cache.LootValue[obj] ~= nil then return Cache.LootValue[obj] end

    local function cache(v)
        if v == 20 then v = nil end
        Cache.LootValue[obj] = v
        return v
    end

    local attr = obj:GetAttribute("Value") or obj:GetAttribute("Amount") or obj:GetAttribute("LootValue")
    if attr then
        local val = tonumber(attr)
        if val then return cache(val) end
    end

    local fallback = nil
    for _, c in ipairs(obj:GetDescendants()) do
        if not c or not c.Parent then continue end
        if c:IsA("ProximityPrompt") then
            local at = c:GetAttribute("ActionText")
            if at and type(at) == "string" then
                local n = at:match("+(%d+)")
                if n then fallback = tonumber(n); break end
            end
            local txt = (c.ActionText or "") .. " " .. (c.ObjectText or "")
            local n = txt:match("+(%d+)") or txt:match("(%d+)%s*[Cc]oin") or txt:match("(%d+)%s*[Gg]old") or txt:match("(%d+)%s*[Pp]oint")
            if n then fallback = tonumber(n); break end
        elseif c:IsA("ClickDetector") then
            local at = c:GetAttribute("ActionText")
            if at and type(at) == "string" then
                local n = at:match("+(%d+)")
                if n then fallback = tonumber(n); break end
            end
        elseif c:IsA("TextLabel") or c:IsA("TextButton") then
            local n = c.Text:match("+(%d+)")
            if n then fallback = tonumber(n); break end
        elseif (c:IsA("IntValue") or c:IsA("NumberValue")) and not fallback then
            fallback = c.Value
        elseif c:IsA("StringValue") and not fallback then
            local n = tonumber(c.Value)
            if n then fallback = n end
        end
    end
    if fallback then return cache(fallback) end

    local map = getCachedMap()
    local lootFolder = map and map:FindFirstChild("LootSpawns", true) or Sv.Workspace:FindFirstChild("LootSpawns", true)
    if lootFolder and obj:IsDescendantOf(lootFolder) then
        return cache(1)
    end
    return cache(nil)
end

local function getSafeLoot(killerPos, rootPos)
    local lootList = {}
    local map = getCachedMap()
    local lf = map and map:FindFirstChild("LootSpawns", true) or Sv.Workspace:FindFirstChild("LootSpawns", true)
    if not lf then return lootList end

    for _, obj in ipairs(lf:GetDescendants()) do
        if not obj or not obj.Parent then continue end
        if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
            local parent = obj.Parent
            local target = nil
            if parent:IsA("BasePart") then
                target = parent
            elseif parent:IsA("Model") then
                target = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true)
            end
            if target and target.Transparency < 0.9 then
                local distToKiller = math.huge
                if killerPos then
                    distToKiller = (Vector3.new(target.Position.X, 0, target.Position.Z) - Vector3.new(killerPos.X, 0, killerPos.Z)).Magnitude
                end
                if distToKiller > CONFIG.LOOT_SAFE_DIST_FROM_KILLER then
                    local val = getLootValue(obj)
                    if val and val >= 1 and val ~= 20 then
                        local dist = (Vector3.new(target.Position.X, 0, target.Position.Z) - Vector3.new(rootPos.X, 0, rootPos.Z)).Magnitude
                        table.insert(lootList, {obj = target, src = obj, value = val, distance = dist})
                    end
                end
            end
        end
    end

    table.sort(lootList, function(a, b)
        if a.value == b.value then
            return a.distance < b.distance
        end
        return a.value > b.value
    end)
    return lootList
end

local function getOpenExits()
    local now = tick()
    if now - Cache.Exits.time < Cache.CACHE_DURATION and #Cache.Exits.list > 0 then
        local valid = true
        for _, e in ipairs(Cache.Exits.list) do if not e or not e.Parent then valid = false; break end end
        if valid then return Cache.Exits.list end
    end

    local exits = {}
    local map = getCachedMap()
    if not map then Cache.Exits.time = now; Cache.Exits.list = exits; return exits end

    local f = map:FindFirstChild("Exits", true)
    if not f then Cache.Exits.time = now; Cache.Exits.list = exits; return exits end

    for _, exitObj in ipairs(f:GetChildren()) do
        if not exitObj or not exitObj.Parent then continue end
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

    Cache.Exits.list = exits
    Cache.Exits.time = now
    return exits
end

local function getLockerModels()
    local now = tick()
    if now - Cache.Lockers.time < Cache.CACHE_DURATION and #Cache.Lockers.models > 0 then
        local valid = true
        for _, m in ipairs(Cache.Lockers.models) do if not m or not m.Parent then valid = false; break end end
        if valid then return Cache.Lockers.models end
    end

    local models = {}
    local seen = {}
    local map = getCachedMap()
    local folder = nil
    local names = {"Lockers", "Locker", "lockers", "locker", "Wardrobes", "Wardrobe", "Cabinets", "Cabinet", "Hideouts", "Hideout", "Closets", "Closet"}

    for _, name in ipairs(names) do
        local f = (map and map:FindFirstChild(name)) or Sv.Workspace:FindFirstChild(name)
        if f then folder = f; break end
    end

    if folder then
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") and not seen[obj] then 
                seen[obj] = true
                table.insert(models, obj) 
            end
        end
    end

    if #models == 0 then
        local searchRoot = map or Sv.Workspace
        for _, obj in ipairs(searchRoot:GetDescendants()) do
            if obj:IsA("Model") and not seen[obj] and obj ~= LP.Character then
                local n = obj.Name:lower()
                for _, kw in ipairs({"locker", "wardrobe", "cabinet", "closet", "hideout", "armoire", "coffin", "chest"}) do
                    if n:find(kw) then seen[obj] = true; table.insert(models, obj); break end
                end
            end
        end
    end

    Cache.Lockers.models = models
    Cache.Lockers.time = now
    return models
end

local function checkLineOfSight(startPos, endPos, ignoreList)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = ignoreList or {LP.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true
    local dir = (endPos - startPos)
    if dir.Magnitude > 100 then return false end
    local ray = Sv.Workspace:Raycast(startPos, dir, rayParams)
    if not ray then return true end
    -- Allow transparent or non-colliding parts
    if ray.Instance then
        if not ray.Instance.CanCollide or ray.Instance.Transparency > 0.7 then
            return true
        end
    end
    return false
end

local function getSafeNodes()
    local nodes = {}
    local map = getCachedMap()
    local searchRoot = map or Sv.Workspace
    local lf = searchRoot:FindFirstChild("LootSpawns", true)
    if lf then
        for _, v in ipairs(lf:GetDescendants()) do
            if v:IsA("BasePart") then table.insert(nodes, v.Position) end
        end
    end
    return nodes
end

local function interactWithPrompt(obj)
    if not obj or not obj.Parent then return end
    for _, c in ipairs(obj:GetDescendants()) do
        if not c or not c.Parent then continue end
        if c:IsA("ProximityPrompt") and c.Enabled then
            pcall(function()
                local oldLos = c.RequiresLineOfSight
                local oldMax = c.MaxActivationDistance
                local oldHold = c.HoldDuration
                c.RequiresLineOfSight = false
                c.MaxActivationDistance = 20
                c.HoldDuration = 0
                fireproximityprompt(c)
                task.delay(0.3, function()
                    if c and c.Parent then
                        c.RequiresLineOfSight = oldLos
                        c.MaxActivationDistance = oldMax
                        c.HoldDuration = oldHold
                    end
                end)
            end)
        elseif c:IsA("ClickDetector") then
            pcall(function() fireclickdetector(c, 0) end)
        end
    end
end

local function handleTraps(char, hum)
    if not char or not hum then return end
    local now = tick()

    -- Handle prompts on character
    for _, v in ipairs(char:GetDescendants()) do
        if not v or not v.Parent then continue end
        if v:IsA("ProximityPrompt") and v.Enabled then
            pcall(function() fireproximityprompt(v) end)
        elseif v:IsA("ClickDetector") then
            pcall(function() fireclickdetector(v, 0) end)
        end
    end

    -- Handle ragdoll state
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        if now - State.LastJump > 0.5 then
            State.LastJump = now
            hum.Jump = true
        end
    end

    -- Only clean traps occasionally (every 2 seconds)
    if now - State.ActionDelay > 2 then
        State.ActionDelay = now
        for _, v in ipairs(Sv.Workspace:GetDescendants()) do
            if v:IsA("Model") and v.Name == "Trap" then
                pcall(function() v:Destroy() end)
            end
        end
        local spaceLab = Sv.Workspace:FindFirstChild("Space Lab")
        if spaceLab then
            local ratTraps = spaceLab:FindFirstChild("RatTraps")
            if ratTraps then
                for _, v in ipairs(ratTraps:GetChildren()) do
                    pcall(function() v:Destroy() end)
                end
            end
        end
    end
end

-- ==================== WALL AVOIDANCE SYSTEM ====================
local function getWallAvoidanceDirection(root, hum, targetPos)
    local char = LP.Character
    if not char then return nil end

    local rootPos = root.Position
    local forward = (targetPos - rootPos).Unit
    if forward.Magnitude < 0.1 then forward = root.CFrame.LookVector end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true

    -- Check forward
    local forwardRay = Sv.Workspace:Raycast(rootPos, forward * CONFIG.WALL_AVOIDANCE_DIST, rayParams)
    if not forwardRay then return nil end -- No wall ahead

    -- Wall detected, check left and right
    local right = Vector3.new(-forward.Z, 0, forward.X).Unit
    local left = -right

    local rightRay = Sv.Workspace:Raycast(rootPos, right * CONFIG.WALL_AVOIDANCE_DIST, rayParams)
    local leftRay = Sv.Workspace:Raycast(rootPos, left * CONFIG.WALL_AVOIDANCE_DIST, rayParams)

    local rightDist = rightRay and (rightRay.Position - rootPos).Magnitude or CONFIG.WALL_AVOIDANCE_DIST
    local leftDist = leftRay and (leftRay.Position - rootPos).Magnitude or CONFIG.WALL_AVOIDANCE_DIST

    -- Also check diagonal directions
    local diagRight = (forward + right * 0.5).Unit
    local diagLeft = (forward + left * 0.5).Unit
    local diagRightRay = Sv.Workspace:Raycast(rootPos, diagRight * CONFIG.WALL_AVOIDANCE_DIST, rayParams)
    local diagLeftRay = Sv.Workspace:Raycast(rootPos, diagLeft * CONFIG.WALL_AVOIDANCE_DIST, rayParams)
    local diagRightDist = diagRightRay and (diagRightRay.Position - rootPos).Magnitude or CONFIG.WALL_AVOIDANCE_DIST
    local diagLeftDist = diagLeftRay and (diagLeftRay.Position - rootPos).Magnitude or CONFIG.WALL_AVOIDANCE_DIST

    -- Choose the direction with most clearance
    local bestDir = nil
    local bestDist = 0

    local dirs = {
        {dir = right, dist = rightDist},
        {dir = left, dist = leftDist},
        {dir = diagRight, dist = diagRightDist},
        {dir = diagLeft, dist = diagLeftDist}
    }

    for _, d in ipairs(dirs) do
        if d.dist > bestDist then
            bestDist = d.dist
            bestDir = d.dir
        end
    end

    return bestDir
end

local function checkStuck(root)
    local now = tick()
    if now - PathData.LastPosTime < CONFIG.STUCK_RESET_TIME then return false end

    local distMoved = (root.Position - PathData.LastPos).Magnitude
    if distMoved < CONFIG.STUCK_THRESHOLD then
        PathData.StuckCount = PathData.StuckCount + 1
        if PathData.StuckCount >= CONFIG.MAX_STUCK_COUNT then
            PathData.StuckCount = 0
            PathData.LastPos = root.Position
            PathData.LastPosTime = now
            return true
        end
    else
        PathData.StuckCount = 0
    end

    PathData.LastPos = root.Position
    PathData.LastPosTime = now
    return false
end

-- ==================== SMART MOVE (IMPROVED) ====================
local function smartMove(targetPos, stopDistance)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end

    local now = tick()
    local rootPos = root.Position
    local rootPos2D = Vector3.new(rootPos.X, 0, rootPos.Z)
    local targetPos2D = Vector3.new(targetPos.X, 0, targetPos.Z)
    local distToTarget = (rootPos2D - targetPos2D).Magnitude

    if distToTarget <= stopDistance then
        if PathData.CurrentMoveTarget then
            hum:MoveTo(rootPos)
            PathData.CurrentMoveTarget = nil
        end
        PathData.Path = nil
        if PathData.PathBlockedConn then
            PathData.PathBlockedConn:Disconnect()
            PathData.PathBlockedConn = nil
        end
        return true
    end

    -- Stuck detection
    if checkStuck(root) then
        State.IsStuck = true
        PathData.Path = nil
        PathData.CurrentMoveTarget = nil
        if PathData.PathBlockedConn then
            PathData.PathBlockedConn:Disconnect()
            PathData.PathBlockedConn = nil
        end

        -- Jump and move in random direction
        hum.Jump = true
        local randomAngle = math.random() * 2 * math.pi
        local randomDir = Vector3.new(math.cos(randomAngle), 0, math.sin(randomAngle))
        local escapePos = rootPos + (randomDir * 15)
        hum:MoveTo(escapePos)
        PathData.LastStuckTime = now
        return false
    else
        State.IsStuck = false
    end

    -- Wall avoidance (check every frame but apply direction smoothing)
    local avoidanceDir = getWallAvoidanceDirection(root, hum, targetPos)
    if avoidanceDir then
        State.AvoidanceDir = avoidanceDir
        State.LastDirChange = now
        -- Blend target direction with avoidance direction
        local targetDir = (targetPos - rootPos).Unit
        local blendedDir = (targetDir + avoidanceDir * 1.5).Unit
        local avoidPos = rootPos + (blendedDir * math.min(distToTarget, 20))

        PathData.Path = nil
        PathData.CurrentMoveTarget = avoidPos
        hum:MoveTo(avoidPos)

        -- Jump if wall is very close
        if now - State.LastJump > CONFIG.JUMP_COOLDOWN then
            local closeRay = Sv.Workspace:Raycast(rootPos, (targetPos - rootPos).Unit * 3, RaycastParams.new())
            if closeRay and closeRay.Instance and closeRay.Instance.CanCollide then
                State.LastJump = now
                hum.Jump = true
            end
        end
        return false
    elseif State.AvoidanceDir and (now - State.LastDirChange < 0.5) then
        -- Continue avoidance for a short time
        local targetDir = (targetPos - rootPos).Unit
        local blendedDir = (targetDir + State.AvoidanceDir).Unit
        local avoidPos = rootPos + (blendedDir * math.min(distToTarget, 15))
        PathData.CurrentMoveTarget = avoidPos
        hum:MoveTo(avoidPos)
        return false
    else
        State.AvoidanceDir = nil
    end

    -- Line of Sight check for direct movement
    local hasLOS = false
    if distToTarget < 50 then
        hasLOS = checkLineOfSight(rootPos, targetPos, {char})
    end

    if hasLOS then
        PathData.Path = nil
        if PathData.PathBlockedConn then
            PathData.PathBlockedConn:Disconnect()
            PathData.PathBlockedConn = nil
        end
        if not PathData.CurrentMoveTarget or (PathData.CurrentMoveTarget - targetPos).Magnitude > 1 then
            PathData.CurrentMoveTarget = targetPos
            hum:MoveTo(targetPos)
        end
        return false
    end

    -- Pathfinding
    local needsRecompute = false
    if not PathData.Path then needsRecompute = true end
    if PathData.TargetPos and (Vector3.new(PathData.TargetPos.X, 0, PathData.TargetPos.Z) - targetPos2D).Magnitude > 3 then needsRecompute = true end
    if now - PathData.LastCompute > CONFIG.PATH_RECOMPUTE_TIME then needsRecompute = true end
    if now - PathData.PathTimeout > CONFIG.PATH_TIMEOUT then needsRecompute = true end

    if needsRecompute then
        PathData.TargetPos = targetPos
        PathData.LastCompute = now
        PathData.PathTimeout = now

        if PathData.PathBlockedConn then
            PathData.PathBlockedConn:Disconnect()
            PathData.PathBlockedConn = nil
        end

        local path = Sv.PathfindingService:CreatePath({
            AgentRadius = CONFIG.AGENT_RADIUS,
            AgentHeight = CONFIG.AGENT_HEIGHT,
            AgentCanJump = true,
            AgentCanClimb = false,
            WaypointSpacing = CONFIG.WAYPOINT_SPACING,
            Costs = {
                Water = 20,
                Danger = math.huge
            }
        })

        local success, err = pcall(function() path:ComputeAsync(rootPos, targetPos) end)
        if success and path.Status == Enum.PathStatus.Success then
            PathData.Waypoints = path:GetWaypoints()
            PathData.CurrentIndex = 2
            PathData.Path = path

            PathData.PathBlockedConn = path.Blocked:Connect(function(blockedWaypointIdx)
                if blockedWaypointIdx >= PathData.CurrentIndex then
                    PathData.Path = nil
                    PathData.CurrentMoveTarget = nil
                end
            end)
        else
            PathData.Path = nil
            if not PathData.CurrentMoveTarget or (PathData.CurrentMoveTarget - targetPos).Magnitude > 1 then
                PathData.CurrentMoveTarget = targetPos
                hum:MoveTo(targetPos)
            end
            return false
        end
    end

    -- Follow path waypoints
    if PathData.Path and PathData.Waypoints[PathData.CurrentIndex] then
        local wp = PathData.Waypoints[PathData.CurrentIndex]

        if not PathData.CurrentMoveTarget or (PathData.CurrentMoveTarget - wp.Position).Magnitude > 1 then
            PathData.CurrentMoveTarget = wp.Position
            hum:MoveTo(wp.Position)
            if wp.Action == Enum.PathWaypointAction.Jump then
                if now - State.LastJump > CONFIG.JUMP_COOLDOWN then
                    State.LastJump = now
                    hum.Jump = true
                end
            end
        end

        local wpPos2D = Vector3.new(wp.Position.X, 0, wp.Position.Z)
        if (rootPos2D - wpPos2D).Magnitude < CONFIG.STOP_DISTANCE then
            PathData.CurrentIndex = PathData.CurrentIndex + 1
        end

        -- Check if we can skip to next waypoint (LOS optimization)
        local nextWp = PathData.Waypoints[PathData.CurrentIndex + 1]
        if nextWp then
            if checkLineOfSight(rootPos, nextWp.Position, {char}) then
                PathData.CurrentIndex = PathData.CurrentIndex + 1
                PathData.CurrentMoveTarget = nextWp.Position
                hum:MoveTo(nextWp.Position)
            end
        end
    end

    return false
end

-- ==================== GAME LOGIC ====================
local function logicLobby(root, hum)
    setStatus("Lobby: Wandering")
    if not State.LobbyTarget or (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(State.LobbyTarget.X, 0, State.LobbyTarget.Z)).Magnitude < 3 then
        State.LobbyTarget = LOBBY_COORDS[math.random(1, #LOBBY_COORDS)]
    end

    local reached = smartMove(State.LobbyTarget, 2)
    if reached then
        local now = tick()
        if now - State.LastJump > 15 then
            State.LastJump = now
            hum.Jump = true
        end
        State.LobbyTarget = LOBBY_COORDS[math.random(1, #LOBBY_COORDS)]
    end
end

local function getKillerInfo(root)
    local killer = nil
    local kDist = math.huge
    local killerPos = nil
    local killerRoot = nil

    for _, p in ipairs(Sv.Players:GetPlayers()) do
        if isKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local pr = p.Character.HumanoidRootPart
            local d = (root.Position - pr.Position).Magnitude
            if d < kDist then
                kDist = d
                killer = p
                killerPos = pr.Position
                killerRoot = pr
            end
        end
    end
    return killer, kDist, killerPos, killerRoot
end

local function logicSurvivor(root, hum)
    local killer, kDist, killerPos, killerRoot = getKillerInfo(root)
    local openExits = getOpenExits()
    local now = tick()

    -- Downed state
    if isPlayerDowned(LP) then
        setStatus("Downed: Seeking help")
        State.IsHiding = false
        State.TargetLocker = nil
        State.CurrentLoot = nil

        -- Find safest exit
        local bestExit = nil
        local bestExitDist = math.huge
        for _, ce in ipairs(openExits) do
            if not killerPos or (Vector3.new(ce.Position.X, 0, ce.Position.Z) - Vector3.new(killerPos.X, 0, killerPos.Z)).Magnitude > 30 then
                local d = (root.Position - ce.Position).Magnitude
                if d < bestExitDist then
                    bestExitDist = d
                    bestExit = ce
                end
            end
        end

        if bestExit then
            smartMove(bestExit.Position, 1)
            return
        end

        -- Find upright survivor
        local upSurvs = {}
        for _, p in ipairs(Sv.Players:GetPlayers()) do
            if p ~= LP and getTeam(p) == "survivor" and not isPlayerDowned(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(upSurvs, p.Character.HumanoidRootPart)
            end
        end

        if #upSurvs > 0 then
            local cs = getClosest(upSurvs, root.Position)
            if cs then
                smartMove(cs.Position, 2)
                return
            end
        end

        -- Wander
        if not State.MapWanderTarget or (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(State.MapWanderTarget.X, 0, State.MapWanderTarget.Z)).Magnitude < 5 then
            local nodes = getSafeNodes()
            if #nodes > 0 then
                State.MapWanderTarget = nodes[math.random(1, #nodes)]
            else
                State.MapWanderTarget = root.Position + Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
            end
        end
        if State.MapWanderTarget then
            smartMove(State.MapWanderTarget, 2)
        end
        return
    end

    -- Hiding state
    if State.IsHiding then
        if killer and kDist > CONFIG.HIDE_DIST_TO_KILLER then
            setStatus("Safe: Exiting hide")
            State.IsHiding = false
            State.TargetLocker = nil
            hum.Jump = true
            local forwardVec = root.CFrame.LookVector * 8
            hum:MoveTo(root.Position + forwardVec)
            task.wait(0.3)
        else
            setStatus("Hiding")
            PathData.CurrentMoveTarget = nil
            hum:MoveTo(root.Position)
            return
        end
    end

    -- Killer nearby - RUN or HIDE
    if killer and kDist < CONFIG.KILLER_DETECT_RANGE then
        setStatus("Killer nearby! " .. math.floor(kDist) .. "m")
        State.CurrentLoot = nil

        -- Try to find locker
        local lockers = getLockerModels()
        local bestLocker, bestLockerDist = nil, math.huge
        local rootPos2D = Vector3.new(root.Position.X, 0, root.Position.Z)

        for _, cl in ipairs(lockers) do
            if not cl or not cl.Parent then continue end
            local clPos = cl:IsA("Model") and (cl.PrimaryPart and cl.PrimaryPart.Position or cl:GetModelCFrame().Position) or cl.Position
            local clPos2D = Vector3.new(clPos.X, 0, clPos.Z)
            local d = (rootPos2D - clPos2D).Magnitude
            if d < bestLockerDist then
                bestLockerDist = d
                bestLocker = cl
            end
        end

        -- If locker is close and killer is close enough, hide
        if bestLocker and bestLockerDist < CONFIG.LOCKER_SEARCH_RANGE and kDist < 45 then
            local targetPos = bestLocker:IsA("Model") and (bestLocker.PrimaryPart and bestLocker.PrimaryPart.Position or bestLocker:GetModelCFrame().Position) or bestLocker.Position
            local reached = smartMove(targetPos, 3)
            if reached then
                interactWithPrompt(bestLocker)
                State.IsHiding = true
                State.TargetLocker = bestLocker
            end
            return
        end

        -- No locker or too far, RUN AWAY
        setStatus("Running from killer!")
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
            smartMove(bestEscapeNode, 2)
        else
            local dir = (root.Position - killer.Position).Unit
            if dir.Magnitude < 0.1 then dir = Vector3.new(1, 0, 0) end
            local escapePos = root.Position + (dir * CONFIG.ESCAPE_DIR_MULTIPLIER)
            smartMove(escapePos, 2)
        end
        return
    end

    -- Safe - try exits
    if #openExits > 0 then
        local bestExit = nil
        local bestExitDist = math.huge
        for _, ce in ipairs(openExits) do
            if not killerPos or (Vector3.new(ce.Position.X, 0, ce.Position.Z) - Vector3.new(killerPos.X, 0, killerPos.Z)).Magnitude > CONFIG.SAFE_EXIT_DIST_FROM_KILLER then
                local d = (root.Position - ce.Position).Magnitude
                if d < bestExitDist then
                    bestExitDist = d
                    bestExit = ce
                end
            end
        end
        if bestExit then
            setStatus("Escaping!")
            smartMove(bestExit.Position, 0.5)
            return
        end
    end

    -- Collect loot
    if State.CurrentLoot and State.CurrentLoot.Parent and State.CurrentLoot.Transparency < 0.9 then
        setStatus("Looting")
        local reached = smartMove(State.CurrentLoot.Position, 0.5)
        if reached then
            interactWithPrompt(State.CurrentLoot)
            State.CurrentLoot = nil
        end
        return
    else
        State.CurrentLoot = nil
    end

    local safeLoot = getSafeLoot(killerPos, root.Position)
    if #safeLoot > 0 then
        State.CurrentLoot = safeLoot[1].obj
        setStatus("Loot: " .. safeLoot[1].value)
        return
    end

    -- Wander
    if not State.MapWanderTarget or (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(State.MapWanderTarget.X, 0, State.MapWanderTarget.Z)).Magnitude < 5 or (now - State.LastWanderTime > 10) then
        local nodes = getSafeNodes()
        if #nodes > 0 then
            State.MapWanderTarget = nodes[math.random(1, #nodes)]
        else
            State.MapWanderTarget = root.Position + Vector3.new(math.random(-25, 25), 0, math.random(-25, 25))
        end
        State.LastWanderTime = now
    end
    if State.MapWanderTarget then
        setStatus("Wandering")
        smartMove(State.MapWanderTarget, 2)
    end
end

local function logicKiller(root, hum)
    local targetSurv = nil
    local sDist = math.huge
    local now = tick()

    -- Find closest survivor
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

    -- Equip tool
    local tool = LP.Character:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LP.Backpack:FindFirstChildOfClass("Tool")
        if bp then hum:EquipTool(bp) end
    end

    if targetSurv then
        setStatus("Chasing: " .. math.floor(sDist) .. "m")
        smartMove(targetSurv.Position, 2)
        if sDist < CONFIG.ATTACK_RANGE and tool then
            if now - State.LastAttack > CONFIG.ATTACK_COOLDOWN then
                tool:Activate()
                State.LastAttack = now
            end
        end
        return
    end

    -- Check lockers for hiding survivors
    if now - State.ActionDelay > CONFIG.LOCKER_CHECK_COOLDOWN then
        local lockers = getLockerModels()
        local bestLocker, bestLockerDist = nil, math.huge
        local rootPos2D = Vector3.new(root.Position.X, 0, root.Position.Z)

        for _, cl in ipairs(lockers) do
            if not cl or not cl.Parent then continue end
            local clPos = cl:IsA("Model") and (cl.PrimaryPart and cl.PrimaryPart.Position or cl:GetModelCFrame().Position) or cl.Position
            local clPos2D = Vector3.new(clPos.X, 0, clPos.Z)
            local d = (rootPos2D - clPos2D).Magnitude
            if d < bestLockerDist then
                bestLockerDist = d
                bestLocker = cl
            end
        end

        if bestLocker then
            local targetPos = bestLocker:IsA("Model") and (bestLocker.PrimaryPart and bestLocker.PrimaryPart.Position or bestLocker:GetModelCFrame().Position) or bestLocker.Position
            local reached = smartMove(targetPos, 3)
            if reached then
                if tool and now - State.LastAttack > 0.8 then
                    tool:Activate()
                    State.LastAttack = now
                    State.ActionDelay = now
                end
            end
            return
        end
    end

    -- Wander
    if not State.MapWanderTarget or (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(State.MapWanderTarget.X, 0, State.MapWanderTarget.Z)).Magnitude < 5 or (now - State.LastWanderTime > 8) then
        local map = getCachedMap()
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
            State.MapWanderTarget = root.Position + Vector3.new(math.random(-25, 25), 0, math.random(-25, 25))
        end
        State.LastWanderTime = now
    end
    if State.MapWanderTarget then
        setStatus("Searching")
        smartMove(State.MapWanderTarget, 2)
    end
end

-- ==================== UI HANDLERS ====================
btn.MouseButton1Click:Connect(function()
    AutoSH_Enabled = not AutoSH_Enabled
    if AutoSH_Enabled then
        btn.Text = "Auto SH: ON"
        btn.TextColor3 = Color3.fromRGB(46, 255, 113)
        stroke.Color = Color3.fromRGB(46, 255, 113)

        State.LobbyTarget = nil
        State.IsHiding = false
        State.TargetLocker = nil
        State.CurrentLoot = nil
        State.MapWanderTarget = nil
        State.CurrentTeam = getTeam(LP)
        State.LastWanderTime = 0
        State.AvoidanceDir = nil

        PathData.Path = nil
        PathData.CurrentMoveTarget = nil
        PathData.StuckCount = 0
        PathData.LastPos = Vector3.new()
        PathData.LastPosTime = 0
    else
        btn.Text = "Auto SH: OFF"
        btn.TextColor3 = Color3.fromRGB(255, 80, 80)
        stroke.Color = Color3.fromRGB(13, 139, 255)

        PathData.Path = nil
        PathData.CurrentMoveTarget = nil
        if PathData.PathBlockedConn then
            PathData.PathBlockedConn:Disconnect()
            PathData.PathBlockedConn = nil
        end

        local c = LP.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h and c and c:FindFirstChild("HumanoidRootPart") then
            h:MoveTo(c.HumanoidRootPart.Position)
        end
    end
end)

-- ==================== MAIN LOOP ====================
task.spawn(function()
    while task.wait(CONFIG.UPDATE_RATE) do
        if AutoSH_Enabled then
            local success, err = pcall(function()
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
                        State.TargetLocker = nil
                        State.CurrentLoot = nil
                        State.MapWanderTarget = nil
                        PathData.Path = nil
                        PathData.CurrentMoveTarget = nil
                        PathData.StuckCount = 0
                    end

                    if team == "lobby" then
                        logicLobby(root, hum)
                    elseif team == "survivor" then
                        logicSurvivor(root, hum)
                    elseif team == "killer" then
                        logicKiller(root, hum)
                    else
                        setStatus("Unknown team")
                    end
                else
                    setStatus("No character")
                end
            end)

            if not success then
                warn("AutoSH Error: " .. tostring(err))
                setStatus("Error!")
            end
        end
    end
end)

-- Cleanup on death
LP.CharacterRemoving:Connect(function()
    if AutoSH_Enabled then
        PathData.Path = nil
        PathData.CurrentMoveTarget = nil
        if PathData.PathBlockedConn then
            PathData.PathBlockedConn:Disconnect()
            PathData.PathBlockedConn = nil
        end
    end
end)

print("AutoSH Improved v2.0 Loaded Successfully!")
print("Features: Wall Avoidance, Smart Pathfinding, Stuck Detection, Caching System")
