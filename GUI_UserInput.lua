wait(1)
local localplayer = game.Players.LocalPlayer
local localcharacter = workspace:WaitForChild(localplayer.Name)
local input = game:GetService("UserInputService")
local debris = game:GetService("Debris")
local mouse = localplayer:GetMouse()
--
local starterGui = localplayer.PlayerGui
local playergui = localplayer.PlayerGui:WaitForChild("Screen"):WaitForChild("Aspect")
local lootFrame = playergui:WaitForChild("LootFrame")
local inventory = playergui:WaitForChild("Inventory")
local journal = playergui:WaitForChild("QuestFrame")
local hotbar = playergui:WaitForChild("Hotbar")
local equips = localcharacter:WaitForChild("Equip")
local righthand = equips:WaitForChild("R")
local playersounds = game.ReplicatedStorage:WaitForChild("Sounds")
--
local ref = game.ReplicatedStorage:WaitForChild("References")
local tex = game.ReplicatedStorage:WaitForChild("Textures")
local refkids = ref:GetChildren()
local stuff = game.ReplicatedStorage.Stuff
local rmd = game.ReplicatedStorage.RemoteDump
local targetfilter = workspace.CurrentCamera:WaitForChild("Filter")
local savehub = workspace.ServerDomain:WaitForChild("SaveHub")
local save = savehub:WaitForChild(localplayer.UserId .. "s Save")
local Snormalslots = save:WaitForChild("Inv")
local stances = playergui.Stance.Stances
--
local AV = localcharacter:WaitForChild("ActorValues")
local sprinting = AV:WaitForChild("Sprinting")
--
local ChatClass = require(localplayer.PlayerGui.Screen.DialogueFrame.TalkieTalk)
local CraftClass = require(playergui.CraftingFrame.CraftingMethods)
local iMethods = require(localplayer.PlayerScripts.InventoryMethods)
local BankClass = require(playergui.BankFrame.BankMethods)
local clientMethods = require(localplayer.PlayerScripts:WaitForChild("ClientMethods"))
local tradeMethods = require(playergui.TradeFrame.TradeMethods)
local checkactor = clientMethods.checkactor
--
localcharacter:WaitForChild("GUI").B.Enabled = false
localcharacter.Humanoid:SetStateEnabled("Swimming",false)
--
local rollAnim = Instance.new("Animation")
rollAnim.Name = "Roll"
rollAnim.Parent = localcharacter
rollAnim.AnimationId = "rbxassetid://159123199"
rollTrack = localcharacter.Humanoid:LoadAnimation(rollAnim)
local stepAnim = Instance.new("Animation")
stepAnim.Name = "BackStep"
stepAnim.Parent = localcharacter
stepAnim.AnimationId = "rbxassetid://845523029"
rollTrack = localcharacter.Humanoid:LoadAnimation(rollAnim)
stepTrack = localcharacter.Humanoid:LoadAnimation(stepAnim)
--
local abortRoll = true
local filtertable = {targetfilter,localcharacter}
local mouserange = 15
local M1 = false
local grabbing = nil
local mapping = false
local sheathDeb = false
local targetPlayer = nil
local lootTarget = nil
local wasd = 0
local jumpCost = 8 
local rollCost = 16
--
local wasdCache = {}
local wasding = {
	W = false,
	A = false,
	S = false,
	D = false,
}

playergui.Visible = true

function playsound(s)
	local sound = playersounds[s]:Clone()
	sound.Parent = localplayer.PlayerScripts
	sound:Play()
	debris:AddItem(sound)
end

function findIDfromName(name)
	local thingies = ref:GetChildren()
	for i = 1, #thingies do
		if thingies[i].Value == name then
			return tonumber(thingies[i].Name)
		end
	end
end

function findEmptyslot()
	local rows = Snormalslots:GetChildren()
	for i = 1, #rows do
		local columns = rows[i]:GetChildren()
		for z = 1, #columns do
			if columns[z].Value == 0 then
				return columns[z]
			end
		end
	end
end

function findDupeslots(id)
	if ref[id]:FindFirstChild("Stackable") == nil then return nil end
	local dupes = {}
	local rows = Snormalslots:GetChildren()
	for i = 1, #rows do
		local columns = rows[i]:GetChildren()
		for z = 1, #columns do
			if columns[z].Value == tonumber(id) then
				table.insert(dupes, columns[z])
			end
		end
	end
	return dupes
end

function checkexists(name)
	for i = 1, #refkids do
		if refkids[i].Name == name then
			return refkids[i]
		end
	end
	return nil
end

function grab(handle)
	if handle:FindFirstChild("GrabForce") == nil then
		local mass = 0
		for i,v in pairs(handle.Parent:GetChildren()) do
			if v:IsA("BasePart") or v.ClassName == "Union" then
				mass = mass + v:GetMass()
			end
		end
		local bp = rmd.RemoteClone:InvokeServer(workspace.ServerDomain.Rec.GrabForce)
		rmd.RemoteMaxForce:FireServer(bp, Vector3.new(1e9,mass*workspace.Gravity + 100,1e9))
		rmd.Remoteposition:FireServer(bp, localcharacter.Head.Position)
		rmd.RemoteParent:FireServer(bp,handle)
		grabbing = handle
	end
end

