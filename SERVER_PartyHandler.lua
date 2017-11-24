-- Every few seconds, a check will be run to look for party invitations.
-- Scan the invitations for players in server
-- If any are, fire their partyevent
-- Let their gui handle the rest
hs = game:GetService("HttpService")
debris = game:GetService("Debris")
rmd = game.ReplicatedStorage.RemoteDump
saves = workspace.ServerDomain.SaveHub
players = game.Players:GetChildren()

function inGame(id)
	for _, player in ipairs(game.Players:GetChildren()) do
		if player.userId == id then
			return player
		end
	end
end

function antiSpam(id)
	local r = script.Recipient:Clone()
	r.Name = id
	r.Parent = script.AntiSpam
	debris:AddItem(r,30)
end

game.Players.PlayerAdded:connect(function(p)
	local save = saves:WaitForChild(p.userId.."s Save")
	local sTracker = nil
	sTracker = save:WaitForChild("Party").Changed:connect(function()
		--print("tracker check")
		rmd.LocalEvent:FireClient(p,"PartyIO","checkPartyStatus")
	end)
	--print("tracking " .. p.Name)
end)

workspace.ServerDomain.PartyInvites.ChildAdded:connect(function(inviter)
	local sender = inviter.Value
	local recipient = tonumber(inviter.Name)
	local client = inGame(recipient)
	print("Recipient: "..recipient.." Sender: "..sender)
	if script.AntiSpam:FindFirstChild(recipient) == nil then
		antiSpam(recipient)
		rmd.LocalEvent:FireClient(client,"PartyIO","partyInvite",{Sender = sender})
		-- Fire event
	end
end)

workspace.ChildAdded:connect(function(child)
	local player = game.Players:GetPlayerFromCharacter(child);
	if (player ~= nil) then
		rmd.LocalEvent:FireClient(player,"PartyIO","checkPartyStatus");
	end
end)