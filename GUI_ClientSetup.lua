local p = game.Players.LocalPlayer
local pgui = p:WaitForChild('PlayerGui')
local rmd = game.ReplicatedStorage.RemoteDump
local LW = rmd:WaitForChild('LocalWarning')
local LON = rmd:WaitForChild('LocalOtherNotification')
local LD = rmd:WaitForChild('LocalDeath')
local LS = rmd:WaitForChild('LocalSound')
local LE = rmd:WaitForChild('LocalEvent')

local dead = false
local killProcessing = false
local processTimer = 1/4

local save = workspace.ServerDomain.SaveHub:WaitForChild(p.UserId .. 's Save')
local cam = workspace.CurrentCamera
local events = p.PlayerScripts:WaitForChild('Events')
local professions = save:WaitForChild("Professions")
local ContentProvider = game:GetService("ContentProvider")
local cMethods = require(p.PlayerScripts:WaitForChild('ClientMethods'))
local sceneMethods = require(p.PlayerScripts:WaitForChild('CutsceneMethods'))
local EXPCALC = cMethods.EXPCALC

local connections = {}
local queued = {}

function LoadAsset(item)
	if item.ClassName == 'Animation' then
		ContentProvider:Preload(item.AnimationId)
	elseif item.ClassName == 'Sound' then
		ContentProvider:Preload(item.SoundId)
	end	
end

for A, a in ipairs(game.ReplicatedStorage.Stuff:GetChildren()) do
	for b, B in pairs(a:GetChildren()) do
		if B:FindFirstChild('Stance') then --Tool
			for z, Z in pairs(B.Stance:GetChildren()) do --Stances
				for y, Y in pairs(Z:GetChildren()) do --Stances' Kids
					LoadAsset(Y)
				end
				for y, Y in pairs(Z.Sounds:GetChildren()) do --Stances' Sounds!
					LoadAsset(Y)
				end
			end
		end
	end
end

for _, s in ipairs(game.ReplicatedStorage.Sounds:GetChildren()) do
	LoadAsset("rbxassetid://" .. s.SoundId)
end

function giveExp(str,exp)
	if str == 'Level' then
		local reqExp = EXPCALC(save.Level.Value)
		rmd.RemoteValue:FireServer(save.Level.Exp,save.Level.Exp.Value + exp)
		if save.Level.Exp.Value / reqExp >= 1 then -- lvlup
			local leftOver = save.Level.Exp.Value - EXPCALC(save.Level.Value)
			rmd.RemoteValue:FireServer(save.Level,save.Level.Value + 1)
			rmd.RemoteValue:FireServer(save.Level.Exp,leftOver)
		end
		local nstr = Instance.new('StringValue')
		nstr.Value = '+' .. exp .. ' Character Exp'
		nstr.Parent = p.PlayerGui.Screen.Aspect.NotificationFrame.Notes
	elseif str == "AP" then --Attribute points
		local totLv = 0 --Sum of points in attributes and unused
		local attributes = save.Attributes:GetChildren()
		for _, a in ipairs(attributes) do
			if a.Name ~= "Exp" then
				totLv = totLv + a.Value -1
			end
		end
		totLv = totLv + save.Attributes.Value
		local reqExp = 10 + totLv*5 --Need 5 more APexp per total level to get 1 AP
		local expHave = save.Attributes.Exp.Value + exp
		if expHave >= reqExp then --lvlup
			local leftOver = expHave - reqExp
			rmd.RemoteValue:FireServer(save.Attributes,save.Attributes.Value + 1)
			rmd.RemoteValue:FireServer(save.Attributes.Exp,leftOver)
		else
			rmd.RemoteValue:FireServer(save.Attributes.Exp,expHave)
		end
		local nstr = Instance.new('StringValue')
		nstr.Value = '+' .. exp .. ' ' .. str .. ' Exp'
		nstr.Parent = p.PlayerGui.Screen.Aspect.NotificationFrame.Notes
	else
		local prof = professions[str]
		local reqExp = math.floor(EXPCALC(prof.Value)*100)/100
		local expHave = prof.Exp.Value + exp
		if expHave >= reqExp then --lvlup
			local leftOver = expHave - reqExp
			rmd.RemoteValue:FireServer(prof,prof.Value + 1)
			rmd.RemoteValue:FireServer(prof.Exp,leftOver)
		else
			rmd.RemoteValue:FireServer(prof.Exp,expHave)
		end
		local nstr = Instance.new('StringValue')
		nstr.Value = '+' .. exp .. ' ' .. str .. ' Exp'
		nstr.Parent = p.PlayerGui.Screen.Aspect.NotificationFrame.Notes
	end
