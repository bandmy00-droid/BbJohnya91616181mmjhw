local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local PathfindingService=game:GetService("PathfindingService")
local LocalPlayer=Players.LocalPlayer

local LOBBY_POINTS={
    Vector3.new(-52.5388,264.6762,10.4454),
    Vector3.new(-37.3878,260.8593,-5.1795),
    Vector3.new(-25.2802,260.8593,-20.4532),
    Vector3.new(-18.4071,260.8593,-20.2298),
    Vector3.new(-18.1125,261.1531,-2.1110),
    Vector3.new(-12.9700,260.8593,15.2693),
    Vector3.new(-11.7560,269.0895,-4.7729),
    Vector3.new(7.0312,260.8593,7.0861),
    Vector3.new(13.1345,260.8593,-12.2344),
    Vector3.new(37.4509,260.8593,-0.8731)
}

local DANGER_RADIUS=28
local HIDE_RADIUS=14
local PATROL_RADIUS=55

local running=false
local runId=0

local function getTeamType()
    local team=LocalPlayer.Team
    if not team then return "lobby" end
    local t=team.Name:lower()
    if t:find("survivor") or t:find("innocent") or t:find("hider") then return "survivor" end
    if t:find("killer") then return "killer" end
    return "lobby"
end

local function isKillerPlayer(player)
    if player==LocalPlayer then return false end
    local team=player.Team
    if not team then return false end
    local t=team.Name:lower()
    if t=="killer" or t:find("^killer") then return true end
    return false
end

local function isPlayerDowned(player)
    local char=player.Character
    if not char then return false end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health<=0 then return false end
    local root=char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local boh=root:FindFirstChild("BleedOutHealth")
    if boh and boh.Enabled then return true end
    local dv=char:FindFirstChild("Downed")
    if dv and ((dv:IsA("BoolValue") and dv.Value) or (dv:IsA("IntValue") and dv.Value>0)) then return true end
    local inc=char:FindFirstChild("Incapacitated")
    if inc and ((inc:IsA("BoolValue") and inc.Value) or (inc:IsA("IntValue") and inc.Value>0)) then return true end
    local state=hum:GetState()
    if (state==Enum.HumanoidStateType.FallingDown or state==Enum.HumanoidStateType.Ragdoll) and hum.WalkSpeed<5 then return true end
    return false
end

local function getMap()
    if getTeamType()=="lobby" then return nil end
    local children=workspace:GetChildren()
    for i=1,#children do
        local obj=children[i]
        if (obj:IsA("Model") or obj:IsA("Folder")) and obj~=LocalPlayer.Character then
            local n=obj.Name:lower()
            if not n:find("lobby") and not n:find("spawn") and not Players:GetPlayerFromCharacter(obj) then
                if n:find("map") or obj:FindFirstChild("LootSpawns",true) or obj:FindFirstChild("Exits",true) then
                    return obj
                end
            end
        end
    end
    return nil
end

local function getLockerModels()
    local map=getMap()
    local models={}
    local seen={}
    local folder=nil
    for _,name in ipairs({"Lockers","Locker","Wardrobes","Wardrobe","Cabinets","Cabinet","Hideouts","Hideout","Closets","Closet"}) do
        local f=(map and map:FindFirstChild(name,true)) or workspace:FindFirstChild(name)
        if f then folder=f; break end
    end
    if folder then
        for _,obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") and not seen[obj] then seen[obj]=true; table.insert(models,obj) end
        end
    end
    if #models==0 then
        local root=map or workspace
        for _,obj in ipairs(root:GetDescendants()) do
            if obj:IsA("Model") and not seen[obj] and obj~=LocalPlayer.Character then
                local n=obj.Name:lower()
                for _,kw in ipairs({"locker","wardrobe","cabinet","closet","hideout","armoire","coffin","chest"}) do
                    if n:find(kw) then seen[obj]=true; table.insert(models,obj); break end
                end
            end
        end
    end
    return models
end

local function getLootParts()
    local map=getMap()
    if not map then return {} end
    local folder=map:FindFirstChild("LootSpawns",true)
    if not folder then return {} end
    local parts={}
    for _,obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("BasePart") then
            table.insert(parts,obj)
        elseif obj:IsA("Model") then
            local p=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true)
            if p then table.insert(parts,p) end
        end
    end
    return parts
end

