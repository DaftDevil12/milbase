AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Fleet Logistics Console"
ENT.Category = "MilBase"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "FleetCount")
	self:NetworkVar("Int", 1, "CargoUsed")
	self:NetworkVar("Int", 2, "CargoCapacity")
	self:NetworkVar("Bool", 0, "RegistryReady")
end

if SERVER then
	function ENT:Initialize()
		local naval = MilBase.Config.NavalOperations or {}
		local model = naval.FleetConsoleModel
			or "models/lordtrilobite/starwars/isd/imp_console_medium02.mdl"
		if not util.IsValidModel(model) then model = "models/props_lab/monitor02.mdl" end
		self:SetModel(model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetUseType(SIMPLE_USE)
		self:SetFleetCount(0)
		self:SetCargoUsed(0)
		self:SetCargoCapacity(0)
		self:SetRegistryReady(false)
		local physics = self:GetPhysicsObject()
		if IsValid(physics) then physics:EnableMotion(false) end
		self:NextThink(CurTime())
	end

	function ENT:Think()
		local naval = MilBase.Naval
		local state = naval and naval.FleetState
		self:SetRegistryReady(naval and naval.FleetRegistryReady == true)
		self:SetFleetCount(istable(state) and table.Count(state.ships or {}) or 0)
		self:SetCargoUsed(naval and naval.CargoUsed and naval.CargoUsed() or 0)
		self:SetCargoCapacity(naval and naval.FleetCargoCapacity
			and naval.FleetCargoCapacity() or 0)
		self:NextThink(CurTime() + 1)
		return true
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		if MilBase.Naval and MilBase.Naval.UseFleetConsole then
			MilBase.Naval.UseFleetConsole(activator, self)
		else
			MilBase.Notify(activator, "Fleet logistics registry is unavailable.", "warn")
		end
	end

	return
end

function ENT:Draw()
	self:DrawModel()
	local ui = MilBase.UI
	local accent = ui and ui.accent or Color(255, 198, 60)
	local text = ui and ui.text or color_white
	local dim = ui and ui.dim or Color(175, 185, 195)
	local ok = ui and ui.ok or Color(90, 205, 125)
	local warning = ui and ui.warn or Color(235, 175, 70)
	local status = self:GetRegistryReady() and "FLEET REGISTRY ONLINE"
		or "FLEET REGISTRY LOADING"
	local access = "PRESS E TO OPERATE"
	if MilBase.Naval and MilBase.Naval.IsNavy
	and not MilBase.Naval.IsNavy(LocalPlayer()) then
		access = "NAVY CREDENTIALS REQUIRED"
	end
	local pos = self:WorldSpaceCenter() + Vector(0, 0, 34)
	local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
	cam.Start3D2D(pos, ang, 0.075)
		surface.SetDrawColor(3, 9, 16, 238)
		surface.DrawRect(-190, -72, 380, 144)
		surface.SetDrawColor(accent.r, accent.g, accent.b, 220)
		surface.DrawOutlinedRect(-190, -72, 380, 144, 2)
		surface.DrawLine(-172, -31, 172, -31)
		draw.SimpleText("FLEET LOGISTICS", ui and "MB.Small" or "DermaDefaultBold",
			0, -52, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(status, ui and "MB.Small" or "DermaDefaultBold",
			0, -12, self:GetRegistryReady() and ok or warning,
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(self:GetFleetCount() .. " VESSELS   /   CARGO "
			.. self:GetCargoUsed() .. "/" .. self:GetCargoCapacity(),
			ui and "MB.Tiny" or "DermaDefault", 0, 17, dim,
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(access, ui and "MB.Tiny" or "DermaDefault",
			0, 49, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
