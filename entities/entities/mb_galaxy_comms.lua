AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Ship Communications Terminal"
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
	function ENT:Initialize()
		local galaxy = MilBase.Config.GalaxyDirector or {}
		local model = galaxy.CommsTerminalModel or "models/props_lab/monitor02.mdl"
		if not util.IsValidModel(model) then model = "models/props_lab/monitor02.mdl" end

		self:SetModel(model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetUseType(SIMPLE_USE)
		self:SetOperator(NULL)
		self:SetSignalWaiting(false)
		self:SetChannelStatus("MONITORING")
		self:SetContactName("NO ACTIVE CONTACT")
		self.mb_hadSignal = false
		self.mb_nextSignalPing = 0

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:EnableMotion(false) end

		timer.Simple(0, function()
			if IsValid(self) and MilBase.Galaxy and MilBase.Galaxy.UpdateCommsTerminals then
				MilBase.Galaxy.UpdateCommsTerminals()
			end
		end)
	end

	function ENT:Think()
		local waiting = self:GetSignalWaiting()
		local now = CurTime()
		local galaxy = MilBase.Config.GalaxyDirector or {}
		local firstPing = waiting and not self.mb_hadSignal
		local unattendedRepeat = waiting and not IsValid(self:GetOperator())
			and now >= (self.mb_nextSignalPing or 0)

		if firstPing or unattendedRepeat then
			local ping = tostring(galaxy.CommsPingSound or "buttons/blip1.wav")
			if ping ~= "" then
				self:EmitSound(ping,
					math.Clamp(tonumber(galaxy.CommsPingSoundLevel) or 72, 40, 120),
					100, 0.85, CHAN_AUTO)
			end
			self.mb_nextSignalPing = now
				+ math.max(1, tonumber(galaxy.CommsPingInterval) or 5)
		end

		self.mb_hadSignal = waiting
		if not waiting then self.mb_nextSignalPing = 0 end
		self:NextThink(now + 0.25)
		return true
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		if MilBase.Galaxy and MilBase.Galaxy.UseCommsTerminal then
			MilBase.Galaxy.UseCommsTerminal(activator, self)
		else
			MilBase.Notify(activator, "Galaxy Director communications is unavailable.", "warn")
		end
	end

	function ENT:OnRemove()
		if not MilBase.Galaxy or MilBase.Galaxy.CommsTerminal ~= self then return end
		MilBase.Galaxy.ReleaseCommsOperator(
			"Ship communications disconnected: terminal removed.", true)
	end

	return
end

function ENT:Draw()
	self:DrawModel()

	local ui = MilBase.UI
	local accent = ui and ui.accent or Color(255, 198, 60)
	local warning = ui and ui.warn or Color(235, 175, 70)
	local text = ui and ui.text or color_white
	local dim = ui and ui.dim or Color(175, 185, 195)
	local operator = self:GetOperator()
	local waiting = self:GetSignalWaiting()
	local status = self:GetChannelStatus() ~= "" and self:GetChannelStatus() or "MONITORING"
	local contact = self:GetContactName() ~= "" and self:GetContactName() or "NO ACTIVE CONTACT"

	local operatorText = "PRESS E TO OPERATE"
	if MilBase.Naval and MilBase.Naval.IsNavy
	and not MilBase.Naval.IsNavy(LocalPlayer()) then
		operatorText = "NAVY CREDENTIALS REQUIRED"
	end
	if IsValid(operator) then
		local name = operator.MBName and operator:MBName() or operator:Nick()
		operatorText = operator == LocalPlayer()
			and "YOU ARE CONNECTED — REMAIN NEARBY"
			or ("CHANNEL OPERATED BY " .. string.upper(name))
	end

	local pos = self:WorldSpaceCenter() + Vector(0, 0, 34)
	local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
	local glow = waiting and warning or accent
	if waiting then
		local pulse = 0.65 + math.sin(CurTime() * 6) * 0.25
		glow = Color(warning.r, warning.g, warning.b, 255 * pulse)
	end

	cam.Start3D2D(pos, ang, 0.075)
		surface.SetDrawColor(3, 9, 16, 235)
		surface.DrawRect(-190, -68, 380, 136)
		surface.SetDrawColor(glow.r, glow.g, glow.b, glow.a or 220)
		surface.DrawOutlinedRect(-190, -68, 380, 136, 2)
		surface.DrawLine(-172, -29, 172, -29)

		draw.SimpleText("SHIP COMMUNICATIONS", ui and "MB.Small" or "DermaDefaultBold",
			0, -49, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(status, ui and "MB.Small" or "DermaDefaultBold",
			0, -10, waiting and warning or accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(contact, ui and "MB.Tiny" or "DermaDefault",
			0, 16, dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(operatorText, ui and "MB.Tiny" or "DermaDefault",
			0, 47, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
