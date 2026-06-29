local Sv = {
    Players = game:GetService("Players"),
    PathfindingService = game:GetService("PathfindingService"),
    CoreGui = game:GetService("CoreGui"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService")
}

local LP = Sv.Players.LocalPlayer
local AutoSH_Enabled = false

local CONFIG = {
    STOP_DISTANCE = 2.5,
    WAYPOINT_SPACING = 2,
    AGENT_RADIUS = 2.5,
    AGENT_HEIGHT = 5,
    JUMP_COOLDOWN = 0.3,
    STUCK_THRESHOLD = 0.5,
    STUCK_RESET_TIME = 0.3,
    MAX_STUCK_COUNT = 2,
    PATH_RECOMPUTE_TIME = 0.8,
    PATH_TIMEOUT = 6,
    WALL_AVOIDANCE_DIST = 8,
    KILLER_DETECT_RANGE = 80,
    KILLER_FLEE_START = 50,
    KILLER_CAUTION = 40,
    KILLER_DANGER = 25,
    KILLER_CRITICAL = 15,
    HIDE_DIST_TO_KILLER = 60,
    SAFE_EXIT_DIST_FROM_KILLER = 40,
    LOCKER_SEARCH_RANGE = 20,
    LOOT_SAFE_DIST_FROM_KILLER = 50,
    LOOT_COLLECT_DIST = 2,
    ESCAPE_DIR_MULTIPLIER = 60,
    ATTACK_RANGE = 12,
    ATTACK_COOLDOWN = 0.6,
    LOCKER_CHECK_COOLDOWN = 5,
    UPDATE_RATE = 0.08,
    CACHE_DURATION = 3,
    WALL_CHECK_DIST = 4,
    WALL_AVOID_ANGLE = 45,
    PATH_SMOOTHING = true,
    MIN_MOVE_DIST = 0.3,
    STUCK_JUMP_COOLDOWN = 1.5,
    KILLER_CHASE_SPEED = 20,
    KILLER_WANDER_SPEED = 16
}

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
    PathTimeout = 0,
    LastPathComputePos = nil,
    PathComputeCooldown = 0
}

local State = {
    IsHiding = false,
    LobbyTarget = nil,
    LastJump = 0,
    ActionDelay = 0,
    TargetLocker = nil,
    MapWanderTarget = nil,
    CurrentTeam = "",
    LastAttack = 0,
    LastWanderTime = 0,
    IsStuck = false,
    LastDirChange = 0,
    AvoidanceDir = nil,
    LastStuckJump = 0,
    ConsecutiveStuck = 0,
    LastTargetPos = nil
}

local KillerData = {
    Player = nil,
    Root = nil,
    Position = nil,
    Distance = math.huge,
    LastUpdate = 0,
    Velocity = Vector3.new()
}

local CurrentLootData = nil

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
sg.Name = "AutoSH"
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

local function setStatus(text)
    statusLabel.Text = string.sub(text, 1, 20)
end

local function getTeam(player)
    if not player then return "lobby" end
    local team = player.Team
    if not team then return "lobby" end
    local t = string.lower(team.Name)
    if string.find(t, "survivor") or string.find(t, "innocent") or string.find(t, "hider") or string.find(t, "player") then return "survivor" end
    if string.find(t, "killer") or string.find(t, "slasher") or string.find(t, "hunter") then return "killer" end
    if string.find(t, "lobby") or string.find(t, "waiting") then return "lobby" end
    return "lobby"
end

local function isKiller(player)
    if player == LP then return false end
    if not player then return false end
    local team = player.Team
    if not team then return false end
    local t = string.lower(team.Name)
    if t == "killer" or string.find(t, "^killer") or string.find(t, "slasher") or string.find(t, "hunter") then return true end
    if string.find(t, "survivor") or string.find(t, "innocent") or string.find(t, "lobby") or string.find(t, "hider") or string.find(t, "waiting") then return false end
    local myTeam = LP.Team
    if myTeam then
        local mt = string.lower(myTeam.Name)
        if string.find(mt, "survivor") or string.find(mt, "innocent") or string.find(mt, "hider") then return team ~= myTeam end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════
