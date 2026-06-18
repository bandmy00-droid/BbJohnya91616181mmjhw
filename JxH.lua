local UPDATE_VERSION = "V6.0"
local UPDATE_TEXT_EN = "1. New Add Ghost Mode \n2. New Add Hitbox ( Killer ) \n3. Fix Double Jump When you Down \n4. Bug Fixed \n5. fix Snowman Animation \n6. UI Color Customization \n7. More....in 6.0 Version "
local UPDATE_TEXT_RU = "1. Добавлен Режим призрака \n2. Добавлен Хитбокс (Убийца) \n3. Исправлен двойной прыжок в нокауте \n4. Исправлены ошибки \n5. Исправлена анимация снеговика \n6. Настройка цветов интерфейса \n7. Больше... в версии 6.0 "
local math_floor=math.floor
local math_max=math.max
local math_min=math.min
local Vector3_new=Vector3.new
local CFrame_new=CFrame.new
local Instance_new=Instance.new
local Color3_new=Color3.new
local Color3_fromRGB=Color3.fromRGB
local UDim2_new=UDim2.new
local UDim_new=UDim.new
local VEC3_ZERO=Vector3_new(0,0,0)
task.wait(0.5)
local Sv={
    Players=game:GetService("Players"),
    RunService=game:GetService("RunService"),
    UserInputService=game:GetService("UserInputService"),
    CoreGui=game:GetService("CoreGui"),
    TweenService=game:GetService("TweenService"),
    Lighting=game:GetService("Lighting"),
    HttpService=game:GetService("HttpService"),
    Stats=game:GetService("Stats"),
    SoundService=game:GetService("SoundService")
}
Sv.LocalPlayer=Sv.Players.LocalPlayer
local St={
    _imageCache={},
    _imgMap=setmetatable({},{__mode="k"}),
    _imgByFile={},
    ALL_ASSETS={"Heart.png","CoINs.png","Farm.png","setting.png","esp.png","JXPhoTHO.png","Telegram.png","Home.png","English.jpg","Russian.jpg"},
    DOUBLE_JUMP_ANIM_ID="rbxassetid://4643151469",
    MIN_LOOT_VALUE=1,
    farmCollectDelay=3.16,
    farmSpeedPct=40,
    LIVES_MAX=3,
    Settings={
        PlayerESP=false,ExitESP=false,LootESP=false,
        ShowDistance=false,ShowNames=false,ShowCoins=false,
        LivesESP=false,
        DoubleJump=true,InfiniteJump=false,Noclip=false,SpeedEnabled=false,
        FlyEnabled=false,GhostMode=false,Hitbox=false,
        AutoFarmLoot=false,KillerSafety=false,AutoEscape=false,
        RemoveFog=true,AntiAFK=false,_killAll=false,
        AutoRevive=false,AutoSelfRevive=false,
        SnowAnimation=false,AntiVoid=false,
        ThemeHue=0,FpsBoost=false,ShowAds=true
    },
    NameSettings={OffsetY=4.5,Font=Enum.Font.GothamBold},
    DistSettings={OffsetY=-4.5,Font=Enum.Font.GothamBold},
    LivesSettings={OffsetY=7,OffsetX=0,HeartSize=10},
    OriginalFog={
        FogEnd=Sv.Lighting.FogEnd,
        FogStart=Sv.Lighting.FogStart,
        Ambient=Sv.Lighting.Ambient,
        OutdoorAmbient=Sv.Lighting.OutdoorAmbient,
        ColorShift_Bottom=Sv.Lighting.ColorShift_Bottom,
        ColorShift_Top=Sv.Lighting.ColorShift_Top,
        ClockTime=Sv.Lighting.ClockTime,
        Brightness=Sv.Lighting.Brightness,
        GlobalShadows=Sv.Lighting.GlobalShadows
    },
    OriginalAtmosphere={},
    OriginalAnims={},
    Connections={Jump=nil,State=nil},
    Storage={Players={},TeamConns={},Exits={},Loot={},NameLabels={},DistLabels={},Lives={}},
    Cn={autoEscape=nil,killerSafety=nil,noclip=nil,speed=nil,fog=nil,antiAfk=nil,autoRevive=nil,reviveFollow=nil,autoSelfRevive=nil,fly=nil,infiniteJump=nil,watchdog=nil,antiSeat=nil,teamWatch=nil,lootAdded=nil,lootRemoved=nil,hitbox=nil},
    Fl={
        autoFarmRunning=false,autoEscapeRunning=false,killerSafetyActive=false,
        killAllRunning=false,fogLoopRunning=false,autoReviveRunning=false,
        reviveSelfPaused=false,farmPaused=false,farmStoppedForRound=false,
        escapeTriggeredExternal=false,escapeCheckTimer=0,farmPriority=0,
        killerSafetyDist=50,currentSpeed=16,flySpeed=50,hitboxRadius=15,
        lastFarmPos=nil,lastFarmPosTime=0,uiScale=1.0,winSize=1.0,hudSize=1.0,bgTransparency=0.85,
        lootCacheMap=nil,currentMapInstance=nil,originalMasterVolume=Sv.SoundService.AmbientReverb,
        currentTab="home",
        _reviveStarting=false,_escapeWaitStart=nil,isTeleporting=false,
        ghostActive=false,ghostDebounce=false,realChar=nil,fakeChar=nil,ghostSavedStates={}
    },
    flyKeys={up=false,down=false},
    toggleRefs={},
    toggleCbs={},
    collectedLoot=setmetatable({},{__mode="k"}),
    cachedMap=nil,
    lootValueCache=setmetatable({},{__mode="k"}),
    espColorCache={},
    reviveTracking={},
    livesData={},
    livesDownState={},
    MainBtn_ref=nil,
    CoinsHUD_ref=nil,
    UIRefs={Themed={}},
    _savedBtnPos=nil,
    noclipParts={},
    _lockerCache={models={},time=0},
    _snowTracks={},
    _snowHrConn=nil,
    SAVE_FILE="JxH_settingsVv6.0.json",
    _lastSaveTime=0,
    _sliderDrags={},
    _sliderDragId=nil,
    _restartCooldown=0,
    canJump2=false,
    jumpCount=0,
    farmLoopId=0,
    lootEspTimer=0,
    livesTrackTimer=0,
    reviveLoopId=0,
    selfReviveLoopId=0,
    PUBLIC_REPO_URL="https://raw.githubusercontent.com/bandmy00-droid/JohnyX-V6.0/main/",
    Language="EN",
    Analytics={
        farmSuccess=0,farmFail=0,escapeCount=0,
        coinsCollected=0,sessionStart=tick()
    }
}
for _,obj in ipairs(Sv.Lighting:GetChildren()) do
    if obj:IsA("Atmosphere") then
        St.OriginalAtmosphere[obj]={Density=obj.Density,Haze=obj.Haze}
    end
end
Sv.UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.Space then St.flyKeys.up=true
    elseif inp.KeyCode==Enum.KeyCode.LeftControl then St.flyKeys.down=true end
end)
Sv.UserInputService.InputEnded:Connect(function(inp,gpe)
    if inp.KeyCode==Enum.KeyCode.Space then St.flyKeys.up=false
    elseif inp.KeyCode==Enum.KeyCode.LeftControl then St.flyKeys.down=false end
end)
local F={}
local UI={}
local _langRefs={}
local _T
local _LR
local _applyLang
function F.clearTable(t) for k in pairs(t) do t[k]=nil end end
function F.safeDestroy(obj)
    if obj and obj.Parent then pcall(function() obj:Destroy() end) end
end
function F.setToggleState(sName,state)
    if St.Settings[sName]~=state then
        St.Settings[sName]=state
        if St.toggleRefs[sName] then St.toggleRefs[sName](state) end
        if St.toggleCbs[sName] then St.toggleCbs[sName](state) end
    end
end


local _ROBLOX_ICONS={
    ["Heart.png"]="rbxthumb://type=Asset&id=108571680732230&w=420&h=420",
    ["CoINs.png"]="rbxthumb://type=Asset&id=136782305608562&w=420&h=420",
    ["Farm.png"]="rbxthumb://type=Asset&id=110686780409469&w=420&h=420",
    ["setting.png"]="rbxthumb://type=Asset&id=96621936204864&w=420&h=420",
    ["esp.png"]="rbxthumb://type=Asset&id=108417288747288&w=420&h=420",
    ["JXPhoTHO.png"]="rbxthumb://type=Asset&id=138627690193651&w=420&h=420",
    ["Telegram.png"]="rbxthumb://type=Asset&id=86445606186301&w=420&h=420",
    ["Home.png"]="rbxthumb://type=Asset&id=102444249610138&w=420&h=420",
    ["English.jpg"]="rbxthumb://type=Asset&id=105735635413663&w=420&h=420",
    ["Russian.jpg"]="rbxthumb://type=Asset&id=95543406783515&w=420&h=420"
}
local function setPrivateImage(img,filename)
    pcall(function()
        if img and img.Parent then
            img.Image=_ROBLOX_ICONS[filename] or ""
        end
    end)
end
local function _preloadFromDisk() end
local function _downloadMissing() end

local _dlGuard={}
local function _downloadMissing()
    task.spawn(function()
        for _,fn in ipairs(St.ALL_ASSETS) do
            if not St._imageCache[fn] and not _dlGuard[fn] then
                _dlGuard[fn]=true
                task.spawn(function()
                    local asset=_fetchIcon(fn)
                    if asset then _applyToAll(fn,asset) end
                    _dlGuard[fn]=nil
                end)
            end
        end
    end)
end
local _folderCache=setmetatable({},{__mode="k"})
function F.findFolder(parent,name)
    if not parent then return nil end
    if not _folderCache[parent] then _folderCache[parent]={} end
    local cached=_folderCache[parent][name]
    if cached~=nil then
        if cached.Parent then return cached end
        _folderCache[parent][name]=nil
    end
    local f=parent:FindFirstChild(name,true)
    if f and (f:IsA("Folder") or f:IsA("Model")) then
        _folderCache[parent][name]=f
        return f
    end
    return nil
end
function F.getMap()
    if F.getMyTeamType()=="lobby" then return nil end
    if St.cachedMap and St.cachedMap.Parent then return St.cachedMap end
    St.cachedMap=nil
    local children=workspace:GetChildren()
    for i=1,#children do
        local obj=children[i]
        if (obj:IsA("Model") or obj:IsA("Folder")) and obj~=Sv.LocalPlayer.Character then
            local n=obj.Name:lower()
            if not n:find("lobby") and not n:find("spawn") and not Sv.Players:GetPlayerFromCharacter(obj) then
                if n:find("map") or F.findFolder(obj,"LootSpawns") or F.findFolder(obj,"Exits") then
                    St.cachedMap=obj
                    return obj
                end
            end
        end
    end
    return nil
end
function F.getMyTeamType()
    local team=Sv.LocalPlayer.Team; if not team then return "lobby" end
    local t=team.Name:lower()
    if t:find("survivor") or t:find("innocent") or t:find("hider") then return "survivor" end
    if t:find("killer") then return "killer" end
    return "lobby"
end
function F.getPlayerTeamType(player)
    if player==Sv.LocalPlayer then return F.getMyTeamType() end
    local team=player.Team; if not team then return "lobby" end
    local t=team.Name:lower()
    if t:find("killer") then return "killer" end
    if t:find("survivor") or t:find("innocent") or t:find("hider") then return "survivor" end
    return "lobby"
end
local KILLER_COLOR=Color3_fromRGB(255,40,40)
local SURVIVOR_COLOR=Color3_fromRGB(40,200,255)
local LOBBY_COLOR=Color3_fromRGB(180,180,180)
function F.isKillerPlayer(player)
    if player==Sv.LocalPlayer then return false end
    local team=player.Team; if not team then return false end
    local t=team.Name:lower()
    if t=="killer" or t:find("^killer") then return true end
    if t:find("survivor") or t:find("innocent") or t:find("lobby") or t:find("hider") then return false end
    local myTeam=Sv.LocalPlayer.Team
    if myTeam then
        local mt=myTeam.Name:lower()
        if mt:find("survivor") or mt:find("innocent") or mt:find("hider") then return team~=myTeam end
    end
    return false
end
function F.refreshPlayerColor(player)
    St.espColorCache[player.UserId]=nil
    local team=player.Team
    local color=(team and team.Name:lower():find("lobby")) and LOBBY_COLOR
        or (F.isKillerPlayer(player) and KILLER_COLOR or SURVIVOR_COLOR)
    St.espColorCache[player.UserId]=color
    return color
end
function F.applyNameFont(font)
    St.NameSettings.Font=font
    for _,d in pairs(St.Storage.NameLabels) do if d.lbl and d.lbl.Parent then d.lbl.Font=font end end
end
function F.applyNameOffset(y)
    St.NameSettings.OffsetY=y
    for _,d in pairs(St.Storage.NameLabels) do
        if d.bgui and d.bgui.Parent then d.bgui.StudsOffset=Vector3_new(0,y,0) end
    end
end
function F.applyDistFont(font)
    St.DistSettings.Font=font
    for _,d in pairs(St.Storage.DistLabels) do if d.lbl and d.lbl.Parent then d.lbl.Font=font end end
end
function F.applyDistOffset(y)
    St.DistSettings.OffsetY=y
    for _,d in pairs(St.Storage.DistLabels) do
        if d.bgui and d.bgui.Parent then d.bgui.StudsOffset=Vector3_new(0,y,0) end
    end
end
function F.applyLivesOffsetY(y)
    St.LivesSettings.OffsetY=y
    for _,ld in pairs(St.livesData) do
        if ld.bgui and ld.bgui.Parent then
            ld.bgui.StudsOffset=Vector3_new(St.LivesSettings.OffsetX,y,0)
        end
    end
end
function F.applyLivesOffsetX(x)
    St.LivesSettings.OffsetX=x
    for _,ld in pairs(St.livesData) do
        if ld.bgui and ld.bgui.Parent then
            ld.bgui.StudsOffset=Vector3_new(x,St.LivesSettings.OffsetY,0)
        end
    end
end
function F.applyLivesSize(s)
    St.LivesSettings.HeartSize=s
    local gap=math_floor(s/6+1)
    local bw=s*St.LIVES_MAX+gap*(St.LIVES_MAX-1)
    for _,ld in pairs(St.livesData) do
        if ld.bgui and ld.bgui.Parent then
            ld.bgui.Size=UDim2_new(0,bw,0,s+4)
            for i,h in ipairs(ld.heartImgs or {}) do
                if h and h.Parent then
                    h.Size=UDim2_new(0,s,0,s)
                    h.Position=UDim2_new(0,(i-1)*(s+gap),0.5,-math_floor(s/2))
                end
            end
        end
    end
end
function F.updateHearts(uid,lives)
    local ld=St.livesData[uid]; if not ld then return end
    lives=math.clamp(lives,0,St.LIVES_MAX)
    ld.lives=lives
    for i,h in ipairs(ld.heartImgs or {}) do
        if h and h.Parent then
            if i<=lives then
                h.Visible=true
                h.ImageTransparency=0
                h.ImageColor3=Color3_fromRGB(255,40,40)
            else
                h.Visible=false
            end
        end
    end
end
function F.isPlayerDowned(player)
    local char=player.Character; if not char then return false end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hum or (hum.Health<=0 and hum.MaxHealth>0) then return false end
    if char:FindFirstChildOfClass("ForceField") then return false end
    local root=char:FindFirstChild("HumanoidRootPart"); if not root then return false end
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
function F.ultraFastTeleport(targetPos)
    local char=Sv.LocalPlayer.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health<=0 then return end
    local startPos=root.Position
    local dist=(targetPos-startPos).Magnitude
    if dist<=55 then
        pcall(function()
            root.CFrame=CFrame_new(targetPos)
            root.Velocity=VEC3_ZERO
            root.RotVelocity=VEC3_ZERO
        end)
    else
        if St.Fl.isTeleporting then return end
        St.Fl.isTeleporting=true
        local steps=math_floor(dist/55)+1
        for i=1,steps do
            if not root or not root.Parent or hum.Health<=0 then break end
            local alpha=i/steps
            local nextPos=startPos:Lerp(targetPos,alpha)
            pcall(function()
                root.CFrame=CFrame_new(nextPos)
                root.Velocity=VEC3_ZERO
                root.RotVelocity=VEC3_ZERO
            end)
            Sv.RunService.Heartbeat:Wait()
        end
        St.Fl.isTeleporting=false
    end
end
function F.createPlayerESP(player)
    if player==Sv.LocalPlayer then return end
    local function cleanup()
        local data=St.Storage.Players[player.UserId]
        if data then
            if data.colorDot then pcall(function() data.colorDot:Destroy() end) end
            F.safeDestroy(data.bgui); F.safeDestroy(data.bguiDist); F.safeDestroy(data.bguiBox); F.safeDestroy(data.hl)
            if data.conn then data.conn:Disconnect() end
            if data.charConn then data.charConn:Disconnect() end
            St.Storage.Players[player.UserId]=nil
        end
        local lv=St.Storage.Lives[player.UserId]
        if lv then F.safeDestroy(lv.bgui); St.Storage.Lives[player.UserId]=nil end
        St.Storage.NameLabels[player.UserId]=nil
        St.Storage.DistLabels[player.UserId]=nil
        St.espColorCache[player.UserId]=nil
        St.livesData[player.UserId]=nil
        St.livesDownState[player.UserId]=nil
    end
    local function setup()
        cleanup()
        local teamKey="team_"..player.UserId
        St.espColorCache[teamKey]=nil
        local color=F.refreshPlayerColor(player)
        local bguiName=Instance_new("BillboardGui")
        bguiName.Name="ESP_Name"; bguiName.Size=UDim2_new(0,100,0,15)
        bguiName.StudsOffset=Vector3_new(0,St.NameSettings.OffsetY,0)
        bguiName.AlwaysOnTop=true; bguiName.LightInfluence=0; bguiName.MaxDistance=math.huge
        bguiName.ResetOnSpawn=false; bguiName.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
        bguiName.Enabled=St.Settings.PlayerESP and St.Settings.ShowNames
        local targetParent=Sv.CoreGui:FindFirstChild("RobloxGui") or Sv.CoreGui
        pcall(function() bguiName.Parent=targetParent end)
        if not bguiName.Parent then pcall(function() bguiName.Parent=Sv.LocalPlayer:WaitForChild("PlayerGui") end) end
        local colorDot=Instance_new("Frame"); colorDot.Parent=bguiName
        colorDot.Size=UDim2_new(0,6,0,6); colorDot.Position=UDim2_new(0,-8,0.5,-3)
        colorDot.BackgroundColor3=color; colorDot.BorderSizePixel=0
        local cdCrn=Instance_new("UICorner"); cdCrn.Parent=colorDot; cdCrn.CornerRadius=UDim_new(1,0)
        local nameLbl=Instance_new("TextLabel"); nameLbl.Parent=bguiName
        nameLbl.Size=UDim2_new(1,0,1,0); nameLbl.BackgroundTransparency=1
        nameLbl.Text=player.DisplayName; nameLbl.TextColor3=color
        nameLbl.Font=St.NameSettings.Font; nameLbl.TextSize=10
        nameLbl.TextStrokeTransparency=0.2; nameLbl.TextStrokeColor3=Color3_new(0,0,0)
        nameLbl.TextXAlignment=Enum.TextXAlignment.Center
        local bguiDist=Instance_new("BillboardGui")
        bguiDist.Name="ESP_Dist"; bguiDist.Size=UDim2_new(0,80,0,12)
        bguiDist.StudsOffset=Vector3_new(0,St.DistSettings.OffsetY,0)
        bguiDist.AlwaysOnTop=true; bguiDist.LightInfluence=0; bguiDist.MaxDistance=math.huge
        bguiDist.ResetOnSpawn=false; bguiDist.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
        bguiDist.Enabled=St.Settings.PlayerESP and St.Settings.ShowDistance
        pcall(function() bguiDist.Parent=targetParent end)
        if not bguiDist.Parent then pcall(function() bguiDist.Parent=Sv.LocalPlayer:WaitForChild("PlayerGui") end) end
        local distLbl=Instance_new("TextLabel"); distLbl.Parent=bguiDist
        distLbl.Size=UDim2_new(1,0,1,0); distLbl.BackgroundTransparency=1
        distLbl.Text=""; distLbl.TextColor3=Color3_fromRGB(230,230,230)
        distLbl.Font=St.DistSettings.Font; distLbl.TextSize=9
        distLbl.TextStrokeTransparency=0.2; distLbl.TextStrokeColor3=Color3_new(0,0,0)
        distLbl.TextXAlignment=Enum.TextXAlignment.Center
        local bguiBox=Instance_new("BillboardGui")
        bguiBox.Name="ESP_Box"; bguiBox.Size=UDim2_new(0,40,0,62)
        bguiBox.StudsOffset=Vector3_new(0,0.5,0)
        bguiBox.AlwaysOnTop=true; bguiBox.LightInfluence=0; bguiBox.MaxDistance=math.huge
        bguiBox.ResetOnSpawn=false; bguiBox.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
        bguiBox.Enabled=false
        pcall(function() bguiBox.Parent=targetParent end)
        if not bguiBox.Parent then pcall(function() bguiBox.Parent=Sv.LocalPlayer:WaitForChild("PlayerGui") end) end
        local boxFrame=Instance_new("Frame"); boxFrame.Parent=bguiBox
        boxFrame.Size=UDim2_new(1,0,1,0); boxFrame.BackgroundTransparency=1; boxFrame.BorderSizePixel=0
        local boxStroke=Instance_new("UIStroke"); boxStroke.Parent=boxFrame
        boxStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
        boxStroke.Color=color; boxStroke.Thickness=1; boxStroke.Transparency=0
        local hs=St.LivesSettings.HeartSize
        local gap=math_floor(hs/6+1)
        local bw=hs*St.LIVES_MAX+gap*(St.LIVES_MAX-1)
        local bguiLives=Instance_new("BillboardGui")
        bguiLives.Name="ESP_Lives"; bguiLives.Size=UDim2_new(0,bw,0,hs+4)
        bguiLives.StudsOffset=Vector3_new(St.LivesSettings.OffsetX,St.LivesSettings.OffsetY,0)
        bguiLives.AlwaysOnTop=true; bguiLives.LightInfluence=0; bguiLives.MaxDistance=math.huge
        bguiLives.ResetOnSpawn=false; bguiLives.Enabled=false
        pcall(function() bguiLives.Parent=targetParent end)
        if not bguiLives.Parent then pcall(function() bguiLives.Parent=Sv.LocalPlayer:WaitForChild("PlayerGui") end) end
        local heartImgs={}
        for i=1,St.LIVES_MAX do
            local h=Instance_new("ImageLabel"); h.Parent=bguiLives
            h.Size=UDim2_new(0,hs,0,hs)
            h.Position=UDim2_new(0,(i-1)*(hs+gap),0.5,-math_floor(hs/2))
            h.BackgroundTransparency=1; h.ScaleType=Enum.ScaleType.Fit
            h.Visible=true; h.ImageColor3=Color3_fromRGB(255,40,40); h.ImageTransparency=0
            setPrivateImage(h,"Heart.png")
            heartImgs[i]=h
        end
        if not St.livesData[player.UserId] then St.livesData[player.UserId]={lives=St.LIVES_MAX,lastLoss=0} end
        St.livesData[player.UserId].bgui=bguiLives
        St.livesData[player.UserId].heartImgs=heartImgs
        St.livesDownState[player.UserId]=false
        St.Storage.Lives[player.UserId]={bgui=bguiLives}
        St.Storage.NameLabels[player.UserId]={lbl=nameLbl,bgui=bguiName}
        St.Storage.DistLabels[player.UserId]={lbl=distLbl,bgui=bguiDist,lastDist=-1}
        local newHl=Instance_new("Highlight")
        newHl.FillTransparency=0.75
        newHl.OutlineTransparency=0.1
        newHl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        newHl.FillColor=color
        newHl.OutlineColor=color
        newHl.Enabled=false
        local DATA={bgui=bguiName,bguiDist=bguiDist,hl=newHl,colorDot=colorDot,conn=nil,charConn=nil,bguiBox=bguiBox,boxStroke=boxStroke,boxSzW=0,boxSzH=0}
        St.Storage.Players[player.UserId]=DATA
        F.updateHearts(player.UserId,St.livesData[player.UserId].lives)
        DATA.charConn=player.CharacterAdded:Connect(function(newChar)
            task.wait(0.5)
            if player and player.Parent then setup() end
        end)
    end
    setup()
    if St.Storage.TeamConns[player.UserId] then St.Storage.TeamConns[player.UserId]:Disconnect() end
    St.Storage.TeamConns[player.UserId]=player:GetPropertyChangedSignal("Team"):Connect(function()
        local teamKey="team_"..player.UserId
        St.espColorCache[teamKey]=nil
        local nc=F.refreshPlayerColor(player)
        local data=St.Storage.Players[player.UserId]
        if data and data.hl then data.hl.FillColor=nc; data.hl.OutlineColor=nc end
        if data and data.boxStroke and data.boxStroke.Parent then data.boxStroke.Color=nc end
        if data and data.colorDot and data.colorDot.Parent then data.colorDot.BackgroundColor3=nc end
        local nl=St.Storage.NameLabels[player.UserId]
        if nl and nl.lbl and nl.lbl.Parent then nl.lbl.TextColor3=nc end
        local pTeam=F.getPlayerTeamType(player)
        local ld=St.livesData[player.UserId]
        if ld and ld.bgui then
            if pTeam~="survivor" then
                ld.bgui.Enabled=false
                ld.lives=St.LIVES_MAX
                St.livesDownState[player.UserId]=false
                F.updateHearts(player.UserId,St.LIVES_MAX)
            end
        end
    end)
end
local _cachedPlayers={}
local _playerListDirty=true
local function _getPlayers()
    if _playerListDirty then
        _cachedPlayers=Sv.Players:GetPlayers()
        _playerListDirty=false
    end
    return _cachedPlayers
end
local _espHbTimer=0
local _soundTimer=0
local _mapCheckTimer=0
Sv.RunService.Heartbeat:Connect(function(dt)
    _espHbTimer=_espHbTimer+dt
    _soundTimer=_soundTimer+dt
    _mapCheckTimer=_mapCheckTimer+dt
    St.livesTrackTimer=St.livesTrackTimer+dt
    if _soundTimer>=0.5 then
        _soundTimer=0
        if St.Fl.autoFarmRunning then
            if Sv.SoundService.AmbientReverb~=Enum.ReverbType.NoReverb then
                Sv.SoundService.AmbientReverb=Enum.ReverbType.NoReverb
            end
        else
            if Sv.SoundService.AmbientReverb~=St.Fl.originalMasterVolume then
                Sv.SoundService.AmbientReverb=St.Fl.originalMasterVolume
            end
        end
    end
    if _mapCheckTimer>=5 then
        _mapCheckTimer=0
        local currentMap=F.getMap()
        if currentMap~=St.Fl.currentMapInstance then
            St.Fl.currentMapInstance=currentMap
            F.clearTable(St.Storage.Loot)
            F.clearTable(St.collectedLoot)
            St.Fl.lootCacheMap=nil
        end
    end
    if _espHbTimer>=0.2 then
        _espHbTimer=0
        if not St.Settings.PlayerESP then
            for _,DATA in pairs(St.Storage.Players) do
                if DATA.bgui and DATA.bgui.Enabled then DATA.bgui.Enabled=false end
                if DATA.bguiDist and DATA.bguiDist.Enabled then DATA.bguiDist.Enabled=false end
                if DATA.hl and DATA.hl.Enabled then DATA.hl.Enabled=false end
                if DATA.bguiBox and DATA.bguiBox.Enabled then DATA.bguiBox.Enabled=false end
            end
        else
            local myChar=Sv.LocalPlayer.Character
            local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart")
            local cam=workspace.CurrentCamera
            local refRoot=myRoot
            local subject=cam and cam.CameraSubject
            if subject and subject:IsA("Humanoid") then
                local subChar=subject.Parent
                if subChar then
                    local subRoot=subChar:FindFirstChild("HumanoidRootPart")
                    if subRoot and subRoot~=myRoot then refRoot=subRoot end
                end
            end
            for _,player in ipairs(_getPlayers()) do
                if player~=Sv.LocalPlayer then
                    local uid=player.UserId
                    local DATA=St.Storage.Players[uid]
                    if DATA then
                        local char=player.Character
                        local root=char and char:FindFirstChild("HumanoidRootPart")
                        local bguiName=DATA.bgui
                        local bguiDist=DATA.bguiDist
                        local bguiLives=St.Storage.Lives[uid] and St.Storage.Lives[uid].bgui
                        if not char or not root then
                            if bguiName and bguiName.Enabled then bguiName.Enabled=false end
                            if bguiDist and bguiDist.Enabled then bguiDist.Enabled=false end
                            if bguiLives and bguiLives.Enabled then bguiLives.Enabled=false end
                            if DATA.hl and DATA.hl.Enabled then DATA.hl.Enabled=false end
                            if DATA.bguiBox and DATA.bguiBox.Enabled then DATA.bguiBox.Enabled=false end
                        else
                            local rawDist=refRoot and (root.Position-refRoot.Position).Magnitude or 0
                            local farAway=rawDist>=203
                            if bguiName then
                                if bguiName.Adornee~=root then bguiName.Adornee=root end
                                local shouldShow=St.Settings.ShowNames
                                if shouldShow~=bguiName.Enabled then bguiName.Enabled=shouldShow end
                            end
                            if bguiDist then
                                if bguiDist.Adornee~=root then bguiDist.Adornee=root end
                                if St.Settings.ShowDistance and myRoot then
                                    local nd=St.Storage.DistLabels[uid]
                                    if nd and nd.lbl then
                                        local ds=math_floor(rawDist)
                                        if nd.lastDist~=ds then nd.lastDist=ds; nd.lbl.Text=ds.." m" end
                                    end
                                    if not bguiDist.Enabled then bguiDist.Enabled=true end
                                else
                                    if bguiDist.Enabled then bguiDist.Enabled=false end
                                end
                            end
                            if DATA.hl then
                                if DATA.hl.Adornee~=char then DATA.hl.Adornee=char end
                                if DATA.hl.Parent~=char then pcall(function() DATA.hl.Parent=char end) end
                                local teamKey="team_"..uid
                                local pTeam=St.espColorCache[teamKey] or F.getPlayerTeamType(player)
                                St.espColorCache[teamKey]=pTeam
                                local color=St.espColorCache[uid] or F.refreshPlayerColor(player)
                                if DATA.hl.FillColor~=color then
                                    DATA.hl.FillColor=color
                                    DATA.hl.OutlineColor=color
                                end
                                local hlOn=not farAway
                                if DATA.hl.Enabled~=hlOn then DATA.hl.Enabled=hlOn end
                            end
                            if DATA.bguiBox then
                                if DATA.bguiBox.Adornee~=root then DATA.bguiBox.Adornee=root end
                                if DATA.bguiBox.Enabled~=farAway then DATA.bguiBox.Enabled=farAway end
                                if farAway then
                                    local bw=math_max(5,math_floor(1540/rawDist))
                                    local bh=math_max(8,math_floor(3850/rawDist))
                                    if DATA.boxSzW~=bw or DATA.boxSzH~=bh then
                                        DATA.boxSzW=bw; DATA.boxSzH=bh
                                        DATA.bguiBox.Size=UDim2_new(0,bw,0,bh)
                                    end
                                    if DATA.boxStroke then
                                        local color=St.espColorCache[uid] or F.refreshPlayerColor(player)
                                        if DATA.boxStroke.Color~=color then DATA.boxStroke.Color=color end
                                    end
                                end
                            end
                            if bguiLives then
                                if bguiLives.Adornee~=root then bguiLives.Adornee=root end
                                local teamKey="team_"..uid
                                local pTeam=St.espColorCache[teamKey] or F.getPlayerTeamType(player)
                                local livesOn=St.Settings.LivesESP and pTeam=="survivor"
                                if livesOn~=bguiLives.Enabled then bguiLives.Enabled=livesOn end
                            end
                        end
                    end
                end
            end
        end
    end
    if St.livesTrackTimer>=0.5 then
        St.livesTrackTimer=0
        if St.Settings.LivesESP then
            for _,p in ipairs(_getPlayers()) do
                if p~=Sv.LocalPlayer then
                    local uid=p.UserId
                    local teamKey="team_"..uid
                    local pTeam=St.espColorCache[teamKey] or F.getPlayerTeamType(p)
                    St.espColorCache[teamKey]=pTeam
                    if pTeam~="survivor" then
                        St.livesDownState[uid]=false
                    else
                        local curDowned=F.isPlayerDowned(p)
                        local wasDowned=St.livesDownState[uid] or false
                        local now=os.clock()
                        if not St.livesData[uid] then St.livesData[uid]={lives=St.LIVES_MAX,lastLoss=0} end
                        St.livesData[uid].lastLoss=St.livesData[uid].lastLoss or 0
                        if curDowned and not wasDowned then
                            if now-St.livesData[uid].lastLoss>4 then
                                St.livesData[uid].lives=math_max(0,St.livesData[uid].lives-1)
                                St.livesData[uid].lastLoss=now
                                F.updateHearts(uid,St.livesData[uid].lives)
                            end
                        end
                        St.livesDownState[uid]=curDowned
                        local char=p.Character
                        local hum=char and char:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health<=0 then
                            if St.livesData[uid] and St.livesData[uid].lives>0 then
                                St.livesData[uid].lives=0
                                F.updateHearts(uid,0)
                            end
                        end
                    end
                end
            end
        end
    end
end)
function F.createLootBillboard(target,value)
    for _,child in ipairs(target:GetChildren()) do
        if child:IsA("BillboardGui") and child.Name=="JxH_LootESP" then
            F.safeDestroy(child)
            break
        end
    end
    local bgui=Instance_new("BillboardGui")
    bgui.Name="JxH_LootESP"
    bgui.Adornee=target; bgui.Size=UDim2_new(0,45,0,14)
    bgui.AlwaysOnTop=true; bgui.StudsOffset=Vector3_new(0,1.5,0); bgui.MaxDistance=400
    bgui.Enabled=target.Transparency<0.9
    local img=Instance_new("ImageLabel"); img.Parent=bgui
    img.Size=UDim2_new(0,9,0,9); img.Position=UDim2_new(0,2,0.5,-4)
    img.BackgroundTransparency=1; img.ScaleType=Enum.ScaleType.Fit
    setPrivateImage(img,"CoINs.png")
    local lbl=Instance_new("TextLabel"); lbl.Parent=bgui
    lbl.Size=UDim2_new(1,-12,1,0); lbl.Position=UDim2_new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text="+"..tostring(value)
    lbl.TextColor3=Color3_fromRGB(255,230,0); lbl.Font=Enum.Font.GothamBold
    lbl.TextSize=9; lbl.TextStrokeTransparency=0.5
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    bgui.Parent=target; return bgui
end
function F.getLootValue(obj)
    if St.lootValueCache[obj]~=nil then return St.lootValueCache[obj] end
    local function cache(v) St.lootValueCache[obj]=v; return v end
    local attr=obj:GetAttribute("Value") or obj:GetAttribute("Amount")
    if attr then
        local val=nil
        if type(attr)=="number" then val=attr
        elseif type(attr)=="string" then val=tonumber(attr) end
        if val then
            if val==20 then return cache(nil) end
            return cache(val)
        end
    end
    local descs=obj:GetDescendants()
    local fallback=nil
    for _,c in ipairs(descs) do
        if c:IsA("ProximityPrompt") or c:IsA("ClickDetector") then
            local at=c:GetAttribute("ActionText")
            if at and type(at)=="string" then
                local n=at:match("%+(%d+)"); if n then fallback=tonumber(n) break end
            end
        elseif c:IsA("TextLabel") or c:IsA("TextButton") then
            local n=c.Text:match("%+(%d+)"); if n then fallback=tonumber(n) break end
        elseif (c:IsA("IntValue") or c:IsA("NumberValue")) and not fallback then
            fallback=c.Value
        elseif c:IsA("StringValue") and not fallback then
            local n=tonumber(c.Value); if n then fallback=n end
        end
    end
    if fallback then
        if fallback==20 then return cache(nil) end
        return cache(fallback)
    end
    if obj:IsDescendantOf(workspace) then
        local map=F.getMap()
        local lootFolder=F.findFolder(map,"LootSpawns") or F.findFolder(workspace,"LootSpawns")
        if lootFolder and obj:IsDescendantOf(lootFolder) then
            return cache(1)
        end
    end
    return nil
