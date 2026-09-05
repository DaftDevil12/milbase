-- World entity for dropped inventory items. Press E to pick up.

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Dropped Item"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "ItemID")
	self:NetworkVar("Int", 0, "Amount")
end

if SERVER then

	function ENT:Initialize()
		local def = MilBase.Items[self:GetItemID()]

		self:SetModel(def and def.model or "models/props_junk/cardboard_box004a.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:Wake() end

		-- Don't litter the map forever.
		timer.Simple(300, function()
			if IsValid(self) then self:Remove() end
		end)
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end

		local given = MilBase.GiveItem(activator, self:GetItemID(), self:GetAmount(), self.mb_charges)

		if given >= self:GetAmount() then
			activator:EmitSound("items/itempickup.wav")
			self:Remove()
		elseif given > 0 then
			self:SetAmount(self:GetAmount() - given)
			activator:EmitSound("items/itempickup.wav")
		else
			MilBase.Notify(activator, "No room in your inventory.")
		end
	end

else

	function ENT:Draw()
		self:DrawModel()
	end

end