-- إصلاح 1: دالة isPlayerDowned المحسّنة
-- ═══════════════════════════════════════════════════════════════
local function isPlayerDowned(player)
    if not player then return false end
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    -- اللاعب ميت تماماً
    if hum.Health <= 0 and hum.MaxHealth > 0 then return false end
    -- اللاعب محمي (ForceField)
    if char:FindFirstChildOfClass("ForceField") then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    -- التحقق من BleedOutHealth (الطريقة الأكثر شيوعاً)
    local boh = root:FindFirstChild("BleedOutHealth")
    if boh then
        if boh:IsA("BoolValue") and boh.Value == true then return true end
        if boh:IsA("NumberValue") and boh.Value > 0 then return true end
        if boh:IsA("IntValue") and boh.Value > 0 then return true end
        -- بعض الألعاب تستخدم Enabled بدلاً من Value
        if boh:IsA("BoolValue") and boh.Enabled == true then return true end
    end

    -- التحقق من Downed
    local dv = char:FindFirstChild("Downed")
    if dv then
        if dv:IsA("BoolValue") and dv.Value == true then return true end
        if dv:IsA("IntValue") and dv.Value > 0 then return true end
        if dv:IsA("NumberValue") and dv.Value > 0 then return true end
    end

    -- التحقق من Incapacitated
    local inc = char:FindFirstChild("Incapacitated")
    if inc then
        if inc:IsA("BoolValue") and inc.Value == true then return true end
        if inc:IsA("IntValue") and inc.Value > 0 then return true end
        if inc:IsA("NumberValue") and inc.Value > 0 then return true end
    end

    -- التحقق من Ragdolled
    local rag = char:FindFirstChild("Ragdolled")
    if rag then
        if rag:IsA("BoolValue") and rag.Value == true then return true end
    end

    -- التحقق من حالة Humanoid
    local state = hum:GetState()
    if (state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.GettingUp) and hum.WalkSpeed < 5 then
        return true
    end

    -- التحقق من السرعة المنخفضة جداً مع وجود صحة
    if hum.WalkSpeed < 3 and hum.Health > 0 and hum.Health < hum.MaxHealth then
        return true
    end

    return false
end

local function getMap()
    for _, obj in ipairs(Sv.Workspace:GetChildren()) do
        if (obj:IsA("Model") or obj:IsA("Folder")) and obj ~= LP.Character then
            local n = string.lower(obj.Name)
            if not string.find(n, "lobby") and not string.find(n, "spawn") and not Sv.Players:GetPlayerFromCharacter(obj) then
                if string.find(n, "map") or obj:FindFirstChild("LootSpawns", true) or obj:FindFirstChild("Exits", true) or obj:FindFirstChild("Lockers", true) then
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
        if obj and obj.Parent then
            local objPos = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetModelCFrame().Position) or obj.Position
            local objPos2D = Vector3.new(objPos.X, 0, objPos.Z)
            local d = (pos2D - objPos2D).Magnitude
            if d < minDist then
                minDist = d
                closest = obj
            end
        end
    end
    return closest, minDist
end

local Cache = {
    LootValue = setmetatable({}, {__mode = "k"}),
    Lockers = {models = {}, time = 0},
    Exits = {list = {}, time = 0},
    Map = {obj = nil, time = 0}
}

local function getCachedMap()
    local now = tick()
    if Cache.Map.obj and (now - Cache.Map.time < CONFIG.CACHE_DURATION) and Cache.Map.obj.Parent then
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
        if c and c.Parent then
            if c:IsA("ProximityPrompt") then
                local at = c:GetAttribute("ActionText")
                if at and type(at) == "string" then
                    local n = string.match(at, "(%d+)")
                    if n then fallback = tonumber(n); break end
                end
                local txt = (c.ActionText or "") .. " " .. (c.ObjectText or "")
                local n = string.match(txt, "(%d+)") or string.match(txt, "(%d+)%s*[Cc]oin") or string.match(txt, "(%d+)%s*[Gg]old") or string.match(txt, "(%d+)%s*[Pp]oint")
                if n then fallback = tonumber(n); break end
            elseif c:IsA("ClickDetector") then
                local at = c:GetAttribute("ActionText")
                if at and type(at) == "string" then
                    local n = string.match(at, "(%d+)")
                    if n then fallback = tonumber(n); break end
                end
            elseif c:IsA("TextLabel") or c:IsA("TextButton") then
                local n = string.match(c.Text, "(%d+)")
                if n then fallback = tonumber(n); break end
            elseif (c:IsA("IntValue") or c:IsA("NumberValue")) and not fallback then
                fallback = c.Value
            elseif c:IsA("StringValue") and not fallback then
                local n = tonumber(c.Value)
                if n then fallback = n end
            end
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

