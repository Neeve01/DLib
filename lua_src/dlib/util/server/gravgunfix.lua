
-- Copyright (C) 2017-2019 DBotThePony

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

-- commented out to not forget which mess my brain digested in sdk code

net.pool('dlib_physgun_tooheavy')
net.pool('dlib_physgun_claws')
net.pool('dlib_physgun_hold')

local IsValid = FindMetaTable('Entity').IsValid
local CurTimeL = CurTimeL
local util = util
local hook = hook
local MOVETYPE_VPHYSICS = MOVETYPE_VPHYSICS
local IN_ATTACK = IN_ATTACK
local IN_ATTACK2 = IN_ATTACK2

-- lets hope nobody reload models and suddenly
-- different model for gravgun loads
local sequences, sequencesH
local lastSeq = -1

local physcannon_maxmass = GetConVar('physcannon_maxmass')
local physcannon_cone = GetConVar('physcannon_cone')

local MAX_GRAB_DIST = 250

local CLAWS_MINS, CLAWS_MAXS = Vector(-4, -4, -4), Vector(4, 4, 4)

local ENABLE = CreateConVar('dlib_gravgun_fix', '1', {FCVAR_NOTIFY, FCVAR_ARCHIVE}, 'Enable Zero Point Energy Field Manipulator:tm: sound fix')

