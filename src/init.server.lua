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
local function getPoints(parent, from, to, points)
	points = points or {}
	table.insert(points, parent.CFrame)
	hidePart(parent)

	local gotNext = false
	for _, joint in parent:GetJoints() do
		if joint.ClassName == "WeldConstraint" and joint[from] == parent and joint[to] then
			if gotNext then
				error("Node has multiple children")
			else
				gotNext = true
				getPoints(joint[to], from, to, points)
			end
		end
	end

	return points
end

local function tubeTagged(tube)
	local child = tube:FindFirstChildWhichIsA("BasePart")
	assert(child, "astrotube " .. tube:GetFullName() .. " has no children")
	
	-- Collect points
	local backwardPoints = getPoints(child, "Part1", "Part0") -- {d, d-1, ..., 1}
	local forwardPoints = getPoints(child, "Part0", "Part1") -- {d, d+1, ..., n}
	local points = table.create(#backwardPoints + #forwardPoints - 1)
	for i = #backwardPoints, 1, -1 do
		table.insert(points, backwardPoints[i])
	end
	table.move(forwardPoints, 2, #forwardPoints, #points + 1, points)
	points[1] *= CFrame.new(0, Config.EntranceHeight, 0)
	
	-- Create tube
	local container = Instance.new("Folder", AstroTubeContainer)
	container.Name = "Tube"
	local touchPart = AstroTube.CreateTube(points, tube:GetAttributes(), container)
	
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