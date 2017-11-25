storage = game.ReplicatedStorage
rmd = storage.RemoteDump
debris = game:GetService('Debris')
runService = game:GetService('RunService')
hs = game:GetService('HttpService')
chatService = game:GetService('Chat') 
tpService = game:GetService('TeleportService')

ref = game.ReplicatedStorage.References
iMethods = require(workspace.ServerDomain.InventoryMethods)
existingTrades = {}

_G.PUBLIC_PLACES = {
	[61751692] = "SpawnLocationA",
}
_G.PRIVATE_PLACES = {
	[61751692] = "SpawnLocationA",
}
_G.DB_PASSWORD = script.PASS.Value;
_G.COMBAT_TIMER = 20
_G.ADMINS = {
	-1, 
	433065, --Me
	917963, --Jason
	67808098, --Len
	615988,	--Christian
	2601136, --Nathan
	29988905, --Justin
	582805, --Andy
	1455880 --Mypi
}
_G['blip'] = function(hit,d,c,b) --hit target, test, color, border?
	local gui = game.ReplicatedStorage.FloatNumber:Clone()
	gui.Parent = workspace.ServerDomain.Temp
	gui.B.Adornee = gui
	gui.Position = hit.Position + Vector3.new(math.random(-2,2),4,math.random(-2,2))
	gui.B.Label.Text = d
	gui.B.Label.TextColor3 = c
	if b then
		gui.B.Label.TextStrokeColor3 = b
	end
	debris:AddItem(gui,1)
	gui.B.Label:TweenPosition(UDim2.new(-1.5, 0, -.5, 0),Enum.EasingDirection.Out,Enum.EasingStyle.Elastic,1)
end

_G['EXPCALC'] = function(lv)
	return math.floor((math.floor(lv + 261.6 * math.pow(2, lv/10))/4)*100)/100
end

_G['effectiveAttribute'] = function(level)
	local softCap = 30
	local reduction = 20
	local deduct = softCap+level-1
	local effective = level*(softCap/deduct)
	return 1 + math.ceil((effective/reduction)*100)/100
end

_G['DamageCalc'] = function(att,def)
	--Weapon calculates effective att
	--This spits out damage.
	local maxMit = def/(3*att)
	--print(att .. ' | ' .. def)	
	
	local preDmg = 1.3 + att
	local noise = math.random(0,math.floor(preDmg/10))
	local dmg = preDmg - preDmg*math.random(0,math.floor(maxMit*100))/100 - noise	
	
	--print(preDmg,dmg,noise)	
	
	if maxMit < 1 then
		return math.floor(dmg)
	else
		if math.random(0,1) == 0 then --you're hopeless anyway, here's a chance at up to 33% damage.
			if math.random(0,1) == 0 then
				return math.floor(preDmg/math.random(3,8)- noise) 
			else
				return 1
			end
		else
			return 0
		end
	end
end

_G['Weld'] = function(x,y,z)
	local weld = Instance.new('Weld') 
	weld.Part0 = x
	weld.Part1 = y
	local HitPos = x.Position
	local CJ = CFrame.new(HitPos) 
	local C0 = x.CFrame:inverse()*CJ 
	local C1 = y.CFrame:inverse()*CJ 
	weld.C0 = C0 
	weld.C1 = C1 
	weld.Parent = x
	if z then 
		weld.Name = z
	end
	x.Anchored = false
end

_G['Glue'] = function(x,y,z)
	local weld = Instance.new('Glue') 
	weld.Part0 = x
	weld.Part1 = y
	local HitPos = x.Position
	local CJ = CFrame.new(HitPos) 
	local C0 = x.CFrame:inverse()*CJ 
	local C1 = y.CFrame:inverse()*CJ 
	weld.C0 = C0 
	weld.C1 = C1 
	weld.Parent = x
	if z then 
		weld.Name = z
	end
end

_G['randopitch'] = function(snd,base,range)
	snd.Pitch = base + math.random(-range,range)/10
end

_G['PlaySound'] = function(obj,snd,base,range,vol)
	local s, e = pcall(function()
		local so = game.ReplicatedStorage.Sounds[snd]:Clone()
		so.Parent = obj
		so.Pitch = base + math.random(-range,range)/10
		if vol ~= nil then
			so.Volume = vol
		end
		so:Play()
		debris:AddItem(so,10)
	end)
	if not s then
		print(e)
	end
end