end
function F.buildLootCache(lootFolder)
    if St.Fl.lootCacheMap==lootFolder then return end
    if St.Cn.lootAdded then St.Cn.lootAdded:Disconnect(); St.Cn.lootAdded=nil end
    if St.Cn.lootRemoved then St.Cn.lootRemoved:Disconnect(); St.Cn.lootRemoved=nil end
    for k,v in pairs(St.Storage.Loot) do if v.bgui then F.safeDestroy(v.bgui) end end
    F.clearTable(St.Storage.Loot)
    St.Fl.lootCacheMap=lootFolder
    local function processObj(obj)
        local target=nil
        if obj:IsA("Model") then
            target=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        elseif obj:IsA("BasePart") then
            if obj.Parent and obj.Parent:IsA("Model") and obj.Parent~=lootFolder then
                return
            end
            target=obj
        end
        if target and not St.collectedLoot[target] then
            local val=F.getLootValue(obj)
            if val then
                if St.Storage.Loot[target] and St.Storage.Loot[target].bgui then
                    F.safeDestroy(St.Storage.Loot[target].bgui)
                end
                St.Storage.Loot[target]={target=target,src=obj,value=val}
                if St.Settings.LootESP and val>=St.MIN_LOOT_VALUE then
                    St.Storage.Loot[target].bgui=F.createLootBillboard(target,val)
                end
            end
        end
    end
    local descs=lootFolder:GetDescendants()
    local count=0
    for i=1,#descs do
        local obj=descs[i]
        if obj:IsA("Model") or obj:IsA("BasePart") then
            processObj(obj)
            count=count+1
            if count%50==0 then task.wait() end
        end
    end
    St.Cn.lootAdded=lootFolder.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") or obj:IsA("BasePart") then
            task.wait(0.1)
            if obj and obj.Parent then processObj(obj) end
        end
    end)
    St.Cn.lootRemoved=lootFolder.DescendantRemoving:Connect(function(obj)
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local target=obj
            if obj:IsA("Model") then
                target=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            end
            if target and St.Storage.Loot[target] then
                if St.Storage.Loot[target].bgui then
                    F.safeDestroy(St.Storage.Loot[target].bgui)
                end
                St.Storage.Loot[target]=nil
            end
        end
    end)
end
function F.updateLootESP()
    if not St.Settings.LootESP or F.getMyTeamType()=="lobby" then
        for k,v in pairs(St.Storage.Loot) do
            if v.bgui then F.safeDestroy(v.bgui); v.bgui=nil end
            St.Storage.Loot[k]=nil
        end
        return
    end
    local map=F.getMap()
    local lootFolder=F.findFolder(map,"LootSpawns") or F.findFolder(workspace,"LootSpawns")
    if not lootFolder then return end
    if St.Fl.lootCacheMap~=lootFolder then
        St.Fl.lootCacheMap=nil
        F.clearTable(St.Storage.Loot)
        task.spawn(function() F.buildLootCache(lootFolder) end)
        return
    else
        for k,v in pairs(St.Storage.Loot) do
            if not v.target or not v.target.Parent then
                if v.bgui then F.safeDestroy(v.bgui); v.bgui=nil end
                St.Storage.Loot[k]=nil
            elseif v.value>=St.MIN_LOOT_VALUE then
                if not v.bgui then
                    v.bgui=F.createLootBillboard(v.target,v.value)
                else
                    local vis=v.target.Transparency<0.9
                    if v.bgui.Enabled~=vis then v.bgui.Enabled=vis end
                end
            else
                if v.bgui then
                    F.safeDestroy(v.bgui)
                    v.bgui=nil
                    if v.target and v.target.Parent then
                        for _,child in ipairs(v.target:GetChildren()) do
                            if child:IsA("BillboardGui") and child.Name=="JxH_LootESP" then
                                F.safeDestroy(child)
                            end
                        end
                    end
                end
            end
        end
    end
end
function F.tryTriggerLoot(srcObj)
    if not srcObj then return end
    local ok,descs=pcall(function() return srcObj:GetDescendants() end)
    if not ok or not descs then return end
    for _,child in ipairs(descs) do
        if child:IsA("ProximityPrompt") and child.Enabled then
            pcall(function()
                local oldLos=child.RequiresLineOfSight
                local oldMax=child.MaxActivationDistance
                child.RequiresLineOfSight=false
                child.MaxActivationDistance=9e9
                fireproximityprompt(child)
                task.delay(0.5,function()
                    if child and child.Parent then
                        child.RequiresLineOfSight=oldLos
                        child.MaxActivationDistance=oldMax
                    end
                end)
            end)
        elseif child:IsA("ClickDetector") then
            pcall(function() fireclickdetector(child,0) end)
        end
    end
end
function F.startAutoFarm()
    if F.getMyTeamType()~="survivor" then return end
    if St.Fl.farmStoppedForRound then return end
    St.Fl.autoFarmRunning=false; St.farmLoopId=St.farmLoopId+1
    local myId=St.farmLoopId; task.wait(0.1)
    if myId~=St.farmLoopId then return end
    St.Fl.autoFarmRunning=true
    St.Fl.lastFarmPos=nil; St.Fl.lastFarmPosTime=tick()
    task.spawn(function()
        while St.Fl.autoFarmRunning and St.Settings.AutoFarmLoot and St.farmLoopId==myId do
            if F.getMyTeamType()~="survivor" then break end
            if St.Fl.farmStoppedForRound then break end
            if St.Fl.farmPaused or St.Fl.killerSafetyActive then task.wait(0.5)
            else
                local char=Sv.LocalPlayer.Character
                local root=char and char:FindFirstChild("HumanoidRootPart")
                local hum=char and char:FindFirstChildOfClass("Humanoid")
                if not root or not hum or hum.Health<=0 then task.wait(0.5)
                else
                    if hum.Sit then pcall(function() hum.Sit=false end) end
                    local rpos=root.Position
                    if rpos.Y<-80 then
                        F.ultraFastTeleport(Vector3_new(rpos.X,20,rpos.Z))
                        task.wait(0.3)
                    else
                        local now=tick()
                        if St.Fl.lastFarmPos and St.Settings.AntiAFK then
                            local dist=(rpos-St.Fl.lastFarmPos).Magnitude
                            if dist<0.5 and now-St.Fl.lastFarmPosTime>5 then
                                pcall(function() hum.Jump=true end)
                                St.Fl.lastFarmPosTime=now
                            elseif dist>0.5 then St.Fl.lastFarmPos=rpos; St.Fl.lastFarmPosTime=now end
                        else St.Fl.lastFarmPos=rpos end
                        local map=F.getMap()
                        local lootFolder=F.findFolder(map,"LootSpawns") or F.findFolder(workspace,"LootSpawns")
                        if not lootFolder then task.wait(0.8)
                        elseif St.Fl.lootCacheMap~=lootFolder then
                            St.Fl.lootCacheMap=nil
                            F.clearTable(St.Storage.Loot)
                            task.spawn(function() F.buildLootCache(lootFolder) end)
                            task.wait(0.5)
                        end
                        if not next(St.Storage.Loot) then task.wait(0.5) end
                        local bestTarget,bestEntry,bestVal=nil,nil,-1
                        for k,entry in pairs(St.Storage.Loot) do
                            if not St.collectedLoot[entry.target] and entry.target.Parent and entry.target.Transparency<0.9 and entry.value>=St.MIN_LOOT_VALUE then
                                if entry.value>bestVal then
                                    bestVal=entry.value
                                    bestTarget=entry.target
                                    bestEntry=entry
                                end
                            end
                        end
                        if not bestEntry then
                            St.Fl.lootCacheMap=nil
                            task.wait(1.2)
                        else
                            local best=bestTarget
                            local yOff=best:IsA("BasePart") and (best.Size.Y/2) or 1
                            F.ultraFastTeleport(Vector3_new(best.Position.X,best.Position.Y+yOff+2.5,best.Position.Z))
                            if St.farmSpeedPct>=180 then
                                if best.Parent then
                                    F.tryTriggerLoot(bestEntry.src)
                                    St.collectedLoot[best]=true
                                    St.Analytics.farmSuccess=St.Analytics.farmSuccess+1
                                    St.Analytics.coinsCollected=St.Analytics.coinsCollected+(bestEntry.value or 0)
                                    if bestEntry.bgui then F.safeDestroy(bestEntry.bgui) end
                                    St.Storage.Loot[best]=nil
                                end
                                task.wait(0.25)
                            else
                                task.wait(0.05)
                                if not (St.Fl.farmPaused or St.Fl.farmStoppedForRound or St.Fl.killerSafetyActive) then
                                    if best.Parent then
                                        F.tryTriggerLoot(bestEntry.src)
                                        task.wait(St.farmCollectDelay)
                                        St.collectedLoot[best]=true
                                        St.Analytics.farmSuccess=St.Analytics.farmSuccess+1
                                        St.Analytics.coinsCollected=St.Analytics.coinsCollected+(bestEntry.value or 0)
                                        if bestEntry.bgui then F.safeDestroy(bestEntry.bgui) end
                                        St.Storage.Loot[best]=nil
                                    else
                                        St.collectedLoot[best]=true
                                        St.Analytics.farmFail=St.Analytics.farmFail+1
                                        if bestEntry.bgui then F.safeDestroy(bestEntry.bgui) end
                                        St.Storage.Loot[best]=nil
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if St.farmLoopId==myId then St.Fl.autoFarmRunning=false end
    end)
