--[[
	Planted demolition charge. A saboteur plants one on a ship's weak point
	(a hull-breach spot); detonating it (self-menu -> Detonate) blows the
	breach open and damages everything nearby. Visible with a blinking
	light so defenders can spot and (later) defuse it.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Demolition Charge"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Planter")
end

if SERVER then

	function ENT:Initialize()
		self:SetModel("models/weapons/w_slam.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE) -- stays stuck where planted
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON) -- don't block soldiers

		self:EmitSound("weapons/slam/mine_mode.wav", 65)
	end

	-- Blow up: open the linked breach + blast damage, then remove.
	function ENT:Detonate()
		local pos = self:GetPos()
		local planter = self:GetPlanter()

		-- Trigger the weak point (creates the hull breach).
		local breach = self.mb_breach
		if IsValid(breach) and breach.Break and not breach:GetBreached() then
			breach:Break()
		end

		-- Or wreck the engine/hyperdrive part it was planted on.
		local part = self.mb_part
		if IsValid(part) and part.Destroy and not part:GetDestroyed() then
			part:Destroy()
		end

		local cfg = MilBase.Config
		util.BlastDamage(self, IsValid(planter) and planter or self, pos,
			cfg.SabotageBlastRadius or 260, cfg.SabotageBlastDamage or 120)

		local fx = EffectData()
		fx:SetOrigin(pos)
		fx:SetScale(1)
		util.Effect("Explosion", fx)
		util.Effect("HelicopterMegaBomb", fx)

		self:Remove()
	end

else

	function ENT:Draw()
		self:DrawModel()

		-- Blinking arming light.
		if (math.floor(RealTime() * 2) % 2) == 0 then
			render.SetColorMaterial()
			render.DrawSphere(self:GetPos() + self:GetUp() * 2, 1.6, 8, 8, Color(220, 60, 40))
		end
	end

end
