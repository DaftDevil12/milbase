AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Prison Transfer LAAT"
ENT.Category = "MilBase"
ENT.Spawnable = false
ENT.AdminOnly = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "TransferID")
	self:NetworkVar("String", 1, "DestinationName")
	self:NetworkVar("String", 2, "FlightState")
end

if SERVER then
	local function smooth(value)
		value = math.Clamp(value, 0, 1)
		return value * value * (3 - 2 * value)
	end
	function ENT:Initialize()
		if not util.IsValidModel(self:GetModel()) then self:SetModel("models/props_c17/oildrum001.mdl") end
		self:SetMoveType(MOVETYPE_NONE); self:SetSolid(SOLID_NONE); self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		self:SetFlightState("STANDBY")
	end
	function ENT:BeginTransferRoute(path, callback, removeOnFinish, state)
		self.mb_finished = false
		self.mb_path = {}
		for _, point in ipairs(path or {}) do if point and isvector(point.pos) then self.mb_path[#self.mb_path+1] = point end end
		self.mb_callback = callback
		self.mb_removeOnFinish = removeOnFinish == true
		self.mb_index = 1
		self.mb_speed = math.max(120, tonumber(((MilBase.Config or {}).Prison or {}).TransferPickupFlightSpeed) or 420)
		self:SetFlightState(tostring(state or (self.mb_removeOnFinish and "DEPARTING" or "INBOUND")))
		if #self.mb_path < 2 then self:FinishTransferRoute() return end
		self:SetPos(self.mb_path[1].pos); self:SetAngles(self.mb_path[1].ang or angle_zero)
		self:StartSegment()
		if self.mb_sound then self.mb_sound:Stop() end
		self.mb_sound = CreateSound(self, "vehicles/airboat/fan_motor_idle_loop1.wav")
		if self.mb_sound then self.mb_sound:PlayEx(0.35, 102) end
	end
	function ENT:BeginTransferArrival(path, callback)
		self:BeginTransferRoute(path, callback, false, "INBOUND")
	end
	function ENT:BeginTransferDeparture(path, callback)
		self:BeginTransferRoute(path, callback, true, "DEPARTING")
	end
	function ENT:BeginTransferFlight(path, callback)
		self:BeginTransferDeparture(path, callback)
	end
	function ENT:StartSegment()
		local a, b = self.mb_path[self.mb_index], self.mb_path[self.mb_index + 1]
		if not a or not b then self:FinishTransferRoute() return end
		self.mb_startPos, self.mb_startAng = self:GetPos(), self:GetAngles()
		self.mb_targetPos, self.mb_targetAng = b.pos, b.ang or self:GetAngles()
		self.mb_started = CurTime()
		self.mb_duration = math.Clamp(self.mb_startPos:Distance(self.mb_targetPos) / self.mb_speed, 0.8, 12)
	end
	function ENT:FinishTransferRoute()
		if self.mb_finished then return end
		self.mb_finished = true
		if self.mb_sound then self.mb_sound:FadeOut(0.3) end
		local callback = self.mb_callback; self.mb_callback = nil
		if not self.mb_removeOnFinish then
			self:SetFlightState("LANDED")
			self.mb_started = nil
			if callback then pcall(callback, self) end
			return
		end
		self:SetFlightState("TRANSFERRED")
		if callback then pcall(callback, self) end
		self:Remove()
	end
	function ENT:Think()
		if self.mb_finished or not self.mb_started then self:NextThink(CurTime()+0.2) return true end
		local f = math.Clamp((CurTime()-self.mb_started)/math.max(0.1,self.mb_duration),0,1)
		local e = smooth(f); self:SetPos(LerpVector(e,self.mb_startPos,self.mb_targetPos)); self:SetAngles(LerpAngle(e,self.mb_startAng,self.mb_targetAng))
		if f >= 1 then self.mb_index=self.mb_index+1; self:StartSegment() end
		self:NextThink(CurTime()+0.02); return true
	end
	function ENT:OnRemove()
		if self.mb_sound then self.mb_sound:Stop() end
		if MilBase.Prison and MilBase.Prison.OnTransferTransportRemoved then
			MilBase.Prison.OnTransferTransportRemoved(self)
		end
	end
	return
end

function ENT:Draw()
	self:DrawModel()
	local ui=MilBase.UI or {}; local pos=self:WorldSpaceCenter()+Vector(0,0,math.max(48,self:BoundingRadius()*0.45)); local ang=Angle(0,LocalPlayer():EyeAngles().y-90,90)
	cam.Start3D2D(pos,ang,0.07)
		surface.SetDrawColor(3,9,16,225); surface.DrawRect(-180,-32,360,64); surface.SetDrawColor(ui.accent or Color(80,160,240)); surface.DrawOutlinedRect(-180,-32,360,64,2)
		draw.SimpleText("REPUBLIC PRISON TRANSFER",ui.text and "MB.Small" or "DermaDefaultBold",0,-12,ui.text or color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
		draw.SimpleText(string.upper(self:GetDestinationName()).."  •  "..string.upper(self:GetFlightState()),ui.text and "MB.Tiny" or "DermaDefault",0,12,ui.dim or Color(180,190,200),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
