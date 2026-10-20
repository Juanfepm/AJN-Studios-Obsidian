local Players = game:GetService("Players")
local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
assert(spawn, "No hay SpawnLocation")
assert(not workspace:FindFirstChild("WendigoEnemy"), "Ya existe WendigoEnemy; no se sobrescribe")
local rig = Instance.new("Model")
rig.Name = "WendigoEnemy"
rig:SetAttribute("CreatedBy", "Copilot")
rig:SetAttribute("DetectionRange", 60)
rig:SetAttribute("LoseInterestRange", 85)
rig:SetAttribute("WalkSpeed", 14)
rig:SetAttribute("AttackDamage", 10)
rig:SetAttribute("AttackCooldown", 1.5)
rig:SetAttribute("AttackRange", 7)
rig:SetAttribute("PlayerScale", 3)
rig:SetAttribute("State", "Idle")
local function core(name, size, pos, collide)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=CFrame.new(pos)
 p.Transparency=1 p.Anchored=false p.CanCollide=collide p.CanTouch=false
 p.Massless=name~="HumanoidRootPart" p.CastShadow=false p.Parent=rig
 return p
end
local root=core("HumanoidRootPart",Vector3.new(2,2,1),Vector3.zero,false)
local torso=core("Torso",Vector3.new(4.2,4.7,2.4),Vector3.zero,true)
local head=core("Head",Vector3.new(2.3,2.3,2),Vector3.new(0,3.4,-0.4),false)
local la=core("Left Arm",Vector3.new(1.5,5.5,1.5),Vector3.new(-2.6,-1.15,0),false)
local ra=core("Right Arm",Vector3.new(1.5,5.5,1.5),Vector3.new(2.6,-1.15,0),false)
local ll=core("Left Leg",Vector3.new(1.6,7,1.6),Vector3.new(-1.15,-4.5,0),false)
local rl=core("Right Leg",Vector3.new(1.6,7,1.6),Vector3.new(1.15,-4.5,0),false)
local function motor(name,a,b,pivot)
 local m=Instance.new("Motor6D") m.Name=name m.Part0=a m.Part1=b
 m.C0=a.CFrame:ToObjectSpace(CFrame.new(pivot)) m.C1=b.CFrame:ToObjectSpace(CFrame.new(pivot))
 m.Parent=a return m
end
motor("RootJoint",root,torso,Vector3.zero)
motor("Neck",torso,head,Vector3.new(0,2.6,-.4))
motor("Left Shoulder",torso,la,Vector3.new(-2.6,1.6,0))
motor("Right Shoulder",torso,ra,Vector3.new(2.6,1.6,0))
motor("Left Hip",torso,ll,Vector3.new(-1.15,-1,0))
motor("Right Hip",torso,rl,Vector3.new(1.15,-1,0))
local visual=Instance.new("Folder") visual.Name="Appearance" visual.Parent=rig
local dark=Color3.fromRGB(34,36,33)
local grey=Color3.fromRGB(65,67,59)
local fur=Color3.fromRGB(22,25,24)
local bone=Color3.fromRGB(194,187,153)
local horn=Color3.fromRGB(58,47,35)
local black=Color3.fromRGB(9,12,11)
local count=0
local function part(name,size,cf,color,owner,shape,material)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color
 p.Material=material or Enum.Material.SmoothPlastic
 p.Shape=shape or Enum.PartType.Block
 p.Anchored=false p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true
 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=visual
 local w=Instance.new("WeldConstraint") w.Part0=owner w.Part1=p w.Parent=p
 count+=1
 return p
end
local function ellipsoid(name,position,size,color,owner)
 return part(name,size,CFrame.new(position),color,owner,Enum.PartType.Ball)
end
local function segment(name,a,b,r1,color,owner)
 a=Vector3.new(table.unpack(a)) b=Vector3.new(table.unpack(b))
 local midpoint=(a+b)*.5
 return part(name,Vector3.new((b-a).Magnitude,r1,r1),CFrame.lookAt(midpoint,b)*CFrame.Angles(0,math.pi/2,0),color,owner,Enum.PartType.Cylinder)
