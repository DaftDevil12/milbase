TOOL.Category = "Star Wars RP"
TOOL.Name = "#tool.mb_dropship.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
	model = "auto",
	npc_class = "npc_combine_s",
	npc_model = "",
	npc_weapon = "weapon_ar2",
	npc_count = "6",
	team = "enemy",
	stance = "attack",
	health_mult = "1",
	approach_time = "7",
	hold_time = "5",
	departure_time = "6",
	approach_distance = "2400",
	approach_height = "900",
	departure_distance = "2400",
	departure_height = "900",
	hover_height = "155",
	drop_delay = "1.2",
	drop_radius = "120",
	turn_around = "1",
}

if CLIENT then
	language.Add("tool.mb_dropship.name", "NPC Dropship")
	language.Add("tool.mb_dropship.desc", "Call a cinematic gunship that drops NPCs and flies away.")
	language.Add("tool.mb_dropship.0", "Left-click a drop zone. Right-click from the desired approach point. Reload clears the custom approach point.")
end

local function canUseTool(ply)
	if game.SinglePlayer() then return true end
	if not IsValid(ply) then return false end
	if ply:IsAdmin() or ply:IsSuperAdmin() then return true end
	return MilBase and MilBase.CanRunEvents and MilBase.CanRunEvents(ply)
end

local function toolOptions(tool, ply)
	return {
		model = tool:GetClientInfo("model"),
		npcClass = tool:GetClientInfo("npc_class"),
		npcModel = tool:GetClientInfo("npc_model"),
		npcWeapon = tool:GetClientInfo("npc_weapon"),
		npcCount = tool:GetClientNumber("npc_count"),
		team = tool:GetClientInfo("team"),
		stance = tool:GetClientInfo("stance"),
		healthMult = tool:GetClientNumber("health_mult"),
		approachTime = tool:GetClientNumber("approach_time"),
		holdTime = tool:GetClientNumber("hold_time"),
		departureTime = tool:GetClientNumber("departure_time"),
		approachDistance = tool:GetClientNumber("approach_distance"),
		approachHeight = tool:GetClientNumber("approach_height"),
		departDistance = tool:GetClientNumber("departure_distance"),
		departHeight = tool:GetClientNumber("departure_height"),
		hoverHeight = tool:GetClientNumber("hover_height"),
		dropDelay = tool:GetClientNumber("drop_delay"),
		dropRadius = tool:GetClientNumber("drop_radius"),
		turnAround = tool:GetClientNumber("turn_around") ~= 0,
		yaw = IsValid(ply) and ply:EyeAngles().y or 0,
		startPos = IsValid(ply) and ply.mb_dropship_start or nil,
	}
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end

	local ply = self:GetOwner()
	if not canUseTool(ply) then return false end
	if not trace.Hit then return false end

	return MilBase.StartDropshipDrop(ply, trace.HitPos, toolOptions(self, ply))
end

function TOOL:RightClick()
	if CLIENT then return true end

	local ply = self:GetOwner()
	if not canUseTool(ply) then return false end

	ply.mb_dropship_start = ply:GetPos() + Vector(0, 0, 80)
	if MilBase.Notify then
		MilBase.Notify(ply, "Dropship approach point set. Left-click a drop zone.", "ok")
	end

	return true
end

function TOOL:Reload()
	if CLIENT then return true end

	local ply = self:GetOwner()
	if not canUseTool(ply) then return false end

	ply.mb_dropship_start = nil
	if MilBase.Notify then
		MilBase.Notify(ply, "Dropship approach point cleared.", "warn")
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
	panel:Help("NPC Dropship")
	panel:Help("Left-click the drop zone. Right-click while noclipped at a high approach point if you want a custom flight path.")

	panel:TextEntry("Gunship model path or auto", "mb_dropship_model")
	panel:TextEntry("NPC class", "mb_dropship_npc_class")
	panel:TextEntry("NPC model override (blank = default for class)", "mb_dropship_npc_model")
	panel:TextEntry("NPC weapon", "mb_dropship_npc_weapon")

	addChoiceBox(panel, "NPC team", "mb_dropship_team", {
		{ "Enemy", "enemy" },
		{ "Friendly", "friendly" },
		{ "Neutral", "neutral" },
	})

	addChoiceBox(panel, "NPC stance", "mb_dropship_stance", {
		{ "Attack", "attack" },
		{ "Hold", "hold" },
		{ "Patrol", "patrol" },
		{ "Careless", "careless" },
	})

	panel:NumSlider("NPC count", "mb_dropship_npc_count", 1, 24, 0)
	panel:NumSlider("NPC health multiplier", "mb_dropship_health_mult", 0.25, 5, 2)
	panel:NumSlider("Drop spread radius", "mb_dropship_drop_radius", 0, 420, 0)

	panel:CheckBox("Turn around after drop", "mb_dropship_turn_around")

	panel:NumSlider("Approach seconds", "mb_dropship_approach_time", 1, 45, 1)
	panel:NumSlider("Hover seconds", "mb_dropship_hold_time", 1, 30, 1)
	panel:NumSlider("Departure seconds", "mb_dropship_departure_time", 1, 45, 1)
	panel:NumSlider("Drop delay after arrival", "mb_dropship_drop_delay", 0, 12, 1)

	panel:NumSlider("Auto approach distance", "mb_dropship_approach_distance", 400, 9000, 0)
	panel:NumSlider("Auto approach height", "mb_dropship_approach_height", 100, 5000, 0)
	panel:NumSlider("Departure distance", "mb_dropship_departure_distance", 400, 9000, 0)
	panel:NumSlider("Departure height", "mb_dropship_departure_height", 100, 5000, 0)
	panel:NumSlider("Hover height", "mb_dropship_hover_height", 32, 600, 0)

	panel:Button("Clear custom approach point", "mb_dropship_clear_start")
	panel:Help("The Workshop HMP addon can be used by setting the model path once it is mounted. 'auto' attempts to discover an installed HMP gunship model and falls back to the LAAT model.")
end