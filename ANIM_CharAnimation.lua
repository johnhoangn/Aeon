local rmd = game.ReplicatedStorage:WaitForChild("RemoteDump")

function   waitForChild(parent, childName)
	local child = parent:findFirstChild(childName)
	if child then return child end
	while true do
		child = parent.ChildAdded:wait()
		if child.Name==childName then return child end
	end
end
local Figure = script.Parent
	Figure:WaitForChild("Sound"):WaitForChild("LocalSound").Disabled = true
local cMethods = require(game.Players.LocalPlayer.PlayerScripts:WaitForChild("ClientMethods"))
local mode = game.Players.LocalPlayer.PlayerGui:WaitForChild("Screen"):WaitForChild("Aspect"):WaitForChild("Inventory"):WaitForChild("Mode")
local sprinting = Figure:WaitForChild("ActorValues"):WaitForChild("Sprinting")
local Torso = waitForChild(Figure, "Torso")
local RightShoulder = waitForChild(Torso, "Right Shoulder")
local LeftShoulder = waitForChild(Torso, "Left Shoulder")
local RightHip = waitForChild(Torso, "Right Hip")
local LeftHip = waitForChild(Torso, "Left Hip")
local Neck = waitForChild(Torso, "Neck")
local Humanoid = waitForChild(Figure, "Humanoid")
local pose = "Standing"

local currentAnim = ""
local currentAnimInstance = nil
local currentAnimTrack = nil
local currentAnimKeyframeHandler = nil
local currentAnimSpeed = 1.0
local animTable = {}
local animNames = { 
	idle = 	{	
				{ id = "rbxassetid://180435571", weight = 10 }
		},
	idleWeapon = 	{	
				{ id = "rbxassetid://180435571", weight = 10 }
			},
	walkNorm = 	{ 	
				{ id = "rbxassetid://478619798", weight = 10 } 
			}, 
	runNorm = 	{
				{ id = "rbxassetid://478619798", weight = 10 } 
			}, 
	walkWeapon = 	{ 	
				{ id = "rbxassetid://180426354", weight = 10 } 
			}, 
	runWeapon = 	{
				{ id = "rbxassetid://180426354", weight = 10 } 
			}, 
	jump = 	{
				{ id = "rbxassetid://125750702", weight = 10 } 
			}, 
	fall = 	{
				{ id = "rbxassetid://180436148", weight = 10 } 
			}, 
	climb = {
				{ id = "rbxassetid://180436334", weight = 10 } 
			}, 
	sit = 	{
				{ id = "rbxassetid://178130996", weight = 10 } 
			},	
	wave = {
				{ id = "rbxassetid://128777973", weight = 10 } 
			},
	point = {
				{ id = "rbxassetid://128853357", weight = 10 } 
			},
	hey = {
				{ id = "rbxassetid://435578898", weight = 10 }
			},
	laugh = {
				{ id = "rbxassetid://897332604", weight = 10 } 
			},
	cheer = {
				{ id = "rbxassetid://129423030", weight = 10 } 
			},
}
local dances = {"dance1", "dance2", "dance3"}

-- Existance in this list signifies that it is an emote, the value indicates if it is a looping emote
local emoteNames = {hey = false, cheer = false, laugh = false, point = false, wave = false}

function configureAnimationSet(name, fileList)
	if (animTable[name] ~= nil) then
		for _, connection in pairs(animTable[name].connections) do
			connection:disconnect()
		end
	end
	animTable[name] = {}
	animTable[name].count = 0
	animTable[name].totalWeight = 0	
	animTable[name].connections = {}

	-- check for config values
	local config = script:FindFirstChild(name)
	if (config ~= nil) then
--		print("Loading anims " .. name)
		table.insert(animTable[name].connections, config.ChildAdded:connect(function(child) configureAnimationSet(name, fileList) end))
		table.insert(animTable[name].connections, config.ChildRemoved:connect(function(child) configureAnimationSet(name, fileList) end))
		local idx = 1
		for _, childPart in pairs(config:GetChildren()) do
			if (childPart:IsA("Animation")) then
				table.insert(animTable[name].connections, childPart.Changed:connect(function(property) configureAnimationSet(name, fileList) end))
				animTable[name][idx] = {}
				animTable[name][idx].anim = childPart
				local weightObject = childPart:FindFirstChild("Weight")
				if (weightObject == nil) then
					animTable[name][idx].weight = 1
				else
					animTable[name][idx].weight = weightObject.Value
				end
				animTable[name].count = animTable[name].count + 1
				animTable[name].totalWeight = animTable[name].totalWeight + animTable[name][idx].weight
	--			print(name .. " [" .. idx .. "] " .. animTable[name][idx].anim.AnimationId .. " (" .. animTable[name][idx].weight .. ")")
				idx = idx + 1
			end
		end
	end

	-- fallback to defaults
	if (animTable[name].count <= 0) then
		for idx, anim in pairs(fileList) do
			animTable[name][idx] = {}
			animTable[name][idx].anim = Instance.new("Animation")
			animTable[name][idx].anim.Name = name
			animTable[name][idx].anim.AnimationId = anim.id
			animTable[name][idx].weight = anim.weight
			animTable[name].count = animTable[name].count + 1
			animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
