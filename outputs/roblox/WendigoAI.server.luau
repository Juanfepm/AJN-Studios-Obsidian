-- Wendigo: server-authoritative pursuit, health, melee and procedural gait.
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local npc = workspace:WaitForChild("WendigoEnemy")
local hum = npc:WaitForChild("Humanoid")
local root = npc:WaitForChild("HumanoidRootPart")
local gui = npc.Head:WaitForChild("HealthBar")
local track = gui.Track
local home = npc:GetAttribute("HomePosition") or root.Position
local function setting(name,fallback)
 local v=npc:GetAttribute(name)
 return typeof(v)=="number" and v or fallback
end
hum.WalkSpeed=setting("WalkSpeed",14)
local joints={}
local function cacheJoints()
 table.clear(joints)
 for _,name in {"Left Shoulder","Right Shoulder","Left Hip","Right Hip","Neck"} do
  local joint=npc:FindFirstChild(name,true)
  if joint and joint:IsA("Motor6D") then joints[name]={joint=joint,base=joint.C0} end
 end
end
cacheJoints()
local function healthBar()
 local ratio=math.clamp(hum.Health/math.max(1,hum.MaxHealth),0,1)
 track.Fill.Size=UDim2.fromScale(ratio,1)
 track.Value.Text=string.format("%d / %d",math.ceil(hum.Health),math.ceil(hum.MaxHealth))
 track.Fill.BackgroundColor3=ratio>.35 and Color3.fromRGB(153,48,43) or Color3.fromRGB(207,99,38)
end
hum.HealthChanged:Connect(healthBar)
hum:GetPropertyChangedSignal("MaxHealth"):Connect(healthBar)
healthBar()
local sized=false
local function matchPlayer(character)
 local ph=character and character:FindFirstChildOfClass("Humanoid")
 if not ph then return end
 if ph.MaxHealth>0 and hum.MaxHealth~=ph.MaxHealth then
  local ratio=hum.Health/math.max(hum.MaxHealth,1)
  hum.MaxHealth=ph.MaxHealth
  hum.Health=ph.MaxHealth*ratio
 end
 if not sized then
  local minimum,maximum=math.huge,-math.huge
  for _,part in character:GetChildren() do
   if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
    local cf,s=part.CFrame,part.Size
    local extent=(math.abs(cf.RightVector.Y)*s.X+math.abs(cf.UpVector.Y)*s.Y+math.abs(cf.LookVector.Y)*s.Z)/2
    minimum=math.min(minimum,part.Position.Y-extent)
    maximum=math.max(maximum,part.Position.Y+extent)
   end
  end
  local height=maximum-minimum
  if height>2 and height<15 then
   local beforeCF,beforeSize=npc:GetBoundingBox()
   local bottom=beforeCF.Position.Y-beforeSize.Y/2
   npc:ScaleTo(npc:GetScale()*(height*setting("PlayerScale",3)/beforeSize.Y))
   local afterCF,afterSize=npc:GetBoundingBox()
   local afterBottom=afterCF.Position.Y-afterSize.Y/2
   npc:PivotTo(npc:GetPivot()+Vector3.new(0,bottom-afterBottom,0))
   home=root.Position
   npc:SetAttribute("HomePosition",home)
   npc:SetAttribute("ReferencePlayerHeight",height)
   npc:SetAttribute("HeightStuds",afterSize.Y)
   gui.StudsOffsetWorldSpace=Vector3.new(0,afterCF.Position.Y+afterSize.Y/2-root.Position.Y+2.3,0)
   cacheJoints()
   sized=true
  end
 end
 healthBar()
end
local alive=true
local targetPlayer=nil
local phase=0
local animationAccumulator=0
local animation=RunService.Heartbeat:Connect(function(dt)
 if not alive or not npc.Parent then return end
 animationAccumulator+=dt
 if animationAccumulator<.05 then return end
 local step=animationAccumulator
 animationAccumulator=0
 local speed=Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude
 phase+=step*(speed>1 and 5.2 or 1.3)
 local swing=math.sin(phase)*(speed>1 and .33 or .025)
 for name,data in joints do
  if name=="Left Shoulder" then data.joint.C0=data.base*CFrame.Angles(swing,0,-.05)
  elseif name=="Right Shoulder" then data.joint.C0=data.base*CFrame.Angles(-swing,0,.05)
  elseif name=="Left Hip" then data.joint.C0=data.base*CFrame.Angles(-swing*.8,0,0)
  elseif name=="Right Hip" then data.joint.C0=data.base*CFrame.Angles(swing*.8,0,0)
  else data.joint.C0=data.base*CFrame.Angles(math.sin(phase*.35)*.025,math.sin(phase*.25)*.05,0) end
 end
end)
hum.Died:Connect(function()
 alive=false
 npc:SetAttribute("State","Dead")
 npc:SetAttribute("TargetUserId",0)
 hum:Move(Vector3.zero)
 animation:Disconnect()
gui:FindFirstChild("Name").Text="WENDIGO · DERROTADO"
 for name,data in joints do
  if name=="Neck" then data.joint.C0=data.base*CFrame.Angles(.55,0,.2) end
 end
end)
local function body(player)
 local char=player and player.Character
 local h=char and char:FindFirstChildOfClass("Humanoid")
 local r=char and char:FindFirstChild("HumanoidRootPart")
 if h and r and h.Health>0 then return char,h,r end