end
function F.updateExitESP()
    for _,v in pairs(St.Storage.Exits) do F.safeDestroy(v) end
    F.clearTable(St.Storage.Exits)
    if not St.Settings.ExitESP or F.getMyTeamType()=="lobby" then return end
    task.spawn(function()
        local map=F.getMap(); if not map then return end
        local candidates={}
        local exitsFolder=F.findFolder(map,"Exits")
        if exitsFolder then
            for _,obj in ipairs(exitsFolder:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("Model") then table.insert(candidates,obj) end
            end
        end
        local count=0
        for _,obj in ipairs(map:GetDescendants()) do
            count=count+1; if count%100==0 then task.wait() end
            if not St.Settings.ExitESP then break end
            local n=obj.Name:lower()
            if n:find("exit") or n:find("gateway") then
                if obj:IsA("BasePart") or obj:IsA("Model") then table.insert(candidates,obj) end
            end
            if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
                local parent=obj.Parent
                if parent and (parent:IsA("BasePart") or parent:IsA("Model")) then table.insert(candidates,parent) end
            end
        end
        local unique={}
        for _,c in ipairs(candidates) do
            if not unique[c] then
                unique[c]=true
                local h=Instance_new("Highlight")
                h.Adornee=c; h.FillTransparency=1
                h.OutlineColor=Color3_fromRGB(0,255,120); h.OutlineTransparency=0
                h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Parent=c
                table.insert(St.Storage.Exits,h)
            end
        end
    end)
end
function F.stopInfiniteJump()
    St.Settings.InfiniteJump=false
    if St.Cn.infiniteJump then St.Cn.infiniteJump:Disconnect(); St.Cn.infiniteJump=nil end
end
function F.startInfiniteJump()
    F.stopInfiniteJump(); St.Settings.InfiniteJump=true
    St.Cn.infiniteJump=Sv.UserInputService.JumpRequest:Connect(function()
        if not St.Settings.InfiniteJump then F.stopInfiniteJump(); return end
        local char=Sv.LocalPlayer.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health>0 then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
    end)
end
local _voidSafetyCn=nil
local function _stopVoidSafetyBG()
    if _voidSafetyCn then pcall(function() _voidSafetyCn:Disconnect() end); _voidSafetyCn=nil end
end
local function _startVoidSafetyBG()
    if _voidSafetyCn then return end
    local timer=0
    _voidSafetyCn=Sv.RunService.Heartbeat:Connect(function(dt)
        if not St.Settings.AntiVoid then return end
        if F.getMyTeamType()=="lobby" then return end
        timer=timer+dt; if timer<0.2 then return end; timer=0
        local char=Sv.LocalPlayer.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if root.Position.Y<-25 or root.Velocity.Y<-250 then
            local lockers=F.getLockerModels()
            if #lockers>0 then
                local targetLocker=lockers[math.random(1,#lockers)]
                task.spawn(function() F.teleportInsideLocker(targetLocker) end)
            else
                task.spawn(function() F.ultraFastTeleport(Vector3_new(root.Position.X,35,root.Position.Z)) end)
            end
        end
    end)
end
function F.setupDoubleJump()
    local char=Sv.LocalPlayer.Character or Sv.LocalPlayer.CharacterAdded:Wait()
    if not char then return end
    local hum=char:WaitForChild("Humanoid",3)
    if not hum then return end
    local animator=hum:WaitForChild("Animator",3)
    if not animator then return end
    local anim=Instance_new("Animation"); anim.AnimationId=St.DOUBLE_JUMP_ANIM_ID
    St.jumpAnimTrack=animator:LoadAnimation(anim)
    St.jumpAnimTrack.Priority=Enum.AnimationPriority.Action
    if St.Connections.Jump then St.Connections.Jump:Disconnect() end
    if St.Connections.State then St.Connections.State:Disconnect() end
    St.Connections.Jump=Sv.UserInputService.JumpRequest:Connect(function()
        if not St.Settings.DoubleJump or not St.canJump2 or St.jumpCount>=2 then return end
        if F.isPlayerDowned(Sv.LocalPlayer) then return end
        hum:ChangeState(Enum.HumanoidStateType.Jumping); St.jumpCount=St.jumpCount+1
        if St.jumpAnimTrack then St.jumpAnimTrack:Stop(); St.jumpAnimTrack:Play() end
    end)
    St.Connections.State=hum.StateChanged:Connect(function(_,new)
        if new==Enum.HumanoidStateType.Landed then St.jumpCount,St.canJump2=0,false
        elseif new==Enum.HumanoidStateType.Freefall then task.wait(0.15); St.canJump2=true
        elseif new==Enum.HumanoidStateType.Jumping then St.jumpCount=St.jumpCount==0 and 1 or St.jumpCount end
    end)
end
function F.getExitParts()
    local map=F.getMap(); if not map then return {} end
    local parts={}; local seen={}
    local function addP(p)
        if p and p:IsA("BasePart") and not seen[p] then seen[p]=true; table.insert(parts,p) end
    end
    local exitsFolder=F.findFolder(map,"Exits")
    if exitsFolder then
        for _,obj in ipairs(exitsFolder:GetDescendants()) do
            if obj:IsA("Model") then
                local t=obj:FindFirstChild("Trigger") or obj.PrimaryPart
                if t and t:IsA("BasePart") then addP(t) end
            elseif obj:IsA("BasePart") then addP(obj) end
        end
    end
    for _,obj in ipairs(map:GetDescendants()) do
        local n=obj.Name:lower()
        if n:find("exit") or n:find("gateway") then
            if obj:IsA("BasePart") then addP(obj)
            elseif obj:IsA("Model") then
                local t=obj:FindFirstChild("Trigger") or obj.PrimaryPart
                if t then addP(t) end
            end
        end
    end
    return parts
end
function F.getReadyExit()
    local map=F.getMap(); if not map then return nil end
    local exitsFolder=F.findFolder(map,"Exits")
    if exitsFolder then
        for _,exitObj in ipairs(exitsFolder:GetChildren()) do
            local hasTrigger=false
            for _,desc in ipairs(exitObj:GetDescendants()) do
                if desc:IsA("TouchTransmitter") and desc.Parent and desc.Parent.Name=="Trigger" then
                    hasTrigger=true; break
                end
            end
            if hasTrigger then
                local bouncer=exitObj:FindFirstChild("Bouncer",true)
                local bouncerClear=(not bouncer or not bouncer:IsA("BasePart") or not bouncer.CanCollide)
                if bouncerClear then return exitObj end
            end
        end
    end
    return nil
end
function F.resolveGatePart(exitObj)
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
function F.doEscapeNow()
    local char=Sv.LocalPlayer.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health<=0 then return end
    local gatePart=nil
    local readyExit=F.getReadyExit()
    if readyExit then gatePart=F.resolveGatePart(readyExit) end
    if not gatePart then
        local parts=F.getExitParts(); if #parts==0 then return end
        local closest,minDist=parts[1],math.huge
        for _,p in ipairs(parts) do
            local d=(root.Position-p.Position).Magnitude
            if d<minDist then minDist=d; closest=p end
        end
        gatePart=closest
    end
    if not gatePart or not gatePart.Parent then return end
    F.ultraFastTeleport(gatePart.Position)
    task.wait(0.1)
    local map=F.getMap()
    if map then
        for _,obj in ipairs(map:GetDescendants()) do
            local n=obj.Name:lower()
            if n:find("exit") or n:find("gateway") or n:find("escape") or n:find("door") or n:find("gate") then
                if obj:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(obj) end)
                elseif obj:IsA("ClickDetector") then pcall(function() fireclickdetector(obj) end)
                elseif obj:IsA("TouchTransmitter") then
                    pcall(function()
                        firetouchinterest(root,obj.Parent,0)
                        task.wait()
                        firetouchinterest(root,obj.Parent,1)
                    end)
                end
            end
        end
    end
    task.wait(0.1)
    F.ultraFastTeleport((gatePart.CFrame*CFrame_new(0,0,-3)).Position)
    task.wait(0.1)
    F.ultraFastTeleport((gatePart.CFrame*CFrame_new(0,0,3)).Position)
    St.Analytics.escapeCount=St.Analytics.escapeCount+1
end
function F.teleportToNearestExit()
    if F.getMyTeamType()=="lobby" then return end
    local char=Sv.LocalPlayer.Character
    local root=char and char:FindFirstChild("HumanoidRootPart"); if not root then return end
    local parts=F.getExitParts(); if #parts==0 then return end
    local closest,minDist=parts[1],math.huge
    for _,p in ipairs(parts) do
        local d=(root.Position-p.Position).Magnitude
        if d<minDist then minDist=d; closest=p end
    end
    if not closest or not closest.Parent then return end
    local toPlayer=root.Position-closest.Position
    local safeDir=toPlayer.Magnitude>2 and toPlayer.Unit or -(closest.CFrame.LookVector)
    F.ultraFastTeleport(closest.Position+safeDir*8+Vector3_new(0,3.5,0))
    St.Analytics.escapeCount=St.Analytics.escapeCount+1
end
function F.stopAutoEscape()
    St.Fl.autoEscapeRunning=false
    if St.Cn.autoEscape then pcall(function() St.Cn.autoEscape:Disconnect() end); St.Cn.autoEscape=nil end
end
function F.startAutoEscape()
    if F.getMyTeamType()~="survivor" then return end
    St.Fl.autoEscapeRunning=false
    if St.Cn.autoEscape then pcall(function() St.Cn.autoEscape:Disconnect() end); St.Cn.autoEscape=nil end
    St.Fl.escapeCheckTimer=0; St.Fl.escapeTriggeredExternal=false
    St.Settings.AutoEscape=true; St.Fl.autoEscapeRunning=true
    local escapeTriggered=false
    local function doEscape()
        if escapeTriggered or not St.Settings.AutoEscape then return end
        escapeTriggered=true; St.Fl.escapeTriggeredExternal=true
        St.Fl.autoFarmRunning=false; St.Fl.farmStoppedForRound=true
        St.Fl.autoEscapeRunning=false
        if St.Cn.autoEscape then pcall(function() St.Cn.autoEscape:Disconnect() end); St.Cn.autoEscape=nil end
        task.spawn(function()
            F.doEscapeNow()
        end)
    end
    St.Cn.autoEscape=Sv.RunService.Heartbeat:Connect(function(dt)
        if F.getMyTeamType()~="survivor" then return end
        if not St.Settings.AutoEscape or not St.Fl.autoEscapeRunning or escapeTriggered then return end
        St.Fl.escapeCheckTimer=St.Fl.escapeCheckTimer+dt; if St.Fl.escapeCheckTimer<0.25 then return end; St.Fl.escapeCheckTimer=0
        local readyExit=F.getReadyExit()
        if readyExit then
            local gatePart=F.resolveGatePart(readyExit)
            local char=Sv.LocalPlayer.Character
            local root=char and char:FindFirstChild("HumanoidRootPart")
            if root and gatePart then
                if (root.Position-gatePart.Position).Magnitude<18 then
                    if not St.Fl._escapeWaitStart then
                        St.Fl._escapeWaitStart=os.clock()
                    end
                    if os.clock()-St.Fl._escapeWaitStart<2 then
                        return
                    end
                else
                    St.Fl._escapeWaitStart=nil
                end
            end
            doEscape()
        else
            St.Fl._escapeWaitStart=nil
        end
    end)
end
function F.stopFly()
    St.Settings.FlyEnabled=false
    if St.Cn.fly then St.Cn.fly:Disconnect(); St.Cn.fly=nil end
    local char=Sv.LocalPlayer.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local att=root:FindFirstChild("JxH_FlyAtt")
        local lv=root:FindFirstChild("JxH_FlyLv")
        local ao=root:FindFirstChild("JxH_FlyAo")
        if att then pcall(function() att:Destroy() end) end
        if lv then pcall(function() lv:Destroy() end) end
        if ao then pcall(function() ao:Destroy() end) end
    end
end
function F.startFly()
    if not St.Settings.FlyEnabled then return end
    local char=Sv.LocalPlayer.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local att=root:FindFirstChild("JxH_FlyAtt")
    if not att then
        att=Instance_new("Attachment")
        att.Name="JxH_FlyAtt"; att.Parent=root
    end
    local lv=root:FindFirstChild("JxH_FlyLv")
    if not lv then
        lv=Instance_new("LinearVelocity")
        lv.Name="JxH_FlyLv"; lv.MaxForce=math.huge
        lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector
        lv.Attachment0=att; lv.Parent=root
    end
    local ao=root:FindFirstChild("JxH_FlyAo")
    if not ao then
        ao=Instance_new("AlignOrientation")
        ao.Name="JxH_FlyAo"; ao.MaxTorque=math.huge
        ao.MaxAngularVelocity=math.huge; ao.Responsiveness=200
        ao.Mode=Enum.OrientationAlignmentMode.OneAttachment
        ao.Attachment0=att; ao.Parent=root
    end
    local cam=workspace.CurrentCamera
    if St.Cn.fly then St.Cn.fly:Disconnect() end
    St.Cn.fly=Sv.RunService.RenderStepped:Connect(function()
        if not St.Settings.FlyEnabled then F.stopFly(); return end
        if not hum or not root then return end
        local moveDir=hum.MoveDirection
        local flyVel=VEC3_ZERO
        if moveDir.Magnitude>0 then
            flyVel=moveDir*St.Fl.flySpeed
            local dot=moveDir:Dot(Vector3_new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z).Unit)
            if dot>0.5 then
                flyVel=flyVel+Vector3_new(0,cam.CFrame.LookVector.Y*St.Fl.flySpeed,0)
            elseif dot<-0.5 then
                flyVel=flyVel-Vector3_new(0,cam.CFrame.LookVector.Y*St.Fl.flySpeed,0)
            end
        end
        if St.flyKeys.up then flyVel=flyVel+Vector3_new(0,St.Fl.flySpeed,0) end
        if St.flyKeys.down then flyVel=flyVel-Vector3_new(0,St.Fl.flySpeed,0) end
        lv.VectorVelocity=flyVel
        ao.CFrame=cam.CFrame
    end)
end
function F.rebuildNoclipCache()
end
function F.startNoclip()
    if St.Cn.noclip then St.Cn.noclip:Disconnect() end
    St.Cn.noclip=Sv.RunService.Stepped:Connect(function()
        if not St.Settings.Noclip then return end
        local char=Sv.LocalPlayer.Character
        if char then
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide=false
                end
            end
        end
    end)
end
function F.stopNoclip()
    St.Settings.Noclip=false
    if St.Cn.noclip then St.Cn.noclip:Disconnect(); St.Cn.noclip=nil end
end
function F.toggleGhostMode(enable)
    if St.Fl.ghostDebounce then return end
    St.Fl.ghostDebounce=true
    task.delay(0.15,function() St.Fl.ghostDebounce=false end)
    local player=Sv.LocalPlayer
    if enable then
        if St.Settings.AutoFarmLoot or St.Settings.AutoRevive or St.Settings.AutoSelfRevive or St.Settings.KillerSafety or St.Settings.AutoEscape or St.Settings._killAll or St.Settings.Hitbox then
            if St.toggleRefs["GhostMode"] then St.toggleRefs["GhostMode"](false) end
            St.Settings.GhostMode=false
            local ui=Sv.CoreGui:FindFirstChild("JxH_UI") or Sv.LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("JxH_UI")
            if ui then UI.showToast(_T("ghost_farm_warn"),ui) end
            return
        end
        if St.Fl.ghostActive then return end
        local realChar=player.Character
        if not realChar then return end
        local realRoot=realChar:FindFirstChild("HumanoidRootPart")
        local realHum=realChar:FindFirstChildOfClass("Humanoid")
        if not realRoot or not realHum then return end
        pcall(function()
            realChar.Archivable=true
            local fakeChar=realChar:Clone()
            realChar.Archivable=false
            if not fakeChar then return end
            St.Fl.realChar=realChar
            fakeChar.Name=realChar.Name.."_Ghost"
            fakeChar.Parent=workspace
            St.Fl.fakeChar=fakeChar
            local fakeRoot=fakeChar:FindFirstChild("HumanoidRootPart")
            if fakeRoot then fakeRoot.CFrame=realRoot.CFrame end
            for _,part in ipairs(fakeChar:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored=false
                    part.Transparency=0.5
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    part.Transparency=0.5
                end
            end
            local fakeHum=fakeChar:FindFirstChildOfClass("Humanoid")
            if fakeHum then
                workspace.CurrentCamera.CameraSubject=fakeHum
                fakeHum.Died:Connect(function() pcall(function() F.toggleGhostMode(false) end) end)
            end
            realHum.Died:Connect(function() pcall(function() F.toggleGhostMode(false) end) end)
            realHum.WalkSpeed=0
            local safeCFrame=CFrame_new(54.907,265.321,-82.957,-0.731,-0.000,0.682,0.000,1.000,0.000,-0.682,0.000,-0.731)
            workspace:BulkMoveTo({realRoot},{safeCFrame})
            St.Fl.ghostSavedStates={}
            for _,desc in ipairs(realChar:GetDescendants()) do
                if desc:IsA("BasePart") then
                    St.Fl.ghostSavedStates[desc]={CanCollide=desc.CanCollide}
                    desc.CanCollide=false
                elseif desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") then
                    St.Fl.ghostSavedStates[desc]={Enabled=desc.Enabled}
                    desc.Enabled=false
                end
            end
            task.wait(0.25)
            realRoot.Anchored=true
            realRoot.Velocity=VEC3_ZERO
            realRoot.RotVelocity=VEC3_ZERO
            player.Character=fakeChar
            if fakeHum then fakeHum:ChangeState(Enum.HumanoidStateType.Running) end
            St.Fl.ghostActive=true
        end)
    else
        if not St.Fl.ghostActive then return end
        local fakeChar=St.Fl.fakeChar
        local realChar=St.Fl.realChar
        pcall(function()
            local returnCFrame=nil
            if fakeChar then
                local fakeRoot=fakeChar:FindFirstChild("HumanoidRootPart")
                if fakeRoot then returnCFrame=fakeRoot.CFrame end
            end
            if realChar then
                for desc,state in pairs(St.Fl.ghostSavedStates) do
                    if desc and desc.Parent then
                        if desc:IsA("BasePart") and state.CanCollide~=nil then
                            desc.CanCollide=state.CanCollide
                        elseif (desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam")) and state.Enabled~=nil then
                            desc.Enabled=state.Enabled
                        end
                    end
                end
                St.Fl.ghostSavedStates={}
                local realRoot=realChar:FindFirstChild("HumanoidRootPart")
                if realRoot then
                    realRoot.Anchored=false
                    if returnCFrame then workspace:BulkMoveTo({realRoot},{returnCFrame}) end
                    realRoot.Velocity=VEC3_ZERO
                    realRoot.RotVelocity=VEC3_ZERO
                end
            end
            task.wait(0.05)
            if realChar then
                player.Character=realChar
                local rHum=realChar:FindFirstChildOfClass("Humanoid")
                if rHum then
                    workspace.CurrentCamera.CameraSubject=rHum
                    if St.Settings.SpeedEnabled then rHum.WalkSpeed=St.Fl.currentSpeed else rHum.WalkSpeed=16 end
                    rHum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
                if St.Settings.SnowAnimation then
                    F.applySnowAnims(realChar)
                end
            end
            if fakeChar then fakeChar:Destroy() end
            St.Fl.fakeChar=nil
            St.Fl.realChar=nil
            St.Fl.ghostActive=false
        end)
    end
end
function F.getLockerModels()
    local now=tick()
    if now-St._lockerCache.time<4 and #St._lockerCache.models>0 then
        local valid=true
        for _,m in ipairs(St._lockerCache.models) do if not m or not m.Parent then valid=false; break end end
        if valid then return St._lockerCache.models end
    end
    local models={}; local seen={}; local map=F.getMap(); local folder=nil
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
        local searchRoot=map or workspace; local count=0
        for _,obj in ipairs(searchRoot:GetDescendants()) do
            count=count+1; if count%100==0 then task.wait() end
            if obj:IsA("Model") and not seen[obj] and obj~=Sv.LocalPlayer.Character then
                local n=obj.Name:lower()
                for _,kw in ipairs({"locker","wardrobe","cabinet","closet","hideout","armoire","coffin","chest"}) do
                    if n:find(kw) then seen[obj]=true; table.insert(models,obj); break end
                end
            end
        end
    end
    St._lockerCache.models=models; St._lockerCache.time=tick()
    return models
end
function F.teleportInsideLocker(lockerModel)
    local char=Sv.LocalPlayer.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not root or not lockerModel then return end
    local wallsPart=nil
    local charHeight=hum and math_max(hum.HipHeight+1.5,2.0) or 2.5
    for _,obj in ipairs(lockerModel:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name=="Walls" then wallsPart=obj; break end
    end
    local targetPos
    if wallsPart then
        targetPos=Vector3_new(wallsPart.Position.X,wallsPart.Position.Y-wallsPart.Size.Y/2+charHeight,wallsPart.Position.Z)
    else
        local ok,cf,size=pcall(function() return lockerModel:GetBoundingBox() end)
        if not ok or not cf then return end
        targetPos=Vector3_new(cf.Position.X,cf.Position.Y-size.Y/2+charHeight,cf.Position.Z)
    end
    local savedCollide={}
    if char then
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then savedCollide[p]=p.CanCollide; p.CanCollide=false end
        end
    end
    F.ultraFastTeleport(targetPos)
    task.delay(1.8,function()
        for p,col in pairs(savedCollide) do if p and p.Parent then pcall(function() p.CanCollide=col end) end end
    end)
end
function F.stopKillerSafety()
    St.Settings.KillerSafety=false
    if St.Cn.killerSafety then St.Cn.killerSafety:Disconnect(); St.Cn.killerSafety=nil end
    St.Fl.killerSafetyActive=false
end
function F.startKillerSafety()
    if F.getMyTeamType()~="survivor" then return end
    if St.Cn.killerSafety then St.Cn.killerSafety:Disconnect(); St.Cn.killerSafety=nil end
    St.Fl.killerSafetyActive=false; St.Settings.KillerSafety=true
    local lastTriggered=0; local safetyTimer=0
    St.Cn.killerSafety=Sv.RunService.Heartbeat:Connect(function(dt)
        if not St.Settings.KillerSafety then F.stopKillerSafety(); return end
        if F.isPlayerDowned(Sv.LocalPlayer) then
            St.Fl.killerSafetyActive=false
            return
        end
        if St.Fl.killerSafetyActive then return end
        safetyTimer=safetyTimer+dt; if safetyTimer<0.3 then return end; safetyTimer=0
        local now=tick(); if now-lastTriggered<3 then return end
        local myChar=Sv.LocalPlayer.Character
        local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum=myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myRoot or not myHum or myHum.Health<=0 then return end
        local closestKiller,closestDist=nil,math.huge
        for _,p in ipairs(Sv.Players:GetPlayers()) do
            if p~=Sv.LocalPlayer then
                local kRoot=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if kRoot then
                    local dist=(myRoot.Position-kRoot.Position).Magnitude
                    if dist<=St.Fl.killerSafetyDist and F.isKillerPlayer(p) and dist<closestDist then
                        closestDist=dist; closestKiller=kRoot
                    end
                end
            end
        end
        if not closestKiller then return end
        lastTriggered=now
        task.spawn(function()
            local lockers=F.getLockerModels(); if #lockers==0 then return end
            local farthest,maxDist=lockers[1],0
            for _,lm in ipairs(lockers) do
                local ok,cf=pcall(function() return lm:GetBoundingBox() end)
                if ok and cf then
                    local d=(closestKiller.Position-cf.Position).Magnitude
                    if d>maxDist then maxDist=d; farthest=lm end
                end
            end
            St.Fl.killerSafetyActive=true
            local wasFarming=St.Fl.autoFarmRunning; St.Fl.autoFarmRunning=false
            task.spawn(function() F.teleportInsideLocker(farthest) end)
            task.delay(4,function()
                St.Fl.killerSafetyActive=false
                if wasFarming and St.Settings.AutoFarmLoot and not St.Fl.farmStoppedForRound then F.startAutoFarm() end
            end)
        end)
    end)
end
function F.stopKillAll() St.Fl.killAllRunning=false; St.Settings._killAll=false end
function F.startKillAll()
    if F.getMyTeamType()~="killer" then return end
    if St.Fl.killAllRunning then return end
    St.Fl.killAllRunning=true; St.Settings._killAll=true
    task.spawn(function()
        local function getSurvivorRoots()
            local list={}
            for _,p in ipairs(_getPlayers()) do
                if p~=Sv.LocalPlayer then
                    local pRoot=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    local pHum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                    if pRoot and pHum and pHum.Health>0 then
                        local team=p.Team
                        if team then
                            local t=team.Name:lower()
                            if t:find("survivor") or t:find("innocent") or t:find("hider") then table.insert(list,pRoot) end
                        elseif not F.isKillerPlayer(p) then table.insert(list,pRoot) end
                    end
                end
            end
            return list
        end
        while St.Fl.killAllRunning and St.Settings._killAll do
            local myRoot=Sv.LocalPlayer.Character and Sv.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then task.wait(0.1)
            else
                local survivors=getSurvivorRoots()
                if #survivors==0 then task.wait(0.5)
                else
                    local targetCF=myRoot.CFrame*CFrame_new(0,0,-3.5)
                    for _,pr in ipairs(survivors) do
                        if not St.Fl.killAllRunning then break end
                        if pr and pr.Parent then pcall(function() pr.CFrame=targetCF; pr.Velocity=VEC3_ZERO end) end
                    end
                    task.wait(0.1)
                end
            end
        end
        St.Fl.killAllRunning=false; St.Settings._killAll=false
    end)
end
local VEC3_NORM_HRP=Vector3_new(2,2,1)
function F.stopHitbox()
    St.Settings.Hitbox=false
    if St.Cn.hitbox then St.Cn.hitbox:Disconnect(); St.Cn.hitbox=nil end
    for _,p in ipairs(Sv.Players:GetPlayers()) do
        if p~=Sv.LocalPlayer then
            local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if r and r.Size.X~=2 then r.Size=VEC3_NORM_HRP; r.Transparency=1 end
        end
    end
end
function F.startHitbox()
    if F.getMyTeamType()~="killer" then return end
    F.stopHitbox(); St.Settings.Hitbox=true
    local hbTimer=0
    St.Cn.hitbox=Sv.RunService.Heartbeat:Connect(function(dt)
        if not St.Settings.Hitbox or F.getMyTeamType()~="killer" then F.stopHitbox(); return end
        hbTimer=hbTimer+dt; if hbTimer<0.2 then return end; hbTimer=0
        local myChar=Sv.LocalPlayer.Character
        local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local hr=St.Fl.hitboxRadius
        local targetSize=Vector3_new(hr,hr,hr)
        local myPos=myRoot.Position
        for _,p in ipairs(_getPlayers()) do
            if p~=Sv.LocalPlayer then
                local char=p.Character
                local root=char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local hum=char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health>0 then
                        local isSurv=false
                        local team=p.Team
                        if team then
                            local t=team.Name:lower()
                            if t:find("survivor") or t:find("innocent") or t:find("hider") then isSurv=true end
                        elseif not F.isKillerPlayer(p) then isSurv=true end
                        if isSurv then
                            local dist=(myPos-root.Position).Magnitude
                            if dist<=hr then
                                if root.Size.X~=hr then
                                    root.Size=targetSize
                                    root.Transparency=0.7
                                    root.CanCollide=false
                                end
                            else
                                if root.Size.X~=2 then
                                    root.Size=VEC3_NORM_HRP
                                    root.Transparency=1
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end
function F.enableFogRemoval()
    if St.Cn.fog then St.Cn.fog:Disconnect(); St.Cn.fog=nil end
    if St.Cn.fogEC then St.Cn.fogEC:Disconnect(); St.Cn.fogEC=nil end
    if St.Cn.fogCC then St.Cn.fogCC:Disconnect(); St.Cn.fogCC=nil end
    if St.Cn.fogCam then St.Cn.fogCam:Disconnect(); St.Cn.fogCam=nil end
    if St.Fl.fogLoopRunning then return end
    St.Fl.fogLoopRunning=true
    local cam=workspace.CurrentCamera
    local function _clearColorEffect(obj)
        if obj:IsA("ColorCorrectionEffect") then
            pcall(function()
                obj.TintColor=Color3_new(1,1,1)
                obj.Brightness=0
                obj.Contrast=0
                obj.Saturation=0
            end)
        end
    end
    local function _clearAll()
        Sv.Lighting.FogEnd=1e9; Sv.Lighting.FogStart=1e9-100
        Sv.Lighting.ExposureCompensation=0
        Sv.Lighting.Ambient=Color3_new(1,1,1)
        Sv.Lighting.OutdoorAmbient=Color3_new(1,1,1)
        Sv.Lighting.ColorShift_Bottom=Color3_new(0,0,0)
        Sv.Lighting.ColorShift_Top=Color3_new(0,0,0)
        Sv.Lighting.ClockTime=14
        Sv.Lighting.Brightness=2
        Sv.Lighting.GlobalShadows=false
        for _,obj in ipairs(Sv.Lighting:GetChildren()) do
            if obj:IsA("Atmosphere") then obj.Density=0; obj.Haze=0; obj.Glare=0; obj.Offset=0 end
            _clearColorEffect(obj)
        end
        if cam and cam.Parent then
            for _,obj in ipairs(cam:GetChildren()) do _clearColorEffect(obj) end
        end
    end
    task.spawn(function()
        while St.Fl.fogLoopRunning and St.Settings.RemoveFog do
            pcall(_clearAll)
            task.wait(1)
        end
        St.Fl.fogLoopRunning=false
    end)
    St.Cn.fogEC=Sv.Lighting:GetPropertyChangedSignal("ExposureCompensation"):Connect(function()
        if St.Settings.RemoveFog then pcall(function() Sv.Lighting.ExposureCompensation=0 end) end
    end)
    local function _onChildAdded(child)
        if not St.Settings.RemoveFog then return end
        task.defer(function()
            if child and child.Parent then
                if child:IsA("Atmosphere") then child.Density=0; child.Haze=0; child.Glare=0; child.Offset=0 end
                pcall(function() _clearColorEffect(child) end)
            end
        end)
    end
    St.Cn.fog=Sv.Lighting.ChildAdded:Connect(_onChildAdded)
    St.Cn.fogCC=Sv.Lighting.DescendantAdded:Connect(function(child)
        if not St.Settings.RemoveFog then return end
        task.defer(function() if child and child.Parent then pcall(function() _clearColorEffect(child) end) end end)
    end)
    St.Cn.fogCam=cam.ChildAdded:Connect(function(child)
        if not St.Settings.RemoveFog then return end
        task.defer(function() if child and child.Parent then pcall(function() _clearColorEffect(child) end) end end)
    end)
end
function F.disableFogRemoval()
    St.Settings.RemoveFog=false; St.Fl.fogLoopRunning=false
    Sv.Lighting.FogEnd=St.OriginalFog.FogEnd; Sv.Lighting.FogStart=St.OriginalFog.FogStart
    Sv.Lighting.Ambient=St.OriginalFog.Ambient
    Sv.Lighting.OutdoorAmbient=St.OriginalFog.OutdoorAmbient
    Sv.Lighting.ColorShift_Bottom=St.OriginalFog.ColorShift_Bottom
    Sv.Lighting.ColorShift_Top=St.OriginalFog.ColorShift_Top
    Sv.Lighting.ClockTime=St.OriginalFog.ClockTime
    Sv.Lighting.Brightness=St.OriginalFog.Brightness
    Sv.Lighting.GlobalShadows=St.OriginalFog.GlobalShadows
    for obj,vals in pairs(St.OriginalAtmosphere) do
        if obj and obj.Parent then pcall(function() obj.Density=vals.Density; obj.Haze=vals.Haze end) end
    end
    if St.Cn.fog then St.Cn.fog:Disconnect(); St.Cn.fog=nil end
    if St.Cn.fogEC then St.Cn.fogEC:Disconnect(); St.Cn.fogEC=nil end
    if St.Cn.fogCC then St.Cn.fogCC:Disconnect(); St.Cn.fogCC=nil end
    if St.Cn.fogCam then St.Cn.fogCam:Disconnect(); St.Cn.fogCam=nil end
end
function F.stopAntiAFK()
    St.Settings.AntiAFK=false
    if St.Cn.antiAfk then St.Cn.antiAfk:Disconnect(); St.Cn.antiAfk=nil end
    if St.Cn.watchdog then St.Cn.watchdog:Disconnect(); St.Cn.watchdog=nil end
end
function F.startAntiAFK()
    F.stopAntiAFK(); St.Settings.AntiAFK=true
    local afkTimer=0; local wdTimer=0
    local ok,VU=pcall(function() return game:GetService("VirtualUser") end)
    if not ok then VU=nil end
    St.Cn.antiAfk=Sv.RunService.Heartbeat:Connect(function(dt)
        if not St.Settings.AntiAFK then F.stopAntiAFK(); return end
        afkTimer=afkTimer+dt; wdTimer=wdTimer+dt
        if afkTimer>=35 then
            afkTimer=0
            pcall(function()
                if VU then
                    VU:Button1Down(Vector2.new(math.random(100,700),math.random(100,500)),workspace.CurrentCamera.CFrame)
                    task.wait(0.05)
                    VU:Button1Up(Vector2.new(math.random(100,700),math.random(100,500)),workspace.CurrentCamera.CFrame)
                end
                local char=Sv.LocalPlayer.Character
                local hum=char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health>0 then
                    if hum.Sit then hum.Sit=false end
                    hum.Jump=true
                end
            end)
        end
        if wdTimer>=10 then
            wdTimer=0
            pcall(function()
                if St.Settings.AutoFarmLoot and not St.Fl.autoFarmRunning
                   and not St.Fl.farmStoppedForRound and F.getMyTeamType()=="survivor" then
                    F.startAutoFarm()
                end
                if St.Settings.AutoRevive and not St.Fl.autoReviveRunning then F.startAutoRevive() end
                if St.Settings.AutoSelfRevive and not St.Cn.autoSelfRevive then F.startAutoSelfRevive() end
                if St.Settings.KillerSafety and not St.Cn.killerSafety then F.startKillerSafety() end
            end)
        end
    end)
end
function F.teleportToRandomSurvivor()
    if F.getMyTeamType()~="survivor" then return end
    local survivors={}
    for _,p in ipairs(Sv.Players:GetPlayers()) do
        if p~=Sv.LocalPlayer then
            local team=p.Team
            if team then
                local t=team.Name:lower()
                if t:find("survivor") or t:find("innocent") or t:find("hider") then
                    local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                    if root and hum and hum.Health>0 then table.insert(survivors,root) end
                end
            end
        end
    end
    if #survivors==0 then return end
    local target=survivors[math.random(#survivors)]
    local myRoot=Sv.LocalPlayer.Character and Sv.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myRoot and target and target.Parent then
        F.ultraFastTeleport(target.Position+Vector3_new(2,0,0))
    end
end
function F.stopReviveFollow()
    if St.Cn.reviveFollow then pcall(function() St.Cn.reviveFollow:Disconnect() end); St.Cn.reviveFollow=nil end
    St.Fl.farmPaused=false
end
function F.stopAutoRevive()
    St.Fl.autoReviveRunning=false
    if St.Cn.autoRevive then pcall(function() St.Cn.autoRevive:Disconnect() end); St.Cn.autoRevive=nil end
    F.stopReviveFollow(); F.clearTable(St.reviveTracking)
end
function F.startAutoRevive()
    if St.Fl._reviveStarting then return end
    St.Fl._reviveStarting=true
    if F.getMyTeamType()~="survivor" then St.Fl._reviveStarting=false; return end
    F.stopAutoRevive(); task.wait(0.05)
    St.Fl._reviveStarting=false
    St.reviveLoopId=St.reviveLoopId+1
    local myId=St.reviveLoopId
    St.Settings.AutoRevive=true; St.Fl.autoReviveRunning=true
    if St.Settings.KillerSafety and not St.Cn.killerSafety then F.startKillerSafety() end
    local checkTimer=0; local activeReviveUid=nil
    St.Cn.autoRevive=Sv.RunService.Heartbeat:Connect(function(dt)
        if myId~=St.reviveLoopId then St.Fl.autoReviveRunning=false; St.Cn.autoRevive:Disconnect(); St.Cn.autoRevive=nil; return end
        if not St.Settings.AutoRevive or not St.Fl.autoReviveRunning then return end
        if F.getMyTeamType()~="survivor" then F.stopAutoRevive(); return end
        if F.isPlayerDowned(Sv.LocalPlayer) then
            if activeReviveUid then
                St.reviveTracking[activeReviveUid]=nil
                activeReviveUid=nil
                F.stopReviveFollow()
            end
            return
        end
        checkTimer=checkTimer+dt; if checkTimer<0.3 then return end; checkTimer=0
        local now=tick()
        for _,p in ipairs(Sv.Players:GetPlayers()) do
            if p~=Sv.LocalPlayer then
                local team=p.Team
                if team then
                    local t=team.Name:lower()
                    if t:find("survivor") or t:find("innocent") or t:find("hider") then
                        local uid=p.UserId
                        if F.isPlayerDowned(p) then
                            if not St.reviveTracking[uid] then St.reviveTracking[uid]={player=p,downTime=now} end
                        else
                            if St.reviveTracking[uid] then
                                St.reviveTracking[uid]=nil
                                if activeReviveUid==uid then activeReviveUid=nil; F.stopReviveFollow() end
                            end
                        end
                    end
                end
            end
        end
        for uid in pairs(St.reviveTracking) do
            local data=St.reviveTracking[uid]
            if not data.player or not data.player.Parent then
                St.reviveTracking[uid]=nil
                if activeReviveUid==uid then activeReviveUid=nil; F.stopReviveFollow() end
            end
        end
        if activeReviveUid and St.reviveTracking[activeReviveUid] then return end
        if activeReviveUid and not St.reviveTracking[activeReviveUid] then activeReviveUid=nil; F.stopReviveFollow() end
        local myChar=Sv.LocalPlayer.Character
        local myHum=myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myHum or myHum.Health<=0 then return end
        local bestUid,bestAge=nil,0
        for uid,data in pairs(St.reviveTracking) do
            local age=now-data.downTime
            if age>=5 and age>bestAge then bestAge=age; bestUid=uid end
        end
        if not bestUid then return end
        local data=St.reviveTracking[bestUid]
        local p=data.player
        local pRoot=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if not pRoot or not pRoot.Parent or not F.isPlayerDowned(p) then St.reviveTracking[bestUid]=nil; return end
        activeReviveUid=bestUid; St.Fl.farmPaused=true
        local followTimer=0
        St.Cn.reviveFollow=Sv.RunService.Heartbeat:Connect(function(fdt)
            if not St.Settings.AutoRevive then St.Fl.farmPaused=false; F.stopReviveFollow(); activeReviveUid=nil; return end
            if St.Fl.killerSafetyActive then return end
            if not F.isPlayerDowned(p) or not pRoot.Parent then
                St.reviveTracking[bestUid]=nil; activeReviveUid=nil
                St.Fl.farmPaused=false; F.stopReviveFollow(); return
            end
            followTimer=followTimer+fdt; if followTimer<0.08 then return end; followTimer=0
            local myR=Sv.LocalPlayer.Character and Sv.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myR then return end
            task.spawn(function()
                pcall(function()
                    F.ultraFastTeleport(pRoot.Position+Vector3_new(2,0,0))
                end)
                F.tryTriggerLoot(p.Character)
            end)
        end)
    end)
end
function F.reviveMySelf()
    if F.getMyTeamType()~="survivor" then return end
    local myChar=Sv.LocalPlayer.Character
    local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart"); if not myRoot then return end
    St.Fl.reviveSelfPaused=true; F.stopReviveFollow()
    if St.Cn.selfReviveFollow then pcall(function() St.Cn.selfReviveFollow:Disconnect() end); St.Cn.selfReviveFollow=nil end
    local farthestRoot,maxDist=nil,0
    for _,p in ipairs(Sv.Players:GetPlayers()) do
        if p~=Sv.LocalPlayer then
            local team=p.Team
            if team then
                local t=team.Name:lower()
                if t:find("survivor") or t:find("innocent") or t:find("hider") then
                    if not F.isPlayerDowned(p) then
                        local pRoot=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                        local pHum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                        if pRoot and pHum and pHum.Health>0 then
                            local d=(myRoot.Position-pRoot.Position).Magnitude
                            if d>maxDist then maxDist=d; farthestRoot=pRoot end
                        end
                    end
                end
            end
        end
    end
    if farthestRoot and farthestRoot.Parent then
        St.Cn.selfReviveFollow=Sv.RunService.Heartbeat:Connect(function()
            if not St.Settings.AutoSelfRevive or not F.isPlayerDowned(Sv.LocalPlayer) or not farthestRoot.Parent then
                if St.Cn.selfReviveFollow then pcall(function() St.Cn.selfReviveFollow:Disconnect() end); St.Cn.selfReviveFollow=nil end
                St.Fl.reviveSelfPaused=false
                return
            end
            F.ultraFastTeleport(farthestRoot.Position+Vector3_new(2,0,0))
        end)
    else
        task.delay(2.5,function() St.Fl.reviveSelfPaused=false end)
    end
end
function F.stopAutoSelfRevive()
    if St.Cn.autoSelfRevive then pcall(function() St.Cn.autoSelfRevive:Disconnect() end); St.Cn.autoSelfRevive=nil end
    if St.Cn.selfReviveFollow then pcall(function() St.Cn.selfReviveFollow:Disconnect() end); St.Cn.selfReviveFollow=nil end
    St.Fl.reviveSelfPaused=false
end
function F.startAutoSelfRevive()
    if F.getMyTeamType()~="survivor" then return end
    F.stopAutoSelfRevive(); task.wait(0.05)
    St.selfReviveLoopId=St.selfReviveLoopId+1
    local myId=St.selfReviveLoopId
    St.Settings.AutoSelfRevive=true
    local selfTimer=0; local lastSelf=0
    St.Cn.autoSelfRevive=Sv.RunService.Heartbeat:Connect(function(dt)
        if myId~=St.selfReviveLoopId then St.Cn.autoSelfRevive:Disconnect(); St.Cn.autoSelfRevive=nil; return end
        if not St.Settings.AutoSelfRevive then F.stopAutoSelfRevive(); return end
        if F.getMyTeamType()~="survivor" then F.stopAutoSelfRevive(); return end
        selfTimer=selfTimer+dt; if selfTimer<0.5 then return end; selfTimer=0
        local now=tick(); if now-lastSelf<5 then return end
        if St.Fl.farmStoppedForRound then return end
        if F.isPlayerDowned(Sv.LocalPlayer) then lastSelf=now; F.reviveMySelf() end
    end)
end
local _SNOW_IDLE="rbxassetid://122257458498464"
local _SNOW_RUN="rbxassetid://82598234841035"
local _SNOW_JUMP="rbxassetid://75290611992385"
local _SNOW_CLIMB="rbxassetid://88763136693023"
local _SNOW_SWIM="rbxassetid://109346520324160"
function F._cleanSnowState()
    if St._snowConns then
        for _,c in ipairs(St._snowConns) do
            pcall(function() c:Disconnect() end)
        end
        St._snowConns=nil
    end
    if St._snowTracks then
        for _,t in pairs(St._snowTracks) do
            pcall(function() t:Stop(0.2) end)
        end
        St._snowTracks=nil
    end
end
function F.applySnowAnims(char)
    if not char then return end
    if F.getMyTeamType()=="killer" then
        F.stopSnowAnimation(true)
        return
    end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator=hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    F.stopSnowAnimation(true)
    local animateScript=char:FindFirstChild("Animate")
    if animateScript then animateScript.Disabled=true end
    for _,track in ipairs(animator:GetPlayingAnimationTracks()) do
        pcall(function() track:Stop(0) end)
    end
    local function loadAnim(id,looped)
        local anim=Instance_new("Animation")
        anim.AnimationId=id
        local track=animator:LoadAnimation(anim)
        track.Priority=Enum.AnimationPriority.Movement
        track.Looped=looped
        return track
    end
    St._snowTracks={
        idle=loadAnim(_SNOW_IDLE,true),
        run=loadAnim(_SNOW_RUN,true),
        jump=loadAnim(_SNOW_JUMP,false),
        climb=loadAnim(_SNOW_CLIMB,true),
        swim=loadAnim(_SNOW_SWIM,true)
    }
    local currentTrack=nil
    local function playTrack(trackName,transition)
        local track=St._snowTracks[trackName]
        if currentTrack==track then return end
        if currentTrack then currentTrack:Stop(transition or 0.2) end
        currentTrack=track
        if track then track:Play(transition or 0.2) end
    end
    local function updateState()
        if F.isPlayerDowned(Sv.LocalPlayer) then
            if currentTrack then currentTrack:Stop(0.2); currentTrack=nil end
            return
        end
        local state=hum:GetState()
        if state==Enum.HumanoidStateType.Freefall or state==Enum.HumanoidStateType.Jumping then
            playTrack("jump",0)
        elseif state==Enum.HumanoidStateType.Climbing then
            playTrack("climb")
        elseif state==Enum.HumanoidStateType.Swimming then
            playTrack("swim")
        elseif state==Enum.HumanoidStateType.Landed or state==Enum.HumanoidStateType.Running or state==Enum.HumanoidStateType.RunningNoPhysics then
            if hum.MoveDirection.Magnitude>0 then
                playTrack("run")
            else
                playTrack("idle")
            end
        else
            playTrack("idle")
        end
    end
    local wasDown=false
    local stateConn=hum.StateChanged:Connect(function(_,newState)
        if F.isPlayerDowned(Sv.LocalPlayer) then
            wasDown=true
            if currentTrack then currentTrack:Stop(0.2); currentTrack=nil end
            return
        end
        if newState==Enum.HumanoidStateType.GettingUp then
            if currentTrack then currentTrack:Stop(0); currentTrack=nil end
            return
        end
        if wasDown then
            wasDown=false
            if currentTrack then currentTrack:Stop(0); currentTrack=nil end
            task.delay(0.15,function()
                if St.Settings.SnowAnimation then
                    local c=Sv.LocalPlayer.Character
                    if c then F.applySnowAnims(c) end
                end
            end)
            return
        end
        updateState()
    end)
    local runConn=hum.Running:Connect(function(speed)
        if F.isPlayerDowned(Sv.LocalPlayer) then
            if currentTrack then currentTrack:Stop(0.2); currentTrack=nil end
            return
        end
        local state=hum:GetState()
        if state==Enum.HumanoidStateType.Freefall or state==Enum.HumanoidStateType.Jumping then return end
        if speed>0.5 then
            playTrack("run")
            pcall(function() St._snowTracks.run:AdjustSpeed(math_max(0.5,math_min(2,speed/16))) end)
        else
            playTrack("idle")
        end
    end)
    St._snowConns={stateConn,runConn}
    updateState()
end
function F.stopSnowAnimation(keepSetting)
    if not keepSetting then St.Settings.SnowAnimation=false end
    if St.Cn.snowRefresh then St.Cn.snowRefresh:Disconnect(); St.Cn.snowRefresh=nil end
    F._cleanSnowState()
    local char=Sv.LocalPlayer.Character
    if char then
        local animateScript=char:FindFirstChild("Animate")
        if animateScript then animateScript.Disabled=false end
    end
end
local _fpsBoostOriginals={qualityLevel=nil,globalShadows=nil,atmospheres={},particles={}}
function F.startFpsBoost()
    St.Settings.FpsBoost=true
    pcall(function()
        _fpsBoostOriginals.qualityLevel=settings().Rendering.QualityLevel
        settings().Rendering.QualityLevel=Enum.QualityLevel.Level01
    end)
    _fpsBoostOriginals.globalShadows=Sv.Lighting.GlobalShadows
    pcall(function() Sv.Lighting.GlobalShadows=false end)
    F.clearTable(_fpsBoostOriginals.atmospheres)
    for _,obj in ipairs(Sv.Lighting:GetChildren()) do
        if obj:IsA("Atmosphere") then
            _fpsBoostOriginals.atmospheres[obj]={Density=obj.Density,Haze=obj.Haze,Glare=obj.Glare,Blur=obj.Blur}
            pcall(function()
                obj.Density=0
                obj.Haze=0
                obj.Glare=0
                obj.Blur=0
            end)
        end
    end
    F.clearTable(_fpsBoostOriginals.particles)
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            pcall(function()
                _fpsBoostOriginals.particles[obj]=obj.Enabled
                obj.Enabled=false
            end)
        end
    end
end
function F.stopFpsBoost()
    St.Settings.FpsBoost=false
    pcall(function()
        settings().Rendering.QualityLevel=_fpsBoostOriginals.qualityLevel or Enum.QualityLevel.Automatic
    end)
    if _fpsBoostOriginals.globalShadows~=nil then
        pcall(function() Sv.Lighting.GlobalShadows=_fpsBoostOriginals.globalShadows end)
        _fpsBoostOriginals.globalShadows=nil
    end
    for obj,vals in pairs(_fpsBoostOriginals.atmospheres) do
        if obj and obj.Parent then
            pcall(function()
                obj.Density=vals.Density
                obj.Haze=vals.Haze
                obj.Glare=vals.Glare
                obj.Blur=vals.Blur
            end)
        end
    end
    for obj,wasEnabled in pairs(_fpsBoostOriginals.particles) do
        if obj and obj.Parent then
            pcall(function() obj.Enabled=wasEnabled end)
        end
    end
    F.clearTable(_fpsBoostOriginals.particles)
    F.clearTable(_fpsBoostOriginals.atmospheres)
    _fpsBoostOriginals.qualityLevel=nil
end
function F.saveSettings()
    local now=tick()
    if now-St._lastSaveTime<1 then return end
    St._lastSaveTime=now
    pcall(function()
        local data={
            s={},sp=St.Fl.currentSpeed,flsp=St.Fl.flySpeed,
            fsp=St.farmSpeedPct,
            kd=St.Fl.killerSafetyDist,lv=St.MIN_LOOT_VALUE,hr=St.Fl.hitboxRadius,
            no=St.NameSettings.OffsetY,do_=St.DistSettings.OffsetY,
            ls={oy=St.LivesSettings.OffsetY,ox=St.LivesSettings.OffsetX,hs=St.LivesSettings.HeartSize},
            ws=St.Fl.winSize,hs2=St.Fl.hudSize,bgt=St.Fl.bgTransparency,
            th=St.Settings.ThemeHue
        }
        for k,v in pairs(St.Settings) do data.s[k]=v end
        if St.MainBtn_ref and St.MainBtn_ref.Parent then
            data.bx=St.MainBtn_ref.AbsolutePosition.X
            data.by=St.MainBtn_ref.AbsolutePosition.Y
        end
        writefile(St.SAVE_FILE,Sv.HttpService:JSONEncode(data))
    end)
end
function F.loadSettings()
    pcall(function()
        if not isfile(St.SAVE_FILE) then return end
        local raw=readfile(St.SAVE_FILE)
        local data=Sv.HttpService:JSONDecode(raw)
        if not data then return end
        if type(data.s)=="table" then
            for k,v in pairs(data.s) do 
                if St.Settings[k]~=nil then 
                    if k=="GhostMode" or k=="FlyEnabled" or k=="Noclip" or k=="SpeedEnabled" then
                        St.Settings[k]=false
                    else
                        St.Settings[k]=v 
                    end
                end 
            end
        end
        if data.sp then St.Fl.currentSpeed=data.sp end
        if data.flsp then St.Fl.flySpeed=data.flsp end
        if data.fsp then
            St.farmSpeedPct=math.clamp(data.fsp,0,180)
            local function _pctToDelay(pct)
                if pct>=180 then return 0 end
                if pct<=100 then return 3.0-(pct/100)*2.0 end
                return 1.0-((pct-100)/80)*0.95
            end
            St.farmCollectDelay=_pctToDelay(St.farmSpeedPct)
        end
        if data.kd then St.Fl.killerSafetyDist=data.kd end
        if data.hr then St.Fl.hitboxRadius=data.hr end
        if data.lv then St.MIN_LOOT_VALUE=data.lv end
        if data.no then St.NameSettings.OffsetY=data.no end
        if data.do_ then St.DistSettings.OffsetY=data.do_ end
        if type(data.ls)=="table" then
            if data.ls.oy then St.LivesSettings.OffsetY=data.ls.oy end
            if data.ls.ox then St.LivesSettings.OffsetX=data.ls.ox end
            if data.ls.hs then St.LivesSettings.HeartSize=data.ls.hs end
        end
        if data.ws then St.Fl.winSize=data.ws end
        if data.hs2 then St.Fl.hudSize=data.hs2 end
        if data.bgt then St.Fl.bgTransparency=data.bgt end
        if data.th then St.Settings.ThemeHue=data.th end
        if data.bx and data.by then St._savedBtnPos=Vector2.new(data.bx,data.by) end
    end)
end
Sv.UserInputService.InputChanged:Connect(function(inp)
    if not St._sliderDragId then return end
    local sd=St._sliderDrags[St._sliderDragId]
    if not sd then St._sliderDragId=nil; return end
    if inp.UserInputType==Enum.UserInputType.MouseMovement
    or inp.UserInputType==Enum.UserInputType.Touch then
        local track=sd.track
        if not track or not track.Parent then St._sliderDragId=nil; return end
        local abs=track.AbsoluteSize.X; if abs==0 then return end
        local f=(inp.Position.X-track.AbsolutePosition.X)/abs
        sd.apply(f)
    end
end)
Sv.UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1
    or inp.UserInputType==Enum.UserInputType.Touch then
        St._sliderDragId=nil
    end
end)
function F.rejoinServer()
    local ts=game:GetService("TeleportService")
    local p=Sv.Players.LocalPlayer
    ts:TeleportToPlaceInstance(game.PlaceId,game.JobId,p)
end
function F.serverHop()
    local hs=Sv.HttpService
    local ts=game:GetService("TeleportService")
    local p=Sv.Players.LocalPlayer
    local url="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
    task.spawn(function()
        pcall(function()
            local res=game:HttpGet(url)
            local data=hs:JSONDecode(res)
            if data and data.data then
                local servers={}
                for _,v in ipairs(data.data) do
                    if type(v)=="table" and v.id~=game.JobId and v.playing<v.maxPlayers then
                        table.insert(servers,v.id)
                    end
                end
                if #servers>0 then
                    ts:TeleportToPlaceInstance(game.PlaceId,servers[math.random(1,#servers)],p)
                end
            end
        end)
    end)
end
function F.stopAllActionsInternal()
    St.Fl.autoFarmRunning=false
    St.farmLoopId=St.farmLoopId+1
    if St.Cn.autoEscape then pcall(function() St.Cn.autoEscape:Disconnect() end); St.Cn.autoEscape=nil end
    St.Fl.autoEscapeRunning=false
    if St.Cn.killerSafety then St.Cn.killerSafety:Disconnect(); St.Cn.killerSafety=nil end
    St.Fl.killerSafetyActive=false
    if St.Cn.autoRevive then pcall(function() St.Cn.autoRevive:Disconnect() end); St.Cn.autoRevive=nil end
    St.Fl.autoReviveRunning=false; F.stopReviveFollow()
    St.reviveLoopId=St.reviveLoopId+1
    if St.Cn.autoSelfRevive then pcall(function() St.Cn.autoSelfRevive:Disconnect() end); St.Cn.autoSelfRevive=nil end
    St.selfReviveLoopId=St.selfReviveLoopId+1
    St.Fl.killAllRunning=false
    if St.Fl.ghostActive then F.toggleGhostMode(false) end
    if St.Cn.hitbox then St.Cn.hitbox:Disconnect(); St.Cn.hitbox=nil end
end
function F.restartEnabledCommands()
    local now=tick()
    if now-St._restartCooldown<1.5 then return end
    St._restartCooldown=now
    F.stopAllActionsInternal()
    St.cachedMap=nil; St._lockerCache.time=0
    St.Fl.farmPriority=0; St.Fl.farmPaused=false; St.Fl.farmStoppedForRound=false
    St.Fl.reviveSelfPaused=false; St.Fl.escapeTriggeredExternal=false; St.Fl.escapeCheckTimer=0
    F.clearTable(St.reviveTracking)
    local tt=F.getMyTeamType()
    if tt=="survivor" then
        if St.Settings.AutoFarmLoot then F.startAutoFarm() end
        if St.Settings.AutoEscape then F.startAutoEscape() end
        if St.Settings.KillerSafety then F.startKillerSafety() end
        if St.Settings.AutoRevive then F.startAutoRevive() end
        if St.Settings.AutoSelfRevive then F.startAutoSelfRevive() end
    elseif tt=="killer" then
        if St.Settings._killAll then F.startKillAll() end
        if St.Settings.Hitbox then F.startHitbox() end
    end
    if St.Settings.InfiniteJump then F.startInfiniteJump() end
    if St.Settings.AntiAFK then F.startAntiAFK() end
    if St.Settings.LootESP then F.updateLootESP() end
    if St.Settings.ExitESP then F.updateExitESP() end
    if St.Settings.SnowAnimation then F.applySnowAnims(Sv.LocalPlayer.Character) end
    if St.Settings.GhostMode and tt~="lobby" then F.toggleGhostMode(true) end
end
UI.C={
    BG=Color3_fromRGB(10,11,14),
    PANEL=Color3_fromRGB(16,18,23),
    ROW=Color3_fromRGB(23,26,33),
    ACCENT=Color3_fromRGB(85,130,255),
    ACCDIM=Color3_fromRGB(55,90,190),
    TEXT=Color3_fromRGB(250,250,255),
    SUBTEXT=Color3_fromRGB(140,150,170),
    DIV=Color3_fromRGB(34,38,48),
    OFF=Color3_fromRGB(30,33,42),
    RED=Color3_fromRGB(245,70,70),
    REDDIM=Color3_fromRGB(180,45,45),
    GLASS=Color3_fromRGB(255,255,255),
    GOOD=Color3_fromRGB(45,215,120),
    WARN=Color3_fromRGB(250,175,50),
    DANGER=Color3_fromRGB(245,70,70)
}
function F.applyTheme(hue)
    hue=math.clamp(hue or 0,0,1)
    St.Settings.ThemeHue=hue
    UI.C.ACCENT=Color3.fromHSV(hue,0.65,1)
    UI.C.ACCDIM=Color3.fromHSV(hue,0.75,0.75)
    local ti=TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
    for _,data in ipairs(St.UIRefs.Themed) do
        if data.inst and data.inst.Parent then
            local targetColor=UI.C[data.type]
            if targetColor then
                Sv.TweenService:Create(data.inst,ti,{[data.prop]=targetColor}):Play()
            end
        end
    end
    if St.UIRefs._updateLangBtns then St.UIRefs._updateLangBtns() end
    for sName,setVisual in pairs(St.toggleRefs) do
        if setVisual then setVisual(St.Settings[sName] or false) end
    end
    if St.UIRefs._updateTabs then St.UIRefs._updateTabs() end
    task.defer(F.saveSettings)
end
function UI.registerTheme(inst,typeKey,propKey)
    table.insert(St.UIRefs.Themed,{inst=inst,type=typeKey,prop=propKey})
    local targetColor=UI.C[typeKey]
    if targetColor then inst[propKey]=targetColor end
end
UI.lo_ctr={}
function UI.nextLO(page)
    UI.lo_ctr[page]=(UI.lo_ctr[page] or 0)+1
    return UI.lo_ctr[page]
end
function UI.A(page,fr) fr.LayoutOrder=UI.nextLO(page); return fr end
function UI.applyHover(item,nColorKey,hColorKey)
    item.MouseEnter:Connect(function()
        Sv.TweenService:Create(item,TweenInfo.new(0.15),{BackgroundColor3=UI.C[hColorKey]}):Play()
    end)
    item.MouseLeave:Connect(function()
        Sv.TweenService:Create(item,TweenInfo.new(0.15),{BackgroundColor3=UI.C[nColorKey]}):Play()
    end)
end
local _toastQueue={}
local _toastActive=false
local function _nextToast(sg)
    if _toastActive or #_toastQueue==0 then return end
    _toastActive=true
    local msg=table.remove(_toastQueue,1)
    local TW,TH=224,36
    local toast=Instance_new("Frame"); toast.Parent=sg
    toast.Size=UDim2_new(0,TW,0,TH); toast.Position=UDim2_new(1,12,1,-TH-14)
    toast.BackgroundColor3=Color3_fromRGB(10,12,20); toast.BackgroundTransparency=0.08
    toast.BorderSizePixel=0; toast.ZIndex=199; toast.ClipsDescendants=true
    local tCrn=Instance_new("UICorner"); tCrn.Parent=toast; tCrn.CornerRadius=UDim_new(0,10)
    local tStr=Instance_new("UIStroke"); tStr.Parent=toast
    tStr.Color=UI.C.ACCENT; tStr.Thickness=0.8; tStr.Transparency=0.45
    UI.registerTheme(tStr,"ACCENT","Color")
    local bar=Instance_new("Frame"); bar.Parent=toast
    bar.Size=UDim2_new(0,3,1,-10); bar.Position=UDim2_new(0,4,0,5)
    bar.BackgroundColor3=UI.C.ACCENT; bar.BorderSizePixel=0
    UI.registerTheme(bar,"ACCENT","BackgroundColor3")
    local bCrn=Instance_new("UICorner"); bCrn.CornerRadius=UDim_new(1,0); bCrn.Parent=bar
    local lbl=Instance_new("TextLabel"); lbl.Parent=toast
    lbl.Size=UDim2_new(1,-16,0,TH-12); lbl.Position=UDim2_new(0,14,0,5)
    lbl.BackgroundTransparency=1; lbl.Text=msg
    lbl.TextColor3=Color3_new(1,1,1)
    UI.registerTheme(lbl,"TEXT","TextColor3")
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=10; lbl.ZIndex=200
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.TextTransparency=1
    local progBg=Instance_new("Frame"); progBg.Parent=toast
    progBg.Size=UDim2_new(1,-8,0,2); progBg.Position=UDim2_new(0,4,1,-4)
    progBg.BackgroundColor3=Color3_fromRGB(25,28,45); progBg.BorderSizePixel=0; progBg.ZIndex=200
    local pgCrn=Instance_new("UICorner"); pgCrn.CornerRadius=UDim_new(1,0); pgCrn.Parent=progBg
    local prog=Instance_new("Frame"); prog.Parent=progBg
    prog.Size=UDim2_new(1,0,1,0); prog.BackgroundColor3=UI.C.ACCENT; prog.BorderSizePixel=0
    UI.registerTheme(prog,"ACCENT","BackgroundColor3")
    local prCrn=Instance_new("UICorner"); prCrn.CornerRadius=UDim_new(1,0); prCrn.Parent=prog
    local ts=Sv.TweenService; local DISPLAY=2.2
    ts:Create(toast,TweenInfo.new(0.32,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2_new(1,-TW-10,1,-TH-14)}):Play()
    ts:Create(lbl,TweenInfo.new(0.22),{TextTransparency=0}):Play()
    ts:Create(prog,TweenInfo.new(DISPLAY,Enum.EasingStyle.Linear),{Size=UDim2_new(0,0,1,0)}):Play()
    task.delay(DISPLAY,function()
        ts:Create(toast,TweenInfo.new(0.24,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2_new(1,12,1,-TH-14)}):Play()
        ts:Create(lbl,TweenInfo.new(0.18),{TextTransparency=1}):Play()
        task.delay(0.27,function()
            F.safeDestroy(toast)
            _toastActive=false
            if sg and sg.Parent then _nextToast(sg) end
        end)
    end)
end
function UI.showToast(msg,sg)
    _toastQueue[#_toastQueue+1]=msg
    _nextToast(sg)
end
function UI.makeSubContainer(parent)
    local fr=Instance_new("Frame"); fr.Parent=parent
    fr.Size=UDim2_new(1,0,0,0); fr.BackgroundTransparency=1
    fr.BorderSizePixel=0; fr.Visible=false; fr.ClipsDescendants=false
    local ll=Instance_new("UIListLayout"); ll.Parent=fr
    ll.Padding=UDim_new(0,4); ll.SortOrder=Enum.SortOrder.LayoutOrder
    ll.HorizontalAlignment=Enum.HorizontalAlignment.Center
    ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        fr.Size=UDim2_new(1,0,0,fr.Visible and ll.AbsoluteContentSize.Y or 0)
    end)
    return fr,ll
end
function UI.makeGridContainer(parent)
    local fr=Instance_new("Frame"); fr.Parent=parent
    fr.Size=UDim2_new(1,0,0,0); fr.BackgroundTransparency=1; fr.BorderSizePixel=0
    local gl=Instance_new("UIGridLayout"); gl.Parent=fr
    gl.CellSize=UDim2_new(0.5,-4,0,34); gl.CellPadding=UDim2_new(0,8,0,6)
    gl.SortOrder=Enum.SortOrder.LayoutOrder
    gl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        fr.Size=UDim2_new(1,0,0,gl.AbsoluteContentSize.Y)
    end)
    return fr
end
function UI.makeToggle(parent,sName,labelTxt,onCb,langKey)
    local row=Instance_new("Frame"); row.Parent=parent
    row.Size=UDim2_new(1,0,0,34); row.BackgroundColor3=UI.C.ROW
    UI.registerTheme(row,"ROW","BackgroundColor3")
    row.BackgroundTransparency=0.2; row.BorderSizePixel=0
    local rCrn=Instance_new("UICorner"); rCrn.Parent=row; rCrn.CornerRadius=UDim_new(0,8)
    local rStr=Instance_new("UIStroke"); rStr.Parent=row; rStr.Thickness=0.8
    local rGrad=Instance_new("UIGradient"); rGrad.Parent=rStr
    rGrad.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3_fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.4,Color3_fromRGB(180,200,255)),
        ColorSequenceKeypoint.new(1,Color3_fromRGB(255,255,255))
    })
    rGrad.Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.85),
        NumberSequenceKeypoint.new(0.5,0.3),
        NumberSequenceKeypoint.new(1,0.85)
    })
    rGrad.Rotation=90
    local lbl=Instance_new("TextLabel"); lbl.Parent=row
    lbl.Size=UDim2_new(1,-50,1,0); lbl.Position=UDim2_new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=labelTxt; lbl.TextColor3=Color3_new(1,1,1)
    UI.registerTheme(lbl,"TEXT","TextColor3")
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=10
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    if langKey then _LR(lbl,langKey) end
    local state=St.Settings[sName] or false
    local tBtn=Instance_new("TextButton"); tBtn.Parent=row
    tBtn.Size=UDim2_new(0,38,0,20); tBtn.Position=UDim2_new(1,-44,0.5,-10)
    tBtn.BackgroundColor3=state and UI.C.ACCENT or UI.C.OFF
    tBtn.Text=""; tBtn.BorderSizePixel=0
    local tbCrn=Instance_new("UICorner"); tbCrn.Parent=tBtn; tbCrn.CornerRadius=UDim_new(1,0)
    local tbStr=Instance_new("UIStroke"); tbStr.Parent=tBtn
    tbStr.Color=Color3_fromRGB(255,255,255); tbStr.Thickness=0.6; tbStr.Transparency=0.7
    local knob=Instance_new("Frame"); knob.Parent=tBtn
    knob.Size=UDim2_new(0,16,0,16)
    knob.Position=state and UDim2_new(1,-18,0.5,-8) or UDim2_new(0,2,0.5,-8)
    knob.BackgroundColor3=Color3_new(1,1,1); knob.BorderSizePixel=0
    local kCrn=Instance_new("UICorner"); kCrn.Parent=knob; kCrn.CornerRadius=UDim_new(1,0)
    local kSh=Instance_new("UIStroke"); kSh.Parent=knob
    kSh.Color=Color3_fromRGB(180,180,180); kSh.Thickness=0.5; kSh.Transparency=0.5
    local ti13=TweenInfo.new(0.13,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
    local function setVisual(on)
        Sv.TweenService:Create(knob,ti13,{Position=on and UDim2_new(1,-18,0.5,-8) or UDim2_new(0,2,0.5,-8)}):Play()
        Sv.TweenService:Create(tBtn,ti13,{BackgroundColor3=on and UI.C.ACCENT or UI.C.OFF}):Play()
    end
    tBtn.MouseButton1Click:Connect(function()
        St.Settings[sName]=not St.Settings[sName]; local on=St.Settings[sName]
        setVisual(on); if onCb then onCb(on) end; task.defer(F.saveSettings)
    end)
    St.toggleRefs[sName]=setVisual
    St.toggleCbs[sName]=onCb
    row.MouseEnter:Connect(function()
        Sv.TweenService:Create(row,TweenInfo.new(0.12),{BackgroundTransparency=0.35}):Play()
    end)
    row.MouseLeave:Connect(function()
        Sv.TweenService:Create(row,TweenInfo.new(0.12),{BackgroundTransparency=0.5}):Play()
    end)
    return row
end
function UI.makeSectionLabel(parent,txt,accent)
    local container=Instance_new("Frame"); container.Parent=parent
    container.Size=UDim2_new(1,0,0,24); container.BackgroundTransparency=1; container.BorderSizePixel=0
    local bar=Instance_new("Frame"); bar.Parent=container
    bar.Size=UDim2_new(0,3,0.7,0); bar.Position=UDim2_new(0,6,0.15,0)
    bar.BackgroundColor3=accent and UI.C.DANGER or UI.C.ACCENT
    UI.registerTheme(bar,accent and "DANGER" or "ACCENT","BackgroundColor3")
    local bCrn=Instance_new("UICorner"); bCrn.Parent=bar; bCrn.CornerRadius=UDim_new(1,0)
    local lbl=Instance_new("TextLabel"); lbl.Parent=container
    lbl.Size=UDim2_new(1,-18,1,0); lbl.Position=UDim2_new(0,14,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=txt
    lbl.TextColor3=accent and Color3_fromRGB(255,120,120) or UI.C.TEXT
    UI.registerTheme(lbl,accent and "DANGER" or "TEXT","TextColor3")
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    return container
end
function UI.makeDivider(parent)
    local d=Instance_new("Frame"); d.Parent=parent
    d.Size=UDim2_new(1,-12,0,1); d.BackgroundColor3=UI.C.DIV
    UI.registerTheme(d,"DIV","BackgroundColor3")
    d.BackgroundTransparency=0.3; d.BorderSizePixel=0
    local dGr=Instance_new("UIGradient"); dGr.Parent=d
    dGr.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3_fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.3,Color3_fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.7,Color3_fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1,Color3_fromRGB(0,0,0))
    }); dGr.Transparency=NumberSequence.new(0.3)
    return d
end
function UI.makeActionRow(parent,labelTxt,btnTxt,btnColorKey,onClick)
    local row=Instance_new("Frame"); row.Parent=parent
    row.Size=UDim2_new(1,0,0,34); row.BackgroundColor3=UI.C.ROW
    UI.registerTheme(row,"ROW","BackgroundColor3")
    row.BackgroundTransparency=0.2; row.BorderSizePixel=0
    local rCrn=Instance_new("UICorner"); rCrn.Parent=row; rCrn.CornerRadius=UDim_new(0,8)
    local rStr=Instance_new("UIStroke"); rStr.Parent=row; rStr.Thickness=0.8
    local rGrad=Instance_new("UIGradient"); rGrad.Parent=rStr
    rGrad.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3_fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.4,Color3_fromRGB(180,200,255)),
        ColorSequenceKeypoint.new(1,Color3_fromRGB(255,255,255))
    })
    rGrad.Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.85),
        NumberSequenceKeypoint.new(0.5,0.3),
        NumberSequenceKeypoint.new(1,0.85)
    })
    rGrad.Rotation=90
    local lbl=Instance_new("TextLabel"); lbl.Parent=row
    lbl.Size=UDim2_new(1,-70,1,0); lbl.Position=UDim2_new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=labelTxt; lbl.TextColor3=Color3_new(1,1,1)
    UI.registerTheme(lbl,"TEXT","TextColor3")
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=10
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local ab=Instance_new("TextButton"); ab.Parent=row
    ab.Size=UDim2_new(0,52,0,24); ab.Position=UDim2_new(1,-58,0.5,-12)
    ab.BackgroundColor3=UI.C[btnColorKey] or UI.C.ACCENT; ab.Text=btnTxt
    if btnColorKey=="ACCENT" then UI.registerTheme(ab,"ACCENT","BackgroundColor3") end
    ab.TextColor3=Color3_new(1,1,1); ab.Font=Enum.Font.GothamBold
    ab.TextSize=9; ab.BorderSizePixel=0
    local abCrn=Instance_new("UICorner"); abCrn.Parent=ab; abCrn.CornerRadius=UDim_new(0,6)
    local abStr=Instance_new("UIStroke"); abStr.Parent=ab
    abStr.Color=Color3_fromRGB(255,255,255); abStr.Thickness=0.6; abStr.Transparency=0.7
    ab.MouseButton1Click:Connect(onClick)
    UI.applyHover(ab,btnColorKey or "ACCENT","ACCDIM")
    row.MouseEnter:Connect(function()
        Sv.TweenService:Create(row,TweenInfo.new(0.12),{BackgroundTransparency=0.35}):Play()
    end)
    row.MouseLeave:Connect(function()
        Sv.TweenService:Create(row,TweenInfo.new(0.12),{BackgroundTransparency=0.5}):Play()
    end)
    return row
