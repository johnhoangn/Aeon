local module = {}

player = game.Players.LocalPlayer
sounds = game.ReplicatedStorage:WaitForChild('Sounds')
char = workspace:WaitForChild(player.Name)
serverDomain = workspace:WaitForChild("ServerDomain")
save = serverDomain.SaveHub:WaitForChild(player.UserId .. 's Save')
rStorage = game.ReplicatedStorage
quests = workspace.ServerDomain:WaitForChild("Quests")
remoteDump = rStorage:WaitForChild("RemoteDump")
dMethods = require(player.PlayerScripts:WaitForChild("DialogueMethods"))
iMethods = require(player.PlayerScripts:WaitForChild("InventoryMethods"))
vMethods = require(player.PlayerGui.Screen.Aspect.VendorFrame:WaitForChild("VendorModule"))
mMethods = require(player.PlayerGui.Screen.Aspect.MarketFrame:WaitForChild("MarketModule"))

translator = game:GetService('HttpService')

bin = script.Parent
nextButton = bin.nFrame.Next
nChatLabel = bin.nFrame.nChatLabel
pChatList = bin.pFrame.pChatList
pChatButtonMaster = script.pChatButton:Clone()
pChatButtons = {}
chatTriggers = {
	'assignQuest',
	'setQuestStage',
	'incrementQuestStage',
	'giveItem',
	'takeItem',
	'openStore',
	'openMarket',
	'backTo'
}
reqs = {
	'isReward',
	'wearingItem',
	'collectItem',
	'questAtStage',
	'questBeforeStage',
	'questAfterStage',
	'characterLevel',
	'questNotStarted',
	'questCompleted',
	'questStarted',
	'doesNotHave',
	'notWearingItem'
}

chatSize = 0
nextChat = nil
currentChat = nil
skipping = false
typeWritering = false
isEnd = false
module.status = 'Idle'
chattingWith = nil

highlighted = Color3.new(1,1,1)
greyed = Color3.new(167/255,167/255,167/255)

function makePChat(chat)
	local newPChat = pChatButtonMaster:Clone()
	newPChat.Parent = pChatList
	newPChat.TextWrapped = false
	newPChat.Text = chat.Value
	local textlength = newPChat.TextBounds.X
	local lines = 1 --How many lines???
	if textlength > newPChat.AbsoluteSize.X then --Our text is longer than our textbox, wrap it!
		lines = math.ceil(textlength/newPChat.AbsoluteSize.X) --Linessssssss
		--print('this choice is ' .. lines)
	end
	if pChatList.CanvasSize.Y.Scale == 1 then
		newPChat.Size = UDim2.new(1, -10, 0, 14*lines)
	else
		newPChat.Size = UDim2.new(1, -18, 0, 14*lines)
	end
	newPChat.TextWrapped = true
	newPChat.MouseButton1Click:connect(function()
		module.pChat(chat)
	end)
	newPChat.MouseMoved:connect(function()
		for _, i in pairs(pChatList:GetChildren()) do
			i.TextColor3 = greyed
			i.TextStrokeColor3 = greyed
		end
		newPChat.TextColor3 = highlighted
		newPChat.TextStrokeColor3 = highlighted
	end)
	return newPChat
end

function isTrigger(str)
	for _, i in pairs(chatTriggers) do
		if i == str then
			return true
		end
	end
	return false
end

function isReq(search)
	for _, i in pairs(reqs) do
		if search == i then 
			return true
		end
	end
	return false
end

