local m = {}

local player = game.Players.LocalPlayer
local rmd = game.ReplicatedStorage.RemoteDump
local stuff = game.ReplicatedStorage.Stuff
local tex = game.ReplicatedStorage.Textures
local ref = game.ReplicatedStorage.References
local sDomain = workspace.ServerDomain
local iMethods = require(player.PlayerScripts.InventoryMethods)
local cMethods = require(player.PlayerScripts.ClientMethods)
local save = workspace.ServerDomain.SaveHub:WaitForChild(player.UserId .. 's Save')

local bin = script.Parent
local listGui = bin.List
local folderGui = bin.Folders
local saleGui = bin.Sales
local ribbon = bin.Ribbon
local trim = bin.Trim
local lTrim = bin.LowerTrim
local infoGui = bin.HoverInfo

local tab = 0
local filterString = ''
local filterType = 'All'
local listings = {}
local folders = {}
local history = {}
local sales = {}
local properties = {
	'Index',
	'Seller',
	'Item',
	'Amt',
	'Per',
	'Bought'
}
local sProperties = {
	'Index',
	'Lifespan',
	'Item',
	'Amt',
	'Per',
	'Bought'
}
local hProperties = {
	'Item',
	'Price'
}
local armors = {
	'Hands',
	'Feet',
	'Chest',
	'Helmet',
	'Neck',
	'Legs',
	'Lantern'
}
local tools = {
	'Bladed Weapon',
	'Blunt Weapon',
	'Tome',
	'Staff',
	'Wand',
	'Ammo',
	'Shield',
	'Pickaxe',
	'Lumberaxe'
}
local checking = false
local slotEvents = {}
local selectedKey = ''

m.open = false

function checkSiteStatus()
	local check = rmd.RemoteHttp:InvokeServer('check')
	if check == false then
		bin.Down.Visible = true
		bin.List.Visible = false
		bin.Sales.Visible = false
		bin.Bag.Visible = false
		pcall(function() bin.BuyPrompt:Destroy() end)
		pcall(function() bin.SellPrompt:Destroy() end)
		bin.Ribbon.Filters.Visible = true
		bin.Ribbon.Folder.Visible = false
		bin.Ribbon.Back.Visible = false
		bin.Ribbon.Selling.Visible = false
	else
		bin.Down.Visible = false
	end
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

function refresh()
	checkSiteStatus()
	if tab == 0 then
		wait(getMarket())
		if listGui.Visible == true then
			drawListings(selectedKey)
		else
			drawFolders()
		end
	else
		wait(getSales())
		drawSales()
	end
end

function wipe()
	for _, i in ipairs(folderGui:GetChildren()) do
		i:Destroy()
	end
	for _, i in ipairs(listGui:GetChildren()) do
		i:Destroy()
	end
	for _, i in ipairs(saleGui:GetChildren()) do
		i:Destroy()
	end
end

function drawTrim()
	lTrim.Stud.Money.Text = cMethods.commafy(save.Silver.Value)
	local open,have = iMethods.getNumSlots(player)
	lTrim.Slots.Text = 'Empty Slots: ' .. open .. '/' .. have
end

function category(str) 
	for _, i in ipairs(tools) do
		if i == str then
			return 'Tool' 
		end
	end
	for _, i in ipairs(armors) do
		if i == str then
			return 'Armor' 
		end
	end
	return str
end

function valueSort(a,b)
	return tonumber(a.Per) < tonumber(b.Per)
end

function nameSort(a,b)
	return string.lower(a.Item) < string.lower(b.Item)
end