mouse.Button1Down:connect(function()
	M1 = true
	if inventory.Mode.Value > 0 then return end
	if inventory.Mode.Value == 0 and #righthand:GetChildren() == 1 
		and stepTrack.IsPlaying == false 
		and rollTrack.IsPlaying == false then
		if localcharacter.Humanoid.Sit == false then
			local weapon = righthand:GetChildren()[1]
			local wepactive = weapon.Activate
			if weapon.Type.Value ~= "Instrument" and wepactive.Value == false then
				rmd.RemoteValue:FireServer(wepactive,true)
			end
		else
			inventory.Mode.Value = -1
			rmd.RemoteValue:FireServer(localcharacter.Equip.R:GetChildren()[1].Mode, inventory.Mode.Value)
		end
	elseif inventory.Mode.Value == -1 then
		local t = mouse.Target
		if t == nil then return end
		if stuff:FindFirstChild(t.Parent.Name) then
			if t.Parent:FindFirstChild("Permission") ~= nil then
				if t.Parent.Permission.Value ~= localplayer then
					rmd.RemoteWarning:FireServer("Not your drop!") 
					return
				end
			end
			grab(t.Parent.PrimaryPart)
			t.Parent.PrimaryPart:WaitForChild("GrabForce")
			lockcam()
			dist = 8
			while M1 == true and grabbing ~= nil do
				local dir = (localcharacter.Torso.Position-mouse.Hit.p).unit * 5
				local ray = Ray.new(localcharacter.Torso.Position,dir)
				local hit, mid = workspace:FindPartOnRayWithIgnoreList(ray, filtertable)
				local tempc = CFrame.new(mid,localcharacter.Torso.CFrame.p) * CFrame.new(0,0,-dist)
				rmd.Remoteposition:FireServer(grabbing.GrabForce, Vector3.new(tempc.x,tempc.y,tempc.z))
				wait()
			end
		end
	end
end)

function lockcam()
	local cc = workspace.CurrentCamera.CFrame
	local d = (Vector3.new(cc.x,cc.y,cc.z)-localcharacter.Head.Position).magnitude
	localplayer.CameraMaxZoomDistance = d
	localplayer.CameraMinZoomDistance = d
end

function unlockcam()
	localplayer.CameraMaxZoomDistance = 50
	localplayer.CameraMinZoomDistance = 5
end

function getRollDir()
	--Precondition: wasd ~= 0
	local c = workspace.CurrentCamera.CoordinateFrame
	local forward = (c.lookVector*Vector3.new(10,0,10)).unit
	local right = (c.rightVector*Vector3.new(10,0,10)).unit
	local recent = cacheWASD(false)
	if wasd > 1 then --Two (or more?) directions
		if wasding.W and wasding.S then
			if recent == 1 then
				return forward
			else
				return -forward
			end
		elseif wasding.A and wasding.D then
			if recent == 4 then
				return right
			else
				return -right
			end
		elseif wasding.W and wasding.D then
			return (forward+right).unit
		elseif wasding.W and wasding.A then
			return (forward-right).unit
		elseif wasding.S and wasding.D then
			return (-forward+right).unit
		elseif wasding.S and wasding.A then
			return (-forward-right).unit
		elseif wasding.W == true then
			return forward
		elseif wasding.S == true then
			return -forward
		elseif wasding.A == true then
			return -right
		elseif wasding.D == true then
			return right
		else
			if recent == 1 then
				return forward
			elseif recent == 2 then
				return -right
			elseif recent == 3 then
				return -forward
			elseif recent == 4 then
				return right
			end
		end
	else --One direction
		if wasding.W == true then
			return forward
		elseif wasding.A == true then
			return -right
		elseif wasding.S == true then
			return -forward
		elseif wasding.D == true then
			return right
		end
	end
	return forward --failsafe, crude but prevents any extraordinary faults
end
function backStep()
	if AV.Stamina.Value > 0 then
		playersounds.Roll.Pitch = 1 + math.random(-10,10)/100
		localcharacter.Humanoid.AutoRotate = false
		local setModeTo = inventory.Mode.Value
		local pointer = localcharacter.HumanoidRootPart
		local dir = -pointer.CFrame.lookVector
		inventory.Mode.Value = 9
		stepTrack:Play(.1,1,1.6)
		local bg = rmd.RemoteInstance:InvokeServer("BodyGyro","Invulnerable",pointer)
		bg.cframe = CFrame.new(pointer.Position,pointer.Position+dir*-2)
		bg.maxTorque = Vector3.new(1e9,1e9,1e9)
		bg.P = 1e9
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1e9,0,1e9)
		bv.Velocity = dir*20
		local hit = nil
		local stop = false
		local stopper = nil
		stopper = stepTrack.KeyframeReached:connect(function(key)
			if key == "Land" then
				stop = true
				stopper:disconnect()
			elseif key == "Woosh" then
				playersounds.Roll:Play()
				bv.Parent = pointer
				rmd.RemoteValue:FireServer(AV.Stamina,AV.Stamina.Value - rollCost)
			end
		end)
		repeat 
			if hit == nil and bv ~= nil then
				hit = workspace:FindPartOnRayWithIgnoreList(Ray.new(pointer.Position+Vector3.new(0,-0.5,0),dir*3),filtertable,false,true)
				if hit ~= nil or stop == true then
					bv:Destroy()
				end
			end
			wait()
		until stepTrack.IsPlaying == false
		local thread = coroutine.wrap(function()
			rmd.RemoteParent:FireServer(bg,nil)
		end)()
		pcall(function() bv:Destroy() end)
		inventory.Mode.Value = setModeTo
		localcharacter.Humanoid.AutoRotate = true
	else
		localplayer.PlayerScripts.Events.oos:Fire()
	end
