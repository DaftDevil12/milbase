include("shared.lua")

function ENT:Initialize()
    self.LastDoorState = nil
    self.DoorFraction = 0
    self.UsingDoorSequence = false
end

function ENT:PlayStableDoorAnimation(doorsOpen)
    local sequenceName = doorsOpen and "doors_open" or "doors_close"
    local sequence = self:LookupSequence(sequenceName)

    if sequence and sequence >= 0 then
        self.UsingDoorSequence = true
        self:ResetSequence(sequence)
        self:SetCycle(0)
        self:SetPlaybackRate(1)
        return
    end

    self.UsingDoorSequence = false
end

function ENT:Draw()
    local pos, ang = SWInfil.GetFlightTransform(self, CurTime())
    local doorsOpen = self:GetDoorsOpen()

    if self.LastDoorState == nil then
        self.LastDoorState = doorsOpen

        if doorsOpen then
            self:PlayStableDoorAnimation(true)
        else
            self.UsingDoorSequence = false
            self.DoorFraction = 0
            self:SetPoseParameter("sidedoor_extentions", 0)
        end
    elseif doorsOpen ~= self.LastDoorState then
        self.LastDoorState = doorsOpen
        self:PlayStableDoorAnimation(doorsOpen)
    end

    if self.UsingDoorSequence then
        self:FrameAdvance(FrameTime())
    else
        local target = doorsOpen and 1 or 0
        self.DoorFraction = math.Approach(self.DoorFraction or 0, target, FrameTime() * 0.8)
        self:SetPoseParameter("sidedoor_extentions", self.DoorFraction)
    end

    self:SetRenderOrigin(pos)
    self:SetRenderAngles(ang)
    self:DrawModel()
    self:SetRenderOrigin()
    self:SetRenderAngles()
end