_G['checkactor'] = function(hit,search)
	--print(hit)
	if hit == nil then return nil end
	local actor = nil
	if (hit.Parent:FindFirstChild(search)) then
		actor = hit.Parent
	elseif (hit.Parent.Parent ~= nil and hit.Parent.Parent:FindFirstChild(search)) then
		actor = hit.Parent.Parent
	elseif (hit.Parent.Parent ~= nil and hit.Parent.Parent.Parent ~= nil and hit.Parent.Parent.Parent:FindFirstChild(search)) then
		actor = hit.Parent.Parent.Parent
	elseif (hit.Parent.Parent ~= nil and hit.Parent.Parent.Parent ~= nil and hit.Parent.Parent.Parent.Parent ~= nil
			and hit.Parent.Parent.Parent.Parent:FindFirstChild(search)) then
		actor = hit.Parent.Parent.Parent.Parent
	elseif (hit.Parent.Parent ~= nil and hit.Parent.Parent.Parent ~= nil and hit.Parent.Parent.Parent.Parent ~= nil
			and hit.Parent.Parent.Parent.Parent.Parent ~= nil and hit.Parent.Parent.Parent.Parent.Parent:FindFirstChild(search)) then
		actor = hit.Parent.Parent.Parent.Parent.Parent
	elseif (hit.Parent.Parent ~= nil and hit.Parent.Parent.Parent ~= nil and hit.Parent.Parent.Parent.Parent ~= nil
			and hit.Parent.Parent.Parent.Parent.Parent ~= nil and hit.Parent.Parent.Parent.Parent.Parent.Parent ~= nil 
			and hit.Parent.Parent.Parent.Parent.Parent.Parent:FindFirstChild(search)) then
		actor = hit.Parent.Parent.Parent.Parent.Parent.Parent
	end
	if actor ~= nil then
		return actor
	else
		return nil
	end
end


_G['getID'] = function(str)
	for _, i in pairs(game.ReplicatedStorage.References:GetChildren()) do
		if i.Value == str then
			print(i.Name)
		end
	end
end

function playerFromId(id)
	for _, p in pairs(game.Players:GetChildren()) do
		if tostring(p.UserId) == tostring(id) then
			return p
		end
	end
end

function newrm(type,name)
	local rmf = Instance.new(type)
	rmf.Name = name
	rmf.Parent = rmd
	return rmf
end

--Local EVENT
newrm('RemoteEvent','LocalEvent')
--Local WARNING
newrm('RemoteEvent','LocalWarning')
--Local WARNING
newrm('RemoteEvent','LocalOtherNotification')
--Local SOUND
newrm('RemoteEvent','LocalSound')
--Local NOTIFICATION
newrm('RemoteEvent','LocalServerNotification')
--GLOBALCHATUPDATE
newrm('RemoteEvent','LocalGlobalChat')
--Die Mode to 9
newrm('RemoteEvent','LocalDeath')

--Returns a clone of an object
rCLONE=newrm('RemoteFunction','RemoteClone')
function rCLONE.OnServerInvoke(client,obj,name,parent,extra)
	local object = obj:Clone()
	if name ~= nil then
		object.Name = name
	end
	if extra ~= nil then
		for key, v in pairs(extra) do
			if key == "Delete" then
				debris:AddItem(object,v)
			elseif key == "ModelCFrame" then
				object:SetPrimaryPartCFrame(v)
			elseif key == "Position" then
				object.Position = v
			elseif key == "ModelCFrameStick" then
				object:SetPrimaryPartCFrame(v[2])
				_G.Weld(object.PrimaryPart,v[1])
			end
		end
	end
	if parent == nil then
		object.Parent = workspace.ServerDomain.Temp
	else
		object.Parent = parent
	end
	return object
end	
--Returns an instance of an object
rINSTANCE=newrm('RemoteFunction','RemoteInstance')
function rINSTANCE.OnServerInvoke(client,str,name,parent,value)
	local object = Instance.new(str)
	object.Parent = workspace.ServerDomain.Temp
	if name ~= nil then
		object.Name = name
	end
	if value ~= nil then
		object.Value = value
	end
	if parent ~= nil then
		object.Parent = parent
	end
	--print(object,parent)
	return object