end
function UI.makeWideBtn(parent,labelTxt,onClick)
    local row=Instance_new("Frame"); row.Parent=parent
    row.Size=UDim2_new(1,0,0,32); row.BackgroundColor3=UI.C.OFF
    UI.registerTheme(row,"OFF","BackgroundColor3")
    row.BackgroundTransparency=0.2; row.BorderSizePixel=0
    local rCrn=Instance_new("UICorner"); rCrn.Parent=row; rCrn.CornerRadius=UDim_new(0,8)
    local rStr=Instance_new("UIStroke"); rStr.Parent=row; rStr.Thickness=0.8
    local rGrad=Instance_new("UIGradient"); rGrad.Parent=rStr
    rGrad.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3_fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.4,Color3_fromRGB(180,200,255)),
        ColorSequenceKeypoint.new(1,Color3_fromRGB(255,255,255))
    })
    rGrad.Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.85),
        NumberSequenceKeypoint.new(0.5,0.3),
        NumberSequenceKeypoint.new(1,0.85)
    })
    rGrad.Rotation=90
    local btn=Instance_new("TextButton"); btn.Parent=row
    btn.Size=UDim2_new(1,0,1,0); btn.BackgroundTransparency=1
    btn.Text=labelTxt; btn.TextColor3=Color3_new(1,1,1)
    UI.registerTheme(btn,"TEXT","TextColor3")
    btn.Font=Enum.Font.GothamBold; btn.TextSize=10; btn.BorderSizePixel=0
    btn.MouseButton1Click:Connect(onClick)
    row.MouseEnter:Connect(function()
        Sv.TweenService:Create(row,TweenInfo.new(0.12),{BackgroundTransparency=0.3}):Play()
    end)
    row.MouseLeave:Connect(function()
        Sv.TweenService:Create(row,TweenInfo.new(0.12),{BackgroundTransparency=0.5}):Play()
    end)
    return row
end
function UI.makeSliderRow(parent,labelTxt,minV,maxV,initV,onChange,fixedColor,langKey)
    local row=Instance_new("Frame"); row.Parent=parent
    row.Size=UDim2_new(1,0,0,52); row.BackgroundColor3=UI.C.ROW; row.BorderSizePixel=0
    UI.registerTheme(row,"ROW","BackgroundColor3")
    row.BackgroundTransparency=0.2
    local rCrn=Instance_new("UICorner"); rCrn.Parent=row; rCrn.CornerRadius=UDim_new(0,8)
    local rStr=Instance_new("UIStroke"); rStr.Parent=row
    rStr.Color=Color3_fromRGB(255,255,255); rStr.Thickness=0.5; rStr.Transparency=0.82
    local topLbl=Instance_new("TextLabel"); topLbl.Parent=row
    topLbl.Size=UDim2_new(1,-20,0,22); topLbl.Position=UDim2_new(0,10,0,2)
    topLbl.BackgroundTransparency=1; topLbl.Text=labelTxt.."  "..initV
    topLbl.TextColor3=Color3_new(1,1,1); topLbl.Font=Enum.Font.GothamSemibold
    UI.registerTheme(topLbl,"TEXT","TextColor3")
    topLbl.TextSize=10; topLbl.TextXAlignment=Enum.TextXAlignment.Left
    if langKey then _LR(topLbl,langKey) end
    local minusBtn=Instance_new("TextButton"); minusBtn.Parent=row
    minusBtn.Size=UDim2_new(0,24,0,22); minusBtn.Position=UDim2_new(0,6,0,27)
    minusBtn.BackgroundColor3=UI.C.OFF; minusBtn.Text="-"
    UI.registerTheme(minusBtn,"OFF","BackgroundColor3")
    minusBtn.TextColor3=Color3_new(1,1,1); minusBtn.Font=Enum.Font.GothamBold
    minusBtn.TextSize=14; minusBtn.BorderSizePixel=0
    local mbCrn=Instance_new("UICorner"); mbCrn.Parent=minusBtn; mbCrn.CornerRadius=UDim_new(0,6)
    local track=Instance_new("Frame"); track.Parent=row
    track.Size=UDim2_new(1,-68,0,8); track.Position=UDim2_new(0,34,0,33)
    track.BackgroundColor3=UI.C.OFF; track.BorderSizePixel=0
    UI.registerTheme(track,"OFF","BackgroundColor3")
    local tCrn=Instance_new("UICorner"); tCrn.Parent=track; tCrn.CornerRadius=UDim_new(1,0)
    local plusBtn=Instance_new("TextButton"); plusBtn.Parent=row
    plusBtn.Size=UDim2_new(0,24,0,22); plusBtn.Position=UDim2_new(1,-30,0,27)
    plusBtn.BackgroundColor3=UI.C.OFF; plusBtn.Text="+"
    UI.registerTheme(plusBtn,"OFF","BackgroundColor3")
    plusBtn.TextColor3=Color3_new(1,1,1); plusBtn.Font=Enum.Font.GothamBold
    plusBtn.TextSize=14; plusBtn.BorderSizePixel=0
    local pbCrn=Instance_new("UICorner"); pbCrn.Parent=plusBtn; pbCrn.CornerRadius=UDim_new(0,6)
    local iF=math.clamp((initV-minV)/math_max(maxV-minV,1),0,1)
    local function _sliderColor(f)
        if fixedColor then return fixedColor end
        if f<=0.33 then return UI.C.GOOD
        elseif f<=0.66 then return UI.C.WARN
        else return UI.C.DANGER end
    end
    local fill=Instance_new("Frame"); fill.Parent=track
    fill.Size=UDim2_new(iF,0,1,0); fill.BackgroundColor3=_sliderColor(iF); fill.BorderSizePixel=0
    if fixedColor then UI.registerTheme(fill,"ACCENT","BackgroundColor3") end
    local fCrn=Instance_new("UICorner"); fCrn.Parent=fill; fCrn.CornerRadius=UDim_new(1,0)
    local kn=Instance_new("Frame"); kn.Parent=track
    kn.Size=UDim2_new(0,14,0,14); kn.Position=UDim2_new(iF,-7,0.5,-7)
    kn.BackgroundColor3=Color3_new(1,1,1); kn.BorderSizePixel=0
    local kCrn=Instance_new("UICorner"); kCrn.Parent=kn; kCrn.CornerRadius=UDim_new(1,0)
    local currentVal=initV
    local dragId=tostring({})
    local ti8=TweenInfo.new(0.08)
    local function applyF(f)
        f=math.clamp(f,0,1)
        local val=math_floor(minV+f*(maxV-minV))
        currentVal=val; fill.Size=UDim2_new(f,0,1,0); kn.Position=UDim2_new(f,-7,0.5,-7)
        if not fixedColor then Sv.TweenService:Create(fill,ti8,{BackgroundColor3=_sliderColor(f)}):Play() end
        topLbl.Text=labelTxt.."  "..val; if onChange then onChange(val) end
        task.defer(F.saveSettings)
    end
    local function stepVal(delta) applyF((currentVal+delta-minV)/math_max(maxV-minV,1)) end
    St._sliderDrags[dragId]={apply=applyF,track=track}
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            St._sliderDragId=dragId
            applyF((inp.Position.X-track.AbsolutePosition.X)/math_max(track.AbsoluteSize.X,1))
        end
    end)
    minusBtn.MouseButton1Click:Connect(function() stepVal(-1) end)
    plusBtn.MouseButton1Click:Connect(function() stepVal(1) end)
    row.AncestryChanged:Connect(function() if not row.Parent then St._sliderDrags[dragId]=nil end end)
    UI.applyHover(minusBtn,"OFF","DIV")
    UI.applyHover(plusBtn,"OFF","DIV")
    return row
end
function UI.makeFontPicker(parent,currentFont,onPick)
    local row=Instance_new("Frame"); row.Parent=parent
    row.Size=UDim2_new(1,0,0,28); row.BackgroundColor3=UI.C.ROW; row.BorderSizePixel=0
    UI.registerTheme(row,"ROW","BackgroundColor3")
    row.BackgroundTransparency=0.2
    local rCrn=Instance_new("UICorner"); rCrn.Parent=row; rCrn.CornerRadius=UDim_new(0,6)
    local lbl=Instance_new("TextLabel"); lbl.Parent=row
    lbl.Size=UDim2_new(0,36,1,0); lbl.Position=UDim2_new(0,6,0,0)
    lbl.BackgroundTransparency=1; lbl.Text="Font"; lbl.TextColor3=Color3_new(1,1,1)
    UI.registerTheme(lbl,"TEXT","TextColor3")
    lbl.Font=Enum.Font.GothamSemibold; lbl.TextSize=9
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    local fontBtns={}; local bW=30; local bG=2; local sX=42
    for i,fd in ipairs({{"Normal",Enum.Font.Gotham},{"Bold",Enum.Font.GothamBold},{"Semi",Enum.Font.GothamSemibold},{"Code",Enum.Font.Code},{"Arcade",Enum.Font.Arcade}}) do
        local fb=Instance_new("TextButton"); fb.Parent=row
        fb.Size=UDim2_new(0,bW,0,20); fb.Position=UDim2_new(0,sX+(i-1)*(bW+bG),0.5,-10)
        fb.BackgroundColor3=(fd[2]==currentFont) and UI.C.ACCENT or UI.C.OFF
        fb.Text=fd[1]; fb.TextColor3=Color3_new(1,1,1)
        fb.Font=Enum.Font.GothamBold; fb.TextSize=7; fb.BorderSizePixel=0
        local fbCrn=Instance_new("UICorner"); fbCrn.Parent=fb; fbCrn.CornerRadius=UDim_new(0,4)
        fontBtns[i]=fb
        local ci,cfd=i,fd
        fb.MouseButton1Click:Connect(function()
            for j,b in ipairs(fontBtns) do b.BackgroundColor3=j==ci and UI.C.ACCENT or UI.C.OFF end
            onPick(cfd[2])
        end)
    end
    return row
end
local _LANG={
    EN={
        home_tab="Home", esp_tab="ESP", farm_tab="Farm", sett_tab="Settings",
        player_info="PLAYER INFO",
        credits="JohnyX Script",
        credits_sub="by @G_p0z  •  v6.0",
        motto="We are not the only ones, but we are the best",
        fps_lbl="FPS", ping_lbl="Ping",
        status_ok="Status: Undetected",
        status_detected="Status: Detected",
        server_tools="SERVER TOOLS",
        rejoin_lbl="Rejoin Server", rejoin_btn="GO",
        hop_lbl="Server Hop", hop_btn="HOP",
        advanced="ADVANCED",
        lang_toggle="Language",
        sec_movement="MOVEMENT", sec_speed="SPEED",
        sec_utility="UTILITY", sec_visuals="VISUALS",
        sec_links="LINKS", sec_uisize="UI SIZE", sec_winsize="WIN SIZE", sec_transparency="TRANSPARENCY",
        sec_player="PLAYER", sec_lives="LIVES TRACKER",
        sec_world="WORLD", sec_hud="HUD",
        sec_autofarm="AUTO FARM", sec_revive="REVIVE",
        sec_safety="SAFETY", sec_killer="KILLER",
        close_script="CLOSE SCRIPT", preset_lbl="Preset",
        uptime="Uptime", ping_card="Ping",
        farm_success="Collected", farm_fail="Errors",
        farm_escapes="Escapes", farm_coins="Coins",
        toast_started="Script Loaded  v6.0",
        toast_farm_on="Auto Farm: ON",
        toast_farm_off="Auto Farm: OFF",
        toast_rejoin="Rejoining...",
        toast_hop="Finding Server...",
        tog_player_esp="Player ESP", tog_show_names="Show Names", tog_show_dist="Show Dist",
        tog_lives_esp="Lives ESP", tog_exit_esp="Exit ESP", tog_loot_esp="Loot ESP",
        tog_coins_disp="Coins Display",
        tog_farm_loot="Farm Loot", tog_auto_revive="Auto Revive", tog_self_revive="Self Revive",
        tog_killer_safe="Killer Safety", tog_auto_escape="Auto Escape", tog_kill_all="Kill All",
        tog_double_jump="Double Jump", tog_inf_jump="Infinite Jump", tog_noclip="Noclip",
        tog_fly="Fly", tog_speed_boost="Speed Boost", tog_anti_afk="Anti AFK",
        tog_remove_fog="Remove Fog", tog_snow_anim="Snow Animation", tog_anti_void="Anti-Void",
        tog_ghost_mode="Ghost Mode", tog_hitbox="Hitbox", tog_fps_boost="FPS Boost",
        sec_fpsboost="FPS BOOST", tog_ads="Show Ads",
        sl_name_offset="Name Offset", sl_dist_offset="Dist Offset", sl_heart_size="Heart Size",
        sl_hitbox_dist="Hitbox Distance",
        sl_height="Height", sl_tilt="Tilt", sl_min_value="Min Value",
        sl_fly_speed="Fly Speed", sl_speed="Speed", sl_safety_dist="Safety Dist",
        sl_farm_speed="Farm Speed",
        theme_lbl="UI Theme",
        confirm_close="Are you sure you want to close?",
        btn_yes="Yes", btn_no="No",
        ghost_farm_warn="Disable Farm features to use Ghost Mode!"
    },
    RU={
        home_tab="Главная", esp_tab="ЕСП", farm_tab="Фарм", sett_tab="Настройки",
        player_info="ИГРОК",
        credits="JohnyX Script",
        credits_sub="от @G_p0z  •  v6.0",
        motto="Мы не единственные, но мы лучшие",
        fps_lbl="FPS", ping_lbl="Пинг",
        status_ok="Статус: Не обнаружен",
        status_detected="Статус: Обнаружен",
        server_tools="СЕРВЕР",
        rejoin_lbl="Переподключение", rejoin_btn="GO",
        hop_lbl="Сменить сервер", hop_btn="HOP",
        advanced="ДОПОЛНИТЕЛЬНО",
        lang_toggle="Язык",
        sec_movement="ДВИЖЕНИЕ", sec_speed="СКОРОСТЬ",
        sec_utility="ФУНКЦИИ", sec_visuals="ВИЗУАЛ",
        sec_links="ССЫЛКИ", sec_uisize="РАЗМЕР UI", sec_winsize="РАЗМЕР ОКНА", sec_transparency="ПРОЗРАЧНОСТЬ",
        sec_player="ИГРОКИ", sec_lives="ЖИЗНИ",
        sec_world="МИР", sec_hud="HUD",
        sec_autofarm="АВТОФАРМ", sec_revive="ВОСКРЕШЕНИЕ",
        sec_safety="ЗАЩИТА", sec_killer="УБИЙЦА",
        close_script="ЗАКРЫТЬ СКРИПТ", preset_lbl="Пресет",
        uptime="Время работы", ping_card="Пинг",
        farm_success="Собрано", farm_fail="Ошибки",
        farm_escapes="Побеги", farm_coins="Монеты",
        toast_started="Скрипт загружен  v6.0",
        toast_farm_on="Автофарм: ВКЛ",
        toast_farm_off="Автофарм: ВЫКЛ",
        toast_rejoin="Переподключение...",
        toast_hop="Поиск сервера...",
        tog_player_esp="ESP игрока", tog_show_names="Имена", tog_show_dist="Расстояние",
        tog_lives_esp="ESP жизней", tog_exit_esp="ESP выходов", tog_loot_esp="ESP лута",
        tog_coins_disp="Монеты HUD",
        tog_farm_loot="Фарм лута", tog_auto_revive="Автоподъём", tog_self_revive="Самоподъём",
        tog_killer_safe="Защита от убийцы", tog_auto_escape="Автопобег", tog_kill_all="Убить всех",
        tog_double_jump="Двойной прыжок", tog_inf_jump="Беск. прыжок", tog_noclip="Нет коллизий",
        tog_fly="Полёт", tog_speed_boost="Ускорение", tog_anti_afk="Анти-АФК",
        tog_remove_fog="Убрать туман", tog_snow_anim="Снежная анимация", tog_anti_void="Анти-Пустота",
        tog_ghost_mode="Режим призрака", tog_hitbox="Хитбокс", tog_fps_boost="FPS Boost",
        sec_fpsboost="FPS BOOST", tog_ads="Показ рекл.",
        sl_name_offset="Смещ. имени", sl_dist_offset="Смещ. дист.", sl_heart_size="Размер сердца",
        sl_hitbox_dist="Дистанция хитбокса",
        sl_height="Высота", sl_tilt="Наклон", sl_min_value="Мин. ценность",
        sl_fly_speed="Скор. полёта", sl_speed="Скорость", sl_safety_dist="Дист. защиты",
        sl_farm_speed="Скор. фарма",
        theme_lbl="Тема UI",
        confirm_close="Вы уверены, что хотите закрыть?",
        btn_yes="Да", btn_no="Нет",
        ghost_farm_warn="Отключите функции Farm для Ghost Mode!"
    }
}
_T=function(k) return (_LANG[St.Language] or _LANG.EN)[k] or k end
_applyLang=function()
    for _,ref in ipairs(_langRefs) do
        if ref.lbl and ref.lbl.Parent then
            ref.lbl.Text=_T(ref.key)
            if ref.origFont then ref.lbl.Font=ref.origFont end
        end
    end
