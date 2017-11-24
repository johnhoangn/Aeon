rmd = game.ReplicatedStorage.RemoteDump
storage = game.ReplicatedStorage
ref = storage.References
domain = workspace.ServerDomain
respawncheck = require(script:WaitForChild('rChecker')).respawncheck

prechecked = {}

function readSave(child)
	if game.Players:FindFirstChild(child.Name) then
		if domain.SaveHub:FindFirstChild(game.Players[child.Name].UserId .. 's Save') == nil then
			local saveobject = game.ReplicatedStorage.Save:Clone()
			saveobject.Name = game.Players[child.Name].UserId .. 's Save'
			saveobject.Parent = domain.SaveHub
			if check(child.Name) == false then
				saveobject:WaitForChild("Saveable")
				respawncheck(child)
				table.insert(prechecked,child.Name)
			end
		else
			respawncheck(child)
		end
		child:WaitForChild("Head").CollisionGroupId = 1
		child:WaitForChild("Torso").CollisionGroupId = 1
		child:WaitForChild("HumanoidRootPart").CollisionGroupId = 1
		child:WaitForChild("Humanoid").MaxSlopeAngle = 60
		child.Head:WaitForChild("Running").Volume = 0
		for _, s in ipairs(child.Head:GetChildren()) do
			if s.ClassName == "Sound" then
				s.Volume = 0
			end
		end		
	end
end

game.Players.PlayerRemoving:connect(function(player)
	local name = player.Name;
	local checked, index = check(name);
	table.remove(prechecked, index);
end)

workspace.ChildAdded:connect(function(c)
	readSave(c)
end)

function check(search)
	for i, item in pairs(prechecked) do
		if search == item then
			return true, i
		end
	end
	return false
end

for _, i in pairs(game.Players:GetChildren()) do
	if i.Character ~= nil then
		readSave(i.Character)
	end
end
