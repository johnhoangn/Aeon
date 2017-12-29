

local gContainer, gBackground, gOptionsBackground, gModType; 
local gTreeList, gChildList, gTriggerList, gReqList;
local gNodeRoot, gCurNodeDialogue, gDialogueField, gDialogueName;
local gTextButton, gTextLabel, gTextBox;
local gNewTree, gExitTree, gDeleteTree, gAddMod;
local gTriggersButton, gReqsButton;
local gMakePChat, gMakeNChat, gEditNode, gUpNode, gDeleteNode, gEndBranch;
local wkspc, trash, curNode;

local triggers = {};
local reqs = {};
local events = {};

function setUp()
	local existing = workspace:FindFirstChild("DialogueWkspc");
	if (existing ~= nil) then
		wkspc = existing;
		trash = workspace.DialogueTrash;
	else
		wkspc = Instance.new("Folder");
		wkspc.Name = "DialogueWkspc";
		wkspc.Parent = workspace;
		
		trash = Instance.new("Folder");
		trash.Name = "DialogueTrash";
		trash.Parent = workspace;
	end
	
	for _, trigger in ipairs(game.ServerStorage.DialogueTreeKit.chatTriggers:GetChildren()) do
		triggers[trigger.Name] = trigger;
	end
	for _, requirement in ipairs(game.ServerStorage.DialogueTreeKit.required:GetChildren()) do
		reqs[requirement.Name] = requirement;
	end
	
	local white = Color3.new(1,1,1);	
	local grey = Color3.new(112/255, 112/255, 112/255, 1);
	local black = Color3.new(0,0,0);
	
	--CONTAINER AND BACKGROUNDS	
	gContainer = Instance.new("ScreenGui");
	gContainer.Name = "DialogueKit";
	
	gBackground = Instance.new("Frame");
	drawGui(gBackground, {0,0,0}, {0,0,0,1}, 0.5, {0, 600, 0, 115}, gContainer);
	gBackground.AnchorPoint = Vector2.new(0.5,0.5);
	gBackground.Position = UDim2.new(0.5, 0, 0.5, 0);
	
	gOptionsBackground = Instance.new("Frame");
	drawGui(gOptionsBackground, {0,0,0}, {0,0,0,1}, 0.5, {0, 80, 1, -10}, gBackground);
	gOptionsBackground.Position = UDim2.new(0, 5, 0, 5);
	
	gModType = Instance.new("Frame");
	drawGui(gModType, {0,0,0}, {0,0,0,1}, 0.5, {0, 80, 0, 55}, gBackground);
	gModType.Visible = false;
	gModType.Position = UDim2.new(0, 5, 1, 5);
	
	--TEMPLATE TEXT OBJECTS
	gTextButton = Instance.new("TextButton");
	drawGui(gTextButton, grey, grey, 0.5);	
	gTextButton.TextColor3 = white;
	gTextButton.Font = "SourceSans";
	gTextButton.TextSize = 14;
	gTextButton.TextTransparency = 0;
	
	gTextLabel = Instance.new("TextLabel");
	drawGui(gTextLabel, {0,0,0}, {0,0,0,1}, 0.5);
	gTextLabel.TextColor3 = white;
	gTextLabel.Font = "SourceSans";
	gTextLabel.TextSize = 14;
	gTextLabel.TextTransparency = 0;
	
	gTextBox = Instance.new("TextBox");
	drawGui(gTextBox, {0,0,0}, {0,0,0,1}, 0.5);
	gTextBox.TextColor3 = white;
	gTextBox.Font = "SourceSans";
	gTextBox.TextSize = 14;
	gTextBox.TextTransparency = 0;

	--ROOT LABEL
	gNodeRoot = gTextLabel:Clone();
	gNodeRoot.Name = "Root";
	gNodeRoot.Parent = gBackground;
	gNodeRoot.TextXAlignment = "Left";
	gNodeRoot.TextYAlignment = "Bottom";
	gNodeRoot.TextColor3 = white;
	gNodeRoot.TextStrokeColor3 = black;
	gNodeRoot.TextStrokeTransparency = 0.6	
	gNodeRoot.TextSize = 20;
	gNodeRoot.Size = UDim2.new(0, 0, 0, 0);
	
	--OPTIONS BUTTONS
	gNewTree = gTextButton:Clone();
	gNewTree.Name = "NewTree";
	gNewTree.Text = "New Tree";
	gNewTree.Parent = gOptionsBackground;
	gNewTree.Size = UDim2.new(0, 70, 0, 20);
	gNewTree.Position = UDim2.new(0, 5, 0, 5);
	
	gExitTree = gNewTree:Clone();
	gExitTree.Name = "ExitTree";
	gExitTree.Text = "Exit Tree";
	gExitTree.Parent = gOptionsBackground;
	gExitTree.Position = UDim2.new(0, 5, 0, 30);
	
	gDeleteTree = gNewTree:Clone();
	gDeleteTree.Name = "DeleteTree";
	gDeleteTree.Text = "Del Tree";
	gDeleteTree.Parent = gOptionsBackground;
	gDeleteTree.Position = UDim2.new(0, 5, 0, 55);
	
	gAddMod = gNewTree:Clone();
	gAddMod.Name = "AddMod";
	gAddMod.Text = "Add Mod";
	gAddMod.Parent = gOptionsBackground;
	gAddMod.Position = UDim2.new(0, 5, 0, 80);
	
	gTriggersButton = gTextButton:Clone();
	gTriggersButton.Name = "Triggers";
	gTriggersButton.Text = "Trigger";
	gTriggersButton.Parent = gModType;
	gTriggersButton.Size = UDim2.new(0, 70, 0, 20);
	gTriggersButton.Position = UDim2.new(0, 5, 0, 5);
	
	gReqsButton = gTextButton:Clone();
	gReqsButton.Name = "Requirements";
	gReqsButton.Text = "Require";
	gReqsButton.Parent = gModType;
	gReqsButton.Size = UDim2.new(0, 70, 0, 20);
	gReqsButton.Position = UDim2.new(0, 5, 0, 30);
	
	--LISTS
	gTreeList = Instance.new("ScrollingFrame");
	gTreeList.Name = "TreeList";
	drawGui(gTreeList, {0,0,0}, {0,0,0,1}, 0.5, {0, 110, 1, -10}, gBackground);
	gTreeList.ScrollBarThickness = 5;
	gTreeList.TopImage = gTreeList.MidImage;
	gTreeList.BottomImage = gTreeList.MidImage;
	gTreeList.Position = UDim2.new(0, 90, 0, 5);

	gChildList = gTreeList:Clone();
	gChildList.Name = "ChildList";
	gChildList.Parent = gBackground;	
	gChildList.AnchorPoint = Vector2.new(1,0);
	gChildList.Position = UDim2.new(1, -5, 0 ,5);
	
	gTriggerList = gTreeList:Clone();
	gTriggerList.Name = "TriggerList";
	gTriggerList.Parent = gBackground;	
	gTriggerList.AnchorPoint = Vector2.new(1,0);
	gTriggerList.Position = UDim2.new(0, -5, 0 ,5);
	gTriggerList.Visible = false;
	
	gReqList = gTreeList:Clone();
	gReqList.Name = "ReqList";
	gReqList.Parent = gBackground;	
	gReqList.AnchorPoint = Vector2.new(1,0);
	gReqList.Position = UDim2.new(0, -5, 0 ,5);
	gReqList.Visible = false;
	
	--MIDDLE FIELDS
	gCurNodeDialogue = gTextLabel:Clone();
	gCurNodeDialogue.Name = "CurNode";
	gCurNodeDialogue.Parent = gBackground;
	gCurNodeDialogue.TextXAlignment = "Left";
	gCurNodeDialogue.BorderSizePixel = 6;
	gCurNodeDialogue.Size = UDim2.new(1, -335, 0 ,14);
	gCurNodeDialogue.Position = UDim2.new(0, 210, 0, 10);
	
	gDialogueField = gTextBox:Clone();
	gDialogueField.Name = "TextField";
	gDialogueField.Parent = gBackground;
	gDialogueField.TextXAlignment = "Left";
	gDialogueField.BorderSizePixel = 6;
	gDialogueField.Size = UDim2.new(1, -335, 0 ,14);
	gDialogueField.Position = UDim2.new(0, 210, 0, 40);
	
	gDialogueName = gTextBox:Clone();
	gDialogueName.Name = "NameField";
	gDialogueName.Parent = gBackground;
	gDialogueName.TextXAlignment = "Left";
	gDialogueName.BorderSizePixel = 6;
	gDialogueName.Size = UDim2.new(1, -335, 0 ,14);
	gDialogueName.Position = UDim2.new(0, 210, 0, 70);
	
	gUpNode = gTextButton:Clone();
	gUpNode.Name = "MakePChat";
	gUpNode.Parent = gBackground;
	gUpNode.Text = "Up";
	gUpNode.Size = UDim2.new(0, 30, 0, 14);
	gUpNode.Position = UDim2.new(0, 205, 0, 95);
	
	gMakePChat = gTextButton:Clone();
	gMakePChat.Name = "MakePChat";
	gMakePChat.Parent = gBackground;
	gMakePChat.Text = "pChat";
	gMakePChat.Size = UDim2.new(0, 40, 0, 14);
	gMakePChat.Position = UDim2.new(0, 240, 0, 95);
	
	gMakeNChat = gMakePChat:Clone();
	gMakeNChat.Name = "MakeNChat";
	gMakeNChat.Parent = gBackground;
	gMakeNChat.Text = "nChat";
	gMakeNChat.Position = UDim2.new(0, 285, 0, 95);
	
	gEditNode = gTextButton:Clone();
	gEditNode.Name = "EditNode";
	gEditNode.Parent = gBackground;
	gEditNode.Text = "Edit";
	gEditNode.Size = UDim2.new(0, 40, 0, 14);
	gEditNode.Position = UDim2.new(0, 330, 0, 95);	
	
	gDeleteNode = gTextButton:Clone();
	gDeleteNode.Name = "DeleteNode";
	gDeleteNode.Parent = gBackground;
	gDeleteNode.Text = "Delete";
	gDeleteNode.Size = UDim2.new(0, 40, 0, 14);
	gDeleteNode.Position = UDim2.new(0, 375, 0, 95);	
	
	gEndBranch = gTextButton:Clone();
	gEndBranch.Name = "End Branch";
	gEndBranch.Text = "End";
	gEndBranch.Parent = gBackground;
	gEndBranch.Size = UDim2.new(0, 40, 0, 14);
	gEndBranch.Position = UDim2.new(0, 430, 0, 95);	
	
	--BUTTON EVENTS
	gNewTree.MouseButton1Click:connect(function()
		local name = gDialogueName.Text;
			local value = gDialogueField.Text;
			if (name ~= "Enter new name/value" and value ~= "Enter new dialogue/value") then
				curNode = makeNode(name, wkspc, value);
			elseif (name == "Enter new name/value") then
				curNode = makeNode("pChat", wkspc, value);
			elseif (value == "Enter new dialogue/value") then
				curNode = makeNode(name, wkspc, "");
			else
				curNode = makeNode("pChat", wkspc, "");
			end
		updateGUI();
	end)
		
	gDeleteTree.MouseButton1Click:connect(function()
		if (curNode ~= nil) then
			curNode.Parent = trash;
			curNode = nil;
			updateGUI();
		end
	end)
		
	gExitTree.MouseButton1Click:connect(function()
		curNode = nil;
		updateGUI();
	end)
	
	gMakeNChat.MouseButton1Click:connect(function()
		if (curNode ~= nil) then
			if (gDialogueField.Text ~= "No current node") then
				curNode = makeNode("nChat", curNode, gDialogueField.Text, 12);
			else
				curNode = makeNode("nChat", curNode, "");
			end
			updateGUI();
		end
	end)	
	
	gMakePChat.MouseButton1Click:connect(function()
		if (curNode ~= nil and curNode.Name == "nChat") then
			local name = gDialogueName.Text;
			local value = gDialogueField.Text;
			if (name ~= "Enter new name/value" and value ~= "Enter new dialogue/value") then
				curNode = makeNode(name, curNode, value);
			elseif (name == "Enter new name/value") then
				curNode = makeNode("pChat", curNode, value);
			elseif (value == "Enter new dialogue/value") then
				curNode = makeNode(name, curNode, "");
			else
				curNode = makeNode("pChat", curNode, "");
			end
			updateGUI();
		end
	end)	
	
	gEditNode.MouseButton1Click:connect(function()
		if (curNode ~= nil) then
			if (curNode.Parent == wkspc) then
				curNode.Name = gDialogueName.Text;
			else
				curNode.Name = curNode.Name ~= "nChat" and gDialogueName.Text or "nChat";
			end
			curNode.Value = gDialogueField.Text;
			updateGUI();
		end
	end)	
	
	gDeleteNode.MouseButton1Click:connect(function()
		if (curNode ~= nil) then
			local temp = curNode.Parent;
			curNode:Destroy();
			curNode = temp ~= wkspc and temp or nil;
			updateGUI();
		end
	end)	
	
	gUpNode.MouseButton1Click:connect(function()
		if (curNode ~= nil) then
			if (curNode.Parent ~= wkspc) then
				curNode = curNode.Parent;
			else
				curNode = nil;
			end
			updateGUI();
		end
	end)
	
	gEndBranch.MouseButton1Click:connect(function()
		if (curNode ~= nil and curNode:FindFirstChild("endChat") == nil) then
			local ender = triggers.endChat:Clone();
			ender.Parent = curNode;
			updateGUI();
		end
	end)
	
	gAddMod.MouseButton1Click:connect(function()
		if (curNode ~= nil) then
			gModType.Visible = not gModType.Visible;
		end
	end)
	
	gTriggersButton.MouseButton1Click:connect(function()
		gTriggerList.Visible = true;
		gModType.Visible = false;
	end)	
	
	gReqsButton.MouseButton1Click:connect(function()
		gReqList.Visible = true;
		gModType.Visible = false;
	end)
	
	for key, trigger in pairs(triggers) do
		local addButton = gTextButton:Clone();
		addButton.Name = key;
		addButton.Text = key;
		addButton.Size = UDim2.new(0, 95, 0, 20);
		addButton.Position = UDim2.new(0, 5, 0, 5 + 25*#gTriggerList:GetChildren());
		addButton.Parent = gTriggerList;

		addButton.MouseButton1Click:connect(function()
			makeModifier(trigger, curNode);
			gTriggerList.Visible = false;
			updateGUI();
		end)
	end	
	
	for key, req in pairs(reqs) do
		local addButton = gTextButton:Clone();
		addButton.Name = key;
		addButton.Text = stringClamp(key, 12);
		addButton.Size = UDim2.new(0, 95, 0, 20);
		addButton.Position = UDim2.new(0, 5, 0, 5 + 25*#gReqList:GetChildren());
		addButton.Parent = gReqList;

		addButton.MouseButton1Click:connect(function()
			makeModifier(req, curNode);
			gReqList.Visible = false;
			updateGUI();
		end)
	end	
	
	gContainer.Parent = game.Players.LocalPlayer.PlayerGui;		
	
	--INITIAL UPDATE
	updateGUI();
end

function drawGui(gui, a, b, t, s, p)
	--background, border, transparency, size, parent
	pcall(function() 
		gui.BackgroundColor3 = Color3.new(a[1]/255,a[2]/255,a[3]/255);
	end);
	pcall(function() 
		gui.BorderColor3 = Color3.new(b[1]/255,b[2]/255,b[3]/255);
		gui.BorderSizePixel = b[4];
	end);
	pcall(function() gui.Transparency = t; end);
	pcall(function() gui.Size = UDim2.new(s[1],s[2],s[3],s[4]) end);
	pcall(function() gui.Parent = p; end);
end

function isMod(c)
	for name, _ in pairs(triggers) do
		if (c.Name == name) then
			return true;
		end
	end
	for name, _ in pairs(reqs) do
		if (c.Name == name) then
			return true;
		end
	end
	return false;
end

function drawRoot(src, list)
	local buttonEvent = nil;
	local rootButton = gTextButton:Clone();
	rootButton.Name = src.Name;
	rootButton.Text = stringClamp(src.Name, 12);
	rootButton.Size = UDim2.new(0, 95, 0, 20);
	rootButton.Position = UDim2.new(0, 5, 0, 5 + 25*#list:GetChildren());
	rootButton.Parent = list;

	buttonEvent = rootButton.MouseButton1Click:connect(function()
		curNode = src;
		updateGUI();
	end)	

	table.insert(events,buttonEvent);	
	
	list.CanvasSize = UDim2.new(0, 0, 0, 10 + 25*#list:GetChildren());
end

function drawChild(src)
	drawRoot(src, gChildList);
end

function drawModifier(src)
	local buttonEvent1 = nil;
	local buttonEvent2 = nil;
	local rootButton = gTextButton:Clone();
	rootButton.Name = src.Name;
	rootButton.Text = "<" .. stringClamp(src.Name, 12) .. ">";
	rootButton.Size = UDim2.new(0, 95, 0, 20);
	rootButton.Position = UDim2.new(0, 5, 0, 5 + 25*#gChildList:GetChildren());
	rootButton.Parent = gChildList;

	buttonEvent1 = rootButton.MouseButton1Click:connect(function()
		if (src.ClassName == "BoolValue") then
			src.Value = gDialogueField.Text == "1" and true or false;
		elseif (src.ClassName == "IntValue") then
			src.Value = tonumber(gDialogueField.Text);
		elseif (src.ClassName == "StringValue") then
			src.Value = gDialogueField.Text;
		else
			print("UNHANDLED TRIGGER/REQUIREMENT");
		end
		
		local kids = src:GetChildren();
		if (#kids == 1) then
			if (kids[1].ClassName == "BoolValue") then
				kids[1].Value = gDialogueName.Text == "1" and true or false;
			elseif (kids[1].ClassName == "IntValue") then
				kids[1].Value = tonumber(gDialogueName.Text);
			elseif (kids[1].ClassName == "StringValue") then
				kids[1].Value = gDialogueName.Text;
			else
				print("UNHANDLED TRIGGER/REQUIREMENT FOR SUB PROPERTY");
			end
		end
	end)	

	buttonEvent2 = rootButton.MouseButton2Click:connect(function()
		src:Destroy();
		updateGUI();
	end)	

	table.insert(events,buttonEvent1);	
	table.insert(events,buttonEvent2);	
	
	gChildList.CanvasSize = UDim2.new(0, 0, 0, 10 + 25*#gChildList:GetChildren());
end

function drawTreeList()
	for _, tree in ipairs(wkspc:GetChildren()) do
		drawRoot(tree, gTreeList);
	end
end

function drawNodeChildren(node)
	for _, child in ipairs(node:GetChildren()) do
		if (isMod(child)) then
			drawModifier(child);
		else
			drawChild(child);
		end
	end
end

function makeModifier(mod, node)
	local newMod = mod:Clone();
	newMod.Parent = node;
end

function makeNode(name, root, value)
	local node = Instance.new("StringValue");
	node.Name = name;
	node.Value = value;
	node.Parent = root;
	return node;
end

function disconnectEvents()
	for _, event in ipairs(events) do
		event:Disconnect();
	end
end

function stringClamp(txt, len)
	if (string.len(txt) > len) then
		return string.sub(txt,1,len) .. "...";
	else
		return txt;
	end
end

function clearLists()
	for _, existingTree in ipairs(gTreeList:GetChildren()) do
		existingTree:Destroy();
	end
	for _, existingTree in ipairs(gChildList:GetChildren()) do
		existingTree:Destroy();
	end
end

function getDepth(node)
	local depth = 0;
	local temp = node;
	while (temp.Parent ~= wkspc) do
		temp = temp.Parent;
		depth = depth + 1
	end
	return depth;
end

function updateGUI()
	disconnectEvents();
	clearLists();
	drawTreeList();
	
	gDialogueField.Text = "Enter new dialogue/value";
	gDialogueName.Text = "Enter new name/value";
	
	if (curNode ~= nil) then
		gCurNodeDialogue.Text = ">> " .. stringClamp(curNode.Value, 30);
		gNodeRoot.Text = "Current Node: " .. stringClamp(curNode.Name, 20) .. " | Parent node: " 
			.. (curNode.Parent ~= wkspc and stringClamp(curNode.Parent.Name, 20) or "No parent") 
			.. " | Depth: " .. getDepth(curNode);
		drawNodeChildren(curNode);
	else
		gCurNodeDialogue.Text = "No current node";
		gNodeRoot.Text = "Current Node: None";
	end
end

setUp();