--			print(name .. " [" .. idx .. "] " .. anim.id .. " (" .. anim.weight .. ")")
		end
	end
end

-- Setup animation objects
function scriptChildModified(child)
	local fileList = animNames[child.Name]
	if (fileList ~= nil) then
		configureAnimationSet(child.Name, fileList)
	end	
end

script.ChildAdded:connect(scriptChildModified)
script.ChildRemoved:connect(scriptChildModified)


for name, fileList in pairs(animNames) do 
	configureAnimationSet(name, fileList)
end	

-- ANIMATION

-- declarations
local toolAnim = "None"
local toolAnimTime = 0

local jumpAnimTime = 0
local jumpAnimDuration = 0.3

local toolTransitionTime = 0.1
local fallTransitionTime = 0.3
local jumpMaxLimbVelocity = 0.75

-- functions

function stopAllAnimations()
	local oldAnim = currentAnim

	-- return to idle if finishing an emote
	if (emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false) then
		oldAnim = "idle"
	end

	currentAnim = ""
	currentAnimInstance = nil
	if (currentAnimKeyframeHandler ~= nil) then
		currentAnimKeyframeHandler:disconnect()
	end

	if (currentAnimTrack ~= nil) then
		currentAnimTrack:Stop(.2)
		currentAnimTrack:Destroy()
		currentAnimTrack = nil
	end
	return oldAnim
end

function setAnimationSpeed(speed)
	if currentAnimTrack and speed ~= currentAnimSpeed then
		currentAnimSpeed = speed
		currentAnimTrack:AdjustSpeed(currentAnimSpeed)
	end
end

function filterMaterial(mat)
	if mat == "Granite" or mat == "Marble" 
		or mat == "Cobblestone" or mat == "Slate" 
		or mat == "Concrete" or mat == "Brick" 
		or mat == "Pavement" or mat == "Asphalt" 
		or mat == "Rock" or mat == "Basalt"
		or mat == "Limestone" or mat == "Plastic" then
		return "Stone"
	elseif mat == "Wood" or mat == "WoodPlanks" then
		return "Wood"
	elseif mat == "Ground" then
		return "Grass"
	else
		return mat
	end
end

function keyFrameReachedFunc(frameName)
	local sound = string.find(frameName,"Sound")
	local step = string.find(frameName,"Step")
	if (frameName == "End") then

		local repeatAnim = currentAnim
		-- return to idle if finishing an emote
		if (emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false) then
			repeatAnim = "idle"
		end
		
		local animSpeed = currentAnimSpeed
		playAnimation(repeatAnim, 0.2, Humanoid)
		setAnimationSpeed(animSpeed)
	end
	if sound ~= nil then
		coroutine.wrap(function()
			rmd.RemoteSound:FireServer(Figure.Head,"Emote"..string.sub(frameName,sound+6),1,0,tonumber(string.sub(frameName,sound+5,sound+6)))
		end)()
	elseif step ~= nil then
		local ray = Ray.new(Figure.Torso.Position,Vector3.new(0,-5,0))
		local hit, p, n, mat = workspace:FindPartOnRayWithIgnoreList(ray,{Figure})
		if hit then
			local material = filterMaterial(string.sub(tostring(mat),15))
			local step = material .. "Step"
			cMethods.playStep(step,Torso.Velocity.magnitude/18,.1)
		end	
	end
end

