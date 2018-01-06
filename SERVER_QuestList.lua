function newStage(journal, objs)
	return {journal, objs};
end

function newQuest(name, endStage, rewards, description, stages)
	return {name, endStage, rewards, description, stages};
end

function copyQuests(quests)
	for i, quest in pairs(quests) do
		local int = Instance.new("IntValue");
		local str = Instance.new("StringValue");
		local rFolder = Instance.new("Folder");

		local qHolder = int:Clone();
		qHolder.Name = quest[1];
		qHolder.Value = i;
		
		local eStage = int:Clone();
		eStage.Name = "EndStage";
		eStage.Value = quest[2];		
		eStage.Parent = qHolder;		
		
		local desc = str:Clone();
		desc.Name = "Description";
		desc.Value = quest[4];
		desc.Parent = qHolder;		
		
		rFolder.Name = "Rewards";
		for thing, reward in pairs(quest[3]) do
			if (type(reward) == "number") then
				local r = int:Clone();
				r.Name = thing;
				r.Value = reward;
				r.Parent = rFolder;
			elseif (type(reward) == "table") then
				for k, j in pairs(reward) do
					local r = int:Clone();
					r.Name = k;
					r.Value = j;
					r.Parent = rFolder;
				end				
			end
		end
		
		rFolder.Parent = qHolder;
		
		for i, stageData in pairs(quest[5]) do
			local sVal = str:Clone();
			sVal.Name = "Stage"..i - 1;
			sVal.Value = stageData[1];
			if (#stageData > 1) then
				for obj, objData in pairs(stageData[2]) do
					local oVal = str:Clone();
					oVal.Name = obj;
					oVal.Value = objData[1];
					if (#objData > 1) then
						local iVal = int:Clone();
						iVal.Name = "Amount";
						iVal.Value = objData[2];
						iVal.Parent = oVal;
					end
					oVal.Parent = sVal;
				end
			end
			sVal.Parent = qHolder;
		end
		
		qHolder.Parent = workspace.ServerDomain.Quests;
	end
end

_G["Quests"] = {}
MorningRoutine = newQuest(
	"Morning Routine", 14, 
	{
		Coines = 0,
		Experience = 50,
		Items = {}
	},
		"I've made it to Aeon to begin my adventure! "
			.. "There are so many things to do! Where do I start?!", 
	{
		newStage("I've just woken up and I'm starving, let's go talk to the Innkeeper for some food.", -- 0
			{GoTo = {"Innkeeper"}}),
		newStage("I don't have enough money for breakfast, but I was referred to a certain Cole Myner for work. "
			.. "Guess I'll go find this Cole; I was told he should be near the mines to the north.",
			{GoTo = {"Cole Myner"}}),
		newStage("Cole ordered me to mine 6 copper ores. There should be some rocks nearby, let's get to it! If I need help with something I can ask Cole.",
			{Gather = {"Copper Ore", 6}, 
				GoTo = {"CaveWaypoint"}}),
		newStage("Alright I have the rocks, let's bring these back to Cole for my pay!",
			{GoTo = {"Cole Myner"}}),
		newStage("I was played like a dang fiddle! My stomach is still empty though, "
			.. "so I'll just have to go smelt these 6 rocks... I think the forge was behind Cole.",
			{Craft = {"Copper Ingot", 2}, 
				GoTo = {"Forge"}}),
		newStage("Okay, copper ingots acquired. I hope Cole will pay me now.", -- 5
			{GoTo = {"Cole Myner"}}),	
		newStage("Dangit! Well at least Cole said this is the FINAL job. " 
			.. "Let's just get it over with and make these two shivs.",
			{Craft = {"Copper Shiv", 2}, 
				GoTo = {"Anvil"}}),
		newStage("Time to turn in these shivs. Boy oh boy " 
			.. "I can taste the soup already!",
			{GoTo = {"Cole Myner"}}),
		newStage("Finally! Now let's buy some of the Innkeeper's delicious soup~",
			{Gather = {"Delicious Soup", 1}, 
				GoTo = {"Innkeeper"}}),
		newStage("Well, I'm one coine short; let's ask around for a small job and ask the Innkeeper again when I have 20 coines.",
			{GoTo = {"TavernWaypoint"}}),
		newStage("Great, got the soup. Now I feel like swinging something, let's meet the combat trainer.", -- 10
			{GoTo = {"Kahm Baght"}}),
		newStage("The trainer told me to give this sword a few swings at the chickens in the pen. " 
			.. "I think hunting one will do and I might as well pick up its drops.",
			{Loot = {"Raw Poultry", 1}, 
				GoTo = {"ChickensWaypoint"}}),
		newStage("That was a nice morning workout! " 
			.. "Let's see if Kahm has anything bigger for me to fight! ", 
			{GoTo = {"Kahm Baght"}}),
		newStage("Kahm said if I want to fight bigger stuff I'll have to venture off to Aeon so " 
			.. "here I go! Let's see if anyone by the dock has a ship to take me there.",
			{GoTo = {"Khap Tinh"}}),		
	})
OnTheHook = newQuest(
	"On The Hook", 2, 
	{
		Coines = 1,
		Experience = 10,
		Items = {}
	},
		"I caught a fish to earn the 1 coine I owed the innkeeper for lying. ",
	{
		newStage("Cod Father wanted me to fish him up a sardine and he'll compensate me for it. " ,
			{Gather = {"Sardine", 1}, 
				GoTo = {"FishingWaypoint"}}),		
		newStage("Okay, got the fish. Wait why don't I just make my own food?? Whatever, I'm this far in.", 
			{GoTo = {"Cod Father"}}),		
	})

table.insert(_G.Quests, MorningRoutine)
table.insert(_G.Quests, OnTheHook)

-- Stage numbers start at 0

--[[
	newQuest(
		"QuestName", numstages, 
		{
			Coines = 0,
			Experience = 0,
			Items = {}
		},
			"Finished quest journal entry "
				.. "Line2", 
		{
			newStage("Journal entry " 
				.. "Line2 " 
				.. "Line3",
				{GoTo = {"Waypoint name"}}),		
		}),
--]]

copyQuests(_G.Quests);