local function getExitParts()
    local map=getMap()
    if not map then return {} end
    local candidates={}
    local seen={}
    local folder=map:FindFirstChild("Exits",true)
    if folder then
        for _,obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("BasePart") and not seen[obj] then seen[obj]=true; table.insert(candidates,obj) end
        end
    end
    for _,obj in ipairs(map:GetDescendants()) do
        local n=obj.Name:lower()
        if obj:IsA("BasePart") and (n:find("exit") or n:find("gateway")) and not seen[obj] then
            seen[obj]=true; table.insert(candidates,obj)
        end
        if obj:IsA("ProximityPrompt") and obj.Parent and obj.Parent:IsA("BasePart") and not seen[obj.Parent] then
            seen[obj.Parent]=true; table.insert(candidates,obj.Parent)
        end
    end
    return candidates
end

local function findPrompt(part)
    if not part then return nil end
    local p=part:FindFirstChildWhichIsA("ProximityPrompt",true)
    if p then return p end
    if part.Parent then return part.Parent:FindFirstChildWhichIsA("ProximityPrompt",true) end
    return nil
end

local function firePrompt(prompt)
    if not prompt then return end
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt,prompt.HoldDuration or 0)
        end
    end)
end

local function unstuckNudge(hum,root)
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    local look=root.CFrame.LookVector
    local side=Vector3.new(-look.Z,0,look.X)
    if math.random(1,2)==1 then side=-side end
    pcall(function() hum:Move(side,false) end)
    task.wait(0.3)
    pcall(function() hum:Move(Vector3.new(0,0,0),false) end)
end

local function directMoveStep(hum,root,targetPos,maxTime)
    hum:MoveTo(targetPos)
    local reached=false
    local conn=hum.MoveToFinished:Connect(function(r) reached=r end)
    local start=tick()
    local lastPos=root.Position
    local stillTime=0
    local stuck=false
    while not reached and tick()-start<maxTime do
        if not running then conn:Disconnect(); return false,false end
        task.wait(0.15)
        if not root.Parent then conn:Disconnect(); return false,false end
        local moved=(root.Position-lastPos).Magnitude
        if moved<0.4 then
            stillTime=stillTime+0.15
        else
            stillTime=0
        end
        lastPos=root.Position
        if stillTime>0.7 then
            stuck=true
            break
        end
    end
    conn:Disconnect()
    return reached,stuck
end

local function computePath(fromPos,toPos)
    local path=PathfindingService:CreatePath({
        AgentRadius=2.4,AgentHeight=5,AgentCanJump=true,AgentCanClimb=true,WaypointSpacing=2.5
    })
    local ok=pcall(function() path:ComputeAsync(fromPos,toPos) end)
    if ok and path.Status==Enum.PathStatus.Success then
        return path:GetWaypoints()
    end
    return nil
end

local function walkTo(targetPos,timeout)
    local char=LocalPlayer.Character
    if not char then return false end
    local hum=char:FindFirstChildOfClass("Humanoid")
    local root=char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    local tries=0
    while tries<2 do
        tries=tries+1
        local waypoints=computePath(root.Position,targetPos)
        if not waypoints then
            local reached,stuck=directMoveStep(hum,root,targetPos,timeout or 8)
            if reached then return true end
            if stuck then unstuckNudge(hum,root) end
            if tries>=2 then return false end
        else
            local allReached=true
            local i=1
            while i<=#waypoints do
                if not running or not root.Parent then return false end
                local wp=waypoints[i]
                if wp.Action==Enum.PathWaypointAction.Jump then
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
                end
                local reached,stuck=directMoveStep(hum,root,wp.Position,3)
                if not reached then
                    if stuck then
                        unstuckNudge(hum,root)
                        task.wait(0.15)
                        local reached2=directMoveStep(hum,root,wp.Position,1.5)
                        if not reached2 then allReached=false; break end
                    else
                        allReached=false; break
                    end
                end
                i=i+1
            end
            if allReached then return true end
            if tries>=2 then return false end
        end
        task.wait(0.2)
    end
    return false
end

local function approachAndFire(part,prompt,maxDist)
    if not part or not prompt then return false end
    local char=LocalPlayer.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    if (root.Position-part.Position).Magnitude>(maxDist or 8) then
        walkTo(part.Position,8)
    end
    task.wait(0.15)
    if root.Parent then
        local d=(root.Position-part.Position).Magnitude
        local limit=(prompt.MaxActivationDistance or 10)+2
        if d<=limit then
            firePrompt(prompt)
            return true
        end
    end
    return false
end

local function pathIsValid(fromPos,toPos)
    local path=PathfindingService:CreatePath({AgentRadius=2.4,AgentHeight=5,AgentCanJump=true})
    local ok=pcall(function() path:ComputeAsync(fromPos,toPos) end)
    return ok and path.Status==Enum.PathStatus.Success