-- Preload animations
function playAnimation(animName, transitionTime, humanoid) 
		
	local roll = math.random(1, animTable[animName].totalWeight) 
	local origRoll = roll
	local idx = 1
	while (roll > animTable[animName][idx].weight) do
		roll = roll - animTable[animName][idx].weight
		idx = idx + 1
	end

	local anim = animTable[animName][idx].anim

	-- switch animation		
	if (anim ~= currentAnimInstance) then		
		if currentAnimTrack ~= nil then
			currentAnimTrack:Stop(transitionTime)
			currentAnimTrack:Destroy()
		end

		currentAnimSpeed = 1.0
	
		-- load it to the humanoid; get AnimationTrack
		currentAnimTrack = humanoid:LoadAnimation(anim)

		-- play the animation
		currentAnim = animName
		currentAnimInstance = anim

		-- set up keyframe name triggers
		if (currentAnimKeyframeHandler ~= nil) then
			currentAnimKeyframeHandler:disconnect()
		end
		currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)
		currentAnimTrack:Play(transitionTime)
		
		setAnimationSpeed(sprinting.Value == true and 24.7 / 12 or 13 / 12)
	end
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

local toolAnimName = ""
local toolAnimTrack = nil
local toolAnimInstance = nil
local currentToolAnimKeyframeHandler = nil

function toolKeyFrameReachedFunc(frameName)
	if (frameName == "End") then
--		print("Keyframe : ".. frameName)	
		playToolAnimation(toolAnimName, 0.0, Humanoid)
	end
end


function playToolAnimation(animName, transitionTime, humanoid)	 
		
		local roll = math.random(1, animTable[animName].totalWeight) 
		local origRoll = roll
		local idx = 1
		while (roll > animTable[animName][idx].weight) do
			roll = roll - animTable[animName][idx].weight
			idx = idx + 1
		end
--		print(animName .. " * " .. idx .. " [" .. origRoll .. "]")
		local anim = animTable[animName][idx].anim

		if (toolAnimInstance ~= anim) then
			
			if (toolAnimTrack ~= nil) then
				toolAnimTrack:Stop()
				toolAnimTrack:Destroy()
				transitionTime = 0
			end
					
			-- load it to the humanoid; get AnimationTrack
			toolAnimTrack = humanoid:LoadAnimation(anim)
			wait(1)
			-- play the animation
			toolAnimTrack:Play(transitionTime)
			toolAnimName = animName
			toolAnimInstance = anim

			currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:connect(toolKeyFrameReachedFunc)
		end
end

function stopToolAnimations()
	local oldAnim = toolAnimName

	if (currentToolAnimKeyframeHandler ~= nil) then
		currentToolAnimKeyframeHandler:disconnect()
	end

	toolAnimName = ""
	toolAnimInstance = nil
	if (toolAnimTrack ~= nil) then
		toolAnimTrack:Stop()
		toolAnimTrack:Destroy()
		toolAnimTrack = nil
	end


	return oldAnim
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

function moveType()
	if Figure.Torso.Velocity.magnitude > 1 then
		if mode.Value ~= 0 and sprinting.Value == false then
			pose = "Walking"
		elseif mode.Value == 0 and sprinting.Value == false then
			pose = "WalkingWeapon"
		elseif mode.Value ~= 0 and sprinting.Value == true then
			pose = "Running"
		elseif mode.Value == 0 and sprinting.Value == true then
			pose = "RunningWeapon"
		end
		setAnimationSpeed(sprinting.Value == true and 24.7 / 12 or 13 / 12)
	else
		if mode.Value ~= 0 then
			playAnimation("idle",0.2,Humanoid)
			pose = "Standing"
		elseif mode.Value == 0 then
			pose = "StandingWeapon"		
		end
	end
end

function onRunning(speed)
	if speed>0.01 then
		moveType()
	else
		if emoteNames[currentAnim] == nil then
			if mode.Value == -1 then
				playAnimation("idle",0.2,Humanoid)
				pose = "Standing"
			elseif mode.Value == 0 then
				pose = "StandingWeapon"		
			end
		end
	end
end

function onDied()
	pose = "Dead"
end

function onJumping()
	playAnimation("jump", 0.1, Humanoid)
	jumpAnimTime = jumpAnimDuration
	pose = "Jumping"
end

function onClimbing(speed)
	playAnimation("climb", 0.1, Humanoid)
	setAnimationSpeed(speed / 12.0)
	pose = "Climbing"
end

function onGettingUp()
	pose = "GettingUp"
end

function onFreeFall()
	if (jumpAnimTime <= 0) then
		playAnimation("fall", fallTransitionTime, Humanoid)
	end
	pose = "FreeFall"
end

function onFallingDown()
	pose = "FallingDown"
end

function onSeated()
	pose = "Seated"
end

function onPlatformStanding()
	pose = "PlatformStanding"
end

function onSwimming(speed)
	if speed>0 then
		pose = "Swimming"
	else
		pose = "Standing"
	end