end	
--Checks actors
rCA=newrm('RemoteFunction','RemoteCheckActor')
function rCA.OnServerInvoke(client,hit,search)
	if hit == nil or hit.Name == 'Handle' then return nil end
	if (hit.Parent:FindFirstChild(search)) then
		return hit.Parent
	elseif (hit.Parent ~= workspace and hit.Parent.Parent:FindFirstChild(search)) then
		return hit.Parent.Parent
	elseif (hit.Parent ~= workspace and hit.Parent.Parent ~= workspace and hit.Parent.Parent.Parent:FindFirstChild(search)) then
		return hit.Parent.Parent.Parent
	elseif (hit.Parent ~= workspace and hit.Parent.Parent ~= workspace and hit.Parent.Parent.Parent ~= workspace 
		and hit.Parent.Parent.Parent.Parent:FindFirstChild(search)) then
		return hit.Parent.Parent.Parent.Parent
	else 
		return nil
	end
end
--Checks if admin
rAC=newrm('RemoteFunction','RemoteAdminCheck')
function rAC.OnServerInvoke(client,check)
	for _, admin in pairs(_G.ADMINS) do
		if admin == check then
			return true
		end
	end
	return false
end
--Handles trade hosts
rTRADEHOST=newrm('RemoteFunction','RemoteTradeHost')
function rTRADEHOST.OnServerInvoke(player,p1,p2)
	local tradeHost = workspace.ServerDomain.TradeStuff.TradeHost:Clone()
	tradeHost.Name = p1 ..'|'.. p2
	tradeHost.OfferA.Name = p1
	tradeHost.OfferB.Name = p2
	tradeHost.Requester.Value = player
	local player1 = playerFromId(p1)
	local player2 = playerFromId(p2)
	local save1 = workspace.ServerDomain.SaveHub[p1 .. 's Save']
	local save2 = workspace.ServerDomain.SaveHub[p2 .. 's Save']
	tradeHost.Parent = workspace.ServerDomain.TradeZone
	existingTrades[tradeHost.Name] = tradeHost.Changed:connect(function(val)
		if val == 'Rejected' or val == 'Aborted' then
			tradeHost.Name = 'PENDING DELETION'
			wait(5)
			tradeHost:Destroy()
		elseif val == 'Confirmed' then
			local give1 = {}
			local give2 = {}
			for _, offer in pairs(tradeHost[p1].Items:GetChildren()) do
				if give1[offer.Value] == nil then
					give1[offer.Value] = offer['#'].Value
				else
					give1[offer.Value] = give1[offer.Value] + offer['#'].Value
				end
			end
			for _, offer in pairs(tradeHost[p2].Items:GetChildren()) do
				if give2[offer.Value] == nil then
					give2[offer.Value] = offer['#'].Value
				else
					give2[offer.Value] = give2[offer.Value] + offer['#'].Value
				end
			end
			for k, offer in pairs(give1) do
				iMethods.giveItem(player2,k,offer)
				iMethods.takeItem(player1,k,offer)
			end
			for k, offer in pairs(give2) do
				iMethods.giveItem(player1,k,offer)
				iMethods.takeItem(player2,k,offer)
			end
			save1.Silver.Value = save1.Silver.Value + tradeHost[p2].Silver.Value - tradeHost[p1].Silver.Value
			save2.Silver.Value = save2.Silver.Value + tradeHost[p1].Silver.Value - tradeHost[p2].Silver.Value
			tradeHost.Name = 'PENDING DELETION'
			wait(5)
			pcall(function() existingTrades[tradeHost.Name]:Disconnect() end)
			existingTrades[tradeHost.Name] = nil
			tradeHost:Destroy()
		end
	end)
	local ABORT = false
	local breaker1 = nil
	breaker1 = game.Players.PlayerRemoving:connect(function(p)
		if p == player1 or p == player2 then
			tradeHost.Value = "Aborted"
			ABORT = true
			breaker1:Disconnect()
		end
	end)
	local breaker2 = nil
	breaker2 = player1.Character.Humanoid.Died:connect(function()
		tradeHost.Value = "Aborted"
		ABORT = true
		breaker2:Disconnect()
	end)
	local breaker3 = nil
	breaker3 = player2.Character.Humanoid.Died:connect(function()
		tradeHost.Value = "Aborted"
		ABORT = true
		breaker3:Disconnect()
	end)
	local breaker4 = coroutine.wrap(function()
		while tradeHost ~= nil and ABORT == false do
			if (player1.Character.PrimaryPart.Position-player2.Character.PrimaryPart.Position).magnitude >= 15 
					or player1.Character == nil
					or player2.Character == nil then
				tradeHost.Value = "Aborted"
				break
			end
			wait(1/4)
		end
	end)
	breaker4()
	return tradeHost