function drawSlot(slot)
	local data = save.Inv[slot.Parent.Name][slot.Name]
	local iRef = nil
	local icon = slot.ClickSlot
	local texture = nil
	if data.Value <= 0 or data['#'].Value <= 0 then
		icon.ImageColor3 = Color3.new(124/255,124/255,124/255)
		icon.BorderSizePixel = 0
		if data.Value == -1 then
			icon['#'].Text = ''
			icon.Image = 'rbxgameasset://Images/Lock FIXED'
		else
			icon['#'].Text = ''
			icon.Image = ''
		end
	else
		iRef = ref[data.Value]
		icon.ImageColor3 = Color3.new(1,1,1)
		texture = tex:FindFirstChild(iRef.Value)
		if texture ~= nil then
			icon.Image = 'rbxassetid://' .. texture.Value
		else
			icon.Image = ''
		end
		if data['#'].Value > 1 then 
			icon['#'].Text = cMethods.commafy(data['#'].Value)
		else
			icon['#'].Text = ''
		end
		local color = sDomain.Rarities[iRef.Rarity.Value].Value
		icon.BorderSizePixel = 2		
		icon.BorderColor3 = color
		table.insert(slotEvents,icon.MouseMoved:connect(function(x,y)
			if data.Value > 0 and bin.Loading.Visible == false and bin:FindFirstChild('BuyPrompt') == nil and bin:FindFirstChild('SellPrompt') == nil then
				drawInfo(x,y,ref:FindFirstChild(data.Value))
			end
			icon.ImageTransparency = 0
		end))
		table.insert(slotEvents,icon.MouseLeave:connect(function()
			infoGui.Visible = false
			icon.ImageTransparency = 0.1
		end))
		table.insert(slotEvents,icon.MouseButton1Click:connect(function()
			infoGui.Visible = false
			local amt = 1
			local per = 1
			local max = 1
			if bin:FindFirstChild('SellPrompt') then
				bin.SellPrompt:Destroy()
			end
			local sPrompt = script.SellPrompt:Clone()
			sPrompt.Label.Text = 'Listing: ' .. iRef.Value
			sPrompt.SubTotal.Text = per*amt
			sPrompt.Total.Text = math.ceil(per*amt*.8)
			if iRef:FindFirstChild('Stackable') then
				max = iRef.Stackable.Value
				local have = iMethods.have(data.Value)
				if have >= max then
					sPrompt.Amt.Max.Text = '/' .. cMethods.commafy(iRef.Stackable.Value)
				else
					max = have
					sPrompt.Amt.Max.Text = '/' .. have
				end
			else
				sPrompt.Amt.Max.Text = '/1'
			end
			sPrompt.Amt.Focused:connect(function()
				sPrompt.Sell.Hide.Visible = true
			end)
			sPrompt.Per.Focused:connect(function()
				sPrompt.Sell.Hide.Visible = true
			end)
			sPrompt.Amt.FocusLost:connect(function()
				amt = tonumber(sPrompt.Amt.Text)
				if amt ~= nil then
					if amt > max then
						amt = max
						sPrompt.Amt.Text = max
					elseif amt <= 0 then
						amt = 1
						sPrompt.Amt.Text = 1
					end
					sPrompt.Sell.Hide.Visible = false
					sPrompt.SubTotal.Text = cMethods.commafy(amt*per)
					sPrompt.Total.Text = cMethods.commafy(math.ceil(amt*per*.8))
				end
			end)
			sPrompt.Per.FocusLost:connect(function()
				per = tonumber(sPrompt.Per.Text)
				if per ~= nil then
					if per > 999999999 then
						per = 999999999
						sPrompt.Per.Text = '999,999,999'
					elseif per <= 0 then
						per = 1
						sPrompt.Per.Text = '1'
					end
					sPrompt.Sell.Hide.Visible = false
					sPrompt.SubTotal.Text = cMethods.commafy(amt*per)
					sPrompt.Total.Text = cMethods.commafy(math.ceil(amt*per*.8))
				end
			end)
			sPrompt.Cancel.MouseButton1Click:connect(function()
				sPrompt:Destroy()
			end)
			sPrompt.Sell.MouseButton1Click:connect(function()
				sPrompt.Visible = false
				local writeTo = rmd.RemoteHttp:InvokeServer('sell',amt,iRef.Value,per)
				if writeTo == 'Listed.' then
					iMethods.takeItem(player,data.Value,amt)
				else
					rmd.RemoteWarning:FireServer(writeTo)
				end
				refresh()
				drawSlots()
				sPrompt:Destroy()
			end)
			sPrompt.Parent = bin
		end))
	end
end

