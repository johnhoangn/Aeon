translator = game:GetService('HttpService')
runService = game:GetService('RunService')
amazon = game:GetService('DataStoreService')
cloudSaves = amazon:GetDataStore('CharacterData')
saveHub = workspace.ServerDomain.SaveHub
players = game.Players
respawncheck = require(script.Parent:WaitForChild('SERVER_CharManagement'):WaitForChild('rChecker')).respawncheck
rmd = game.ReplicatedStorage.RemoteDump

function tInv(save)
	local inv = {}
	local function cols(parent)
		local t = {}
		local columns = parent:GetChildren()
		for _, i in pairs(columns) do
			t[i.Name] = {i.Value, i['#'].Value}
		end
		return t
	end
	for _,i in pairs(save.Inv:GetChildren()) do
		inv[i.Name] = cols(i)
	end
	return inv
end

function dInv(save,source)
	if source.Inv == nil then return end
	for _, i in pairs(save.Inv:GetChildren()) do
		for _, b in pairs(i:GetChildren()) do
			b.Value = source.Inv[i.Name][b.Name][1]
			b['#'].Value = source.Inv[i.Name][b.Name][2]
		end
	end
end

function tEquipped(save)
	local equips = {}
	equips.L = {save.Equipped.L.Value, save.Equipped.L['#'].Value}
	for _, i in pairs(save.Equipped:GetChildren()) do
		if i.Name ~= 'L' then
			equips[i.Name] = i.Value
		end
	end
	return equips
end

function dEquipped(save,source)
	if source.Equipped == nil then return end
	save.Equipped.L.Value = source.Equipped.L[1]
	save.Equipped.L['#'].Value = source.Equipped.L[2]
	for _, i in pairs(save.Equipped:GetChildren()) do
		if i.Name ~= 'L' then
			i.Value = source.Equipped[i.Name]
		end
	end
end

function tProfs(save)
	local profs = {}
	for _, i in pairs(save.Professions:GetChildren()) do
		profs[i.Name] = {i.Value, i.Exp.Value}
	end
	return profs
end

function dProfs(save,source)
	if source.Professions == nil then return end
	for _, i in pairs(save.Professions:GetChildren()) do
		i.Value = source.Professions[i.Name][1]
		i.Exp.Value = source.Professions[i.Name][2]
	end
end

function tAttributes(save)
	local attributes = {}
	for _, i in pairs(save.Attributes:GetChildren()) do
		attributes[i.Name] = i.Value
	end
	attributes.Points = save.Attributes.Value
	return attributes
end

function dAttributes(save,source)
	if source.Attributes == nil then return end
	for _, i in pairs(save.Attributes:GetChildren()) do
		i.Value = source.Attributes[i.Name]
	end
	save.Attributes.Value = source.Attributes.Points
end

function tQuests(save)
	local quests = {}
	for _, i in pairs(save.Quests:GetChildren()) do
		quests[i.Name] = {i.Value, i.Stage.Value}
	end
	return quests
end

function dQuests(save,source)
	if source.Quests == nil then return end
	for _, i in pairs(save.Quests:GetChildren()) do
		i.Value = source.Quests[i.Name][1]
		i.Stage.Value = source.Quests[i.Name][2]
	end
end

--save > inv > column.value | column['#'].Value

local http = game:GetService("HttpService");
local database = "https://kickedbla.000webhostapp.com/";
local password = "&password=sxfbke1999";

function removePlayerData(targetPlayerId, rosterString, pId)
	local a, b = string.find(rosterString,"%["..targetPlayerId.."%]");
	local preTarget = string.sub(rosterString,1,a-1);
	local postTarget = string.sub(rosterString,b+1);
	http:PostAsync(database,"op=updateParty&id=" .. pId .. "&roster=" .. preTarget .. postTarget .. password,2);
end

function promote(rosterString, targetPlayerId, pId)
	local a, b = string.find(rosterString,"%["..targetPlayerId.."%]");
	local preTarget = string.sub(rosterString,1,a-1);
	local postTarget = string.sub(rosterString,b+1);
	local cut = string.sub(rosterString,a,b);
	http:PostAsync(database,"op=updateParty&id=" .. pId .. "&roster=" .. cut .. preTarget .. postTarget .. password,2);
end

