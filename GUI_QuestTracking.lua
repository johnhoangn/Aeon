local player = game.Players.LocalPlayer
local bindables = player.PlayerScripts:WaitForChild("Events")
local sDomain = workspace.ServerDomain
local questBank = sDomain.Quests
local rmd = game.ReplicatedStorage.RemoteDump
local save = sDomain.SaveHub:WaitForChild(player.UserId .. "s Save")
local gui = script.Parent
local compass = gui.Parent:WaitForChild("Compass"):WaitForChild("Compass")
local journalEntry = script:WaitForChild("Entry"):Clone()

local iMethods = require(player.PlayerScripts.InventoryMethods)
local cMethods = require(player.PlayerScripts.ClientMethods)

local quests = {} -- Max six
local yield = false -- During reOrganize()
local selectedEntry = "" -- Currently selected journal entry

function indexOf(questId)
	-- Linear search, returns index of quest of Integer questId
	for i, v in ipairs(quests) do
		if v.id == questId then
			return i
		end
	end
end

function getId(questName)
	-- Receives String, returns Integer
	for _, v in ipairs(questBank:GetChildren()) do
		if v.Name == tostring(questName) then
			return tonumber(v.Value)
		end
	end
end

function getName(questId)
	-- Receives Integer input, returns String
	for _, v in ipairs(questBank:GetChildren()) do
		if v.Value == questId then
			return v.Name
		end
	end
end

function insertQuest(trackerObj)
	-- Precondition: questlog not full
	-- Receives Object tracker and sets up the quest object in the quests table
	local questRef = questBank[getName(trackerObj.Value)]
	local questObject = {}
		questObject.id = trackerObj.Value
		questObject.stage = trackerObj.Stage.Value
		questObject.endStage = questRef.EndStage.Value
		questObject.events = {}
		questObject.tracker = trackerObj
	table.insert(quests,questObject)
	setEvents(questObject)
	drawGUI()
end

function splash(questId,msg)
	local completeSplash = script.Splash:Clone()
	local questName = getName(questId)
	completeSplash.Text = string.upper(questName).." : "..msg
	completeSplash.Parent = gui.Parent
	local thread = coroutine.wrap(function()
		for i = 1, 10 do
			completeSplash.TextTransparency = 1-(i/10)
			completeSplash.TextStrokeTransparency = 1-(i/10)*.6
			wait(1/20)
		end
		wait(3)
		for i = 1, 10 do
			completeSplash.TextTransparency = (i/10)
			completeSplash.TextStrokeTransparency = (i/10)
			wait(1/20)
		end
		completeSplash:Destroy()
	end)
	thread()
end

function animateStart(questId)
	cMethods.playSound("QuestStarted")
	splash(questId,"QUEST STARTED")
end

function animateObjective(questObject)
	cMethods.playSound("QuestProgressed")
	splash(questObject.id,"JOURNAL ENTRY UPDATED")
end

function animateComplete(questObject)
	cMethods.playSound("QuestComplete")
	splash(questObject.id,"QUEST COMPLETED")
end

function animateForfeit(questObject)
	cMethods.playSound("QuestProgressed")
	splash(questObject.id,"QUEST FORFEITED")
end

function finishQuest(questObject)
	-- Precondition: inventory has enough space for all item rewards
	-- Function for completing a quest
	-- Give rewards
	if selectedEntry == questObject.tracker.Name then
		selectedEntry = ""
	end
	local index = indexOf(questObject.id)
	local questName = getName(questObject.id)
	local questData = questBank[questName]
	local rewards = questData.Rewards:GetChildren()
	for _, reward in ipairs(rewards) do
		if reward.Name == "Coines" then
			rmd.RemoteValue:FireServer(save.Silver,save.Silver.Value + reward.Value)
		elseif reward.Name == "Experience" then
			rmd.RemoteValue:FireServer(save.Level.Exp,save.Level.Exp.Value + reward.Value)
		else
			iMethods.giveItem(player,reward.Name,reward.Value)
		end
	end
	unbind(questObject)
	rmd.RemoteValue:FireServer(questObject.tracker,0)
	rmd.RemoteValue:FireServer(questObject.tracker.Stage,0)
	rmd.RemoteValue:FireServer(save.CQs, save.CQs.Value.."["..questName.."]")
	table.remove(quests,index)
	wait(1)
	reOrganize()
	drawGUI()
	animateComplete(questObject)
	local wp = compass.WaypointFolder["QuestMarker"..questObject.tracker.Name]
	local marker = gui["QuestMarker"..questObject.tracker.Name]
	marker.Adornee = nil
	wp.Active.Value = false
