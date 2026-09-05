AddCSLuaFile()

SWEP.PrintName = "Contraband Scanner"
SWEP.Author = "MilBase"
SWEP.Instructions = "Primary Fire: Scan prisoner or cell area for contraband."
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
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/v_weapon_smg1.mdl"
SWEP.WorldModel = "models/weapons/w_physics-gun.mdl"

function SWEP:Initialize()
	self:SetHoldType("pistol")
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryAttack(CurTime() + 1.5)
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local tr = util.TraceLine({
		start = owner:GetShootPos(),
		endpos = owner:GetShootPos() + owner:GetAimVector() * 180,
		filter = owner,
	})

	if SERVER then
		local ed = EffectData()
		ed:SetOrigin(tr.HitPos)
		ed:SetNormal(tr.HitNormal)
		util.Effect("cshot_spark", ed, true, true)

		self:EmitSound("ambient/energy/spark" .. math.random(1, 3) .. ".wav", 65, 110)

		local target = tr.Entity
		local P = MilBase.Prison
		if IsValid(target) and P and P.IsPrisonerEntity and P.IsPrisonerEntity(target) then
			local record = P.GetRecord and P.GetRecord(target:GetPrisonerID())
			if record then
				local contraband = record.contraband or {}
				if #contraband > 0 then
					local item = table.remove(contraband, 1)
					MilBase.Notify(owner, "Contraband Scanner: Confiscated " .. item .. " from " .. record.name .. "!", "ok")
					if P.AddIncident then
						P.AddIncident("contraband", owner:Nick() .. " confiscated " .. item .. " from " .. record.name .. ".", record, owner, 1)
					end
				else
					MilBase.Notify(owner, "Contraband Scanner: No prohibited items detected on " .. record.name .. ".", "warn")
				end
			end
		elseif tr.Hit then
			MilBase.Notify(owner, "Contraband Scanner: Cell area clear of radiation / metals.", "ok")
		end
	end
end

function SWEP:SecondaryAttack()
end
