AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Prison Security Terminal"
ENT.Author = "MilBase"
SWEP = SWEP or {}
ENT.Category = "MilBase"
ENT.Spawnable = true
ENT.AdminOnly = true

if SERVER then
	function ENT:Initialize()
		self:SetModel("models/props_combine/combine_interface001.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:Wake() end
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end

		local P = MilBase.Prison
		if P and P.CanUse and not P.CanUse(activator) then
			MilBase.Notify(activator, "Access Denied: Only Coruscant Guard, Navy & Officers may access the Security Terminal.", "danger")
			return
		end

		net.Start("MilBase_Prison_CommsData")
		net.WriteTable({
			message = "REPUBLIC DETENTION SECURITY TERMINAL ONLINE",
			destinations = {
				{ id = "coruscant", name = "Coruscant Judicial Detention", capacity = 100, used = 42 },
				{ id = "kuat", name = "Kuat Sector Holding Facility", capacity = 50, used = 18 },
				{ id = "naboo", name = "Naboo Royal Guard Citadel", capacity = 30, used = 8 },
			},
			prisoners = (P and P.ActivePrisonersList) and P.ActivePrisonersList() or {},
		})
		net.Send(activator)
	end
else
	function ENT:Draw()
		self:DrawModel()
		local lp = LocalPlayer()
		if not IsValid(lp) or lp:GetPos():DistToSqr(self:GetPos()) > 400 * 400 then return end

		local pos = self:WorldSpaceCenter() + Vector(0, 0, 38)
		local ang = Angle(0, lp:EyeAngles().y - 90, 90)

		cam.Start3D2D(pos, ang, 0.08)
			surface.SetDrawColor(3, 12, 22, 230)
			surface.DrawRect(-140, -35, 280, 70)
			surface.SetDrawColor(65, 175, 240)
			surface.DrawOutlinedRect(-140, -35, 280, 70, 2)

			draw.SimpleText("SECURITY CONTROL TERMINAL", "DermaDefaultBold", 0, -16, Color(100, 210, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("PRESS [E] TO ACCESS FACILITY CONTROLS", "DermaDefault", 0, 10, Color(200, 220, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end
end
