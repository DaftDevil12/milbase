TOOL.Category = "Star Wars RP"
TOOL.Name = "#tool.mb_aat_dropship.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
	carrier_model = "auto",
	vehicle_class = "auto",
	vehicle_model = "auto",
	team = "enemy",
	approach_time = "7",
	hold_time = "5",
	departure_time = "6",
	approach_distance = "2600",
	approach_height = "950",
	departure_distance = "2600",
	departure_height = "950",
	hover_height = "185",
	drop_delay = "1.1",
	turn_around = "1",
	carry_forward = "0",
	carry_right = "0",
	carry_up = "-95",
}

if CLIENT then
	language.Add("tool.mb_aat_dropship.name", "AAT Dropship")
	language.Add("tool.mb_aat_dropship.desc", "Call a gunship carrying a visible AAT, then deploy it with AI enabled.")
	language.Add("tool.mb_aat_dropship.0", "Left-click an AAT drop zone. Right-click from a custom approach point. Reload clears that point.")
end

local function canUseTool(ply)
	if game.SinglePlayer() then return true end
	if not IsValid(ply) then return false end
	if ply:IsAdmin() or ply:IsSuperAdmin() then return true end
	return MilBase and MilBase.CanRunEvents and MilBase.CanRunEvents(ply)
end

local function toolOptions(tool, ply)
	return {
		carrierModel = tool:GetClientInfo("carrier_model"),
		vehicleClass = tool:GetClientInfo("vehicle_class"),
		vehicleModel = tool:GetClientInfo("vehicle_model"),
		team = tool:GetClientInfo("team"),
		approachTime = tool:GetClientNumber("approach_time"),
		holdTime = tool:GetClientNumber("hold_time"),
		departureTime = tool:GetClientNumber("departure_time"),
		approachDistance = tool:GetClientNumber("approach_distance"),
		approachHeight = tool:GetClientNumber("approach_height"),
		departDistance = tool:GetClientNumber("departure_distance"),
		departHeight = tool:GetClientNumber("departure_height"),
		hoverHeight = tool:GetClientNumber("hover_height"),
		dropDelay = tool:GetClientNumber("drop_delay"),
		turnAround = tool:GetClientNumber("turn_around") ~= 0,
		carryForward = tool:GetClientNumber("carry_forward"),
		carryRight = tool:GetClientNumber("carry_right"),
		carryUp = tool:GetClientNumber("carry_up"),
		yaw = IsValid(ply) and ply:EyeAngles().y or 0,
		startPos = IsValid(ply) and ply.mb_aat_dropship_start or nil,
	}
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end

	local ply = self:GetOwner()
	if not canUseTool(ply) then return false end
	if not trace.Hit then return false end

	return MilBase.StartVehicleDropshipDrop(ply, trace.HitPos, toolOptions(self, ply))
end

function TOOL:RightClick()
	if CLIENT then return true end

	local ply = self:GetOwner()
	if not canUseTool(ply) then return false end

	ply.mb_aat_dropship_start = ply:GetPos() + Vector(0, 0, 80)
	if MilBase.Notify then
		MilBase.Notify(ply, "AAT approach point set. Left-click a drop zone.", "ok")
	end

	return true
end

function TOOL:Reload()
	if CLIENT then return true end

	local ply = self:GetOwner()
	if not canUseTool(ply) then return false end

	ply.mb_aat_dropship_start = nil
	if MilBase.Notify then
		MilBase.Notify(ply, "AAT approach point cleared.", "warn")
	end

	return true
end

local function addChoiceBox(panel, label, convar, choices)
	local combo = panel:ComboBox(label, convar)
	for _, choice in ipairs(choices) do
		combo:AddChoice(choice[1], choice[2])
	end
	return combo
end

function TOOL.BuildCPanel(panel)
	panel:Help("AAT Dropship")
	panel:Help("The carrier visibly brings an AAT underneath it, releases it, then spawns the real LVS AAT with AI enabled.")

	panel:TextEntry("Carrier model path or auto", "mb_aat_dropship_carrier_model")
	panel:TextEntry("AAT class or auto", "mb_aat_dropship_vehicle_class")
	panel:TextEntry("Carried AAT model path or auto", "mb_aat_dropship_vehicle_model")

	addChoiceBox(panel, "AAT team", "mb_aat_dropship_team", {
		{ "Enemy", "enemy" },
		{ "Friendly", "friendly" },
		{ "Neutral", "neutral" },
	})

	panel:CheckBox("Turn around after drop", "mb_aat_dropship_turn_around")

	panel:NumSlider("Approach seconds", "mb_aat_dropship_approach_time", 1, 45, 1)
	panel:NumSlider("Hover seconds", "mb_aat_dropship_hold_time", 1, 30, 1)
	panel:NumSlider("Departure seconds", "mb_aat_dropship_departure_time", 1, 45, 1)
	panel:NumSlider("Drop delay after arrival", "mb_aat_dropship_drop_delay", 0, 12, 1)

	panel:NumSlider("Auto approach distance", "mb_aat_dropship_approach_distance", 400, 9000, 0)
	panel:NumSlider("Auto approach height", "mb_aat_dropship_approach_height", 100, 5000, 0)
	panel:NumSlider("Departure distance", "mb_aat_dropship_departure_distance", 400, 9000, 0)
	panel:NumSlider("Departure height", "mb_aat_dropship_departure_height", 100, 5000, 0)
	panel:NumSlider("Hover height", "mb_aat_dropship_hover_height", 48, 800, 0)

	panel:NumSlider("Carried AAT forward/back", "mb_aat_dropship_carry_forward", -320, 320, 0)
	panel:NumSlider("Carried AAT left/right", "mb_aat_dropship_carry_right", -320, 320, 0)
	panel:NumSlider("Carried AAT up/down", "mb_aat_dropship_carry_up", -360, 64, 0)
	panel:Help("If the tank clips into the carrier, adjust the carried AAT up/down value.")
	panel:Button("Clear custom approach point", "mb_aat_dropship_clear_start")
end
