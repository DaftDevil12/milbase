AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Fleet Supply Drop"
ENT.Category = "MilBase"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Charges")
end

if SERVER then
	function ENT:Initialize()
		local model = MilBase.Config.OrdnanceSupplyCrateModel or "models/Items/item_item_crate.mdl"
		if not util.IsValidModel(model) then model = "models/props_junk/wood_crate002a.mdl" end

		self:SetModel(model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:SetCharges(8)
		self:SetNWBool("mb_supply_drop", true)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:SetMass(math.max(phys:GetMass(), 80))
		end
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		if self:GetCharges() <= 0 then return end

		activator:SetHealth(math.min(activator:GetMaxHealth(), activator:Health() + 45))
		activator:SetArmor(math.min(100, activator:Armor() + 35))
		activator:GiveAmmo(120, "AR2", true)
		activator:GiveAmmo(180, "SMG1", true)
		activator:GiveAmmo(72, "Pistol", true)
		activator:GiveAmmo(24, "Buckshot", true)

		self:SetCharges(self:GetCharges() - 1)
		self:EmitSound("items/ammocrate_open.wav", 70, 100, 0.85)

		if MilBase.Notify then
			MilBase.Notify(activator, "Resupplied from fleet drop.", "ok")
		end

		if self:GetCharges() <= 0 then
			self:SetColor(Color(120, 120, 120))
			timer.Simple(3, function()
				if IsValid(self) then self:Remove() end
			end)
		end
	end

	function ENT:PhysicsCollide(data)
		if data.Speed > 180 then
			self:EmitSound("physics/metal/metal_box_impact_hard" .. math.random(1, 3) .. ".wav", 76)
		end
	end

	return
end

function ENT:Draw()
	self:DrawModel()

	local pos = self:GetPos() + Vector(0, 0, 34)
	local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)

	cam.Start3D2D(pos, ang, 0.08)
		local text = "SUPPLY DROP  " .. self:GetCharges()
		surface.SetFont("MB.Tiny")
		local tw = surface.GetTextSize(text)
		surface.SetDrawColor(0, 0, 0, 180)
		surface.DrawRect(-tw / 2 - 8, -12, tw + 16, 24)
		surface.SetDrawColor(255, 198, 60, 160)
		surface.DrawOutlinedRect(-tw / 2 - 8, -12, tw + 16, 24, 1)
		draw.SimpleText(text, "MB.Tiny", 0, 0, MilBase.UI.accent,
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
