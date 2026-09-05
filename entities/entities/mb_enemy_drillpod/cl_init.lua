include("shared.lua")

local STATUS_COLOR = {
	incoming = Color(240, 190, 70),
	drilling = Color(230, 120, 70),
	active = Color(120, 200, 140),
	destroyed = Color(200, 80, 70),
}

function ENT:Draw()
	self:DrawModel()
end

hook.Add("HUDPaint", "MilBase.EnemyDrillPodHUD", function()
	local lp = LocalPlayer()
	if not IsValid(lp) then return end

	for _, pod in ipairs(ents.FindByClass("mb_enemy_drillpod")) do
		if not IsValid(pod) or pod:GetPos():DistToSqr(lp:GetPos()) > 1800 * 1800 then continue end
		local screen = (pod:GetPos() + Vector(0, 0, 48)):ToScreen()
		if not screen.visible then continue end
		local status = pod:GetSpawnStatus()
		local col = STATUS_COLOR[status] or MilBase.UI.dim
		draw.SimpleTextOutlined(string.upper(pod:SpawnLabel()), "MB.Small", screen.x, screen.y,
			col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
		draw.SimpleTextOutlined(string.upper(status or "active"), "MB.Tiny", screen.x, screen.y + 16,
			MilBase.UI.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
	end
end)