end

local function pickFleeTarget(root,killerRoot)
    local away=root.Position-killerRoot.Position
    if away.Magnitude<0.1 then away=Vector3.new(1,0,0) end
    away=away.Unit
    local angles={0,30,-30,60,-60,100,-100,150,-150}
    for _,ang in ipairs(angles) do
        local rad=math.rad(ang)
        local dir=Vector3.new(
            away.X*math.cos(rad)-away.Z*math.sin(rad),
            0,
            away.X*math.sin(rad)+away.Z*math.cos(rad)
        )
        local candidate=root.Position+dir*18
        if pathIsValid(root.Position,candidate) then
            return candidate
        end
    end
    return root.Position+away*18
end

local function nearestKiller(root)
    local closest,dist=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if isKillerPlayer(p) then
            local pRoot=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if pRoot then
                local d=(root.Position-pRoot.Position).Magnitude
                if d<dist then dist=d; closest=pRoot end
            end
        end
    end
    return closest,dist
end

local function nearestLocker(root)
    local lockers=getLockerModels()
    local closest,dist=nil,math.huge
    for _,lm in ipairs(lockers) do
        local ok,cf=pcall(function() return lm:GetBoundingBox() end)
        if ok and cf then
            local d=(root.Position-cf.Position).Magnitude
            if d<dist then dist=d; closest=lm end
        end
    end
    return closest,dist
end

local function hideInLocker(lockerModel)
    if not lockerModel then return end
    local ok,cf=pcall(function() return lockerModel:GetBoundingBox() end)
    if not ok then return end
    walkTo(cf.Position,7)
    local prompt=lockerModel:FindFirstChildWhichIsA("ProximityPrompt",true)
    if prompt then
        local char=LocalPlayer.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local d=(root.Position-cf.Position).Magnitude
            local limit=(prompt.MaxActivationDistance or 10)+2
            if d<=limit then firePrompt(prompt) end
        end
    end
end