end

function push(...)
	table.insert(queued,{...})
end

function pop(t)
	local args = queued[1]
	table.remove(t,1)
	killProcessing = true
	--print(args[1].Name .. ' Was Killed Earlier! Processing Now!')
	giveExp('Level',args[2]*args[3])
	giveExp('AP',args[3])
	wait(processTimer)
	killProcessing = false
	if #queued > 0 then
		pop(queued)
	end
end

table.insert(connections,LW.OnClientEvent:connect(function(val)
	local str = Instance.new('StringValue')
	str.Value = val
	str.Parent = p.PlayerGui.Screen.Aspect.WarningFrame.Warnings
end))

table.insert(connections,LON.OnClientEvent:connect(function(val)
	local str = Instance.new('StringValue')
	str.Value = val
	str.Parent = p.PlayerGui.Screen.Aspect.OtherNotificationFrame.Notes
end))

table.insert(connections,LD.OnClientEvent:connect(function()
	p.PlayerGui.Screen.Aspect.Inventory.Mode.Value = 9
end))

table.insert(connections,LS.OnClientEvent:connect(function(str)
	local s = game.ReplicatedStorage.Sounds[str]:Clone()
	s.Parent = p.PlayerScripts
	s:Play()
	game:GetService("Debris"):AddItem(s,5)
end))

table.insert(connections,LE.OnClientEvent:connect(function(event,...)
	events:WaitForChild(event):Fire(...)
end))

table.insert(connections,events:WaitForChild('Craft').Event:connect(function(obj,str,exp)
	--print'crafted'
	giveExp(str,exp)
	giveExp('Level',exp/5)
end))

table.insert(connections,events:WaitForChild('Gather').Event:connect(function(obj,str,exp)
	--print'gathered'
	giveExp(str,exp)
	giveExp('Level',exp/10)
end))

table.insert(connections,events:WaitForChild('Loot').Event:connect(function(obj,str)
	print('looted' .. str)
end))

table.insert(connections,events:WaitForChild('Kill').Event:connect(function(obj,ratio,exp)
	if not killProcessing then
		killProcessing = true
		--print(obj.Name .. ' Killed! Processing!')
		wait(giveExp('Level',ratio*exp))
		wait(giveExp('AP',exp))
		wait(processTimer)
		killProcessing = false
		if #queued > 0 then
			pop(queued)
		end
	else
		--print(obj.Name .. ' Killed! Queued!')
		push(obj,ratio,exp)
	end
end))

table.insert(connections,events:WaitForChild('DialogueEnd').Event:connect(function(obj)
	print('Finished talking to ' .. obj.Name .. '!')
end))

table.insert(connections,events:WaitForChild('SceneStart').Event:connect(function(scene)
	sceneMethods.startScene(scene)
end))

print'new connections'

local StarterGui = game:GetService('StarterGui')
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

--p.PlayerGui:SetTopbarTransparency(1)

if cam:FindFirstChild('Filter') == nil then
	local f = Instance.new('Part')
	f.Anchored = true
	f.Transparency = 1
	f.CanCollide = false
	f.Name = 'Filter'
	f.Parent = cam
	game.Players.LocalPlayer:GetMouse().TargetFilter = f
else
	game.Players.LocalPlayer:GetMouse().TargetFilter = cam.Filter
end

success = false
repeat
	wait(1)
	success,msg = pcall(function()
		local starterGui = game:GetService('StarterGui')
		starterGui:SetCore("TopbarEnabled", false)
	end)
until success == true

table.insert(connections,p.Character.ActorValues.Health.Changed:connect(function(val)
	if dead == false and val <= 0 then
		dead = true
		p.PlayerScripts.ControlScript.Disabled = true
		p.PlayerGui.Screen.Aspect.Inventory.Mode.Value = 9
		for i = 0, 10 do
			game.Lighting.Blur.Size = i
			wait()
		end
		rmd.RemoteRespawn:FireServer('Home')
		local tempC = nil
		tempC = p.Character.ActorValues.Health.Changed:connect(function(val)
			if val == p.Character.ActorValues.MaxHealth.Value then
				wait(1)
				for i = 10, 0, -1 do
					game.Lighting.Blur.Size = i
					wait()
				end
				wait(1)
				p.PlayerScripts.ControlScript.Disabled = false
				dead = false
				p.PlayerGui.Screen.Aspect.Inventory.Mode.Value = -1
				tempC:disconnect()
			end
		end)
	end
end))

p.Character.Humanoid.Died:connect(function()
	for i ,connection in pairs(connections) do
		connection:disconnect()
	end
	print'deleted connections'
end)