end

function roll()
	if wasd == 0 then return end
	local thread = coroutine.wrap(function()
		if rollTrack.IsPlaying == false and localcharacter.Humanoid.Sit == false and localcharacter.Humanoid.PlatformStand == false then
			if AV.Stamina.Value > 0 then
				playersounds.Roll.Pitch = 1 + math.random(-10,10)/100
				playersounds.Roll:Play()
				local setmodeto = -1
				local pointer = localcharacter.HumanoidRootPart
				if inventory.Mode.Value == 0 then
					setmodeto = 0
				end
				localcharacter.Head.CollisionGroupId = 5
				localcharacter.Torso.CollisionGroupId = 5
				localcharacter.Humanoid.AutoRotate = false
				rollTrack:Play(.1,1,1.2)
				inventory.Mode.Value = 9
				local bv = Instance.new("BodyVelocity")
				local bg = nil
				local dir = getRollDir()
				coroutine.wrap(function()
					pcall(function() rmd.RemoteValue:FireServer(localcharacter.Equip.R:GetChildren()[1].Mode, inventory.Mode.Value) end)
					bg = rmd.RemoteInstance:InvokeServer("BodyGyro","Invulnerable",pointer)
					bg.cframe = CFrame.new(pointer.Position,pointer.Position+dir*2)
					pointer.CFrame = bg.cframe
					bg.maxTorque = Vector3.new(1e9,1e9,1e9)
					bg.P = 1e9
					rmd.RemoteValue:FireServer(AV.Stamina,AV.Stamina.Value - rollCost)
				end)()
				bv.Velocity = dir*25 * Vector3.new(1,0,1)
				bv.MaxForce = Vector3.new(1e9,1e9,1e9)
				bv.Parent = pointer
				local hit = nil
				repeat 
					if hit == nil and bv ~= nil then
						hit = workspace:FindPartOnRayWithIgnoreList(Ray.new(pointer.Position+Vector3.new(0,-0.5,0),dir*3),filtertable,false,true)
						local ground = workspace:FindPartOnRayWithIgnoreList(Ray.new(pointer.Position,Vector3.new(0,-4,0)),filtertable,false,true)
						if hit ~= nil or ground == nil then
							bv:Destroy()
						end
					end
					wait()
				until rollTrack.IsPlaying == false
				pcall(function() bv:Destroy() end)
				inventory.Mode.Value = setmodeto
				local thread = coroutine.wrap(function()
					rmd.RemoteParent:FireServer(bg,nil)
				end)()
				localcharacter.Head.CollisionGroupId = 1
				localcharacter.Torso.CollisionGroupId = 1
				localcharacter.Humanoid.AutoRotate = true
				if AV.Sprinting.Value == true then
					rmd.RemoteValue:FireServer(AV.Sprinting,false)
				end
			end
		end
	end)
	thread()
end

mouse.Button1Up:connect(function()
	M1 = false
	unlockcam()
	if grabbing ~= nil then
		pcall(function() rmd.RemoteParent:FireServer(grabbing.GrabForce,nil) end)
		grabbing = nil
	end
end)

mouse.WheelBackward:connect(function()
	if grabbing == nil then return end
	if dist > 8 then
		dist = dist - 1
	end
end)
mouse.WheelForward:connect(function()
	if grabbing == nil then return end
	if dist < 15 then
		dist = dist + 1
	end
end)

function checkequipment(item)
	local equipfolders = {"L","R","Head","Chest","Legs","Earrings","Ring"}
	for _, i in pairs(equipfolders) do
		if item.Parent.Name == i then
			return true
		end
	end
	return false
end

--[[
input.InputChanged:connect(function(obj,event)
	if obj.UserInputType == Enum.UserInputType.MouseMovement then
		print("delta is (" .. tostring(obj.Delta.x) .. ", " ..  tostring(obj.Delta.y) .. ")")
	end
	print(input.MouseBehavior)
end)
]]--

function wasWASD(code,generic)
	if (inventory.Mode.Value == 6 
		or inventory.Mode.Value == 99 or generic ~= nil)
		and (code == Enum.KeyCode.W 
			or code == Enum.KeyCode.A 
			or code == Enum.KeyCode.S 
			or code == Enum.KeyCode.D) then
		return true, string.sub(tostring(code),string.len(tostring(code)))
	end
end

function cacheWASD(op,key)
	--Keep track of last two
	if op then
		wasdCache[2] = wasdCache[1]
		wasdCache[1] = key
	else
		return wasdCache[1], wasdCache[2]
	end
end

