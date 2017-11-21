wait(1)
local sDomain = workspace.ServerDomain
local rmd = game.ReplicatedStorage.RemoteDump
local bin = script.Parent
local player = game.Players.LocalPlayer
local save = sDomain.SaveHub:WaitForChild(player.userId.."s Save")
local tpService = game:GetService("TeleportService")

local currentRoster = ""
local rosterTable = {}
local characterTable = {}
local partyId = 0
local yield = false
local wasLeader = false
local wasInParty = false
local clickable = true

local pRequest = bin.Parent:WaitForChild("ContextYesNo")

function checkExisting(override)
	-- Executed every checkPartyStatus event fire
	if yield == false then
		if save.Party.Value > 0 or override ~= nil then
			partyId = save.Party.Value
			if override ~= nil then
				yield = true
				partyId = override
				wait(rmd.RemoteValue:FireServer(save.Party,partyId))
				yield = false
			end
			local roster = rmd.RemoteHttp:InvokeServer("getParty",partyId)
			rosterTable = {}
			currentRoster = roster
			if roster ~= "No Party" and string.find(roster,player.userId) then
				for id in string.gmatch(roster,"%[%w*%]") do
					local userId = string.sub(id,2,string.len(id)-1)
					table.insert(rosterTable,userId)
				end
				--print(table.concat(rosterTable," | "))
				bin.Visible = true
				drawGUI()
				if bin.Parent.BackgroundTransparency == 1 then
					if wasInParty == true and wasLeader == false and tonumber(rosterTable[1]) == player.userId then
						wasLeader = true
						-- Notify promotion
						rmd.RemoteWarning:FireServer("You are now the party leader.")
					elseif wasInParty == false then
						wasInParty = true
						-- Notify joined party
						rmd.RemoteWarning:FireServer("You joined the party.")
					end
				end
			else
				hideGUI()
				if wasInParty == true then
					wasInParty = false
					-- Notify kicked from party
					rmd.RemoteWarning:FireServer("You are no longer in a party.")
				end
			end
			--[[if joinHost == 0 and sameInstance(save.Party.Value) ~= true then
				joinHost = false
				if pRequest.Visible == true then
					repeat
						wait(1)
					until pRequest.Visible == false and bin.Parent.Inventory.Mode.Value == -1
				end
				listener = pRequest.Answer.Event:connect(function(ans)
					if ans == true then
						rmd.RemoteTeleportToPlayer:FireServer(partyId)
					end
					listener:Disconnect()
				end)
			end]]
		else
			partyId = 0
			hideGUI()
			wasInParty = false
			wasLeader = false
		end
	end
end

function disbandParty()
	-- Deletes party data on database, each server should send party disband orders
	-- LEADER ONLY
	rmd.RemoteHttp:InvokeServer("disbandParty",save.Party.Value)
end

function removePlayerData(targetPlayerId)
	-- Redundant method, isolated for ease
	local roster = currentRoster
	local a, b = string.find(roster,"%["..targetPlayerId.."%]")
	local preTarget = string.sub(roster,1,a-1)
	local postTarget = string.sub(roster,b+1)
	rmd.RemoteHttp:InvokeServer("updateParty",partyId,preTarget..postTarget)
	checkExisting()
end