end
--HandlesHTTPRequests
rHTTP = newrm('RemoteFunction','RemoteHttp')
database = "https://kickedbla.000webhostapp.com/"
password = _G.DB_PASSWORD;
function rHTTP.OnServerInvoke(client,op,val,val2,val3)
	--print(op,val,val2,val3)
	if op == 'list' then
		return hs:PostAsync(database,"op=list",2)
	elseif op == 'buy' then
		return hs:PostAsync(database,"op=buy" .. "&num=" .. val .. "&id=" .. val2 .. password,2)
	elseif op == 'sell' then
		return hs:PostAsync(database,"op=sell" .. "&amount=" .. val .. "&item='" .. val2 .. "'&each=" .. val3 .. "&seller=" .. client.UserId .. password,2)
	elseif op == 'history' then
		return hs:PostAsync(database,"op=history",2)
	elseif op == 'collect' then
		return hs:PostAsync(database,"op=collect" .. "&id=" .. val .. password,2)
	elseif op == 'cancel' then
		return hs:PostAsync(database,"op=cancel" .. "&id=" .. val .. password,2)
	elseif op == 'numListings' then
		return hs:PostAsync(database,"op=numListings" .. "&seller=" .. client.UserId,2)
	elseif op == 'listedBy' then
		return hs:PostAsync(database,"op=listedBy" .. "&seller=" .. client.UserId,2)
	elseif op == 'check' then
		local success, msg = pcall(function() hs:PostAsync(database,"op=list",2) end)
		return success
	elseif op == 'sendInvite' then
		if script.Parent.SERVER_PartyHandler.AntiSpam:FindFirstChild(val) == nil then
			local invite = script.Parent.SERVER_PartyHandler.Invitation:Clone()
			invite.Name = val
			invite.Value = tostring(client.userId)
			invite.Parent = workspace.ServerDomain.PartyInvites
			debris:AddItem(invite,25)
		else
			rmd.LocalWarning:FireClient(client,"Invitation pending")
		end
	elseif op == 'checkInvites' then
		return hs:PostAsync(database,"op=".. op .. "&id=" .. val,2)	
	elseif op == 'deleteInvite' then
		local s, e = pcall(function() 
			workspace.ServerDomain.PartyInvites[val]:Destroy()			
		end)
		if not s then 
			print(e,client,val)
		end
	elseif op == 'setParty' then
		local id = tonumber(hs:PostAsync(database,"op=".. op .. "&roster=" .. val  .. password,2))
		for _, player in ipairs(game.Players:GetChildren()) do
			if string.find(val,"["..player.userId.."]") ~= nil then
				local save = workspace.ServerDomain.SaveHub[player.userId.."s Save"]
				if save.Party.Value ~= id then
					save.Party.Value = id
					wait(1)
					rmd.LocalEvent:FireClient(player,"PartyIO","checkPartyStatus")
					print("Global "..save.Party.Value.."|"..id)
				else
					rmd.LocalEvent:FireClient(player,"PartyIO","updateGUI")
				end
			end
		end
		return id
	elseif op == 'getPartyId' then
		return hs:PostAsync(database,"op=".. op .. "&id=" .. val,2)
	elseif op == 'getParty' then
		local roster = hs:PostAsync(database,"op=".. op .. "&id=" .. val,2)
		--print(roster)
		return roster
	elseif op == 'getAccessCode' then
		local code = hs:PostAsync(database,"op=".. op .. "&id=" .. val,2)
		--print(roster)
		return code
	elseif op == 'updateParty' then
		for _, player in ipairs(game.Players:GetChildren()) do
			if workspace.ServerDomain.SaveHub[player.userId.."s Save"].Party.Value == val then
				rmd.LocalEvent:FireClient(player,"PartyIO","checkPartyStatus")
			end
		end
		return hs:PostAsync(database,"op=".. op .. "&id=" .. val .. "&roster=" .. val2 .. password,2)
	elseif op == 'disbandParty' then
		for _, player in ipairs(game.Players:GetChildren()) do
			local save = workspace.ServerDomain.SaveHub[player.userId.."s Save"]
			if save.Party.Value == val then
				save.Party.Value = 0
			end
			rmd.LocalEvent:FireClient(player,"PartyIO","updateGUI")
		end
		return hs:PostAsync(database,"op=".. op .. "&id=" .. val .. password,2)
	end
