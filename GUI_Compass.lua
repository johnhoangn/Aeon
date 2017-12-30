workspace:WaitForChild(game.Players.LocalPlayer.Name)
northVector = Vector3.new(0,0,-1)
camera = workspace.CurrentCamera
bin = script.Parent
r = game:GetService('RunService')
torso = game.Players.LocalPlayer.Character:WaitForChild("Torso")
width = bin.AbsoluteSize.X
dir = {
	bin:WaitForChild('North'),
	bin:WaitForChild('East'),
	bin:WaitForChild('South'),
	bin:WaitForChild('West')
}
--DOT PRODUCT MATH:  A dot B = A.magnitude * B.magnitude * cos(THETA)
--(A dot B)/(A.magnitude*B.magnitude) = cos(THETA)
--THETA = acos(A dot B)/(A.magnitude*B.magnitude)
--width/2  width is pi, this = pi/2

function cardinal()
	local cameraVector = camera.CoordinateFrame.lookVector*Vector3.new(1,0,1) --zero the pitch
	local magProduct = cameraVector.magnitude*northVector.magnitude
	local dot = cameraVector:Dot(northVector)
	local theta = math.acos(dot/magProduct)
	local pole = -1
	if cameraVector.x < 0 then
		pole = 1
	end
	local deg = math.deg(theta)*pole
	local fakePi = width/2
	dir[1].Position = UDim2.new(0,(deg/180)*(width)+(fakePi),0,0) --0 is centered on the left edge of the compass, offset by 1/2 of the bar, equal to pi/2
	dir[2].Position = UDim2.new(0,(deg/180)*(width)+(fakePi*2),0,0)
	if deg < 0 then
		dir[3].Position = UDim2.new(0,(deg/180)*(width)+(fakePi*3),0,0)
	else
		dir[3].Position = UDim2.new(0,(deg/180)*(width)-(fakePi),0,0)
	end
	dir[4].Position = UDim2.new(0,(deg/180)*(width),0,0)
end

function makeWPs()
	for _, v in pairs(bin.WaypointFolder:GetChildren()) do
		if not bin.Parent.Waypoints:FindFirstChild(v.Name) then
			if (string.find(v.Name,"QuestMarker") ~= nil) then
				if (v.Active.Value == true) then
					local newWP = script.WP:Clone()
					newWP.Name = v.Name
					newWP.Parent = bin.Parent.Waypoints
				end
			else
				local newWP = script.WP:Clone()
				newWP.Name = v.Name
				newWP.Parent = bin.Parent.Waypoints
			end
		end
	end
end

function clearWPs()
	for _, v in pairs(bin.Parent.Waypoints:GetChildren()) do
		if bin.WaypointFolder:FindFirstChild(v.Name) == nil or (string.find(v.Name,"QuestMarker") ~= nil and v.Active.Value == false) then
			v:Destroy()
		end
	end
end

function angleBetween(a,b)
	-- Normalize along only x and z
	local aVec = (a * Vector3.new(1,0,1)).unit;
	local bVec = (b * Vector3.new(1,0,1)).unit;
	
	local project = aVec:Dot(bVec)
	local magProd = aVec.magnitude*bVec.magnitude
	local angle = math.acos(project/magProd)
	return angle
end

function clamp(ratio)
	if (ratio < -1/2) then
		return -1/2;
	elseif (ratio > 1/2) then
		return 1/2;
	else
		return ratio;
	end
end

function waypoint(gui,tVec)
	local n = Vector3.new(1,0,1);
	local nn = Vector3.new(-1,0,1);
	
	local cVec = camera.CoordinateFrame.lookVector*n;
	local rCVec = camera.CoordinateFrame.rightVector*n;	
	
	local angle = angleBetween(cVec,tVec);	
	local rightAngle = angleBetween(rCVec,tVec);	
	
	if (rightAngle > math.pi/2) then
		angle = -angle;
	end
	
	local deg = math.deg(angle);	

	local dMax = 50;
	local dMin = 12;
	local d = dMax;
	local minDist = 20;
	local maxDist = 100;
	local dist = tVec.magnitude;
	local size = (maxDist/dist)*dMax*(minDist/maxDist);
	
	if (size > dMin and size < dMax) then
		d = size;
	elseif (size <= dMin) then
		d = dMin;
	else 
		d = dMax;
	end	

	gui.Position = UDim2.new(0,clamp(deg/180)*width,0.5,0);
	gui.Size = UDim2.new(0,d,0,d);
end

r.Stepped:connect(function()
	cardinal()
	clearWPs()
	makeWPs()
	for _, wp in pairs(bin.Parent.Waypoints:GetChildren()) do
		local vector = (bin.WaypointFolder[wp.Name].Value-torso.Position)
		waypoint(wp,vector)
	end
end)