function kick(targetPlayerId)
	-- Removes targetPlayer from the party dataobject, set their party Int to 0 if in the server
	-- LEADER ONLY
	local plySave = sDomain.SaveHub:FindFirstChild(targetPlayerId .. "s Save")
	if plySave ~= nil then
		rmd.RemoteValue:FireServer(plySave.Party,0)
	end
	if #rosterTable > 2 then
		removePlayerData(targetPlayerId)
		local leaderId = tonumber(rosterTable[1])
		if leaderId == player.userId then
			promote(rosterTable[math.random(1,#rosterTable)])
		end
	else
		disbandParty()
	end
end

function promote(targetPlayerId)
	-- LEADER ONLY
	yield = true
	local roster = currentRoster
	local a, b = string.find(roster,"%["..targetPlayerId.."%]")
	local preTarget = string.sub(roster,1,a-1)
	local postTarget = string.sub(roster,b+1)
	local cut = string.sub(roster,a,b)
	roster = cut..preTarget..postTarget
	rmd.RemoteHttp:InvokeServer("updateParty",partyId,roster)
	yield = false
	checkExisting()
end

function leaveParty()
	-- Set party Int to 0 and hide GUI
	-- If leader, pick random member and promote
	hideGUI()
	if #rosterTable > 2 then
		removePlayerData(player.userId)
		local leaderId = tonumber(rosterTable[1])
		if leaderId == player.userId then
			promote(rosterTable[math.random(1,#rosterTable)])
		end
	else
		disbandParty()
	end
end

function sameInstance(targetPlayerId)
	for _, p in ipairs(game.Players:GetChildren()) do
		if p.userId == tonumber(targetPlayerId) then
			return true
		end
	end
end

function sameParty(targetPlayerId)
	for _, p in ipairs(rosterTable) do
		if tonumber(p) == tonumber(targetPlayerId) then
			return true
		end
	end
end

function color3(r,g,b)
	return Color3.new(r/255,g/255,b/255)
end

function drawMember(targetPlayerId,i)
	-- Draws a member in the list
	local leaderId = tonumber(rosterTable[1])
	local height = i*40
	local bar = nil
	if tonumber(targetPlayerId) == leaderId then
		bar = script.Leader:Clone()
	else
		bar = script.Member:Clone()
	end
	if tonumber(targetPlayerId) > 0 then
		bar.PlayerName.Text = game.Players:GetNameFromUserIdAsync(targetPlayerId)
		if sameInstance(targetPlayerId) ~= true then
			bar.PlayerName.TextTransparency = .5
			bar.PlayerName.TextStrokeTransparency = 1
		end
	else
		bar.PlayerName.Text = targetPlayerId
	end
	bar.Position = UDim2.new(0,0,0,height)
	if sameInstance(targetPlayerId) then
		bar.Health.Fill.BackgroundColor3 = color3(223,0,0)
		bar.Stamina.Fill.BackgroundColor3 = color3(17, 255, 0)
		bar.Mana.Fill.BackgroundColor3 = color3(0, 85, 223)
	end
	bar.Parent = bin.Members
	return bar
end

function hideOptions()
	for _, bar in ipairs(bin.Members:GetChildren()) do
		pcall(function() bar.Member.Visible = false end)
		bar.Leader.Visible = false
	end
	clickable = true
end

function drawGUI() 
	-- Draws leader, then members and sets up the click events
	-- First, clear the current GUI
	if save.Party.Value > 0 then
		clickable = true
		for _, member in ipairs(bin.Members:GetChildren()) do
			member:Destroy()
		end
		for i, c in ipairs(characterTable) do
			for _, av in pairs(c) do
				pcall(function() c.Av.hpTracker:Disconnect() end)
				pcall(function() c.Av.spTracker:Disconnect() end)
				pcall(function() c.Av.mpTracker:Disconnect() end)
				pcall(function() c.Av.Died:Disconnect() end)
			end
		end
		characterTable = {}
		for i, userId in ipairs(rosterTable) do
			local bar = drawMember(userId,i-1)
			if bar.Name == "Leader" and player.userId == tonumber(rosterTable[1]) then -- Leader bar
				bar:WaitForChild("Leader")
				bar.Leader.MouseLeave:connect(function()
					hideOptions()
				end)
				bar.MouseButton2Click:connect(function()
					if clickable == false then return end
					clickable = false
					hideOptions()
					bar.Leader.Visible = true
				end)
				-- Party control
				bar.Leader.Disband.MouseButton1Click:connect(function()
					hideGUI()
					rmd.RemoteHttp:InvokeServer("disbandParty",save.Party.Value)
				end)
				bar.Leader.Leave.MouseButton1Click:connect(function()
					leaveParty()
				end)
			else -- Normal member bar
				-- Member control
				if player.userId == tonumber(rosterTable[1]) then
					bar.MouseButton2Click:connect(function()
						if clickable == false then return end
						clickable = false
						hideOptions()
						bar.Leader.Visible = true
					end)
					bar.Leader.Kick.MouseButton1Click:connect(function()
						hideOptions()
						kick(userId)
					end)
					bar.Leader.Promote.MouseButton1Click:connect(function()
						hideOptions()
						promote(userId)
					end)
				else
					if bar.Name == "Member" and bar.PlayerName.Text == player.Name then
						bar:WaitForChild("Member")
						bar.Member.MouseLeave:connect(function()
							hideOptions()
						end)
						bar.MouseButton2Click:connect(function()
							if clickable == false then return end
							clickable = false
							hideOptions()
							bar.Member.Visible = true
						end)
						bar.Member.Leave.MouseButton1Click:connect(function()
							leaveParty()
						end)
					end
				end
			end
			-- HP/SP/MP trackers
			local b, p = sameInstance(userId)
			if p ~= nil then
				local c = p.Character
				local Av = {
					hpTracker = c.ActorValues.Health.Changed:connect(function()
						pcall(function() bar.Health.Fill.Size = UDim2.new(c.ActorValues.Health.Value/c.ActorValues.MaxHealth.Value,0,1,0) end)
					end),
					spTracker = c.ActorValues.Stamina.Changed:connect(function()
						pcall(function() bar.Stamina.Fill.Size = UDim2.new(c.ActorValues.Stamina.Value/c.ActorValues.MaxStamina.Value,0,1,0) end)
					end),
					mpTracker = c.ActorValues.Mana.Changed:connect(function()
						pcall(function() bar.Mana.Fill.Size = UDim2.new(c.ActorValues.Mana.Value/c.ActorValues.MaxMana.Value,0,1,0) end)
					end)
				}
				table.insert(characterTable,Av)
				c.Humanoid.Died:connect(function()
					Av.hpTracker:Disconnect()
					Av.spTracker:Disconnect()
					Av.mpTracker:Disconnect()
					p.CharacterAdded:connect(function()	
						drawGUI()
					end)
				end)
			end
		end
		bin.Size = UDim2.new(0,250,0,20+40*#bin.Members:GetChildren())
	else
		hideGUI()
	end
end

function hideGUI()
	bin.Visible = false
	rmd.RemoteValue:FireServer(save.Party,0)
	for _, member in ipairs(bin.Members:GetChildren()) do
		member:Destroy()
	end
end

-- Sends out requests to the rest of the party to teleport (only applicable to leader) 11.18.17
function teleportRequest()
	-- Fired when the player touches a portal
	-- If leader, send requests to the rest of the party granted every member is in range
	-- If not, ask if s/he wishes to leave the party and go solo into the private dungeon/public zone
end

function drawInvite(senderId)
	local name = senderId
	if tonumber(senderId) > 0 then
		name = game.Players:GetNameFromUserIdAsync(senderId)
	end
	pRequest.Trim.Label.Text = name.." invited you to a party"
	pRequest.Visible = true
	wait(27)
	pRequest.Visible = false
end

function drawTeleportPrompt()
	pRequest.Trim.Label.Text = "Leader requested a teleport"
	pRequest.Visible = true
	wait(27)
	pRequest.Visible = false
end

function sameInstance(targetPlayerId)
	for _, i in ipairs(game.Players:GetChildren()) do
		if i.userId == tonumber(targetPlayerId) then
			return true,i
		end
	end
end

-- Some objects and scripts need to communicate with this script. Handle their requests here.
player.PlayerScripts:WaitForChild("Events").PartyIO.Event:connect(function(request,args)
	--print(request,yield)
	if request == "partyInvite" and save.Party.Value == 0 and yield == false then
		print(args[1]);
		local listener = nil
		local sender = tonumber(args.Sender)
		local yieldControl = true;
		if pRequest.Visible == true then --Wait for previous prompt to be answered
			repeat
				wait(1)
			until pRequest.Visible == false
		end
		yield = true
		listener = pRequest.Answer.Event:connect(function(ans)
			yield = false
			yieldControl = false;
			if ans == true then
				local pId = sDomain.SaveHub[sender.."s Save"].Party.Value
				if pId <= 0 then -- If inviter is not in party, make new party with sender as host
					local roster = "["..sender.."]["..player.userId.."]"
					pId = rmd.RemoteHttp:InvokeServer("setParty",roster)
				else -- Inviter in party, add recipient(localplayer) to party
					local roster = rmd.RemoteHttp:InvokeServer("getParty",pId)
					local numMembers = 0
					for p in string.gmatch(roster,"%[%w+%]") do
						numMembers = numMembers + 1
					end
					--print(roster)
					if numMembers < 6 then
						roster = roster.."["..player.userId.."]"
						rmd.RemoteHttp:InvokeServer("updateParty",pId,roster)
						rmd.RemoteValue:FireServer(save.Party, pId)
					else
						rmd.RemoteWarning:FireServer("Party full!")
					end
				end
				checkExisting(pId)
			end
			rmd.RemoteHttp:InvokeServer("deleteInvite",player.userId)
			listener:Disconnect()
		end)
		drawInvite(sender)
		if (yieldControl == true) then
			yield = false;
			listener:Disconnect()
		end
	elseif request == "checkPartyStatus" then
		checkExisting()
	elseif request == "updateGUI" then
		drawGUI()
	elseif request == "teleportPrompt" then
		local yieldControl = true;
		if pRequest.Visible == true then --Wait for previous prompt to be answered
			repeat
				wait(1)
			until pRequest.Visible == false
		end
		yield = true
		listener = pRequest.Answer.Event:connect(function(ans)
			if ans == true then
				rmd.RemoteValue:FireServer(args, 1);
			elseif ans == false then
				rmd.RemoteValue:FireServer(args, -1);
			end
			yieldControl = false;
			yield = false
			listener:Disconnect()
		end)
		drawTeleportPrompt();
		if (yieldControl == true) then
			yield = false;
			listener:Disconnect()
		end
	end
end)

game.Players.PlayerAdded:connect(function(p)
	if sameParty(p.userId) == true then
		drawGUI()
	end
end)

game.Players.PlayerRemoving:connect(function(p)
	wait(1)
	drawGUI()
end)

bin.MouseLeave:connect(hideOptions)

wait(1)
checkExisting()