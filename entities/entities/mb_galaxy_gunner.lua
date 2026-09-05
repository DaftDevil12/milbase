AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Long-Range Fire Control"
ENT.Category = "MilBase"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Operator")
	self:NetworkVar("Bool", 0, "SignalWaiting")
	self:NetworkVar("String", 0, "ChannelStatus")
	self:NetworkVar("String", 1, "ContactName")
end

if SERVER then
	local function ordnanceType(terminal)
		if terminal:GetClass() == "mb_galaxy_ion" then return "ion" end
		if terminal:GetClass() == "mb_galaxy_torpedo" then return "torpedo" end
		return "turbolaser"
	end

	function ENT:Initialize()
		local galaxy = MilBase.Config.GalaxyDirector or {}
		local kind = ordnanceType(self)
		local model = kind == "ion" and galaxy.IonTerminalModel
			or kind == "torpedo" and galaxy.TorpedoTerminalModel
			or galaxy.GunnerTerminalModel or galaxy.CommsTerminalModel
			or "models/props_lab/monitor02.mdl"
		if not util.IsValidModel(model) then model = "models/props_lab/monitor02.mdl" end
		self:SetModel(model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetUseType(SIMPLE_USE)
		self:SetOperator(NULL)
		self:SetSignalWaiting(false)
		self:SetChannelStatus("STANDBY")
		self:SetContactName("AWAITING SCANNER LOCK")
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:EnableMotion(false) end
		timer.Simple(0, function()
			if IsValid(self) and MilBase.Galaxy and MilBase.Galaxy.UpdateCommsTerminals then
				MilBase.Galaxy.UpdateCommsTerminals()
			end
		end)
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		if MilBase.Galaxy and MilBase.Galaxy.UseOrdnanceTerminal then
			MilBase.Galaxy.UseOrdnanceTerminal(activator, self)
		else
			MilBase.Notify(activator, "Galaxy Director fire control is unavailable.", "warn")
		end
	end

	function ENT:OnRemove()
		if MilBase.Galaxy and MilBase.Galaxy.ReleaseOrdnanceOperatorForTerminal then
			MilBase.Galaxy.ReleaseOrdnanceOperatorForTerminal(self,
				"Ordnance control disconnected: terminal removed.")
		end
	end

	return
end

function ENT:Draw()
	self:DrawModel()
	local ui = MilBase.UI
	local accent = ui and ui.danger or Color(230, 75, 65)
	local warning = ui and ui.warn or Color(235, 175, 70)
	local text = ui and ui.text or color_white
	local dim = ui and ui.dim or Color(175, 185, 195)
	local operator = self:GetOperator()
	local waiting = self:GetSignalWaiting()
	local status = self:GetChannelStatus() ~= "" and self:GetChannelStatus() or "STANDBY"
	local contact = self:GetContactName() ~= "" and self:GetContactName() or "AWAITING SCANNER LOCK"
	local kind = self:GetClass() == "mb_galaxy_ion" and "ion"
		or self:GetClass() == "mb_galaxy_torpedo" and "torpedo" or "turbolaser"
	local title = kind == "ion" and "ION CANNON CONTROL"
		or kind == "torpedo" and "PROTON TORPEDO CONTROL" or "TURBOLASER FIRE CONTROL"
	local operatorText = "PRESS E TO OPERATE"
	if MilBase.Naval and MilBase.Naval.IsNavy
	and not MilBase.Naval.IsNavy(LocalPlayer()) then
		operatorText = "NAVY CREDENTIALS REQUIRED"
	end
	if IsValid(operator) then
		local name = operator.MBName and operator:MBName() or operator:Nick()
		operatorText = operator == LocalPlayer() and "YOU ARE AT " .. title
			or ("GUNNER: " .. string.upper(name))
	end
	local pos = self:WorldSpaceCenter() + Vector(0, 0, 34)
	local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
	local glow = waiting and warning or accent
	cam.Start3D2D(pos, ang, 0.075)
		surface.SetDrawColor(16, 5, 7, 235)
		surface.DrawRect(-190, -68, 380, 136)
		surface.SetDrawColor(glow.r, glow.g, glow.b, 220)
		surface.DrawOutlinedRect(-190, -68, 380, 136, 2)
		surface.DrawLine(-172, -29, 172, -29)
		draw.SimpleText(title, ui and "MB.Small" or "DermaDefaultBold",
			0, -49, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(status, ui and "MB.Small" or "DermaDefaultBold",
			0, -10, glow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(contact, ui and "MB.Tiny" or "DermaDefault",
			0, 16, dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(operatorText, ui and "MB.Tiny" or "DermaDefault",
			0, 47, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