end
--Handles client-side bank withdrawals to prevent timing out with remote-calls. Also more efficient.
rWithdraw = newrm("RemoteFunction","RemoteWithdraw")
function rWithdraw.OnServerInvoke(client,id,amt)
	local save = workspace.ServerDomain.SaveHub[client.UserId .. 's Save']
	local slotsWith = {}
	local have = 0
	local debt = 1
	if amt ~= nil then
		debt = amt
	end
	for _, row in pairs(save.Inv:GetChildren()) do
		for _, col in pairs(row:GetChildren()) do
			if col.Value == tonumber(id) and col['#'].Value > 0 then
				table.insert(slotsWith,col)
				have = have + col['#'].Value
			end
		end
	end
	for _, slot in pairs(slotsWith) do --Per each indexed slot, do we have enough to satisfy the debt?
		if debt >= slot['#'].Value then 	--No, we don't, so take what it has and move to the next
			debt = debt - slot['#'].Value
			slot['#'].Value = 0
		else	--Debt satisified
			slot['#'].Value = slot['#'].Value - debt
			debt = 0
		end
	end	
	return amt - debt
end
--Handles networkset
newrm('RemoteEvent','RemoteNetworkOwner').OnServerEvent:connect(function(client,obj)
	if obj.ClassName == 'Model' then
		for _, i in pairs(obj:GetChildren()) do
			if i:IsA('BasePart') then
				i:SetNetworkOwner(client)
			end
		end
	else
		obj:SetNetworkOwner(client)
	end
end)
--Changes "Name"
newrm('RemoteEvent','RemoteName').OnServerEvent:connect(function(client,obj,str)
	obj.Name = str
end)
--Changes "Velocity"
newrm('RemoteEvent','RemoteVelocity').OnServerEvent:connect(function(client,obj,v)
	obj.Velocity = v
end)
--Changes "RotVelocity"
newrm('RemoteEvent','RemoteRotVelocity').OnServerEvent:connect(function(client,obj,v)
	obj.RotVelocity = v
end)
--Changes "Value"
newrm('RemoteEvent','RemoteValue').OnServerEvent:connect(function(client,obj,value)
	--if obj.Parent.Name == "Quests" or obj.Parent.Parent.Name == "Quests" then print("Setting " .. obj.Name .. " to " .. tostring(value)) end
	if obj.ClassName == 'IntValue' or obj.ClassName == 'NumberValue' then
		if tonumber(value) <= 999999999 then
			obj.Value = tonumber(value)
		else
			obj.Value = 999999999
		end
	else
		obj.Value = value
	end
end)
--Changes "Parent"
newrm('RemoteEvent','RemoteParent').OnServerEvent:connect(function(client,obj,parent)
	if parent == nil then
		obj.Parent = nil
		wait(1)
		obj:Destroy()
	else
		if parent == workspace.PlayerDrops then
			local parts = obj:GetChildren()
			if not obj.PrimaryPart then obj.PrimaryPart = obj:FindFirstChildOfClass("Part") end
			for _, part in ipairs(parts) do
				if part:IsA("BasePart") then
					part.CollisionGroupId = 2
					part.CanCollide = true
					_G.Weld(part,obj.PrimaryPart)
					part.Anchored = false
				end
			end
			obj.PrimaryPart.Anchored = false
		end
		obj.Parent = parent
	end
end)
--Changes "ModelCFrame"
newrm('RemoteEvent','RemotePrimaryPartCFrame').OnServerEvent:connect(function(client,obj,cframe)
	obj:SetPrimaryPartCFrame(cframe)
end)
--Moves models
newrm('RemoteEvent','RemoteMoveTo').OnServerEvent:connect(function(client,obj,vector3)
	obj:MoveTo(vector3)
end)
--Changes "Disable"
newrm('RemoteEvent','RemoteDisable').OnServerEvent:connect(function(client,obj,bool)
	obj.Disabled = bool
end)
--Changes "angularvelocity"
newrm('RemoteEvent','Remoteangularvelocity').OnServerEvent:connect(function(client,obj,vector3)
	obj.angularvelocity = vector3
end)
--Changes "position"
newrm('RemoteEvent','Remoteposition').OnServerEvent:connect(function(client,obj,vector3)
	obj.position = vector3
end)
--Changes "MaxForce"
newrm('RemoteEvent','RemoteMaxForce').OnServerEvent:connect(function(client,obj,vector3)
	obj.MaxForce = vector3
end)
--Changes "Transparency"
newrm('RemoteEvent','RemoteTransparency').OnServerEvent:connect(function(client,obj,int)
	obj.Transparency = int
end)
--Adds trade offers
newrm('RemoteEvent','RemoteTradeOffer').OnServerEvent:connect(function(client,id,num,row,col,host)
	local offer = workspace.ServerDomain.TradeStuff.Item:Clone()
	offer.Value = id
	offer['#'].Value = num
	offer.Row.Value = row
	offer.Column.Value = col
	offer.Parent = host[tostring(client.UserId)].Items
end)
--Handles blips
newrm('RemoteEvent','RemoteBlip').OnServerEvent:connect(function(client,hit,d,c)
	return _G.blip(hit,d,c)
end)
--Handles Whispers
newrm('RemoteEvent','RemoteWhisper').OnServerEvent:connect(function(client, recipient, chat)
	--[[if recipient.Save.Blocklist find client then 
		
	end]]
	rmd.LocalServerNotification:FireClient(recipient, chat)
end)
--Handles Warning Requests from client
newrm('RemoteEvent','RemoteWarning').OnServerEvent:connect(function(client, chat)
	rmd.LocalWarning:FireClient(client, chat)
end)
--Handles client requests to swap zones
newrm('RemoteEvent','RemoteTeleport').OnServerEvent:connect(function(client, placeId)
	tpService:Teleport(placeId,client)
end)
--Handles client requests to follow another player
newrm('RemoteEvent','RemoteTeleportToPlayer').OnServerEvent:connect(function(client, targetId)
	local _,_,targetZone,instance = tpService:GetPlayerPlaceInstanceAsync(targetId)
	if targetZone == game.PlaceId then
		tpService:TeleportToPlaceInstance(targetZone,instance,client)
	else
		rmd.LocalWarning:FireClient(client, "Must be in the same zone!")
	end
end)
--Handles client requests to move a party to a private zone
newrm('RemoteEvent','RemotePartyTeleport').OnServerEvent:connect(function(client, placeId, roster)
	local key = tpService:ReserveServer(placeId)
	tpService:TeleportToPrivateServer(placeId,key,roster)
end)
--Handles Client Requests to change inventory slot data
newrm('RemoteEvent','RemoteSlot').OnServerEvent:connect(function(client, slotData, itemId, num)
	if num > 0 then
		slotData.Value = itemId
	else
		slotData.Value = 0
	end
	if slotData:FindFirstChild('#') then
		if num > 0 then
			slotData['#'].Value = num
		else
			slotData['#'].Value = -1
		end
	end
end)
--Handles Client Requests to equip items
newrm('RemoteEvent','RemoteEquip').OnServerEvent:connect(function(client, t, obj)
	local eFolder = client.Character.Equip[t]
	for _, i in ipairs(eFolder:GetChildren()) do
		if i:FindFirstChild('Disable') then
			i.Disable.Value = not i.Disable.Value
		end
		if i:FindFirstChild('CleanUp') then
			i.CleanUp.Value = not i.CleanUp.Value
		end
		i:Destroy()
	end
	local item = obj:Clone()
	item.Parent = eFolder
	for _, i in ipairs (item:GetChildren()) do
		if i.ClassName == 'Script' then
			i.Disabled = false
		elseif i.ClassName == 'Model' then
			for _, z in ipairs(i:GetChildren()) do
				if z.ClassName == 'Script' then
					z.Disabled = false
				end
			end
		end
	end
	if item:FindFirstChild("DropModel") then
		item.DropModel:Destroy()
	end
end)
--Handles Global Chat
newrm('RemoteEvent','RemoteChatServer').OnServerEvent:connect(function(client, chat)
	local msgs = 0
	local errd = false
	for _,msg in pairs(workspace.ServerDomain.GlobalChat:GetChildren()) do
		if msg.Name == client.Name then
			msgs = msgs + 1
		end
	end
	if msgs <= 3 and workspace.ServerDomain.GlobalChat:FindFirstChild(client.Name) == nil then
		if runService:IsStudio() then
			-- FilterStringAsync does not work in Studio
			rmd.LocalGlobalChat:FireAllClients(client,chat)
		else
			for _, player in pairs(game.Players:GetChildren()) do
				if player ~= client then
					local success, filteredMessage = pcall(function() return chatService:FilterStringAsync(chat, client, player) end)
					if success then
						rmd.LocalGlobalChat:FireClient(player,client,filteredMessage)
					else
						if errd == false then
							errd = true
							rmd.LocalServerNotification:FireClient(client,'Your message was not sent because ROBLOX failed to filter your message.')
							rmd.LocalServerNotification:FireClient(client,'Notify an admin of this: ' .. filteredMessage)
						end
					end
				end
			end
			rmd.LocalGlobalChat:FireClient(client,client,chat)
		end
		local antispam = Instance.new('BoolValue')
		antispam.Name = client.Name
		antispam.Parent = workspace.ServerDomain.GlobalChat
		debris:AddItem(antispam,3)
	else
		local antispam = Instance.new('BoolValue')
		antispam.Name = client.Name
		antispam.Parent = workspace.ServerDomain.GlobalChat
		debris:AddItem(antispam,3)
		rmd.LocalServerNotification:FireClient(client, 'DO NOT SPAM THE CHAT!')
	end
end)