end

function dropQuest(questObject)
	-- Function for forfeiting a quest
	-- Remove any quest items given to the player at any stage
	local index = indexOf(questObject.id)
	unbind(questObject.events)
	rmd.RemoteValue:FireServer(questObject.tracker,0)
	rmd.RemoteValue:FireServer(questObject.tracker.Stage,0)
	table.remove(quests,index)
	reOrganize()
	drawGUI()
end

function incrementStage(questObject)
	-- Receives index of a quest in the log and increments its stage
	-- If incremented to endStage then read quest rewards, give, and display
	-- After incrementing, clean and get new tasks
	unbind(questObject)
	questObject.stage = questObject.stage + 1
	if questObject.stage == questObject.endStage then
		finishQuest(questObject)
	else
		setEvents(questObject)
		animateObjective(questObject)
	end
	updateSave()
	drawGUI()
	--print("_qTracker_"..getName(questObject.id) .. " incremented")
end

function readSave()
	-- Read save and insert into quests table
	-- Run only at character load/reset
	quests = {}
	for _, v in ipairs(save.Quests:GetChildren()) do
		if v.Value ~= 0 then
			insertQuest(v)
		end
	end
end

function updateSave()
	-- Read quest table and update save
	-- Run when:
	-- 	Quest stage(s) change
	-- 	Quest(s) are dropped  / finished
	for _, v in ipairs(quests) do
		rmd.RemoteValue:FireServer(v.tracker.Stage, v.stage)
	end
end

function reOrganize()
	-- Unbind events, yield the tracker events
	yield = true
	for _, questObject in ipairs(quests) do
		unbind(questObject)
	end
	local trackers = save.Quests:GetChildren()
	local questsInLog = {}
	local logIndex = 1
	-- Store pass
	for _, tracker in ipairs(trackers) do
		if tracker.Value > 0 then
			table.insert(questsInLog,tracker:Clone())
		end
	end	
	-- Rewrite pass
	for _, tracker in ipairs(trackers) do
		if questsInLog[logIndex] ~= nil then
			rmd.RemoteValue:FireServer(tracker,questsInLog[logIndex].Value)
			rmd.RemoteValue:FireServer(tracker.Stage, questsInLog[logIndex].Stage.Value)
			logIndex = logIndex + 1
		else
			rmd.RemoteValue:FireServer(tracker, 0)
			rmd.RemoteValue:FireServer(tracker.Stage, 0)
		end
	end
	questsInLog = nil
	-- Reconnect pass, tracker and Tracker are different
	trackers = save.Quests:GetChildren()
	for _, questObject in ipairs(quests) do
		for _, Tracker in ipairs(trackers) do
			if questObject.id == Tracker.Value then
				questObject.tracker = Tracker
				setEvents(questObject)
			end
		end
	end
	yield = false
end

