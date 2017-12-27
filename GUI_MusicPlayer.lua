local cProv = game:GetService("ContentProvider")
local rService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local figure = workspace:WaitForChild(player.Name)
local rootPart = figure:WaitForChild("HumanoidRootPart")
local humanoid = figure:WaitForChild("Humanoid")
local otherPlayers = {}
local songs = {}
local cVol = 0;
local cTrack = nil
local pZone = nil --Previous zone, including generic
local adjustingVol = false
local adjustStack = {}

local on = true
local maxHeight = 100
local fadingOut = false
local fadingIn = false
local fading = nil
local fadeTime = 1/30 --Seconds


local times = {}
local preLoadList = script.Parent.Songs:GetChildren()
cProv:PreloadAsync(preLoadList)

--Preload
for _, Asset in pairs(preLoadList) do
	songs[Asset.Name] = Asset
end

--Initialize time block settings
for _, block in ipairs(script.Parent.Times:GetChildren()) do
	times[block.Name] = {block.Start.Value,block.Stop.Value}
end

--Refresh player list
function getPlayers()
	for i, p in ipairs(game.Players:GetChildren()) do
		otherPlayers[i] = p.Character
	end
end

--Used for zones or generics that have variations based on the time of day
function determineTimeTrack(zone)
	local cTime = game.Lighting:GetMinutesAfterMidnight()
	local tBlock = "AM12" --Assume first block
	--Actually figure out what block we're in
	for block, range in pairs(times) do
		if cTime >= range[1] and cTime < range[2] then
			tBlock = block
			break
		end
	end
	if cTrack ~= nil then
		--If we're now moving into generic
		if zone == nil then
			local song = "Generic" .. tBlock
			if zone == pZone and cTrack ~= songs[song] then
				if songs[song].isPaused == true then --was in generic, still in generic, new time of day, but new song was paused
					songs[song].TimePosition = 0
				end
			end	
			pZone = nil
			return song
		else --If we're in a time variant
			local tVariants = zone.ZoneSelector.TimeVariants:GetChildren()
			--Find the matching time block
			for _, song in ipairs(tVariants) do
				if song:FindFirstChild(tBlock) then
					if zone == pZone and cTrack ~= songs[song.Name] then
						if songs[song.Name].isPaused == true then --was in generic, still in generic, new time of day, but new song was paused
							songs[song.Name].TimePosition = 0
						end
					end
					pZone = zone
					return song.Name
				end
			end
		end	
	end
	--Developer messed up, play default generic
	pZone = nil
	return "Generic" .. tBlock
end

--What zone am I in? or generic?
function getZone()
	local ray = Ray.new(rootPart.Position,Vector3.new(0,maxHeight,0))
	local ignoreList = {}
	getPlayers()
	for _, p in ipairs(otherPlayers) do	table.insert(ignoreList,p) end --Ignore all player characters
	local hit, p = workspace:FindPartOnRayWithIgnoreList(ray,ignoreList)
	--visual(p)
	repeat
		if hit ~= nil then			
			table.insert(ignoreList,hit)
			if hit.Name ~= "ZonePart" then
				hit, p = workspace:FindPartOnRayWithIgnoreList(ray,ignoreList) --Get outta way
				--visual(p)
			else
				local selector = hit.Parent
				if selector:FindFirstChild("TimeVariants") ~= nil then
					return determineTimeTrack(selector.Parent)
				else
					pZone = selector.Parent
					return selector.Parent.Name
				end
			end
		end
	until hit == nil --No zone parts
	--At this point, the player isn't in a zone, assume generic
	return determineTimeTrack()
end
--Fade in/out
function fadeIn(track)
	if track ~= nil then
		fadingIn = true
		--print("Fade in requested: " .. track.Name)
		play(track)
		fading = track
		local goal = track.VolPercent.Value*(script.Parent.VolSetting.Value/100) --Both out of 100
		local incr = math.ceil(goal - track.Volume*100*(script.Parent.VolSetting.Value/100))
		for vol = math.floor(track.Volume*100*(script.Parent.VolSetting.Value/100)), goal, 1 do
			if fadingIn == false then fading = nil break end --Interrupt
			track.Volume = vol/100
			wait(fadeTime/incr)
		end
		fadingIn = false
		fading = nil
		--print("Fade in completed: " .. track.Name)
	end
end
function fadeOut(track)
	if track ~= nil then
		fadingOut = true
		fading = track
		--print("Fade out requested: " .. track.Name)
		local incr = math.ceil(track.Volume*100*(script.Parent.VolSetting.Value/100))
		for vol = math.floor(track.Volume*100*(script.Parent.VolSetting.Value/100)), 0, -1 do
			if fadingOut == false then fading = nil break end --Interrupt
			track.Volume = vol/100
			wait(fadeTime/incr)
		end
		if fadingOut == true and fading == track then
			pause(track)
		end
		fadingOut = false
		fading = nil
		--print("Fade out completed: " .. track.Name)
	end
end

function play(track)
	if track ~= nil and track ~= cTrack then
		cTrack = track
		cVol = track.VolPercent.Value/100
		--print("Play requested: " .. track.Name)
		if track.IsPaused then
			track:Resume()
		else
			track:Play()
		end
	end
end

function pause(track)
	if track ~= nil then
		--print("Pause requested: " .. track.Name)
		track:Pause()
	end
end

function push(stack, thing)
	stack[stack.length + 1] = thing;
	if stack.length == 1 then
		repeat wait() until not adjustingVol and not fadingIn and not fadingOut 
		while stack.length > 0 do
			stack[1]()
			table.remove(stack,1)
		end
	end
end

function setVol(v)
	cTrack.Volume = cVol*(v/100)
end

function adjustVolume(v)
	if not adjustingVol and not fadingIn and not fadingOut then
		setVol(v);
	else
		push(adjustStack,setVol(v));
	end
end

--Finale
function playMusic()
	if figure ~= nil and on == true then
		local zone = getZone()
		local nTrack = songs[zone]
		if fading == nil and nTrack ~= nil then --Nothing fading atm
			if cTrack ~= nil then --Something playing
				if nTrack ~= cTrack then --New track
					fadeOut(cTrack)
					cTrack = nil
				end
			else --Nothing playing
				play(nTrack)
				fadeIn(nTrack)
			end
		end
	end
end

script.Parent.VolSetting.Changed:connect(adjustVolume)

while figure ~= nil and figure.Parent ~= nil and wait() do
	playMusic()
end