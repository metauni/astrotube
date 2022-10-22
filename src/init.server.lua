local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

script.AstroTubePlayer.Parent = StarterPlayer.StarterPlayerScripts
local AstroTubeCommon = script.AstroTubeCommon
AstroTubeCommon.Parent = ReplicatedStorage
local AstroTube = require(AstroTubeCommon.AstroTube)
local Config = require(AstroTubeCommon.Config)

local AstroTubeContainer = Instance.new("Model", workspace)
AstroTubeContainer.Name = "AstroTubeContainer"
CollectionService:AddTag(AstroTubeContainer, Config.TubeContainerTag)

local function hidePart(part)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
end

-- Walks a chain of WeldConstraints and adds the part positions to a table
local function getPoints(parent, points)
	local gotNext = false
	for _, joint in parent:GetJoints() do
		if joint.ClassName == "WeldConstraint" and joint.Part0 == parent and joint.Part1 then
			if gotNext then
				error("Node has multiple children")
			else
				gotNext = true
				table.insert(points, joint.Part1.Position)
				hidePart(joint.Part1)
				getPoints(joint.Part1, points)
			end
		end
	end
end

local function tubeTagged(tube)
	local entrance = tube:WaitForChild("Entrance")
	assert(entrance)
	hidePart(entrance)
	
	-- Collect points
	local points = {}
	table.insert(points, entrance.CFrame*Vector3.new(0, Config.EntranceHeight, 0))
	getPoints(entrance, points)
	
	-- Create tube
	local container = Instance.new("Folder", AstroTubeContainer)
	container.Name = "Tube"
	local touchPart = AstroTube.CreateTube(points, entrance.CFrame, tube:GetAttributes(), container)
	
	-- Serialize points to an attribute of touchPart; tag touchPart
	local pointsString = AstroTube.SerializePoints(points)
	touchPart:SetAttribute(Config.TouchPartPointsAttribute, pointsString)
	touchPart:SetAttribute("EjectSpeed", tube:GetAttribute("EjectSpeed"))
	touchPart:SetAttribute("SlideSpeed", tube:GetAttribute("SlideSpeed"))
	CollectionService:AddTag(touchPart, Config.TouchPartTag)
end

for _, tube in CollectionService:GetTagged(Config.TubeTag) do
	task.spawn(tubeTagged, tube)
end
CollectionService:GetInstanceAddedSignal(Config.TubeTag):Connect(tubeTagged)