function addItemReward(reward)
	-- Inserts reward item into the rewards box
	local ref = game.ReplicatedStorage.References
	local tex = game.ReplicatedStorage.Textures
	local items = gui.MoInfo.Rewards.Items
	local item = script.Item:Clone()
	pcall(function() 
		item.ClickSlot.Image = "rbxassetid://"..tex[reward.Name] 
		item["#"].Text = reward.Value
	end)
	item.Position = UDim2.new(0,5+45*#gui.MoInfo.Rewards.Items:GetChildren(),0,0)
	item.Parent = gui.MoInfo.Rewards.Items
end

function drawDetails(questObject)
	local questName = getName(questObject.id)
	local questData = questBank[questName]
	local questDesc = questData.Description.Value
	local stageBrief = questData["Stage"..questObject.stage].Value
	local brief = gui.MoInfo
	brief.Rewards.Stud.Visible = true
	brief.Rewards.RewardLabel.Visible = true
	brief.Title.Title.Text = questName
	selectedEntry = questObject.tracker.Name
	brief.Desc.Desc.Text = stageBrief
	pcall(function() 
		brief.Rewards.Coines.Text = cMethods.commafy(questData.Rewards.Coines.Value)
		brief.Rewards.Stud.Visible = true
	end)
	pcall(function() 
		brief.Rewards.Exp.Text = cMethods.commafy(questData.Rewards.Experience.Value)
		brief.Rewards.ExpLabel.Visible = true
	end)
	for _, i in ipairs(brief.Rewards.Items:GetChildren()) do
		i:Destroy()
	end
	for _, reward in ipairs(questData.Rewards:GetChildren()) do
		if reward.Name ~= "Coines" and reward.Name ~= "Experience" then
			addItemReward(reward)
		end
	end
end

function dullOthers(entry)
	for _, i in ipairs(gui.Trackers.List:GetChildren()) do
		if i ~= entry and i.Name ~= selectedEntry and i.Name ~= "Line" then
			i.TextTransparency = 0.5
			i.TextStrokeTransparency = 1
		end
	end
end

function drawTracker(index)
	-- Receives the index of a quest and draws the GUI for it
	local questObject = quests[index]
	local questName = getName(questObject.id)
	local questData = questBank[questName]
	local questDesc = questData.Description.Value
	local stageBrief = questData["Stage"..questObject.stage].Value
	local brief = gui.MoInfo
	local newEntry = journalEntry:Clone()
	newEntry.Text = questName
	-- More info button
	newEntry.MouseButton1Click:connect(function()
		drawDetails(questObject)
		dullOthers(newEntry)
	end)
	newEntry.MouseEnter:connect(function()
		dullOthers(newEntry)
		newEntry.TextTransparency = 0
		newEntry.TextStrokeTransparency = .8
	end)
	newEntry.MouseLeave:connect(function()
		if newEntry.Name ~= selectedEntry then
			newEntry.TextTransparency = 0.5
			newEntry.TextStrokeTransparency = 1
		end
	end)
	newEntry.Name = questObject.tracker.Name
	local numTrackers = #gui.Trackers.List:GetChildren()
	local y = newEntry.Size.Y.Offset + 5
	newEntry.Position = UDim2.new(0,10,0,10+numTrackers*y)
	newEntry.Parent = gui.Trackers.List
	gui.Trackers.List.CanvasSize = UDim2.new(0,0,0,10+(numTrackers+1)+(numTrackers*y))
end

function drawCompleted(questData)
	local questName = questData.Name
	local questData = questBank[questName]
	local questDesc = questData.Description.Value
	local brief = gui.MoInfo
	local newEntry = journalEntry:Clone()
	newEntry.Text = questName
	-- More info button
	newEntry.MouseButton1Click:connect(function()
		brief.Title.Title.Text = questName
		brief.Desc.Desc.Text = questData.Description.Value
		brief.Rewards.Stud.Visible = false
		brief.Rewards.ExpLabel.Visible = false
		brief.Rewards.Exp.Text = ""
		brief.Rewards.Coines.Text = ""
	end)
	newEntry.MouseEnter:connect(function()
		dullOthers(newEntry)
		newEntry.TextTransparency = 0
		newEntry.TextStrokeTransparency = .8
	end)
	newEntry.MouseLeave:connect(function()
		newEntry.TextTransparency = 0.5
		newEntry.TextStrokeTransparency = 1
	end)
	newEntry.Name = "CompletedQuest"
	local numTrackers = #gui.Trackers.List:GetChildren()
	local y = newEntry.Size.Y.Offset + 5
	newEntry.Position = UDim2.new(0,10,0,10+(numTrackers-1)*y)
	newEntry.Parent = gui.Trackers.List
	gui.Trackers.List.CanvasSize = UDim2.new(0,0,0,15+(numTrackers*y))
end

function drawGUI()
	-- Calls drawTracker for each quest in the quests table
	-- Draws the rest of the GUI
	-- Run whenever a quest tracker updates
	local brief = gui.MoInfo
	for _, i in ipairs(gui.Trackers.List:GetChildren()) do
		i:Destroy()
	end
	for i, _ in ipairs(quests) do
		drawTracker(i)
	end
	if save.CQs.Value ~= "" then
		local numTrackers = #gui.Trackers.List:GetChildren()
		local y = script.Entry.Size.Y.Offset + 5
		local line = script.Line:Clone()
		line.Position = UDim2.new(0.5,0,0,10+numTrackers*y)
		line.Parent = gui.Trackers.List
		for word in string.gmatch(save.CQs.Value, "%[%w+%s*%w*%s*%w*%s*%w*%s*%w*%]") do 
			drawCompleted(questBank[string.sub(word,2,string.len(word)-1)])
		end
	end
	if selectedEntry == "" then
		brief.Rewards.Stud.Visible = false
		brief.Rewards.RewardLabel.Visible = false
		brief.Rewards.ExpLabel.Visible = false
		brief.Title.Title.Text = ""
		brief.Desc.Desc.Text = ""
		brief.Rewards.Exp.Text = ""
		brief.Rewards.Coines.Text = ""
	else
		gui.Trackers.List[selectedEntry].TextTransparency = 0
		gui.Trackers.List[selectedEntry].TextStrokeTransparency = .8
		drawDetails(quests[indexOf(save.Quests[selectedEntry].Value)])
	end
end

function preQualify(task)
	-- For tasks that apply, check if the player already completed it
	if task.Name == "Craft" or task.Name == "Gather" or task.Name == "Loot" then
		if iMethods.haveEnough(task.Value,task.Amount.Value) == false then
			return false
		end
	elseif task.Name == "GoTo" then
		return false
	end
end

function setEvents(questObject)
	-- Gets tasks from quest data and binds the proper functions to their events
	local stage = "Stage" .. questObject.stage
	local tasks = questBank[getName(questObject.id)][stage]:GetChildren()
	-- Prequalify check
	local preQualified = (#tasks > 0) -- Genius. Leaves room for dialogue prompted stage changes... not so anymore with "GoTo"
	for _, task in ipairs(tasks) do
		if preQualify(task) == false then
			preQualified = false 
			break
		end
	end
	-- Handle marker
	local wp = compass.WaypointFolder["QuestMarker"..questObject.tracker.Name]
	local marker = gui["QuestMarker"..questObject.tracker.Name]
	marker.Adornee = nil
	wp.Active.Value = false
	-- Oh no, I have to go kill 10,000 more tigers
	if preQualified == false then
		print("_qTracking_Player did not prequalify, setting task events for stage "..questObject.stage)
		for _, task in ipairs(tasks) do
			if (task.Name == "GoTo") then
				marker.Adornee = workspace[task.Value].PrimaryPart
				wp.Value = workspace[task.Value].PrimaryPart.Position
				wp.Active.Value = true
				if (workspace[task.Value]:FindFirstChild("Humanoid")) then
					marker.StudsOffset = Vector3.new(0,4,0)
				else
					marker.StudsOffset = Vector3.new(0,1,0)
				end
			else
				local event = bindables[task.Name]
				local function func(arg)
					print("_qTracking_"..task.Name.." fired with "..arg.Name)
					if arg.Name == task.Value then
						if task:FindFirstChild("Amount") then
							if iMethods.haveEnough(task.Value,task.Amount.Value) then
								incrementStage(questObject)
							end
						else
							incrementStage(questObject)
						end
					end
				end
				bind(questObject,func,event)
			end		
		end
	else
		print("_qTracking_Prequalified, incrementing to stage"..questObject.stage+1)
		incrementStage(questObject)
	end
	--printJournal()
end

function bind(questObject,func,event)
	-- Binds a function to an event
	-- Ex. func = set stage; bound to gather
	local connection = event.Event:connect(func)
	table.insert(questObject.events,connection)
	print("_qTracking_Bound function to " .. event.Name)
end

function unbind(questObject)
	-- Unbinds all events connected to the input questObject
	for _, v in ipairs(questObject.events) do
		v:Disconnect()
	end
	questObject.events = {}
end

function printQuestDetails(questObject)
	-- Debugging function
	local id = questObject.id
	local name = getName(id)
	local stage = questObject.stage
	local eStage = questObject.endStage
	local numEvents = #questObject.events
	local tracker = questObject.tracker.Name
	print("QUEST: [" .. name .. "]")
	print("_ID: [" .. id .. "]")
	print("_STAGE: [" .. stage .. "]")
	print("_ENDSTAGE: [" .. eStage .. "]")
	print("_EVENTS: " .. tostring(questObject.events) .. " [" .. numEvents .. "]")
	print("_TRACKER: [" .. tracker .. "]")
end

function printJournal()
	-- Debugging function
	for _, v in ipairs(quests) do
		printQuestDetails(v)
	end
end


bindables.DialogueOverride.Event:connect(function(op,...)
	-- Some dialogue triggers will override quest stages, handle them here
	local args = {...}
	local questId = getId(args[1])
	local index = indexOf(questId)
	local questObject = quests[index]
	if op == "setQuestStage" then
		if args[2] == -1 then
			finishQuest(questObject)
		elseif args[2] == -2 then
			dropQuest(questObject)
			animateForfeit(questObject)
		else
			unbind(questObject)
			questObject.stage = args[2]
			updateSave()
			setEvents(questObject)
			animateObjective(questObject)
		end
		drawGUI()
	elseif op == "incrementQuestStage" then
		incrementStage(questObject)
	end
end)

-- Initialize
wait(1)

for _, tracker in ipairs(save.Quests:GetChildren()) do
	tracker.Changed:connect(function(id)
		if id > 0 and yield == false then
			animateStart(id)
			readSave()
		end
	end)
end

readSave()
wait(1)
reOrganize()
drawGUI()