-- ═══════════════════════════════════════════════════════════════
-- إصلاح 4: جلب الـ Loot بالترتيب حسب الأقرب (بدلاً من الأعلى قيمة)
-- ═══════════════════════════════════════════════════════════════
local function getSafeLoot(killerPos, rootPos)
    local lootList = {}
    local map = getCachedMap()
    local lf = map and map:FindFirstChild("LootSpawns", true) or Sv.Workspace:FindFirstChild("LootSpawns", true)
    if not lf then return lootList end
    for _, obj in ipairs(lf:GetDescendants()) do
        if obj and obj.Parent then
            local target = nil
            local prompt = nil
            if obj:IsA("BasePart") then
                target = obj
                for _, d in ipairs(obj:GetDescendants()) do
                    if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
                        prompt = d
                        break
                    end
                end
            elseif obj:IsA("Model") then
                target = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                if target then
                    for _, d in ipairs(obj:GetDescendants()) do
                        if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
                            prompt = d
                            break
                        end
                    end
                end
            elseif obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
                local parent = obj.Parent
                if parent then
                    if parent:IsA("BasePart") then
                        target = parent
                        prompt = obj
                    elseif parent:IsA("Model") then
                        target = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true)
                        prompt = obj
                    end
                end
            end
            if target and target.Transparency < 0.9 and prompt then
                local distToKiller = math.huge
                if killerPos then
                    distToKiller = (Vector3.new(target.Position.X, 0, target.Position.Z) - Vector3.new(killerPos.X, 0, killerPos.Z)).Magnitude
                end
                if distToKiller > CONFIG.LOOT_SAFE_DIST_FROM_KILLER then
                    local val = getLootValue(obj)
                    if not val then
                        val = getLootValue(target)
                    end
                    if val and val >= 1 and val ~= 20 then
                        local dist = (Vector3.new(target.Position.X, 0, target.Position.Z) - Vector3.new(rootPos.X, 0, rootPos.Z)).Magnitude
                        table.insert(lootList, {obj = target, src = prompt, value = val, distance = dist})
                    end
                end
            end
        end
    end
    -- ترتيب حسب الأقرب أولاً (بدلاً من الأعلى قيمة)
    table.sort(lootList, function(a, b)
        return a.distance < b.distance
    end)
    return lootList
end

local function getOpenExits()
    local now = tick()
    if now - Cache.Exits.time < CONFIG.CACHE_DURATION and #Cache.Exits.list > 0 then
        local valid = true
        for _, e in ipairs(Cache.Exits.list) do
            if not e or not e.Parent then valid = false; break end
        end
        if valid then return Cache.Exits.list end
    end
    local exits = {}
    local map = getCachedMap()
    if not map then Cache.Exits.time = now; Cache.Exits.list = exits; return exits end
    local f = map:FindFirstChild("Exits", true)
    if not f then Cache.Exits.time = now; Cache.Exits.list = exits; return exits end
    for _, exitObj in ipairs(f:GetChildren()) do
        if exitObj and exitObj.Parent then
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
    Cache.Exits.list = exits
    Cache.Exits.time = now
    return exits
end

local function getLockerModels()
    local now = tick()
    if now - Cache.Lockers.time < CONFIG.CACHE_DURATION and #Cache.Lockers.models > 0 then
        local valid = true
        for _, m in ipairs(Cache.Lockers.models) do
            if not m or not m.Parent then valid = false; break end
        end
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
                local n = string.lower(obj.Name)
                for _, kw in ipairs({"locker", "wardrobe", "cabinet", "closet", "hideout", "armoire", "coffin", "chest"}) do
                    if string.find(n, kw) then
                        seen[obj] = true
                        table.insert(models, obj)
                        break
                    end
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