function drawInfo(dx,dy,iRef)
	local item = stuff[iRef.Value]
	infoGui.Visible = true
	local x = bin.AbsolutePosition.X + infoGui.AbsoluteSize.X + 2
	local y = bin.AbsolutePosition.Y + 35
	infoGui.Position = UDim2.new(0,dx,0,dy) - UDim2.new(0,x,0,y)
	infoGui.Info.Text = iRef.Info.Value
	infoGui.Info.TextWrapped = false
	infoGui.BorderColor3 = sDomain.Rarities[iRef.Rarity.Value].Value
	local textlength = infoGui.Info.TextBounds.X
	local lines = math.ceil(textlength/infoGui.Info.AbsoluteSize.X)
	infoGui.Info.Size = UDim2.new(1, -20, 0, 14+14*lines)
	infoGui.Info.TextWrapped = true
	infoGui.Size = UDim2.new(0, 130, 0, 134+(14*lines))
	infoGui.Quality.Text = iRef.Rarity.Value
	infoGui.Quality.TextColor3 = sDomain.Rarities[iRef.Rarity.Value].Value
	infoGui.Quality.TextStrokeColor3 = sDomain.Rarities[iRef.Rarity.Value].Value
	infoGui.LABELName.Text = iRef.Value
	infoGui.Weight.Text = 'Weight: ' .. iRef.Weight.Value .. ' grain(s)'
	if iRef:FindFirstChild('Stackable') then
		infoGui.Weight.Text = infoGui.Weight.Text .. ' each'
		infoGui.Stackable.Text = 'Max stack: ' .. iRef.Stackable.Value
	else
		infoGui.Stackable.Text = 'Cannot stack'
	end
	infoGui.Type.Text = 'Type: ' .. item.Type.Value
	if iRef:FindFirstChild("Requirements") 
		and iRef.Requirements:FindFirstChild("Level") then 
		infoGui.Dye.Text = 'Requires Lv. '..iRef.Requirements.Level.Value
	else
		infoGui.Dye.Text = 'No Lv. requirement'
	end
	if item:FindFirstChild('StatMod') then
		infoGui.SFrame.Frame:ClearAllChildren()
		infoGui.SFrame.Visible = true
		local stats = item.StatMod:GetChildren()
		for _, stat in pairs(stats) do
			local newStat = infoGui.SFrame.Stat:Clone()
			if stat:FindFirstChild('Percent') then
				newStat.Text = stat.Value .. '% ' .. stat.Name
			else
				newStat.Text = stat.Value .. ' ' .. stat.Name
			end
			if stat.Value > 0 then
				newStat.Text = '+' .. newStat.Text
			end
			local numY = #infoGui.SFrame.Frame:GetChildren()*14
			newStat.Position = UDim2.new(0,0,0,numY)
			newStat.Visible = true
			newStat.Parent = infoGui.SFrame.Frame
		end
		infoGui.SFrame.Size = UDim2.new(0,-100,0,#infoGui.SFrame.Frame:GetChildren()*14+10)
		infoGui.SFrame.BorderColor3 = sDomain.Rarities[iRef.Rarity.Value].Value
	else
		infoGui.SFrame.Visible = false
	end
end

function drawListing(listing,key,cheapest,recent)
	local item = script.Item:Clone()
	pcall(function() item.Icon.Image = 'rbxassetid://' .. tex[listing.Item].Value end)
	item.Label.Text = listing.Item
	item.Cost.Text = cMethods.commafy(tonumber(listing.Per))
	item.Icon.BorderColor3 = sDomain.Rarities[ref[iMethods.getItemId(key)].Rarity.Value].Value
	if tonumber(listing.Amt) > 1 then
		item.Amt.Text = listing.Amt
		item.Cost.Text = item.Cost.Text .. ' each'
	else
		item.Amt.Text = ''
	end
	item.user.Text = game.Players:GetNameFromUserIdAsync(tonumber(listing.Seller))
	item.Position = UDim2.new(0,5,0,5+#listGui:GetChildren()*55)
	item.Parent = listGui
	listGui.CanvasSize = UDim2.new(0,0,0,5+#listGui:GetChildren()*55)
	if tonumber(listing.Seller) ~= player.UserId and -tonumber(listing.Seller) ~= player.UserId then
		item.Buy.MouseButton1Click:connect(function()
			if bin:FindFirstChild('BuyPrompt') then
				bin.BuyPrompt:Destroy()
			end
			local per = tonumber(listing.Per)
			local bPrompt = script.BuyPrompt:Clone()
			bPrompt.Label.Text = 'How many do you want to buy? (' .. listing.Amt .. ' max)'
			bPrompt.P.Text = cMethods.commafy(per)
			bPrompt.Amt.Text = '1'
			if per > save.Silver.Value then
				bPrompt.Buy.Hide.Visible = true
				bPrompt.P.TextColor3 = Color3.new(1,0,0)
				bPrompt.P.TextStrokeColor3 = Color3.new(1,0,0)
			else
				bPrompt.Buy.Hide.Visible = false
				bPrompt.P.TextColor3 = Color3.new(1,1,1)
				bPrompt.P.TextStrokeColor3 = Color3.new(1,1,1)
			end
			bPrompt.Amt.Focused:connect(function()
				bPrompt.Buy.Hide.Visible = true
			end)
			bPrompt.Amt.FocusLost:connect(function()
				local input = tonumber(bPrompt.Amt.Text)
				if input ~= nil and input > 0 then 
					if input > tonumber(listing.Amt) then
						input = tonumber(listing.Amt)
						bPrompt.Amt.Text = input
					end
					bPrompt.P.Text = cMethods.commafy(input*per)
					if input*listing.Per > save.Silver.Value then
						bPrompt.P.TextColor3 = Color3.new(1,0,0)
						bPrompt.P.TextStrokeColor3 = Color3.new(1,0,0)
					else
						bPrompt.Buy.Hide.Visible = false
						bPrompt.P.TextColor3 = Color3.new(1,1,1)
						bPrompt.P.TextStrokeColor3 = Color3.new(1,1,1)
					end
				end
			end)
			bPrompt.Cancel.MouseButton1Click:connect(function()
				bPrompt:Destroy()
			end)
			bPrompt.Buy.MouseButton1Click:connect(function()
				if bPrompt.Buy.Hide.Visible == true then return end
				local input = tonumber(bPrompt.Amt.Text)
				if input ~= nil and save.Silver.Value >= input*listing.Per then
					local post = rmd.RemoteHttp:InvokeServer('buy',input,listing.Index)
					if post == 'Successfully bought.' then
						iMethods.giveItem(player,iMethods.getItemId(listing.Item),input)
						rmd.RemoteValue:FireServer(save.Silver,save.Silver.Value - input*per)
					else
						rmd.RemoteWarning:FireServer('Failed to purchase.')
					end
				end
				getMarket()
				drawListings(key,cheapest,recent)
				bPrompt:Destroy()
			end)
			bPrompt.Parent = bin
		end)
		item.Buy.MouseEnter:connect(function()
			item.Buy.TextColor3 = Color3.new(0,1,1)
			item.Buy.TextStrokeColor3 = Color3.new(0,1,1)
		end)
		item.Buy.MouseLeave:connect(function()
			item.Buy.TextColor3 = Color3.new(1,1,1)
			item.Buy.TextStrokeColor3 = Color3.new(1,1,1)
		end)
	else
		item.Buy.Text = 'Your Item'
	end
	item.MouseEnter:connect(function()
		item.BackgroundColor3 = Color3.new(.17,.17,.17)
	end)
	item.MouseLeave:connect(function()
		item.BackgroundColor3 = Color3.new(0,0,0)
	end)
	item.Icon.MouseMoved:connect(function(dx,dy)
		drawInfo(dx,dy,ref[iMethods.getItemId(listing.Item)])
	end)
	item.Icon.MouseLeave:connect(function()
		infoGui.Visible = false
	end)
end

function drawListings(key)
	listGui.CanvasPosition = Vector2.new(0,0)
	getHistory()
	local recent = history[key]
	wipe()
	bin.List.Visible = true
	bin.Folders.Visible = false
	bin.Ribbon.Filters.Visible = false
	bin.Ribbon.Folder.Visible = true
	bin.Ribbon.Folder.Icon.BorderColor3 = sDomain.Rarities[ref[iMethods.getItemId(key)].Rarity.Value].Value
	bin.Ribbon.Back.Visible = true
	bin.Ribbon.Back.ImageTransparency = 0.5
	pcall(function() bin.Ribbon.Folder.Icon.Image = tex[folders[key].Item].Value end)
	if recent ~= nil and recent ~= 0 then
		bin.Ribbon.Folder.Cost2.Text = cMethods.commafy(recent)
	else
		bin.Ribbon.Folder.Cost2.Text = 'Never sold before'
	end
	bin.Ribbon.Folder.Label.Text = key
	local qualify = {}
	local numListings = #listings
	local max = numListings
	if numListings > 50 then
		max = 50
	end
	for i = 1, max do
		local listing = listings[i]
		if listing.Item == key then
			table.insert(qualify,listing)
		end
	end
	table.sort(qualify,valueSort)
	local cheapest = qualify[1].Per
	for _, qualified in ipairs(qualify) do
		drawListing(qualified,key,cheapest,recent)
	end
	if cheapest ~= nil then
		bin.Ribbon.Folder.Cost.Text = cMethods.commafy(cheapest)
	else
		bin.Ribbon.Folder.Cost.Text = 'No listings'
	end
	drawTrim()
	if #listGui:GetChildren() == 0 then
		back()
	end
	bin.Loading.Visible = false
end

function drawFolder(key,cheapest,recent)
	local folder = script.Folder:Clone()
	local refId = ref[iMethods.getItemId(key)]
	pcall(function() folder.Icon.Image = 'rbxassetid://' .. tex[key].Value end)
	folder.Label.Text = key
	folder.Icon.BorderColor3 = sDomain.Rarities[ref[iMethods.getItemId(key)].Rarity.Value].Value
	if cheapest ~= nil then
		folder.Cost.Text = cMethods.commafy(cheapest)
	else
		folder.Cost.Text = 'No listings'
	end
	if recent ~= nil and recent ~= 0 then
		folder.Cost2.Text = cMethods.commafy(recent)
	else
		folder.Cost2.Text = 'Never sold before'
	end
	folder.Position = UDim2.new(0,5,0,5+#folderGui:GetChildren()*55)
	folder.Parent = folderGui
	folderGui.CanvasSize = UDim2.new(0,0,0,5+#folderGui:GetChildren()*55)
	folder.MouseButton1Click:connect(function()
		selectedKey = key
		drawListings(key,cheapest,recent)
	end)
	folder.MouseEnter:connect(function()
		folder.BackgroundColor3 = Color3.new(.17,.17,.17)
	end)
	folder.MouseLeave:connect(function()
		folder.BackgroundColor3 = Color3.new(0,0,0)
	end)
	folder.Icon.MouseMoved:connect(function(dx,dy)
		drawInfo(dx,dy,ref[iMethods.getItemId(key)])
	end)
	folder.Icon.MouseLeave:connect(function()
		infoGui.Visible = false
	end)
end

function drawFolders()
	folderGui.CanvasPosition = Vector2.new(0,0)
	selectedKey = ''
	bin.List.Visible = false
	bin.Folders.Visible = true
	bin.Empty.Visible = false
	wipe()
	getHistory()
	for key, folder in pairsByKeys(folders) do
		if (filterString == '' or string.find(string.lower(key),filterString) ~= nil) and (filterType == 'All' or string.find(category(stuff[key].Type.Value),filterType) ~= nil) then
			local cheapest = nil
			for k, listing in ipairs(folder) do
				if listing.Per ~= nil and (cheapest == nil or tonumber(listing.Per) < cheapest) then
					cheapest = tonumber(listing.Per)
				end			
			end
			drawFolder(key,cheapest,history[key])
		end
	end
	if #folderGui:GetChildren() == 0 then
		bin.Empty.Visible = true
	end
	drawTrim()
	bin.Loading.Visible = false
end

function drawSale(sale)
	local item = script.Sale:Clone()
	local clickable = true
	pcall(function() item.Icon.Image = 'rbxassetid://' .. tex[sale.Item].Value end)
	if string.len(sale.Item) > 18 then
		item.Label.Text = string.sub(sale.Item,1,18) .. '...'
	else
		item.Label.Text = sale.Item
	end
	item.Icon.BorderColor3 = sDomain.Rarities[ref[iMethods.getItemId(sale.Item)].Rarity.Value].Value
	item.Cost.Text = cMethods.commafy(sale.Per)
	if tonumber(sale.Amt) > 1 then
		item.Amt.Text = cMethods.commafy(sale.Amt)
		item.Cost.Text = item.Cost.Text  .. ' each'
	else
		item.Amt.Text = ''
	end
	if tonumber(sale.Amt) ~= nil and tonumber(sale.Amt) > 0 then
		if tonumber(sale.Lifespan) <= 28800 then
			item.Sold.Text = 8-math.ceil(tonumber(sale.Lifespan)/3600) .. 'h'
		else
			item.Sold.Text = 'Expired'
			item.Cancel.Visible = false
		end
	else
		item.Sold.Text = 'Sold out!'
	end
	item.Earnings.Text = cMethods.commafy(math.ceil(tonumber(sale.Bought)*tonumber(sale.Per)*.8))
	
	item.Position = UDim2.new(0,5,0,5+#saleGui:GetChildren()*55)
	item.Parent = saleGui
	saleGui.CanvasSize = UDim2.new(0,0,0,5+#saleGui:GetChildren()*55)
	item.MouseEnter:connect(function()
		item.BackgroundColor3 = Color3.new(.17,.17,.17)
	end)
	item.MouseLeave:connect(function()
		item.BackgroundColor3 = Color3.new(0,0,0)
	end)
	item.Icon.MouseMoved:connect(function(dx,dy)
		drawInfo(dx,dy,ref[iMethods.getItemId(sale.Item)])
	end)
	item.Icon.MouseLeave:connect(function()
		infoGui.Visible = false
	end)
	item.Collect.MouseEnter:connect(function()
		item.Collect.TextColor3 = Color3.new(0,1,1)
		item.Collect.TextStrokeColor3 = Color3.new(0,1,1)
	end)
	item.Collect.MouseLeave:connect(function()
		item.Collect.TextColor3 = Color3.new(1,1,1)
		item.Collect.TextStrokeColor3 = Color3.new(1,1,1)
	end)
	item.Cancel.MouseEnter:connect(function()
		item.Cancel.TextColor3 = Color3.new(0,1,1)
		item.Cancel.TextStrokeColor3 = Color3.new(0,1,1)
	end)
	item.Cancel.MouseLeave:connect(function()
		item.Cancel.TextColor3 = Color3.new(1,1,1)
		item.Cancel.TextStrokeColor3 = Color3.new(1,1,1)
	end)
	item.Cancel.MouseButton1Click:connect(function()
		if clickable == true then
			clickable = false
			if iMethods.getNumSlots(player) > 0 then
				local writeTo = rmd.RemoteHttp:InvokeServer('cancel',sale.Index)
				if writeTo == 'Unlisted.' then
					iMethods.giveItem(player,iMethods.getItemId(sale.Item),tonumber(sale.Amt))
				else
					rmd.RemoteWarning:FireServer(writeTo)
				end
				refresh()
			else
				rmd.RemoteWarning:FireServer('No inventory space!')
			end
			clickable = true
		end
	end)
	item.Collect.MouseButton1Click:connect(function()
		if clickable == true then
			clickable = false
			if tonumber(sale.Lifespan) <= 28800 then
				rmd.RemoteValue:FireServer(save.Silver,save.Silver.Value + math.ceil(tonumber(sale.Bought)*tonumber(sale.Per)*.8))
				rmd.RemoteHttp:InvokeServer('collect',sale.Index)
				refresh()
			else
				local e,h = iMethods.getNumSlots(player)
				if e > 0 then
					rmd.RemoteValue:FireServer(save.Silver,save.Silver.Value + math.ceil(tonumber(sale.Bought)*tonumber(sale.Per)*.8))
					if tonumber(sale.Amt) ~= nil and tonumber(sale.Amt) > 0 then
						iMethods.giveItem(player,iMethods.getItemId(sale.Item),tonumber(sale.Amt))
					end
					rmd.RemoteHttp:InvokeServer('cancel',sale.Index)
					refresh()
				else
					rmd.RemoteWarning:FireServer('No inventory space!')
				end
			end
			clickable = true
		end
	end)
end

function drawSlots()
	slotEvents = {}
	for _, row in ipairs(bin.Bag.Slots:GetChildren()) do
		for _, col in ipairs(row:GetChildren()) do
			drawSlot(col)
		end
	end	
end

function drawSales()
	bin.Empty.Visible = false
	wipe()
	saleGui.CanvasPosition = Vector2.new(0,0)
	for _, sale in ipairs(sales) do
		drawSale(sale)
	end
	if #saleGui:GetChildren() == 0 then
		bin.Empty.Visible = true
	end
	for _, event in ipairs(slotEvents) do
		event:disconnect()
	end
	drawSlots()
	drawTrim()
end

function getSales()
	bin.Loading.Visible = true
	local saleStr = rmd.RemoteHttp:InvokeServer('listedBy')
	local index = 1	
	local propIndex = 1	
	sales = {}
	sales[1] = {}
	for w in string.gmatch(saleStr, "%w+%s*%w*%s*%w*%s*%w*%s*%w*") do 
		if w == 'zzz' then
			index = index + 1
			propIndex = 1
			sales[index] = {}
		else
			sales[index][sProperties[propIndex]] = w
			propIndex = propIndex + 1
		end
	end	
	for i, v in ipairs(sales) do
		if v.Index == nil then
			table.remove(sales,i)
		end
	end
	table.sort(sales,nameSort)
	bin.Loading.Visible = false
end

function getMarket()
	bin.Loading.Visible = true
	local marketString = rmd.RemoteHttp:InvokeServer('list')
	local index = 1	
	local propIndex = 1	
	listings = {}
	folders = {}
	listings[1] = {}
	for w in string.gmatch(marketString, "%w+%s*%w*%s*%w*%s*%w*%s*%w*") do 
		if w == 'zzz' then
			index = index + 1
			propIndex = 1
			listings[index] = {}
		else
			listings[index][properties[propIndex]] = w
			propIndex = propIndex + 1
		end
	end
	for i, listing in ipairs(listings) do
		if listing.Index ~= nil then
			if tonumber(listing.Amt) > 0 then
				if folders[listing.Item] == nil then
					folders[listing.Item] = {listing}
				else
					table.insert(folders[listing.Item],listing)
				end
			else
				table.remove(listings,i)
			end
		else
			table.remove(listing,i)
		end
	end
	bin.Loading.Visible = false
end 

function getHistory()
	bin.Loading.Visible = true
	local historyStr = rmd.RemoteHttp:InvokeServer('history')
	local index = 1
	local propIndex = 1
	local db = {}
	history = {}
	db[1] = {}
	for w in string.gmatch(historyStr, "%w+%s*%w*%s*%w*%s*%w*%s*%w*") do 
		if w == 'zzz' then
			index = index + 1
			propIndex = 1
			db[index] = {}
		else
			db[index][hProperties[propIndex]] = w
			propIndex = propIndex + 1
		end
	end
	for _, v in ipairs(db) do
		if v.Item ~= nil then
			history[v.Item] = v.Price
			--print(v.Item .. ' ' .. history[v.Item])
		end
	end
end

for _, button in ipairs(bin.Ribbon.Filters:GetChildren()) do
	if button.ClassName == 'ImageButton' then
		button.MouseEnter:connect(function()
			if bin.Loading.Visible == true or bin.Down.Visible == true then return end
			for _, b in ipairs(bin.Ribbon.Filters:GetChildren()) do
				if b.ClassName == 'ImageButton' and b.Name ~= filterType then
					b.ImageColor3  = Color3.new(172/255, 172/255, 172/255)
					b.ImageTransparency = 0.5
				end
			end
			button.ImageColor3 = button.C.Value
			button.ImageTransparency = 0
		end)
		button.MouseLeave:connect(function()
			if bin.Loading.Visible == true or bin.Down.Visible == true then return end
			if button.Name ~= filterType then
				button.ImageColor3 = Color3.new(172/255, 172/255, 172/255)
				button.ImageTransparency = 0.5
			end
		end)
		button.MouseButton1Click:connect(function()
			if bin.Loading.Visible == true or bin.Down.Visible == true then return end
			filterType = button.Name
			for _, b in ipairs(bin.Ribbon.Filters:GetChildren()) do
				if b.ClassName == 'ImageButton' and b.Name ~= filterType then
					b.ImageColor3  = Color3.new(172/255, 172/255, 172/255)
					b.ImageTransparency = 0.5
				end
			end
			drawFolders()
		end)
	elseif button.Name == 'Search' then
		button.MouseButton1Click:connect(function()
			if bin.Loading.Visible == true or bin.Down.Visible == true then return end
			filterString = string.lower(bin.Ribbon.Filters.StringFilter.Text)
			drawFolders()
		end)	
		button.MouseEnter:connect(function()
			button.TextColor3 = Color3.new(0,1,1)
			button.TextStrokeColor3 = Color3.new(0,1,1)
		end)	
		button.MouseLeave:connect(function()
			button.TextColor3 = Color3.new(1,1,1)
			button.TextStrokeColor3 = Color3.new(1,1,1)
		end)
	end
end

function back()
	selectedKey = ''
	bin.Ribbon.Folder.Visible = false
	bin.Ribbon.Back.Visible = false
	bin.Ribbon.Filters.Visible = true
	drawFolders()
end

function m.openMarket()
	m.open = true
	checking = true
	local thread = coroutine.wrap(function()
		while checking == true do
			wait(10)
			checkSiteStatus()
		end
	end)
	thread()
	drawTrim()
	filterString = ''
	filterType = 'All'
	bin.Parent.Inventory.Mode.Value = 1
	cMethods.playSound('Click')
	bin.Visible = true
	tab = 0
	bin.Buy.BackgroundTransparency = 0
	bin.Sell.BackgroundTransparency = 0.5
	bin.Ribbon.Filters.Visible = true
	bin.Ribbon.Back.Visible = false
	bin.Ribbon.Folder.Visible = false
	bin.Ribbon.Selling.Visible = false
	bin.Bag.Visible = false
	saleGui.Visible = false
	listGui.Visible = false
	folderGui.Visible = true
	bin.Ribbon.Filters.All.ImageColor3 = bin.Ribbon.Filters.All.C.Value
	selectedKey = ''
	wait(getMarket())
	drawFolders()
end

function m.closeMarket()
	m.open = false
	checking = false
	bin.Parent.Inventory.Mode.Value = -1
	selectedKey = ''
	bin.Ribbon.Folder.Visible = false
	bin.Ribbon.Back.Visible = false
	bin.Ribbon.Filters.Visible = true
	cMethods.playSound('Click')
	wipe()
	bin.Visible = false
end

bin.Ribbon.Back.MouseButton1Click:connect(function()
	if bin.Loading.Visible == true or bin.Down.Visible == true then return end
	back()
end)

bin.Ribbon.Back.MouseButton1Down:connect(function()
	if bin.Loading.Visible == true or bin.Down.Visible == true then return end
	bin.Ribbon.Back.ImageTransparency = 0.5
end)

bin.Ribbon.Back.MouseEnter:connect(function()
	bin.Ribbon.Back.ImageTransparency = 0
end)

bin.Ribbon.Back.MouseLeave:connect(function()
	bin.Ribbon.Back.ImageTransparency = 0.5
end)

bin.Sell.MouseButton1Click:connect(function()
	if bin.Loading.Visible == true or bin.Down.Visible == true then return end
	pcall(function() bin.BuyPrompt:Destroy() end)
	pcall(function() bin.SellPrompt:Destroy() end)
	if tab == 0 then
		tab = 1
		bin.Sell.BackgroundTransparency = 0
		bin.Buy.BackgroundTransparency = 0.5
		bin.Ribbon.Filters.Visible = false
		bin.Ribbon.Back.Visible = false
		bin.Ribbon.Folder.Visible = false
		bin.Ribbon.Selling.Visible = true
		bin.Bag.Visible = true
		saleGui.Visible = true
		listGui.Visible = false
		folderGui.Visible = false
		wait(getSales())
		drawSales()
	end
end)

bin.Buy.MouseButton1Click:connect(function()
	if bin.Loading.Visible == true or bin.Down.Visible == true then return end
	pcall(function() bin.BuyPrompt:Destroy() end)
	pcall(function() bin.SellPrompt:Destroy() end)
	if tab == 1 then
		tab = 0
		bin.Buy.BackgroundTransparency = 0
		bin.Sell.BackgroundTransparency = 0.5
		bin.Ribbon.Filters.Visible = true
		bin.Ribbon.Back.Visible = false
		bin.Ribbon.Folder.Visible = false
		bin.Ribbon.Selling.Visible = false
		bin.Bag.Visible = false
		saleGui.Visible = false
		listGui.Visible = false
		folderGui.Visible = true
		selectedKey = ''
		wait(getMarket())
		drawFolders()
	end
end)

lTrim.Refresh.MouseEnter:connect(function()
	lTrim.Refresh.TextColor3 = Color3.new(0,1,1)
	lTrim.Refresh.TextStrokeColor3 = Color3.new(0,1,1)
end)
lTrim.Refresh.MouseLeave:connect(function()
	lTrim.Refresh.TextColor3 = Color3.new(1,1,1)
	lTrim.Refresh.TextStrokeColor3 = Color3.new(1,1,1)
end)
lTrim.Refresh.MouseButton1Click:connect(function()
	if bin.Loading.Visible == true then return end
	refresh()
end)

trim.Close.MouseButton1Click:connect(m.closeMarket)

return m