function checkChatReqs(chat)
	local reqs = {}
	local success = true			--Reverse check, innocent until proven guilty
	for _, i in pairs(chat:GetChildren()) do
		if isReq(i.Name) == true then
			table.insert(reqs,i)
		end
	end
	for _, i in pairs(reqs) do
		if i.Name == 'questAtStage' then
			local reqQuestID = quests[i.Value].Value
			local reqQuestStage = i.stage.Value
			local trackedQuests = save.Quests:GetChildren()
			local foundQuest = false
			for _, tracking in pairs(trackedQuests) do
				if tracking.Value == reqQuestID then
					foundQuest = true
					if tracking.Stage.Value ~= reqQuestStage then
						success = false
					end
					break
				end
			end
			if foundQuest == false then
				success = false
			end
		elseif i.Name == 'questBeforeStage' then
			local reqQuestID = quests[i.Value].Value
			local reqQuestStage = i.stage.Value
			local trackedQuests = save.Quests:GetChildren()
			local foundQuest = false
			for _, tracking in pairs(trackedQuests) do
				if tracking.Value == reqQuestID then
					foundQuest = true
					if tracking.Stage.Value >= reqQuestStage then
						success = false
					end
					break
				end
			end
			if foundQuest == false then
				success = false
			end
		elseif i.Name == 'questAfterStage' then
			local reqQuestID = quests[i.Value].Value
			local reqQuestStage = i.stage.Value
			local trackedQuests = save.Quests:GetChildren()
			local foundQuest = false
			for _, tracking in pairs(trackedQuests) do
				if tracking.Value == reqQuestID then
					foundQuest = true
					if tracking.Stage.Value <= reqQuestStage then
						success = false
					end
					break
				end
			end
			if foundQuest == false then
				success = false
			end
		elseif i.Name == 'questNotStarted' then
			local reqQuestID = quests[i.Value].Value
			local trackedQuests = save.Quests:GetChildren()
			for _, tracking in pairs(trackedQuests) do
				if tracking.Value == reqQuestID then
					success = false
				end
			end
			local foundIt = false
			if string.find(save.CQs.Value,"["..i.Value.."]") then
				foundIt = true
			end
			if foundIt == true then
				success = false
			end
		elseif i.Name == 'questStarted' then
			local foundIt = false
			local reqQuestID = quests[i.Value].Value
			local trackedQuests = save.Quests:GetChildren()
			for _, tracking in pairs(trackedQuests) do
				if tracking.Value == reqQuestID then
					foundIt = true
				end
			end
			if foundIt == false then success = false end
		elseif i.Name == 'questCompleted' then
			local foundIt = false
			local reqQuestID = i.Value
			local CQs = save.CQs.Value
			if string.find(CQs,"["..reqQuestID.."]") ~= nil then
				foundIt = true
			end
			if foundIt == false then success = false end
		elseif i.Name == 'isReward' then
			if iMethods.getNumSlots(player) <= #serverDomain.Quests[i.Value].Rewards:GetChildren() - 1 then
				success = false
			end
		elseif i.Name == 'characterLevel' then
			if save.Level.Value < i.Value then
				success = false
			end
		elseif i.Name == 'collectItem' then
			--print'check collectitem'
			if iMethods.haveEnough(i.Value,i.Amount.Value) == false then
				success = false
			end
		elseif i.Name == 'wearingItem' then
			local foundItem = false
			local id = dMethods.getItemId(i.Value)
			if id ~= nil then
				for _, z in pairs(save.Equipped:GetChildren()) do
					if z.Value == tonumber(id) then
						foundItem = true
					end
				end
				if foundItem == false then
					success = false
				end
			end
		elseif i.Name == 'notWearingItem' then
			local foundItem = false
			local id = dMethods.getItemId(i.Value)
			if id ~= nil then
				for _, z in pairs(save.Equipped:GetChildren()) do
					if z.Value == tonumber(id) then
						foundItem = true
					end
				end
				if foundItem == true then
					success = false
				end
			end
		elseif i.Name == 'doesNotHave' then
			if iMethods.haveEnough(i.Value,1) == true then
				success = false
			end
		end
	end
	--print(tostring(#reqs) .. ' checks. ' .. tostring(success) .. ' for ' .. chat.Name)
	return success
end

function pairsByKeys(t)
	local a = {}
	for n in pairs(t) do 
		table.insert(a, n) 
	end
	table.sort(a)
	local i = 0
	local iter = function()
		i = i + 1
		if a[i] == nil then 
			return nil
		else 
			return a[i], t[a[i]]
		end
	end
	return iter
end

function listPChats(chatTree)
	local chats = chatTree:GetChildren()
	local branches = {}
	for _, i in ipairs(chats) do
		branches[i.Name] = i
	end
	table.sort(branches)
	pChatList.CanvasSize = UDim2.new(1,0,1,0)
	for _, i in pairsByKeys(branches) do
		if checkChatReqs(i) == true and ((i.ClassName == 'StringValue' and i.Name ~= 'nChat' and isTrigger(i.Name) == false) or i.Name == 'pChat') then
			local newChat = makePChat(i)
			local pChats = pChatList:GetChildren()
			newChat.Position = UDim2.new(0,5,0,chatSize+5)
			pChatButtons[#pChatButtons+1] = newChat
			chatSize = chatSize + newChat.AbsoluteSize.Y + 8
			if chatSize > pChatList.AbsoluteSize.Y then
				pChatList.CanvasSize = UDim2.new(1,0,0,chatSize+8)
			else
				pChatList.CanvasSize = UDim2.new(1,0,1,0)
			end
			nextButton.Visible = false
		end
	end
	pChatList.CanvasPosition = Vector2.new(0,0)
	chatSize = 0
end

function talk(chat)
	typewritering = true
	currentChat = chat
	local chatChops = {}
	local formattedChat = chat.Value
	local requests = {}
	local nameRequest,nR = string.find(formattedChat,'##PLAYERNAME##')
	if nameRequest ~= nil then
		--print('Start request at: ' .. nameRequest)
		--print('End request at: ' .. nR)
		formattedChat = string.sub(formattedChat,1,nameRequest-1) .. player.Name .. string.sub(formattedChat,nR+1)
	end
	local levelRequest,lR = string.find(formattedChat,'##PLAYERLEVEL##')
	if levelRequest ~= nil then
		formattedChat = string.sub(formattedChat,1,levelRequest-1) .. save.Level.Value .. string.sub(formattedChat,lR+1)
	end
	pChatList:ClearAllChildren()
	--print('talking ' .. formattedChat)
	for i = 1, string.len(formattedChat) do
		if math.fmod(i,3) == 0 then
			local sound = sounds.TalkBlip:Clone()
			sound.Parent = player.PlayerScripts
			sound:Play()
			game:GetService("Debris"):AddItem(sound,1)
		end
		if skipping == true then
			skipping = false
			nChatLabel.Text = formattedChat
			typewritering = false
			break
		else
			nChatLabel.Text = string.sub(formattedChat,1,i) 
		end
		if string.sub(formattedChat,i,i) == "," or string.sub(formattedChat,i,i) == "." then
			wait(1/5)
		else
			wait()
		end
	end
	typewritering = false
end

function showNChat(nChat)
	nextButton.Visible = true
	module.layerTable[module.layerIndex] = nChat
	module.layerIndex = module.layerIndex + 1
	currentChat = nChat
	talk(nChat)
	if nChat:FindFirstChild('pChat') ~= nil then
		nextButton.Visible = false
	elseif nChat:FindFirstChild('nChat') ~= nil then
		nextChat = nChat.nChat
		--print('next assigned to: ' .. nextChat.Value)
	else
		nextChat = nil
	end
	pChatList:ClearAllChildren()
	pChatButtons = {}
	listPChats(nChat)
	if nChat:FindFirstChild('endChat') then
		isEnd = true
		module.status = 'Ending'
	end
end

function module.endChat()
	bin.Parent.Parent.lockOverride.Value = true
	nextButton.Visible = false
	module.layerIndex = 0
	module.layerTable = {}
	nChatLabel.Text = ''
	pChatList:ClearAllChildren()
	pChatButtons = {}
	isEnd = false
	nextChat = nil
	currentChat = nil
	local down = UDim2.new(0.5, -300, 1,0)
	bin:TweenPosition(down,"In","Quad",.5)
	--player.PlayerScripts.Events.DialogueEnd:Fire(chattingWith)
	chattingWith = nil
	module.status = 'Idle'
	wait(1)
	if bin.Parent.Aspect.Inventory.Mode.Value ~= 1 then
		bin.Parent.Aspect.Inventory.Mode.Value = -1
	end
	--print 'endchat'
end

function hideEverythingElse()
	player.PlayerGui.Screen.Aspect.Inventory.Visible = false
	player.PlayerGui.Screen.Aspect.Professions.Visible = false
	player.PlayerGui.Screen.Aspect.Attributes.Visible = false
	player.PlayerGui.Screen.Aspect.QuestFrame.Visible = false
end

function module.newDialogue(chatTree)
	if module.status == 'Conversing' then return end
	bin.Parent.Parent.lockOverride.Value = false
	chattingWith = chatTree.Parent.Parent.Parent
	hideEverythingElse()
	module.status = 'Conversing'
	bin.Parent.Aspect.Inventory.Mode.Value = 7
	module.layerIndex = 0
	module.layerTable = {}
	local up = UDim2.new(0.5, -300, 1, -215)
	bin:TweenPosition(up,"Out","Quad",.5)
	repeat wait() until bin.Position == up
	showNChat(chatTree)
end

function module.nextMethod()
	if currentChat == nil or nextButton.Visible == false then return end
	if nextChat ~= nil then --There's another nChat after
		--print('nextChat is: ' ..nextChat.Value)
		if typewritering == true then
			typewritering = false
			skipping = true
		else				--Finished typing
			showNChat(nextChat)
		end
	else
		if typewritering == true then --If in the middle of typing, just skip, but do not end dialogue if is end
			typewritering = false
			skipping = true
		else						
			local advanceable = true
			if currentChat:FindFirstChild('backTo') then
				module.layerIndex = currentChat.backTo.Value
				showNChat(module.layerTable[currentChat.backTo.Value])
			end
			if currentChat:FindFirstChild('openStore') then
				local cWith = chattingWith
				local t = coroutine.wrap(function()
					while (char.PrimaryPart.Position - cWith.PrimaryPart.Position).magnitude < 13 and vMethods.open == true do
						wait(.2)
					end
					if vMethods.open == true then
						vMethods.closeStore()
					end
				end)
				vMethods.openStore(chattingWith.Store)
				t()
			end
			if currentChat:FindFirstChild('openMarket') then
				local cWith = chattingWith
				local t = coroutine.wrap(function()
					while (char.PrimaryPart.Position - cWith.PrimaryPart.Position).magnitude < 13 and mMethods.open == true do
						wait(.2)
					end
					if mMethods.open == true then
						mMethods.closeMarket()
					end
				end)
				mMethods.openMarket()
				t()
			end
			if advanceable == true then 
				for _, t in ipairs(currentChat:GetChildren()) do
					if t.Name == 'giveItem' then
						local itemStr = t.Value
						if itemStr == 'Coines' then
							remoteDump.RemoteValue:FireServer(save.Silver,save.Silver.Value + currentChat.giveItem.Amount.Value)
							--print'gave'
						else
							--print'failed give'
							local itemId = dMethods.getItemId(itemStr)
							iMethods.giveItem(player,itemId,currentChat.giveItem.Amount.Value)
						end
					elseif t.Name == 'takeItem' then
						local itemStr = t.Value
						if iMethods.haveEnough(itemStr,currentChat.takeItem.Amount.Value) ~= false then
							local itemId = dMethods.getItemId(itemStr)
							iMethods.takeItem(player,itemId,currentChat.takeItem.Amount.Value)
							--print'took'
						else
							--print'failed take'
							advanceable = false
						end
					elseif t.Name == 'setQuestStage' then
						player.PlayerScripts.Events.DialogueOverride:Fire(t.Name,t.Value,t.Stage.Value)
					elseif t.Name == 'incrementQuestStage' then
						player.PlayerScripts.Events.DialogueOverride:Fire(t.Name,t.Value)	
					elseif t.Name == 'assignQuest' then
						local possible = dMethods.findEmptyTracker(save)
						if possible ~= nil then
							dMethods.assignQuest(save,t.Value)
						else
							remoteDump.RemoteWarning:FireServer('Quest tracker full!')
							advanceable = false
						end
					elseif t.Name == "clientEvent" then
						remoteDump.rIO:FireServer("module",t)
					end
				end
			end
			if isEnd == true then
				--print'ender'
				module.endChat()			
			end
			nextButton.Visible = false
		end
	end
end

nextButton.MouseButton1Click:connect(module.nextMethod)

function module.pChat(pChat)
	module.layerTable[module.layerIndex] = pChat
	module.layerIndex = module.layerIndex + 1
	pChatList.CanvasSize = UDim2.new(1,0,1,0)
	pChatList.CanvasPosition = Vector2.new(0,0)
	if pChat:FindFirstChild('nChat') then
		if pChat.nChat:FindFirstChild('nChat') then
			nextChat = pChat.nChat
		end
		showNChat(pChat.nChat)
	else
		nChatLabel.Text = ''
	end
	if pChat:FindFirstChild('backTo') then
		module.layerIndex = pChat.backTo.Value
		showNChat(module.layerTable[pChat.backTo.Value])
	end
	for _, t in ipairs(pChat:GetChildren()) do
		print(t)
		if t.Name == 'giveItem' then
			local itemStr = t.Value
			if itemStr == 'Silver' then
				remoteDump.RemoteValue:FireServer(save.Silver,save.Silver.Value + currentChat.giveItem.Amount.Value)
				--print'gave'
			else
				--print'failed give'
				local itemId = dMethods.getItemId(itemStr)
				iMethods.giveItem(player,itemId,t.Amount.Value)
			end
		elseif t.Name == 'takeItem' then
			local itemStr = t.Value
			if iMethods.haveEnough(itemStr,t.Amount.Value) ~= false then
				local itemId = dMethods.getItemId(itemStr)
				iMethods.takeItem(player,itemId,t.Amount.Value)
				--print'took'
			end
		elseif t.Name == 'setQuestStage' then
			
			player.PlayerScripts.Events.DialogueOverride:Fire(t.Name,t.Value,t.Stage.Value)
			
		elseif t.Name == 'incrementQuestStage' then
			
			player.PlayerScripts.Events.DialogueOverride:Fire(t.Name,t.Value)	
							
		elseif t.Name == 'assignQuest' then
			local possible = dMethods.findEmptyTracker(save)
			if possible ~= nil then
				dMethods.assignQuest(save,t.Value)
			end
		elseif t.Name == "clientEvent" then
			remoteDump.rIO:FireServer("module",t)
		end
	end
	if pChat:FindFirstChild('endChat') then
		module.endChat()
		--Hide dialogue menu
	end
end

return module
