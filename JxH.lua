local Players=game:GetService("Players")
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

local DANGER_RADIUS=65
local HIDE_RADIUS=50
local PATROL_RADIUS=55

local running=false
local runId=0
local cachedMap=nil

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
    if t:find("survivor") or t:find("innocent") or t:find("lobby") or t:find("hider") then return false end
    local myTeam=LocalPlayer.Team
    if myTeam then
        local mt=myTeam.Name:lower()
        if mt:find("survivor") or mt:find("innocent") or mt:find("hider") then return team~=myTeam end
    end
    return false
end

local function isPlayerDowned(player)
    local char=player.Character
    if not char then return false end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hum or (hum.Health<=0 and hum.MaxHealth>0) then return false end
    if char:FindFirstChildOfClass("ForceField") then return false end
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

local function getHumChar()
    local char=LocalPlayer.Character
    if not char then return nil,nil,nil end
    local hum=char:FindFirstChildOfClass("Humanoid")
    local root=char:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health<=0 then return nil,nil,nil end
    return char,hum,root
end

local function findFolder(parent,name)
    if not parent then return nil end
    local f=parent:FindFirstChild(name,true)
    if f and (f:IsA("Folder") or f:IsA("Model")) then return f end
    return nil
end

local function getMap()
    if getTeamType()=="lobby" then return nil end
    if cachedMap and cachedMap.Parent then return cachedMap end
    cachedMap=nil
    local children=workspace:GetChildren()
    for i=1,#children do
        local obj=children[i]
        if (obj:IsA("Model") or obj:IsA("Folder")) and obj~=LocalPlayer.Character then
            local n=obj.Name:lower()
            if not n:find("lobby") and not n:find("spawn") and not Players:GetPlayerFromCharacter(obj) then
                if n:find("map") or findFolder(obj,"LootSpawns") or findFolder(obj,"Exits") then
                    cachedMap=obj
                    return obj
                end
            end
        end
    end
    return nil
end

local function tryTriggerLoot(srcObj)
    if not srcObj then return end
    local ok,descs=pcall(function() return srcObj:GetDescendants() end)
    if not ok or not descs then return end
    for _,child in ipairs(descs) do
        if child:IsA("ProximityPrompt") and child.Enabled then
            pcall(function() fireproximityprompt(child) end)
        elseif child:IsA("ClickDetector") then
            pcall(function() fireclickdetector(child,0) end)
        end
    end
end

local function getLootCandidates()
    local map=getMap()
    if not map then return {} end
    local lootFolder=findFolder(map,"LootSpawns")
    if not lootFolder then return {} end
    local results={}
    local descs=lootFolder:GetDescendants()
    for i=1,#descs do
        local obj=descs[i]
        if obj:IsA("Model") or obj:IsA("Folder") then
            local target=(obj:IsA("Model") and obj.PrimaryPart) or obj:FindFirstChildWhichIsA("BasePart",true)
            if target then table.insert(results,{target=target,src=obj}) end
        elseif obj:IsA("BasePart") then
            local skip=false
            if obj.Parent and (obj.Parent:IsA("Model") or obj.Parent:IsA("Folder")) and obj.Parent~=lootFolder then
                local hasOwn=obj:GetAttribute("Value") or obj:GetAttribute("Amount")
                    or obj:FindFirstChildWhichIsA("ProximityPrompt",true)
                    or obj:FindFirstChildWhichIsA("ClickDetector",true)
                if not hasOwn then skip=true end
            end
            if not skip then table.insert(results,{target=obj,src=obj}) end
        end
    end
    return results
end

local function getReadyExit()
    local map=getMap()
    if not map then return nil end
    local exitsFolder=findFolder(map,"Exits")
    if not exitsFolder then return nil end
    for _,exitObj in ipairs(exitsFolder:GetChildren()) do
        local hasTrigger=false
        for _,desc in ipairs(exitObj:GetDescendants()) do
            if desc:IsA("TouchTransmitter") and desc.Parent and desc.Parent.Name=="Trigger" then
                hasTrigger=true; break
            end
        end
        if hasTrigger then
            local bouncer=exitObj:FindFirstChild("Bouncer",true)
            local bouncerClear=(not bouncer) or (not bouncer:IsA("BasePart")) or (not bouncer.CanCollide)
            if bouncerClear then return exitObj end
        end
    end
    return nil
end