input.InputBegan:connect(function(obj,event)
	if playergui.ChatFrame.Input:IsFocused() == true then return end
	local processed = false
	--CORE
	local WASD, key = wasWASD(obj.KeyCode,true)
	if WASD == true then
		wasd = wasd + 1
		wasding[key] = true
	end
	if obj.KeyCode == Enum.KeyCode.W then
		cacheWASD(true,1)
	elseif obj.KeyCode == Enum.KeyCode.A then
		cacheWASD(true,2)
	elseif obj.KeyCode == Enum.KeyCode.S then
		cacheWASD(true,3)
	elseif obj.KeyCode == Enum.KeyCode.D then
		cacheWASD(true,4)
	--[[elseif obj.KeyCode == Enum.KeyCode.Space 
		and (inventory.Mode.Value == -1 
			or inventory.Mode.Value == 0 
			or inventory.Mode.Value == 3) then
		localcharacter.Humanoid:SetStateEnabled("Swimming",true)]]
	elseif obj.KeyCode == Enum.KeyCode.F and inventory.Mode.Value == 7 then
			ChatClass.nextMethod()
			processed = true
	elseif obj.KeyCode == Enum.KeyCode.B then
		if not inventory.Visible 
			and (inventory.Mode.Value == -1 
			or inventory.Mode.Value == 0 
			or inventory.Mode.Value == 6 
			or inventory.Mode.Value == 99) then
			inventory.Visible = true
			playsound("Bag")
		elseif inventory.Visible then
			inventory.Visible = false
			playsound("Bag")
		end	
		starterGui.lockOverride.Value = not inventory.Visible
	end
	--Secondary
	if inventory.Mode.Value <= 0 and grabbing == nil and processed == false then
		if obj.KeyCode == Enum.KeyCode.LeftShift then
			abortRoll = false
			if localcharacter.Humanoid.Sit == false and localcharacter.Torso.Velocity.magnitude > 1 then
				if AV.Stamina.Value > 0 then 
					rmd.RemoteValue:FireServer(sprinting,true) 
					coroutine.wrap(function()
						wait(.14)
						abortRoll = true
					end)()
				else
					localplayer.PlayerScripts.Events.oos:Fire()
				end
			end
		elseif obj.KeyCode == Enum.KeyCode.R then
			if #localcharacter.Equip.R:GetChildren() > 0 then
				if localcharacter.Humanoid.Sit == false then
					if localcharacter.Equip.R:GetChildren()[1].Activate.Value == false and sheathDeb == false then
						sheathDeb = true
						if inventory.Mode.Value == 0 then
							inventory.Mode.Value = -1
							playersounds.Sheathe:Play()
						elseif inventory.Mode.Value == -1 then
							if localcharacter.Humanoid.Sit == true then
								localcharacter.Humanoid.Sit = false
								if localcharacter.Torso:FindFirstChild("Seat") then
									rmd.RemoteParent:FireServer(localcharacter.Torso.Seat.Value,nil)
									localcharacter.Torso.Seat:Destroy()
								end
							end
							inventory.Mode.Value = 0
							playersounds.Sheathe:Play()
						end
						wait(rmd.RemoteValue:FireServer(localcharacter.Equip.R:GetChildren()[1].Mode, inventory.Mode.Value))
						sheathDeb = false
					end
				else
					inventory.Mode.Value = -1
					rmd.RemoteValue:FireServer(localcharacter.Equip.R:GetChildren()[1].Mode, inventory.Mode.Value)
				end
			end
		elseif obj.KeyCode == Enum.KeyCode.J then
			local n = not journal.Visible;
			journal.Visible = n
			starterGui.lockOverride.Value = not n
			playsound("Click")
		elseif obj.KeyCode == Enum.KeyCode.K then
			local n = not playergui.Professions.Visible;
			playergui.Professions.Visible = n
			starterGui.lockOverride.Value = not n
			playsound("Click")
		elseif obj.KeyCode == Enum.KeyCode.C then
			local n = not playergui.Attributes.Visible;
			playergui.Attributes.Visible = n
			starterGui.lockOverride.Value = not n
			playsound("Click")
		elseif obj.KeyCode == Enum.KeyCode.H then
			local n = not playergui.Emotes.Visible;
			playergui.Emotes.Visible = n
			starterGui.lockOverride.Value = not n
			playsound("Click")
		elseif obj.KeyCode == Enum.KeyCode.F then
			local function isPlayer(part)
				for _, p in pairs(game.Players:GetChildren()) do
					if part:IsDescendantOf(p.Character) then
						return p
					end
				end
				return nil
			end
			local target = mouse.Target
			if target == nil then return end
			local interactable = checkactor(target,"Interactable")
		--	if target.Locked == true then return end
			if (mouse.Hit.p - localcharacter.Torso.Position).magnitude <= mouserange then
				if stuff:FindFirstChild(target.Parent.Name) then --Pick up
					if checkequipment(target.Parent) == true then return end
					if target.Parent:FindFirstChild("Permission") ~= nil then
						if target.Parent.Permission.Value ~= localplayer then
							rmd.RemoteWarning:FireServer("Not your drop!") 
							return
						end
					end
					local id = findIDfromName(target.Parent.Name)
					local amt = 1
					if target.Parent:FindFirstChild("Amount") then
						amt = target.Parent.Amount.Value
					end
					iMethods.giveItem(localplayer,id,amt)
					rmd.RemoteParent:FireServer(target.Parent,nil)
				--Begin interacts
				elseif interactable ~= nil then
					local iv = interactable.Interactable.Value
					if iv == "Toggle" then
						local cd = interactable:FindFirstChild("CD")
						wait(.1)
						if cd then if cd.Value == true then return end end
						local toggle = interactable.Toggle
						rmd.RemoteValue:FireServer(toggle, not toggle.Value)
					elseif iv == "Door" then
						if interactable.Toggle.Value == false then
							rmd.RemoteValue:FireServer(interactable.Toggle, true)
						end
					elseif iv == "ChatInterest" then
						print("Conversation requested, status: " .. ChatClass.status)
						if ChatClass.status == "Idle" then
							local chats = interactable.ChatInterest:FindFirstChild("Dialogues")
							if chats ~= nil then
								ChatClass.newDialogue(chats.nChat)
								while ChatClass.status == "Conversing" do
									if (localcharacter.Torso.Position-target.Position).magnitude > mouserange then
										ChatClass.endChat()
									end
									wait()
								end
							else
								ChatClass.newDialogue(game.ReplicatedStorage.NoDialogue)
								while ChatClass.status == "Conversing" do
									if (localcharacter.Torso.Position-target.Position).magnitude > mouserange then
										ChatClass.endChat()
									end
									wait()
								end
							end
						end
					elseif iv == "CraftingStation" then
						if CraftClass.status == "Idle" then
							playsound("Click")
							CraftClass.newSession(interactable.CraftingStation)
							while CraftClass.status == "Crafting" do
								if (localcharacter.Torso.Position-target.Position).magnitude > mouserange then
									CraftClass.endSession()
								end
								wait()
							end
						end
					elseif iv == "SmallPlant" then
						if interactable.Mature.Value == true then
							local yieldStr = interactable.Plant.Value
							local yieldId = iMethods.getItemId(yieldStr)
							local amt = math.random(interactable.Plant.low.Value,interactable.Plant.high.Value)
							iMethods.giveItem(localplayer,yieldId,amt)
							localplayer.PlayerScripts.Events.Gathered:Fire(stuff[yieldStr],"Farming",workspace.ServerDomain.ExpRewards[interactable.Exp.Value].Value)
							rmd.RemoteParent:FireServer(interactable,nil)
						end
					elseif iv == "Tree" then
						if save.Equipped.Tool.Value > 0 and stuff[ref[tostring(save.Equipped.Tool.Value)].Value].Type.Value == "Lumberaxe" then
							if interactable.Mature.Value == true then
								local tool = equips.Tool:GetChildren()[1]
								rmd.RemoteValue:FireServer(tool.Gather,interactable.Stump)
								inventory.Mode.Value = 6
								local connection = nil
								local connectionB = nil
								connection = tool.Gather.Changed:connect(function(val)
									if val == nil or tool == nil then
										inventory.Mode.Value = -1
										connection:disconnect()
									end
								end)
								connectionB = game:GetService("UserInputService").InputBegan:connect(function(obj) 
									if tool:FindFirstChild("Cancel") == nil or (tool.Cancel.Value == false and wasWASD(obj.KeyCode) == true) then 
										pcall(function() rmd.RemoteValue:FireServer(tool.Cancel,true) end)
										connectionB:disconnect()
									end 
								end)
							else
								rmd.RemoteWarning:FireServer("Tree is dead!")
							end
						else
							rmd.RemoteWarning:FireServer("You need a lumberaxe equipped!")
						end
					elseif iv == "Mineral" then
						if save.Equipped.Tool.Value > 0 and stuff[ref[tostring(save.Equipped.Tool.Value)].Value].Type.Value == "Pickaxe" then
							if interactable.Compressed.Value == true then
								local tool = equips.Tool:GetChildren()[1]
								rmd.RemoteValue:FireServer(tool.Gather,interactable.Rock)
								inventory.Mode.Value = 6
								local connection = nil
								local connectionB = nil
								connection = tool.Gather.Changed:connect(function(val)
									if val == nil or tool == nil then
										inventory.Mode.Value = -1
										connection:disconnect()
									end
								end)
								connectionB = game:GetService("UserInputService").InputBegan:connect(function(obj) 
									if tool:FindFirstChild("Cancel") == nil or (tool.Cancel.Value == false and wasWASD(obj.KeyCode) == true) then 
										pcall(function() rmd.RemoteValue:FireServer(tool.Cancel,true) end)
										connectionB:disconnect()
									end 
								end)
							else
								rmd.RemoteWarning:FireServer("Vein is depleted!")
							end
						else
							rmd.RemoteWarning:FireServer("You need a pickaxe equipped!")
						end
					elseif iv == "Fishing" then
						if save.Equipped.Tool.Value > 0 and stuff[ref[tostring(save.Equipped.Tool.Value)].Value].Type.Value == "FishingRod" then
							if interactable.Spot.PE.Enabled == true then
								local tool = equips.Tool:GetChildren()[1]
								rmd.RemoteValue:FireServer(tool.Gather,interactable.Spot)
								inventory.Mode.Value = 6
								local connection = nil
								local connectionB = nil
								connection = tool.Gather.Changed:connect(function(val)
									if val == nil or tool == nil then
										inventory.Mode.Value = -1
										connection:disconnect()
									end
								end)						
								connectionB = game:GetService("UserInputService").InputBegan:connect(function(obj) 
									if tool:FindFirstChild("Cancel") == nil or (tool.Cancel.Value == false and wasWASD(obj.KeyCode) == true) then 
										pcall(function() rmd.RemoteValue:FireServer(tool.Cancel,true) end)
										connectionB:disconnect()
									end 
								end)
							else
								rmd.RemoteWarning:FireServer("No more fish!")
							end
						else
							rmd.RemoteWarning:FireServer("You need a fishing rod equipped!")
						end
					elseif iv == "Bank" then
						if save.Bank.Value == "" then
							BankClass.bankString = game:GetService("HttpService"):JSONEncode({Items = {}, Tabs = {"Main"}, MaxWeight = 1e5, Money = 0})
						else
							BankClass.bankString = save.Bank.Value
						end
						BankClass.desk = interactable
						BankClass.openBank()
						while BankClass.status == "Banking" 
							and localplayer:DistanceFromCharacter(target.Position) < mouserange do
							wait()
						end
						if localplayer:DistanceFromCharacter(target.Position) > mouserange then BankClass.closeBank() end
					elseif iv == "Loot" then
						if playergui.PromptGui.Enabled == true then
							playergui.PromptGui.Enabled = false
							targetPlayer = nil
						end
						playsound("Bag")
						if lootTarget == interactable then
							for _, item in ipairs(lootTarget.Loot:GetChildren()) do
								if item.Name ~= "Coines" then
									iMethods.giveItem(localplayer,item.Name,item.Value,true)
								else
									playsound("Ching")
									wait(rmd.RemoteValue:FireServer(save.Silver,save.Silver.Value + item.Value))
								end
								localplayer.PlayerScripts.Events.Loot:Fire(item)
							end
							lootTarget:Destroy()
							lootTarget = nil
							interactable = nil
						else
							lootTarget = interactable
							local function listLoot()
								if interactable ~= nil and interactable:FindFirstChild("Loot") ~= nil then
									lootFrame.Trim.Confirm.Visible = false
									lootFrame.Loot:ClearAllChildren()
									local lootStuff = interactable.Loot:GetChildren()
									if #lootStuff > 0 then
										for _, item in ipairs(lootStuff) do
											local itemGui = lootFrame.Item:Clone()
											pcall(function() itemGui.Icon.Image = tex[item.Name] end)
											itemGui.Label.Text = item.Name
											itemGui.Amt.Text = item.Value
											itemGui.MouseMoved:connect(function() --highlight
												itemGui.BackgroundColor3 = Color3.new(80/255,80/255,80/255)
											end)
											itemGui.MouseLeave:connect(function() --delight
												itemGui.BackgroundColor3 = Color3.new(0,0,0)
											end)
											itemGui.MouseButton2Click:connect(function() --take individual
												local remainder = nil
												if item.Name ~= "Coines" then
													remainder = iMethods.giveItem(localplayer,item.Name,item.Value)
												else
													playsound("Ching")
													wait(rmd.RemoteValue:FireServer(save.Silver,save.Silver.Value + item.Value))
												end
												if remainder == 0 then
													item:Destroy()
													itemGui.Visible = false
												end
												localplayer.PlayerScripts.Events.Loot:Fire(item)
											end)
											itemGui.Position = UDim2.new(0,0,0,#lootFrame.Loot:GetChildren()*(itemGui.Size.Y.Offset+5))
											itemGui.Parent = lootFrame.Loot
											itemGui.Visible = true
										end
										if #lootStuff >= 3 then
											lootFrame.Loot.CanvasSize = UDim2.new(1,0,0,#lootFrame.Loot:GetChildren()*(lootFrame.Item.Size.Y.Offset+5)-5)
										else
											lootFrame.Loot.CanvasSize = UDim2.new(1,0,1,1)
										end
									else
										playsound("Bag")
										lootFrame.Visible = false
										lootTarget = nil
										interactable:Destroy()
										interactable = nil
									end
								end
							end	
							--setup complete, display loot list
							listLoot()						
							
							local vec, b = workspace.CurrentCamera:WorldToScreenPoint(interactable.PrimaryPart.Position)
							local halfX = lootFrame.Size.X.Offset/2
							local halfY = lootFrame.Size.Y.Offset/2
							lootFrame.Position = UDim2.new(0,vec.X-halfX,0,vec.Y-halfY)
							lootFrame.Visible = true
							
							local listUpdate = nil					
							local trash = nil
							local confirm = nil
							local hideConfirm = nil
							local takeAll = nil
							listUpdate = lootTarget.Loot.ChildRemoved:connect(function()
								if lootTarget ~= nil and interactable ~= nil then
									listLoot()
								else
									lootFrame.Loot:ClearAllChildren()
									lootFrame.Visible = false
									trash:disconnect()
									confirm:disconnect()
									hideConfirm:disconnect()
									listUpdate:disconnect()
								end
							end)	
							takeAll = lootFrame.Trim.All.MouseButton1Click:connect(function()
								for _, item in ipairs(lootTarget.Loot:GetChildren()) do
									if item.Name ~= "Coines" then
										iMethods.giveItem(localplayer,item.Name,item.Value,true)
									else
										playsound("Ching")
										wait(rmd.RemoteValue:FireServer(save.Silver,save.Silver.Value + item.Value))
									end
									localplayer.PlayerScripts.Events.Loot:Fire(item)
								end
								listUpdate:disconnect()
								lootTarget:Destroy()
								lootTarget = nil
								interactable = nil
							end)
							trash = lootFrame.Trim.Close.MouseButton1Click:connect(function()
								lootFrame.Trim.Confirm.Visible = true
							end)
							confirm = lootFrame.Trim.Confirm.MouseButton1Click:connect(function()
								listUpdate:disconnect()
								lootTarget:Destroy()
								lootTarget = nil
								interactable = nil
							end)
							hideConfirm = lootFrame.Trim.Confirm.MouseLeave:connect(function()
								lootFrame.Trim.Confirm.Visible = false
							end)
							--displaying, hide when walked too far or finished looting
							while lootTarget ~= nil 
								and (lootTarget.PrimaryPart.Position - localcharacter.Torso.Position).magnitude < mouserange do
								wait()
							end
							lootFrame.Loot:ClearAllChildren()
							lootFrame.Visible = false
							listUpdate:disconnect()
							trash:disconnect()
							confirm:disconnect()
							hideConfirm:disconnect()
						end
					elseif iv == "Seat" and localcharacter.Humanoid.Sit == false then
						if interactable.Torso:FindFirstChild("Seat") == nil then
							rmd.RemoteSeat:FireServer(interactable)
							if inventory.Mode.Value == 0 then
								inventory.Mode.Value = -1
								wait(rmd.RemoteValue:FireServer(localcharacter.Equip.R:GetChildren()[1].Mode, inventory.Mode.Value))
							end
						else
							rmd.RemoteWarning:FireServer("Taken!")
						end
					end
					--End interacts
				elseif isPlayer(target) ~= nil then
					--print("Options")
					if lootFrame.Visible == true then
						lootFrame.Visible = false
						lootFrame.Loot:ClearAllChildren()
						lootTarget = nil
						interactable = nil
						playsound("Bag")
					end
					local p = isPlayer(target)
					playergui.PromptGui.Adornee = p.Character.HumanoidRootPart
					playergui.PromptGui.Enabled = true
					playergui.PromptGui.Frame.ActorName.Text = p.Name
					targetPlayer = p
					while targetPlayer == p 
						and (p.Character.PrimaryPart.Position-localcharacter.PrimaryPart.Position).magnitude < mouserange do
						wait()
					end
					targetPlayer = nil
					playergui.PromptGui.Enabled = false
				end
			end
		elseif obj.KeyCode == Enum.KeyCode.T then
			if targetPlayer ~= nil and inventory.Mode.Value == -1 then
				tradeMethods.requestTrade(targetPlayer)
				playergui.PromptGui.Enabled = false
				targetPlayer = nil
			elseif lootTarget ~= nil and inventory.Mode.Value <= 0 then
				for _, item in ipairs(lootTarget.Loot:GetChildren()) do
					if item.Name ~= "Coines" then
						iMethods.giveItem(localplayer,item.Name,item.Value,true)
					else
						playsound("Ching")
						wait(rmd.RemoteValue:FireServer(save.Silver,save.Silver.Value + item.Value))
					end
				end
				lootTarget:Destroy()
				lootTarget = nil
			end
		elseif obj.KeyCode == Enum.KeyCode.G then
			if targetPlayer ~= nil and inventory.Mode.Value <= 0 then
				local function inviteToParty(id)
					if savehub[id.."s Save"].Party.Value <= 0 then
						local hasInvitation = workspace.ServerDomain.PartyInvites:FindFirstChild(id) ~= nil
						if not hasInvitation then
							rmd.RemoteHttp:InvokeServer("sendInvite",id)
						else
							rmd.RemoteWarning:FireServer("Player has pending invitations.")
						end
					else
						rmd.RemoteWarning:FireServer("Player is in another party.")
					end
				end
				local id = targetPlayer.userId
				local roster = "No Party"
				local numMembers = 0
				local host = nil
				if save.Party.Value > 0 then
					roster = rmd.RemoteHttp:InvokeServer("getParty",save.Party.Value)
					for p in string.gmatch(roster,"%[%w+%]") do
						if host == nil then
							host = tonumber(string.sub(p,2,string.len(p)-1))
						end
						numMembers = numMembers + 1
					end
					if localplayer.userId == host then
						if numMembers < 6 then
							inviteToParty(id)
						else
							rmd.RemoteWarning:FireServer("Your party is full.")
						end
					else
						rmd.RemoteWarning:FireServer("Only the party leader may invite.")
					end
				else
					inviteToParty(id)
				end
				playergui.PromptGui.Enabled = false
				targetPlayer = nil
			end
		elseif obj.KeyCode == Enum.KeyCode.U then
			playergui.PromptGui.Enabled = false
			--follow
		end
		--HOTKEYS
		if playergui.Inventory.Bag.ClickMenu.Visible == false then
			if obj.KeyCode == Enum.KeyCode.One then
				hotbar.A.ButtonDown.Value = true
			elseif obj.KeyCode == Enum.KeyCode.Two then
				hotbar.B.ButtonDown.Value = true
			elseif obj.KeyCode == Enum.KeyCode.Three then
				hotbar.C.ButtonDown.Value = true
			elseif obj.KeyCode == Enum.KeyCode.Four then
				hotbar.D.ButtonDown.Value = true
			elseif obj.KeyCode == Enum.KeyCode.Five then
				hotbar.E.ButtonDown.Value = true
			elseif obj.KeyCode == Enum.KeyCode.Six then
				hotbar.F.ButtonDown.Value = true
			elseif obj.KeyCode == Enum.KeyCode.Seven then
				hotbar.G.ButtonDown.Value = true
			end
		end
	end
end)

function changestance(dir)
	if #localcharacter.Equip.R:GetChildren() == 0 or localcharacter.Equip.R:GetChildren()[1].Type.Value == "Instrument" then return end
	local stanceObj = localcharacter.Equip.R:GetChildren()[1].Stance
	local skillList = {}
	for _, skill in pairs(stances:GetChildren()) do
		skillList[tonumber(skill.Name)] = skill
	end
	local limit = #skillList
	local currentStance = stanceObj.Value
	local test = currentStance + dir
	if test < 1 then
		currentStance = limit
	elseif test > limit then
		currentStance = 1
	else
		currentStance = test
	end
	skillList[currentStance].Force.Value = not skillList[currentStance].Force.Value
end

function attacking()
	local weapon = localcharacter.Equip.R:GetChildren()[1]
	if weapon ~= nil and weapon.Activate.Value == true then
		return true
	else
		return false
	end
end

input.InputEnded:connect(function(obj,event)
	local WASD, key = wasWASD(obj.KeyCode,true)
	if WASD == true and wasding[key] == true then
		wasd = wasd - 1
		wasding[key] = false
	end
	if obj.KeyCode == Enum.KeyCode.Slash and 
		(inventory.Mode.Value == -1 or 
		inventory.Mode.Value == 0 or 
		inventory.Mode.Value == 6 or 
		inventory.Mode.Value == 99 or
		inventory.Mode.Value == 1 or
		inventory.Mode.Value == 2 or
		inventory.Mode.Value == 5) then
		if playergui.ChatFrame.Input:IsFocused() == false then
			playergui.ChatFrame.Input:CaptureFocus()
		end
	end
	--HOTKEYS
	if obj.KeyCode == Enum.KeyCode.One then
		hotbar.A.ButtonDown.Value = false
	elseif obj.KeyCode == Enum.KeyCode.Two then
		hotbar.B.ButtonDown.Value = false
	elseif obj.KeyCode == Enum.KeyCode.Three then
		hotbar.C.ButtonDown.Value = false
	elseif obj.KeyCode == Enum.KeyCode.Four then
		hotbar.D.ButtonDown.Value = false
	elseif obj.KeyCode == Enum.KeyCode.Five then
		hotbar.E.ButtonDown.Value = false
	elseif obj.KeyCode == Enum.KeyCode.Six then
		hotbar.F.ButtonDown.Value = false
	elseif obj.KeyCode == Enum.KeyCode.Seven then
		hotbar.G.ButtonDown.Value = false
	end
	if inventory.Mode.Value > 0 then return end
	if obj.KeyCode == Enum.KeyCode.LeftShift then
		local state = localcharacter.Humanoid:GetState()
		if wasd > 0 and not abortRoll and state ~= Enum.HumanoidStateType.Jumping 
			and state ~= Enum.HumanoidStateType.Freefall then
			abortRoll = true 
			roll()
		elseif localcharacter.Humanoid.Sit == false 
			and localcharacter.Torso.Velocity.Magnitude < 2 
			and not attacking() then
			backStep()
		end
		rmd.RemoteValue:FireServer(sprinting,false)
	elseif obj.KeyCode == Enum.KeyCode.Q then
		changestance(-1)
	elseif obj.KeyCode == Enum.KeyCode.E then
		changestance(1)
	elseif obj.KeyCode == Enum.KeyCode.Space then
		localcharacter.Humanoid:SetStateEnabled("Swimming",false)
	end
end)

input.InputBegan:connect(function(obj)
	local equippedTool = localcharacter:WaitForChild("Equip").R:GetChildren()[1]
	if equippedTool ~= nil and equippedTool.Type.Value == "Instrument" and inventory.Mode.Value == 0 then
		if obj.KeyCode == Enum.KeyCode.One then
			equippedTool.Played:FireServer(0)
		elseif obj.KeyCode == Enum.KeyCode.Two then
			equippedTool.Played:FireServer(1)
		elseif obj.KeyCode == Enum.KeyCode.Three then
			equippedTool.Played:FireServer(2)
		elseif obj.KeyCode == Enum.KeyCode.Four then
			equippedTool.Played:FireServer(3)
		elseif obj.KeyCode == Enum.KeyCode.Five then
			equippedTool.Played:FireServer(4)
		elseif obj.KeyCode == Enum.KeyCode.Six then
			equippedTool.Played:FireServer(5)
		elseif obj.KeyCode == Enum.KeyCode.Seven then
			equippedTool.Played:FireServer(6)
		elseif obj.KeyCode == Enum.KeyCode.Eight then
			equippedTool.Played:FireServer(7)
		end
	end
end)

input.JumpRequest:connect(function()
	local state = localcharacter.Humanoid:GetState()
	if (state == Enum.HumanoidStateType.Running 
	or state == Enum.HumanoidStateType.RunningNoPhysics) 
	and (inventory.Mode.Value == -1 or inventory.Mode.Value == 0) then
		if AV.Stamina.Value > 0 then
			localcharacter.Humanoid.JumpPower = 50
			local predict = AV.Stamina.Value - jumpCost
			rmd.RemoteValue:FireServer(AV.Stamina,predict)
		else
			localcharacter.Humanoid.JumpPower = 0
			localplayer.PlayerScripts.Events.oos:Fire()
		end
	else
		if localcharacter.Humanoid.Sit == true then
			localcharacter.Humanoid.Sit = false
			if localcharacter.Torso:FindFirstChild("Seat") then
				rmd.RemoteParent:FireServer(localcharacter.Torso.Seat.Value,nil)
				localcharacter.Torso.Seat:Destroy()
			end
		end
		localcharacter.Humanoid.JumpPower = 0
	end
end)

--[[
local inFOV = false
local outFOV = false

function zIn()
	inFOV = true
	outFOV = false
	local cF = workspace.CurrentCamera.FieldOfView
	local incr = (70 - cF)/10
	for _ = 1, 10 do
		if inFOV == true then
			workspace.CurrentCamera.FieldOfView = workspace.CurrentCamera.FieldOfView + incr
		else
			break
		end
		wait()
	end
end

function zOut()
	inFOV = false
	outFOV = true
	local cF = workspace.CurrentCamera.FieldOfView
	local incr = (90 - cF)/10
	for _ = 1, 10 do
		if outFOV == true then
			workspace.CurrentCamera.FieldOfView = workspace.CurrentCamera.FieldOfView + incr
		else
			break
		end
		wait()
	end
end

sprinting.Changed:connect(function(val)
	if val == true then
		zOut()
	else
		zIn()
	end
end)
]]

unlockcam()

localcharacter.Humanoid.JumpPower = 0