--Handles respawns
rRESPAWN=newrm('RemoteEvent','RemoteRespawn').OnServerEvent:connect(function(client, location)
	local character = client.Character
	local fountain = workspace.ServerDomain.Spawns[location].Fountain
	local deg = math.random(0,360)
	local rad = math.rad(deg)
	local ray = Ray.new(fountain.PrimaryPart.Position,Vector3.new(math.cos(rad),0,math.sin(rad)))
	--print(deg .. ' ' .. tostring(math.cos(rad)) .. ',' .. tostring(math.sin(rad)))
	local dist = math.random(10,20)
	character:MoveTo(fountain.PrimaryPart.Position+ray.Direction*dist)
	wait(2)
	character.ActorValues.Health.Value = character.ActorValues.MaxHealth.Value
	for _,i in pairs(character.Humanoid:GetPlayingAnimationTracks()) do
		i:Stop()
	end
end)
--Handles local calls for welding
rWELD=newrm('RemoteEvent','RemoteWeld').OnServerEvent:connect(function(client,model,z)
	for _, i in pairs(model:GetChildren()) do
		if i:isA('BasePart') then
			local weld = Instance.new('Weld') 
			weld.Part0 = i
			weld.Part1 = model.PrimaryPart
			local HitPos = i.Position
			local CJ = CFrame.new(HitPos) 
			local C0 = i.CFrame:inverse()*CJ 
			local C1 = model.PrimaryPart.CFrame:inverse()*CJ 
			weld.C0 = C0 
			weld.C1 = C1 
			weld.Parent = i
			if z then 
				weld.Name = z
			end
			i.Anchored = false
		end
	end
	for _, i in pairs(model:GetChildren()) do
		if i:IsA('BasePart') then
			i:SetNetworkOwner(client)
		end
	end
	model.PrimaryPart.Anchored = false
end)
--Handles sitting
rSeat=newrm("RemoteEvent","RemoteSeat").OnServerEvent:connect(function(client,chair)
	client.Character.Torso.CFrame = chair.Torso.CFrame
	local weld = Instance.new("Weld")
	weld.Parent = chair.Torso
	weld.Part0 = chair.Torso
	weld.Part1 = client.Character.Torso
	weld.Name = "Seat"
	local weldRef = Instance.new("ObjectValue")
	weldRef.Name = "Seat"
	weldRef.Parent = client.Character.Torso
	weldRef.Value = weld
	client.Character.Humanoid.Sit = true
end)
--Plays sounds at request of client
rSound = newrm("RemoteEvent","RemoteSound").OnServerEvent:connect(function(client,obj,snd,base,range,vol)
	_G.PlaySound(obj,snd,base,range,vol)
end)
--Teleports at request of client via server-dealt prompt
rSound = newrm("RemoteEvent", "RemoteTeleport").OnServerEvent:connect(function(client, placeId, accessCode)
	if (accessCode == nil) then
		tpService:TeleportToSpawnByName(placeId, _G.PUBLIC_PLACES[placeId], client);
	else
		tpService:TeleportToPrivateServer(placeId, accessCode, {client}, _G.PRIVATE_PLACES[placeId]);
	end
end)

finished = Instance.new('BoolValue')
finished.Name = 'Globals Finished'
finished.Parent = workspace.ServerDomain