end

function getTool()	
	for _, kid in ipairs(Figure:GetChildren()) do
		if kid.className == "Tool" then return kid end
	end
	return nil
end

function getToolAnim(tool)
	for _, c in ipairs(tool:GetChildren()) do
		if c.Name == "toolanim" and c.className == "StringValue" then
			return c
		end
	end
	return nil
end

function animateTool()
	if (toolAnim == "None") then
		playToolAnimation("toolnone", toolTransitionTime, Humanoid)
		return
	end
	if (toolAnim == "Slash") then
		playToolAnimation("toolslash", 0, Humanoid)
		return
	end
	if (toolAnim == "Lunge") then
		playToolAnimation("toollunge", 0, Humanoid)
		return
	end
end

function moveSit()
	RightShoulder.MaxVelocity = 0.15
	LeftShoulder.MaxVelocity = 0.15
	RightShoulder:SetDesiredAngle(3.14 /2)
	LeftShoulder:SetDesiredAngle(-3.14 /2)
	RightHip:SetDesiredAngle(3.14 /2)
	LeftHip:SetDesiredAngle(-3.14 /2)
end

local lastTick = 0

function move(time)
	local amplitude = 1
	local frequency = 1
  	local deltaTime = time - lastTick
  	lastTick = time

	local climbFudge = 0
	local setAngles = false

  	if (jumpAnimTime > 0) then
  		jumpAnimTime = jumpAnimTime - deltaTime
  	end

	if (pose == "FreeFall" and jumpAnimTime <= 0) then
		playAnimation("fall", fallTransitionTime, Humanoid)
	elseif (pose == "Seated") then
		playAnimation("sit", 0.5, Humanoid)
		return
	elseif (pose == "Walking") then
		if Torso.Velocity.Magnitude > 1 then
			playAnimation("walkNorm", 0.2, Humanoid)
		else
			stopAllAnimations()
		end
	elseif (pose == "Running") then
		if Torso.Velocity.Magnitude > 1 then
			playAnimation("runNorm", 0.2, Humanoid)
		else
			stopAllAnimations()
		end
	elseif (pose == "WalkingWeapon") then
		if Torso.Velocity.Magnitude > 1 then
			playAnimation("walkWeapon", 0.2, Humanoid)
		else
			stopAllAnimations()
		end
	elseif (pose == "RunningWeapon") then
		if Torso.Velocity.Magnitude > 1 then
			playAnimation("runWeapon", 0.2, Humanoid)
		else
			stopAllAnimations()
		end
	elseif (pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "Seated" or pose == "PlatformStanding") then
--		print("Wha " .. pose)
		stopAllAnimations()
		amplitude = 0.1
		frequency = 1
		setAngles = true
	elseif (pose == "StandingWeapon") then
		playAnimation("idleWeapon", 0.2, Humanoid)
	elseif (pose == "Standing") then
		setAnimationSpeed(1)
	end

	if (setAngles) then
		local desiredAngle = amplitude * math.sin(time * frequency)

		RightShoulder:SetDesiredAngle(desiredAngle + climbFudge)
		LeftShoulder:SetDesiredAngle(desiredAngle - climbFudge)
		RightHip:SetDesiredAngle(-desiredAngle)
		LeftHip:SetDesiredAngle(-desiredAngle)
	end
end

-- connect events
Humanoid.Died:connect(onDied)
Humanoid.Running:connect(onRunning)
Humanoid.Jumping:connect(onJumping)
Humanoid.Climbing:connect(onClimbing)
Humanoid.GettingUp:connect(onGettingUp)
Humanoid.FreeFalling:connect(onFreeFall)
Humanoid.FallingDown:connect(onFallingDown)
Humanoid.Seated:connect(onSeated)
Humanoid.PlatformStanding:connect(onPlatformStanding)
Humanoid.Swimming:connect(onSwimming)
sprinting.Changed:connect(moveType)
mode.Changed:connect(moveType)

-- setup emote hook
game.Players.LocalPlayer.PlayerScripts:WaitForChild("Events"):WaitForChild("Emote").Event:connect(function(arg)
	if pose == "Standing" then
		playAnimation(string.lower(arg), 0.2, Humanoid)
	end
end)

-- main program

local runService = game:service("RunService")

-- initialize to idle
playAnimation("idle", 0.2, Humanoid)
pose = "Standing"

coroutine.wrap(function()
	while Figure.Parent~=nil do
		local _, time = wait(0.1)
		move(time)
	end
end)()