end
local function nearest()
 local best,range=nil,setting("DetectionRange",60)
 for _,p in Players:GetPlayers() do
  local _,_,r=body(p)
  if r then
   local distance=(r.Position-root.Position).Magnitude
   if distance<range then best,range=p,distance end
  end
 end
 return best
end
local route={}
local routeIndex=1
local lastPath=0
local lastGoal=nil
local lastAttack=0
local lastProgress=os.clock()
local progressPosition=root.Position
local function walkToward(goal,character)
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances=character and {npc,character} or {npc}
 local from=root.Position
 local obstruction=workspace:Raycast(from,goal-from,params)
 if not obstruction then
  table.clear(route)
  hum:MoveTo(goal)
  return
 end
 local now=os.clock()
 if now-lastPath>1.1 and (not lastGoal or (lastGoal-goal).Magnitude>5 or routeIndex>#route) then
  lastPath=now
  lastGoal=goal
  local path=PathfindingService:CreatePath({AgentRadius=3,AgentHeight=math.ceil(npc:GetAttribute("HeightStuds") or 18),AgentCanJump=true,WaypointSpacing=5})
  local ok=pcall(function() path:ComputeAsync(root.Position,goal) end)
  if ok and path.Status==Enum.PathStatus.Success then
   route=path:GetWaypoints()
   routeIndex=math.min(2,#route)
  else
   table.clear(route)
  end
 end
 local point=route[routeIndex]
 if point then
  local delta=point.Position-root.Position
  if Vector3.new(delta.X,0,delta.Z).Magnitude<3 then routeIndex+=1 point=route[routeIndex] end
 end
 if point then
  if point.Action==Enum.PathWaypointAction.Jump then hum.Jump=true end
  hum:MoveTo(point.Position)
 else
  hum:MoveTo(goal)
 end
end
local function onPlayer(player)
 player.CharacterAdded:Connect(function(character)
  local h=character:WaitForChild("Humanoid",10)
  local r=character:WaitForChild("HumanoidRootPart",10)
  if h and r and alive then task.wait(.3) matchPlayer(character) end
 end)
 if player.Character then matchPlayer(player.Character) end
end
Players.PlayerAdded:Connect(onPlayer)
for _,p in Players:GetPlayers() do onPlayer(p) end
while npc.Parent and hum.Health>0 and alive do
 local char,ph,pr=body(targetPlayer)
 if not pr or (pr.Position-root.Position).Magnitude>setting("LoseInterestRange",85) then
  targetPlayer=nearest()
  char,ph,pr=body(targetPlayer)
  table.clear(route)
  lastGoal=nil
 end
 if pr then
  matchPlayer(char)
  npc:SetAttribute("State","Chasing")
  npc:SetAttribute("TargetUserId",targetPlayer.UserId)
  local distance=(pr.Position-root.Position).Magnitude
  npc:SetAttribute("DistanceToTarget",math.round(distance*10)/10)
  if distance>5 then walkToward(pr.Position,char) else hum:MoveTo(root.Position) end
  if distance<=setting("AttackRange",7) and os.clock()-lastAttack>=setting("AttackCooldown",1.5) then
   lastAttack=os.clock()
   -- Damage respects Roblox spawn protection.
   ph:TakeDamage(setting("AttackDamage",10))
   npc:SetAttribute("LastAttackAt",workspace:GetServerTimeNow())
  end
 elseif (Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(home.X,0,home.Z)).Magnitude>4 then
  npc:SetAttribute("State","Returning")
  npc:SetAttribute("TargetUserId",0)
  walkToward(home,nil)
 else
  npc:SetAttribute("State","Idle")
  npc:SetAttribute("TargetUserId",0)
  hum:MoveTo(root.Position)
 end
 if os.clock()-lastProgress>2.5 then
  if pr and (root.Position-progressPosition).Magnitude<1.5 then hum.Jump=true end
  progressPosition=root.Position lastProgress=os.clock()
 end
 task.wait(.15)
end
if animation.Connected then animation:Disconnect() end
