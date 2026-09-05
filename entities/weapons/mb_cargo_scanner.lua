AddCSLuaFile()

SWEP.PrintName = "Cargo Scanner"
SWEP.Author = "MilBase"
SWEP.Instructions = "Primary Fire: Scan cargo crate or trade vessel for contraband."
SWEP.Category = "Star Wars RP"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 4
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/v_weapon_smg1.mdl"
SWEP.WorldModel = "models/weapons/w_physics-gun.mdl"

function SWEP:Initialize()
	self:SetHoldType("pistol")
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryAttack(CurTime() + 2.0)
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local tr = util.TraceLine({
		start = owner:GetShootPos(),
		endpos = owner:GetShootPos() + owner:GetAimVector() * 260,
		filter = owner,
	})

	if SERVER then
		local ed = EffectData()
		ed:SetOrigin(tr.HitPos)
		ed:SetNormal(tr.HitNormal)
		util.Effect("cshot_spark", ed, true, true)
		util.Effect("StunstickImpact", ed, true, true)

		self:EmitSound("ambient/energy/zap1.wav", 70, 115)

		local target = tr.Entity
		local contrabandItems = {
			"Illegal E-11 Blasters", "Smuggled Death Sticks", "Forged Imperial Chain-Code",
			"Stolen Republic Power Cells", "Unregistered Droid Core", "Hutt Syndicate Spice"
		}

		if IsValid(target) then
			if math.random(1, 3) == 1 then
				local item = contrabandItems[math.random(1, #contrabandItems)]
				MilBase.Notify(owner, "Cargo Scanner ALERT: Detected hidden " .. item .. "!", "danger")
				owner:EmitSound("buttons/weapon_cant_buy.wav", 70, 100)
			else
				MilBase.Notify(owner, "Cargo Scanner: Manifest matches cargo. No illegal items detected.", "ok")
				owner:EmitSound("buttons/button14.wav", 65, 110)
			end
		else
			MilBase.Notify(owner, "Cargo Scanner: Target crate / hull out of range.", "warn")
		end
	end
end

function SWEP:SecondaryAttack()
end