local function resolveGatePart(exitObj)
    if exitObj:IsA("BasePart") then return exitObj end
    if exitObj:IsA("Model") then
        for _,name in ipairs({"Getawaygate","GetawayGate","getawaygate","Gate","Exit","Door","Escape"}) do
            local found=exitObj:FindFirstChild(name,true)
            if found and found:IsA("BasePart") then return found end
        end
        local biggest,biggestVol=nil,0
        for _,p in ipairs(exitObj:GetDescendants()) do
            if p:IsA("BasePart") and p.Name~="Bouncer" then
                local vol=p.Size.X*p.Size.Y*p.Size.Z
                if vol>biggestVol then biggest=p; biggestVol=vol end
            end
        end
        return biggest or exitObj.PrimaryPart
    end
    return nil
end

local function triggerExit(exitObj)
    local char,hum,root=getHumChar()
    if not root then return end
    pcall(function()
        for _,desc in ipairs(exitObj:GetDescendants()) do
            if desc:IsA("TouchTransmitter") and desc.Parent then
                firetouchinterest(root,desc.Parent,0)
                task.wait()
                firetouchinterest(root,desc.Parent,1)
            elseif desc:IsA("ProximityPrompt") and desc.Enabled then
                fireproximityprompt(desc)
            elseif desc:IsA("ClickDetector") then
                fireclickdetector(desc,0)
            end
        end
    end)
end

local function getLockerModels()
    local map=getMap()
    local models={}
    local seen={}
    local folder=nil
    for _,name in ipairs({"Lockers","Locker","lockers","locker","Wardrobes","Wardrobe","Cabinets","Cabinet","Hideouts","Hideout","Closets","Closet"}) do
        local f=(map and map:FindFirstChild(name)) or workspace:FindFirstChild(name)
        if f then folder=f; break end
    end
    if folder then
        for _,obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") and not seen[obj] then seen[obj]=true; table.insert(models,obj) end
        end
    end
    if #models==0 then
        local searchRoot=map or workspace
        for _,obj in ipairs(searchRoot:GetDescendants()) do
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

local function modelPos(model)
    local ok,cf=pcall(function() return model:GetBoundingBox() end)
    if ok then return cf.Position end
    local p=model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
    if p then return p.Position end
    return nil
end

local function computeWaypoints(fromPos,toPos)
    local path=PathfindingService:CreatePath({
        AgentRadius=2,AgentHeight=5,AgentCanJump=true,AgentCanClimb=true,WaypointSpacing=3
    })
    local ok=pcall(function() path:ComputeAsync(fromPos,toPos) end)
    if ok and path.Status==Enum.PathStatus.Success then
        return path:GetWaypoints()
    end
    return nil
end

local function walkTo(targetPos,timeLimit,abortFn)
    local char,hum,root=getHumChar()
    if not hum then return false end
    local waypoints=computeWaypoints(root.Position,targetPos)
    if not waypoints then
        waypoints={
            {Position=root.Position,Action=Enum.PathWaypointAction.Walk},
            {Position=targetPos,Action=Enum.PathWaypointAction.Walk}
        }
    end
    local idx=2
    local startTime=tick()
    local lastPos=root.Position
    local stillTime=0
    while running and idx<=#waypoints and tick()-startTime<(timeLimit or 10) do
        if abortFn and abortFn() then
            char,hum,root=getHumChar()
            if hum then hum:Move(Vector3.new(0,0,0),false) end
            return false
        end
        char,hum,root=getHumChar()
        if not hum then return false end
        local wp=waypoints[idx]
        local toWp=wp.Position-root.Position
        local flatToWp=Vector3.new(toWp.X,0,toWp.Z)
        if flatToWp.Magnitude<2.5 then
            idx=idx+1
        else
            hum:Move(flatToWp.Unit,false)
            if wp.Action==Enum.PathWaypointAction.Jump then
                hum.Jump=true
            end
        end
        local moved=(root.Position-lastPos).Magnitude
        if moved<0.08 then
            stillTime=stillTime+0.05
        else
            stillTime=0
        end
        lastPos=root.Position
        if stillTime>0.55 then
            hum.Jump=true
            local look=root.CFrame.LookVector
            local side=Vector3.new(-look.Z,0,look.X)
            if math.random(1,2)==1 then side=-side end
            hum:Move(side,false)
            task.wait(0.22)
            stillTime=0
        end
        task.wait(0.05)
    end
    char,hum,root=getHumChar()
    if hum then hum:Move(Vector3.new(0,0,0),false) end
    return idx>#waypoints
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

