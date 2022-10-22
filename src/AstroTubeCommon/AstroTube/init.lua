local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.Config)
local CatRom = require(script.CatRom)
local Ring = script.Ring
local Tube = script.Tube
local Entrance = script.Entrance

local SEGMENTS_PER_TUBE = 4
local ENTRANCE_SIZE = Vector3.new(3, 4, 3)

local TUBE_BONE_ROT = CFrame.Angles(-math.pi/2, 0, 0)

local AstroTube = {}

function AstroTube.Slide(spline, speed, callback)
	speed = speed or Config.TubeAttributes.SlideSpeed

	local slideTime = spline.length / speed
	local extraTime = Config.ExtraSlideDist / speed
	local finished = false
	local t = os.clock()

	while os.clock() - t <= slideTime + extraTime and not finished do
		local timeElapsed = os.clock() - t
		local alpha = timeElapsed / slideTime

		local pos = spline:SolveUniformPosition(alpha)
		local cf = CFrame.lookAt(pos, pos + spline:SolveUniformTangent(alpha))
		finished = callback(cf) ~= false
		RunService.Heartbeat:Wait()
	end
	
	return not finished
end

local function createTube(cf0, cf1, radius)
	local vec = cf1.Position - cf0.Position
	local tube = Tube:Clone()
	tube.CFrame = cf0 * TUBE_BONE_ROT + vec/2
	tube.Bottom.WorldCFrame = cf0 * TUBE_BONE_ROT
	tube.Top.WorldCFrame = cf1 * TUBE_BONE_ROT
	tube.Size = Vector3.new(radius*2, vec.Magnitude, radius*2)
	return tube
end
local function createRing(cf, radius)
	local ring = Ring:Clone()
	ring.CFrame = cf * CFrame.Angles(math.pi/2, 0, 0)
	ring.Size = Ring.Size * (radius/3) -- The ring mesh has a radius of 3
	return ring
end

function AstroTube.CreateTube(points, entranceCF, attributes, parent)
	local props = {}
	for name, default in pairs(Config.TubeAttributes) do
		props[name] = attributes[name] or default
	end
	
	local function styleTube(part)
		part.Color = props.TubeColor
		part.Transparency = props.TubeTransparency
		part.Material = props.TubeMaterial
		part.Parent = part.Parent or parent
	end
	local function styleRing(part)
		part.Color = props.RingColor
		part.Parent = part.Parent or parent
	end
	
	local spline = CatRom.new(points)
	local numTubes = math.ceil(spline.length / props.TubeLength) * SEGMENTS_PER_TUBE

	local prevCF = spline:SolveUniformCFrame(0)
	-- Align prevCF to top of entrance
	prevCF = CFrame.lookAt(prevCF.Position, prevCF.Position + entranceCF.UpVector, prevCF.UpVector)
	for i = 1, numTubes do
		local cf = spline:SolveUniformCFrame(i / numTubes)
		-- Low-budget rotation-minimizing frame
		cf = CFrame.lookAt(cf.Position, cf.Position + cf.LookVector, prevCF.UpVector)
		styleTube(createTube(prevCF, cf, props.TubeRadius))
		if i%SEGMENTS_PER_TUBE == 0 then
			styleRing(createRing(cf, props.TubeRadius))
		end
		prevCF = cf
	end
	
	local entrance = Entrance:Clone()
	entrance:PivotTo(entranceCF)
	styleRing(entrance.Ring1)
	styleRing(entrance.Ring2)
	styleRing(entrance.DoorFrame)
	styleTube(entrance.Tube)
	entrance.Parent = parent
	
	local touchPart = Instance.new("Part")
	touchPart.Anchored = true
	touchPart.CanCollide = false
	touchPart.CanQuery = false
	touchPart.CFrame = entranceCF * CFrame.new(0, ENTRANCE_SIZE.Y/2, 0)
	touchPart.Size = ENTRANCE_SIZE
	touchPart.Transparency = 1
	touchPart.Parent = parent
	
	return touchPart
end

-- Convenience function for AstroTubePlayer
function AstroTube.GetSpline(points)
	return CatRom.new(points)
end

-- Serializes a table of points into a string of the form "x1,y1,z1|x2,y2,z2|,..."
function AstroTube.SerializePoints(points)
	local pointsStrings = table.create(#points)
	for i, point in points do 
		pointsStrings[i] = point.X .. "," .. point.Y .. "," .. point.Z
	end
	return table.concat(pointsStrings, "|")
end

-- Unserializes a string of points
function AstroTube.UnserializePoints(pointsString)
	local pointStrings = string.split(pointsString, "|")
	local points = table.create(#pointStrings)
	for i, pointString in pointStrings do
		local coords = string.split(pointString, ",")
		points[i] = Vector3.new(tonumber(coords[1]), tonumber(coords[2]), tonumber(coords[3]))
	end
	return points
end

return AstroTube