end
ellipsoid("GauntTorso",Vector3.new(0,.6,0),Vector3.new(4.5,5.2,2.4),dark,torso)
ellipsoid("NarrowWaist",Vector3.new(0,-2,0),Vector3.new(2.4,2.7,1.6),grey,torso)
ellipsoid("HunchedBack",Vector3.new(0,1.9,.75),Vector3.new(4.8,2.6,2.8),fur,torso)
ellipsoid("Pelvis",Vector3.new(0,-2.5,.15),Vector3.new(3.3,1.8,2),dark,torso)
for side=-1,1,2 do
 local arm=side<0 and la or ra
 local leg=side<0 and ll or rl
 local label=side<0 and "Left" or "Right"
 ellipsoid(label.."Shoulder",Vector3.new(side*2.65,1.65,.1),Vector3.new(2,2,2),fur,arm)
 segment(label.."UpperArm",{side*2.65,1.5,0},{side*3.7,-1.5,-.2},.95,grey,arm)
 ellipsoid(label.."Elbow",Vector3.new(side*3.7,-1.5,-.2),Vector3.new(1.1,1.1,1.1),dark,arm)
 segment(label.."Forearm",{side*3.7,-1.5,-.2},{side*4.2,-4.5,-.8},.64,dark,arm)
 ellipsoid(label.."Palm",Vector3.new(side*4.2,-4.65,-.85),Vector3.new(.9,1.15,.6),grey,arm)
 for finger=1,3 do
  local x=side*4.2+(finger-2)*.35
  local bottom=-5.7-(finger==2 and .3 or 0)
  segment(label.."Finger"..finger,{x,-4.95,-.9},{x+side*.1,bottom,-1.15},.2,dark,arm)
  segment(label.."Claw"..finger,{x+side*.1,bottom,-1.15},{x+side*.08,bottom-.38,-1.45},.12,bone,arm)
 end
 segment(label.."Thigh",{side*1.15,-2.65,.25},{side*1.5,-4.9,-.55},1.25,dark,leg)
 ellipsoid(label.."Knee",Vector3.new(side*1.5,-4.9,-.55),Vector3.new(1.25,1.35,1.2),grey,leg)
 segment(label.."Shin",{side*1.5,-5,-.55},{side*1.25,-7.55,.3},.65,dark,leg)
 ellipsoid(label.."Hoof",Vector3.new(side*1.25,-7.65,-.25),Vector3.new(1.15,.7,2),black,leg)
 for row=1,4 do
  part(label.."ChestPlate"..row,Vector3.new(1.55,.18,.27),CFrame.new(side*.95,1.55-row*.65,-1.05)*CFrame.Angles(0,side*.16,side*.18),grey,torso)
 end
 for tuft=1,5 do
  local x=side*(1.1+tuft*.31)
  part(label.."ManeTuft"..tuft,Vector3.new(.65,2.15,.8),CFrame.new(x,2.3-math.abs(x)*.1,.25)*CFrame.Angles(.4,0,side*.44),fur,torso)
 end
end
for i=1,7 do
 part("TatteredPelt"..i,Vector3.new(.5,1.7+(i%3)*.35,.4),CFrame.new((i-4)*.43,-3.1,.7)*CFrame.Angles(.15,0,(i-4)*.06),fur,torso)
end
segment("Neck",{0,1.5,.1},{0,3.5,-.5},1.4,fur,head)
ellipsoid("SkullCrown",Vector3.new(0,3.8,-.9),Vector3.new(2.55,2.85,1.85),bone,head)
ellipsoid("LongMuzzle",Vector3.new(0,2.85,-1.65),Vector3.new(1.35,2.3,1.35),bone,head)
ellipsoid("NoseCavity",Vector3.new(0,2.45,-2.28),Vector3.new(.45,.85,.18),black,head)
for side=-1,1,2 do
 local s=side<0 and "Left" or "Right"
 ellipsoid(s.."EyeSocket",Vector3.new(side*.73,3.85,-1.68),Vector3.new(.8,1.04,.28),black,head)
 local eye=ellipsoid(s.."AmberEye",Vector3.new(side*.73,3.88,-1.84),Vector3.new(.15,.38,.1),Color3.fromRGB(214,144,47),head)
 eye.Material=Enum.Material.Neon
 part(s.."Brow",Vector3.new(1.05,.35,.48),CFrame.new(side*.72,4.4,-1.55)*CFrame.Angles(0,0,side*.24),bone,head)
 segment(s.."Jaw",{side*.8,3.1,-1.25},{side*.46,1.8,-1.55},.24,bone,head)
 for t=1,3 do
  part(s.."Tooth"..t,Vector3.new(.16,.3+(t%2)*.12,.16),CFrame.new(side*(.16+t*.14),2.04,-1.8),bone,head)
 end
 local base={side*.95,4.9,-.35}
 local elbow={side*2.7,6.1,.1}
 local middle={side*4.3,6.95,.25}
 local endp={side*5.8,7.65,.45}
 segment(s.."AntlerBase",base,elbow,.5,horn,head)
 segment(s.."AntlerBeam",elbow,middle,.35,horn,head)
 segment(s.."AntlerTip",middle,endp,.18,horn,head)
 for tine=1,4 do
  local x=side*(1.75+tine*.73)
  local y=5.65+tine*.43
  segment(s.."AntlerTine"..tine,{x,y,.15},{x+side*.18,y+1.55+(tine%2)*.35,.25},.18,horn,head)
  segment(s.."AntlerTineTip"..tine,{x+side*.18,y+1.55+(tine%2)*.35,.25},{x-side*.05,y+2.05+(tine%2)*.35,.2},.09,horn,head)
 end