end
_LR=function(lbl,key)
    lbl.Text=_T(key)
    _langRefs[#_langRefs+1]={lbl=lbl,key=key,origFont=lbl.Font}
end
local function _LS(pg,key,accent)
    local c=UI.makeSectionLabel(pg,_T(key),accent)
    _LR(c:FindFirstChildOfClass("TextLabel"),key)
    UI.A(pg,c)
end
local function buildUI()
    local frameW,frameH=380,310
    local ScreenGui=Instance_new("ScreenGui")
    ScreenGui.Name="JxH_UI"; ScreenGui.ResetOnSpawn=false; ScreenGui.DisplayOrder=10
    pcall(function() ScreenGui.Parent=Sv.CoreGui end)
    if not ScreenGui.Parent then pcall(function() ScreenGui.Parent=Sv.LocalPlayer:WaitForChild("PlayerGui") end) end
    local CoinsHUD=Instance_new("Frame"); CoinsHUD.Parent=ScreenGui; CoinsHUD.Name="CoinsHUD"
    CoinsHUD.Size=UDim2_new(0,120,0,28); CoinsHUD.Position=UDim2_new(0.5,-60,0,36)
    CoinsHUD.BackgroundTransparency=1; CoinsHUD.BorderSizePixel=0
    CoinsHUD.ZIndex=12; CoinsHUD.Visible=false
    St.CoinsHUD_ref=CoinsHUD
    local CoinsIcon=Instance_new("ImageLabel"); CoinsIcon.Parent=CoinsHUD
    CoinsIcon.Size=UDim2_new(0,20,0,20); CoinsIcon.Position=UDim2_new(0,4,0.5,-10)
    CoinsIcon.BackgroundTransparency=1; CoinsIcon.ScaleType=Enum.ScaleType.Fit; CoinsIcon.ZIndex=13
    setPrivateImage(CoinsIcon,"CoINs.png")
    local CoinsLbl=Instance_new("TextLabel"); CoinsLbl.Parent=CoinsHUD
    CoinsLbl.Size=UDim2_new(1,-28,1,0); CoinsLbl.Position=UDim2_new(0,26,0,0)
    CoinsLbl.BackgroundTransparency=1; CoinsLbl.Text="---"
    CoinsLbl.TextColor3=Color3_fromRGB(255,230,80); CoinsLbl.Font=Enum.Font.GothamBold
    CoinsLbl.TextSize=12; CoinsLbl.TextXAlignment=Enum.TextXAlignment.Left
    CoinsLbl.TextStrokeTransparency=0.15; CoinsLbl.ZIndex=13
    local _cachedCoinObj=nil
    local _cachedCoinType=nil
    local function readCoinsValue()
        if _cachedCoinObj and _cachedCoinObj.Parent then
            if _cachedCoinType=="val" then return _cachedCoinObj.Value
            elseif _cachedCoinType=="txt" then
                local n=tonumber(tostring(_cachedCoinObj.Text):gsub(",",""):gsub("%s",""):match("^(%d+)$"))
                if n and n>=0 then return n end
            end
        end
        _cachedCoinObj=nil; _cachedCoinType=nil
        local ls=Sv.LocalPlayer:FindFirstChild("leaderstats")
        if ls then
            for _,name in ipairs({"Coins","coins","Gold","gold","Cash","cash","Money","money"}) do
                local cv=ls:FindFirstChild(name)
                if cv and (cv:IsA("IntValue") or cv:IsA("NumberValue")) then _cachedCoinObj=cv; _cachedCoinType="val"; return cv.Value end
            end
        end
        for _,v in ipairs(Sv.LocalPlayer:GetChildren()) do
            local ln=v.Name:lower()
            if (ln:find("coin") or ln:find("gold") or ln:find("cash")) and (v:IsA("IntValue") or v:IsA("NumberValue")) then
                _cachedCoinObj=v; _cachedCoinType="val"; return v.Value
            end
        end
        local pg=Sv.LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local top=pg:FindFirstChild("CurrencyTop",true)
            if top then
                local cf=top:FindFirstChild("Coins")
                if cf then
                    local av=cf:FindFirstChild("Amount",true)
                    if av and (av:IsA("IntValue") or av:IsA("NumberValue")) then _cachedCoinObj=av; _cachedCoinType="val"; return av.Value end
                    for _,ch in ipairs(cf:GetDescendants()) do
                        if (ch:IsA("TextLabel") or ch:IsA("TextButton")) and ch.Name~="BuyCoins" and ch.Name~="+" then
                            local n=tonumber(tostring(ch.Text):gsub(",",""):gsub("%s",""):match("^(%d+)$"))
                            if n and n>=0 then _cachedCoinObj=ch; _cachedCoinType="txt"; return n end
                        end
                    end
                end
            end
        end
        return nil
    end
    task.spawn(function()
        while ScreenGui and ScreenGui.Parent do
            local val=readCoinsValue()
            if CoinsLbl and CoinsLbl.Parent then
                if val~=nil then
                    local str=tostring(math_floor(val)); local result,len="",#str
                    for i=1,len do
                        result=result..str:sub(i,i)
                        if (len-i)%3==0 and i~=len then result=result.."," end
                    end
                    CoinsLbl.Text=result
                else CoinsLbl.Text="---" end
            end
            task.wait(0.5)
        end
    end)
    local MIN_H_SIZE,MAX_H_SIZE=0.6,1.8
    local BASE_HUD_W,BASE_HUD_H=100,26
    local function _makeHudUnit(name,labelText,labelColor,defaultY,sliderInitF,sliderSaveKey)
        local frame=Instance_new("Frame")
        frame.Name=name
        frame.Size=UDim2_new(0,math_floor(BASE_HUD_W*St.Fl.hudSize),0,math_floor(BASE_HUD_H*St.Fl.hudSize))
        frame.Position=UDim2_new(0,8,0,defaultY)
        frame.BackgroundTransparency=1
        frame.BorderSizePixel=0
        frame.ZIndex=20
        frame.Active=true
        frame.Visible=false
        frame.Parent=ScreenGui
        local lbl=Instance_new("TextLabel")
        lbl.Name="Label"
        lbl.Size=UDim2_new(1,-18,1,0)
        lbl.Position=UDim2_new(0,0,0,0)
        lbl.BackgroundTransparency=1
        lbl.Text=labelText
        lbl.TextColor3=labelColor
        lbl.Font=Enum.Font.GothamBold
        lbl.TextSize=math.clamp(math_floor(13*St.Fl.hudSize),8,20)
        lbl.TextStrokeTransparency=0.4
        lbl.TextXAlignment=Enum.TextXAlignment.Left
        lbl.ZIndex=21
        lbl.Parent=frame
        local locked=false
        local xBtn=Instance_new("TextButton")
        xBtn.Name="XBtn"
        xBtn.Size=UDim2_new(0,18,0,18)
        xBtn.Position=UDim2_new(1,-19,0,0)
        xBtn.BackgroundColor3=Color3_fromRGB(180,30,30)
        xBtn.BackgroundTransparency=0.05
        xBtn.Text="X"
        xBtn.TextColor3=Color3_fromRGB(255,255,255)
        xBtn.Font=Enum.Font.GothamBold
        xBtn.TextSize=11
        xBtn.BorderSizePixel=0
        xBtn.ZIndex=22
        xBtn.Visible=false
        xBtn.Parent=frame
        local _xCrn=Instance_new("UICorner"); _xCrn.CornerRadius=UDim_new(0,4); _xCrn.Parent=xBtn
        local lockBtn=Instance_new("TextButton")
        lockBtn.Name="LockBtn"
        lockBtn.Size=UDim2_new(0,34,0,18)
        lockBtn.Position=UDim2_new(1,-55,0,0)
        lockBtn.BackgroundColor3=Color3_fromRGB(30,40,65)
        lockBtn.BackgroundTransparency=0.05
        lockBtn.Text="Lock"
        lockBtn.TextColor3=Color3_fromRGB(180,200,255)
        lockBtn.Font=Enum.Font.GothamBold
        lockBtn.TextSize=9
        lockBtn.BorderSizePixel=0
        lockBtn.ZIndex=22
        lockBtn.Visible=false
        lockBtn.Parent=frame
        local _lkCrn=Instance_new("UICorner"); _lkCrn.CornerRadius=UDim_new(0,4); _lkCrn.Parent=lockBtn
        local sliderFrame=Instance_new("Frame")
        sliderFrame.Name="SliderFrame"
        sliderFrame.Size=UDim2_new(1,0,0,10)
        sliderFrame.Position=UDim2_new(0,0,1,2)
        sliderFrame.BackgroundTransparency=1
        sliderFrame.BorderSizePixel=0
        sliderFrame.ZIndex=22
        sliderFrame.Visible=false
        sliderFrame.Parent=frame
        local sTrack=Instance_new("Frame")
        sTrack.Size=UDim2_new(1,0,0,6)
        sTrack.Position=UDim2_new(0,0,0.5,-3)
        sTrack.BackgroundColor3=Color3_fromRGB(40,40,50)
        sTrack.BorderSizePixel=0
        sTrack.Parent=sliderFrame
        local stCrn=Instance_new("UICorner"); stCrn.CornerRadius=UDim_new(1,0); stCrn.Parent=sTrack
        local sInitF=math.clamp((St.Fl.hudSize-MIN_H_SIZE)/(MAX_H_SIZE-MIN_H_SIZE),0,1)
        local sFill=Instance_new("Frame")
        sFill.Size=UDim2_new(sInitF,0,1,0)
        sFill.BackgroundColor3=Color3_fromRGB(80,180,255)
        sFill.BorderSizePixel=0
        sFill.Parent=sTrack
        local sfCrn=Instance_new("UICorner"); sfCrn.CornerRadius=UDim_new(1,0); sfCrn.Parent=sFill
        local sKnob=Instance_new("Frame")
        sKnob.Size=UDim2_new(0,10,0,10)
        sKnob.Position=UDim2_new(sInitF,-5,0.5,-5)
        sKnob.BackgroundColor3=Color3_new(1,1,1)
        sKnob.BorderSizePixel=0
        sKnob.Parent=sTrack
        local skCrn=Instance_new("UICorner"); skCrn.CornerRadius=UDim_new(1,0); skCrn.Parent=sKnob
        local customMode=false
        local dragActive=false
        local dragOffset=Vector2.new()
        local function applySize(f)
            f=math.clamp(f,0,1)
            local sv=MIN_H_SIZE+(MAX_H_SIZE-MIN_H_SIZE)*f
            St.Fl.hudSize=sv
            frame.Size=UDim2_new(0,math_floor(BASE_HUD_W*sv),0,math_floor(BASE_HUD_H*sv))
            local ts=math.clamp(math_floor(13*sv),8,20)
            if lbl and lbl.Parent then lbl.TextSize=ts end
            sFill.Size=UDim2_new(f,0,1,0)
            sKnob.Position=UDim2_new(f,-5,0.5,-5)
            task.defer(F.saveSettings)
        end
        local function setCustomMode(on)
            customMode=on
            xBtn.Visible=on
            lockBtn.Visible=on
            sliderFrame.Visible=on
        end
        lbl.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1
            or inp.UserInputType==Enum.UserInputType.Touch then
                setCustomMode(not customMode)
            end
        end)
        lockBtn.MouseButton1Click:Connect(function()
            locked=not locked
            if locked then
                dragActive=false
                lockBtn.Text="Unlock"
                lockBtn.BackgroundColor3=Color3_fromRGB(160,100,0)
                lockBtn.TextColor3=Color3_fromRGB(255,220,120)
            else
                lockBtn.Text="Lock"
                lockBtn.BackgroundColor3=Color3_fromRGB(30,40,65)
                lockBtn.TextColor3=Color3_fromRGB(180,200,255)
            end
        end)
        xBtn.MouseButton1Click:Connect(function()
            locked=false
            setCustomMode(false)
            frame.Visible=false
            if St.UIRefs.hudToggleBtn then
                local anyVisible=false
                if St.UIRefs.hudFpsFrame and St.UIRefs.hudFpsFrame.Visible then anyVisible=true end
                if St.UIRefs.hudPingFrame and St.UIRefs.hudPingFrame.Visible then anyVisible=true end
                if not anyVisible then
                    St.UIRefs.hudToggleBtn.BackgroundColor3=UI.C.OFF
                end
            end
        end)
        frame.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1
            or inp.UserInputType==Enum.UserInputType.Touch then
                if not customMode or locked then return end
                dragActive=true
                dragOffset=Vector2.new(inp.Position.X-frame.AbsolutePosition.X,inp.Position.Y-frame.AbsolutePosition.Y)
            end
        end)
        Sv.UserInputService.InputChanged:Connect(function(inp)
            if not dragActive then return end
            if inp.UserInputType==Enum.UserInputType.MouseMovement
            or inp.UserInputType==Enum.UserInputType.Touch then
                local vp=workspace.CurrentCamera.ViewportSize
                local sz=frame.AbsoluteSize
                frame.Position=UDim2_new(0,math.clamp(inp.Position.X-dragOffset.X,0,vp.X-sz.X),0,math.clamp(inp.Position.Y-dragOffset.Y,0,vp.Y-sz.Y))
            end
        end)
        Sv.UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1
            or inp.UserInputType==Enum.UserInputType.Touch then
                dragActive=false
            end
        end)
        local sDragId=tostring(frame)
        St._sliderDrags[sDragId]={track=sTrack,apply=applySize}
        sTrack.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1
            or inp.UserInputType==Enum.UserInputType.Touch then
                local abs=sTrack.AbsoluteSize.X; if abs==0 then return end
                applySize((inp.Position.X-sTrack.AbsolutePosition.X)/abs)
                St._sliderDrags[sDragId]={track=sTrack,apply=applySize}
                St._sliderDragId=sDragId
            end
        end)
        sKnob.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1
            or inp.UserInputType==Enum.UserInputType.Touch then
                St._sliderDrags[sDragId]={track=sTrack,apply=applySize}
                St._sliderDragId=sDragId
            end
        end)
        applySize(sInitF)
        return frame,lbl
    end
    local HudFpsFrame,HudFpsLbl=_makeHudUnit("JxH_HudFps","FPS  --",Color3_new(1,1,1),100,0)
    local HudPingFrame,HudPingLbl=_makeHudUnit("JxH_HudPing","PING  --",Color3_fromRGB(0,220,90),132,0)
    St.UIRefs.hudFpsFrame=HudFpsFrame
    St.UIRefs.hudPingFrame=HudPingFrame
    St.UIRefs.hudFpsLabel=HudFpsLbl
    St.UIRefs.hudPingLabel=HudPingLbl
    local MainBtn=Instance_new("ImageButton"); MainBtn.Parent=ScreenGui
    MainBtn.Size=UDim2_new(0,46,0,46); MainBtn.Position=UDim2_new(0,10,0.5,-23)
    MainBtn.BackgroundColor3=Color3_fromRGB(15,15,15); MainBtn.BorderSizePixel=0
    MainBtn.BackgroundTransparency=0.15; MainBtn.ClipsDescendants=true
    MainBtn.ZIndex=100; MainBtn.AutoButtonColor=false; MainBtn.ScaleType=Enum.ScaleType.Fit
    local mbCrn=Instance_new("UICorner"); mbCrn.Parent=MainBtn; mbCrn.CornerRadius=UDim_new(0,12)
    local mainBtnStroke=Instance_new("UIStroke"); mainBtnStroke.Parent=MainBtn
    mainBtnStroke.Color=Color3_new(0,0,0); mainBtnStroke.Thickness=1
    local fallbackTxt=Instance_new("TextLabel"); fallbackTxt.Parent=MainBtn
    fallbackTxt.Size=UDim2_new(1,0,1,0); fallbackTxt.BackgroundTransparency=1
    fallbackTxt.Text="JX"; fallbackTxt.TextColor3=Color3_new(1,1,1)
    fallbackTxt.Font=Enum.Font.GothamBlack; fallbackTxt.TextSize=16; fallbackTxt.ZIndex=99
    setPrivateImage(MainBtn,"JXPhoTHO.png")
    St.MainBtn_ref=MainBtn
    local MainFrame=Instance_new("Frame"); MainFrame.Parent=ScreenGui
    MainFrame.AnchorPoint=Vector2.new(0.5,0.5)
    MainFrame.Size=UDim2_new(0,frameW,0,frameH)
    MainFrame.Position=UDim2_new(0.5,0,0.5,0)
    MainFrame.BackgroundColor3=UI.C.BG
    UI.registerTheme(MainFrame,"BG","BackgroundColor3")
    MainFrame.BackgroundTransparency=St.Fl.bgTransparency
    MainFrame.BorderSizePixel=0; MainFrame.Visible=false
    MainFrame.ClipsDescendants=true
    MainFrame.Active=true
    local mfCrn=Instance_new("UICorner"); mfCrn.Parent=MainFrame; mfCrn.CornerRadius=UDim_new(0,10)
    local mfStroke=Instance_new("UIStroke")
    mfStroke.Parent=MainFrame
    mfStroke.Color=UI.C.ACCENT
    mfStroke.Thickness=1.2
    mfStroke.Transparency=0.68
    UI.registerTheme(mfStroke,"ACCENT","Color")
    local menuAnimating=false
    local function openMenu()
        if menuAnimating then return end; menuAnimating=true
        MainFrame.Size=UDim2_new(0,frameW*0.8,0,frameH*0.8); MainFrame.Visible=true
        MainFrame.BackgroundTransparency=1
        Sv.TweenService:Create(MainFrame,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
            {Size=UDim2_new(0,frameW,0,frameH),BackgroundTransparency=St.Fl.bgTransparency}):Play()
        task.delay(0.4,function() menuAnimating=false end)
    end
    local function closeMenu()
        if menuAnimating then return end; menuAnimating=true
        Sv.TweenService:Create(MainFrame,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.In),
            {Size=UDim2_new(0,frameW*0.6,0,frameH*0.6),BackgroundTransparency=1}):Play()
        task.delay(0.35,function() MainFrame.Visible=false; menuAnimating=false end)
    end
    local TITLE_H=36
    local TitleBar=Instance_new("Frame"); TitleBar.Parent=MainFrame
    TitleBar.Size=UDim2_new(1,0,0,TITLE_H); TitleBar.BackgroundColor3=UI.C.PANEL
    UI.registerTheme(TitleBar,"PANEL","BackgroundColor3")
    TitleBar.BackgroundTransparency=0.3; TitleBar.BorderSizePixel=0
    local tbCrn=Instance_new("UICorner"); tbCrn.Parent=TitleBar; tbCrn.CornerRadius=UDim_new(0,10)
    TitleBar.ClipsDescendants=false
    local TFix=Instance_new("Frame"); TFix.Parent=TitleBar
    TFix.Size=UDim2_new(1,0,0.5,0); TFix.Position=UDim2_new(0,0,0.5,0)
    TFix.BackgroundColor3=UI.C.PANEL; TFix.BackgroundTransparency=0.3; TFix.BorderSizePixel=0
    UI.registerTheme(TFix,"PANEL","BackgroundColor3")
    local TitleLbl=Instance_new("TextLabel"); TitleLbl.Parent=MainFrame
    TitleLbl.Size=UDim2_new(1,0,1,0); TitleLbl.BackgroundTransparency=1
    TitleLbl.Text="JohnyX Script"
    TitleLbl.TextColor3=Color3_new(1,1,1)
    UI.registerTheme(TitleLbl,"TEXT","TextColor3")
    TitleLbl.Font=Enum.Font.GothamBold; TitleLbl.TextSize=13
    TitleLbl.TextXAlignment=Enum.TextXAlignment.Center
    local HideBtn=Instance_new("TextButton"); HideBtn.Parent=TitleBar
    HideBtn.Size=UDim2_new(0,22,0,22); HideBtn.Position=UDim2_new(1,-27,0.5,-11)
    HideBtn.BackgroundColor3=Color3_fromRGB(200,50,50)
    HideBtn.BackgroundTransparency=1
    HideBtn.Text="_"
    HideBtn.TextColor3=UI.C.ACCENT; HideBtn.Font=Enum.Font.GothamBold
    UI.registerTheme(HideBtn,"ACCENT","TextColor3")
    HideBtn.TextSize=15; HideBtn.BorderSizePixel=0
    local hbCrn=Instance_new("UICorner"); hbCrn.Parent=HideBtn; hbCrn.CornerRadius=UDim_new(0,6)
    local hbStroke=Instance_new("UIStroke"); hbStroke.Parent=HideBtn
    hbStroke.Color=UI.C.ACCENT; hbStroke.Thickness=1.4
    UI.registerTheme(hbStroke,"ACCENT","Color")
    HideBtn.MouseButton1Click:Connect(closeMenu)
    local guiDragging=false
    local guiDragStart,guiStartPos,guiDragInput=nil,nil,nil
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            guiDragging=true
            guiDragInput=input
            guiDragStart=input.Position
            guiStartPos=MainFrame.AbsolutePosition + (MainFrame.AbsoluteSize / 2)
        end
    end)
    Sv.UserInputService.InputEnded:Connect(function(input)
        if input==guiDragInput then
            guiDragging=false
            guiDragInput=nil
        end
    end)
    Sv.UserInputService.InputChanged:Connect(function(input)
        if not guiDragging then return end
        if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end
        local delta=input.Position-guiDragStart
        local vp=workspace.CurrentCamera.ViewportSize
        local szW=MainFrame.AbsoluteSize.X/2
        local szH=MainFrame.AbsoluteSize.Y/2
        local newX=math.clamp(guiStartPos.X+delta.X,szW,vp.X-szW)
        local newY=math.clamp(guiStartPos.Y+delta.Y,szH,vp.Y-szH)
        MainFrame.Position=UDim2_new(0,newX,0,newY)
    end)
    local BADGE_H=20
    local TeamBadge=Instance_new("TextLabel"); TeamBadge.Parent=MainFrame
    TeamBadge.Size=UDim2_new(1,0,0,BADGE_H); TeamBadge.Position=UDim2_new(0,0,0,TITLE_H)
    TeamBadge.BackgroundColor3=UI.C.ROW; TeamBadge.BorderSizePixel=0
    UI.registerTheme(TeamBadge,"ROW","BackgroundColor3")
    TeamBadge.BackgroundTransparency=0.75
    TeamBadge.Text="LOBBY"; TeamBadge.TextColor3=Color3_new(1,1,1)
    TeamBadge.Font=Enum.Font.GothamBold; TeamBadge.TextSize=10
    TeamBadge.TextXAlignment=Enum.TextXAlignment.Center
    St.UIRefs.teamBadge=TeamBadge
    local SIDEBAR_W=82
    local BODY_TOP=TITLE_H+BADGE_H+2
    local Sidebar=Instance_new("Frame"); Sidebar.Parent=MainFrame
    Sidebar.Size=UDim2_new(0,SIDEBAR_W,1,-BODY_TOP)
    Sidebar.Position=UDim2_new(0,0,0,BODY_TOP)
    Sidebar.BackgroundColor3=UI.C.PANEL; Sidebar.BackgroundTransparency=St.Fl.bgTransparency
    Sidebar.ClipsDescendants=true
    UI.registerTheme(Sidebar,"PANEL","BackgroundColor3")
    Sidebar.BorderSizePixel=0; Sidebar.ClipsDescendants=true
    local sbCrn=Instance_new("UICorner"); sbCrn.Parent=Sidebar; sbCrn.CornerRadius=UDim_new(0,10)
    local TabContainer=Instance_new("Frame"); TabContainer.Parent=Sidebar
    TabContainer.Size=UDim2_new(1,0,1,-40); TabContainer.BackgroundTransparency=1
    TabContainer.ClipsDescendants=true
    local SbList=Instance_new("UIListLayout"); SbList.Parent=TabContainer
    SbList.Padding=UDim_new(0,3); SbList.SortOrder=Enum.SortOrder.LayoutOrder
    SbList.HorizontalAlignment=Enum.HorizontalAlignment.Center
    local sbPad=Instance_new("UIPadding"); sbPad.Parent=TabContainer
    sbPad.PaddingTop=UDim_new(0,6); sbPad.PaddingBottom=UDim_new(0,4)
    sbPad.PaddingLeft=UDim_new(0,4); sbPad.PaddingRight=UDim_new(0,4)
    local function fullClose()
        F.saveSettings()
        if St.Connections.Jump then St.Connections.Jump:Disconnect() end
        if St.Connections.State then St.Connections.State:Disconnect() end
        St.Fl.autoFarmRunning=false; St.Fl.killAllRunning=false; St.Settings.SpeedEnabled=false
        if St.Cn.speed then St.Cn.speed:Disconnect(); St.Cn.speed=nil end
        F.stopAutoEscape(); F.stopKillerSafety(); F.stopNoclip(); F.stopAntiAFK(); F.disableFogRemoval()
        F.stopAutoRevive(); F.stopAutoSelfRevive(); F.stopFly(); F.stopSnowAnimation()
        F.stopFpsBoost()
        if St.Fl.ghostActive then F.toggleGhostMode(false) end
        St.Fl.reviveSelfPaused=false; St.Fl.farmPriority=0
        for _,data in pairs(St.Storage.Players) do
            if data.colorDot then pcall(function() data.colorDot:Destroy() end) end
            F.safeDestroy(data.bgui); F.safeDestroy(data.bguiDist); F.safeDestroy(data.bguiBox); F.safeDestroy(data.hl)
            if data.conn then data.conn:Disconnect() end
        end
        F.clearTable(St.Storage.Players)
        for _,conn in pairs(St.Storage.TeamConns) do conn:Disconnect() end
        F.clearTable(St.Storage.TeamConns)
        for _,lv in pairs(St.Storage.Lives) do F.safeDestroy(lv.bgui) end; F.clearTable(St.Storage.Lives)
        for _,entry in pairs(St.Storage.Loot) do F.safeDestroy(entry.bgui) end; F.clearTable(St.Storage.Loot)
        for _,v in pairs(St.Storage.Exits) do F.safeDestroy(v) end; F.clearTable(St.Storage.Exits)
        F.clearTable(St.Storage.NameLabels); F.clearTable(St.Storage.DistLabels)
        F.clearTable(St.espColorCache); F.clearTable(St.lootValueCache)
        F.clearTable(St.livesData); F.clearTable(St.livesDownState)
        ScreenGui:Destroy()
    end
    local function showCloseConfirm()
        local overlay=Instance_new("Frame")
        overlay.Size=UDim2_new(1,0,1,0)
        overlay.BackgroundColor3=Color3_new(0,0,0)
        overlay.BackgroundTransparency=0.5
        overlay.ZIndex=100
        overlay.Active=true
        overlay.Parent=ScreenGui
        local dialog=Instance_new("Frame")
        dialog.Size=UDim2_new(0,240,0,110)
        dialog.Position=UDim2_new(0.5,-120,0.5,-55)
        dialog.BackgroundColor3=UI.C.PANEL
        UI.registerTheme(dialog,"PANEL","BackgroundColor3")
        dialog.ZIndex=101
        dialog.Parent=overlay
        local dCrn=Instance_new("UICorner"); dCrn.CornerRadius=UDim_new(0,8); dCrn.Parent=dialog
        local dStr=Instance_new("UIStroke"); dStr.Color=UI.C.ACCENT; dStr.Thickness=1; dStr.Parent=dialog
        UI.registerTheme(dStr,"ACCENT","Color")
        local lbl=Instance_new("TextLabel")
        lbl.Size=UDim2_new(1,0,0,50)
        lbl.Position=UDim2_new(0,0,0,10)
        lbl.BackgroundTransparency=1
        lbl.Text=_T("confirm_close")
        lbl.TextColor3=Color3_new(1,1,1)
        UI.registerTheme(lbl,"TEXT","TextColor3")
        lbl.Font=Enum.Font.GothamBold
        lbl.TextSize=11
        lbl.ZIndex=102
        lbl.Parent=dialog
        _LR(lbl,"confirm_close")
        local yesBtn=Instance_new("TextButton")
        yesBtn.Size=UDim2_new(0,90,0,28)
        yesBtn.Position=UDim2_new(0,20,0,65)
        yesBtn.BackgroundColor3=UI.C.ACCENT
        UI.registerTheme(yesBtn,"ACCENT","BackgroundColor3")
        yesBtn.Text=_T("btn_yes")
        yesBtn.TextColor3=Color3_new(1,1,1)
        UI.registerTheme(yesBtn,"TEXT","TextColor3")
        yesBtn.Font=Enum.Font.GothamBold
        yesBtn.TextSize=10
        yesBtn.ZIndex=102
        yesBtn.Parent=dialog
        local yCrn=Instance_new("UICorner"); yCrn.CornerRadius=UDim_new(0,6); yCrn.Parent=yesBtn
        _LR(yesBtn,"btn_yes")
        local noBtn=Instance_new("TextButton")
        noBtn.Size=UDim2_new(0,90,0,28)
        noBtn.Position=UDim2_new(1,-110,0,65)
        noBtn.BackgroundColor3=UI.C.OFF
        UI.registerTheme(noBtn,"OFF","BackgroundColor3")
        noBtn.Text=_T("btn_no")
        noBtn.TextColor3=Color3_new(1,1,1)
        UI.registerTheme(noBtn,"TEXT","TextColor3")
        noBtn.Font=Enum.Font.GothamBold
        noBtn.TextSize=10
        noBtn.ZIndex=102
        noBtn.Parent=dialog
        local nCrn=Instance_new("UICorner"); nCrn.CornerRadius=UDim_new(0,6); nCrn.Parent=noBtn
        _LR(noBtn,"btn_no")
        yesBtn.MouseButton1Click:Connect(function() fullClose() end)
        noBtn.MouseButton1Click:Connect(function() overlay:Destroy() end)
    end
    local CloseSidebarBtn=Instance_new("TextButton"); CloseSidebarBtn.Parent=Sidebar
    CloseSidebarBtn.Size=UDim2_new(1,-12,0,30); CloseSidebarBtn.Position=UDim2_new(0,6,1,-36)
    CloseSidebarBtn.BackgroundColor3=UI.C.PANEL; CloseSidebarBtn.BorderSizePixel=0
    CloseSidebarBtn.BackgroundTransparency=0.35
    UI.registerTheme(CloseSidebarBtn,"PANEL","BackgroundColor3")
    CloseSidebarBtn.Text="EXIT"; CloseSidebarBtn.TextColor3=Color3_fromRGB(255,60,60)
    CloseSidebarBtn.Font=Enum.Font.GothamBold; CloseSidebarBtn.TextSize=12
    local csbCrn=Instance_new("UICorner"); csbCrn.Parent=CloseSidebarBtn; csbCrn.CornerRadius=UDim_new(0,6)
    _LR(CloseSidebarBtn,"close_script")
    CloseSidebarBtn.MouseButton1Click:Connect(showCloseConfirm)
    local ContentArea=Instance_new("Frame"); ContentArea.Parent=MainFrame
    ContentArea.Size=UDim2_new(1,-(SIDEBAR_W+4),1,-BODY_TOP-2)
    ContentArea.Position=UDim2_new(0,SIDEBAR_W+3,0,BODY_TOP+1)
    ContentArea.BackgroundColor3=UI.C.PANEL; ContentArea.BackgroundTransparency=St.Fl.bgTransparency
    UI.registerTheme(ContentArea,"PANEL","BackgroundColor3")
    ContentArea.BorderSizePixel=0; ContentArea.ClipsDescendants=true
    local caCrn=Instance_new("UICorner"); caCrn.Parent=ContentArea; caCrn.CornerRadius=UDim_new(0,10)
    local pages={}; local tabFrames={}; local tabLbls={}; local activeAccents={}
    local function selectTab(name)
        St.Fl.currentTab=name
        for n,pg in pairs(pages) do pg.Visible=n==name end
        for n,tf in pairs(tabFrames) do
            local on=n==name
            Sv.TweenService:Create(tf,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
                BackgroundColor3=on and UI.C.ROW or UI.C.PANEL,
                BackgroundTransparency=on and 0 or 1
            }):Play()
            if tabLbls[n] then
                local targetColor=on and Color3_new(1,1,1) or UI.C.SUBTEXT
                Sv.TweenService:Create(tabLbls[n],TweenInfo.new(0.18),{TextColor3=targetColor}):Play()
            end
            if activeAccents[n] then activeAccents[n].Visible=on end
        end
    end
    St.UIRefs._updateTabs=function() selectTab(St.Fl.currentTab or "home") end
    local function makePage()
        local sf=Instance_new("ScrollingFrame"); sf.Parent=ContentArea
        sf.Size=UDim2_new(1,0,1,0); sf.BackgroundTransparency=1; sf.BorderSizePixel=0
        sf.ScrollBarThickness=2; sf.ScrollBarImageColor3=UI.C.ACCDIM
        UI.registerTheme(sf,"ACCDIM","ScrollBarImageColor3")
        sf.CanvasSize=UDim2_new(0,0,0,0); sf.Visible=false
        sf.ScrollingDirection=Enum.ScrollingDirection.Y
        sf.ElasticBehavior=Enum.ElasticBehavior.Always
        sf.ClipsDescendants=true
        local ll=Instance_new("UIListLayout"); ll.Parent=sf
        ll.Padding=UDim_new(0,6); ll.HorizontalAlignment=Enum.HorizontalAlignment.Center
        ll.SortOrder=Enum.SortOrder.LayoutOrder
        ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            sf.CanvasSize=UDim2_new(0,0,0,ll.AbsoluteContentSize.Y+16)
        end)
        local pad=Instance_new("UIPadding"); pad.Parent=sf
        pad.PaddingTop=UDim_new(0,8); pad.PaddingLeft=UDim_new(0,8); pad.PaddingRight=UDim_new(0,8)
        return sf
    end
    local TAB_COUNT=4
    local function _fitTabs()
        local avail=TabContainer.AbsoluteSize.Y-10-TAB_COUNT*3
        local h=math_floor(avail/TAB_COUNT)
        h=math_max(h,40); h=math_min(h,72)
        local iconY=math_floor(h*0.10)
        local lblY=h-17
        for _,tf in pairs(tabFrames) do
            tf.Size=UDim2_new(1,0,0,h)
            local ic=tf:FindFirstChildOfClass("ImageLabel")
            if ic then
                local half=math_floor(ic.Size.X.Offset/2)
                ic.Position=UDim2_new(0.5,-half,0,iconY)
            end
            for _,c in ipairs(tf:GetChildren()) do
                if c:IsA("TextLabel") then c.Position=UDim2_new(0,0,0,lblY) end
            end
        end
    end
    local function addTab(name,label,iconFile)
        local tf=Instance_new("Frame"); tf.Parent=TabContainer
        tf.Size=UDim2_new(1,0,0,62)
        tf.BackgroundColor3=UI.C.ROW; tf.BackgroundTransparency=1; tf.BorderSizePixel=0
        local tfCrn=Instance_new("UICorner"); tfCrn.Parent=tf; tfCrn.CornerRadius=UDim_new(0,8)
        local accentBar=Instance_new("Frame"); accentBar.Parent=tf
        accentBar.Size=UDim2_new(0,3,0.55,0); accentBar.Position=UDim2_new(0,0,0.225,0)
        accentBar.BackgroundColor3=UI.C.ACCENT; accentBar.BorderSizePixel=0; accentBar.Visible=false
        UI.registerTheme(accentBar,"ACCENT","BackgroundColor3")
        local abCrn=Instance_new("UICorner"); abCrn.Parent=accentBar; abCrn.CornerRadius=UDim_new(1,0)
        activeAccents[name]=accentBar
        local hoverGlow=Instance_new("UIStroke"); hoverGlow.Parent=tf
        hoverGlow.Color=UI.C.ACCENT; hoverGlow.Thickness=0; hoverGlow.Transparency=0.5
        UI.registerTheme(hoverGlow,"ACCENT","Color")
        local iconImg=nil
        if iconFile then
            iconImg=Instance_new("ImageLabel"); iconImg.Parent=tf
            iconImg.Size=UDim2_new(0,32,0,32); iconImg.Position=UDim2_new(0.5,-16,0,6)
            iconImg.BackgroundTransparency=1; iconImg.ScaleType=Enum.ScaleType.Fit
            setPrivateImage(iconImg,iconFile)
        end
        local lbl=Instance_new("TextLabel"); lbl.Parent=tf
        lbl.Size=UDim2_new(1,0,0,16); lbl.Position=UDim2_new(0,0,0,43)
        lbl.BackgroundTransparency=1; lbl.Text=label
        lbl.TextColor3=UI.C.SUBTEXT; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=9
        lbl.TextXAlignment=Enum.TextXAlignment.Center
        tabLbls[name]=lbl
        local clickBtn=Instance_new("TextButton"); clickBtn.Parent=tf
        clickBtn.Size=UDim2_new(1,0,1,0); clickBtn.BackgroundTransparency=1
        clickBtn.Text=""; clickBtn.BorderSizePixel=0
        local tiH=TweenInfo.new(0.12)
        clickBtn.MouseEnter:Connect(function()
            Sv.TweenService:Create(hoverGlow,tiH,{Thickness=1}):Play()
            Sv.TweenService:Create(tf,tiH,{BackgroundTransparency=0.55}):Play()
            if iconImg then Sv.TweenService:Create(iconImg,tiH,{Size=UDim2_new(0,35,0,35),Position=UDim2_new(0.5,-17,0,5)}):Play() end
        end)
        clickBtn.MouseLeave:Connect(function()
            Sv.TweenService:Create(hoverGlow,tiH,{Thickness=0}):Play()
            Sv.TweenService:Create(tf,tiH,{BackgroundTransparency=1}):Play()
            if iconImg then Sv.TweenService:Create(iconImg,tiH,{Size=UDim2_new(0,32,0,32),Position=UDim2_new(0.5,-16,0,6)}):Play() end
        end)
        clickBtn.MouseButton1Click:Connect(function() selectTab(name) end)
        tabFrames[name]=tf; pages[name]=makePage()
        return pages[name]
    end
    local homePage=addTab("home","Home",nil)
    local espPage=addTab("esp","ESP","esp.png")
    local farmPage=addTab("farm","Farm","Farm.png")
    local settPage=addTab("sett","Settings","setting.png")
    task.defer(_fitTabs)
    MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(_fitTabs)
    do
        local htf=tabFrames["home"]
        local hIcon=Instance_new("ImageLabel"); hIcon.Parent=htf
        hIcon.Size=UDim2_new(0,32,0,32); hIcon.Position=UDim2_new(0.5,-16,0,6)
        hIcon.BackgroundTransparency=1; hIcon.ScaleType=Enum.ScaleType.Fit
        setPrivateImage(hIcon,"Home.png")
        St.UIRefs.homeIcon=hIcon
    end
    _LR(tabLbls["home"],"home_tab")
    _LR(tabLbls["esp"],"esp_tab")
    _LR(tabLbls["farm"],"farm_tab")
    _LR(tabLbls["sett"],"sett_tab")
    local function _buildHome()
        local LP=Sv.LocalPlayer
        local credCard=Instance_new("Frame"); credCard.Parent=homePage
        credCard.Size=UDim2_new(1,0,0,68); credCard.BackgroundColor3=UI.C.ROW
        UI.registerTheme(credCard,"ROW","BackgroundColor3")
        credCard.BackgroundTransparency=0.2; credCard.BorderSizePixel=0
        local ccCrn=Instance_new("UICorner"); ccCrn.Parent=credCard; ccCrn.CornerRadius=UDim_new(0,10)
        local ccStr=Instance_new("UIStroke"); ccStr.Parent=credCard
        ccStr.Color=UI.C.ACCENT; ccStr.Thickness=0.8; ccStr.Transparency=0.3
        UI.registerTheme(ccStr,"ACCENT","Color")
        local ccTitle=Instance_new("TextLabel"); ccTitle.Parent=credCard
        ccTitle.Size=UDim2_new(1,0,0,28); ccTitle.Position=UDim2_new(0,0,0,4)
        ccTitle.BackgroundTransparency=1; ccTitle.TextColor3=Color3_new(1,1,1)
        UI.registerTheme(ccTitle,"TEXT","TextColor3")
        ccTitle.Font=Enum.Font.GothamBold; ccTitle.TextSize=13
        ccTitle.TextXAlignment=Enum.TextXAlignment.Center
        _LR(ccTitle,"credits")
        local ccSub=Instance_new("TextLabel"); ccSub.Parent=credCard
        ccSub.Size=UDim2_new(1,0,0,18); ccSub.Position=UDim2_new(0,0,0,28)
        ccSub.BackgroundTransparency=1; ccSub.TextColor3=UI.C.SUBTEXT
        UI.registerTheme(ccSub,"SUBTEXT","TextColor3")
        ccSub.Font=Enum.Font.GothamSemibold; ccSub.TextSize=9
        ccSub.TextXAlignment=Enum.TextXAlignment.Center
        _LR(ccSub,"credits_sub")
        local ccMotto=Instance_new("TextLabel"); ccMotto.Parent=credCard
        ccMotto.Size=UDim2_new(1,0,0,16); ccMotto.Position=UDim2_new(0,0,0,46)
        ccMotto.BackgroundTransparency=1; ccMotto.TextColor3=UI.C.ACCENT
        UI.registerTheme(ccMotto,"ACCENT","TextColor3")
        ccMotto.Font=Enum.Font.GothamBold; ccMotto.TextSize=10
        ccMotto.TextXAlignment=Enum.TextXAlignment.Center
        _LR(ccMotto,"motto")
        local verLbl=Instance_new("TextLabel"); verLbl.Parent=credCard
        verLbl.Size=UDim2_new(1,0,0,14); verLbl.Position=UDim2_new(0,0,1,-14)
        verLbl.BackgroundTransparency=1; verLbl.Text=UPDATE_VERSION
        verLbl.TextColor3=UI.C.SUBTEXT; verLbl.Font=Enum.Font.GothamBold
        UI.registerTheme(verLbl,"SUBTEXT","TextColor3")
        verLbl.TextSize=8; verLbl.TextXAlignment=Enum.TextXAlignment.Right
        verLbl.ZIndex=verLbl.Parent.ZIndex+1
        UI.A(homePage,credCard)
        local cardRow=Instance_new("Frame"); cardRow.Parent=homePage
        cardRow.Size=UDim2_new(1,0,0,64); cardRow.BackgroundColor3=UI.C.ROW
        UI.registerTheme(cardRow,"ROW","BackgroundColor3")
        cardRow.BackgroundTransparency=0.45; cardRow.BorderSizePixel=0
        local cardCrn=Instance_new("UICorner"); cardCrn.Parent=cardRow; cardCrn.CornerRadius=UDim_new(0,10)
        local cStr=Instance_new("UIStroke"); cStr.Parent=cardRow
        cStr.Color=Color3_fromRGB(255,255,255); cStr.Thickness=0.5; cStr.Transparency=0.82
        UI.A(homePage,cardRow)
        local avatarImg=Instance_new("ImageLabel"); avatarImg.Parent=cardRow
        avatarImg.Size=UDim2_new(0,48,0,48); avatarImg.Position=UDim2_new(0,8,0.5,-24)
        avatarImg.BackgroundColor3=UI.C.PANEL; avatarImg.BorderSizePixel=0
        UI.registerTheme(avatarImg,"PANEL","BackgroundColor3")
        avatarImg.ScaleType=Enum.ScaleType.Fit
        local avCrn=Instance_new("UICorner"); avCrn.Parent=avatarImg; avCrn.CornerRadius=UDim_new(0,8)
        local avStr=Instance_new("UIStroke"); avStr.Parent=avatarImg
        avStr.Color=UI.C.ACCENT; avStr.Thickness=1; avStr.Transparency=0.4
        UI.registerTheme(avStr,"ACCENT","Color")
        task.spawn(function()
            local ok,img=pcall(function()
                return Sv.Players:GetUserThumbnailAsync(LP.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size60x60)
            end)
            if ok and img and avatarImg.Parent then avatarImg.Image=img end
        end)
        St.UIRefs.avatarImg=avatarImg
        local nameLbl=Instance_new("TextLabel"); nameLbl.Parent=cardRow
        nameLbl.Size=UDim2_new(1,-66,0,22); nameLbl.Position=UDim2_new(0,62,0,10)
        nameLbl.BackgroundTransparency=1; nameLbl.Text=LP.DisplayName
        nameLbl.TextColor3=Color3_new(1,1,1); nameLbl.Font=Enum.Font.GothamBold
        UI.registerTheme(nameLbl,"TEXT","TextColor3")
        nameLbl.TextSize=12; nameLbl.TextXAlignment=Enum.TextXAlignment.Left
        St.UIRefs.homeNameLbl=nameLbl
        local userLbl=Instance_new("TextLabel"); userLbl.Parent=cardRow
        userLbl.Size=UDim2_new(1,-66,0,16); userLbl.Position=UDim2_new(0,62,0,34)
        userLbl.BackgroundTransparency=1; userLbl.Text="@"..LP.Name
        userLbl.TextColor3=UI.C.SUBTEXT; userLbl.Font=Enum.Font.GothamSemibold
        UI.registerTheme(userLbl,"SUBTEXT","TextColor3")
        userLbl.TextSize=9; userLbl.TextXAlignment=Enum.TextXAlignment.Left
        St.UIRefs.homeUserLbl=userLbl
        local function _makeStatCard(parent,titleKey,valText,color,slot,total)
            local gap=6
            local card=Instance_new("Frame"); card.Parent=parent
            card.Size=UDim2_new(1/total,-gap*(total-1)/total,1,0)
            card.Position=UDim2_new((slot-1)/total,(slot-1)*gap/total,0,0)
            card.BackgroundColor3=UI.C.ROW; card.BackgroundTransparency=0.4; card.BorderSizePixel=0
            UI.registerTheme(card,"ROW","BackgroundColor3")
            local cCrn=Instance_new("UICorner"); cCrn.Parent=card; cCrn.CornerRadius=UDim_new(0,8)
            local cStr=Instance_new("UIStroke"); cStr.Parent=card
            cStr.Color=color or UI.C.ACCENT; cStr.Thickness=0.7; cStr.Transparency=0.5
            if not color then UI.registerTheme(cStr,"ACCENT","Color") end
            local tLbl=Instance_new("TextLabel"); tLbl.Parent=card
            tLbl.Size=UDim2_new(1,0,0,18); tLbl.Position=UDim2_new(0,0,0,4)
            tLbl.BackgroundTransparency=1; tLbl.TextColor3=UI.C.SUBTEXT
            UI.registerTheme(tLbl,"SUBTEXT","TextColor3")
            tLbl.Font=Enum.Font.GothamBold; tLbl.TextSize=8; tLbl.TextXAlignment=Enum.TextXAlignment.Center
            _LR(tLbl,titleKey)
            local vLbl=Instance_new("TextLabel"); vLbl.Parent=card
            vLbl.Size=UDim2_new(1,0,0,22); vLbl.Position=UDim2_new(0,0,0,24)
            vLbl.BackgroundTransparency=1; vLbl.Text=valText
            vLbl.TextColor3=color or Color3_new(1,1,1); vLbl.Font=Enum.Font.GothamBold
            if not color then UI.registerTheme(vLbl,"TEXT","TextColor3") end
            vLbl.TextSize=14; vLbl.TextXAlignment=Enum.TextXAlignment.Center
            return card,vLbl
        end
        local serverRow=Instance_new("Frame"); serverRow.Parent=homePage
        serverRow.Size=UDim2_new(1,0,0,52); serverRow.BackgroundTransparency=1; serverRow.BorderSizePixel=0
        UI.A(homePage,serverRow)
        local _,pingValLbl=_makeStatCard(serverRow,"ping_card","--ms",Color3_fromRGB(80,160,255),1,3)
        local _,fpsValLbl=_makeStatCard(serverRow,"fps_lbl","--",Color3_fromRGB(100,255,100),2,3)
        local _,uptimeLbl=_makeStatCard(serverRow,"uptime","00:00",Color3_fromRGB(180,140,255),3,3)
        local serverHRow=Instance_new("Frame"); serverHRow.Parent=homePage
        serverHRow.Size=UDim2_new(1,0,0,56); serverHRow.BackgroundTransparency=1; serverHRow.BorderSizePixel=0
        UI.A(homePage,serverHRow)
        local function _makeMiniCard(parent,titleKey,valText,color,slot,total)
            local gap=4
            local card=Instance_new("Frame"); card.Parent=parent
            card.Size=UDim2_new(1/total,-gap*(total-1)/total,1,0)
            card.Position=UDim2_new((slot-1)/total,(slot-1)*gap/(total),0,0)
            card.BackgroundColor3=UI.C.ROW; card.BackgroundTransparency=0.4; card.BorderSizePixel=0
            UI.registerTheme(card,"ROW","BackgroundColor3")
            local cCrn=Instance_new("UICorner"); cCrn.Parent=card; cCrn.CornerRadius=UDim_new(0,8)
            local cStr=Instance_new("UIStroke"); cStr.Parent=card
            cStr.Color=color; cStr.Thickness=0.7; cStr.Transparency=0.5
            local tL=Instance_new("TextLabel"); tL.Parent=card
            tL.Size=UDim2_new(1,0,0,18); tL.Position=UDim2_new(0,0,0,3)
            tL.BackgroundTransparency=1; tL.TextColor3=UI.C.SUBTEXT
            UI.registerTheme(tL,"SUBTEXT","TextColor3")
            tL.Font=Enum.Font.GothamBold; tL.TextSize=8; tL.TextXAlignment=Enum.TextXAlignment.Center
            _LR(tL,titleKey)
            local vL=Instance_new("TextLabel"); vL.Parent=card
            vL.Size=UDim2_new(1,0,0,22); vL.Position=UDim2_new(0,0,0,22)
            vL.BackgroundTransparency=1; vL.Text=valText
            vL.TextColor3=color; vL.Font=Enum.Font.GothamBold
            vL.TextSize=13; vL.TextXAlignment=Enum.TextXAlignment.Center
            return vL
        end
        local farmSuccessLbl=_makeMiniCard(serverHRow,"farm_success","0",UI.C.GOOD,1,4)
        local farmFailLbl=_makeMiniCard(serverHRow,"farm_fail","0",UI.C.DANGER,2,4)
        local farmEscLbl=_makeMiniCard(serverHRow,"farm_escapes","0",Color3_fromRGB(180,140,255),3,4)
        local farmCoinLbl=_makeMiniCard(serverHRow,"farm_coins","0",UI.C.WARN,4,4)
        St.UIRefs.farmSuccessLbl=farmSuccessLbl
        St.UIRefs.farmFailLbl=farmFailLbl
        St.UIRefs.farmEscLbl=farmEscLbl
        St.UIRefs.farmCoinLbl=farmCoinLbl
        local statusRow=Instance_new("Frame"); statusRow.Parent=homePage
        statusRow.Size=UDim2_new(1,0,0,32); statusRow.BackgroundColor3=UI.C.ROW
        UI.registerTheme(statusRow,"ROW","BackgroundColor3")
        statusRow.BackgroundTransparency=0.45; statusRow.BorderSizePixel=0
        local stCrn=Instance_new("UICorner"); stCrn.Parent=statusRow; stCrn.CornerRadius=UDim_new(0,8)
        local stStr=Instance_new("UIStroke"); stStr.Parent=statusRow
        stStr.Color=Color3_fromRGB(255,255,255); stStr.Thickness=0.5; stStr.Transparency=0.82
        UI.A(homePage,statusRow)
        local dot=Instance_new("Frame"); dot.Parent=statusRow
        dot.Size=UDim2_new(0,9,0,9); dot.Position=UDim2_new(0,10,0.5,-4)
        dot.BackgroundColor3=Color3_fromRGB(0,255,120); dot.BorderSizePixel=0
        local dotCrn=Instance_new("UICorner"); dotCrn.Parent=dot; dotCrn.CornerRadius=UDim_new(1,0)
        local dotGlow=Instance_new("UIStroke"); dotGlow.Parent=dot
        dotGlow.Color=Color3_fromRGB(0,255,120); dotGlow.Thickness=2
        St.UIRefs.statusDot=dot
        St.UIRefs.statusDotGlow=dotGlow
        task.spawn(function()
            local ts=Sv.TweenService
            local ti=TweenInfo.new(0.85,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,0,true)
            while dot.Parent do
                local detected=St.Analytics.farmFail>=20
                local col=detected and Color3_fromRGB(255,60,60) or Color3_fromRGB(0,255,120)
                ts:Create(dot,ti,{BackgroundColor3=col}):Play()
                task.wait(1.7)
            end
        end)
        local statusLbl=Instance_new("TextLabel"); statusLbl.Parent=statusRow
        statusLbl.Size=UDim2_new(1,-26,1,0); statusLbl.Position=UDim2_new(0,24,0,0)
        statusLbl.BackgroundTransparency=1; statusLbl.TextColor3=Color3_fromRGB(0,255,120)
        statusLbl.Font=Enum.Font.GothamBold; statusLbl.TextSize=10
        statusLbl.TextXAlignment=Enum.TextXAlignment.Left
        _LR(statusLbl,"status_ok")
        St.UIRefs.statusLbl=statusLbl
        do
            local hudBtnRow=Instance_new("Frame"); hudBtnRow.Parent=homePage
            hudBtnRow.Size=UDim2_new(1,0,0,32); hudBtnRow.BackgroundColor3=UI.C.ROW
            UI.registerTheme(hudBtnRow,"ROW","BackgroundColor3")
            hudBtnRow.BackgroundTransparency=0.45; hudBtnRow.BorderSizePixel=0
            local hbrCrn=Instance_new("UICorner"); hbrCrn.Parent=hudBtnRow; hbrCrn.CornerRadius=UDim_new(0,8)
            local hbrStr=Instance_new("UIStroke"); hbrStr.Parent=hudBtnRow
            hbrStr.Color=Color3_fromRGB(255,255,255); hbrStr.Thickness=0.5; hbrStr.Transparency=0.82
            UI.A(homePage,hudBtnRow)
            local hudToggleBtn=Instance_new("TextButton"); hudToggleBtn.Parent=hudBtnRow
            hudToggleBtn.Size=UDim2_new(1,-14,0,22); hudToggleBtn.Position=UDim2_new(0,7,0.5,-11)
            hudToggleBtn.BackgroundColor3=UI.C.OFF; hudToggleBtn.BorderSizePixel=0
            UI.registerTheme(hudToggleBtn,"OFF","BackgroundColor3")
            hudToggleBtn.TextColor3=Color3_new(1,1,1); hudToggleBtn.Font=Enum.Font.GothamBold
            UI.registerTheme(hudToggleBtn,"TEXT","TextColor3")
            hudToggleBtn.TextSize=10; hudToggleBtn.Text="FPS / PING  HUD"
            local htbCrn=Instance_new("UICorner"); htbCrn.Parent=hudToggleBtn; htbCrn.CornerRadius=UDim_new(0,6)
            local htbStr=Instance_new("UIStroke"); htbStr.Parent=hudToggleBtn
            htbStr.Color=Color3_fromRGB(255,255,255); htbStr.Thickness=0.6; htbStr.Transparency=0.75
            St.UIRefs.hudToggleBtn=hudToggleBtn
            hudToggleBtn.MouseButton1Click:Connect(function()
                local fps=St.UIRefs.hudFpsFrame
                local ping=St.UIRefs.hudPingFrame
                if not fps or not ping then return end
                local nowVisible=fps.Visible or ping.Visible
                fps.Visible=not nowVisible
                ping.Visible=not nowVisible
                hudToggleBtn.BackgroundColor3=(not nowVisible) and UI.C.ACCENT or UI.C.OFF
            end)
            UI.applyHover(hudToggleBtn,"OFF","DIV")
        end
        local _UIRefs = St.UIRefs
        local _Analytics = St.Analytics
        local _mfloor = math_floor
        local _tostr = tostring
        local frameCount = 0
        Sv.RunService.RenderStepped:Connect(function() frameCount = frameCount + 1 end)
        task.spawn(function()
            local lastTime = tick()
            while task.wait(0.5) do
                local currentTime = tick()
                local fpsVal = _mfloor(frameCount / (currentTime - lastTime))
                frameCount = 0
                lastTime = currentTime
                local fpsStr = _tostr(fpsVal)
                if fpsValLbl and fpsValLbl.Parent then fpsValLbl.Text = fpsStr end
                local hudFps = _UIRefs.hudFpsLabel
                if hudFps and hudFps.Parent and _UIRefs.hudFpsFrame and _UIRefs.hudFpsFrame.Visible then
                    hudFps.Text = "FPS  " .. fpsStr
                    if fpsVal >= 40 then hudFps.TextColor3 = Color3_fromRGB(0,255,120)
                    elseif fpsVal >= 20 then hudFps.TextColor3 = Color3_fromRGB(255,200,0)
                    else hudFps.TextColor3 = Color3_fromRGB(255,60,60) end
                end
                local p = 0
                pcall(function() p = Sv.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
                local pv = _mfloor(p + 0.5)
                local ps = pv .. "ms"
                if pingValLbl and pingValLbl.Parent then pingValLbl.Text = ps end
                local hudPing = _UIRefs.hudPingLabel
                if hudPing and hudPing.Parent and _UIRefs.hudPingFrame and _UIRefs.hudPingFrame.Visible then
                    hudPing.Text = "PING  " .. ps
                    if pv < 100 then hudPing.TextColor3 = Color3_fromRGB(0,255,120)
                    elseif pv < 200 then hudPing.TextColor3 = Color3_fromRGB(255,200,0)
                    else hudPing.TextColor3 = Color3_fromRGB(255,60,60) end
                end
                local elapsed = _mfloor(tick() - _Analytics.sessionStart)
                local m = _mfloor(elapsed / 60)
                local s = elapsed % 60
                if uptimeLbl and uptimeLbl.Parent then uptimeLbl.Text = string.format("%02d:%02d", m, s) end
                if farmSuccessLbl and farmSuccessLbl.Parent then
                    farmSuccessLbl.Text = _tostr(_Analytics.farmSuccess)
                    farmFailLbl.Text = _tostr(_Analytics.farmFail)
                    farmEscLbl.Text = _tostr(_Analytics.escapeCount)
                    farmCoinLbl.Text = _tostr(_Analytics.coinsCollected)
                end
                local sLbl = _UIRefs.statusLbl
                local sDot = _UIRefs.statusDot
                local sDotGlow = _UIRefs.statusDotGlow
                if sLbl and sLbl.Parent then
                    local detected = _Analytics.farmFail >= 20
                    local col = detected and Color3_fromRGB(255,60,60) or Color3_fromRGB(0,255,120)
                    sLbl.Text = detected and _T("status_detected") or _T("status_ok")
                    sLbl.TextColor3 = col
                    if sDot and sDot.Parent then sDot.BackgroundColor3 = col end
                    if sDotGlow and sDotGlow.Parent then sDotGlow.Color = col end
                end
            end
        end)
    end
    local function _buildESP()
        _LS(espPage,"sec_player")
        local pGrid1=UI.makeGridContainer(espPage)
        UI.A(espPage,pGrid1)
        UI.makeToggle(pGrid1,"PlayerESP",_T("tog_player_esp"),nil,"tog_player_esp")
        local subN,sllN=UI.makeSubContainer(espPage)
        UI.makeToggle(pGrid1,"ShowNames",_T("tog_show_names"),function(on)
            subN.Visible=on; subN.Size=UDim2_new(1,0,0,on and sllN.AbsoluteContentSize.Y or 0)
        end,"tog_show_names")
        UI.A(espPage,subN)
        UI.makeSliderRow(subN,_T("sl_name_offset"),-10,10,St.NameSettings.OffsetY,function(v) F.applyNameOffset(v) end,Color3_fromRGB(60,130,255),"sl_name_offset")
        UI.makeFontPicker(subN,St.NameSettings.Font,function(f) F.applyNameFont(f) end)
        local pGrid2=UI.makeGridContainer(espPage)
        UI.A(espPage,pGrid2)
        local subD,sllD=UI.makeSubContainer(espPage)
        UI.makeToggle(pGrid2,"ShowDistance",_T("tog_show_dist"),function(on)
            subD.Visible=on; subD.Size=UDim2_new(1,0,0,on and sllD.AbsoluteContentSize.Y or 0)
        end,"tog_show_dist")
        UI.A(espPage,subD)
        UI.makeSliderRow(subD,_T("sl_dist_offset"),-10,10,St.DistSettings.OffsetY,function(v) F.applyDistOffset(v) end,Color3_fromRGB(60,130,255),"sl_dist_offset")
        UI.makeFontPicker(subD,St.DistSettings.Font,function(f) F.applyDistFont(f) end)
        UI.A(espPage,UI.makeDivider(espPage))
        _LS(espPage,"sec_lives")
        local pGrid3=UI.makeGridContainer(espPage)
        UI.A(espPage,pGrid3)
        local subL,sllL=UI.makeSubContainer(espPage)
        UI.makeToggle(pGrid3,"LivesESP",_T("tog_lives_esp"),function(on)
            subL.Visible=on; subL.Size=UDim2_new(1,0,0,on and sllL.AbsoluteContentSize.Y or 0)
            if not on then
                for _,ld in pairs(St.livesData) do
                    if ld.bgui and ld.bgui.Parent then ld.bgui.Enabled=false end
                end
            end
        end,"tog_lives_esp")
        UI.A(espPage,subL)
        UI.makeSliderRow(subL,_T("sl_heart_size"),6,20,St.LivesSettings.HeartSize,function(v) F.applyLivesSize(v) end,Color3_fromRGB(60,130,255),"sl_heart_size")
        UI.makeSliderRow(subL,_T("sl_height"),-12,12,St.LivesSettings.OffsetY,function(v) F.applyLivesOffsetY(v) end,Color3_fromRGB(60,130,255),"sl_height")
        UI.makeSliderRow(subL,_T("sl_tilt"),-10,10,St.LivesSettings.OffsetX,function(v) F.applyLivesOffsetX(v) end,Color3_fromRGB(60,130,255),"sl_tilt")
        UI.A(espPage,UI.makeDivider(espPage))
        _LS(espPage,"sec_world")
        local wGrid=UI.makeGridContainer(espPage)
        UI.A(espPage,wGrid)
        UI.makeToggle(wGrid,"ExitESP",_T("tog_exit_esp"),function() F.updateExitESP() end,"tog_exit_esp")
        local subLt,sllLt=UI.makeSubContainer(espPage)
        UI.makeToggle(wGrid,"LootESP",_T("tog_loot_esp"),function(on)
            subLt.Visible=on; subLt.Size=UDim2_new(1,0,0,on and sllLt.AbsoluteContentSize.Y or 0)
            F.updateLootESP()
        end,"tog_loot_esp")
        UI.A(espPage,subLt)
        UI.makeSliderRow(subLt,_T("sl_min_value"),1,1000,St.MIN_LOOT_VALUE,function(v) St.MIN_LOOT_VALUE=v; F.updateLootESP() end,Color3_fromRGB(60,130,255),"sl_min_value")
        UI.A(espPage,UI.makeDivider(espPage))
        _LS(espPage,"sec_hud")
        local hGrid=UI.makeGridContainer(espPage)
        UI.A(espPage,hGrid)
        UI.makeToggle(hGrid,"ShowCoins",_T("tog_coins_disp"),function(on)
            if CoinsHUD and CoinsHUD.Parent then CoinsHUD.Visible=on end
        end,"tog_coins_disp")
    end
    local function _buildFarm()
        _LS(farmPage,"sec_autofarm")
        local fGrid1=UI.makeGridContainer(farmPage)
        UI.A(farmPage,fGrid1)
        local subF,sllF=UI.makeSubContainer(farmPage)
        UI.makeToggle(fGrid1,"AutoFarmLoot",_T("tog_farm_loot"),function(on)
            subF.Visible=on; subF.Size=UDim2_new(1,0,0,on and sllF.AbsoluteContentSize.Y or 0)
            if on then F.startAutoFarm(); UI.showToast(_T("toast_farm_on"),ScreenGui)
            else St.Fl.autoFarmRunning=false; UI.showToast(_T("toast_farm_off"),ScreenGui) end
        end,"tog_farm_loot")
        if St.Settings.AutoFarmLoot then
            task.defer(function()
                subF.Visible=true; subF.Size=UDim2_new(1,0,0,sllF.AbsoluteContentSize.Y)
            end)
        end
        UI.A(farmPage,subF)
        do
            local function _pctToDelay(pct)
                if pct>=180 then return 0 end
                if pct<=100 then return 3.0-(pct/100)*2.0 end
                return 1.0-((pct-100)/80)*0.95
            end
            St.farmCollectDelay=_pctToDelay(St.farmSpeedPct)
            local spRow=Instance_new("Frame"); spRow.Parent=subF
            spRow.Size=UDim2_new(1,0,0,52); spRow.BackgroundColor3=UI.C.ROW; spRow.BorderSizePixel=0
            UI.registerTheme(spRow,"ROW","BackgroundColor3")
            spRow.BackgroundTransparency=0.4
            local spCrn=Instance_new("UICorner"); spCrn.Parent=spRow; spCrn.CornerRadius=UDim_new(0,8)
            local spTopLbl=Instance_new("TextLabel"); spTopLbl.Parent=spRow
            spTopLbl.Size=UDim2_new(1,-20,0,22); spTopLbl.Position=UDim2_new(0,10,0,2)
            spTopLbl.BackgroundTransparency=1; spTopLbl.TextColor3=Color3_new(1,1,1)
            UI.registerTheme(spTopLbl,"TEXT","TextColor3")
            spTopLbl.Font=Enum.Font.GothamSemibold; spTopLbl.TextSize=10
            spTopLbl.TextXAlignment=Enum.TextXAlignment.Left
            spTopLbl.Text=_T("sl_farm_speed").."  "..St.farmSpeedPct.."%"
            _LR(spTopLbl,"sl_farm_speed")
            local spMinus=Instance_new("TextButton"); spMinus.Parent=spRow
            spMinus.Size=UDim2_new(0,24,0,22); spMinus.Position=UDim2_new(0,6,0,27)
            spMinus.BackgroundColor3=UI.C.OFF; spMinus.Text="-"
            UI.registerTheme(spMinus,"OFF","BackgroundColor3")
            spMinus.TextColor3=Color3_new(1,1,1); spMinus.Font=Enum.Font.GothamBold
            spMinus.TextSize=14; spMinus.BorderSizePixel=0
            local smCrn=Instance_new("UICorner"); smCrn.Parent=spMinus; smCrn.CornerRadius=UDim_new(0,6)
            local spPlus=Instance_new("TextButton"); spPlus.Parent=spRow
            spPlus.Size=UDim2_new(0,24,0,22); spPlus.Position=UDim2_new(1,-30,0,27)
            spPlus.BackgroundColor3=UI.C.OFF; spPlus.Text="+"
            UI.registerTheme(spPlus,"OFF","BackgroundColor3")
            spPlus.TextColor3=Color3_new(1,1,1); spPlus.Font=Enum.Font.GothamBold
            spPlus.TextSize=14; spPlus.BorderSizePixel=0
            local spCrn2=Instance_new("UICorner"); spCrn2.Parent=spPlus; spCrn2.CornerRadius=UDim_new(0,6)
            local spTrack=Instance_new("Frame"); spTrack.Parent=spRow
            spTrack.Size=UDim2_new(1,-68,0,8); spTrack.Position=UDim2_new(0,34,0,33)
            spTrack.BackgroundColor3=UI.C.OFF; spTrack.BorderSizePixel=0
            UI.registerTheme(spTrack,"OFF","BackgroundColor3")
            local stCrn=Instance_new("UICorner"); stCrn.Parent=spTrack; stCrn.CornerRadius=UDim_new(1,0)
            local function _spColor(f)
                local r,g,b
                if f<=0.5 then
                    r=math_floor(255*f*2); g=220; b=60
                else
                    r=255; g=math_floor(220*(1-(f-0.5)*2)); b=60
                end
                return Color3_fromRGB(r,g,b)
            end
            local iF=math.clamp(St.farmSpeedPct/180,0,1)
            local spFill=Instance_new("Frame"); spFill.Parent=spTrack
            spFill.Size=UDim2_new(iF,0,1,0); spFill.BackgroundColor3=_spColor(iF); spFill.BorderSizePixel=0
            local sfCrn=Instance_new("UICorner"); sfCrn.CornerRadius=UDim_new(1,0); sfCrn.Parent=spFill
            local spKn=Instance_new("Frame"); spKn.Parent=spTrack
            spKn.Size=UDim2_new(0,14,0,14); spKn.Position=UDim2_new(iF,-7,0.5,-7)
            spKn.BackgroundColor3=Color3_new(1,1,1); spKn.BorderSizePixel=0
            local skCrn=Instance_new("UICorner"); skCrn.CornerRadius=UDim_new(1,0); skCrn.Parent=spKn
            local ti8=TweenInfo.new(0.08)
            local function applySpeedF(f)
                f=math.clamp(f,0,1)
                local pct=math_floor(f*180)
                St.farmSpeedPct=pct
                St.farmCollectDelay=_pctToDelay(pct)
                spFill.Size=UDim2_new(f,0,1,0); spKn.Position=UDim2_new(f,-7,0.5,-7)
                Sv.TweenService:Create(spFill,ti8,{BackgroundColor3=_spColor(f)}):Play()
                spTopLbl.Text=_T("sl_farm_speed").."  "..pct.."%"
                task.defer(F.saveSettings)
            end
            local spDragId=tostring({})
            St._sliderDrags[spDragId]={apply=applySpeedF,track=spTrack}
            spTrack.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1
                or inp.UserInputType==Enum.UserInputType.Touch then
                    St._sliderDragId=spDragId
                    applySpeedF((inp.Position.X-spTrack.AbsolutePosition.X)/math_max(spTrack.AbsoluteSize.X,1))
                end
            end)
            spMinus.MouseButton1Click:Connect(function()
                applySpeedF(math_max(0,St.farmSpeedPct-1)/180)
            end)
            spPlus.MouseButton1Click:Connect(function()
                applySpeedF(math_min(180,St.farmSpeedPct+1)/180)
            end)
            spRow.AncestryChanged:Connect(function() if not spRow.Parent then St._sliderDrags[spDragId]=nil end end)
            UI.applyHover(spMinus,"OFF","DIV")
            UI.applyHover(spPlus,"OFF","DIV")
        end
        UI.A(farmPage,UI.makeDivider(farmPage))
        _LS(farmPage,"sec_revive")
        local rGrid=UI.makeGridContainer(farmPage)
        UI.A(farmPage,rGrid)
        UI.makeToggle(rGrid,"AutoRevive",_T("tog_auto_revive"),function(on)
            if on then
                F.startAutoRevive()
                if St.Settings.KillerSafety and not St.Cn.killerSafety then F.startKillerSafety() end
            else F.stopAutoRevive() end
        end,"tog_auto_revive")
        UI.makeToggle(rGrid,"AutoSelfRevive",_T("tog_self_revive"),function(on)
            if on then F.startAutoSelfRevive() else F.stopAutoSelfRevive() end
        end,"tog_self_revive")
        UI.A(farmPage,UI.makeWideBtn(farmPage,"Revive My Self  GO",F.reviveMySelf))
        UI.A(farmPage,UI.makeDivider(farmPage))
        _LS(farmPage,"sec_safety")
        local sGrid=UI.makeGridContainer(farmPage)
        UI.A(farmPage,sGrid)
        UI.makeToggle(sGrid,"KillerSafety",_T("tog_killer_safe"),function(on)
            if on then F.startKillerSafety() else F.stopKillerSafety() end
        end,"tog_killer_safe")
        local subS,sllS=UI.makeSubContainer(farmPage)
        UI.makeSliderRow(subS,_T("sl_safety_dist"),0,150,St.Fl.killerSafetyDist,function(v) St.Fl.killerSafetyDist=v end,nil,"sl_safety_dist")
        subS.Visible=true; subS.Size=UDim2_new(1,0,0,sllS.AbsoluteContentSize.Y)
        UI.A(farmPage,subS)
        local eGrid=UI.makeGridContainer(farmPage)
        UI.A(farmPage,eGrid)
        UI.makeToggle(eGrid,"AutoEscape",_T("tog_auto_escape"),function(on)
            if on then F.startAutoEscape() else F.stopAutoEscape() end
        end,"tog_auto_escape")
        UI.A(farmPage,UI.makeWideBtn(farmPage,"Teleport to Exit  GO",F.teleportToNearestExit))
        UI.A(farmPage,UI.makeWideBtn(farmPage,"Random Survivor  TP",F.teleportToRandomSurvivor))
        UI.A(farmPage,UI.makeDivider(farmPage))
        _LS(farmPage,"sec_killer",true)
        local kGrid=UI.makeGridContainer(farmPage)
        UI.A(farmPage,kGrid)
        UI.makeToggle(kGrid,"_killAll",_T("tog_kill_all"),function(on)
            if on then F.startKillAll() else F.stopKillAll() end
        end,"tog_kill_all")
        local subH,sllH=UI.makeSubContainer(farmPage)
        UI.makeToggle(kGrid,"Hitbox",_T("tog_hitbox"),function(on)
            subH.Visible=on; subH.Size=UDim2_new(1,0,0,on and sllH.AbsoluteContentSize.Y or 0)
            if on then F.startHitbox() else F.stopHitbox() end
        end,"tog_hitbox")
        if St.Settings.Hitbox then task.defer(function() subH.Visible=true; subH.Size=UDim2_new(1,0,0,sllH.AbsoluteContentSize.Y) end) end
        UI.A(farmPage,subH)
        UI.makeSliderRow(subH,_T("sl_hitbox_dist"),5,50,St.Fl.hitboxRadius,function(v) St.Fl.hitboxRadius=v end,nil,"sl_hitbox_dist")
    end
    local function _buildSettings()
        do
            local langRow=Instance_new("Frame"); langRow.Parent=settPage
            langRow.Size=UDim2_new(1,0,0,56); langRow.BackgroundColor3=UI.C.ROW
            UI.registerTheme(langRow,"ROW","BackgroundColor3")
            langRow.BackgroundTransparency=0.5; langRow.BorderSizePixel=0
            local lrCrn=Instance_new("UICorner"); lrCrn.Parent=langRow; lrCrn.CornerRadius=UDim_new(0,8)
            local lrStr=Instance_new("UIStroke"); lrStr.Parent=langRow; lrStr.Thickness=0.8
            local lrGrad=Instance_new("UIGradient"); lrGrad.Parent=lrStr
            lrGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3_fromRGB(255,255,255)),ColorSequenceKeypoint.new(0.5,Color3_fromRGB(180,200,255)),ColorSequenceKeypoint.new(1,Color3_fromRGB(255,255,255))})
            lrGrad.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.85),NumberSequenceKeypoint.new(0.5,0.3),NumberSequenceKeypoint.new(1,0.85)})
            lrGrad.Rotation=90
            local lrLbl=Instance_new("TextLabel"); lrLbl.Parent=langRow
            lrLbl.Size=UDim2_new(1,-160,1,0); lrLbl.Position=UDim2_new(0,10,0,0)
            lrLbl.BackgroundTransparency=1; lrLbl.TextColor3=Color3_new(1,1,1)
            UI.registerTheme(lrLbl,"TEXT","TextColor3")
            lrLbl.Font=Enum.Font.GothamSemibold; lrLbl.TextSize=10
            lrLbl.TextXAlignment=Enum.TextXAlignment.Left
            _LR(lrLbl,"lang_toggle")
            local enContainer=Instance_new("Frame"); enContainer.Parent=langRow
            enContainer.Size=UDim2_new(0,62,0,42); enContainer.Position=UDim2_new(1,-137,0.5,-21)
            enContainer.BackgroundTransparency=1; enContainer.BorderSizePixel=0
            local enBorder=Instance_new("Frame"); enBorder.Parent=enContainer
            enBorder.Size=UDim2_new(1,0,1,0); enBorder.BackgroundColor3=UI.C.ACCENT; enBorder.BorderSizePixel=0
            UI.registerTheme(enBorder,"ACCENT","BackgroundColor3")
            local enBCrn=Instance_new("UICorner"); enBCrn.Parent=enBorder; enBCrn.CornerRadius=UDim_new(0,7)
            local enBtn=Instance_new("TextButton"); enBtn.Parent=enContainer
            enBtn.Size=UDim2_new(1,-2,1,-2); enBtn.Position=UDim2_new(0,1,0,1)
            enBtn.BackgroundColor3=UI.C.OFF; enBtn.Text=""; enBtn.BorderSizePixel=0
            UI.registerTheme(enBtn,"OFF","BackgroundColor3")
            local enCrn=Instance_new("UICorner"); enCrn.Parent=enBtn; enCrn.CornerRadius=UDim_new(0,6)
            local enImg=Instance_new("ImageLabel"); enImg.Parent=enBtn
            enImg.Size=UDim2_new(0,20,0,14); enImg.Position=UDim2_new(0.5,-10,0,6)
            enImg.BackgroundTransparency=1; enImg.ScaleType=Enum.ScaleType.Fit
            setPrivateImage(enImg,"English.jpg")
            local enTxt=Instance_new("TextLabel"); enTxt.Parent=enBtn
            enTxt.Size=UDim2_new(1,0,0,14); enTxt.Position=UDim2_new(0,0,0,22)
            enTxt.BackgroundTransparency=1; enTxt.Text="English"
            enTxt.TextColor3=Color3_new(1,1,1); enTxt.Font=Enum.Font.GothamBold; enTxt.TextSize=9
            enTxt.TextXAlignment=Enum.TextXAlignment.Center
            local ruContainer=Instance_new("Frame"); ruContainer.Parent=langRow
            ruContainer.Size=UDim2_new(0,62,0,42); ruContainer.Position=UDim2_new(1,-69,0.5,-21)
            ruContainer.BackgroundTransparency=1; ruContainer.BorderSizePixel=0
            local ruBorder=Instance_new("Frame"); ruBorder.Parent=ruContainer
            ruBorder.Size=UDim2_new(1,0,1,0); ruBorder.BackgroundColor3=UI.C.ACCENT; ruBorder.BorderSizePixel=0
            UI.registerTheme(ruBorder,"ACCENT","BackgroundColor3")
            local ruBCrn=Instance_new("UICorner"); ruBCrn.Parent=ruBorder; ruBCrn.CornerRadius=UDim_new(0,7)
            local ruBtn=Instance_new("TextButton"); ruBtn.Parent=ruContainer
            ruBtn.Size=UDim2_new(1,-2,1,-2); ruBtn.Position=UDim2_new(0,1,0,1)
            ruBtn.BackgroundColor3=UI.C.OFF; ruBtn.Text=""; ruBtn.BorderSizePixel=0
            UI.registerTheme(ruBtn,"OFF","BackgroundColor3")
            local ruCrn=Instance_new("UICorner"); ruCrn.Parent=ruBtn; ruCrn.CornerRadius=UDim_new(0,6)
            local ruImg=Instance_new("ImageLabel"); ruImg.Parent=ruBtn
            ruImg.Size=UDim2_new(0,20,0,14); ruImg.Position=UDim2_new(0.5,-10,0,6)
            ruImg.BackgroundTransparency=1; ruImg.ScaleType=Enum.ScaleType.Fit
            setPrivateImage(ruImg,"Russian.jpg")
            local ruTxt=Instance_new("TextLabel"); ruTxt.Parent=ruBtn
            ruTxt.Size=UDim2_new(1,0,0,14); ruTxt.Position=UDim2_new(0,0,0,22)
            ruTxt.BackgroundTransparency=1; ruTxt.Text="Russian"
            ruTxt.TextColor3=Color3_new(1,1,1); ruTxt.Font=Enum.Font.GothamBold; ruTxt.TextSize=9
            ruTxt.TextXAlignment=Enum.TextXAlignment.Center
            local function _updateLangBtns()
                enBorder.Visible=(St.Language=="EN")
                ruBorder.Visible=(St.Language=="RU")
            end
            _updateLangBtns()
            enBtn.MouseButton1Click:Connect(function()
                St.Language="EN"; _applyLang(); _updateLangBtns(); task.defer(F.saveSettings)
            end)
            ruBtn.MouseButton1Click:Connect(function()
                St.Language="RU"; _applyLang(); _updateLangBtns(); task.defer(F.saveSettings)
            end)
            St.UIRefs._updateLangBtns=_updateLangBtns
            UI.A(settPage,langRow)
        end
        UI.A(settPage,UI.makeDivider(settPage))
        _LS(settPage,"theme_lbl")
        do
            local thRow=Instance_new("Frame"); thRow.Parent=settPage
            thRow.Size=UDim2_new(1,0,0,38); thRow.BackgroundColor3=UI.C.ROW; thRow.BorderSizePixel=0
            UI.registerTheme(thRow,"ROW","BackgroundColor3")
            thRow.BackgroundTransparency=0.4
            local thCrn=Instance_new("UICorner"); thCrn.Parent=thRow; thCrn.CornerRadius=UDim_new(0,7)
            local thLbl=Instance_new("TextLabel"); thLbl.Parent=thRow
            thLbl.Size=UDim2_new(0,80,1,0); thLbl.Position=UDim2_new(0,7,0,0)
            thLbl.BackgroundTransparency=1; thLbl.TextColor3=UI.C.SUBTEXT
            UI.registerTheme(thLbl,"SUBTEXT","TextColor3")
            thLbl.Font=Enum.Font.GothamBold; thLbl.TextSize=8; thLbl.Text="COLOR"
            thLbl.TextXAlignment=Enum.TextXAlignment.Left
            local tTrack=Instance_new("Frame"); tTrack.Parent=thRow
            tTrack.Size=UDim2_new(1,-100,0,12); tTrack.Position=UDim2_new(0,86,0.5,-6)
            tTrack.BackgroundColor3=Color3_new(1,1,1); tTrack.BorderSizePixel=0
            local tTCrn=Instance_new("UICorner"); tTCrn.Parent=tTrack; tTCrn.CornerRadius=UDim_new(1,0)
            local tGrad=Instance_new("UIGradient"); tGrad.Parent=tTrack
            local colors={}
            for i=0,14 do table.insert(colors,ColorSequenceKeypoint.new(i/14,Color3.fromHSV(i/14,0.75,0.95))) end
            tGrad.Color=ColorSequence.new(colors)
            local tKnob=Instance_new("Frame"); tKnob.Parent=tTrack
            tKnob.Size=UDim2_new(0,16,0,16); tKnob.Position=UDim2_new(St.Settings.ThemeHue,-8,0.5,-8)
            tKnob.BackgroundColor3=Color3_new(1,1,1); tKnob.BorderSizePixel=0
            local tKCrn=Instance_new("UICorner"); tKCrn.Parent=tKnob; tKCrn.CornerRadius=UDim_new(1,0)
            local tKStr=Instance_new("UIStroke"); tKStr.Parent=tKnob
            tKStr.Color=Color3_new(0,0,0); tKStr.Thickness=1; tKStr.Transparency=0.5
            local dragId=tostring({})
            local function applyHue(f)
                f=math.clamp(f,0,1)
                tKnob.Position=UDim2_new(f,-8,0.5,-8)
                F.applyTheme(f)
            end
            tKnob.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                    St._sliderDrags[dragId]={track=tTrack,apply=applyHue}; St._sliderDragId=dragId
                end
            end)
            tTrack.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                    local abs=tTrack.AbsoluteSize.X; if abs==0 then return end
                    applyHue((inp.Position.X-tTrack.AbsolutePosition.X)/abs)
                    St._sliderDrags[dragId]={track=tTrack,apply=applyHue}; St._sliderDragId=dragId
                end
            end)
            UI.A(settPage,thRow)
        end
        UI.A(settPage,UI.makeDivider(settPage))
        _LS(settPage,"sec_movement")
        local mGrid=UI.makeGridContainer(settPage)
        UI.A(settPage,mGrid)
        UI.makeToggle(mGrid,"DoubleJump",_T("tog_double_jump"),function(on) if on then F.setupDoubleJump() end end,"tog_double_jump")
        UI.makeToggle(mGrid,"InfiniteJump",_T("tog_inf_jump"),function(on) if on then F.startInfiniteJump() else F.stopInfiniteJump() end end,"tog_inf_jump")
        UI.makeToggle(mGrid,"Noclip",_T("tog_noclip"),function(on) if on then F.startNoclip() else F.stopNoclip() end end,"tog_noclip")
        UI.makeToggle(mGrid,"GhostMode",_T("tog_ghost_mode"),function(on) F.toggleGhostMode(on) end,"tog_ghost_mode")
        local subFly,sllFly=UI.makeSubContainer(settPage)
        UI.makeToggle(mGrid,"FlyEnabled",_T("tog_fly"),function(on)
            subFly.Visible=on; subFly.Size=UDim2_new(1,0,0,on and sllFly.AbsoluteContentSize.Y or 0)
            if on then F.startFly() else F.stopFly() end
        end,"tog_fly")
        UI.A(settPage,subFly)
        UI.makeSliderRow(subFly,_T("sl_fly_speed"),10,300,St.Fl.flySpeed,function(v) St.Fl.flySpeed=v end,nil,"sl_fly_speed")
        UI.A(settPage,UI.makeDivider(settPage))
        _LS(settPage,"sec_speed")
        local spGrid=UI.makeGridContainer(settPage)
        UI.A(settPage,spGrid)
        local subSp,sllSp=UI.makeSubContainer(settPage)
        UI.makeToggle(spGrid,"SpeedEnabled",_T("tog_speed_boost"),function(on)
            subSp.Visible=on; subSp.Size=UDim2_new(1,0,0,on and sllSp.AbsoluteContentSize.Y or 0)
            local ch=Sv.LocalPlayer.Character
            local hu=ch and ch:FindFirstChildOfClass("Humanoid")
            if hu then hu.WalkSpeed=on and St.Fl.currentSpeed or 16 end
            if on then
                if St.Cn.speed then St.Cn.speed:Disconnect() end
                local _spChar,_spHum=nil,nil
                St.Cn.speed=Sv.RunService.Heartbeat:Connect(function()
                    if not St.Settings.SpeedEnabled then return end
                    local c=Sv.LocalPlayer.Character
                    if c~=_spChar then _spChar=c; _spHum=c and c:FindFirstChildOfClass("Humanoid") end
                    if _spHum and _spHum.WalkSpeed~=St.Fl.currentSpeed then _spHum.WalkSpeed=St.Fl.currentSpeed end
                end)
            else
                if St.Cn.speed then St.Cn.speed:Disconnect(); St.Cn.speed=nil end
                local c=Sv.LocalPlayer.Character
                local h=c and c:FindFirstChildOfClass("Humanoid")
                if h then h.WalkSpeed=16 end
            end
        end,"tog_speed_boost")
        UI.A(settPage,subSp)
        UI.makeSliderRow(subSp,_T("sl_speed"),1,300,St.Fl.currentSpeed,function(v)
            St.Fl.currentSpeed=v
            if St.Settings.SpeedEnabled then
                local ch=Sv.LocalPlayer.Character
                local hu=ch and ch:FindFirstChildOfClass("Humanoid")
                if hu then hu.WalkSpeed=St.Fl.currentSpeed end
            end
        end,nil,"sl_speed")
        UI.A(settPage,UI.makeDivider(settPage))
        _LS(settPage,"sec_visuals")
        local vGrid=UI.makeGridContainer(settPage)
        UI.A(settPage,vGrid)
        UI.makeToggle(vGrid,"RemoveFog",_T("tog_remove_fog"),function(on) if on then F.enableFogRemoval() else F.disableFogRemoval() end end,"tog_remove_fog")
        UI.makeToggle(vGrid,"SnowAnimation",_T("tog_snow_anim"),function(on) if on then F.applySnowAnims(Sv.LocalPlayer.Character) else F.stopSnowAnimation() end end,"tog_snow_anim")
        UI.A(settPage,UI.makeDivider(settPage))
        _LS(settPage,"sec_utility")
        local uGrid=UI.makeGridContainer(settPage)
        UI.A(settPage,uGrid)
        UI.makeToggle(uGrid,"AntiAFK",_T("tog_anti_afk"),function(on) if on then F.startAntiAFK() else F.stopAntiAFK() end end,"tog_anti_afk")
        UI.makeToggle(uGrid,"AntiVoid",_T("tog_anti_void"),nil,"tog_anti_void")
        UI.A(settPage,UI.makeDivider(settPage))
        _LS(settPage,"sec_links")
        _LS(settPage,"sec_fpsboost")
        do
            local fpsGrid=UI.makeGridContainer(settPage)
            UI.A(settPage,fpsGrid)
            UI.makeToggle(fpsGrid,"FpsBoost",_T("tog_fps_boost"),function(on)
                if on then F.startFpsBoost() else F.stopFpsBoost() end
            end,"tog_fps_boost")
            UI.makeToggle(fpsGrid,"ShowAds",_T("tog_ads"),nil,"tog_ads")
        end
        do
            local TG_LINK="https://t.me/JohnyX_STK"
            local tgRow=Instance_new("Frame"); tgRow.Parent=settPage
            tgRow.Size=UDim2_new(1,0,0,36); tgRow.BackgroundColor3=UI.C.ROW; tgRow.BorderSizePixel=0
            UI.registerTheme(tgRow,"ROW","BackgroundColor3")
            tgRow.BackgroundTransparency=0.4
            local trCrn=Instance_new("UICorner"); trCrn.Parent=tgRow; trCrn.CornerRadius=UDim_new(0,7)
            local tgImg=Instance_new("ImageLabel"); tgImg.Parent=tgRow
            tgImg.Size=UDim2_new(0,26,0,26); tgImg.Position=UDim2_new(0,5,0.5,-13)
            tgImg.BackgroundTransparency=1; tgImg.ScaleType=Enum.ScaleType.Fit
            local tiCrn=Instance_new("UICorner"); tiCrn.Parent=tgImg; tiCrn.CornerRadius=UDim_new(1,0)
            setPrivateImage(tgImg,"Telegram.png")
            local tgLbl=Instance_new("TextLabel"); tgLbl.Parent=tgRow
            tgLbl.Size=UDim2_new(1,-112,1,0); tgLbl.Position=UDim2_new(0,38,0,0)
            tgLbl.BackgroundTransparency=1; tgLbl.Text="JohnyX Channel"
            tgLbl.TextColor3=Color3_new(1,1,1); tgLbl.Font=Enum.Font.GothamSemibold
            UI.registerTheme(tgLbl,"TEXT","TextColor3")
            tgLbl.TextSize=10; tgLbl.TextXAlignment=Enum.TextXAlignment.Left
            local tgBtn=Instance_new("TextButton"); tgBtn.Parent=tgRow
            tgBtn.Size=UDim2_new(0,64,0,22); tgBtn.Position=UDim2_new(1,-70,0.5,-11)
            tgBtn.BackgroundColor3=Color3_fromRGB(0,118,190); tgBtn.Text=" COPY"
            tgBtn.TextColor3=Color3_new(1,1,1); tgBtn.Font=Enum.Font.GothamBold
            tgBtn.TextSize=9; tgBtn.BorderSizePixel=0
            local tbCrn=Instance_new("UICorner"); tbCrn.Parent=tgBtn; tbCrn.CornerRadius=UDim_new(0,5)
            tgBtn.MouseButton1Click:Connect(function()
                pcall(function() setclipboard(TG_LINK) end)
                UI.showToast("  Link copied!",ScreenGui)
            end)
            UI.A(settPage,tgRow)
        end
        UI.A(settPage,UI.makeDivider(settPage))
        _LS(settPage,"server_tools")
        UI.A(settPage,UI.makeActionRow(settPage,_T("rejoin_lbl"),_T("rejoin_btn"),"ACCENT",function()
            local ui=Sv.CoreGui:FindFirstChild("JxH_UI") or Sv.LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("JxH_UI")
            if ui then UI.showToast(_T("toast_rejoin"),ui) end
            F.rejoinServer()
        end))
        UI.A(settPage,UI.makeActionRow(settPage,_T("hop_lbl"),_T("hop_btn"),"ACCENT",function()
            local ui=Sv.CoreGui:FindFirstChild("JxH_UI") or Sv.LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("JxH_UI")
            if ui then UI.showToast(_T("toast_hop"),ui) end
            F.serverHop()
        end))
        UI.A(settPage,UI.makeDivider(settPage))
        _LS(settPage,"sec_transparency")
        do
            local transRow=Instance_new("Frame"); transRow.Parent=settPage
            transRow.Size=UDim2_new(1,0,0,38); transRow.BackgroundColor3=UI.C.ROW; transRow.BorderSizePixel=0
            UI.registerTheme(transRow,"ROW","BackgroundColor3")
            transRow.BackgroundTransparency=0.4
            local trCrn2=Instance_new("UICorner"); trCrn2.Parent=transRow; trCrn2.CornerRadius=UDim_new(0,7)
            local tLblT=Instance_new("TextLabel"); tLblT.Parent=transRow
            tLblT.Size=UDim2_new(0,80,0,16); tLblT.Position=UDim2_new(0,7,0,3)
            tLblT.BackgroundTransparency=1; tLblT.TextColor3=UI.C.SUBTEXT
            UI.registerTheme(tLblT,"SUBTEXT","TextColor3")
            tLblT.Font=Enum.Font.GothamBold; tLblT.TextSize=8; tLblT.Text="TRANSPARENCY"
            tLblT.TextXAlignment=Enum.TextXAlignment.Left
            local tValT=Instance_new("TextLabel"); tValT.Parent=transRow
            tValT.Size=UDim2_new(0,30,0,16); tValT.Position=UDim2_new(1,-34,0,3)
            tValT.BackgroundTransparency=1; tValT.TextColor3=Color3_new(1,1,1)
            UI.registerTheme(tValT,"TEXT","TextColor3")
            tValT.Font=Enum.Font.GothamBold; tValT.TextSize=8; tValT.TextXAlignment=Enum.TextXAlignment.Right
            tValT.Text=tostring(math_floor(St.Fl.bgTransparency*100)).."%"
            local tTrack=Instance_new("Frame"); tTrack.Parent=transRow
            tTrack.Size=UDim2_new(1,-16,0,6); tTrack.Position=UDim2_new(0,8,0,26)
            tTrack.BackgroundColor3=UI.C.OFF; tTrack.BorderSizePixel=0
            UI.registerTheme(tTrack,"OFF","BackgroundColor3")
            local tTCrn=Instance_new("UICorner"); tTCrn.Parent=tTrack; tTCrn.CornerRadius=UDim_new(1,0)
            local MIN_T,MAX_T=0.0,1.0
            local iF=math_max(0,math_min(1,(St.Fl.bgTransparency-MIN_T)/(MAX_T-MIN_T)))
            local tFill=Instance_new("Frame"); tFill.Parent=tTrack
            tFill.Size=UDim2_new(iF,0,1,0); tFill.BackgroundColor3=UI.C.ACCENT; tFill.BorderSizePixel=0
            UI.registerTheme(tFill,"ACCENT","BackgroundColor3")
            local tFCrn=Instance_new("UICorner"); tFCrn.Parent=tFill; tFCrn.CornerRadius=UDim_new(1,0)
            local tKnob=Instance_new("Frame"); tKnob.Parent=tTrack
            tKnob.Size=UDim2_new(0,13,0,13); tKnob.Position=UDim2_new(iF,-6,0.5,-6)
            tKnob.BackgroundColor3=Color3_new(1,1,1); tKnob.BorderSizePixel=0
            local tKCrn=Instance_new("UICorner"); tKCrn.Parent=tKnob; tKCrn.CornerRadius=UDim_new(1,0)
            local dragId=tostring({})
            local function applyTrans(f)
                f=math_max(0,math_min(1,f))
                local sv=MIN_T+(MAX_T-MIN_T)*f
                St.Fl.bgTransparency=sv
                tFill.Size=UDim2_new(f,0,1,0); tKnob.Position=UDim2_new(f,-6,0.5,-6)
                tValT.Text=tostring(math_floor(sv*100)).."%"
                if MainFrame and MainFrame.Visible then MainFrame.BackgroundTransparency=sv end
                if Sidebar then Sidebar.BackgroundTransparency=sv end
                if ContentArea then ContentArea.BackgroundTransparency=sv end
                task.defer(F.saveSettings)
            end
            tKnob.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                    St._sliderDrags[dragId]={track=tTrack,apply=applyTrans}; St._sliderDragId=dragId
                end
            end)
            tTrack.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                    local abs=tTrack.AbsoluteSize.X; if abs==0 then return end
                    applyTrans((inp.Position.X-tTrack.AbsolutePosition.X)/abs)
                    St._sliderDrags[dragId]={track=tTrack,apply=applyTrans}; St._sliderDragId=dragId
                end
            end)
            UI.A(settPage,transRow)
        end
        UI.A(settPage,UI.makeDivider(settPage))
        _LS(settPage,"sec_uisize")
        do
            local scaleRow=Instance_new("Frame"); scaleRow.Parent=settPage
            scaleRow.Size=UDim2_new(1,0,0,38); scaleRow.BackgroundColor3=UI.C.ROW; scaleRow.BorderSizePixel=0
            UI.registerTheme(scaleRow,"ROW","BackgroundColor3")
            scaleRow.BackgroundTransparency=0.4
            local srCrn2=Instance_new("UICorner"); srCrn2.Parent=scaleRow; srCrn2.CornerRadius=UDim_new(0,7)
            local sLblT=Instance_new("TextLabel"); sLblT.Parent=scaleRow
            sLblT.Size=UDim2_new(0,38,0,16); sLblT.Position=UDim2_new(0,7,0,3)
            sLblT.BackgroundTransparency=1; sLblT.TextColor3=UI.C.SUBTEXT
            UI.registerTheme(sLblT,"SUBTEXT","TextColor3")
            sLblT.Font=Enum.Font.GothamBold; sLblT.TextSize=8; sLblT.Text="SCALE"
            sLblT.TextXAlignment=Enum.TextXAlignment.Left
            local sValT=Instance_new("TextLabel"); sValT.Parent=scaleRow
            sValT.Size=UDim2_new(0,30,0,16); sValT.Position=UDim2_new(1,-34,0,3)
            sValT.BackgroundTransparency=1; sValT.TextColor3=Color3_new(1,1,1)
            UI.registerTheme(sValT,"TEXT","TextColor3")
            sValT.Font=Enum.Font.GothamBold; sValT.TextSize=8; sValT.TextXAlignment=Enum.TextXAlignment.Right
            sValT.Text=tostring(math_floor(St.Fl.uiScale*100)).."%"
            local scTrack=Instance_new("Frame"); scTrack.Parent=scaleRow
            scTrack.Size=UDim2_new(1,-16,0,6); scTrack.Position=UDim2_new(0,8,0,26)
            scTrack.BackgroundColor3=UI.C.OFF; scTrack.BorderSizePixel=0
            UI.registerTheme(scTrack,"OFF","BackgroundColor3")
            local scTCrn=Instance_new("UICorner"); scTCrn.Parent=scTrack; scTCrn.CornerRadius=UDim_new(1,0)
            local MIN_S,MAX_S=0.7,1.4
            local iF=math_max(0,math_min(1,(St.Fl.uiScale-MIN_S)/(MAX_S-MIN_S)))
            local scFill=Instance_new("Frame"); scFill.Parent=scTrack
            scFill.Size=UDim2_new(iF,0,1,0); scFill.BackgroundColor3=UI.C.ACCENT; scFill.BorderSizePixel=0
            UI.registerTheme(scFill,"ACCENT","BackgroundColor3")
            local scFCrn=Instance_new("UICorner"); scFCrn.Parent=scFill; scFCrn.CornerRadius=UDim_new(1,0)
            local scKnob=Instance_new("Frame"); scKnob.Parent=scTrack
            scKnob.Size=UDim2_new(0,13,0,13); scKnob.Position=UDim2_new(iF,-6,0.5,-6)
            scKnob.BackgroundColor3=Color3_new(1,1,1); scKnob.BorderSizePixel=0
            local scKCrn=Instance_new("UICorner"); scKCrn.Parent=scKnob; scKCrn.CornerRadius=UDim_new(1,0)
            local uiScaleObj=Instance_new("UIScale"); uiScaleObj.Parent=MainFrame; uiScaleObj.Scale=St.Fl.uiScale
            local function applyScale(f)
                f=math_max(0,math_min(1,f))
                local sv=MIN_S+(MAX_S-MIN_S)*f
                St.Fl.uiScale=sv; uiScaleObj.Scale=sv
                scFill.Size=UDim2_new(f,0,1,0); scKnob.Position=UDim2_new(f,-6,0.5,-6)
                sValT.Text=tostring(math_floor(sv*100)).."%"
            end
            local dragId=tostring({})
            scKnob.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                    St._sliderDrags[dragId]={track=scTrack,apply=applyScale}; St._sliderDragId=dragId
                end
            end)
            scTrack.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                    local abs=scTrack.AbsoluteSize.X; if abs==0 then return end
                    applyScale((inp.Position.X-scTrack.AbsolutePosition.X)/abs)
                    St._sliderDrags[dragId]={track=scTrack,apply=applyScale}; St._sliderDragId=dragId
                end
            end)
            UI.A(settPage,scaleRow)
        end
        _LS(settPage,"sec_winsize")
        do
            local winRow=Instance_new("Frame"); winRow.Parent=settPage
            winRow.Size=UDim2_new(1,0,0,38); winRow.BackgroundColor3=UI.C.ROW; winRow.BorderSizePixel=0
            UI.registerTheme(winRow,"ROW","BackgroundColor3")
            winRow.BackgroundTransparency=0.4
            local wrCrn=Instance_new("UICorner"); wrCrn.Parent=winRow; wrCrn.CornerRadius=UDim_new(0,7)
            local wLblT=Instance_new("TextLabel"); wLblT.Parent=winRow
            wLblT.Size=UDim2_new(0,60,0,16); wLblT.Position=UDim2_new(0,7,0,3)
            wLblT.BackgroundTransparency=1; wLblT.TextColor3=UI.C.SUBTEXT
            UI.registerTheme(wLblT,"SUBTEXT","TextColor3")
            wLblT.Font=Enum.Font.GothamBold; wLblT.TextSize=8; wLblT.Text="WIN SIZE"
            wLblT.TextXAlignment=Enum.TextXAlignment.Left
            local wValT=Instance_new("TextLabel"); wValT.Parent=winRow
            wValT.Size=UDim2_new(0,30,0,16); wValT.Position=UDim2_new(1,-34,0,3)
            wValT.BackgroundTransparency=1; wValT.TextColor3=Color3_new(1,1,1)
            UI.registerTheme(wValT,"TEXT","TextColor3")
            wValT.Font=Enum.Font.GothamBold; wValT.TextSize=8; wValT.TextXAlignment=Enum.TextXAlignment.Right
            wValT.Text=tostring(math_floor(St.Fl.winSize*100)).."%"
            local wTrack=Instance_new("Frame"); wTrack.Parent=winRow
            wTrack.Size=UDim2_new(1,-16,0,6); wTrack.Position=UDim2_new(0,8,0,26)
            wTrack.BackgroundColor3=UI.C.OFF; wTrack.BorderSizePixel=0
            UI.registerTheme(wTrack,"OFF","BackgroundColor3")
            local wTCrn=Instance_new("UICorner"); wTCrn.Parent=wTrack; wTCrn.CornerRadius=UDim_new(1,0)
            local MIN_W,MAX_W=0.75,1.35
            local iF=math_max(0,math_min(1,(St.Fl.winSize-MIN_W)/(MAX_W-MIN_W)))
            local wFill=Instance_new("Frame"); wFill.Parent=wTrack
            wFill.Size=UDim2_new(iF,0,1,0); wFill.BackgroundColor3=UI.C.ACCENT; wFill.BorderSizePixel=0
            UI.registerTheme(wFill,"ACCENT","BackgroundColor3")
            local wFCrn=Instance_new("UICorner"); wFCrn.Parent=wFill; wFCrn.CornerRadius=UDim_new(1,0)
            local wKnob=Instance_new("Frame"); wKnob.Parent=wTrack
            wKnob.Size=UDim2_new(0,13,0,13); wKnob.Position=UDim2_new(iF,-6,0.5,-6)
            wKnob.BackgroundColor3=Color3_new(1,1,1); wKnob.BorderSizePixel=0
            local wKCrn=Instance_new("UICorner"); wKCrn.Parent=wKnob; wKCrn.CornerRadius=UDim_new(1,0)
            local dragId=tostring({})
            local function applyWinSize(f)
                f=math_max(0,math_min(1,f))
                local sv=MIN_W+(MAX_W-MIN_W)*f
                St.Fl.winSize=sv
                wFill.Size=UDim2_new(f,0,1,0); wKnob.Position=UDim2_new(f,-6,0.5,-6)
                wValT.Text=tostring(math_floor(sv*100)).."%"
                if St.UIRefs.baseW and St.UIRefs.baseH and MainFrame then
                    MainFrame.Size=UDim2_new(0,math_floor(St.UIRefs.baseW*sv),0,math_floor(St.UIRefs.baseH*sv))
                end
                task.defer(F.saveSettings)
            end
            wKnob.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                    St._sliderDrags[dragId]={track=wTrack,apply=applyWinSize}; St._sliderDragId=dragId
                end
            end)
            wTrack.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                    local abs=wTrack.AbsoluteSize.X; if abs==0 then return end
                    applyWinSize((inp.Position.X-wTrack.AbsolutePosition.X)/abs)
                    St._sliderDrags[dragId]={track=wTrack,apply=applyWinSize}; St._sliderDragId=dragId
                end
            end)
            UI.A(settPage,winRow)
        end
    end
    _buildHome(); task.wait()
    _buildESP(); task.wait()
    _buildFarm(); task.wait()
    _buildSettings()
    selectTab("home")
    F.applyTheme(St.Settings.ThemeHue)
    task.delay(0.5,function() if St.Settings.ShowAds then UI.showToast(_T("toast_started"),ScreenGui) end end)
    task.defer(function()
        St.UIRefs.baseW=MainFrame.AbsoluteSize.X
        St.UIRefs.baseH=MainFrame.AbsoluteSize.Y
        if St.Fl.winSize~=1.0 then
            MainFrame.Size=UDim2_new(0,math_floor(St.UIRefs.baseW*St.Fl.winSize),0,math_floor(St.UIRefs.baseH*St.Fl.winSize))
        end
    end)
    do
        local dragging=false
        local dragStart,startPos,hasDragged,dragInput=nil,nil,false,nil
        MainBtn.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                dragging=true
                hasDragged=false
                dragInput=input
                dragStart=input.Position
                local ap=MainBtn.AbsolutePosition
                startPos=UDim2_new(0,ap.X,0,ap.Y)
            end
        end)
        Sv.UserInputService.InputEnded:Connect(function(input)
            if input==dragInput then
                dragging=false
                dragInput=nil
            end
        end)
        Sv.UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end
            local delta=input.Position-dragStart
            if delta.Magnitude>5 then hasDragged=true end
            local vp=workspace.CurrentCamera.ViewportSize
            local sz=MainBtn.AbsoluteSize
            local newX=math.clamp(startPos.X.Offset+delta.X,0,vp.X-sz.X)
            local newY=math.clamp(startPos.Y.Offset+delta.Y,0,vp.Y-sz.Y)
            MainBtn.Position=UDim2_new(0,newX,0,newY)
        end)
        MainBtn.MouseButton1Click:Connect(function()
            if not hasDragged then
                if MainFrame.Visible then closeMenu() else openMenu() end
            end
        end)
    end
    task.delay(0,function()
        for sName,cb in pairs(St.toggleCbs) do
            if cb and St.Settings[sName] then
                pcall(cb,true)
            end
        end
    end)

