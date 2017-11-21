if (game.Players.LocalPlayer.Name ~= "Dynamese") then
	script.Parent:Destroy();
end

local bin = script.Parent;
local pList = bin:WaitForChild("PlayerList");
local pInfo = bin:WaitForChild("PlayerInfo");
local pButton = script:WaitForChild("Player");
local property = script:WaitForChild("Property");
local toggle = bin:WaitForChild("Toggle");
local stats = {"Level", "Silver", "Party"}; -- There are more
local listeners = {};
local curPlayers = {};

function open()
	pList.Visible = true;
	startTracking();
end

function close()
	pList.Visible = false;
	pInfo.Visible = false;
	stopTracking();
	returnProperties();
end

function bindTracker(pLabel, stat)
	local tracker = nil;
	pLabel.Text = stat.Name .. ": " .. stat.Value;
	tracker = stat.Changed:connect(function()
		pLabel.Text = stat.Name .. ": " .. stat.Value;
	end)
	return tracker;
end

function playersUpToDate()
	for _, guy in ipairs(curPlayers) do
		if (guy == nil) then
			return false;
		end
	end
	if (#game.Players:GetChildren() > #curPlayers) then
		return false;		
	end
	return true;
end

function returnProperties()
	for _, pLabel in ipairs(pInfo:GetChildren()) do
		if (pList:FindFirstChild(pLabel.Name)) then
			pLabel.Parent = pList[pLabel.Name];
			pLabel.Visible = false;
		else
			pLabel:Destroy();
		end
	end
end

function disconnectTrackers()
	for _, tracker in ipairs(listeners) do
		for _, listener in ipairs(tracker) do
			listener:Disconnect();
		end
	end
	listeners = {};
	returnProperties();
end

function resetPlayers()
	disconnectTrackers();
	return game.Players:GetChildren();
end

function startTracking()
	curPlayers = playersUpToDate() and curPlayers or resetPlayers();
	for _, guy in ipairs(curPlayers) do
		local guyButton = pButton:Clone();
		
		for _, stat in ipairs(stats) do
			local pLabel = property:Clone();
			pLabel.Name = guy.Name;
			local tracker = bindTracker(pLabel, workspace.ServerDomain.SaveHub[guy.userId .. "s Save"][stat]);
			if (listeners[guy.Name] == nil) then
				listeners[guy.Name] = {};
			end
			table.insert(listeners[guy.Name], tracker);
			pLabel.Position = pLabel.Position + UDim2.new(0, 0, 0, 12 * #guyButton:GetChildren());
			pLabel.Visible = false;
			pLabel.Parent = guyButton;
		end
		
		guyButton.MouseButton1Click:connect(function()
			returnProperties();
			for _, pLabel in ipairs(guyButton:GetChildren()) do
				pLabel.Parent = pInfo;
				pLabel.Visible = true;
			end
			pInfo.Visible = true;
		end)
		
		guyButton.Name = guy.Name;
		guyButton.Position = guyButton.Position + UDim2.new(0, 0, 0, 30 * #pList:GetChildren());
		guyButton.Parent = pList;
	end
end

function stopTracking()
	disconnectTrackers();
	pList:ClearAllChildren();
end

toggle.MouseButton1Click:connect(function()
	if (pList.Visible) then
		close();
	else
		open();
	end 
end)