function saveData(UserId)
	local save = saveHub[UserId .. 's Save']
	if save:FindFirstChild('Saveable') then
		local s = {}
		s.Inv = tInv(save,'Inv')
		s.Equipped = tEquipped(save)
		s.Professions = tProfs(save)
		s.Attributes = tAttributes(save)
		s.Quests = tQuests(save)
		s.Level = {save.Level.Value, save.Level.Exp.Value}
		s.CQs = save.CQs.Value
		s.Silver = save.Silver.Value
		s.Diamonds = save.Diamonds.Value
		s.Bank = save.Bank.Value
		if (save.Party.Value ~= 0) then
			local teleported = workspace.ServerDomain.PlayersTeleported:FindFirstChild(UserId)
			print(teleported)
			if (teleported ~= nil) then
				-- If the player teleported, keep party data
				s.Party = save.Party.Value
				teleported:Destroy()
				print("keep pid")
			else
				-- Manual exit, assume left the party
				local rosterString = http:PostAsync(database,"op=getParty&id=" .. save.Party.Value,2);
				local rosterTable = {};
				for id in string.gmatch(rosterString,"%[%w*%]") do
					local userId = string.sub(id,2,string.len(id)-1);
					table.insert(rosterTable,userId);
				end
				-- Disband if only two members
				if #rosterTable > 2 then
					removePlayerData(UserId, rosterString, save.Party.Value);
					local leaderId = tonumber(rosterTable[1]);
					-- What if quitter was leader?
					if leaderId == UserId then
						promote(rosterString, rosterTable[math.random(1,#rosterTable)], save.Party.Value);
					end
				else
					for _, player in ipairs(game.Players:GetChildren()) do
						local save = workspace.ServerDomain.SaveHub[player.userId.."s Save"]
						if save.Party.Value == save.Party.Value then
							save.Party.Value = 0
						end
						rmd.LocalEvent:FireClient(player,"PartyIO","updateGUI")
					end
					http:PostAsync(database,"op=disbandParty&id=" .. save.Party.Value .. password, 2);
				end
				s.Party = 0;
				print("erase pid" .. rosterString)
			end
		end
		s.Title = {save.Title.Value,save.Title.Titles.Value}
		local encoded = translator:JSONEncode(s)
		cloudSaves:SetAsync(UserId .. 's Save',encoded)
		--[[if runService:IsStudio() == false then
			local echo = translator:PostAsync("http://aeondatastore.orgfree.com/","operation=uploadPlayerSave" .. "&userId=" .. tostring(UserId) .. "&save=" .. encoded, 2)
		end]]
		--print('Encoded: ' .. encoded)
		save:Destroy();
	end
end

function loadData(player)
	print('Data attempted to load')
	local UserId = player.UserId
	local save = saveHub:WaitForChild(UserId .. 's Save')
	local source = cloudSaves:GetAsync(UserId .. 's Save',true)
	if source == nil then
		local saveable = Instance.new('BoolValue')
		saveable.Name = 'Saveable'
		saveable.Parent = save
		saveData(UserId)
		wait()
		source = cloudSaves:GetAsync(UserId .. 's Save',true)
	end
	local t = Instance.new('StringValue')
	t.Parent = workspace
	t.Value = source
	local success, msg
	local decoded = translator:JSONDecode(source)
	if decoded.Level[1] > 0 then save.Level.Value = decoded.Level[1] else save.Level.Value = 1 end
	success, msg = pcall(function() dInv(save,decoded) end)
	success, msg = pcall(function() dEquipped(save,decoded) end)
	success, msg = pcall(function() dProfs(save,decoded) end)
	success, msg = pcall(function() dAttributes(save,decoded) end)
	success, msg = pcall(function() dQuests(save,decoded) end)
	success, msg = pcall(function() save.CQs.Value = decoded.CQs end)
	success, msg = pcall(function() save.Bank.Value = decoded.Bank end)
	success, msg = pcall(function() save.Diamonds.Value = decoded.Diamonds end)
	success, msg = pcall(function() save.Silver.Value = decoded.Silver end)
	success, msg = pcall(function() save.Level.Exp.Value = decoded.Level[2] end)
	if (decoded.Party ~= nil and decoded.Party > 0) then
		local rosterString = http:PostAsync(database,"op=getParty&id=" .. decoded.Party, 2);
		local rosterTable = {};
		for id in string.gmatch(rosterString,"%[%w*%]") do
			local userId = string.sub(id,2,string.len(id)-1);
			table.insert(rosterTable,userId);
		end
		-- Oh no my friends left me, fix my party value pls
		if #rosterTable >= 2 then
			print("loaded with party" .. rosterString)
			success, msg = pcall(function() save.Party.Value = decoded.Party end)
		else
			print("loaded no party" .. rosterString)
			http:PostAsync(database,"op=disbandParty&id=" .. save.Party.Value .. password, 2);
			success, msg = pcall(function() save.Party.Value = 0 end)
		end
	end
	pcall(function() save.Title.Value = decoded.Title[1] end)
	pcall(function() save.Title.Titles.Value = decoded.Title[2] end)	
	
	if msg ~= nil then
		rmd.LocalServerNotification:FireClient(player,'YOUR SAVE DATA WAS CORRUPTED, A NEW SAVE WILL NOT BE RECORDED; PLEASE INFORM THE DEVELOPER OF THIS ERROR:')
		wait()
		rmd.LocalServerNotification:FireClient(player,msg)
	else
		local saveable = Instance.new('BoolValue')
		saveable.Name = 'Saveable'
		saveable.Parent = save
		print('Data loaded')
	end
end

players.PlayerRemoving:connect(function(child)
	local tempStr = child.Name
	local tempId = child.UserId
	saveData(tempId)
end)

players.ChildAdded:connect(function(child)
	loadData(child)
end)

game.OnClose = function()
	if game.Players:FindFirstChild("Player1") == nil then
		local saves = saveHub:GetChildren()
		for _, i in pairs(saves) do
			local strStop = string.find(i.Name,'s')
			local UserId = string.sub(i.Name,1,strStop-1)
			if workspace.ServerDomain.PlayersTeleported:FindFirstChild(UserId) == nil then
				saveData(UserId)
			end
		end
		wait(1)
	end
end