local function showChangelog(parentGui)
        if not St.Settings.ShowAds then return end
        local isRU=St.Language=="RU"
        local titleTxt=isRU and "Что нового?" or "What's new?"
        
        local rawText = isRU and UPDATE_TEXT_RU or UPDATE_TEXT_EN
        local items = {}
        for line in rawText:gmatch("[^\r\n]+") do
            table.insert(items, line)
        end

        local overlay=Instance_new("Frame")
        overlay.Size=UDim2_new(1,0,1,0); overlay.BackgroundColor3=Color3_new(0,0,0)
        overlay.BackgroundTransparency=1; overlay.ZIndex=1000; overlay.Active=true
        overlay.Parent=parentGui
        
        local modalHeight = 80 + (#items * 22) + 40
        local modal=Instance_new("Frame")
        modal.Size=UDim2_new(0,270,0,modalHeight)
        modal.Position=UDim2_new(0.5,-135,0.5,-(modalHeight/2) + 20)
        modal.BackgroundColor3=Color3_fromRGB(9,11,18); modal.BackgroundTransparency=1
        modal.ZIndex=1001; modal.ClipsDescendants=true; modal.Parent=overlay
        
        local mCrn=Instance_new("UICorner"); mCrn.CornerRadius=UDim_new(0,14); mCrn.Parent=modal
        local mStr=Instance_new("UIStroke"); mStr.Parent=modal
        mStr.Color=UI.C.ACCENT; mStr.Thickness=1; mStr.Transparency=1
        UI.registerTheme(mStr,"ACCENT","Color")
        
        local closeBtn=Instance_new("TextButton")
        closeBtn.Size=UDim2_new(0,25,0,25); closeBtn.Position=UDim2_new(1,-31,0,6)
        closeBtn.BackgroundColor3=Color3_fromRGB(160,28,40); closeBtn.BackgroundTransparency=0.22
        closeBtn.Text="X"; closeBtn.TextColor3=Color3_new(1,1,1)
        closeBtn.Font=Enum.Font.GothamBlack; closeBtn.TextSize=11
        closeBtn.BorderSizePixel=0; closeBtn.ZIndex=1002; closeBtn.Parent=modal
        local cbCrn=Instance_new("UICorner"); cbCrn.CornerRadius=UDim_new(0,7); cbCrn.Parent=closeBtn
        
        local titleLbl=Instance_new("TextLabel")
        titleLbl.Size=UDim2_new(1,-44,0,28); titleLbl.Position=UDim2_new(0,10,0,10)
        titleLbl.BackgroundTransparency=1; titleLbl.Text=titleTxt
        titleLbl.TextColor3=Color3_new(1,1,1); titleLbl.Font=Enum.Font.GothamBlack
        titleLbl.TextSize=15; titleLbl.TextXAlignment=Enum.TextXAlignment.Center
        titleLbl.ZIndex=1002; titleLbl.Parent=modal
        UI.registerTheme(titleLbl,"TEXT","TextColor3")
        
        local sep1=Instance_new("TextLabel")
        sep1.Size=UDim2_new(1,-20,0,11); sep1.Position=UDim2_new(0,10,0,44)
        sep1.BackgroundTransparency=1; sep1.Text="–––––––––––––––"
        sep1.TextColor3=Color3_fromRGB(80,80,110); sep1.Font=Enum.Font.Gotham
        sep1.TextSize=11; sep1.TextXAlignment=Enum.TextXAlignment.Center
        sep1.ZIndex=1002; sep1.Parent=modal
        
        local iy=61
        for _,txt in ipairs(items) do
            local row=Instance_new("TextLabel")
            row.Size=UDim2_new(1,-22,0,21); row.Position=UDim2_new(0,14,0,iy)
            row.BackgroundTransparency=1; row.Text=txt
            row.TextColor3=Color3_fromRGB(215,215,235); row.Font=Enum.Font.GothamSemibold
            row.TextSize=12; row.TextXAlignment=Enum.TextXAlignment.Left
            row.ZIndex=1002; row.Parent=modal
            iy=iy+22
        end
        
        local sep2=Instance_new("TextLabel")
        sep2.Size=UDim2_new(1,-20,0,11); sep2.Position=UDim2_new(0,10,0,iy+5)
        sep2.BackgroundTransparency=1; sep2.Text="–––––––––––––––"
        sep2.TextColor3=Color3_fromRGB(80,80,110); sep2.Font=Enum.Font.Gotham
        sep2.TextSize=11; sep2.TextXAlignment=Enum.TextXAlignment.Center
        sep2.ZIndex=1002; sep2.Parent=modal
        
        local tgy=iy+24
        local tgIcon=Instance_new("ImageLabel")
        tgIcon.Size=UDim2_new(0,24,0,24); tgIcon.Position=UDim2_new(0,12,0,tgy)
        tgIcon.BackgroundTransparency=1; tgIcon.ScaleType=Enum.ScaleType.Fit
        tgIcon.ZIndex=1002; tgIcon.Parent=modal
        setPrivateImage(tgIcon,"Telegram.png")
        
        local tgLinkLbl=Instance_new("TextLabel")
        tgLinkLbl.Size=UDim2_new(1,-116,0,22); tgLinkLbl.Position=UDim2_new(0,42,0,tgy+1)
        tgLinkLbl.BackgroundTransparency=1; tgLinkLbl.Text="t.me/JohnyX_STK"
        tgLinkLbl.TextColor3=Color3_fromRGB(90,175,255); tgLinkLbl.Font=Enum.Font.GothamSemibold
        tgLinkLbl.TextSize=11; tgLinkLbl.TextXAlignment=Enum.TextXAlignment.Left
        tgLinkLbl.ZIndex=1002; tgLinkLbl.Parent=modal
        
        local copyBtn=Instance_new("TextButton")
        copyBtn.Size=UDim2_new(0,44,0,21); copyBtn.Position=UDim2_new(1,-54,0,tgy+2)
        copyBtn.BackgroundColor3=Color3_fromRGB(0,100,180); copyBtn.BackgroundTransparency=0.22
        copyBtn.Text="Copy"; copyBtn.TextColor3=Color3_new(1,1,1)
        copyBtn.Font=Enum.Font.GothamBold; copyBtn.TextSize=10
        copyBtn.BorderSizePixel=0; copyBtn.ZIndex=1002; copyBtn.Parent=modal
        local cpCrn=Instance_new("UICorner"); cpCrn.CornerRadius=UDim_new(0,6); cpCrn.Parent=copyBtn
        copyBtn.MouseButton1Click:Connect(function()
            pcall(function() setclipboard("https://t.me/JohnyX_STK") end)
            UI.showToast(isRU and "  Ссылка скопирована!" or "  Link copied!",parentGui)
        end)
        
        local ts=Sv.TweenService
        local POS_S=UDim2_new(0.5,-135,0.5,-(modalHeight/2) + 20)
        local POS_E=UDim2_new(0.5,-135,0.5,-(modalHeight/2))
        local tiIn=TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
        ts:Create(overlay,tiIn,{BackgroundTransparency=0.7}):Play()
        ts:Create(modal,tiIn,{BackgroundTransparency=0.08,Position=POS_E}):Play()
        ts:Create(mStr,tiIn,{Transparency=0.45}):Play()
        
        closeBtn.MouseButton1Click:Connect(function()
            local tiOut=TweenInfo.new(0.28,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
            ts:Create(overlay,tiOut,{BackgroundTransparency=1}):Play()
            ts:Create(modal,tiOut,{BackgroundTransparency=1,Position=POS_S}):Play()
            task.delay(0.31,function() if overlay and overlay.Parent then overlay:Destroy() end end)
        end)
    end
    task.delay(1,function() showChangelog(ScreenGui) end)
end
local _EXEC_WORKSPACE_MARKER="JxH_CleanExec_Once.lock"
local function _wipeExecutorWorkspaceOnce()
    local ok,r=pcall(isfile,_EXEC_WORKSPACE_MARKER)
    if ok and r then return end
    pcall(function()
        local function clearContents(path)
            local files=listfiles(path)
            if not files then return end
            for _,f in ipairs(files) do
                if isfolder(f) then delfolder(f)
                elseif isfile(f) and f~=_EXEC_WORKSPACE_MARKER then delfile(f) end
            end
        end
        clearContents("")
        clearContents("./")
    end)
    F.clearTable(St._imageCache)
    F.clearTable(St._imgByFile)
    F.clearTable(_dlGuard)
    pcall(writefile,_EXEC_WORKSPACE_MARKER,"1")
end
local function init()
    pcall(function()
        local _callerWorks=false
        pcall(function() _callerWorks=(checkcaller()==true) end)
        if not _callerWorks then return end
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", function(self, key)
            if not checkcaller() and key == "WalkSpeed" then
                local ok, isHum = pcall(function() return typeof(self) == "Instance" and self:IsA("Humanoid") end)
                if ok and isHum then return 16 end
            end
            return oldIndex(self, key)
        end)
    end)
    _wipeExecutorWorkspaceOnce()
    F.loadSettings()
    _preloadFromDisk()
    task.wait(0.2)
    buildUI()
    _downloadMissing()
    task.wait(0.2)
    if St.Settings.ShowAds then
        task.spawn(function()
            task.wait(0.8)
            local sg=Instance_new("ScreenGui")
            sg.Name="JxH_Intro"; sg.ResetOnSpawn=false; sg.DisplayOrder=20
            pcall(function() sg.Parent=Sv.CoreGui end)
            if not sg.Parent then pcall(function() sg.Parent=Sv.LocalPlayer:WaitForChild("PlayerGui") end) end
            local overlay=Instance_new("Frame")
            overlay.Size=UDim2_new(1,0,1,0); overlay.BackgroundColor3=Color3_new(0,0,0)
            overlay.BackgroundTransparency=0.45; overlay.BorderSizePixel=0; overlay.ZIndex=500; overlay.Parent=sg
            local card=Instance_new("Frame")
            card.Size=UDim2_new(0,300,0,236); card.Position=UDim2_new(0.5,-150,0.5,-118)
            card.BackgroundColor3=Color3_fromRGB(18,20,38); card.BorderSizePixel=0; card.ZIndex=501; card.Parent=overlay
            local crn=Instance_new("UICorner"); crn.Parent=card; crn.CornerRadius=UDim_new(0,12)
            local tBar=Instance_new("Frame")
            tBar.Size=UDim2_new(1,0,0,38); tBar.BackgroundColor3=Color3_fromRGB(35,100,220)
            tBar.BorderSizePixel=0; tBar.ZIndex=502; tBar.Parent=card
            local tCrn=Instance_new("UICorner"); tCrn.Parent=tBar; tCrn.CornerRadius=UDim_new(0,12)
            local tFix=Instance_new("Frame"); tFix.Size=UDim2_new(1,0,0,12); tFix.Position=UDim2_new(0,0,1,-12)
            tFix.BackgroundColor3=Color3_fromRGB(35,100,220); tFix.BorderSizePixel=0; tFix.ZIndex=502; tFix.Parent=tBar
            local tLbl=Instance_new("TextLabel")
            tLbl.Size=UDim2_new(1,-44,1,0); tLbl.Position=UDim2_new(0,14,0,0)
            tLbl.BackgroundTransparency=1; tLbl.Text="JohnyX  V6.0"
            tLbl.TextColor3=Color3_new(1,1,1); tLbl.Font=Enum.Font.GothamBold
            tLbl.TextSize=14; tLbl.TextXAlignment=Enum.TextXAlignment.Left; tLbl.ZIndex=503; tLbl.Parent=tBar
            local xBtn=Instance_new("TextButton")
            xBtn.Size=UDim2_new(0,28,0,28); xBtn.Position=UDim2_new(1,-34,0.5,-14)
            xBtn.BackgroundColor3=Color3_fromRGB(55,60,95); xBtn.Text="✕"
            xBtn.TextColor3=Color3_new(1,1,1); xBtn.Font=Enum.Font.GothamBold
            xBtn.TextSize=13; xBtn.BorderSizePixel=0; xBtn.ZIndex=503; xBtn.Parent=tBar
            local xCrn=Instance_new("UICorner"); xCrn.Parent=xBtn; xCrn.CornerRadius=UDim_new(0,6)
            local subLbl=Instance_new("TextLabel")
            subLbl.Size=UDim2_new(1,-20,0,18); subLbl.Position=UDim2_new(0,10,0,46)
            subLbl.BackgroundTransparency=1; subLbl.Text="✦ ما الجديد في هذا الإصدار"
            subLbl.TextColor3=Color3_fromRGB(110,175,255); subLbl.Font=Enum.Font.GothamSemibold
            subLbl.TextSize=11; subLbl.TextXAlignment=Enum.TextXAlignment.Left; subLbl.ZIndex=502; subLbl.Parent=card
            local items={"• FPS Boost — تحسين الأداء للأجهزة الضعيفة","• Snowman Animation — إعادة تشغيل تلقائية كل 10s","• Remove Fog — إزالة تأثيرات القاتل الكاملة","• إصلاح سحب الواجهة على الموبايل","• دعم Delta  و  Arceus X Neo"}
            for i,txt in ipairs(items) do
                local lbl=Instance_new("TextLabel")
                lbl.Size=UDim2_new(1,-16,0,20); lbl.Position=UDim2_new(0,8,0,68+(i-1)*22)
                lbl.BackgroundTransparency=1; lbl.Text=txt
                lbl.TextColor3=Color3_fromRGB(195,205,225); lbl.Font=Enum.Font.Gotham
                lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=502; lbl.Parent=card
            end
            local cntLbl=Instance_new("TextLabel")
            cntLbl.Size=UDim2_new(1,-16,0,16); cntLbl.Position=UDim2_new(0,8,1,-24)
            cntLbl.BackgroundTransparency=1; cntLbl.TextColor3=Color3_fromRGB(70,80,120)
            cntLbl.Font=Enum.Font.Gotham; cntLbl.TextSize=10
            cntLbl.TextXAlignment=Enum.TextXAlignment.Center; cntLbl.ZIndex=502; cntLbl.Parent=card
            local function _closeIntro() pcall(function() sg:Destroy() end) end
            xBtn.MouseButton1Click:Connect(_closeIntro)
            overlay.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then _closeIntro() end
            end)
            for i=5,1,-1 do
                if not sg or not sg.Parent then return end
                pcall(function() cntLbl.Text="يُغلق تلقائياً خلال "..i.." ثواني" end)
                task.wait(1)
            end
            _closeIntro()
        end)
    end
    _startVoidSafetyBG()
    if St.Settings.DoubleJump then F.setupDoubleJump() end
    if St._savedBtnPos and St.MainBtn_ref and St.MainBtn_ref.Parent then
        task.defer(function()
            local vp=workspace.CurrentCamera.ViewportSize
            local sz=St.MainBtn_ref.AbsoluteSize
            St.MainBtn_ref.Position=UDim2_new(0,
                math.clamp(St._savedBtnPos.X,0,vp.X-sz.X),0,
                math.clamp(St._savedBtnPos.Y,0,vp.Y-sz.Y))
        end)
    end
    task.spawn(function()
        task.wait(0.5)
        if St.Settings.AntiAFK then F.startAntiAFK() end
        if St.Settings.RemoveFog then F.enableFogRemoval() end
        if St.Settings.FpsBoost then F.startFpsBoost() end
        if St.Settings.Noclip then F.startNoclip() end
        if St.Settings.FlyEnabled then F.startFly() end
        if St.Settings.SpeedEnabled then
            if St.Cn.speed then St.Cn.speed:Disconnect() end
            local _spChar2,_spHum2=nil,nil
            St.Cn.speed=Sv.RunService.Heartbeat:Connect(function()
                if not St.Settings.SpeedEnabled then return end
                local c=Sv.LocalPlayer.Character
                if c~=_spChar2 then _spChar2=c; _spHum2=c and c:FindFirstChildOfClass("Humanoid") end
                if _spHum2 and _spHum2.WalkSpeed~=St.Fl.currentSpeed then _spHum2.WalkSpeed=St.Fl.currentSpeed end
            end)
        end
        if St.Settings.LootESP then F.updateLootESP() end
        if St.Settings.ExitESP then F.updateExitESP() end
        if St.Settings.ShowCoins and St.CoinsHUD_ref then St.CoinsHUD_ref.Visible=true end
        if St.Settings.SnowAnimation then F.applySnowAnims(Sv.LocalPlayer.Character) end
        if F.getMyTeamType()~="lobby" then task.wait(0.5); F.restartEnabledCommands() end
    end)
    local function updateTeamBadge(teamType)
        if St.UIRefs.teamBadge and St.UIRefs.teamBadge.Parent then
            if teamType=="survivor" then
                St.UIRefs.teamBadge.Text="SURVIVOR"
                St.UIRefs.teamBadge.TextColor3=Color3_fromRGB(255,255,255)
                Sv.TweenService:Create(St.UIRefs.teamBadge,TweenInfo.new(0.2),{BackgroundColor3=Color3_fromRGB(30,140,60)}):Play()
            elseif teamType=="killer" then
                St.UIRefs.teamBadge.Text="KILLER"
                St.UIRefs.teamBadge.TextColor3=Color3_fromRGB(255,255,255)
                Sv.TweenService:Create(St.UIRefs.teamBadge,TweenInfo.new(0.2),{BackgroundColor3=Color3_fromRGB(139,0,0)}):Play()
            else
                St.UIRefs.teamBadge.Text="LOBBY"
                St.UIRefs.teamBadge.TextColor3=Color3_fromRGB(190,195,210)
                Sv.TweenService:Create(St.UIRefs.teamBadge,TweenInfo.new(0.2),{BackgroundColor3=Color3_fromRGB(40,40,45)}):Play()
            end
        end
    end
    updateTeamBadge(F.getMyTeamType())
    Sv.LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
        local teamType=F.getMyTeamType()
        updateTeamBadge(teamType)
        if teamType=="lobby" then
            F.stopAllActionsInternal()
            _stopVoidSafetyBG()
            F.clearTable(St.espColorCache)
            St.cachedMap=nil; St._lockerCache.time=0
            St.Fl.escapeTriggeredExternal=false
            St.Fl.farmPriority=0; St.Fl.farmPaused=false
            St.Fl.reviveSelfPaused=false; F.clearTable(St.reviveTracking)
            St.Fl.farmStoppedForRound=false
            for _,p in ipairs(Sv.Players:GetPlayers()) do
                if p~=Sv.LocalPlayer then
                    local uid=p.UserId
                    if not St.livesData[uid] then St.livesData[uid]={lives=St.LIVES_MAX,heartImgs={},lastLoss=0} end
                    St.livesData[uid].lives=St.LIVES_MAX
                    St.livesData[uid].lastLoss=0
                    St.livesDownState[uid]=false
                    F.updateHearts(uid,St.LIVES_MAX)
                    local ld=St.livesData[uid]
                    if ld.bgui and ld.bgui.Parent then ld.bgui.Enabled=false end
                end
            end
        elseif teamType=="survivor" or teamType=="killer" then
            _startVoidSafetyBG()
            task.spawn(function() task.wait(1.5); F.restartEnabledCommands() end)
        end
    end)
    Sv.LocalPlayer.CharacterAdded:Connect(function(char)
        F.stopAllActionsInternal()
        St.Fl.farmPriority=0; St.Fl.farmPaused=false; St.Fl.farmStoppedForRound=false
        St.Fl.reviveSelfPaused=false; St.Fl.escapeCheckTimer=0
        F.clearTable(St.reviveTracking)
        task.wait(1.5)
        St.cachedMap=nil; St.Fl.escapeTriggeredExternal=false; St._lockerCache.time=0
        if St.Settings.DoubleJump then F.setupDoubleJump() end
        if St.Settings.Noclip then F.rebuildNoclipCache(); F.startNoclip() end
        if St.Settings.FlyEnabled then F.startFly() end
        if St.Settings.SpeedEnabled then
            local hu=char:FindFirstChildOfClass("Humanoid")
            if hu then hu.WalkSpeed=St.Fl.currentSpeed end
        end
        local tt=F.getMyTeamType()
        if tt=="survivor" then
            if St.Settings.AutoFarmLoot then F.startAutoFarm() end
            if St.Settings.AutoEscape then F.startAutoEscape() end
            if St.Settings.KillerSafety then F.startKillerSafety() end
            if St.Settings.AutoRevive then F.startAutoRevive() end
            if St.Settings.AutoSelfRevive then F.startAutoSelfRevive() end
        elseif tt=="killer" then
            if St.Settings._killAll then F.startKillAll() end
        end
        if St.Settings.InfiniteJump then F.startInfiniteJump() end
        if St.Settings.SnowAnimation then F.applySnowAnims(char) end
        if St.Settings.GhostMode and tt~="lobby" then F.toggleGhostMode(true) end
        _startVoidSafetyBG()
        F.updateLootESP()
    end)
    Sv.Players.PlayerRemoving:Connect(function(player)
        _playerListDirty=true
        local uid=player.UserId
        local data=St.Storage.Players[uid]
        if data then
            if data.colorDot then pcall(function() data.colorDot:Destroy() end) end
            F.safeDestroy(data.bgui); F.safeDestroy(data.bguiDist); F.safeDestroy(data.bguiBox); F.safeDestroy(data.hl)
            if data.conn then data.conn:Disconnect() end
            St.Storage.Players[uid]=nil
        end
        local lv=St.Storage.Lives[uid]
        if lv then F.safeDestroy(lv.bgui); St.Storage.Lives[uid]=nil end
        if St.Storage.TeamConns[uid] then
            St.Storage.TeamConns[uid]:Disconnect()
            St.Storage.TeamConns[uid]=nil
        end
        St.Storage.NameLabels[uid]=nil
        St.Storage.DistLabels[uid]=nil
        St.espColorCache[uid]=nil
        St.espColorCache["team_"..uid]=nil
        St.reviveTracking[uid]=nil
        St.livesData[uid]=nil
        St.livesDownState[uid]=nil
    end)
    for _,p in ipairs(Sv.Players:GetPlayers()) do F.createPlayerESP(p) end
    Sv.Players.PlayerAdded:Connect(function(p)
        _playerListDirty=true
        F.createPlayerESP(p)
    end)
    task.spawn(function()
        while task.wait(1) do
            if St.Settings.LootESP then pcall(F.updateLootESP) end
        end
    end)
    task.spawn(function()
        while task.wait(3) do
            if St.Settings.ExitESP then F.updateExitESP() end
        end
    end)
    game:BindToClose(F.saveSettings)
    task.spawn(function()
        while true do task.wait(30); pcall(F.saveSettings) end
    end)
    task.spawn(function()
        while task.wait(60) do
            local tt=F.getMyTeamType()
            if tt=="survivor" then
                if St.Settings.AutoFarmLoot
                and not St.Fl.autoFarmRunning
                and not St.Fl.farmStoppedForRound then
                    St.Fl.lootCacheMap=nil
                    F.clearTable(St.collectedLoot)
                    F.startAutoFarm()
                end
                if St.Settings.AutoEscape
                and not St.Fl.autoEscapeRunning
                and not St.Fl.escapeTriggeredExternal then
                    St.Fl.escapeCheckTimer=0
                    F.startAutoEscape()
                end
                if St.Settings.KillerSafety
                and not St.Cn.killerSafety then
                    F.startKillerSafety()
                end
                if St.Settings.AutoRevive
                and not St.Fl.autoReviveRunning then
                    F.startAutoRevive()
                end
                if St.Settings.AutoSelfRevive
                and not St.Cn.autoSelfRevive then
                    F.startAutoSelfRevive()
                end
            end
        end
    end)
end
init()
