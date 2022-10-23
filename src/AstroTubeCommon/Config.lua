local AstroTubeConstants = {
	TubeTag = "astrotube";
	TubeContainerTag = "astrotube_container";
	TouchPartTag = "astrotube_touch_part";
	TouchPartPointsAttribute = "astrotube_points";

	SlideCooldown = 5;
	MaxFlingTime = 5;
	ExtraSlideDist = 10;
	EntranceHeight = 10;
	SegmentsPerTube = 4;
	TouchPartSize = Vector3.new(3, 4, 3);

	TubeAttributes = { -- [Name]: Default
		EjectSpeed = 0;
		SlideSpeed = 200;

		RingColor = Color3.fromRGB(170, 136, 0);
		
		TubeColor = BrickColor.new("Bright blue").Color;
		TubeLength = 10;
		TubeMaterial = Enum.Material.Glass;
		TubeRadius = 3;
		TubeTransparency = 0.6;
	}
}

return AstroTubeConstants