local function killerStillClose(root,limit)
    local kRoot,kDist=nearestKiller(root)
    return kRoot~=nil and kDist<=limit
end

local function pickFleeTarget(root,killerRoot)
    local away=root.Position-killerRoot.Position
    if away.Magnitude<0.1 then away=Vector3.new(1,0,0) end
    away=away.Unit
    return root.Position+away*22
end

local function nearestLocker(root)
    local lockers=getLockerModels()
    local closest,dist,pos=nil,math.huge,nil
    for _,lm in ipairs(lockers) do
        local p=modelPos(lm)
        if p then
            local d=(root.Position-p).Magnitude
            if d<dist then dist=d; closest=lm; pos=p end
        end
    end
    return closest,dist,pos
end

local function hideInLocker(lockerModel,pos)
    if not lockerModel or not pos then return end
    walkTo(pos,7)
    tryTriggerLoot(lockerModel)
end

local function lobbyLoop(myId)
    local point=LOBBY_POINTS[math.random(1,#LOBBY_POINTS)]
    walkTo(point,14)
    local lastJump=tick()
    while running and runId==myId and getTeamType()=="lobby" do
        task.wait(1)
        if tick()-lastJump>=20 then
            local char,hum=getHumChar()
            if hum then
                hum.Jump=true
                if math.random(1,2)==2 then
                    task.wait(0.6)
                    hum.Jump=true
                end
            end
            lastJump=tick()
        end
    end
end

local function survivorLoop(myId)
    while running and runId==myId and getTeamType()=="survivor" do
        local char,hum,root=getHumChar()
        if hum then
            if isPlayerDowned(LocalPlayer) then
                tryTriggerLoot(char)
                task.wait(0.6)
            else
                local killerRoot,killerDist=nearestKiller(root)
                if killerRoot and killerDist<=HIDE_RADIUS then
                    local locker,_,lockerPos=nearestLocker(root)
                    if locker then
                        hideInLocker(locker,lockerPos)
                    else
                        walkTo(pickFleeTarget(root,killerRoot),4)
                    end
                elseif killerRoot and killerDist<=DANGER_RADIUS then
                    walkTo(pickFleeTarget(root,killerRoot),4)
                else
                    local readyExit=getReadyExit()
                    local gatePart=readyExit and resolveGatePart(readyExit)
                    if gatePart then
                        local reached=walkTo(gatePart.Position,10,function()
                            local _,_,r2=getHumChar()
                            return r2 and killerStillClose(r2,HIDE_RADIUS)
                        end)
                        if reached then triggerExit(readyExit) end
                    else
                        local loot=getLootCandidates()
                        local closestLoot,lootDist=nil,math.huge
                        for _,l in ipairs(loot) do
                            local d=(root.Position-l.target.Position).Magnitude
                            if d<lootDist then lootDist=d; closestLoot=l end
                        end
                        if closestLoot then
                            local reached=walkTo(closestLoot.target.Position,8,function()
                                local _,_,r2=getHumChar()
                                return r2 and killerStillClose(r2,HIDE_RADIUS)
                            end)
                            if reached then tryTriggerLoot(closestLoot.src) end
                        else
                            task.wait(0.6)
                        end
                    end
                end
            end
        else
            task.wait(0.4)
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

local function killerLoop(myId)
    while running and runId==myId and getTeamType()=="killer" do
        local char,hum,root=getHumChar()
        if hum then
            local target,dist=nearestSurvivor(root)
            if target then
                local tChar=target.Character
                local tRoot=tChar and tChar:FindFirstChild("HumanoidRootPart")
                if tRoot then
                    walkTo(tRoot.Position,5,function()
                        return target.Character==nil or isPlayerDowned(target)
                    end)
                end
            else
                if math.random(1,3)==1 then
                    local lockers=getLockerModels()
                    if #lockers>0 then
                        local lm=lockers[math.random(1,#lockers)]
                        local pos=modelPos(lm)
                        if pos then
                            walkTo(pos,7)
                            tryTriggerLoot(lm)
                        end
                    else
                        walkTo(randomPatrolPoint(root),10)
                    end
                else
                    walkTo(randomPatrolPoint(root),10)
                end
                task.wait(0.3)
            end
        else
            task.wait(0.4)
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
        task.wait(0.3)
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