end
local humanoid=Instance.new("Humanoid") humanoid.Name="Humanoid" humanoid.DisplayName="WENDIGO"
humanoid.MaxHealth=100 humanoid.Health=100 humanoid.WalkSpeed=14 humanoid.HipHeight=0
humanoid.RequiresNeck=false humanoid.BreakJointsOnDeath=false humanoid.AutoRotate=true
humanoid.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff
humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
humanoid.Parent=rig
local animator=Instance.new("Animator") animator.Parent=humanoid
rig.PrimaryPart=root
local _,size=rig:GetBoundingBox()
rig:ScaleTo(18/size.Y)
local cf2,size2=rig:GetBoundingBox()
local spawnPos=spawn.Position+Vector3.new(40,0,24)
local ground=workspace:Raycast(Vector3.new(spawnPos.X,100,spawnPos.Z),Vector3.new(0,-200,0))
local groundY=ground and ground.Position.Y or 0
local origin=root.Position
local feet=cf2.Position.Y-size2.Y/2
rig:PivotTo(CFrame.new(spawnPos.X,groundY+.1+(origin.Y-feet),spawnPos.Z)*CFrame.Angles(0,math.rad(58),0))
rig:SetAttribute("NominalHeight",size2.Y)
rig:SetAttribute("VisualPartCount",count)
rig:SetAttribute("HomePosition",root.Position)
local gui=Instance.new("BillboardGui") gui.Name="HealthBar" gui.Adornee=root gui.Size=UDim2.fromOffset(220,56)
gui.StudsOffsetWorldSpace=Vector3.new(0,size2.Y-(root.Position.Y-groundY)+2.3,0)
gui.AlwaysOnTop=true gui.MaxDistance=120 gui.Parent=head
local label=Instance.new("TextLabel") label.Name="Name" label.Size=UDim2.new(1,0,0,25) label.BackgroundTransparency=1
label.Font=Enum.Font.GothamBold label.Text="WENDIGO" label.TextSize=19 label.TextColor3=Color3.fromRGB(226,218,193)
label.TextStrokeTransparency=.35 label.Parent=gui
local back=Instance.new("Frame") back.Name="Track" back.Position=UDim2.fromOffset(5,29) back.Size=UDim2.new(1,-10,0,18)
back.BackgroundColor3=Color3.fromRGB(23,24,23) back.BorderSizePixel=0 back.ClipsDescendants=true back.Parent=gui
local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,5) corner.Parent=back
local fill=Instance.new("Frame") fill.Name="Fill" fill.Size=UDim2.fromScale(1,1)
fill.BackgroundColor3=Color3.fromRGB(153,48,43) fill.BorderSizePixel=0 fill.Parent=back
local value=Instance.new("TextLabel") value.Name="Value" value.Size=UDim2.fromScale(1,1) value.BackgroundTransparency=1
value.Text="100 / 100" value.Font=Enum.Font.GothamBold value.TextSize=12 value.TextColor3=Color3.new(1,1,1) value.Parent=back
rig.Parent=workspace
for _,p in rig:GetDescendants() do if p:IsA("BasePart") and not p.Anchored then pcall(function() p:SetNetworkOwner(nil) end) end end
game:GetService("ChangeHistoryService"):SetWaypoint("Crear Wendigo")
return {name=rig:GetFullName(),height=rig:GetExtentsSize().Y,parts=count,position=tostring(root.Position),health=humanoid.Health}
