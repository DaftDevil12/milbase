AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Fleet Fire Control Console"
ENT.Category = "MilBase"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "Status")
	self:NetworkVar("String", 1, "ActiveGrid")
	self:NetworkVar("Float", 0, "ReadyTime")
end

if SERVER then
	function ENT:Initialize()
		local model = MilBase.Config.OrdnanceConsoleModel or "models/props_lab/monitor01b.mdl"
		if not util.IsValidModel(model) then model = "models/props_lab/monitor01b.mdl" end

		self:SetModel(model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:SetStatus("STANDBY")
		self:SetActiveGrid("")
		self:SetReadyTime(0)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:EnableMotion(false) end
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		if MilBase.Ordnance and MilBase.Ordnance.OpenConsole then
			MilBase.Ordnance.OpenConsole(activator, self)
		end
	end

	return
end

local function screenAngles(ent)
	local ang = ent:GetAngles()
	ang:RotateAroundAxis(ang:Up(), 90)
	ang:RotateAroundAxis(ang:Forward(), 90)
	return ang
end

function ENT:Draw()
	self:DrawModel()

	local pos = self:GetPos() + self:GetUp() * 18 + self:GetForward() * 4
	local ang = screenAngles(self)
	local status = self:GetStatus()
	local grid = self:GetActiveGrid()
	local ready = self:GetReadyTime()
	local remaining = math.max(ready - CurTime(), 0)

	cam.Start3D2D(pos, ang, 0.08)
		surface.SetDrawColor(3, 8, 10, 238)
		surface.DrawRect(-145, -78, 290, 156)
		surface.SetDrawColor(255, 198, 60, 175)
		surface.DrawOutlinedRect(-145, -78, 290, 156, 2)
		surface.DrawLine(-128, -44, 128, -44)

		draw.SimpleText("FLEET FIRE CONTROL", "MB.Small", 0, -66, MilBase.UI.accent,
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(status ~= "" and status or "STANDBY", "MB.Tiny", 0, -24, MilBase.UI.text,
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(grid ~= "" and grid or "NO GRID LOCK", "MB.Tiny", 0, 2, MilBase.UI.dim,
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local pulse = 90 + math.sin(CurTime() * 5) * 45
		surface.SetDrawColor(255, 198, 60, pulse)
		for i = 0, 4 do
			surface.DrawLine(-118 + i * 58, 42, -96 + i * 58, 42)
		end

		if remaining > 0 then
			draw.SimpleText("T-" .. string.format("%.1f", remaining), "MB.Tiny", 0, 58, MilBase.UI.warn,
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			draw.SimpleText("READY", "MB.Tiny", 0, 58, MilBase.UI.ok,
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	cam.End3D2D()
end
