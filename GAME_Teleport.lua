-- FIRST CHECK IF PLAYER IS IN A PARTY
-- CHECK IF S/HE IS HOST
-- IF LEADER PROMPT REQUESTS TO MEMBERS, WHEN ALL ACCEPTED SEND IN
-- IF ANY DECLINED, ABORT TELEPORT, LET LEADER HANDLE SITUATION
-- IF NOT LEADER, ASK TO LEAVE PARTY AND GO SOLO OR ABORT TELEPORT

local database = "https://kickedbla.000webhostapp.com/";
local hs = game:GetService("HttpService");
local tp = game:GetService("TeleportService");

local rmd = game.ReplicatedStorage.RemoteDump;
local bin = script.Parent;
local portal = bin.Portal;
local config = bin.Config;
local placeId = config.Place.Value;
local destination = config.Destination.Value;
local isPrivate = config.Private.Value;
local iDebCD = 5;
local teleportTimeout = 30;
local teleportRange = 30;

local debouncing = {};

function main(part)
	local player = game.Players:GetPlayerFromCharacter(part.Parent);
	if (player ~= nil and not iDebounce(player)) then
		local save = getSave(player);
		print("is player and not cd");
		if (inParty(save)) then
			print("in party");
			local roster = getRoster(save.Party.Value);
			if (isHost(player, roster)) then
				if (partyInRange(player, roster)) then
					promptParty(player, roster);
				else
					rmd.LocalWarning:FireClient(player, "Party member(s) not in range");
				end
			else
				rmd.LocalWarning:FireClient(player, "Only the party leader may start teleports");
			end
		else
			print("solo tp");
			teleportSolo(player);
		end
	end
end

function iDebounce(player) 
	for _, p in ipairs(debouncing) do
		if (p == player) then
			return true
		end
	end
	coroutine.wrap(function() 
		table.insert(debouncing,player);
		local insertedAt = debouncing.length;
		wait(iDebCD);
		table.remove(debouncing,insertedAt);
	end)();
	return false;
end

function getSave(player)
	return workspace.ServerDomain.SaveHub:FindFirstChild(player.userId.."s Save");
end

function inParty(save) 
	return save.Party.Value ~= 0;
end

function partyInRange(hostPlayer, roster)
	for _, id in ipairs(roster) do
		local player = game.Players:GetPlayerByUserId(id);
		if (player ~= nil and hostPlayer:DistanceFromCharacter(player.Character.Torso.Position) > teleportRange) then
			return false;
		end
	end
	return true;
end

function isHost(player, roster)
	local hostId = roster[1];
	print("player: " .. player.userId .. " | host: " .. hostId);
	if (player.userId == hostId) then
		return true;
	end	
end

function getRoster(pId)
	local roster = hs:PostAsync(database,"op=getParty&id=" .. pId,2);
	local rosterTable = {};
	print(roster);
	for id in string.gmatch(roster,"%[%w*%]") do
		print(id);
		local userId = tonumber(string.sub(id,2,string.len(id)-1));
		table.insert(rosterTable,userId);
	end
	return rosterTable;
end

function teleportParty(hostPlayer, roster)
	-- Tell the server that these players are teleporting; do not set their party value to 0
	for _, playerId in ipairs(roster) do
		local teleported = Instance.new("BoolValue");
		teleported.Name = playerId;
		teleported.Parent = workspace.ServerDomain.PlayersTeleported;
	end
	if (not isPrivate) then
		-- Teleport the host then make the members follow
		for i, playerId in ipairs(roster) do
			local player = game.Players:GetPlayerByUserId(playerId)
			if (i == 1) then
				tp:TeleportToSpawnByName(placeId, destination, player);
			else
				coroutine.wrap(function()
					rmd.LocalWarning:FireClient(player, "Teleporting in 5 seconds");
					wait(5);
					for attempt = 1, 5 do
						local b, errorMsg, leaderPlaceId, instanceId;
						local s, msg = pcall(function() b, errorMsg, leaderPlaceId, instanceId = tp:GetPlayerPlaceInstanceAsync(roster[1]) end)
					    if (s and tonumber(leaderPlaceId) == tonumber(placeId)) then
					        tp:TeleportToPlaceInstance(placeId, instanceId, player, destination);
							break;
					    else
							if (attempt == 5) then
								rmd.LocalWarning:FireClient(player, "Teleport aborted; leader possibly closed his/her game");
								wait(2)
								rmd.LocalWarning:FireClient(player, "Party disbanded");
								local save = workspace.ServerDomain.SaveHub[player.userId.."s Save"]
								for _, player in ipairs(game.Players:GetChildren()) do
									if save.Party.Value == save.Party.Value then
										save.Party.Value = 0
									end
									rmd.LocalEvent:FireClient(player,"PartyIO","updateGUI")
								end
								hs:PostAsync(database,"op=disbandParty&id=" .. save.Party.Value .. _G.DB_PASSWORD, 2);
								break;
							else
								rmd.LocalWarning:FireClient(player, "Leader hasn't loaded yet; trying again in 5 seconds (" .. attempt .. "/5)");
							end
					    end
						wait(5);
					end
				end)();
			end
		end
	else
		local reserveCode = tp:ReserveServer(placeId);
		local playerList = {};
		for _, id in ipairs(roster) do
			table.insert(playerList,game.Players:GetPlayerByUserId(id));
		end
		hs:PostAsync(database,"op=setAccessCode&id=" .. getSave(hostPlayer).Party.Value .. "&accessCode=" .. reserveCode .. _G.DB_PASSWORD, 2);
		
		tp:TeleportToPrivateServer(placeId, reserveCode, playerList, destination);
	end
end

function checkPromptListener(listener)
	local decision = 1;
	for _, prompt in ipairs(listener:GetChildren()) do
		if (prompt.Value == -1) then
			return -1;
		elseif (prompt.Value == 0) then
			decision = 0;
		end
	end
	return decision;
end

function makePromptListener(roster)
	local listener = Instance.new("Folder");
	listener.Name = roster[1];
	listener.Parent = workspace.ServerDomain.PartyTeleportPrompts;
	
	for i, id in ipairs(roster) do
		if (i > 1) then
			local prompt = Instance.new("IntValue");
			prompt.Name = id;
			prompt.Parent = listener;
			
			local player = game.Players:GetPlayerByUserId(id);
			rmd.LocalEvent:FireClient(player, "PartyIO", "teleportPrompt", prompt);
		end
	end

	return listener; 
end

function promptParty(hostPlayer, roster)
	local timer = 0;
	local listener = makePromptListener(roster);
	
	while (timer < teleportTimeout) do
		if (checkPromptListener(listener) == 1) then
			teleportParty(hostPlayer, roster);
			break;
		elseif (checkPromptListener(listener) == -1) then
			for _, id in ipairs(roster) do
				local player = game.Players:GetPlayerByUserId(id);
				rmd.LocalWarning:FireClient(player, "Teleport request declined");
			end
			break;
		end
		timer = timer + wait();
	end
	
	listener:Destroy();
end
	
function teleportSolo(player) 
	if (not isPrivate) then
		tp:TeleportToSpawnByName(placeId, destination, player);
	else
		local reserveCode = tp:ReserveServer(placeId);
		tp:TeleportToPrivateServer(placeId, reserveCode, {player}, destination);
	end
end

portal.Touched:connect(main);