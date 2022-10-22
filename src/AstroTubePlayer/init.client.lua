local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local PlayerModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

local AstroTube = require(ReplicatedStorage:WaitForChild("AstroTubeCommon"):WaitForChild("AstroTube"))
local Constants = require(ReplicatedStorage.AstroTubeCommon:WaitForChild("Config"))
local Destructor = require(script.Destructor)

local AstroTubeContainer = CollectionService:GetTagged(Constants.TubeContainerTag)[1]
if not AstroTubeContainer then
	CollectionService:GetInstanceAddedSignal(Constants.TubeContainerTag):Once(function(container)
		AstroTubeContainer = container
	end)
end

local ROOTPART_ROT = CFrame.Angles(-math.pi/2, 0, 0)

local CanSlide = true

local function eject(rootPart, humanoid)
	local dtor = Destructor.new()

	dtor:add(function()
		-- Fix up the character when we're done
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		rootPart.CFrame = CFrame.new(rootPart.Position)
		humanoid.PlatformStand = false
	end)

	dtor:add(RunService.Heartbeat:Connect(function()
		-- Point the character in the direction they're ejecting
		local pos = rootPart.Position
		local vel = rootPart.AssemblyLinearVelocity
		local up = rootPart.CFrame.UpVector
		rootPart.CFrame = CFrame.lookAt(pos, pos + vel, up) * ROOTPART_ROT
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end))

	local function touched(hit)
		if not (hit:IsDescendantOf(AstroTubeContainer) or hit:IsDescendantOf(LocalPlayer.Character)) then
			-- Touched something; cleanup
			dtor:destroy()
		end
	end
	for _, child in LocalPlayer.Character:GetChildren() do
		if child:IsA("BasePart") then
			dtor:add(child.Touched:Connect(touched))
		end
	end

	task.delay(Constants.MaxFlingTime, dtor.destroy, dtor)
end

local function slide(rootPart, humanoid, spline, slideSpeed, ejectSpeed)
	humanoid.PlatformStand = true
	Controls:Disable()

	local success = AstroTube.Slide(spline, slideSpeed, function(cframe)
		rootPart:PivotTo(cframe * ROOTPART_ROT)
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		return humanoid.Health == 0
	end)
	Controls:Enable()
	if not success then
		return
	end

	rootPart.AssemblyAngularVelocity = Vector3.zero
	if ejectSpeed and ejectSpeed > 0 then
		-- Eject!
		rootPart.AssemblyLinearVelocity = spline:SolveTangent(1) * ejectSpeed
		eject(rootPart, humanoid)
	else
		rootPart.CFrame = CFrame.new(rootPart.Position)
		rootPart.AssemblyLinearVelocity = Vector3.zero
		humanoid.PlatformStand = false
	end
end

local TouchPartConnections = {}
local function touchPartTagged(touchPart)
	local pointsString = touchPart:GetAttribute(Constants.TouchPartPointsAttribute)
	assert(pointsString)
	local points = AstroTube.UnserializePoints(pointsString)
	local spline = AstroTube.GetSpline(points)
	
	TouchPartConnections[touchPart] = touchPart.Touched:Connect(function(hit)
		if hit.Parent == LocalPlayer.Character then
			local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
			if not (CanSlide and rootPart and humanoid and humanoid.Health > 0) then
				return
			end

			CanSlide = false
			task.delay(Constants.SlideCooldown, function()
				CanSlide = true
			end)
			slide(rootPart, humanoid, spline, touchPart:GetAttribute("SlideSpeed"), touchPart:GetAttribute("EjectSpeed"))
		end
	end)
end
local function touchPartRemoved(touchPart)
	local conn = TouchPartConnections[touchPart]
	if conn then
		conn:Destroy()
		TouchPartConnections[touchPart] = nil
	end
end

for _, touchPart in CollectionService:GetTagged(Constants.TouchPartTag) do
	touchPartTagged(touchPart)
end
CollectionService:GetInstanceAddedSignal(Constants.TouchPartTag):Connect(touchPartTagged)
CollectionService:GetInstanceRemovedSignal(Constants.TouchPartTag):Connect(touchPartRemoved)