-- this code can not be predicted clientside due to VPhysics limitations
hook.Add('Think', 'DLib_GravgunSoundFix', function(ply)
	if not ENABLE:GetBool() then return end

	for i, ply in ipairs(player.GetAll()) do
		local weapon = ply:GetActiveWeapon()
		if not weapon:IsValid() then goto CONTINUE end
		if weapon:GetClass() ~= 'weapon_physcannon' then goto CONTINUE end
		local weapont = weapon:GetTable()
		local plyt = ply:GetTable()
		local altfire = ply:KeyDown(IN_ATTACK2)

		if not sequences then
			sequences = weapon:GetSequenceList()
			sequencesH = table.flipIntoHash(sequences)
		end

		if plyt.__dlib_gravgun_hold_check then
			local m_hUseEntity = ply:GetInternalVariable('m_hUseEntity')
			plyt.__dlib_gravgun_hold_r = not IsValid(m_hUseEntity)

			if plyt.__dlib_gravgun_hold_r then
				weapon:EmitSound('Weapon_PhysCannon.Pickup')
				net.Start('dlib_physgun_hold', true)
				net.WriteBool(true)
				net.Send(ply)
				plyt.__dlib_physgun_hold_s = true
			end

			plyt.__dlib_gravgun_hold_check = false
		end

		if IsValid(plyt.__dlib_gravgun_hold) and ply:KeyDown(IN_ATTACK) and plyt.__dlib_gravgun_hold_r then
			weapont.__dlib_too_heavy = false
			--clawsOpen = false
			weapont.__dlib_claws_open = false
			plyt.__dlib_gravgun_hold = nil
			weapont.__dlib_gravgun_wait = CurTimeL() + 0.3
			weapont.__dlib_gravgun_dropped = plyt.__dlib_gravgun_hold
			net.Start('dlib_physgun_hold', true)
			net.WriteBool(false)
			net.Send(ply)
			plyt.__dlib_physgun_hold_s = false
			goto CONTINUE
		end

		if weapont.__dlib_gravgun_wait and weapont.__dlib_gravgun_wait > CurTimeL() then goto CONTINUE end

		if plyt.__dlib_gravgun_hold and (not IsValid(plyt.__dlib_gravgun_hold) or not plyt.__dlib_gravgun_hold:IsPlayerHolding()) then
			if plyt.__dlib_gravgun_hold_r then
				weapon:EmitSound('Weapon_PhysCannon.Drop')
				net.Start('dlib_physgun_hold', true)
				net.WriteBool(false)
				net.Send(ply)
				plyt.__dlib_physgun_hold_s = false
			end

			plyt.__dlib_gravgun_hold = nil
		end

		if not plyt.__dlib_gravgun_hold_r then
			local m_hUseEntity = ply:GetInternalVariable('m_hUseEntity')
			plyt.__dlib_gravgun_hold_r = not IsValid(m_hUseEntity)
		end

		local spos = ply:GetShootPos()
		local fwd = ply:GetAimVector()

		local tr = util.TraceHull({
			start = spos,
			endpos = spos + fwd * MAX_GRAB_DIST,
			filter = ply,
			mask = MASK_SHOT,
			mins = CLAWS_MINS,
			maxs = CLAWS_MAXS
		})

		local clawsOpen = tr.Hit and tr.HitNonWorld and tr.Entity:IsValid() and tr.Entity:GetMoveType() == MOVETYPE_VPHYSICS

		if clawsOpen then
			local phys = tr.Entity:GetPhysicsObject()
			clawsOpen = phys:IsValid()

			if clawsOpen then
				clawsOpen = phys:IsMotionEnabled() and phys:GetMass() <= physcannon_maxmass:GetInt() and hook.Run('GravGunPickupAllowed', ply, tr.Entity) ~= false
			end
		end

		if clawsOpen then
			if tr.Entity:IsPlayerHolding() and plyt.__dlib_gravgun_hold ~= tr.Entity then
				plyt.__dlib_gravgun_hold = tr.Entity
				plyt.__dlib_gravgun_hold_check = true
				plyt.__dlib_gravgun_hold_r = false
			end
		elseif IsValid(plyt.__dlib_gravgun_hold) and plyt.__dlib_gravgun_hold:IsPlayerHolding() then
			clawsOpen = true
			tr.Entity = plyt.__dlib_gravgun_hold
		end

		-- grab from distance
		if altfire and not weapont.__dlib_too_heavy then
			weapont.__dlib_too_heavy = true

			if not weapont.__dlib_hold_idle and not clawsOpen then
				weapon:EmitSound('Weapon_PhysCannon.TooHeavy')
				net.Start('dlib_physgun_tooheavy', true)
				net.WriteBool(true)
				net.Send(ply)
			end
		elseif not altfire and weapont.__dlib_too_heavy then
			weapont.__dlib_too_heavy = false
			net.Start('dlib_physgun_tooheavy', true)
			net.WriteBool(false)
			net.Send(ply)
		end

		-- hold
		local seq = weapon:GetSequence()

		if sequencesH.hold_idle == seq and not weapont.__dlib_hold_idle then
			weapont.__dlib_hold_idle = true
		elseif sequencesH.hold_idle ~= seq and weapont.__dlib_hold_idle then
			weapont.__dlib_hold_idle = false
			net.Start('dlib_physgun_hold', true)
			net.WriteBool(false)
			net.Send(ply)
			plyt.__dlib_physgun_hold_s = false
		end

		-- claws
		if not weapont.__dlib_hold_idle then
			if clawsOpen then
				if not weapont.__dlib_claws_open then
					if not altfire and tr.Entity ~= weapont.__dlib_gravgun_dropped then
						weapon:EmitSound('Weapon_PhysCannon.OpenClaws')
						net.Start('dlib_physgun_claws', true)
						net.WriteBool(true)
						net.Send(ply)
					end

					weapont.__dlib_claws_open = true
					weapont.__dlib_claws_open_t = CurTimeL() + 0.7
				end

				weapont.__dlib_claws_stare = (weapont.__dlib_claws_stare or 0) + FrameTime()
				weapont.__dlib_claws_open_t = weapont.__dlib_claws_open_t:max(CurTimeL() + 0.6)
			else
				if weapont.__dlib_claws_stare then
					if weapont.__dlib_claws_stare < 0.1 then
						weapont.__dlib_claws_open_t = weapont.__dlib_claws_open_t:min(CurTimeL() + 0.45)
					elseif weapont.__dlib_claws_stare < 0.25 then
						weapont.__dlib_claws_open_t = weapont.__dlib_claws_open_t:min(CurTimeL() + 0.5)
					elseif weapont.__dlib_claws_stare < 0.4 then
						weapont.__dlib_claws_open_t = weapont.__dlib_claws_open_t:min(CurTimeL() + 0.65)
					end

					weapont.__dlib_claws_stare = nil
				end

				if weapont.__dlib_claws_open and weapont.__dlib_claws_open_t < CurTimeL() then
					weapon:EmitSound('Weapon_PhysCannon.CloseClaws')
					net.Start('dlib_physgun_claws', true)
					net.WriteBool(false)
					net.Send(ply)
					weapont.__dlib_claws_open = false
					weapont.__dlib_gravgun_dropped = nil
				end
			end
		end

		::CONTINUE::
	end
end, 2)

