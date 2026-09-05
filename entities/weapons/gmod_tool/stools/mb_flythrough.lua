--[[
	MilBase Flythrough Camera toolgun tool (staff only).

	Authors the cinematic map tour that new players see the first time they
	load in (see modules/sh_tutorial.lua). You fly around the map in noclip
	and drop camera keyframes; the tutorial then glides the camera along a
	smooth spline through them.

	  LEFT-CLICK  - drop a camera keyframe at your current view (eye position
	                + look angle). Fly to the next spot and click again.
	  RIGHT-CLICK - remove the last keyframe.
	  RELOAD      - clear all editor keyframes.

	Open the tool menu to set the pace, PREVIEW the tour, then SAVE it. Saved
	tours are per-map and persist (frontier_flythrough). Admin-only.
]]

TOOL.Category = "MilBase"
TOOL.Name     = "Flythrough Camera"

TOOL.ClientConVar["seconds"] = "3" -- seconds of travel per keyframe

if CLIENT then
	language.Add("tool.mb_flythrough.name", "Flythrough Camera")
	language.Add("tool.mb_flythrough.desc", "Author the new-player cinematic map tour.")
	language.Add("tool.mb_flythrough.left", "Drop a camera keyframe at your view")
	language.Add("tool.mb_flythrough.right", "Remove the last keyframe")
	language.Add("tool.mb_flythrough.reload", "Clear all editor keyframes")

	-- Editor keyframes live client-side; SAVE nets them to the server.
	MilBase.FlyAuthor = MilBase.FlyAuthor or {}

	function TOOL.BuildCPanel(panel)
		panel:Help("Fly around the map in noclip and LEFT-CLICK to drop camera "
			.. "keyframes for the new-player tour. RIGHT-CLICK removes the last one, "
			.. "RELOAD clears them all.")

		panel:NumSlider("Seconds per keyframe", "mb_flythrough_seconds", 0.5, 10, 1)

		local preview = panel:Button("Preview Tour")
		preview.DoClick = function()
			local pts = (MilBase.FlyAuthor and #MilBase.FlyAuthor > 1) and MilBase.FlyAuthor or MilBase.FlyPath
			MilBase.PlayFlythrough({
				points   = pts,
				seconds  = GetConVarNumber("mb_flythrough_seconds"),
				caption  = "TOUR PREVIEW",
			})
		end

		local save = panel:Button("Save Tour")
		save.DoClick = function()
			local pts = MilBase.FlyAuthor or {}
			if #pts < 2 then
				MilBase.Notify("Drop at least two keyframes before saving.", "warn")
				return
			end

			net.Start("MilBase_FlySave")
				net.WriteFloat(GetConVarNumber("mb_flythrough_seconds"))
				net.WriteUInt(#pts, 10)
				for _, kf in ipairs(pts) do
					net.WriteVector(kf.pos)
					net.WriteAngle(kf.ang)
				end
			net.SendToServer()
		end

		panel:Help("──────────")

		local load = panel:Button("Load Saved Tour Into Editor")
		load.DoClick = function()
			MilBase.FlyAuthor = {}
			for _, kf in ipairs(MilBase.FlyPath or {}) do
				MilBase.FlyAuthor[#MilBase.FlyAuthor + 1] = { pos = Vector(kf.pos), ang = Angle(kf.ang) }
			end
			MilBase.Notify("Loaded " .. #MilBase.FlyAuthor .. " keyframe(s) into the editor.", "ok")
		end

		local clr = panel:Button("Clear Editor Keyframes")
		clr.DoClick = function()
			MilBase.FlyAuthor = {}
			MilBase.Notify("Editor keyframes cleared.")
		end

		local del = panel:Button("Delete Saved Tour")
		del.DoClick = function()
			net.Start("MilBase_FlyClear")
			net.SendToServer()
		end
	end
end

local function toolAdmin(ply)
	return IsValid(ply) and (ply:IsAdmin() or ply:IsSuperAdmin())
end

function TOOL:LeftClick(trace)
	local ply = self:GetOwner()

	if CLIENT then
		MilBase.FlyAuthor = MilBase.FlyAuthor or {}
		local kf = { pos = LocalPlayer():EyePos(), ang = LocalPlayer():EyeAngles() }
		table.insert(MilBase.FlyAuthor, kf)
		surface.PlaySound("ui/buttonclickrelease.wav")
		return true
	end

	if not toolAdmin(ply) then
		MilBase.Notify(ply, "The flythrough tool is admin-only.")
		return false
	end
	MilBase.Notify(ply, "Keyframe dropped. Open the tool menu to preview / save.")
	return true
end

function TOOL:RightClick(trace)
	if CLIENT then
		if MilBase.FlyAuthor and #MilBase.FlyAuthor > 0 then
			table.remove(MilBase.FlyAuthor)
			surface.PlaySound("ui/buttonrollover.wav")
		end
		return true
	end
	return toolAdmin(self:GetOwner())
end

function TOOL:Reload(trace)
	if CLIENT then
		MilBase.FlyAuthor = {}
		surface.PlaySound("buttons/button15.wav")
		return true
	end
	return toolAdmin(self:GetOwner())
end

--------------------------------------------------------------------------
-- In-world editor preview: keyframe markers + the path between them, drawn
-- while the local admin is holding this tool.
--------------------------------------------------------------------------

if CLIENT then
	local function holdingTool()
		local lp = LocalPlayer()
		if not IsValid(lp) then return false end
		local wep = lp:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= "gmod_tool" then return false end
		return lp:GetInfo("gmod_toolmode") == "mb_flythrough"
	end

	hook.Add("PostDrawTranslucentRenderables", "MilBase.FlythroughEditor", function(depth, sky)
		if depth or sky then return end
		if not holdingTool() then return end

		local pts = MilBase.FlyAuthor or {}
		if #pts == 0 then return end

		-- Path line through the keyframes.
		render.SetColorMaterial()
		for i = 1, #pts - 1 do
			render.DrawLine(pts[i].pos, pts[i + 1].pos, Color(255, 198, 60), true)
		end

		-- Keyframe markers + a stub showing the look direction.
		for i, kf in ipairs(pts) do
			render.DrawWireframeBox(kf.pos, Angle(), Vector(-4, -4, -4), Vector(4, 4, 4),
				Color(255, 198, 60), true)
			render.DrawLine(kf.pos, kf.pos + kf.ang:Forward() * 40, Color(120, 200, 255), true)
			local scr = kf.pos:ToScreen()
			if scr.visible then
				draw.SimpleText(i, "MB.Small", scr.x, scr.y - 14, Color(255, 198, 60),
					TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end)
end