local function interactWithPrompt(obj, src)
    if not obj or not obj.Parent then return end
    if src and src.Parent then
        if src:IsA("ProximityPrompt") and src.Enabled then
            pcall(function()
                local oldLos = src.RequiresLineOfSight
                local oldMax = src.MaxActivationDistance
                local oldHold = src.HoldDuration
                src.RequiresLineOfSight = false
                src.MaxActivationDistance = 50
                src.HoldDuration = 0
                fireproximityprompt(src)
                task.delay(0.3, function()
                    if src and src.Parent then
                        src.RequiresLineOfSight = oldLos
                        src.MaxActivationDistance = oldMax
                        src.HoldDuration = oldHold
                    end
                end)
            end)
        elseif src:IsA("ClickDetector") then
            pcall(function() fireclickdetector(src, 0) end)
        end
    end
    for _, c in ipairs(obj:GetDescendants()) do
        if c and c.Parent then
            if c:IsA("ProximityPrompt") and c.Enabled then
                pcall(function()
                    local oldLos = c.RequiresLineOfSight
                    local oldMax = c.MaxActivationDistance
                    local oldHold = c.HoldDuration
                    c.RequiresLineOfSight = false
                    c.MaxActivationDistance = 50
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
end

local function handleTraps(char, hum)
    if not char or not hum then return end
    local now = tick()
    for _, v in ipairs(char:GetDescendants()) do
        if v and v.Parent then
            if v:IsA("ProximityPrompt") and v.Enabled then
                pcall(function() fireproximityprompt(v) end)
            elseif v:IsA("ClickDetector") then
                pcall(function() fireclickdetector(v, 0) end)
            end
        end
    end
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        if now - State.LastJump > 0.5 then
            State.LastJump = now
            hum.Jump = true
        end
    end
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

-- ═══════════════════════════════════════════════════════════════
-- إصلاح 4: تحسين تجنب الجدران بشكل ذكي جداً
-- ═══════════════════════════════════════════════════════════════
local function getWallAvoidanceDirection(root, targetPos)
    local char = LP.Character
    if not char then return nil end
    local rootPos = root.Position
    local forward = (targetPos - rootPos).Unit
    if forward.Magnitude < 0.1 then forward = root.CFrame.LookVector end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true

    -- فحص الاتجاه الأمامي
    local forwardRay = Sv.Workspace:Raycast(rootPos, forward * CONFIG.WALL_AVOIDANCE_DIST, rayParams)
    if not forwardRay then return nil end
    if forwardRay.Instance then
        if not forwardRay.Instance.CanCollide or forwardRay.Instance.Transparency > 0.7 then
            return nil
        end
        local wallHeight = forwardRay.Instance.Size and forwardRay.Instance.Size.Y or 10
        if wallHeight > CONFIG.AGENT_HEIGHT * 0.6 then
            -- فحص زوايا متعددة للعثور على أفضل اتجاه
            local bestDir = nil
            local bestScore = -math.huge
            local angles = {-90, -75, -60, -45, -30, -15, 15, 30, 45, 60, 75, 90}

            for _, angle in ipairs(angles) do
                local rad = math.rad(angle)
                local dir = Vector3.new(
                    forward.X * math.cos(rad) - forward.Z * math.sin(rad),
                    0,
                    forward.X * math.sin(rad) + forward.Z * math.cos(rad)
                ).Unit

                local testPos = rootPos + (dir * CONFIG.WALL_AVOIDANCE_DIST)
                local ray = Sv.Workspace:Raycast(rootPos, (testPos - rootPos), rayParams)
                local clearDist = CONFIG.WALL_AVOIDANCE_DIST
                if ray and ray.Instance and ray.Instance.CanCollide then
                    clearDist = (ray.Position - rootPos).Magnitude * 0.8
                end

                -- حساب النتيجة: المسافة الصافية + قرب الاتجاه من الهدف
                local toTarget = (targetPos - rootPos).Unit
                local alignment = dir:Dot(toTarget)
                local score = clearDist + alignment * 5

                if score > bestScore then
                    bestScore = score
                    bestDir = dir
                end
            end

            return bestDir
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- إصلاح 4: تحسين كشف الالتصاق (Stuck Detection)
-- ═══════════════════════════════════════════════════════════════
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
            State.ConsecutiveStuck = State.ConsecutiveStuck + 1
            return true
        end
    else
        PathData.StuckCount = 0
        State.ConsecutiveStuck = 0
    end
    PathData.LastPos = root.Position
    PathData.LastPosTime = now
    return false
end

-- ═══════════════════════════════════════════════════════════════
-- إصلاح 4: تحسين smartMove لمنع الالتصاق بالجدران
-- ═══════════════════════════════════════════════════════════════
local function smartMove(targetPos, stopDistance, avoidPos)
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

    -- تجنب القاتل
    if avoidPos then
        local distNow = (rootPos - avoidPos).Magnitude
        local distTarget = (targetPos - avoidPos).Magnitude
        if distTarget < distNow - 3 then
            local awayDir = (targetPos - avoidPos).Unit
            targetPos = avoidPos + (awayDir * math.max(distNow + 15, 60))
            targetPos2D = Vector3.new(targetPos.X, 0, targetPos.Z)
            distToTarget = (rootPos2D - targetPos2D).Magnitude
            PathData.Path = nil
            if PathData.PathBlockedConn then
                PathData.PathBlockedConn:Disconnect()
                PathData.PathBlockedConn = nil
            end
        end
    end

    -- كشف الالتصاق المحسّن
    if checkStuck(root) then
        State.IsStuck = true
        PathData.Path = nil
        PathData.CurrentMoveTarget = nil
        if PathData.PathBlockedConn then
            PathData.PathBlockedConn:Disconnect()
            PathData.PathBlockedConn = nil
        end

        -- قفزة ذكية لتجاوز العائق
        if now - State.LastStuckJump > CONFIG.STUCK_JUMP_COOLDOWN then
            State.LastStuckJump = now
            hum.Jump = true
        end

        -- اتجاه هروب عشوائي ذكي (بعيداً عن الجدران)
        local escapeAngles = {0, 45, -45, 90, -90, 135, -135, 180}
        local bestEscape = nil
        local bestEscapeDist = 0
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {char}
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist

        for _, angle in ipairs(escapeAngles) do
            local rad = math.rad(angle)
            local dir = Vector3.new(math.cos(rad), 0, math.sin(rad))
            local testRay = Sv.Workspace:Raycast(rootPos, dir * 15, rayParams)
            local clearDist = 15
            if testRay and testRay.Instance and testRay.Instance.CanCollide then
                clearDist = (testRay.Position - rootPos).Magnitude * 0.7
            end
            if clearDist > bestEscapeDist then
                bestEscapeDist = clearDist
                bestEscape = rootPos + (dir * math.min(clearDist, 12))
            end
        end

        if bestEscape then
            hum:MoveTo(bestEscape)
            PathData.LastStuckTime = now
        end
        return false
    else
        State.IsStuck = false
    end

    -- تجنب الجدران بشكل استباقي
    local avoidanceDir = getWallAvoidanceDirection(root, targetPos)
    if avoidanceDir then
        State.AvoidanceDir = avoidanceDir
        State.LastDirChange = now
        local targetDir = (targetPos - rootPos).Unit
        local blendedDir = (targetDir + avoidanceDir * 2).Unit
        local avoidPos2 = rootPos + (blendedDir * math.min(distToTarget, 15))
        PathData.Path = nil
        PathData.CurrentMoveTarget = avoidPos2
        hum:MoveTo(avoidPos2)

        -- قفزة ذكية فوق العوائق الصغيرة
        if now - State.LastJump > CONFIG.JUMP_COOLDOWN then
            local closeRayParams = RaycastParams.new()
            closeRayParams.FilterDescendantsInstances = {char}
            closeRayParams.FilterType = Enum.RaycastFilterType.Blacklist
            local closeRay = Sv.Workspace:Raycast(rootPos, (targetPos - rootPos).Unit * 3, closeRayParams)
            if closeRay and closeRay.Instance and closeRay.Instance.CanCollide and closeRay.Instance.Size.Y < CONFIG.AGENT_HEIGHT * 0.5 then
                State.LastJump = now
                hum.Jump = true
            end
        end
        return false
    elseif State.AvoidanceDir and (now - State.LastDirChange < 0.6) then
        local targetDir = (targetPos - rootPos).Unit
        local blendedDir = (targetDir + State.AvoidanceDir).Unit
        local avoidPos2 = rootPos + (blendedDir * math.min(distToTarget, 12))
        PathData.CurrentMoveTarget = avoidPos2
        hum:MoveTo(avoidPos2)
        return false
    else
        State.AvoidanceDir = nil
    end

    -- التحقق من خط الرؤية المباشر
    local hasLOS = false
    if distToTarget < 60 then
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

    -- إعادة حساب المسار
    local needsRecompute = false
    if not PathData.Path then needsRecompute = true end
    if PathData.TargetPos and (Vector3.new(PathData.TargetPos.X, 0, PathData.TargetPos.Z) - targetPos2D).Magnitude > 3 then needsRecompute = true end
    if now - PathData.LastCompute > CONFIG.PATH_RECOMPUTE_TIME then needsRecompute = true end
    if now - PathData.PathTimeout > CONFIG.PATH_TIMEOUT then needsRecompute = true end

    -- منع إعادة الحساب المتكررة في نفس المكان
    if PathData.LastPathComputePos and (rootPos - PathData.LastPathComputePos).Magnitude < 2 and (now - PathData.PathComputeCooldown < 1) then
        needsRecompute = false
    end

    if needsRecompute then
        PathData.TargetPos = targetPos
        PathData.LastCompute = now
        PathData.PathTimeout = now
        PathData.LastPathComputePos = rootPos
        PathData.PathComputeCooldown = now
        if PathData.PathBlockedConn then
            PathData.PathBlockedConn:Disconnect()
            PathData.PathBlockedConn = nil
        end

        -- حساب المسار من موقع الأقدام (إصلاح الالتصاق)
        local computeStart = rootPos - Vector3.new(0, root.Size.Y * 0.3, 0)
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
        local success, err = pcall(function() path:ComputeAsync(computeStart, targetPos) end)
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

    -- متابعة النقاط
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

local function updateKillerData(root)
    local now = tick()
    local closestKiller = nil
    local closestDist = math.huge
    local closestPos = nil
    local closestRoot = nil
    for _, p in ipairs(Sv.Players:GetPlayers()) do
        if isKiller(p) and p.Character then
            local pr = p.Character:FindFirstChild("HumanoidRootPart")
            if pr then
                local d = (root.Position - pr.Position).Magnitude
                if d < closestDist then
                    closestDist = d
                    closestKiller = p
                    closestPos = pr.Position
                    closestRoot = pr
                end
            end
        end
    end
    if closestKiller then
        if KillerData.Position and KillerData.LastUpdate > 0 then
            local dt = math.max(now - KillerData.LastUpdate, 0.001)
            KillerData.Velocity = (closestPos - KillerData.Position) / dt
        end
        KillerData.Player = closestKiller
        KillerData.Root = closestRoot
        KillerData.Position = closestPos
        KillerData.Distance = closestDist
        KillerData.LastUpdate = now
    else
        KillerData.Player = nil
        KillerData.Root = nil
        KillerData.Position = nil
        KillerData.Distance = math.huge
    end
    return closestKiller, closestDist, closestPos, closestRoot
end

local function getFleeLevel(kDist)
    if kDist < CONFIG.KILLER_CRITICAL then return 4 end
    if kDist < CONFIG.KILLER_DANGER then return 3 end
    if kDist < CONFIG.KILLER_CAUTION then return 2 end
    if kDist < CONFIG.KILLER_FLEE_START then return 1 end
    return 0
end

local function getEscapeTarget(root, killerPos, level)
    local char = LP.Character
    if not char then return root.Position + Vector3.new(50, 0, 0) end
    local awayDir = (root.Position - killerPos).Unit
    if awayDir.Magnitude < 0.1 then awayDir = Vector3.new(1, 0, 0) end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true
    local bestPos = nil
    local bestScore = -math.huge
    local angleStep = 15
    if level >= 3 then angleStep = 10 end
    if level >= 4 then angleStep = 5 end
    local searchDist = CONFIG.ESCAPE_DIR_MULTIPLIER
    if level >= 4 then searchDist = 40 end
    for angle = -90, 90, angleStep do
        local rad = math.rad(angle)
        local dir = Vector3.new(
            awayDir.X * math.cos(rad) - awayDir.Z * math.sin(rad),
            0,
            awayDir.X * math.sin(rad) + awayDir.Z * math.cos(rad)
        ).Unit
        local testPos = root.Position + (dir * searchDist)
        local ray = Sv.Workspace:Raycast(root.Position, (testPos - root.Position), rayParams)
        local clearDist = searchDist
        if ray and ray.Instance and ray.Instance.CanCollide then
            clearDist = (ray.Position - root.Position).Magnitude * 0.7
        end
        local actualPos = root.Position + (dir * clearDist)
        local distFromKiller = (actualPos - killerPos).Magnitude
        local distGain = distFromKiller - (root.Position - killerPos).Magnitude
        local score = distFromKiller + clearDist * 0.3 + distGain * 3
        if level >= 3 then
            score = score + distGain * 5
        end
        if score > bestScore then
            bestScore = score
            bestPos = actualPos
        end
    end
    return bestPos or (root.Position + (awayDir * 30))
end

local function doFlee(root, hum, killerPos, level)
    local now = tick()
    if level >= 4 then
        local target = getEscapeTarget(root, killerPos, level)
        hum:MoveTo(target)
        PathData.Path = nil
        PathData.CurrentMoveTarget = target
        if now - State.LastJump > 0.2 then
            State.LastJump = now
            hum.Jump = true
        end
        local lockers = getLockerModels()
        local bestLocker = nil
        local bestDist = math.huge
        for _, cl in ipairs(lockers) do
            if cl and cl.Parent then
                local clPos = cl:IsA("Model") and (cl.PrimaryPart and cl.PrimaryPart.Position or cl:GetModelCFrame().Position) or cl.Position
                local d = (root.Position - clPos).Magnitude
                if d < bestDist and d < 15 then
                    bestDist = d
                    bestLocker = cl
                end
            end
        end
        if bestLocker and bestDist < 12 then
            local targetPos = bestLocker:IsA("Model") and (bestLocker.PrimaryPart and bestLocker.PrimaryPart.Position or bestLocker:GetModelCFrame().Position) or bestLocker.Position
            hum:MoveTo(targetPos)
            if bestDist < 3 then
                interactWithPrompt(bestLocker)
                State.IsHiding = true
                State.TargetLocker = bestLocker
            end
        end
        setStatus("FLEE " .. math.floor(KillerData.Distance) .. "m")
        return true
    elseif level >= 2 then
        local target = getEscapeTarget(root, killerPos, level)
        smartMove(target, 3, killerPos)
        setStatus("FLEE " .. math.floor(KillerData.Distance) .. "m")
        return true
    elseif level >= 1 then
        setStatus("CAUTION " .. math.floor(KillerData.Distance) .. "m")
        return false
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════
-- إصلاح 3: تحسين منطق Lobby
-- ═══════════════════════════════════════════════════════════════
local function logicLobby(root, hum)
    setStatus("Lobby")
    local now = tick()

    -- اختيار إحداثية عشوائية والذهاب إليها
    if not State.LobbyTarget or (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(State.LobbyTarget.X, 0, State.LobbyTarget.Z)).Magnitude < 3 then
        State.LobbyTarget = LOBBY_COORDS[math.random(1, #LOBBY_COORDS)]
    end

    local reached = smartMove(State.LobbyTarget, 2)
    if reached then
        -- الوقوف في المكان والقفز كل 20 ثانية فقط
        if now - State.LastJump > 20 then
            State.LastJump = now
            hum.Jump = true
        end
        -- اختيار إحداثية جديدة
        State.LobbyTarget = LOBBY_COORDS[math.random(1, #LOBBY_COORDS)]
    end
end

-- ═══════════════════════════════════════════════════════════════
-- إصلاح 4: تحسين منطق Survivor
-- ═══════════════════════════════════════════════════════════════
local function logicSurvivor(root, hum)
    local now = tick()
    local killer, kDist, killerPos, killerRoot = updateKillerData(root)
    local fleeLevel = getFleeLevel(kDist)

    -- إذا كان اللاعب ساقطاً
    if isPlayerDowned(LP) then
        setStatus("Downed")
        State.IsHiding = false
        State.TargetLocker = nil
        CurrentLootData = nil

        -- الذهاب لأقرب مخرج آمن
        local openExits = getOpenExits()
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
            smartMove(bestExit.Position, 1, killerPos)
            return
        end

        -- الذهاب لأقرب لاعب حي
        local upSurvs = {}
        for _, p in ipairs(Sv.Players:GetPlayers()) do
            if p ~= LP and getTeam(p) == "survivor" and not isPlayerDowned(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(upSurvs, p.Character.HumanoidRootPart)
            end
        end
        if #upSurvs > 0 then
            local cs = getClosest(upSurvs, root.Position)
            if cs then
                smartMove(cs.Position, 2, killerPos)
                return
            end
        end

        -- التجوال العشوائي
        if not State.MapWanderTarget or (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(State.MapWanderTarget.X, 0, State.MapWanderTarget.Z)).Magnitude < 5 then
            local nodes = getSafeNodes()
            if #nodes > 0 then
                State.MapWanderTarget = nodes[math.random(1, #nodes)]
            else
                State.MapWanderTarget = root.Position + Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
            end
        end
        if State.MapWanderTarget then
            smartMove(State.MapWanderTarget, 2, killerPos)
        end
        return
    end

    -- إذا كان مختبئاً
    if State.IsHiding then
        if fleeLevel == 0 then
            setStatus("Safe")
            State.IsHiding = false
            State.TargetLocker = nil
            hum.Jump = true
            local forwardVec = root.CFrame.LookVector * 8
            hum:MoveTo(root.Position + forwardVec)
            task.wait(0.3)
        else
            setStatus("Hide")
            PathData.CurrentMoveTarget = nil
            hum:MoveTo(root.Position)
            return
        end
    end

    -- الهروب من القاتل
    if fleeLevel >= 1 then
        local fled = doFlee(root, hum, killerPos, fleeLevel)
        if fled then return end
    end

    -- الذهاب للمخرج المفتوح
    local openExits = getOpenExits()
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
            setStatus("Exit")
            smartMove(bestExit.Position, 0.5, killerPos)
            return
        end
    end

    -- جمع الـ Loot (الأقرب أولاً)
    if CurrentLootData and CurrentLootData.obj and CurrentLootData.obj.Parent and CurrentLootData.obj.Transparency < 0.9 then
        setStatus("Loot")
        local reached = smartMove(CurrentLootData.obj.Position, CONFIG.LOOT_COLLECT_DIST, killerPos)
        if reached then
            interactWithPrompt(CurrentLootData.obj, CurrentLootData.src)
            task.wait(0.2)
            CurrentLootData = nil
        end
        return
    else
        CurrentLootData = nil
    end

    -- البحث عن أقرب Loot آمن
    local safeLoot = getSafeLoot(killerPos, root.Position)
    if #safeLoot > 0 then
        CurrentLootData = {obj = safeLoot[1].obj, src = safeLoot[1].src}
        setStatus("Loot " .. safeLoot[1].value)
        return
    end

    -- التجوال العشوائي
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
        setStatus("Wander")
        smartMove(State.MapWanderTarget, 2, killerPos)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- إصلاح 2: تحسين منطق Killer (بدون تفتيش خزائن، مسارات دقيقة)
-- ═══════════════════════════════════════════════════════════════
local function logicKiller(root, hum)
    local now = tick()

    -- البحث عن أقرب لاعب حي (غير ساقط) - فحص مزدوج
    local targetSurv = nil
    local sDist = math.huge
    local targetPlayer = nil

    for _, p in ipairs(Sv.Players:GetPlayers()) do
        if p ~= LP then
            local pTeam = getTeam(p)
            if pTeam == "survivor" then
                -- التحقق الأول: هل اللاعب ساقط؟
                if not isPlayerDowned(p) then
                    local pChar = p.Character
                    if pChar then
                        local pr = pChar:FindFirstChild("HumanoidRootPart")
                        local ph = pChar:FindFirstChildOfClass("Humanoid")
                        if pr and ph and ph.Health > 0 then
                            -- التحقق الثاني: هل RootPart موجود وله Parent
                            if pr.Parent then
                                local d = (root.Position - pr.Position).Magnitude
                                if d < sDist then
                                    sDist = d
                                    targetSurv = pr
                                    targetPlayer = p
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- تجهيز السلاح
    local tool = LP.Character:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LP.Backpack:FindFirstChildOfClass("Tool")
        if bp then 
            pcall(function() hum:EquipTool(bp) end)
            tool = LP.Character:FindFirstChildOfClass("Tool")
        end
    end

    if targetSurv and targetPlayer then
        -- التحقق النهائي قبل المطاردة
        if isPlayerDowned(targetPlayer) or not targetSurv.Parent then
            setStatus("Target Invalid")
            return
        end

        -- تعيين سرعة المطاردة العالية
        hum.WalkSpeed = CONFIG.KILLER_CHASE_SPEED

        setStatus("Chase " .. math.floor(sDist) .. "m")

        -- حساب موقع الهدف مع التنبؤ بالحركة
        local targetPos = targetSurv.Position
        local targetVel = targetSurv.Velocity
        local predictPos = targetPos + (targetVel * 0.2)

        -- التأكد من أن التنبؤ لا يبعد كثيراً
        if (predictPos - targetPos).Magnitude > 20 then
            predictPos = targetPos + (targetVel.Unit * 10)
        end

        -- التحريك المباشر نحو الهدف (بدون مسار معقد للقاتل)
        if sDist > 5 then
            -- استخدام MoveTo المباشر للسرعة
            hum:MoveTo(predictPos)
            PathData.CurrentMoveTarget = predictPos
        else
            -- قريب جداً - تحريك مباشر
            hum:MoveTo(targetPos)
            PathData.CurrentMoveTarget = targetPos
        end

        -- الهجوم إذا كان في النطاق
        if sDist < CONFIG.ATTACK_RANGE and tool then
            if now - State.LastAttack > CONFIG.ATTACK_COOLDOWN then
                pcall(function() tool:Activate() end)
                State.LastAttack = now
            end
        end
        return
    end

    -- لا يوجد لاعبون أحياء - الوقوف في المكان (بدون تفتيش خزائن)
    setStatus("No Targets")
    hum.WalkSpeed = CONFIG.KILLER_WANDER_SPEED
    hum:MoveTo(root.Position)
end

btn.MouseButton1Click:Connect(function()
    AutoSH_Enabled = not AutoSH_Enabled
    if AutoSH_Enabled then
        btn.Text = "Auto SH: ON"
        btn.TextColor3 = Color3.fromRGB(46, 255, 113)
        stroke.Color = Color3.fromRGB(46, 255, 113)
        State.LobbyTarget = nil
        State.IsHiding = false
        State.TargetLocker = nil
        CurrentLootData = nil
        State.MapWanderTarget = nil
        State.CurrentTeam = getTeam(LP)
        State.LastWanderTime = 0
        State.AvoidanceDir = nil
        State.ConsecutiveStuck = 0
        KillerData.Player = nil
        KillerData.Root = nil
        KillerData.Position = nil
        KillerData.Distance = math.huge
        PathData.Path = nil
        PathData.CurrentMoveTarget = nil
        PathData.StuckCount = 0
        PathData.LastPos = Vector3.new()
        PathData.LastPosTime = 0
        PathData.LastPathComputePos = nil
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
                        CurrentLootData = nil
                        State.MapWanderTarget = nil
                        PathData.Path = nil
                        PathData.CurrentMoveTarget = nil
                        PathData.StuckCount = 0
                        State.ConsecutiveStuck = 0
                    end
                    if team == "lobby" then
                        logicLobby(root, hum)
                    elseif team == "survivor" then
                        logicSurvivor(root, hum)
                    elseif team == "killer" then
                        logicKiller(root, hum)
                    else
                        setStatus("Unknown")
                    end
                else
                    setStatus("No char")
                end
            end)
            if not success then
                warn("AutoSH Error: " .. tostring(err))
                setStatus("Error")
            end
        end
    end
end)

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
