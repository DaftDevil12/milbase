TOOL.Category = "Star Wars RP"
TOOL.Name = "#tool.mb_enemy_spawn.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
	spawn_name = "Drill Pod",
	radius = "110",
	max_active = "0",
	drop_height = "1600",
	drop_time = "3",
	drill_time = "3",
}

if CLIENT then
	language.Add("tool.mb_enemy_spawn.name", "Event Enemy Spawn")
	language.Add("tool.mb_enemy_spawn.desc", "Place event-enemy spawns.")
	language.Add("tool.mb_enemy_spawn.0", "Left-click drops a drill pod. Right-click places an invisible spawn. Reload removes the aimed spawn.")
end

local function canUseTool(ply)
	if game.SinglePlayer() then return true end
	if not IsValid(ply) then return false end
	if ply:IsAdmin() or ply:IsSuperAdmin() then return true end
	return MilBase and MilBase.CanRunEvents and MilBase.CanRunEvents(ply)
end

local function opts(tool)
	return {
		name = tool:GetClientInfo("spawn_name"),
		radius = tool:GetClientNumber("radius"),
		maxActive = tool:GetClientNumber("max_active"),
		dropHeight = tool:GetClientNumber("drop_height"),
		dropTime = tool:GetClientNumber("drop_time"),
		drillTime = tool:GetClientNumber("drill_time"),
	}
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUseTool(ply) or not trace.Hit then return false end
	return IsValid(MilBase.CreateEventEnemyDrillPod(ply, trace.HitPos, opts(self)))
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUseTool(ply) or not trace.Hit then return false end
	local data = opts(self)
	data.name = data.name ~= "" and data.name or "Enemy Spawn"
	return MilBase.CreateInvisibleEventEnemySpawn(ply, trace.HitPos, data) ~= nil
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUseTool(ply) then return false end

	local ent = trace.Entity
	if IsValid(ent) and ent:GetClass() == "mb_enemy_drillpod" then
		if MilBase.RemoveEventEnemySpawn then MilBase.RemoveEventEnemySpawn(ent:GetSpawnID()) end
		return true
	end

	local hit = trace.HitPos
	local best, bestD
	for id, spawn in pairs(MilBase.EventEnemySpawns or {}) do
		local d = spawn.pos and spawn.pos:DistToSqr(hit) or math.huge
		if d < 220 * 220 and (not bestD or d < bestD) then
			best, bestD = id, d
		end
	end
	if best and MilBase.RemoveEventEnemySpawn then
		MilBase.RemoveEventEnemySpawn(best)
		if MilBase.Notify then MilBase.Notify(ply, "Enemy spawn removed.", "warn") end
		return true
	end

	return false
end

function TOOL.BuildCPanel(panel)
	panel:Help("Event Enemy Spawn")
	panel:TextEntry("Spawn name", "mb_enemy_spawn_spawn_name")
	panel:NumSlider("Spawn radius", "mb_enemy_spawn_radius", 32, 512, 0)
	panel:NumSlider("Max active enemies", "mb_enemy_spawn_max_active", 0, 64, 0)
	panel:NumSlider("Drop height", "mb_enemy_spawn_drop_height", 200, 6000, 0)
	panel:NumSlider("Drop seconds", "mb_enemy_spawn_drop_time", 0.2, 20, 1)
	panel:NumSlider("Drill seconds", "mb_enemy_spawn_drill_time", 0, 20, 1)
end