local function lobbyLoop(myId)
    local point=LOBBY_POINTS[math.random(1,#LOBBY_POINTS)]
    walkTo(point,14)
    local lastJump=tick()
    while running and runId==myId and getTeamType()=="lobby" do
        task.wait(1)
        if tick()-lastJump>=20 then
            local char=LocalPlayer.Character
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                if math.random(1,2)==2 then
                    task.wait(0.6)
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
            lastJump=tick()
        end
    end
end

local function survivorLoop(myId)
    while running and runId==myId and getTeamType()=="survivor" do
        local char=LocalPlayer.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health>0 then
            if isPlayerDowned(LocalPlayer) then
                local prompt=root:FindFirstChildWhichIsA("ProximityPrompt",true)
                if not prompt then prompt=char:FindFirstChildWhichIsA("ProximityPrompt",true) end
                if prompt then firePrompt(prompt) end
                task.wait(1)
            else
                local killerRoot,killerDist=nearestKiller(root)
                local handled=false
                if killerRoot and killerDist<=HIDE_RADIUS then
                    local locker=nearestLocker(root)
                    if locker then
                        hideInLocker(locker)
                        task.wait(2)
                        handled=true
                    end
                end
                if not handled and killerRoot and killerDist<=DANGER_RADIUS then
                    local fleeTarget=pickFleeTarget(root,killerRoot)
                    walkTo(fleeTarget,4)
                    task.wait(0.1)
                    handled=true
                end
                if not handled then
                    local exits=getExitParts()
                    local closestExit,exitDist=nil,math.huge
                    for _,e in ipairs(exits) do
                        local d=(root.Position-e.Position).Magnitude
                        if d<exitDist then exitDist=d; closestExit=e end
                    end
                    if closestExit then
                        walkTo(closestExit.Position,10)
                        local prompt=findPrompt(closestExit)
                        if prompt then approachAndFire(closestExit,prompt,10) end
                        handled=true
                    end
                end
                if not handled then
                    local loot=getLootParts()
                    local closestLoot,lootDist=nil,math.huge
                    for _,l in ipairs(loot) do
                        local d=(root.Position-l.Position).Magnitude
                        if d<lootDist then lootDist=d; closestLoot=l end
                    end
                    if closestLoot then
                        walkTo(closestLoot.Position,8)
                        local prompt=findPrompt(closestLoot)
                        if prompt then approachAndFire(closestLoot,prompt,8) end
                        task.wait(0.2)
                        handled=true
                    end
                end
                if not handled then
                    task.wait(1)
                end
            end
        else
            task.wait(0.5)
        end
    end
end

local function randomPatrolPoint(root)
    local map=getMap()
    if map then
        local ok,cf,size=pcall(function() return map:GetBoundingBox() end)
        if ok and cf and size then
            local x=cf.Position.X+(math.random()-0.5)*size.X*0.6
            local z=cf.Position.Z+(math.random()-0.5)*size.Z*0.6
            return Vector3.new(x,cf.Position.Y,z)
        end
    end
    local angle=math.random()*math.pi*2
    local dist=math.random(15,PATROL_RADIUS)
    return root.Position+Vector3.new(math.cos(angle)*dist,0,math.sin(angle)*dist)
end

local function nearestSurvivor(root)
    local closest,dist=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and not isKillerPlayer(p) then
            local pChar=p.Character
            local pRoot=pChar and pChar:FindFirstChild("HumanoidRootPart")
            local pHum=pChar and pChar:FindFirstChildOfClass("Humanoid")
            if pRoot and pHum and pHum.Health>0 and not isPlayerDowned(p) then
                local d=(root.Position-pRoot.Position).Magnitude
                if d<dist then dist=d; closest=p end
            end
        end
    end
    return closest,dist
end

local function tryAttack(targetRoot)
    pcall(function()
        if fireclickdetector and targetRoot.Parent then
            local cd=targetRoot.Parent:FindFirstChildWhichIsA("ClickDetector",true)
            if cd then fireclickdetector(cd) end
        end
        local vim=game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0,0,0,true,game,0)
        task.wait(0.05)
        vim:SendMouseButtonEvent(0,0,0,false,game,0)
    end)
end

local function killerLoop(myId)
    local lastAttack=0
    while running and runId==myId and getTeamType()=="killer" do
        local char=LocalPlayer.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health>0 then
            local target,dist=nearestSurvivor(root)
            if target then
                local tRoot=target.Character:FindFirstChild("HumanoidRootPart")
                if tRoot then
                    walkTo(tRoot.Position,5)
                    if dist<=6 and tick()-lastAttack>1 then
                        tryAttack(tRoot)
                        lastAttack=tick()
                    end
                end
            else
                local lockers=getLockerModels()
                if #lockers>0 and math.random(1,3)==1 then
                    local lm=lockers[math.random(1,#lockers)]
                    local ok,cf=pcall(function() return lm:GetBoundingBox() end)
                    if ok then
                        walkTo(cf.Position,7)
                        local prompt=lm:FindFirstChildWhichIsA("ProximityPrompt",true)
                        if prompt then firePrompt(prompt) end
                    end
                else
                    walkTo(randomPatrolPoint(root),10)
                end
                task.wait(0.5)
            end
        else
            task.wait(0.5)
        end
    end
end

local function masterLoop(myId)
    while running and runId==myId do
        local tt=getTeamType()
        if tt=="lobby" then
            lobbyLoop(myId)
        elseif tt=="survivor" then
            survivorLoop(myId)
        elseif tt=="killer" then
            killerLoop(myId)
        end
        task.wait(0.5)
    end
end

local function startLegitBot()
    if running then return end
    running=true
    runId=runId+1
    local myId=runId
    task.spawn(function() masterLoop(myId) end)
end

local function stopLegitBot()
    running=false
    runId=runId+1
end

local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="LegitBotTest"
ScreenGui.ResetOnSpawn=false
ScreenGui.Parent=game:GetService("CoreGui")

local Btn=Instance.new("TextButton")
Btn.Size=UDim2.new(0,160,0,44)
Btn.Position=UDim2.new(0,20,0,150)
Btn.BackgroundColor3=Color3.fromRGB(20,20,24)
Btn.TextColor3=Color3.fromRGB(255,255,255)
Btn.Font=Enum.Font.GothamBold
Btn.TextSize=14
Btn.Text="Auto LegitBot: OFF"
Btn.BorderSizePixel=0
Btn.Parent=ScreenGui
local Crn=Instance.new("UICorner")
Crn.CornerRadius=UDim.new(0,8)
Crn.Parent=Btn

Btn.MouseButton1Click:Connect(function()
    if running then
        stopLegitBot()
        Btn.Text="Auto LegitBot: OFF"
        Btn.BackgroundColor3=Color3.fromRGB(20,20,24)
    else
        startLegitBot()
        Btn.Text="Auto LegitBot: ON"
        Btn.BackgroundColor3=Color3.fromRGB(20,140,70)
    end
end)
